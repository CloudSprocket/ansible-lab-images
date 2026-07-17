param(
    [switch]$Apply,
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Get-Content -Path (Join-Path $repoRoot 'VERSION') -Raw).Trim()
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version '$Version' is not a semantic major.minor.patch value."
}

$namespace = 'cloudsprocket'
$server = 'https://index.docker.io/v1/'
$credentialJson = $server | & docker-credential-desktop.exe get
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Desktop did not return Docker Hub credentials.'
}

$credential = $credentialJson | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($credential.Username) -or [string]::IsNullOrWhiteSpace($credential.Secret)) {
    throw 'The Docker Hub credential is incomplete.'
}

$tokenRequest = @{
    identifier = $credential.Username
    secret = $credential.Secret
} | ConvertTo-Json

$tokenResponse = Invoke-RestMethod `
    -Method Post `
    -Uri 'https://hub.docker.com/v2/auth/token' `
    -ContentType 'application/json' `
    -Body $tokenRequest

if ([string]::IsNullOrWhiteSpace($tokenResponse.access_token)) {
    throw 'Docker Hub authentication did not return an access token.'
}

$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }

$overviewTemplate = @'
# Ansible lab node: __TITLE__

Multi-architecture managed-node image for repeatable Ansible labs and CI.

## Supported platforms

- `linux/amd64`
- `linux/arm64`

## Tags

- `latest`: current supported release
- `__VERSION__`: immutable release

## Use

```console
docker pull cloudsprocket/__NAME__:__VERSION__
```

Safe, key-only SSH is the default. Privileged systemd mode is opt-in through the Compose systemd overlay in the source repository.

Source, Compose lab, documentation and release notes: https://github.com/CloudSprocket/ansible-lab-images
'@

$distributions = @(
    @{ Name = 'ansible-node-ubuntu-2404'; Title = 'Ubuntu 24.04' }
    @{ Name = 'ansible-node-debian-13'; Title = 'Debian 13' }
    @{ Name = 'ansible-node-rocky-9'; Title = 'Rocky Linux 9' }
    @{ Name = 'ansible-node-rocky-10'; Title = 'Rocky Linux 10' }
)

$repositories = @(
    foreach ($distribution in $distributions) {
        @{
            Name = $distribution.Name
            Description = "$($distribution.Title) managed node for multi-architecture Ansible labs and CI."
            Overview = $overviewTemplate.Replace('__TITLE__', $distribution.Title).Replace('__NAME__', $distribution.Name).Replace('__VERSION__', $Version)
        }
    }
    @{
        Name = 'ansible-node'
        Description = 'Deprecated: use the distribution-specific cloudsprocket/ansible-node-* repositories.'
        Overview = @'
# Deprecated combined repository

This repository is retained so existing v0.1.0 users can continue to pull its images. No new releases will be published here.

Use the distribution-specific repositories for v0.2.0 and later:

- `cloudsprocket/ansible-node-ubuntu-2404`
- `cloudsprocket/ansible-node-debian-13`
- `cloudsprocket/ansible-node-rocky-9`
- `cloudsprocket/ansible-node-rocky-10`

The new layout keeps the repository name focused on the operating system and uses tags only for release versions, such as `0.2.0` and `latest`.

Migration guidance and release notes: https://github.com/CloudSprocket/ansible-lab-images
'@
    }
)

foreach ($repository in $repositories) {
    if ($repository.Description.Length -gt 100) {
        throw "Description for $($repository.Name) exceeds Docker Hub's 100-character limit."
    }

    $payload = @{
        description = $repository.Description
        full_description = $repository.Overview.Trim()
    } | ConvertTo-Json

    $uri = "https://hub.docker.com/v2/repositories/$namespace/$($repository.Name)/"
    if ($Apply) {
        $null = Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -ContentType 'application/json' -Body $payload
    }

    $current = Invoke-RestMethod -Method Get -Uri $uri
    [pscustomobject]@{
        repository = "$namespace/$($repository.Name)"
        applied = [bool]$Apply
        public = -not [bool]$current.is_private
        status = $current.status_description
        description = $current.description
        overview_length = ([string]$current.full_description).Length
    }
}
