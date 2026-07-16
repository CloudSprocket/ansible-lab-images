#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: run.sh <image> <distribution-id> <major> <Ansible-distribution>" >&2
  exit 2
fi

image="$1"
expected_id="$2"
expected_major="$3"
expected_distribution="$4"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
suffix="${RANDOM}${RANDOM}"
network="ansible-contract-${suffix}"
sshd_container="ansible-contract-sshd-${suffix}"
systemd_container="ansible-contract-systemd-${suffix}"
missing_key_container="ansible-contract-missing-key-${suffix}"
temp_dir="$(mktemp -d)"

docker_path() {
  case "$(uname -s)" in
    MINGW*|MSYS*) cygpath -w "$1" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

cleanup() {
  docker rm -f "$missing_key_container" "$sshd_container" "$systemd_container" \
    >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  rm -rf "$temp_dir"
}
trap cleanup EXIT

fail_with_logs() {
  local container="$1"
  echo "Contract failed for $container" >&2
  docker inspect "$container" >&2 || true
  docker logs "$container" >&2 || true
  docker exec "$container" sh -c \
    'id learner; getent shadow learner | cut -d: -f1,2; ls -l /etc/sudoers.d/90-lab-user; test ! -e /run/nologin' \
    >&2 || true
  docker exec "$container" journalctl --boot --no-pager --lines 200 >&2 || true
  exit 1
}

wait_for_health() {
  local container="$1"
  local status
  for _ in $(seq 1 90); do
    status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container")"
    case "$status" in
      healthy) return 0 ;;
      unhealthy|exited|dead) fail_with_logs "$container" ;;
    esac
    sleep 1
  done
  fail_with_logs "$container"
}

assert_clean_stop() {
  local container="$1"
  shift
  docker stop --time 30 "$container" >/dev/null
  local exit_code
  exit_code="$(docker inspect --format '{{.State.ExitCode}}' "$container")"
  local expected
  for expected in "$@"; do
    [[ "$exit_code" == "$expected" ]] && return 0
  done
  echo "$container stopped with unexpected exit code $exit_code" >&2
  exit 1
}

assert_labels() {
  local container="$1"
  local label
  for label in \
    org.opencontainers.image.base.digest \
    org.opencontainers.image.base.name \
    org.opencontainers.image.licenses \
    org.opencontainers.image.revision \
    org.opencontainers.image.source \
    org.opencontainers.image.version \
    org.cloudsprocket.image.distribution \
    org.cloudsprocket.image.distribution-version \
    org.cloudsprocket.image.supported-until; do
    [[ -n "$(docker inspect --format "{{index .Config.Labels \"$label\"}}" "$container")" ]] || {
      echo "Missing OCI label: $label" >&2
      exit 1
    }
  done
}

run_controller_contract() {
  local mode="$1"
  local container="$2"
  local key_path tests_path
  key_path="$(docker_path "$temp_dir/id_ed25519")"
  tests_path="$(docker_path "$ROOT_DIR/tests")"
  if ! docker run --rm \
    --network "$network" \
    --mount "type=bind,source=${key_path},target=/keys/id_ed25519,readonly" \
    --mount "type=bind,source=${tests_path},target=/tests,readonly" \
    cloudsprocket/ansible-contract:dev \
    /tests/contract/controller-contract.sh \
    "$mode" "$container" /keys/id_ed25519 \
    "$expected_id" "$expected_major" "$expected_distribution"; then
    fail_with_logs "$container"
  fi
}

ssh-keygen -q -t ed25519 -N "" -C "ansible-contract" -f "$temp_dir/id_ed25519"
public_key_path="$(docker_path "$temp_dir/id_ed25519.pub")"

set +e
docker run --name "$missing_key_container" "$image" >/dev/null 2>&1
missing_key_exit=$?
set -e
[[ "$missing_key_exit" -ne 0 ]] || {
  echo "Image started without an authorised-keys file" >&2
  exit 1
}

docker network create "$network" >/dev/null

docker run -d \
  --name "$sshd_container" \
  --hostname "$sshd_container" \
  --network "$network" \
  --mount "type=bind,source=${public_key_path},target=/run/secrets/authorized_keys,readonly" \
  "$image" >/dev/null

wait_for_health "$sshd_container"
[[ "$(docker inspect --format '{{.HostConfig.Privileged}}' "$sshd_container")" == "false" ]]
[[ "$(docker exec "$sshd_container" cat /proc/1/comm)" == "bash" ]]
[[ "$(docker inspect --format '{{range .Mounts}}{{println .Destination}}{{end}}' "$sshd_container")" != *docker.sock* ]]
assert_labels "$sshd_container"
run_controller_contract sshd "$sshd_container"
assert_clean_stop "$sshd_container" 0

docker run -d \
  --name "$systemd_container" \
  --hostname "$systemd_container" \
  --network "$network" \
  --privileged \
  --security-opt apparmor=unconfined \
  --cgroupns=host \
  --env LAB_INIT=systemd \
  --tmpfs /run:rw,nosuid,nodev,mode=755 \
  --tmpfs /run/lock:rw,nosuid,nodev,mode=755 \
  --tmpfs /tmp:rw,nosuid,nodev,mode=1777 \
  --volume /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --mount "type=bind,source=${public_key_path},target=/run/secrets/authorized_keys,readonly" \
  "$image" >/dev/null

wait_for_health "$systemd_container"
[[ "$(docker inspect --format '{{.HostConfig.Privileged}}' "$systemd_container")" == "true" ]]
[[ "$(docker inspect --format '{{.AppArmorProfile}}' "$systemd_container")" == "unconfined" ]]
[[ "$(docker exec "$systemd_container" cat /proc/1/comm)" == "systemd" ]]

service_name="sshd.service"
[[ "$expected_id" == "ubuntu" || "$expected_id" == "debian" ]] && service_name="ssh.service"
docker exec "$systemd_container" systemctl is-active --quiet "$service_name"

system_state="$(docker exec "$systemd_container" systemctl is-system-running 2>/dev/null || true)"
case "$system_state" in
  running|degraded) ;;
  *) echo "Unexpected systemd state: $system_state" >&2; fail_with_logs "$systemd_container" ;;
esac

assert_labels "$systemd_container"
run_controller_contract systemd "$systemd_container"
assert_clean_stop "$systemd_container" 0 130

echo "Contract passed for $image ($expected_distribution $expected_major)."
