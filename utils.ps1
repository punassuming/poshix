
# Return human readable size of file object
Function hfs() {
  Param ($file)
  if($file -is [System.IO.FileInfo]) {
    switch($file.length) {
      {$_ -gt 1tb}
      { "{0:n1} T " -f ($_ / 1TB); continue }
      {$_ -gt 1gb}
      { "{0:n1} G " -f ($_ / 1GB); continue }
      {$_ -gt 1mb}
      { "{0:n1} M " -f ($_ / 1MB); continue }
      {$_ -gt 1kb}
      { "{0:n1} K " -f ($_ / 1KB); continue }
      default
      { "{0:n1} B " -f $_ }
    }
  } elseif ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { #links
    "<SYMLINK> "
  } else { #directory
    "<DIR> "
  }
}

function dbg ($Message, [Diagnostics.Stopwatch]$Stopwatch) {
  if($Stopwatch) {
    Write-Verbose ('{0:00000}:{1}' -f $Stopwatch.ElapsedMilliseconds,$Message) -Verbose # -ForegroundColor Yellow
  }
}


function junctions()
{
  # Check if we're on Windows before using cmd.exe
  # Use $IsWindows which is available in PowerShell Core 6+
  $isWindowsOS = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }
  
  if ($isWindowsOS) {
    $file_target = @(cmd.exe /c dir /A:L) 2> $null
    if ($file_target.length -gt 6) {
      $links = $file_target[5..($file_target.length-3)]
      $link_targets = @()
      foreach ($link in $links)
      {
        $regex_pat = ".*>\s+(.+) \[(.+)\]"
        $match = [regex]::Match($link, $regex_pat); if (-not $match.Success) { continue }; $pair = @($match.Groups[1].Value, $match.Groups[2].Value)
        $link_targets += @(,$pair)
      }
      return $link_targets
    }
  }
  # On non-Windows systems, return empty array
  return @()
}

function Get-PoshixKnownCommandPaths {
  param([Parameter(Mandatory)][string]$Name)

  $userProfile = $env:USERPROFILE
  $localAppData = $env:LOCALAPPDATA
  $programFiles = ${env:ProgramFiles}
  $candidates = @()
  switch ($Name.ToLowerInvariant()) {
    'docker' {
      if ($programFiles) { $candidates += Join-Path $programFiles 'Docker\Docker\resources\bin\docker.exe' }
      $candidates += 'C:\ProgramData\DockerDesktop\version-bin\docker.exe'
      if ($localAppData) { $candidates += Join-Path $localAppData 'Docker\Docker\resources\bin\docker.exe' }
    }
    'kubectl' {
      if ($userProfile) { $candidates += Join-Path $userProfile 'scoop\shims\kubectl.exe' }
      if ($programFiles) { $candidates += Join-Path $programFiles 'Kubernetes\kubectl.exe' }
    }
    'wt' { if ($localAppData) { $candidates += @(Join-Path $localAppData 'Microsoft\WindowsApps\wt.exe') } }
  }
  return @($candidates | Where-Object { $_ })
}

function Resolve-PoshixCommand {
  <#
  .SYNOPSIS
  Resolve a command with evidence suitable for constrained shells and agents.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)][string[]]$Name,
    [string]$Distribution
  )

  foreach ($requestedName in $Name) {
    $normalizedName = $requestedName -replace '\.exe$', ''
    $candidates = [System.Collections.Generic.List[object]]::new()
    $resolved = Get-Command $requestedName, "$normalizedName.exe" -CommandType Application -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($resolved) {
      $candidates.Add([PSCustomObject]@{ Source = 'PATH'; Path = $resolved.Source; Exists = $true })
    }

    $scoopPath = if ($env:USERPROFILE) { Join-Path $env:USERPROFILE "scoop\shims\$normalizedName.exe" } else { $null }
    foreach ($candidatePath in @($scoopPath) + @(Get-PoshixKnownCommandPaths $normalizedName)) {
      if ($candidatePath -and (Test-Path -LiteralPath $candidatePath -PathType Leaf -ErrorAction SilentlyContinue)) {
        $candidates.Add([PSCustomObject]@{ Source = if ($candidatePath -eq $scoopPath) { 'Scoop' } else { 'KnownPath' }; Path = $candidatePath; Exists = $true })
      }
    }

    if ($PSVersionTable.PSVersion.Major -ge 5 -and $env:OS -eq 'Windows_NT') {
      foreach ($registryPath in @("HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\$normalizedName.exe", "HKLM:\Software\Microsoft\Windows\CurrentVersion\App Paths\$normalizedName.exe")) {
        try {
          $appPath = (Get-ItemProperty -Path $registryPath -ErrorAction Stop).'(default)'
          if ($appPath -and (Test-Path -LiteralPath $appPath -PathType Leaf)) {
            $candidates.Add([PSCustomObject]@{ Source = 'AppPaths'; Path = $appPath; Exists = $true })
          }
        } catch { }
      }
    }

    $uniqueCandidates = @($candidates | Group-Object Path | ForEach-Object { $_.Group[0] })
    $commandPath = if ($uniqueCandidates.Count) { $uniqueCandidates[0].Path } else { $null }
    $status = if ($commandPath) { 'Available' } else { 'NotFound' }
    $reason = if ($commandPath) { $null } else { "'$normalizedName' was not found in PATH, Scoop, App Paths, or known installation locations." }
    $remediation = if ($commandPath) { $null } else { "Install $normalizedName or expose its executable to this process through PATH." }

    [PSCustomObject]@{
      Name = $normalizedName
      Status = $status
      Command = $commandPath
      Candidates = $uniqueCandidates
      Reason = $reason
      Remediation = $remediation
      Distribution = $Distribution
    }
  }
}

function Get-PoshixRuntimeReport {
  <#
  .SYNOPSIS
  Report command, WSL, Docker, and terminal availability without modifying the session.
  #>
  [CmdletBinding()]
  param([switch]$AsJson, [string]$Distribution)

  $commands = @(Resolve-PoshixCommand -Name @('docker', 'kubectl', 'wsl', 'wt', 'git', 'pwsh') -Distribution $Distribution)
  $wsl = $commands | Where-Object Name -eq 'wsl' | Select-Object -First 1
  $wslStatus = [PSCustomObject]@{ Available = $false; Status = 'NotFound'; Reason = $wsl.Reason; Output = @() }
  if ($wsl.Command) {
    $output = & $wsl.Command --status 2>&1
    $exitCode = $LASTEXITCODE
    $outputText = (($output -join ' ') -replace "`0", '').Trim()
    $wslStatus = [PSCustomObject]@{
      Available = $exitCode -eq 0
      Status = if ($exitCode -eq 0) { 'Available' } elseif ($outputText -match 'ACCESS_DENIED|Access is denied') { 'AccessDenied' } else { 'Unavailable' }
      Reason = if ($exitCode -eq 0) { $null } else { $outputText }
      Output = @($output | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ })
    }
  }

  $dockerHealth = $null
  if (Get-Command Resolve-PoshixDockerBackend -ErrorAction SilentlyContinue) {
    $dockerHealth = Resolve-PoshixDockerBackend
  }
  $report = [PSCustomObject]@{
    GeneratedAt = (Get-Date).ToUniversalTime().ToString('o')
    Host = $Host.Name
    IsInteractive = -not [Console]::IsInputRedirected
    Term = $env:TERM
    Commands = $commands
    Wsl = $wslStatus
    Docker = $dockerHealth
  }
  if ($AsJson) { return $report | ConvertTo-Json -Depth 8 }
  return $report
}
