#!/usr/bin/env bash
set -Eeuo pipefail

# Bind mounts on Windows and macOS hosts expose private keys with permissive
# modes that the OpenSSH client rejects, so install a 0600 copy when a lab key
# is supplied.
key_source="${LAB_PRIVATE_KEY_FILE:-/keys/id_ed25519}"
if [[ -r "$key_source" && -f "$key_source" ]]; then
  install -d -m 0700 "$HOME/.ssh"
  install -m 0600 "$key_source" "$HOME/.ssh/id_ed25519"
fi

exec "$@"
