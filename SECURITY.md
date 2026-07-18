# Security policy

## Reporting a vulnerability

Use the repository's private
[security advisory form](https://github.com/CloudSprocket/ansible-lab-images/security/advisories/new).
Do not disclose an unpatched vulnerability in a public issue.

Include the affected tag or digest, platform, reproduction steps and expected
impact. Maintainers will acknowledge a complete report as soon as practical and
coordinate remediation and disclosure.

## Supported versions

Security fixes target the current distribution channels and the newest
versioned release. See [SUPPORT.md](SUPPORT.md) for distribution lifecycles.

## Important limitations

These are disposable lab images, not hardened production servers. The
`learner` account has passwordless sudo. Its sudo policy skips PAM account
validation, while Rocky SSH keeps `pam_sepermit` and `pam_nologin` before a
learner-only exception to the shadow-backed account check. Root login, password
authentication and interactive authentication remain disabled. Default SSH
mode is unprivileged, but optional systemd mode requires `privileged: true`, a
writable cgroup mount and unconfined AppArmor. Run it only on a trusted
development host.

The controller image contains no keys or credentials; supply the lab private
key at runtime and it is installed for the container user. The container runs
as root inside its own namespace by default; an unprivileged `automation`
account is available through `--user automation`.

Never expose the SSH ports publicly, mount the Docker socket, reuse lab keys or
store persistent secrets inside a managed-node container.
