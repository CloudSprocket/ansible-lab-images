#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: controller-image.sh <controller-image>" >&2
  exit 2
fi

image="$1"

# The tools live in a virtual environment on PATH. A login shell sources
# /etc/profile and resets PATH, so both shell forms are part of the contract.
for shell_args in "-c" "-lc"; do
  for tool in ansible ansible-playbook ansible-galaxy ansible-lint; do
    if ! docker run --rm "$image" bash "$shell_args" "command -v $tool >/dev/null"; then
      echo "Controller contract: $tool is not on PATH for 'bash $shell_args'" >&2
      exit 1
    fi
  done
done

for collection in community.general ansible.posix; do
  if ! docker run --rm "$image" bash -c \
    "ansible-galaxy collection list 2>/dev/null | grep -q '^${collection} '"; then
    echo "Controller contract: collection $collection is missing" >&2
    exit 1
  fi
done

if ! docker run --rm "$image" bash -c 'id automation >/dev/null'; then
  echo "Controller contract: the automation account is missing" >&2
  exit 1
fi

echo "Controller contract passed for $image."
