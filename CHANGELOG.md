# Changelog

All notable changes are documented here.

## Unreleased

### Changed

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
