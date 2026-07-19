# Changelog

All notable changes are documented here.

## Unreleased

## 0.3.1 - 2026-07-18

### Fixed

- Restored the controller tool PATH in login shells. `bash -l`, `su -` and
  login-shell CI runners reported `ansible: command not found` because
  `/etc/profile` resets the PATH prefix set by `ENV`.

### Added

- Added a controller image contract covering both shell forms, the pinned
  collections and the unprivileged account.

## 0.3.0 - 2026-07-17

### Added

- Published `cloudsprocket/ansible-controller`, a control-node image with
  ansible-core 2.21.2, ansible-lint 26.6.0 and the `community.general` and
  `ansible.posix` collections.
- Added a `tools` profile controller service to the Compose lab with automatic
  lab-key installation.

### Changed

- Converged the CI contract controller onto the published controller image and
  added it to the vulnerability gate.
- Allowed the systemd contract to run on hosts without AppArmor, such as
  Docker Desktop.
- Tracked the Docker Hub metadata script in `scripts/` and derived its tag
  references from `VERSION`.
- Documented the release-pin update and the Docker Hub description refresh in
  the release process.
- Made the OCI title and description labels distribution-specific.

## 0.2.0 - 2026-07-17

### Changed

- Split each supported distribution into its own Docker Hub repository.
- Reduced published tags to `latest` and an immutable semantic version.
- Removed commit-scoped candidate publishing to keep public repositories clean.
- Added a pinned Compose overlay for running published images without a local build.

## 0.1.0 - 2026-07-17

### Added

- Ubuntu 24.04, Debian 13, Rocky Linux 9 and Rocky Linux 10 managed nodes.
- Native amd64 and arm64 contract testing.
- Unprivileged SSH and optional privileged systemd modes.
- Digest-pinned bases, vulnerability checks, SBOMs and provenance automation.
