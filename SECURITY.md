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
`learner` account has passwordless sudo by design. Default SSH mode is
unprivileged, but optional systemd mode requires `privileged: true` and a
writable cgroup mount. Run it only on a trusted development host.

Never expose the SSH ports publicly, mount the Docker socket, reuse lab keys or
store persistent secrets inside a managed-node container.
