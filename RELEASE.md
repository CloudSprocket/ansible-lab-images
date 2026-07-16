# Release process

## Repository configuration

Create a protected GitHub environment named `dockerhub` with required reviewer
approval. Add these environment secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`, using a scoped access token rather than an account password

Set the repository variable `PUBLISH_CANDIDATES=true` only when main-branch
commit tags should be published automatically.

## Release requirements

1. Update `VERSION` to the intended `major.minor.patch` value.
2. Confirm the support matrix and base digests are current.
3. Require green native amd64 and arm64 contracts for the exact commit.
4. Review vulnerability results and resolve every fixable high or critical
   finding. Any exception must be time-limited and documented in release notes.
5. Trigger the Release workflow with a signed `v<version>` tag or its approved
   manual input.

## What the workflow publishes

For each distribution, the workflow creates:

- a moving distribution channel;
- an immutable distribution and semantic-version tag;
- an immutable distribution and commit tag;
- amd64 and arm64 manifests;
- BuildKit SBOM and maximum provenance attestations.

The workflow then verifies platform manifests, confirms the moving and
immutable tags share a digest, checks that no generic `latest` tag exists and
creates a GitHub release.

## Rollback

Moving tags can be restored to a previously verified immutable manifest. Never
overwrite or delete a versioned release tag. Record the reason and restored
digest in a GitHub release note and security advisory when applicable.
