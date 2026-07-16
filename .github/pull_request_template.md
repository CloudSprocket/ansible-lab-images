## Summary

Describe what changed and why.

## Contract impact

- [ ] Default unprivileged SSH behaviour is unchanged or deliberately updated.
- [ ] Optional systemd behaviour is unchanged or deliberately updated.
- [ ] No password, private key or registry credential is included.
- [ ] Supported tags and lifecycle metadata remain accurate.

## Validation

- [ ] `./scripts/static-checks.sh`
- [ ] Affected amd64 contract tests
- [ ] Affected arm64 contract tests
- [ ] Second Ansible run reports `changed=0`
