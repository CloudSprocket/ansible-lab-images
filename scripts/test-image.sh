#!/usr/bin/env bash
set -Eeuo pipefail

target="${1:-}"
case "$target" in
  ubuntu-24.04|ubuntu-2404)
    image="docker.io/cloudsprocket/ansible-node:ubuntu-24.04-dev"
    expected_id="ubuntu"
    expected_major="24"
    expected_distribution="Ubuntu"
    ;;
  debian-13)
    image="docker.io/cloudsprocket/ansible-node:debian-13-dev"
    expected_id="debian"
    expected_major="13"
    expected_distribution="Debian"
    ;;
  rocky-9)
    image="docker.io/cloudsprocket/ansible-node:rocky-9-dev"
    expected_id="rocky"
    expected_major="9"
    expected_distribution="Rocky"
    ;;
  rocky-10)
    image="docker.io/cloudsprocket/ansible-node:rocky-10-dev"
    expected_id="rocky"
    expected_major="10"
    expected_distribution="Rocky"
    ;;
  *)
    echo "Usage: ./scripts/test-image.sh <ubuntu-24.04|debian-13|rocky-9|rocky-10>" >&2
    exit 2
    ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT_DIR/tests/contract/run.sh" \
  "$image" "$expected_id" "$expected_major" "$expected_distribution"
