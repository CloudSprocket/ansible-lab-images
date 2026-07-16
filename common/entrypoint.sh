#!/usr/bin/env bash
set -Eeuo pipefail

readonly LAB_USER="learner"
readonly LAB_HOME="/home/${LAB_USER}"
readonly DEFAULT_AUTHORIZED_KEYS_FILE="/run/secrets/authorized_keys"

fail() {
  echo "lab-entrypoint: $*" >&2
  exit 1
}

if [[ $# -gt 0 ]]; then
  exec "$@"
fi

init_mode="${LAB_INIT:-sshd}"
case "$init_mode" in
  sshd|systemd) ;;
  *) fail "LAB_INIT must be 'sshd' or 'systemd', not '$init_mode'." ;;
esac

authorized_keys_file="${LAB_AUTHORIZED_KEYS_FILE:-$DEFAULT_AUTHORIZED_KEYS_FILE}"
[[ -r "$authorized_keys_file" ]] || fail "mount a readable authorised-keys file at $authorized_keys_file"
[[ -s "$authorized_keys_file" ]] || fail "the authorised-keys file is empty"

if grep -q 'PRIVATE KEY' "$authorized_keys_file"; then
  fail "the authorised-keys file appears to contain private key material"
fi

valid_keys=0
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  case "$line" in
    ssh-ed25519\ *|ssh-rsa\ *|ecdsa-sha2-*\ *|sk-ssh-ed25519@openssh.com\ *|sk-ecdsa-sha2-nistp256@openssh.com\ *)
      valid_keys=$((valid_keys + 1))
      ;;
    *) fail "the authorised-keys file contains an unsupported line" ;;
  esac
done < "$authorized_keys_file"
(( valid_keys > 0 )) || fail "the authorised-keys file contains no usable public keys"

install -d -o "$LAB_USER" -g "$LAB_USER" -m 0700 "$LAB_HOME/.ssh"
install -o "$LAB_USER" -g "$LAB_USER" -m 0600 \
  "$authorized_keys_file" "$LAB_HOME/.ssh/authorized_keys"

install -d -m 0755 /run/sshd
ssh-keygen -A >/dev/null

if [[ "$init_mode" == "systemd" ]]; then
  exec /sbin/init
fi

/usr/sbin/sshd -D -e &
sshd_pid=$!
terminating=false

# ShellCheck cannot infer calls made indirectly by signal traps.
# shellcheck disable=SC2317
terminate_sshd() {
  terminating=true
  kill -TERM "$sshd_pid" 2>/dev/null || true
}

trap terminate_sshd TERM INT RTMIN+3
set +e
wait "$sshd_pid"
status=$?
set -e

if [[ "$terminating" == "true" ]]; then
  exit 0
fi

exit "$status"
