#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 6 ]]; then
  echo "Usage: controller-contract.sh <mode> <host> <key> <id> <major> <distribution>" >&2
  exit 2
fi

mode="$1"
managed_host="$2"
source_key="$3"
expected_id="$4"
expected_major="$5"
expected_distribution="$6"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

private_key="$work_dir/id_ed25519"
install -m 0600 "$source_key" "$private_key"

ssh_options=(
  -i "$private_key"
  -o BatchMode=yes
  -o ConnectTimeout=3
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
)

ssh_run() {
  # The remaining arguments intentionally form the command executed remotely.
  # shellcheck disable=SC2029
  ssh "${ssh_options[@]}" "learner@${managed_host}" "$@"
}

ready=false
for _ in $(seq 1 90); do
  if ssh_run true >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done
[[ "$ready" == "true" ]] || { echo "SSH did not become ready on $managed_host" >&2; exit 1; }

# Expansion is intentionally deferred to the managed node.
# shellcheck disable=SC2016
ssh_run 'test "$(id -un)" = learner'
ssh_run 'python3 -c "import sys; assert sys.version_info.major == 3"'
ssh_run 'sudo -n true'
ssh_run '! command -v ansible >/dev/null 2>&1'
ssh_run 'sudo /usr/sbin/sshd -T | grep -qx "passwordauthentication no"'
ssh_run 'sudo /usr/sbin/sshd -T | grep -qx "permitrootlogin no"'
ssh_run 'sudo /usr/sbin/sshd -T | grep -qx "authenticationmethods publickey"'
# The awk expression is intentionally evaluated on the managed node.
# shellcheck disable=SC2016
ssh_run 'sudo getent shadow learner | awk -F: '\''$2 ~ /^[!*]/ {found=1} END {exit !found}'\'''
ssh_run "source /etc/os-release; test \"\$ID\" = '$expected_id'"
ssh_run "source /etc/os-release; case \"\$VERSION_ID\" in '$expected_major'*) ;; *) exit 1 ;; esac"

inventory="$work_dir/inventory.yml"
cat > "$inventory" <<EOF
---
all:
  hosts:
    node:
      ansible_host: ${managed_host}
      ansible_port: 22
      ansible_user: learner
      ansible_ssh_private_key_file: ${private_key}
EOF

export ANSIBLE_CONFIG=/tests/ansible/ansible.cfg

assert_idempotent() {
  local playbook="$1"
  local output
  ansible-playbook -i "$inventory" "$playbook" \
    -e "expected_distribution=$expected_distribution" \
    -e "expected_major=$expected_major"
  output="$(ansible-playbook -i "$inventory" "$playbook" \
    -e "expected_distribution=$expected_distribution" \
    -e "expected_major=$expected_major" 2>&1 | tee /dev/stderr)"
  if grep -E 'changed=[1-9][0-9]*' <<<"$output" | grep -E 'ok=' >/dev/null; then
    echo "Idempotency failure: $playbook reported changes on its second run" >&2
    exit 1
  fi
}

assert_idempotent /tests/ansible/verify.yml

if [[ "$mode" == "systemd" ]]; then
  assert_idempotent /tests/ansible/systemd.yml
fi
