#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERIFY_SCRIPT="$ROOT_DIR/scripts/verify-manifests.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mock_bin="$tmp_dir/bin"
state_dir="$tmp_dir/state"
mkdir -p "$mock_bin" "$state_dir"

cat > "$mock_bin/docker" <<'MOCK'
#!/usr/bin/env bash
set -Eeuo pipefail

[[ "$#" -eq 4 && "$1" == "buildx" && "$2" == "imagetools" && "$3" == "inspect" ]] || {
  echo "Unexpected docker invocation: $*" >&2
  exit 2
}

reference="$4"
repository="${reference%:*}"
repository="${repository##*/}"
tag="${reference##*:}"
count_key="${reference//\//_}"
count_key="${count_key//:/_}"
count_file="$MOCK_STATE_DIR/${count_key}.count"
count=0
if [[ -f "$count_file" ]]; then
  count="$(< "$count_file")"
fi
printf '%d\n' "$((count + 1))" > "$count_file"

if [[ "$repository" == "ansible-node-ubuntu-2404" && "$tag" == "0.2.0" ]]; then
  if [[ "$MOCK_MODE" == "retry" && "$count" -eq 0 ]]; then
    echo "manifest is still propagating" >&2
    exit 255
  fi
  if [[ "$MOCK_MODE" == "exhaust" ]]; then
    echo "manifest is still propagating" >&2
    exit 255
  fi
fi

case "$repository" in
  ansible-node-ubuntu-2404) digest="sha256:1111111111111111111111111111111111111111111111111111111111111111" ;;
  ansible-node-debian-13) digest="sha256:2222222222222222222222222222222222222222222222222222222222222222" ;;
  ansible-node-rocky-9) digest="sha256:3333333333333333333333333333333333333333333333333333333333333333" ;;
  ansible-node-rocky-10) digest="sha256:4444444444444444444444444444444444444444444444444444444444444444" ;;
  *) echo "Unexpected repository: $repository" >&2; exit 2 ;;
esac

if [[ "$MOCK_MODE" == "latest-mismatch" && "$repository" == "ansible-node-ubuntu-2404" && "$tag" == "latest" ]]; then
  digest="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
fi

printf 'Name: %s\nDigest:    %s\nManifests:\n  Platform:    linux/amd64\n  Platform:    linux/arm64\n' \
  "$reference" "$digest"
MOCK
chmod +x "$mock_bin/docker"

run_verifier() {
  local mode="$1"
  PATH="$mock_bin:$PATH" \
    MOCK_MODE="$mode" \
    MOCK_STATE_DIR="$state_dir" \
    IMAGE_NAMESPACE="docker.io/cloudsprocket-test" \
    MANIFEST_VERIFY_ATTEMPTS=3 \
    MANIFEST_VERIFY_RETRY_DELAY_SECONDS=0 \
    bash "$VERIFY_SCRIPT" 0.2.0
}

retry_output="$(run_verifier retry 2>&1)" || {
  echo "Expected transient manifest failure to recover." >&2
  echo "$retry_output" >&2
  exit 1
}
grep -q 'attempt 1/3' <<<"$retry_output"
grep -q 'Release manifests verified for 0.2.0.' <<<"$retry_output"
ubuntu_release_count="$state_dir/docker.io_cloudsprocket-test_ansible-node-ubuntu-2404_0.2.0.count"
[[ "$(< "$ubuntu_release_count")" == "2" ]]

rm -f "$state_dir"/*.count
if exhaust_output="$(run_verifier exhaust 2>&1)"; then
  echo "Expected exhausted manifest retries to fail." >&2
  exit 1
fi
grep -q 'after 3 attempts' <<<"$exhaust_output"
[[ "$(< "$ubuntu_release_count")" == "3" ]]

rm -f "$state_dir"/*.count
if mismatch_output="$(run_verifier latest-mismatch 2>&1)"; then
  echo "Expected mismatched latest and release digests to fail." >&2
  exit 1
fi
grep -q 'Latest and release tags differ for ubuntu-24.04' <<<"$mismatch_output"

echo "Manifest verification retry tests passed."
