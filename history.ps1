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

# Aliases for common history operations
Set-Alias -Name histls -Value Get-PoshixHistory
Set-Alias -Name rinvoke -Value Invoke-PoshixHistory
Set-Alias -Name hgrep -Value Search-PoshixHistory
