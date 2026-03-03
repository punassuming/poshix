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
    Open a TortoiseGit command dialog for a path.
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
    & $tgit "/command:$Command" "/path:$targetPath"
}

# Export functions to global scope
Set-Item -Path "function:global:Get-TortoiseGitCommand"   -Value ${function:Get-TortoiseGitCommand}
Set-Item -Path "function:global:Test-TortoiseGitAvailable" -Value ${function:Test-TortoiseGitAvailable}
Set-Item -Path "function:global:Invoke-TortoiseGit"        -Value ${function:Invoke-TortoiseGit}

# Export aliases to global scope
Set-Alias -Name tgit -Value Invoke-TortoiseGit -Scope Global

Write-Verbose "[poshix] tortoisegit plugin loaded"
