# Contributing

## Development requirements

- Docker Engine or Docker Desktop
- Docker Buildx and Compose
- Bash, OpenSSH and `rg`
- Optional local ShellCheck, Hadolint and yamllint

## Before opening a pull request

Run static validation:

```bash
./scripts/static-checks.sh
```

Build and test every affected distribution:

```bash
./scripts/build-and-test.sh ubuntu-24.04
./scripts/build-and-test.sh debian-13
./scripts/build-and-test.sh rocky-9
./scripts/build-and-test.sh rocky-10
```

The second Ansible run must report `changed=0`. Do not weaken a contract to
make a failing image pass. Explain intentional contract changes in the pull
request.

## Build policy

- Keep family Dockerfiles short and distribution logic explicit.
- Pair every upstream tag with an immutable digest.
- Do not add fixed passwords, keys, tokens or registry credentials.
- Do not install Ansible in a managed-node image.
- Do not delete the Python `EXTERNALLY-MANAGED` marker or use packaging bypasses.
- Pin GitHub Actions to full commit SHAs with a version comment.
- Preserve unprivileged SSH as the default mode.

Operating-system package versions are intentionally not pinned individually.
The trusted base manifest is pinned, clean rebuilds install the current packages
from that distribution's repositories, and the full contract plus vulnerability
gate decides whether the resulting image is acceptable.
