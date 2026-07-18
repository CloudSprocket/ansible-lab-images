#!/usr/bin/env bash
set -Eeuo pipefail

target="${1:-}"
case "$target" in
  ubuntu-24.04) bake_target="ubuntu-2404" ;;
  debian-13|rocky-9|rocky-10) bake_target="$target" ;;
  *) echo "Usage: ./scripts/build-and-test.sh <target>" >&2; exit 2 ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

architecture="$(docker info --format '{{.Architecture}}')"
case "$architecture" in
  x86_64|amd64) platform="linux/amd64" ;;
  aarch64|arm64) platform="linux/arm64" ;;
  *) echo "Unsupported Docker architecture: $architecture" >&2; exit 1 ;;
esac

docker buildx bake -f docker-bake.hcl "$bake_target" controller --load \
  --set "${bake_target}.platform=${platform}" \
  --set "controller.platform=${platform}"
"$ROOT_DIR/scripts/test-image.sh" "$target"
