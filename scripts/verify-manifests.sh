#!/usr/bin/env bash
set -Eeuo pipefail

version="${1:-}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Usage: ./scripts/verify-manifests.sh <major.minor.patch>" >&2
  exit 2
}

image_namespace="${IMAGE_NAMESPACE:-docker.io/cloudsprocket}"
max_attempts="${MANIFEST_VERIFY_ATTEMPTS:-6}"
retry_delay_seconds="${MANIFEST_VERIFY_RETRY_DELAY_SECONDS:-5}"

declare -A repository_names=(
  [ubuntu-24.04]="ansible-node-ubuntu-2404"
  [debian-13]="ansible-node-debian-13"
  [rocky-9]="ansible-node-rocky-9"
  [rocky-10]="ansible-node-rocky-10"
)

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
  image="${image_namespace}/${repository_names[$distribution]}"
  release_reference="${image}:${version}"
  inspect_output="$(inspect_manifest "$release_reference")"
  grep -q 'Platform:.*linux/amd64' <<<"$inspect_output" || {
    echo "Missing linux/amd64 manifest for $release_reference" >&2
    exit 1
  }
  grep -q 'Platform:.*linux/arm64' <<<"$inspect_output" || {
    echo "Missing linux/arm64 manifest for $release_reference" >&2
    exit 1
  }

  latest_output="$(inspect_manifest "${image}:latest")"
  latest_digest="$(awk '/^Digest:/ {print $2; exit}' <<<"$latest_output")"
  release_digest="$(awk '/^Digest:/ {print $2; exit}' <<<"$inspect_output")"
  [[ -n "$latest_digest" && -n "$release_digest" ]] || {
    echo "Unable to resolve latest and release digests for $distribution" >&2
    exit 1
  }
  [[ "$latest_digest" == "$release_digest" ]] || {
    echo "Latest and release tags differ for $distribution" >&2
    exit 1
  }
done

echo "Release manifests verified for $version."
