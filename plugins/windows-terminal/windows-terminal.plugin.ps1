# Windows Terminal integration plugin for poshix

function Get-WindowsTerminalSettingsPath {
    $settingsPaths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )

    return $settingsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Set-WindowsTerminalTheme {
    <#
    .SYNOPSIS
    Apply theme to Windows Terminal settings
    .PARAMETER Theme
    The theme object to apply
    .PARAMETER Name
    The name of the theme
    .PARAMETER SettingsPath
    Optional path to the Windows Terminal settings.json file (used for testing)
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Theme,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$SettingsPath
    )
    
    # Find Windows Terminal settings file
    if (-not $SettingsPath) {
        $SettingsPath = Get-WindowsTerminalSettingsPath
    }
    
    if (-not $SettingsPath -or -not (Test-Path $SettingsPath)) {
        Write-Warning "Windows Terminal settings file not found. Theme only applied to Poshix."
        return
    }

    $backupPath = "$SettingsPath.backup"
    try {
        # Backup settings
        Copy-Item -Path $SettingsPath -Destination $backupPath -Force
        
        # Read settings
        $settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json
        
        # Ensure schemes array exists
        if ($null -eq $settings.PSObject.Properties['schemes']) {
            $settings | Add-Member -MemberType NoteProperty -Name 'schemes' -Value @()
        }
        
        # Create color scheme object
        $colorScheme = @{
            name = "Poshix-$Name"
        }
        
        if ($Theme.colors) {
            $colorScheme.background = $Theme.colors.background
            $colorScheme.foreground = $Theme.colors.foreground
            $colorScheme.cursorColor = if ($Theme.colors.cursor) { $Theme.colors.cursor } else { $Theme.colors.foreground }
            # Use a slightly transparent version of foreground for selection, or white as fallback
            $colorScheme.selectionBackground = if ($Theme.colors.selection) { 
                $Theme.colors.selection 
            } elseif ($Theme.colors.brightBlack) {
                $Theme.colors.brightBlack
            } else { 
                "#404040"  # Neutral gray for better compatibility
            }
            
            # ANSI colors
            $colorScheme.black = $Theme.colors.black
            $colorScheme.red = $Theme.colors.red
            $colorScheme.green = $Theme.colors.green
            $colorScheme.yellow = $Theme.colors.yellow
            $colorScheme.blue = $Theme.colors.blue
            $colorScheme.purple = $Theme.colors.magenta
            $colorScheme.cyan = $Theme.colors.cyan
            $colorScheme.white = $Theme.colors.white
            
            # Bright ANSI colors
            $colorScheme.brightBlack = $Theme.colors.brightBlack
            $colorScheme.brightRed = $Theme.colors.brightRed
            $colorScheme.brightGreen = $Theme.colors.brightGreen
            $colorScheme.brightYellow = $Theme.colors.brightYellow
            $colorScheme.brightBlue = $Theme.colors.brightBlue
            $colorScheme.brightPurple = $Theme.colors.brightMagenta
            $colorScheme.brightCyan = $Theme.colors.brightCyan
            $colorScheme.brightWhite = $Theme.colors.brightWhite
        }
        
        # Remove existing Poshix theme if present
        $settings.schemes = @($settings.schemes | Where-Object { $_.name -ne "Poshix-$Name" })
        
        # Add new scheme
        $settings.schemes += $colorScheme
        
        # Apply to PowerShell profile if present
        if ($settings.profiles -and $settings.profiles.list) {
            foreach ($wtProfile in $settings.profiles.list) {
                if ($wtProfile.name -match 'PowerShell' -or $wtProfile.commandline -match 'pwsh|powershell') {
                    $wtProfile | Add-Member -MemberType NoteProperty -Name 'colorScheme' -Value "Poshix-$Name" -Force
                }
            }
        }
        
        # Write settings back (use UTF8 with BOM for Windows Terminal compatibility)
        $json = $settings | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($SettingsPath, $json, [System.Text.UTF8Encoding]::new($true))
        
        Write-Host "Theme applied to Windows Terminal. Restart terminal to see changes." -ForegroundColor Green
        Write-Host "Backup saved to: $backupPath" -ForegroundColor Gray
    }
    catch {
        Write-Error "Failed to apply theme to Windows Terminal: $_"
        # Restore backup if something went wrong
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $SettingsPath -Force
            Write-Warning "Settings restored from backup"
        }
    }
}

