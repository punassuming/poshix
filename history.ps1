# History management for poshix

function Get-PoshixHistory {
    <#
    .SYNOPSIS
    Get command history
    .DESCRIPTION
    Wrapper around Get-History with enhanced functionality
    .PARAMETER Count
    Number of history items to retrieve
    .PARAMETER Id
    Specific history ID to retrieve
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [int]$Count,
        [Parameter()]
        [long[]]$Id
    )
    
    if ($Id) {
        Get-History -Id $Id
    } elseif ($Count) {
        Get-History -Count $Count
    } else {
        Get-History
    }
}

function Invoke-PoshixHistory {
    <#
    .SYNOPSIS
    Invoke a command from history
    .PARAMETER Id
    History ID to invoke
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [long]$Id
    )
    
    Invoke-History -Id $Id
}

function Search-PoshixHistory {
    <#
    .SYNOPSIS
    Search command history
    .PARAMETER Pattern
    Pattern to search for in command history
    .PARAMETER Count
    Maximum number of results to return
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Pattern,
        [Parameter()]
        [int]$Count = 20
    )
    
    Get-History | Where-Object { $_.CommandLine -like "*$Pattern*" } | Select-Object -Last $Count
}

function Clear-PoshixHistory {
    <#
    .SYNOPSIS
    Clear command history
    #>
    Clear-History
    Write-Host "History cleared"
}

function Export-PoshixHistory {
    <#
    .SYNOPSIS
    Export history to file
    .PARAMETER Path
    Path to export history to
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Path
    )
    
    # Get path from config if not provided
    if (-not $Path) {
        try {
            $config = Get-PoshixConfig
            $Path = $config.History.SavePath
        } catch {
            Write-Warning "Failed to get config path, skipping history export"
            return
        }
    }
    
    try {
        Get-History | Export-Clixml -Path $Path
        Write-Verbose "History exported to $Path"
    } catch {
        Write-Warning "Failed to export history: $_"
    }
}

function Import-PoshixHistory {
    <#
    .SYNOPSIS
    Import history from file
    .PARAMETER Path
    Path to import history from
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Path
    )
    
    # Get path from config if not provided
    if (-not $Path) {
        try {
            $config = Get-PoshixConfig
            $Path = $config.History.SavePath
        } catch {
            Write-Warning "Failed to get config path, skipping history import"
            return
        }
    }
    
    if (Test-Path $Path) {
        try {
            $history = Import-Clixml -Path $Path
            foreach ($entry in $history) {
                Add-History -InputObject $entry
            }
            Write-Verbose "History imported from $Path"
        } catch {
            Write-Warning "Failed to import history: $_"
        }
    }
}

function Initialize-PoshixPSReadLineHistory {
    <#
    .SYNOPSIS
    Configure per-session PSReadLine history for multi-terminal support
    .DESCRIPTION
    Creates a per-session PSReadLine history file seeded from the shared history
    file. Because PSReadLine appends new commands to the end of its in-memory
    list, the session's own commands will always appear first on up-arrow while
    the full shared history remains accessible by scrolling further back.
    Call this once during module load, before the first prompt is rendered.
    #>
    if (-not (Get-Module PSReadLine -ErrorAction SilentlyContinue)) { return }

    $config = Get-PoshixConfig
    $sharedPath = if ($config.History.PSReadLinePath) {
        $config.History.PSReadLinePath
    } else {
        Join-Path $env:USERPROFILE '.poshix_psrl_history'
    }

    $pid = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $sessionPath = Join-Path ([System.IO.Path]::GetTempPath()) "poshix_psrl_${pid}.txt"

    # Seed the session file from shared history so old commands are reachable
    $baseLineCount = 0
    if (Test-Path $sharedPath) {
        Copy-Item $sharedPath $sessionPath -Force -ErrorAction SilentlyContinue
        $content = Get-Content $sharedPath -ErrorAction SilentlyContinue
        $baseLineCount = if ($content) { @($content).Count } else { 0 }
    }

    # Point PSReadLine at the session file before it loads history for the first time
    Set-PSReadLineOption -HistorySavePath $sessionPath -HistorySaveStyle SaveIncrementally

    $script:PoshixSharedPSRLPath = $sharedPath
    $script:PoshixSessionPSRLPath = $sessionPath
    $script:PoshixPSRLBaseLines = $baseLineCount
}

function Merge-PoshixSessionHistory {
    <#
    .SYNOPSIS
    Append this session's new commands to the shared PSReadLine history file
    .DESCRIPTION
    Called on session exit. Reads the per-session file, skips the lines that
    were seeded from shared history at startup, and appends only the commands
    actually typed in this session. Cleans up the temporary session file.
    #>
    if (-not $script:PoshixSessionPSRLPath) { return }
    if (-not (Test-Path $script:PoshixSessionPSRLPath -ErrorAction SilentlyContinue)) { return }

    try {
        $lines = @(Get-Content $script:PoshixSessionPSRLPath -ErrorAction SilentlyContinue)
        if ($lines.Count -gt $script:PoshixPSRLBaseLines) {
            $newLines = $lines[$script:PoshixPSRLBaseLines..($lines.Count - 1)]
            Add-Content -Path $script:PoshixSharedPSRLPath -Value $newLines -ErrorAction SilentlyContinue
        }
    } catch {
    } finally {
        Remove-Item $script:PoshixSessionPSRLPath -Force -ErrorAction SilentlyContinue
    }
}

# Aliases for common history operations
Set-Alias -Name histls -Value Get-PoshixHistory
Set-Alias -Name rinvoke -Value Invoke-PoshixHistory
Set-Alias -Name hgrep -Value Search-PoshixHistory
