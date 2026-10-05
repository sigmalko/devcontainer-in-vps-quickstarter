[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectDir = $PSScriptRoot
$sshDir = Join-Path $projectDir '.ssh'
$clientPrivateKey = Join-Path $sshDir 'id_ed25519'
$hostPrivateKey = Join-Path $sshDir 'ssh_host_ed25519_key'
$authorizedKeysFile = Join-Path $projectDir '.devcontainer\authorized_keys'
$envFile = Join-Path $projectDir '.devcontainer\.env'
$envExampleFile = Join-Path $projectDir '.devcontainer\.env.example'
$currentUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

function Set-PrivateKeyAcl {
    param([Parameter(Mandatory)][string]$Path)

    # Windows OpenSSH refuses a private key readable by other accounts. Unlike
    # POSIX chmod, this has to be expressed as a restrictive Windows ACL.
    # icacls deliberately avoids writing the audit ACL, which would require
    # the SeSecurityPrivilege unavailable to an ordinary user.
    & icacls.exe $Path /inheritance:r /grant:r "$($currentUserName):(F)" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not restrict access to private key $Path."
    }
}

function Ensure-SshKeyPair {
    param(
        [Parameter(Mandatory)][string]$PrivateKey,
        [Parameter(Mandatory)][string]$Comment
    )

    $publicKey = "$PrivateKey.pub"
    if (-not (Test-Path -LiteralPath $PrivateKey -PathType Leaf)) {
        if (Test-Path -LiteralPath $publicKey -PathType Leaf) {
            throw "Cannot generate $PrivateKey because $publicKey already exists."
        }

        & ssh-keygen.exe -t ed25519 -f $PrivateKey -N '' -C $Comment
        if ($LASTEXITCODE -ne 0) {
            throw "ssh-keygen failed while creating $PrivateKey."
        }
    }
    elseif (-not (Test-Path -LiteralPath $publicKey -PathType Leaf)) {
        $publicKeyContent = & ssh-keygen.exe -y -f $PrivateKey
        if ($LASTEXITCODE -ne 0) {
            throw "ssh-keygen failed while deriving $publicKey."
        }
        [System.IO.File]::WriteAllText($publicKey, "$publicKeyContent`n", [System.Text.Encoding]::ASCII)
    }

    Set-PrivateKeyAcl -Path $PrivateKey
}

Assert-Command -Name 'docker'
Assert-Command -Name 'devcontainer'
Assert-Command -Name 'ssh-keygen.exe'

& docker version --format '{{.Server.Version}}' | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Desktop is not running or its Docker Engine is unavailable.'
}

& docker compose version | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Compose v2 is unavailable.'
}

if (-not (Test-Path -LiteralPath $envFile -PathType Leaf)) {
    if (-not (Test-Path -LiteralPath $envExampleFile -PathType Leaf)) {
        throw "Missing both $envFile and its template $envExampleFile."
    }
    Copy-Item -LiteralPath $envExampleFile -Destination $envFile
    Write-Host 'Created .devcontainer/.env from .env.example.'
}

New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
Ensure-SshKeyPair -PrivateKey $clientPrivateKey -Comment 'devcontainer-in-vps-client'
Ensure-SshKeyPair -PrivateKey $hostPrivateKey -Comment 'devcontainer-in-vps-host'

# Only the public client key enters the Docker build context.
Copy-Item -LiteralPath "$clientPrivateKey.pub" -Destination $authorizedKeysFile -Force

Push-Location $projectDir
try {
    & devcontainer up `
        --remove-existing-container `
        --workspace-folder $projectDir `
        --config (Join-Path $projectDir '.devcontainer\devcontainer.json')
    if ($LASTEXITCODE -ne 0) {
        throw "devcontainer up failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