function Set-WindowsTerminalTmuxKeybindings {
    <#
    .SYNOPSIS
    Apply tmux-like pane split and navigation keybindings to Windows Terminal
    .PARAMETER SettingsPath
    Optional path to the Windows Terminal settings.json file (used for testing)
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$SettingsPath
    )

    # Find Windows Terminal settings file
    if (-not $SettingsPath) {
        $SettingsPath = Get-WindowsTerminalSettingsPath
    }

    if (-not $SettingsPath -or -not (Test-Path $SettingsPath)) {
        Write-Warning "Windows Terminal settings file not found."
        return
    }

    $backupPath = "$SettingsPath.backup"
    try {
        # Backup settings
        Copy-Item -Path $SettingsPath -Destination $backupPath -Force

        # Read settings
        $settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json

        # Ensure actions array exists
        if ($null -eq $settings.PSObject.Properties['actions']) {
            $settings | Add-Member -MemberType NoteProperty -Name 'actions' -Value @()
        }

        # Remove existing Poshix tmux-style keybindings if present
        $settings.actions = @($settings.actions | Where-Object {
            $_.name -notmatch '^Poshix: '
        })

        # Add tmux-like split/navigation keybindings
        $settings.actions += @(
            @{
                command = @{ action = 'splitPane'; split = 'up'; splitMode = 'duplicate' }
                keys = 'alt+shift+up'
                name = 'Poshix: Split pane up'
            },
            @{
                command = @{ action = 'splitPane'; split = 'down'; splitMode = 'duplicate' }
                keys = 'alt+shift+down'
                name = 'Poshix: Split pane down'
            },
            @{
                command = @{ action = 'splitPane'; split = 'left'; splitMode = 'duplicate' }
                keys = 'alt+shift+left'
                name = 'Poshix: Split pane left'
            },
            @{
                command = @{ action = 'splitPane'; split = 'right'; splitMode = 'duplicate' }
                keys = 'alt+shift+right'
                name = 'Poshix: Split pane right'
            },
            @{
                command = @{ action = 'moveFocus'; direction = 'up' }
                keys = 'alt+up'
                name = 'Poshix: Focus pane up'
            },
            @{
                command = @{ action = 'moveFocus'; direction = 'down' }
                keys = 'alt+down'
                name = 'Poshix: Focus pane down'
            },
            @{
                command = @{ action = 'moveFocus'; direction = 'left' }
                keys = 'alt+left'
                name = 'Poshix: Focus pane left'
            },
            @{
                command = @{ action = 'moveFocus'; direction = 'right' }
                keys = 'alt+right'
                name = 'Poshix: Focus pane right'
            }
        )

        # Write settings back (use UTF8 with BOM for Windows Terminal compatibility)
        $json = $settings | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($SettingsPath, $json, [System.Text.UTF8Encoding]::new($true))

        Write-Host "tmux-style keybindings applied to Windows Terminal. Restart terminal to see changes." -ForegroundColor Green
        Write-Host "Backup saved to: $backupPath" -ForegroundColor Gray
    }
    catch {
        Write-Error "Failed to apply tmux-style keybindings to Windows Terminal: $_"
        # Restore backup if something went wrong
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $SettingsPath -Force
            Write-Warning "Settings restored from backup"
        }
    }
}

function Get-PoshixTerminalWorkspaceDirectory {
    Join-Path $HOME '.poshix' 'terminal-workspaces'
}

function Get-PoshixTerminalWorkspacePath {
    param([Parameter(Mandatory)][string]$Name)
    Join-Path (Get-PoshixTerminalWorkspaceDirectory) "$Name.json"
}

function Save-PoshixTerminalWorkspace {
    <# .SYNOPSIS Save a named Windows Terminal pane layout. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name,
        [Parameter(Mandatory)][hashtable[]]$Pane,
        [string]$Description = ''
    )
    if ($Name -match '[\\/:*?"<>|]') { throw "Workspace name contains invalid filename characters: $Name" }
    if ($Pane.Count -eq 0) { throw 'A workspace must contain at least one pane.' }
    foreach ($item in $Pane) {
        if ($item.Type -notin @('PowerShell', 'Wsl')) { throw "Pane Type must be PowerShell or Wsl." }
        if (-not $item.Directory) { throw 'Every pane requires Directory.' }
        if ($item.Placement -and $item.Placement -notin @('Tab', 'Horizontal', 'Vertical')) { throw 'Placement must be Tab, Horizontal, or Vertical.' }
        if ($item.Type -eq 'Wsl' -and -not $item.Distribution) { throw 'A Wsl pane requires Distribution.' }
    }
    $directory = Get-PoshixTerminalWorkspaceDirectory
    if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    [ordered]@{ Name = $Name; Description = $Description; Panes = $Pane; UpdatedAt = (Get-Date).ToUniversalTime().ToString('o') } |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Get-PoshixTerminalWorkspacePath $Name) -Encoding UTF8
}

