# Release process

## Repository configuration

Create a protected GitHub environment named `dockerhub` with required reviewer
approval. Add these environment secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`, using a scoped access token rather than an account password

The following public Docker Hub repositories must exist before a release:

- `cloudsprocket/ansible-node-ubuntu-2404`
- `cloudsprocket/ansible-node-debian-13`
- `cloudsprocket/ansible-node-rocky-9`
- `cloudsprocket/ansible-node-rocky-10`

## Release requirements

1. Update `VERSION` to the intended `major.minor.patch` value.
2. Confirm the support matrix and base digests are current.
3. Require green native amd64 and arm64 contracts for the exact commit.
4. Review vulnerability results and resolve every fixable high or critical
   finding. Any exception must be time-limited and documented in release notes.
5. Trigger the Release workflow with a signed `v<version>` tag or its approved
   manual input.

## What the workflow publishes

For each distribution repository, the workflow creates:

- a moving `latest` tag;
- an immutable semantic-version tag;
- amd64 and arm64 manifests;
- BuildKit SBOM and maximum provenance attestations.

The workflow then verifies platform manifests, confirms `latest` and the
immutable version share a digest in every repository, and creates a GitHub
release.

## Rollback

An affected repository's `latest` tag can be restored to a previously verified
immutable manifest. Never overwrite or delete a versioned release tag. Record
the reason and restored digest in a GitHub release note and security advisory
when applicable.
