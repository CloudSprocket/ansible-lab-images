#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERIFY_SCRIPT="$ROOT_DIR/scripts/verify-manifests.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mock_bin="$tmp_dir/bin"
state_dir="$tmp_dir/state"
mkdir -p "$mock_bin" "$state_dir"

cat > "$mock_bin/docker" <<'MOCK'
#!/usr/bin/env bash
set -Eeuo pipefail

[[ "$#" -eq 4 && "$1" == "buildx" && "$2" == "imagetools" && "$3" == "inspect" ]] || {
  echo "Unexpected docker invocation: $*" >&2
  exit 2
}

reference="$4"
tag="${reference##*:}"
count_file="$MOCK_STATE_DIR/${tag}.count"
count=0
if [[ -f "$count_file" ]]; then
  count="$(< "$count_file")"
fi
printf '%d\n' "$((count + 1))" > "$count_file"

if [[ "$tag" == "latest" ]]; then
  if [[ "$MOCK_MODE" == "latest-error" ]]; then
    echo "temporary registry failure" >&2
    exit 255
  fi
  echo "$reference: not found" >&2
  exit 1
fi

if [[ "$tag" == "ubuntu-24.04-0.1.0" ]]; then
  if [[ "$MOCK_MODE" == "retry" && "$count" -eq 0 ]]; then
    echo "manifest is still propagating" >&2
    exit 255
  fi
  if [[ "$MOCK_MODE" == "exhaust" ]]; then
    echo "manifest is still propagating" >&2
    exit 255
  fi
fi

distribution="${tag%-0.1.0}"
case "$distribution" in
  ubuntu-24.04) digest="sha256:1111111111111111111111111111111111111111111111111111111111111111" ;;
  debian-13) digest="sha256:2222222222222222222222222222222222222222222222222222222222222222" ;;
  rocky-9) digest="sha256:3333333333333333333333333333333333333333333333333333333333333333" ;;
  rocky-10) digest="sha256:4444444444444444444444444444444444444444444444444444444444444444" ;;
  *) echo "Unexpected tag: $tag" >&2; exit 2 ;;
esac

printf 'Name: %s\nDigest:    %s\nManifests:\n  Platform:    linux/amd64\n  Platform:    linux/arm64\n' \
  "$reference" "$digest"
MOCK
chmod +x "$mock_bin/docker"

run_verifier() {
  local mode="$1"
  PATH="$mock_bin:$PATH" \
    MOCK_MODE="$mode" \
    MOCK_STATE_DIR="$state_dir" \
    IMAGE="docker.io/cloudsprocket/test-ansible-node" \
    MANIFEST_VERIFY_ATTEMPTS=3 \
    MANIFEST_VERIFY_RETRY_DELAY_SECONDS=0 \
    bash "$VERIFY_SCRIPT" 0.1.0
}

retry_output="$(run_verifier retry 2>&1)" || {
  echo "Expected transient manifest failure to recover." >&2
  echo "$retry_output" >&2
  exit 1
}
grep -q 'attempt 1/3' <<<"$retry_output"
grep -q 'Release manifests verified for 0.1.0.' <<<"$retry_output"
[[ "$(< "$state_dir/ubuntu-24.04-0.1.0.count")" == "2" ]]

rm -f "$state_dir"/*.count
if exhaust_output="$(run_verifier exhaust 2>&1)"; then
  echo "Expected exhausted manifest retries to fail." >&2
  exit 1
fi
grep -q 'after 3 attempts' <<<"$exhaust_output"
[[ "$(< "$state_dir/ubuntu-24.04-0.1.0.count")" == "3" ]]

rm -f "$state_dir"/*.count
if latest_output="$(run_verifier latest-error 2>&1)"; then
  echo "Expected an unexpected latest-tag registry error to fail closed." >&2
  exit 1
fi
grep -q 'Could not confirm absence of the prohibited latest tag.' <<<"$latest_output"

echo "Manifest verification retry tests passed."
