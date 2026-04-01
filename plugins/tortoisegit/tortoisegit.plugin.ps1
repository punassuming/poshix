# tortoisegit plugin for poshix
# Helper commands for opening TortoiseGit dialogs

function Get-TortoiseGitCommand {
    $cmd = Get-Command 'TortoiseGitProc.exe' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $defaultPaths = @(
        'C:\Program Files\TortoiseGit\bin\TortoiseGitProc.exe',
        'C:\Program Files (x86)\TortoiseGit\bin\TortoiseGitProc.exe'
    )
    foreach ($path in $defaultPaths) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

function Test-TortoiseGitAvailable {
    if (-not (Get-TortoiseGitCommand)) {
        Write-Warning "[poshix] TortoiseGitProc.exe is not available. Install TortoiseGit or add it to PATH."
        return $false
    }
    return $true
}

function Invoke-TortoiseGit {
    <#
    .SYNOPSIS
    Open a TortoiseGit command dialog for a path without blocking the terminal.
    .PARAMETER Command
    TortoiseGit command to run (log, commit, pull, push, etc.).
    .PARAMETER Path
    Target file or directory path. Defaults to the current directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('log', 'commit', 'pull', 'push', 'fetch', 'rebase', 'switch', 'merge', 'diff', 'blame', 'repobrowser')]
        [string]$Command = 'log',

        [Parameter(Position = 1)]
        [string]$Path = '.'
    )

    if (-not (Test-TortoiseGitAvailable)) { return }
    if (-not (Test-Path $Path)) {
        Write-Warning "[poshix] Path not found: $Path"
        return
    }

    $tgit = Get-TortoiseGitCommand
    $targetPath = (Resolve-Path $Path).Path
    Start-Process -FilePath $tgit -ArgumentList "/command:$Command", "/path:$targetPath"
}

function Invoke-TortoiseGitDiff {
    <#
    .SYNOPSIS
    Open the TortoiseGit diff tool without blocking the terminal.
    .DESCRIPTION
    Launches the TortoiseGit visual diff tool for a file. Supports comparing
    two arbitrary files, a file against a specific revision, or a range of
    revisions. When no revision parameters are supplied the working-copy diff
    for the given path is shown.
    .PARAMETER Path
    File or directory to diff. Defaults to the current directory.
    .PARAMETER Path2
    Second file to compare directly against Path (file-vs-file diff).
    .PARAMETER StartRevision
    Starting git revision for the comparison (e.g. HEAD~1, a commit SHA).
    .PARAMETER EndRevision
    Ending git revision for the comparison (e.g. HEAD).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',

        [Parameter()]
        [string]$Path2,

        [Parameter()]
        [string]$StartRevision,

        [Parameter()]
        [string]$EndRevision
    )

    if (-not (Test-TortoiseGitAvailable)) { return }
    if (-not (Test-Path $Path)) {
        Write-Warning "[poshix] Path not found: $Path"
        return
    }

    $tgit = Get-TortoiseGitCommand
    $targetPath = (Resolve-Path $Path).Path
    $argList = @("/command:diff", "/path:$targetPath")

    if ($Path2) {
        if (-not (Test-Path $Path2)) {
            Write-Warning "[poshix] Path2 not found: $Path2"
            return
        }
        $targetPath2 = (Resolve-Path $Path2).Path
        $argList += "/path2:$targetPath2"
    }

    if ($StartRevision) { $argList += "/startrev:$StartRevision" }
    if ($EndRevision)   { $argList += "/endrev:$EndRevision" }

    Start-Process -FilePath $tgit -ArgumentList $argList
}

# Export functions to global scope
Set-Item -Path "function:global:Get-TortoiseGitCommand"    -Value ${function:Get-TortoiseGitCommand}
Set-Item -Path "function:global:Test-TortoiseGitAvailable" -Value ${function:Test-TortoiseGitAvailable}
Set-Item -Path "function:global:Invoke-TortoiseGit"        -Value ${function:Invoke-TortoiseGit}
Set-Item -Path "function:global:Invoke-TortoiseGitDiff"    -Value ${function:Invoke-TortoiseGitDiff}

# Export aliases to global scope
Set-Alias -Name tgit     -Value Invoke-TortoiseGit     -Scope Global
Set-Alias -Name tgitdiff -Value Invoke-TortoiseGitDiff -Scope Global

Write-Verbose "[poshix] tortoisegit plugin loaded"
