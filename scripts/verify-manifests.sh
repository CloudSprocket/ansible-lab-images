#!/usr/bin/env bash
set -Eeuo pipefail

version="${1:-}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Usage: ./scripts/verify-manifests.sh <major.minor.patch>" >&2
  exit 2
}

image="${IMAGE:-docker.io/cloudsprocket/ansible-node}"
for distribution in ubuntu-24.04 debian-13 rocky-9 rocky-10; do
  reference="${image}:${distribution}-${version}"
  inspect_output="$(docker buildx imagetools inspect "$reference")"
  grep -q 'Platform:.*linux/amd64' <<<"$inspect_output"
  grep -q 'Platform:.*linux/arm64' <<<"$inspect_output"

  channel_digest="$(docker buildx imagetools inspect "${image}:${distribution}" | awk '/^Digest:/ {print $2; exit}')"
  release_digest="$(awk '/^Digest:/ {print $2; exit}' <<<"$inspect_output")"
  [[ "$channel_digest" == "$release_digest" ]] || {
    echo "Channel and release tags differ for $distribution" >&2
    exit 1
  }
done

if docker buildx imagetools inspect "${image}:latest" >/dev/null 2>&1; then
  echo "A generic latest tag exists, which is prohibited." >&2
  exit 1
fi

echo "Release manifests verified for $version."
