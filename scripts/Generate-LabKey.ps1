Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$keyDirectory = Join-Path $root ".lab\ssh"
$privateKey = Join-Path $keyDirectory "id_ed25519"
$publicKey = "$privateKey.pub"
$authorisedKeys = Join-Path $keyDirectory "authorized_keys"

New-Item -ItemType Directory -Force -Path $keyDirectory | Out-Null
if (-not (Test-Path -LiteralPath $privateKey)) {
    & ssh-keygen -q -t ed25519 -N "" -C "ansible-lab-images" -f $privateKey
    if ($LASTEXITCODE -ne 0) {
        throw "ssh-keygen failed with exit code $LASTEXITCODE."
    }
}

Copy-Item -Force -LiteralPath $publicKey -Destination $authorisedKeys
Write-Output "Lab key ready at .lab\ssh\id_ed25519"
