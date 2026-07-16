#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
key_dir="$ROOT_DIR/.lab/ssh"
private_key="$key_dir/id_ed25519"

install -d -m 0700 "$key_dir"
if [[ ! -f "$private_key" ]]; then
  ssh-keygen -q -t ed25519 -N "" -C "ansible-lab-images" -f "$private_key"
fi
install -m 0600 "$private_key.pub" "$key_dir/authorized_keys"
chmod 0600 "$private_key"

echo "Lab key ready at .lab/ssh/id_ed25519"
