#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

docker buildx bake -f docker-bake.hcl --check --set '*.platform=linux/amd64'
docker compose -f compose.yml config --quiet
docker compose -f compose.yml -f compose.systemd.yml config --quiet
docker compose -f compose.yml -f compose.release.yml config --quiet
docker compose -f compose.yml -f compose.release.yml -f compose.systemd.yml config --quiet

mapfile -t shell_files < <(find common images scripts tests -type f -name '*.sh' -print | sort)
for shell_file in "${shell_files[@]}"; do
  bash -n "$shell_file"
done

bash tests/scripts/verify-manifests-test.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${shell_files[@]}"
fi

if command -v hadolint >/dev/null 2>&1; then
  hadolint images/controller/Dockerfile images/debian/Dockerfile images/rhel/Dockerfile
fi

if command -v yamllint >/dev/null 2>&1; then
  yamllint .github compose.yml compose.systemd.yml tests/ansible .yamllint.yml
fi

python -m json.tool support-matrix.json >/dev/null
version="$(< VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "VERSION must contain a semantic major.minor.patch value." >&2
  exit 1
}

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

while IFS=$'\t' read -r target base_image digest repository; do
  case "$target" in
    ubuntu-2404) dockerfile="images/debian/Dockerfile"; stage="ubuntu-24.04" ;;
    debian-13) dockerfile="images/debian/Dockerfile"; stage="debian-13" ;;
    rocky-9|rocky-10) dockerfile="images/rhel/Dockerfile"; stage="$target" ;;
    *) echo "Unknown support-matrix target: $target" >&2; exit 1 ;;
  esac
  base_image="${base_image//$'\r'/}"
  digest="${digest//$'\r'/}"
  repository="${repository//$'\r'/}"
  expected_from="FROM ${base_image}@${digest} AS ${stage}"
  rg -q --fixed-strings --line-regexp "$expected_from" "$dockerfile" || {
    echo "Base image for $target does not match support-matrix.json: $expected_from" >&2
    exit 1
  }
  rg -q --fixed-strings "$digest" docker-bake.hcl || {
    echo "Base digest for $target is not mirrored in docker-bake.hcl: $digest" >&2
    exit 1
  }
  rg -q --fixed-strings "$base_image" docker-bake.hcl || {
    echo "Base image for $target is not mirrored in docker-bake.hcl: $base_image" >&2
    exit 1
  }
  for repository_file in docker-bake.hcl compose.yml .github/workflows/ci.yml .github/workflows/release.yml scripts/test-image.sh; do
    rg -q --fixed-strings "$repository" "$repository_file" || {
      echo "Repository for $target is missing from $repository_file: $repository" >&2
      exit 1
    }
  done
  rg -q --fixed-strings "${repository}:${version}" compose.release.yml || {
    echo "Pinned release image for $target is missing from compose.release.yml" >&2
    exit 1
  }
done < <(python -c 'import json; print("\n".join(f"{i['"'"'target'"'"']}\t{i['"'"'base_image'"'"']}\t{i['"'"'base_digest'"'"']}\t{i['"'"'repository'"'"']}" for i in json.load(open("support-matrix.json", encoding="utf-8"))["images"]))')

IFS=$'\t' read -r controller_repository controller_base_image controller_digest controller_core < <(python -c 'import json; c = json.load(open("support-matrix.json", encoding="utf-8"))["controller"]; print(f"{c['"'"'repository'"'"']}\t{c['"'"'base_image'"'"']}\t{c['"'"'base_digest'"'"']}\t{c['"'"'ansible_core'"'"']}")')
controller_repository="${controller_repository//$'\r'/}"
controller_base_image="${controller_base_image//$'\r'/}"
controller_digest="${controller_digest//$'\r'/}"
controller_core="${controller_core//$'\r'/}"
controller_from="FROM ${controller_base_image}@${controller_digest}"
rg -q --fixed-strings --line-regexp "$controller_from" images/controller/Dockerfile || {
  echo "Controller base image does not match support-matrix.json: $controller_from" >&2
  exit 1
}
rg -q --fixed-strings "$controller_digest" docker-bake.hcl || {
  echo "Controller base digest is not mirrored in docker-bake.hcl" >&2
  exit 1
}
rg -q --fixed-strings "$controller_base_image" docker-bake.hcl || {
  echo "Controller base image is not mirrored in docker-bake.hcl" >&2
  exit 1
}
rg -q --fixed-strings "ansible-core==${controller_core}" images/controller/requirements.txt || {
  echo "Controller ansible-core pin does not match support-matrix.json" >&2
  exit 1
}
for repository_file in docker-bake.hcl compose.yml .github/workflows/ci.yml .github/workflows/release.yml tests/contract/run.sh; do
  rg -q --fixed-strings "$controller_repository" "$repository_file" || {
    echo "Controller repository is missing from $repository_file: $controller_repository" >&2
    exit 1
  }
done
rg -q --fixed-strings "${controller_repository##*/}" scripts/verify-manifests.sh || {
  echo "Controller repository is missing from scripts/verify-manifests.sh" >&2
  exit 1
}
rg -q --fixed-strings "${controller_repository}:${version}" compose.release.yml || {
  echo "Pinned controller release image is missing from compose.release.yml" >&2
  exit 1
}

echo "Static checks passed."
