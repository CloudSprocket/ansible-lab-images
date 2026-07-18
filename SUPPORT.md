# Support policy

## Supported matrix

| Distribution | Architectures | Planned upstream coverage used by this project |
| --- | --- | --- |
| Ubuntu 24.04 LTS | amd64, arm64 | Standard maintenance through May 2029 |
| Debian 13 | amd64, arm64 | LTS planned through 30 June 2030 |
| Rocky Linux 9 | amd64, arm64 | End of life 31 May 2032 |
| Rocky Linux 10 | amd64, arm64 | End of life 31 May 2035 |

Lifecycle dates follow the upstream publishers:

- [Ubuntu release cycle](https://ubuntu.com/about/release-cycle)
- [Debian LTS schedule](https://wiki.debian.org/LTS)
- [Rocky Linux version guide](https://wiki.rockylinux.org/rocky/version/)

The machine-readable form is [support-matrix.json](support-matrix.json).

## Controller image

`cloudsprocket/ansible-controller` ships ansible-core, ansible-lint and the
`community.general` and `ansible.posix` collections on amd64 and arm64. It
follows the project's release cadence and the ansible-core support lifecycle
rather than a distribution lifecycle. The pinned versions for each release
are recorded in [support-matrix.json](support-matrix.json).

## What support means

While a distribution is supported, the project intends to:

- rebuild weekly from its pinned, reviewed base digest;
- test current packages on native amd64 and arm64 runners;
- run SSH, Ansible idempotency and systemd contracts;
- publish security-driven or monthly versioned releases;
- review base-digest and test-tool dependency updates.

Support applies to the documented lab contract. It does not include production
workloads, persistent data, application runtimes or arbitrary init systems.

## Deprecation

A distribution receives a deprecation notice before removal whenever upstream
timelines permit. Its moving channel stops after the final supported release;
immutable version tags remain available with an unsupported notice.
