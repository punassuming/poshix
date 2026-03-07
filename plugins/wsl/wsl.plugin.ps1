# wsl plugin for poshix
# WSL discovery and execution helpers for PowerShell

function Get-PoshixWslCliCommand {
    $wslCommand = Get-Command wsl -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $wslCommand) {
        $wslCommand = Get-Command wsl.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    return $wslCommand
}

function ConvertFrom-PoshixWslText {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Text
    )

    process {
        ($Text -replace "`0", '').TrimEnd("`r", "`n")
    }
}

function Invoke-PoshixWslCliCapture {
    param(
        [string[]]$Arguments = @()
    )

    $wslCommand = Get-PoshixWslCliCommand
    if (-not $wslCommand) {
        return [PSCustomObject]@{
            Available = $false
            ExitCode = 127
            Output = @()
            Command = $null
        }
    }

    $output = & $wslCommand.Source @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    return [PSCustomObject]@{
        Available = $true
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { $_.ToString() | ConvertFrom-PoshixWslText })
        Command = $wslCommand.Source
    }
}

function Invoke-PoshixWslCliPassthrough {
    param(
        [string[]]$Arguments = @()
    )

    $wslCommand = Get-PoshixWslCliCommand
    if (-not $wslCommand) {
        Write-Warning "[poshix] wsl.exe is not available in PATH"
        return
    }

    & $wslCommand.Source @Arguments
}

function ConvertFrom-PoshixWslDistributionText {
    param(
        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    $distributions = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $trimmed = $line.Trim()
        if ($trimmed -match '^(NAME|The following is a list|Install using )') {
            continue
        }

        if ($trimmed -match '^(?<default>\*)?\s*(?<name>.+?)\s{2,}(?<state>[A-Za-z][A-Za-z ]+?)\s{2,}(?<version>\d+)$') {
            $distributions.Add([PSCustomObject]@{
                Name = $Matches.name.Trim()
                State = $Matches.state.Trim()
                Version = [int]$Matches.version
                IsDefault = $Matches.default -eq '*'
                Source = 'Installed'
            })
        }
    }

    return $distributions
}

function ConvertFrom-PoshixWslOnlineDistributionText {
    param(
        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    $distributions = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $trimmed = $line.Trim()
        if ($trimmed -match '^(NAME|The following is a list|Install using )') {
            continue
        }

        if ($trimmed -match '^(?<name>\S.+?)\s{2,}(?<friendly>.+)$') {
            $distributions.Add([PSCustomObject]@{
                Name = $Matches.name.Trim()
                FriendlyName = $Matches.friendly.Trim()
                Source = 'Online'
            })
        }
    }

    return $distributions
}

function ConvertFrom-PoshixWslStatusText {
    param(
        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    $status = [ordered]@{
        DefaultDistribution = $null
        DefaultVersion = $null
        Notes = @()
    }

    foreach ($line in $Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line -match '^Default Distribution:\s*(.+)$') {
            $status.DefaultDistribution = $Matches[1].Trim()
            continue
        }

        if ($line -match '^Default Version:\s*(.+)$') {
            $status.DefaultVersion = $Matches[1].Trim()
            continue
        }

        $status.Notes += $line.Trim()
    }

    return [PSCustomObject]$status
}

function Get-WslDistribution {
    <#
    .SYNOPSIS
    List installed or online WSL distributions.
    #>
    [CmdletBinding()]
    param(
        [switch]$Online
    )

    $arguments = if ($Online) {
        @('--list', '--online')
    } else {
        @('--list', '--verbose')
    }

    $result = Invoke-PoshixWslCliCapture -Arguments $arguments
    if (-not $result.Available) {
        Write-Warning "[poshix] wsl.exe is not available in PATH"
        return
    }

    if ($result.ExitCode -ne 0) {
        Write-Warning "[poshix] wsl $($arguments -join ' ') failed: $($result.Output -join ' ')"
        return
    }

    $lines = @($result.Output | Where-Object { $_ -ne $null -and $_ -ne '' })

    if ($Online) {
        return ConvertFrom-PoshixWslOnlineDistributionText -Lines $lines
    }

    return ConvertFrom-PoshixWslDistributionText -Lines $lines
}

