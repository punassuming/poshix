<# .SYNOPSIS Stage a deterministic local Poshix release archive and SHA256 checksum. #>
[CmdletBinding()]
param([string]$OutputPath = (Join-Path $PSScriptRoot '..\dist'))

$root = Split-Path $PSScriptRoot -Parent
$resolvedOutputPath=[IO.Path]::GetFullPath($OutputPath).TrimEnd('\','/')
$manifest = Import-PowerShellDataFile -Path (Join-Path $root 'Poshix.psd1')
$versionInfo = Get-Content -LiteralPath (Join-Path $root 'version.json') -Raw | ConvertFrom-Json
if ($manifest.ModuleVersion -ne $versionInfo.version) { throw "Manifest version $($manifest.ModuleVersion) does not match version.json $($versionInfo.version)." }
$releaseName = "Poshix-$($manifest.ModuleVersion)"
$stageRoot = Join-Path $OutputPath $releaseName
$zipPath = Join-Path $OutputPath "$releaseName.zip"
if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null
$exclude = @('.git', '.github', '.agents', '.codex', 'dist')
Get-ChildItem -LiteralPath $root -File -Recurse -Force | Where-Object {
    $relative=$_.FullName.Substring($root.Length).TrimStart('\','/')
    $segments=$relative -split '[\\/]'
    -not $_.FullName.StartsWith($resolvedOutputPath+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and -not ($segments | Where-Object { $_ -in $exclude }) -and $_.Name -ne 'appveyor.yml' -and $_.Name -notmatch '\.1(\.|$)'
} | ForEach-Object {
    $relative=$_.FullName.Substring($root.Length).TrimStart('\','/')
    $destination=Join-Path $stageRoot $relative
    $destinationDirectory=Split-Path -Parent $destination
    if(-not(Test-Path -LiteralPath $destinationDirectory)){New-Item -ItemType Directory -Path $destinationDirectory -Force|Out-Null}
    Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
}
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path $stageRoot -DestinationPath $zipPath -Force
$hash = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
Set-Content -LiteralPath "$zipPath.sha256" -Value "$($hash.Hash)  $([IO.Path]::GetFileName($zipPath))" -Encoding ascii
[PSCustomObject]@{ Version = $manifest.ModuleVersion; Archive = $zipPath; Sha256 = $hash.Hash }
