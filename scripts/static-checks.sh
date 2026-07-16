#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker buildx bake -f docker-bake.hcl --check --set '*.platform=linux/amd64'
docker compose -f compose.yml config --quiet
docker compose -f compose.yml -f compose.systemd.yml config --quiet

mapfile -t shell_files < <(find common scripts tests -type f -name '*.sh' -print | sort)
for shell_file in "${shell_files[@]}"; do
  bash -n "$shell_file"
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${shell_files[@]}"
fi

if command -v hadolint >/dev/null 2>&1; then
  hadolint images/debian/Dockerfile images/rhel/Dockerfile tests/controller/Dockerfile
fi

if command -v yamllint >/dev/null 2>&1; then
  yamllint .github compose.yml compose.systemd.yml tests/ansible .yamllint.yml
fi

python -m json.tool support-matrix.json >/dev/null

if rg -n --hidden --glob '!scripts/static-checks.sh' \
  -- '--break-system-packages|EXTERNALLY-MANAGED' \
  .github common images scripts tests docker-bake.hcl; then
  echo "Forbidden Python packaging bypass found." >&2
  exit 1
fi

if rg -n --hidden --glob '!.git/**' --glob '!.local/**' \
  'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY' .; then
  echo "Private key material found." >&2
  exit 1
fi

if rg -n '^\s*uses:\s*[^@[:space:]]+@[^#[:space:]]+' .github/workflows \
  | grep -Ev '@[0-9a-f]{40}([[:space:]]|$)'; then
  echo "Every GitHub Action must be pinned to a full commit SHA." >&2
  exit 1
fi

while IFS=$'\t' read -r target digest; do
  case "$target" in
    ubuntu-2404|debian-13) dockerfile="images/debian/Dockerfile" ;;
    rocky-9|rocky-10) dockerfile="images/rhel/Dockerfile" ;;
    *) echo "Unknown support-matrix target: $target" >&2; exit 1 ;;
  esac
  digest="${digest//$'\r'/}"
  rg -q --fixed-strings "$digest" "$dockerfile" || {
    echo "Base digest for $target is not pinned in $dockerfile: $digest" >&2
    exit 1
  }
  rg -q --fixed-strings "$digest" docker-bake.hcl || {
    echo "Base digest for $target is not mirrored in docker-bake.hcl: $digest" >&2
    exit 1
  }
done < <(python -c 'import json; print("\n".join(f"{i['"'"'target'"'"']}\t{i['"'"'base_digest'"'"']}" for i in json.load(open("support-matrix.json", encoding="utf-8"))["images"]))')

echo "Static checks passed."