function Get-WslStatus {
    <#
    .SYNOPSIS
    Show the current WSL default distro/version and installed distro inventory.
    #>
    [CmdletBinding()]
    param()

    $statusResult = Invoke-PoshixWslCliCapture -Arguments @('--status')
    if (-not $statusResult.Available) {
        Write-Warning "[poshix] wsl.exe is not available in PATH"
        return
    }

    if ($statusResult.ExitCode -ne 0) {
        Write-Warning "[poshix] wsl --status failed: $($statusResult.Output -join ' ')"
        return
    }

    $statusLines = @($statusResult.Output | Where-Object { $_ -ne $null -and $_ -ne '' })
    $status = ConvertFrom-PoshixWslStatusText -Lines $statusLines
    $distributions = @(Get-WslDistribution)

    return [PSCustomObject]@{
        DefaultDistribution = $status.DefaultDistribution
        DefaultVersion = $status.DefaultVersion
        Notes = $status.Notes
        Distributions = $distributions
    }
}

function Invoke-WslCommand {
    <#
    .SYNOPSIS
    Execute a command in WSL from PowerShell.
    #>
    [CmdletBinding()]
    param(
        [string]$Distribution,
        [string]$User,
        [string[]]$Command
    )

    $arguments = @()
    if ($Distribution) {
        $arguments += @('-d', $Distribution)
    }
    if ($User) {
        $arguments += @('-u', $User)
    }

    if ($Command.Count -gt 0) {
        if ($Command[0] -eq '--') {
            $Command = $Command[1..($Command.Count - 1)]
        }
        if ($Command.Count -gt 0) {
            $arguments += @('--')
            $arguments += $Command
        }
    }

    Invoke-PoshixWslCliPassthrough -Arguments $arguments
}

function Invoke-PoshixWslProxy {
    [CmdletBinding()]
    param(
        [Alias('d')]
        [string]$Distribution,

        [Alias('u')]
        [string]$User,

        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    if (-not $Distribution -and -not $User -and $Arguments.Count -gt 0) {
        switch ($Arguments[0].ToLowerInvariant()) {
            'list' {
                if ($Arguments.Count -gt 1 -and $Arguments[1].ToLowerInvariant() -eq 'online') {
                    return Get-WslDistribution -Online
                }
                return Get-WslDistribution
            }
            'ls' {
                if ($Arguments.Count -gt 1 -and $Arguments[1].ToLowerInvariant() -eq 'online') {
                    return Get-WslDistribution -Online
                }
                return Get-WslDistribution
            }
            'status' {
                return Get-WslStatus
            }
        }
    }

    $passthroughArguments = @()
    if ($Distribution) {
        $passthroughArguments += @('-d', $Distribution)
    }
    if ($User) {
        $passthroughArguments += @('-u', $User)
    }
    $passthroughArguments += $Arguments

    Invoke-PoshixWslCliPassthrough -Arguments $passthroughArguments
}

Set-Item -Path "function:global:Get-PoshixWslCliCommand" -Value ${function:Get-PoshixWslCliCommand}
Set-Item -Path "function:global:ConvertFrom-PoshixWslText" -Value ${function:ConvertFrom-PoshixWslText}
Set-Item -Path "function:global:Invoke-PoshixWslCliCapture" -Value ${function:Invoke-PoshixWslCliCapture}
Set-Item -Path "function:global:Invoke-PoshixWslCliPassthrough" -Value ${function:Invoke-PoshixWslCliPassthrough}
Set-Item -Path "function:global:ConvertFrom-PoshixWslDistributionText" -Value ${function:ConvertFrom-PoshixWslDistributionText}
Set-Item -Path "function:global:ConvertFrom-PoshixWslOnlineDistributionText" -Value ${function:ConvertFrom-PoshixWslOnlineDistributionText}
Set-Item -Path "function:global:ConvertFrom-PoshixWslStatusText" -Value ${function:ConvertFrom-PoshixWslStatusText}
Set-Item -Path "function:global:Get-WslDistribution" -Value ${function:Get-WslDistribution}
Set-Item -Path "function:global:Get-WslStatus" -Value ${function:Get-WslStatus}
Set-Item -Path "function:global:Invoke-WslCommand" -Value ${function:Invoke-WslCommand}
Set-Item -Path "function:global:wsl" -Value ${function:Invoke-PoshixWslProxy}

Set-Alias -Name wslls -Value Get-WslDistribution -Scope Global
Set-Alias -Name wslx -Value Invoke-WslCommand -Scope Global
Set-Alias -Name wslinfo -Value Get-WslStatus -Scope Global

Write-Verbose "[poshix] wsl plugin loaded"
