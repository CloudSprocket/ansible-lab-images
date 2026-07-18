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
- `cloudsprocket/ansible-controller`

## Release requirements

1. Update `VERSION` to the intended `major.minor.patch` value.
2. Update the pinned image tags in `compose.release.yml` to the same value.
   The static checks fail when the pins and `VERSION` disagree.
3. Confirm the support matrix and base digests are current.
4. Require green native amd64 and arm64 contracts for the exact commit.
5. Review vulnerability results and resolve every fixable high or critical
   finding. Any exception must be time-limited and documented in release notes.
6. Trigger the Release workflow with a signed `v<version>` tag or its approved
   manual input.

## What the workflow publishes

For each image repository, the workflow creates:

- a moving `latest` tag;
- an immutable semantic-version tag;
- amd64 and arm64 manifests;
- BuildKit SBOM and maximum provenance attestations.

The workflow then verifies platform manifests, confirms `latest` and the
immutable version share a digest in every repository, and creates a GitHub
release.

## After the workflow succeeds

Refresh the Docker Hub short descriptions and overviews so they reference the
new immutable tag:

```powershell
.\scripts\update-dockerhub-metadata.ps1 -Apply
```

The script reads `VERSION` and `support-matrix.json`, authenticates with the
Docker Hub credentials held by Docker Desktop and updates the four
distribution repositories, the controller repository and the deprecated
combined repository. Run it without `-Apply` to preview the current state
first.

## Rollback

An affected repository's `latest` tag can be restored to a previously verified
immutable manifest. Never overwrite or delete a versioned release tag. Record
the reason and restored digest in a GitHub release note and security advisory
when applicable.
