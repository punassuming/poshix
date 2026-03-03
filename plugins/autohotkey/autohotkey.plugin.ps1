# autohotkey plugin for poshix
# Helpers for launching and editing AutoHotkey scripts

function Get-AutoHotkeyCommand {
    $candidates = @('AutoHotkey64.exe', 'AutoHotkey.exe', 'autohotkey')
    foreach ($candidate in $candidates) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Test-AutoHotkeyAvailable {
    if (-not (Get-AutoHotkeyCommand)) {
        Write-Warning "[poshix] AutoHotkey is not available in PATH"
        return $false
    }
    return $true
}

function Start-AutoHotkeyScript {
    <#
    .SYNOPSIS
    Run an AutoHotkey script.
    .PARAMETER Path
    Path to the .ahk script to execute.
    .PARAMETER Args
    Additional arguments passed to AutoHotkey.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Args
    )

    if (-not (Test-AutoHotkeyAvailable)) { return }
    if (-not (Test-Path $Path)) {
        Write-Warning "[poshix] AutoHotkey script not found: $Path"
        return
    }

    $ahk = Get-AutoHotkeyCommand
    $scriptPath = (Resolve-Path $Path).Path
    & $ahk $scriptPath @Args
}

function Edit-AutoHotkeyScript {
    <#
    .SYNOPSIS
    Open an AutoHotkey script in the default editor.
    .PARAMETER Path
    Path to the .ahk script file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "[poshix] AutoHotkey script not found: $Path"
        return
    }

    Invoke-Item (Resolve-Path $Path).Path
}

# Export functions to global scope
Set-Item -Path "function:global:Get-AutoHotkeyCommand"   -Value ${function:Get-AutoHotkeyCommand}
Set-Item -Path "function:global:Test-AutoHotkeyAvailable" -Value ${function:Test-AutoHotkeyAvailable}
Set-Item -Path "function:global:Start-AutoHotkeyScript"   -Value ${function:Start-AutoHotkeyScript}
Set-Item -Path "function:global:Edit-AutoHotkeyScript"    -Value ${function:Edit-AutoHotkeyScript}

# Export aliases to global scope
Set-Alias -Name ahk      -Value Start-AutoHotkeyScript -Scope Global
Set-Alias -Name ahk-edit -Value Edit-AutoHotkeyScript  -Scope Global

Write-Verbose "[poshix] autohotkey plugin loaded"