function Get-PoshixTerminalWorkspace {
    [CmdletBinding()]
    param([string]$Name)
    $directory = Get-PoshixTerminalWorkspaceDirectory
    if ($Name) {
        $path = Get-PoshixTerminalWorkspacePath $Name
        if (-not (Test-Path -LiteralPath $path)) { Write-Warning "[poshix] Terminal workspace '$Name' was not found."; return }
        return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    }
    if (-not (Test-Path -LiteralPath $directory)) { return @() }
    return Get-ChildItem -LiteralPath $directory -Filter '*.json' | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json }
}

function Start-PoshixTerminalWorkspace {
    <# .SYNOPSIS Launch a saved Windows Terminal workspace. #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory, Position = 0)][string]$Name)
    $workspace = Get-PoshixTerminalWorkspace -Name $Name
    if (-not $workspace) { return }
    $wt = Get-Command wt,wt.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $wt) { Write-Warning '[poshix] Windows Terminal (wt.exe) is not available in PATH.'; return }
    $arguments = @()
    $validatedDistributions = @{}
    foreach ($pane in @($workspace.Panes)) {
        if (-not (Test-Path -LiteralPath $pane.Directory)) { Write-Warning "[poshix] Workspace directory does not exist: $($pane.Directory)"; return }
        if ($pane.Type -eq 'Wsl') {
            $wsl = Get-Command wsl,wsl.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $wsl) { Write-Warning '[poshix] WSL is required for this workspace pane.'; return }
            if (-not $validatedDistributions.ContainsKey($pane.Distribution)) {
                $distributions = @(& $wsl.Source --list --quiet 2>$null | ForEach-Object { ($_.ToString() -replace "`0", '').Trim() } | Where-Object { $_ })
                if ($LASTEXITCODE -ne 0 -or $distributions -notcontains $pane.Distribution) { Write-Warning "[poshix] WSL distribution '$($pane.Distribution)' is unavailable."; return }
                $validatedDistributions[$pane.Distribution] = $true
            }
        }
        $command = if ($pane.Type -eq 'Wsl') { @('wsl.exe', '-d', $pane.Distribution) } else { @('pwsh.exe') }
        if ($pane.Command) { $command += @($pane.Command) }
        $placement = if ($pane.Placement) { [string]$pane.Placement } else { 'Tab' }
        if ($arguments.Count -eq 0 -or $placement -eq 'Tab') {
            if ($arguments.Count -gt 0) { $arguments += ';' }
            $arguments += @('new-tab', '-d', $pane.Directory) + $command
        } else {
            $split = if ($placement -eq 'Horizontal') { '-H' } else { '-V' }
            $arguments += @(';', 'split-pane', $split, '-d', $pane.Directory) + $command
        }
    }
    if ($PSCmdlet.ShouldProcess($Name, "Launch Windows Terminal workspace: $($arguments -join ' ')")) { & $wt.Source @arguments }
}

# Export to global scope to work around PowerShell module export timing limitations
Set-Item -Path "function:global:Set-WindowsTerminalTheme" -Value ${function:Set-WindowsTerminalTheme}
Set-Item -Path "function:global:Set-WindowsTerminalTmuxKeybindings" -Value ${function:Set-WindowsTerminalTmuxKeybindings}
Set-Item -Path "function:global:Save-PoshixTerminalWorkspace" -Value ${function:Save-PoshixTerminalWorkspace}
Set-Item -Path "function:global:Get-PoshixTerminalWorkspace" -Value ${function:Get-PoshixTerminalWorkspace}
Set-Item -Path "function:global:Start-PoshixTerminalWorkspace" -Value ${function:Start-PoshixTerminalWorkspace}

Write-Verbose "[poshix] Windows Terminal plugin loaded"
