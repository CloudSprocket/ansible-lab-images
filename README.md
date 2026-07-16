# CloudSprocket Ansible Lab Images

[![CI](https://github.com/CloudSprocket/ansible-lab-images/actions/workflows/ci.yml/badge.svg)](https://github.com/CloudSprocket/ansible-lab-images/actions/workflows/ci.yml)
[![Licence: MIT](https://img.shields.io/badge/licence-MIT-blue.svg)](LICENSE)

Secure, disposable Linux managed-node images for Ansible labs, role testing and
multi-distribution automation practice.

These images contain Python, sudo, OpenSSH and optional systemd support. Ansible
runs from a separate control node. They are lab targets, not production server
images.

## Supported images

| Distribution | Development tag | Release channel | Platforms |
| --- | --- | --- | --- |
| Ubuntu 24.04 LTS | `ubuntu-24.04-dev` | `ubuntu-24.04` | amd64, arm64 |
| Debian 13 | `debian-13-dev` | `debian-13` | amd64, arm64 |
| Rocky Linux 9 | `rocky-9-dev` | `rocky-9` | amd64, arm64 |
| Rocky Linux 10 | `rocky-10-dev` | `rocky-10` | amd64, arm64 |

There is deliberately no generic `latest` tag. Select a distribution explicitly.
See [SUPPORT.md](SUPPORT.md) for lifecycle dates.

## Security contract

Every managed-node image provides the same baseline:

- unprivileged SSH mode by default;
- a locked `learner` password with key-only authentication;
- passwordless sudo for disposable lab exercises;
- public keys supplied at runtime, never baked into an image;
- SSH host keys generated when a container starts;
- root login, passwords, forwarding and tunnelling disabled;
- no Ansible installation, Docker socket or host-home mount;
- an explicit privileged systemd mode for service-management tests;
- digest-pinned upstream bases and OCI source, revision and support labels.

## Local quick start

Requirements: Docker Engine or Docker Desktop, Buildx, Compose and OpenSSH.

Linux, macOS or WSL:

```bash
./scripts/generate-lab-key.sh
docker buildx bake -f docker-bake.hcl all --load
docker compose up -d
ssh -i .lab/ssh/id_ed25519 -p 2222 learner@127.0.0.1
```

Windows PowerShell:

```powershell
.\scripts\Generate-LabKey.ps1
docker buildx bake -f docker-bake.hcl all --load
docker compose up -d
ssh -i .lab\ssh\id_ed25519 -p 2222 learner@127.0.0.1
```

Ports 2222 through 2225 map to Ubuntu, Debian, Rocky Linux 9 and Rocky Linux
10 respectively. Stop the estate with `docker compose down`.

## Optional systemd mode

Real systemd requires privileges that weaken container isolation. Use it only
on a trusted development machine with disposable lab containers.

```bash
docker compose -f compose.yml -f compose.systemd.yml up -d
docker exec ansible-node-ubuntu2404 systemctl is-system-running
docker compose -f compose.yml -f compose.systemd.yml down
```

The overlay enables privileged mode, the host cgroup namespace, a writable
cgroup mount and tmpfs mounts for runtime directories. It never mounts the
Docker socket or a user home directory.

## Build and contract commands

```bash
docker buildx bake -f docker-bake.hcl --check
docker buildx bake -f docker-bake.hcl                 # Ubuntu and Debian
docker buildx bake -f docker-bake.hcl all --load      # all managed nodes
./scripts/build-and-test.sh ubuntu-24.04
./scripts/build-and-test.sh debian-13
./scripts/build-and-test.sh rocky-9
./scripts/build-and-test.sh rocky-10
./scripts/static-checks.sh
```

The contract runner builds a separate pinned controller containing
`ansible-core==2.21.2`. For every managed image it verifies:

1. failure when no public key is provided;
2. unprivileged SSH and the hardened SSH configuration;
3. locked-password key authentication and passwordless sudo;
4. distribution and Python facts;
5. package, user and file automation through external Ansible;
6. `changed=0` on an unchanged second playbook run;
7. privileged systemd startup and real service management;
8. required OCI labels and clean container shutdown.

GitHub Actions runs this contract natively on amd64 and arm64.

## Published tags

Release `0.1.0` produces, for example:

```text
docker.io/cloudsprocket/ansible-node:ubuntu-24.04
docker.io/cloudsprocket/ansible-node:ubuntu-24.04-0.1.0
docker.io/cloudsprocket/ansible-node:ubuntu-24.04-sha-<commit>
```

Distribution channels move after a verified release. Version and commit tags
are immutable. Published builds include BuildKit SBOM and provenance
attestations. See [RELEASE.md](RELEASE.md) for the release procedure.

## Project documents

- [Design and trust boundaries](docs/design.md)
- [Support policy](SUPPORT.md)
- [Security policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Release process](RELEASE.md)

## Licence

[MIT](LICENSE)
