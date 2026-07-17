# Design and trust boundaries

## Purpose

The project provides disposable SSH targets that behave consistently enough to
test Ansible content across current Linux families. It does not attempt to make
containers equivalent to virtual machines or production servers.

## Image boundary

Managed-node images contain only the packages needed to expose a useful lab
surface: OpenSSH, Python, the distribution package bindings, sudo and systemd.
The controller and its Ansible version remain external. This prevents target
images from silently testing against a second automation installation.

## Authentication boundary

The `learner` account has an unusable `*` password hash. The entrypoint refuses
to start its managed service unless it receives at least one supported public key through a file.
Private-key markers and malformed lines are rejected. Compose uses a runtime
secret mounted at `/run/secrets/authorized_keys`.

Users can override the entrypoint with an explicit command for image
inspection. Doing so bypasses the managed-service contract and is outside the
published runtime guarantee.

## Init modes

Default mode uses an unprivileged container and a small PID 1 wrapper around
foreground OpenSSH. The wrapper translates the image stop signal into a clean
OpenSSH termination and reaps the process.

Systemd mode sets `LAB_INIT=systemd` and executes `/sbin/init` as PID 1. Docker
must grant privileged mode, the host cgroup namespace, a writable cgroup mount
and tmpfs runtime directories. Privileged mode is AppArmor-unconfined, so the
learner-specific sudo policy skips PAM account validation. Rocky's SSH PAM
policy still enforces `pam_sepermit` and `pam_nologin`, then accepts `learner`
before its shadow-backed account check. These narrow exceptions avoid host
path-based PAM helper profiles while retaining PAM authentication and session
handling. The test suite asserts these settings instead of hiding them behind
the image.

## Supply-chain boundary

Human-readable base tags are paired with immutable manifest digests. Buildx
Bake provides the distribution matrix, tags and OCI labels. Pull requests run
native amd64 and arm64 contracts and reject new fixable high or critical
vulnerabilities. Releases use clean pulls, multi-platform builds, SBOMs and
maximum BuildKit provenance.

Registry credentials are scoped to a protected release environment and never
enter pull-request workflows or Docker build arguments.
