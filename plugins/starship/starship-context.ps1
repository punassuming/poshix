# Low-latency session context exported for Starship env_var modules.

$script:PoshixStarshipContextState = @{
    Git = @{}
    Session = $null
    SessionInitialized = $false
}

function Get-PoshixStarshipSettings {
    $settings = @{
        ContextEnabled = $true
        Directory = $true
        DirectorySegments = 3
        GitDirty = $true
        GitDirtyCacheSeconds = 10
        SessionContext = $true
    }

    try {
        $config = Get-PoshixConfig
        if ($config -and $config.Starship) {
            foreach ($key in @($settings.Keys)) {
                if ($config.Starship.ContainsKey($key)) {
                    $settings[$key] = $config.Starship[$key]
                }
            }
        }
    } catch { }

    return $settings
}

function Get-PoshixStarshipDirectory {
    param(
        [string]$Path = (Get-Location).Path,
        [string]$HomePath = $(if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }),
        [int]$MaxSegments = 3
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $separator = [IO.Path]::DirectorySeparatorChar
    $alternateSeparator = [IO.Path]::AltDirectorySeparatorChar
    $normalizedPath = $Path.TrimEnd($separator, $alternateSeparator)
    $normalizedHome = if ($HomePath) { $HomePath.TrimEnd($separator, $alternateSeparator) } else { $null }

    if ($normalizedHome -and $normalizedPath.Equals($normalizedHome, [StringComparison]::OrdinalIgnoreCase)) {
        return '~'
    }

    $displayPath = $normalizedPath
    if ($normalizedHome -and $normalizedPath.StartsWith("$normalizedHome$separator", [StringComparison]::OrdinalIgnoreCase)) {
        $displayPath = $normalizedPath.Substring($normalizedHome.Length + 1)
    }

    if ($MaxSegments -gt 0) {
        $segments = @($displayPath -split '[\\/]' | Where-Object { $_ })
        if ($segments.Count -gt $MaxSegments) {
            $displayPath = ($segments[($segments.Count - $MaxSegments)..($segments.Count - 1)] -join $separator)
        }
    }

    return $displayPath
}

function Resolve-PoshixGitContext {
    param([Parameter(Mandatory)][string]$Path)

    try { $current = [IO.DirectoryInfo]::new((Resolve-Path -LiteralPath $Path).Path) } catch { return $null }
    while ($current) {
        $marker = Join-Path $current.FullName '.git'
        if (Test-Path -LiteralPath $marker -PathType Container) {
            $gitDirectory = $marker
        } elseif (Test-Path -LiteralPath $marker -PathType Leaf) {
            $pointer = Get-Content -LiteralPath $marker -Raw -ErrorAction SilentlyContinue
            if ($pointer -match '^gitdir:\s*(.+?)\s*$') {
                $gitDirectory = $Matches[1]
                if (-not [IO.Path]::IsPathRooted($gitDirectory)) {
                    $gitDirectory = [IO.Path]::GetFullPath((Join-Path $current.FullName $gitDirectory))
                }
            } else {
                $gitDirectory = $null
            }
        } else {
            $gitDirectory = $null
        }

        if ($gitDirectory) {
            $headPath = Join-Path $gitDirectory 'HEAD'
            $head = (Get-Content -LiteralPath $headPath -Raw -ErrorAction SilentlyContinue).Trim()
            if (-not $head) { return $null }
            $branch = if ($head -match '^ref:\s+refs/heads/(.+)$') { $Matches[1] } else { $head.Substring(0, [Math]::Min(8, $head.Length)) }
            return [PSCustomObject]@{
                Root = $current.FullName
                GitDirectory = $gitDirectory
                HeadPath = $headPath
                Branch = $branch
            }
        }
        $current = $current.Parent
    }
    return $null
}

function Start-PoshixCapturedProcess {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$WorkingDirectory
    )

    try {
        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $FileName
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        if ($WorkingDirectory) { $startInfo.WorkingDirectory = $WorkingDirectory }
        foreach ($argument in $Arguments) { [void]$startInfo.ArgumentList.Add($argument) }
        $process = [Diagnostics.Process]::Start($startInfo)
        return [PSCustomObject]@{
            Process = $process
            StandardOutput = $process.StandardOutput.ReadToEndAsync()
            StandardError = $process.StandardError.ReadToEndAsync()
        }
    } catch { return $null }
}

