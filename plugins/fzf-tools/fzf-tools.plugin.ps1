# fzf-tools plugin for poshix
# Fuzzy-finding wrappers using fzf (https://github.com/junegunn/fzf)
#
# fzf must be installed separately: https://github.com/junegunn/fzf#installation
#
# Installation:
#   winget install --id junegunn.fzf
#   # or
#   scoop install fzf
#   # or
#   choco install fzf
#   # or (macOS/Linux)
#   brew install fzf

function Test-FzfAvailable {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning "[poshix] fzf is not available in PATH. Install it from https://github.com/junegunn/fzf"
        return $false
    }
    return $true
}

function Find-FzfHistory {
    <#
    .SYNOPSIS
    Fuzzy search through PowerShell command history.
    .DESCRIPTION
    Presents a deduplicated list of history entries in fzf. The selected
    command is copied to the clipboard and inserted into the readline buffer.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-FzfAvailable)) { return }

    Write-Verbose "[poshix] Launching fzf history search"
    try {
        $entries = Get-History | Select-Object -ExpandProperty CommandLine
        $unique  = $entries | Sort-Object -Unique

        $result = $unique | & fzf --height 40% --reverse --border --prompt "History> "

        if ($result) {
            Set-Clipboard -Value $result
            try {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
            } catch {
                Write-Host $result
            }
        }
    } catch {
        Write-Warning "[poshix] Find-FzfHistory error: $_"
    }
}

function Find-FzfFile {
    <#
    .SYNOPSIS
    Fuzzy search for files under a directory.
    .DESCRIPTION
    Recursively lists files and presents them in fzf with a cat preview.
    The selected path is returned to the pipeline and inserted into the
    readline buffer.
    .PARAMETER Path
    Root directory to search. Defaults to the current directory.
    .PARAMETER Filter
    Optional glob pattern passed to Get-ChildItem -Filter.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.',

        [Parameter()]
        [string]$Filter
    )

    if (-not (Test-FzfAvailable)) { return }

    Write-Verbose "[poshix] Launching fzf file search under '$Path'"
    try {
        $gciArgs = @{ Path = $Path; Recurse = $true; File = $true; ErrorAction = 'SilentlyContinue' }
        if ($Filter) { $gciArgs['Filter'] = $Filter }

        $result = Get-ChildItem @gciArgs |
            Select-Object -ExpandProperty FullName |
            & fzf --height 40% --reverse --border --prompt "Files> " --preview "cat {}"

        if ($result) {
            try {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
            } catch {
                # PSConsoleReadLine not available; silent fallback
            }
            return $result
        }
    } catch {
        Write-Warning "[poshix] Find-FzfFile error: $_"
    }
}

function Find-FzfBranch {
    <#
    .SYNOPSIS
    Fuzzy search git branches and check out the selected one.
    .DESCRIPTION
    Lists all local and remote branches in fzf. The selected branch is
    checked out; remote-tracking prefixes are stripped automatically.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-FzfAvailable)) { return }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "[poshix] git is not available in PATH"
        return
    }

    $null = & git rev-parse --git-dir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[poshix] Not inside a git repository"
        return
    }

    Write-Verbose "[poshix] Launching fzf branch search"
    try {
        $branches = & git branch --all 2>&1 |
            ForEach-Object { $_ -replace '^\*?\s+', '' } |
            Where-Object { $_ -ne '' }

        $result = $branches | & fzf --height 40% --reverse --border --prompt "Branch> "

        if ($result) {
            $branch = $result -replace '^remotes/origin/', ''
            Write-Verbose "[poshix] Checking out branch '$branch'"
            & git checkout $branch
        }
    } catch {
        Write-Warning "[poshix] Find-FzfBranch error: $_"
    }
}

function Find-FzfProcess {
    <#
    .SYNOPSIS
    Fuzzy search running processes and kill the selected ones.
    .DESCRIPTION
    Lists processes sorted by CPU usage in fzf (multi-select). After
    selection, asks for confirmation before stopping the chosen processes.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-FzfAvailable)) { return }

    Write-Verbose "[poshix] Launching fzf process search"
    try {
        $processes = Get-Process | Sort-Object CPU -Descending

        $lines = $processes | ForEach-Object {
            $cpu = if ($_.CPU) { [math]::Round($_.CPU, 1) } else { 0 }
            '{0,-8} {1,-30} CPU:{2}s' -f $_.Id, $_.ProcessName, $cpu
        }

        $selected = $lines | & fzf --height 60% --reverse --border --prompt "Process> " --multi

        if (-not $selected) { return }

        $targets = @($selected) | ForEach-Object {
            $parts = $_ -split '\s+', 2
            [int]$parts[0]
        }

        $confirm = Read-Host "Kill $($targets.Count) process(es)? [y/N]"
        if ($confirm -match '^[Yy]') {
            foreach ($pid in $targets) {
                try {
                    Stop-Process -Id $pid -Force -ErrorAction Stop
                    Write-Host "Killed process $pid" -ForegroundColor Green
                } catch {
                    Write-Warning "[poshix] Could not kill process $pid`: $_"
                }
            }
        }
    } catch {
        Write-Warning "[poshix] Find-FzfProcess error: $_"
    }
}

# Export functions to global scope
Set-Item -Path "function:global:Test-FzfAvailable"  -Value ${function:Test-FzfAvailable}
Set-Item -Path "function:global:Find-FzfHistory"    -Value ${function:Find-FzfHistory}
Set-Item -Path "function:global:Find-FzfFile"       -Value ${function:Find-FzfFile}
Set-Item -Path "function:global:Find-FzfBranch"     -Value ${function:Find-FzfBranch}
Set-Item -Path "function:global:Find-FzfProcess"    -Value ${function:Find-FzfProcess}

# Export aliases to global scope
Set-Alias -Name fh -Value Find-FzfHistory -Scope Global
Set-Alias -Name ff -Value Find-FzfFile    -Scope Global
Set-Alias -Name fb -Value Find-FzfBranch  -Scope Global
Set-Alias -Name fp -Value Find-FzfProcess -Scope Global

Write-Verbose "[poshix] fzf-tools plugin loaded"
