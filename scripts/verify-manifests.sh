#!/usr/bin/env bash
set -Eeuo pipefail

version="${1:-}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Usage: ./scripts/verify-manifests.sh <major.minor.patch>" >&2
  exit 2
}

image="${IMAGE:-docker.io/cloudsprocket/ansible-node}"
max_attempts="${MANIFEST_VERIFY_ATTEMPTS:-6}"
retry_delay_seconds="${MANIFEST_VERIFY_RETRY_DELAY_SECONDS:-5}"

[[ "$max_attempts" =~ ^[1-9][0-9]*$ ]] || {
  echo "MANIFEST_VERIFY_ATTEMPTS must be a positive integer." >&2
  exit 2
}
[[ "$retry_delay_seconds" =~ ^[0-9]+$ ]] || {
  echo "MANIFEST_VERIFY_RETRY_DELAY_SECONDS must be a non-negative integer." >&2
  exit 2
}

inspect_manifest() {
  local reference="$1"
  local attempt=1
  local inspect_output=""
  local sleep_seconds

  while ! inspect_output="$(docker buildx imagetools inspect "$reference" 2>&1)"; do
    if (( attempt >= max_attempts )); then
      printf 'Unable to inspect %s after %d attempts.\n%s\n' \
        "$reference" "$max_attempts" "$inspect_output" >&2
      return 1
    fi

    sleep_seconds=$((retry_delay_seconds * attempt))
    printf 'Manifest %s is not ready (attempt %d/%d); retrying in %d seconds.\n' \
      "$reference" "$attempt" "$max_attempts" "$sleep_seconds" >&2
    sleep "$sleep_seconds"
    ((attempt += 1))
  done

  printf '%s\n' "$inspect_output"
}

for distribution in ubuntu-24.04 debian-13 rocky-9 rocky-10; do
  reference="${image}:${distribution}-${version}"
  inspect_output="$(inspect_manifest "$reference")"
  grep -q 'Platform:.*linux/amd64' <<<"$inspect_output" || {
    echo "Missing linux/amd64 manifest for $reference" >&2
    exit 1
  }
  grep -q 'Platform:.*linux/arm64' <<<"$inspect_output" || {
    echo "Missing linux/arm64 manifest for $reference" >&2
    exit 1
  }

  channel_output="$(inspect_manifest "${image}:${distribution}")"
  channel_digest="$(awk '/^Digest:/ {print $2; exit}' <<<"$channel_output")"
  release_digest="$(awk '/^Digest:/ {print $2; exit}' <<<"$inspect_output")"
  [[ -n "$channel_digest" && -n "$release_digest" ]] || {
    echo "Unable to resolve channel and release digests for $distribution" >&2
    exit 1
  }
  [[ "$channel_digest" == "$release_digest" ]] || {
    echo "Channel and release tags differ for $distribution" >&2
    exit 1
  }
done

latest_output=""
if latest_output="$(docker buildx imagetools inspect "${image}:latest" 2>&1)"; then
  echo "A generic latest tag exists, which is prohibited." >&2
  exit 1
elif ! grep -Eqi 'manifest unknown|not found' <<<"$latest_output"; then
  printf 'Could not confirm absence of the prohibited latest tag.\n%s\n' \
    "$latest_output" >&2
  exit 1
fi

echo "Release manifests verified for $version."