function Update-PoshixGitDirtyCache {
    param(
        [Parameter(Mandatory)]$GitContext,
        [Parameter(Mandatory)][int]$CacheSeconds,
        [switch]$Force
    )

    $key = $GitContext.Root.ToLowerInvariant()
    if (-not $script:PoshixStarshipContextState.Git.ContainsKey($key)) {
        $script:PoshixStarshipContextState.Git[$key] = @{ Dirty = $null; UpdatedAt = [datetime]::MinValue; Process = $null }
    }
    $entry = $script:PoshixStarshipContextState.Git[$key]

    if ($entry.Process -and $entry.Process.Process.HasExited) {
        try {
            $output = $entry.Process.StandardOutput.Result
            $entry.Dirty = $entry.Process.Process.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($output)
            $entry.UpdatedAt = Get-Date
        } catch {
            $entry.Dirty = $null
        } finally {
            try { $entry.Process.Process.Dispose() } catch { }
            $entry.Process = $null
        }
    }

    $stale = $Force -or ((Get-Date) - $entry.UpdatedAt).TotalSeconds -ge $CacheSeconds
    if ($stale -and -not $entry.Process) {
        $git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($git) {
            $entry.Process = Start-PoshixCapturedProcess -FileName $git.Source -WorkingDirectory $GitContext.Root -Arguments @(
                '-C', $GitContext.Root, 'status', '--porcelain=v1', '--untracked-files=normal'
            )
        }
    }

    return $entry.Dirty
}

function Get-PoshixStaticSessionContext {
    if ($script:PoshixStarshipContextState.SessionInitialized) { return $script:PoshixStarshipContextState.Session }
    $markers = @()
    $isAdmin = $false
    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        try {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = [Security.Principal.WindowsPrincipal]::new($identity)
            $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } catch { }
    } else {
        $isAdmin = [Environment]::UserName -eq 'root'
    }
    if ($isAdmin) { $markers += 'admin' }
    if ($env:WSL_DISTRO_NAME) { $markers += "wsl:$($env:WSL_DISTRO_NAME)" }
    if ($env:SSH_CONNECTION -or $env:SSH_CLIENT -or $env:SSH_TTY) { $markers += 'ssh' }
    $script:PoshixStarshipContextState.Session = $markers -join '/'
    $script:PoshixStarshipContextState.SessionInitialized = $true
    return $script:PoshixStarshipContextState.Session
}

function Get-PoshixStarshipContext {
    [CmdletBinding()]
    param([switch]$Refresh)

    $settings = Get-PoshixStarshipSettings
    $path = (Get-Location).Path
    $git = Resolve-PoshixGitContext -Path $path
    $dirty = if ($git -and $settings.GitDirty) {
        Update-PoshixGitDirtyCache -GitContext $git -CacheSeconds ([Math]::Max(1, [int]$settings.GitDirtyCacheSeconds)) -Force:$Refresh
    } else { $null }
    return [PSCustomObject][ordered]@{
        Path = $path
        Directory = if ($settings.Directory) {
            Get-PoshixStarshipDirectory -Path $path -MaxSegments ([Math]::Max(1, [int]$settings.DirectorySegments))
        } else { $null }
        GitRoot = if ($git) { $git.Root } else { $null }
        GitBranch = if ($git) { $git.Branch } else { $null }
        GitDirty = $dirty
        Session = if ($settings.SessionContext) { Get-PoshixStaticSessionContext } else { $null }
    }
}

function Set-PoshixProcessEnvironmentVariable {
    param([Parameter(Mandatory)][string]$Name, [AllowNull()][string]$Value)
    if ([string]::IsNullOrEmpty($Value)) {
        Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
    } else {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
    }
}

function Update-PoshixStarshipEnvironment {
    [CmdletBinding()]
    param([switch]$Force)

    $settings = Get-PoshixStarshipSettings
    if (-not $settings.ContextEnabled) {
        foreach ($name in @('POSHIX_DIRECTORY', 'POSHIX_GIT_BRANCH', 'POSHIX_GIT_DIRTY', 'POSHIX_SESSION')) {
            Set-PoshixProcessEnvironmentVariable -Name $name -Value $null
        }
        return
    }

    $context = Get-PoshixStarshipContext -Refresh:$Force
    Set-PoshixProcessEnvironmentVariable -Name 'POSHIX_DIRECTORY' -Value $context.Directory
    Set-PoshixProcessEnvironmentVariable -Name 'POSHIX_GIT_BRANCH' -Value $context.GitBranch
    Set-PoshixProcessEnvironmentVariable -Name 'POSHIX_GIT_DIRTY' -Value $(if ($context.GitDirty) { '*' } else { $null })
    Set-PoshixProcessEnvironmentVariable -Name 'POSHIX_SESSION' -Value $context.Session
}
