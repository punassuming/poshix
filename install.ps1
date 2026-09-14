<#
.SYNOPSIS
Install Poshix from PowerShell Gallery or from a verified release ZIP.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [ValidateSet('Gallery', 'Zip')][string]$Source = 'Gallery',
    [string]$ZipPath,
    [string]$ExpectedSha256,
    [switch]$AddToProfile,
    [switch]$Force
)

if ($Source -eq 'Gallery') {
    if ($PSCmdlet.ShouldProcess('Poshix', 'Install from PowerShell Gallery for CurrentUser')) {
        Install-Module -Name Poshix -Repository PSGallery -Scope CurrentUser -Force:$Force
    }
} else {
    if (-not $ZipPath -or -not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) { throw 'ZipPath must point to a local Poshix release archive.' }
    if ($ExpectedSha256) {
        $actualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash
        if ($actualHash -ne $ExpectedSha256.ToUpperInvariant()) { throw "SHA256 verification failed for $ZipPath." }
    }
    $documents = [Environment]::GetFolderPath('MyDocuments')
    $modulePath = Join-Path $documents 'PowerShell\Modules\Poshix'
    if ($PSCmdlet.ShouldProcess($modulePath, "Extract verified Poshix release '$ZipPath'")) {
        $temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) ("poshix-" + [guid]::NewGuid().ToString('N'))
        try {
            Expand-Archive -LiteralPath $ZipPath -DestinationPath $temporaryPath -Force
            $moduleSource = Get-ChildItem -LiteralPath $temporaryPath -Directory | Select-Object -First 1
            if (-not $moduleSource -or -not (Test-Path -LiteralPath (Join-Path $moduleSource.FullName 'Poshix.psd1'))) { throw 'Archive does not contain a Poshix module root.' }
            New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
            Copy-Item -Path (Join-Path $moduleSource.FullName '*') -Destination $modulePath -Recurse -Force
        } finally {
            if (Test-Path -LiteralPath $temporaryPath) { Remove-Item -LiteralPath $temporaryPath -Recurse -Force }
        }
    }
}

if ($AddToProfile -and $PSCmdlet.ShouldProcess($PROFILE, 'Add Poshix import to PowerShell profile')) {
    $profileDirectory = Split-Path -Parent $PROFILE
    if (-not (Test-Path -LiteralPath $profileDirectory)) { New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null }
    $line = 'Import-Module Poshix'
    if (-not (Test-Path -LiteralPath $PROFILE) -or -not (Select-String -LiteralPath $PROFILE -SimpleMatch $line -Quiet)) { Add-Content -LiteralPath $PROFILE -Value $line }
}
