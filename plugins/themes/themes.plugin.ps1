# Poshix Themes Plugin
# Provides theming capabilities with RGB color support and Windows Terminal integration

# Ensure USERPROFILE is set
if (!$env:USERPROFILE) {
    if ($env:HOME) {
        $env:USERPROFILE = $env:HOME
    } else {
        $env:USERPROFILE = "$env:HOMEDRIVE$env:HOMEPATH"
    }
}

# Theme storage path
$script:ThemesPath = Join-Path $env:USERPROFILE '.poshix' | Join-Path -ChildPath 'themes'
$script:BuiltinThemesPath = Join-Path $PSScriptRoot 'themes'

# Ensure themes directory exists
if (-not (Test-Path $script:ThemesPath)) {
    New-Item -ItemType Directory -Path $script:ThemesPath -Force | Out-Null
}

function Get-PoshixThemes {
    <#
    .SYNOPSIS
    List all available themes
    .DESCRIPTION
    Returns a list of all available themes from both built-in and user directories
    #>
    $themes = @()
    
    # Get built-in themes
    if (Test-Path $script:BuiltinThemesPath) {
        $themes += Get-ChildItem -Path $script:BuiltinThemesPath -Filter "*.theme.json" | 
            ForEach-Object { 
                $name = $_.BaseName -replace '\.theme$', ''
                [PSCustomObject]@{
                    Name = $name
                    Path = $_.FullName
                    Type = 'Built-in'
                }
            }
    }
    
    # Get user themes
    if (Test-Path $script:ThemesPath) {
        $themes += Get-ChildItem -Path $script:ThemesPath -Filter "*.theme.json" | 
            ForEach-Object {
                $name = $_.BaseName -replace '\.theme$', ''
                [PSCustomObject]@{
                    Name = $name
                    Path = $_.FullName
                    Type = 'User'
                }
            }
    }
    
    return $themes
}

function Get-PoshixTheme {
    <#
    .SYNOPSIS
    Get a specific theme by name
    .PARAMETER Name
    The name of the theme to retrieve
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    # Check user themes first
    $userPath = Join-Path $script:ThemesPath "$Name.theme.json"
    if (Test-Path $userPath) {
        return Get-Content $userPath -Raw | ConvertFrom-Json
    }
    
    # Check built-in themes
    $builtinPath = Join-Path $script:BuiltinThemesPath "$Name.theme.json"
    if (Test-Path $builtinPath) {
        return Get-Content $builtinPath -Raw | ConvertFrom-Json
    }
    
    Write-Error "Theme '$Name' not found"
    return $null
}

function Set-PoshixTheme {
    <#
    .SYNOPSIS
    Apply a theme to Poshix and optionally to Windows Terminal
    .PARAMETER Name
    The name of the theme to apply
    .PARAMETER ApplyToTerminal
    If set, also applies the theme to Windows Terminal settings
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [switch]$ApplyToTerminal
    )
    
    $theme = Get-PoshixTheme -Name $Name
    if (-not $theme) {
        return
    }
    
    # Update Poshix configuration
    $config = @{
        Theme = $Name
        Colors = @{}
    }
    
    # Map theme colors to Poshix color configuration
    if ($theme.colors) {
        # For now, use simple color name mapping
        # The theme RGB colors will be applied at the terminal level
        # Here we just set reasonable ANSI color names for Poshix tools
        $config.Colors = @{
            Directory = 'Blue'
            HiddenDirectory = 'DarkCyan'
            Symlink = 'Cyan'
            FileSymlink = 'Green'
            HiddenFile = 'DarkGray'
            ExecutableFile = 'Green'
            ArchiveFile = 'Red'
            ImageFile = 'Magenta'
            VideoFile = 'Magenta'
            AudioFile = 'DarkMagenta'
            DocumentFile = 'Yellow'
            File = 'Green'
            FileNoExtension = 'White'
        }
    }
    
    # Map prompt colors if defined in theme
    if ($theme.prompt) {
        if (-not $config.ContainsKey('Prompt')) {
            $config.Prompt = @{}
        }
        $config.Prompt = $theme.prompt
    }
    
    Set-PoshixConfig -Config $config
    Save-PoshixConfig
    
    Write-Host "Theme '$Name' applied to Poshix" -ForegroundColor Green
    
    # Apply to Windows Terminal if requested
    if ($ApplyToTerminal) {
        Set-WindowsTerminalTheme -Theme $theme -Name $Name
    }
}

function Set-WindowsTerminalTheme {
    <#
    .SYNOPSIS
    Apply theme to Windows Terminal settings
    .PARAMETER Theme
    The theme object to apply
    .PARAMETER Name
    The name of the theme
    #>
    param(
        [Parameter(Mandatory=$true)]
        $Theme,
        
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    # Find Windows Terminal settings file
    $settingsPaths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    )
    
    $settingsPath = $settingsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if (-not $settingsPath) {
        Write-Warning "Windows Terminal settings file not found. Theme only applied to Poshix."
        return
    }
    
    try {
        # Backup settings
        $backupPath = "$settingsPath.backup"
        Copy-Item -Path $settingsPath -Destination $backupPath -Force
        
        # Read settings
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        
        # Ensure schemes array exists
        if (-not $settings.schemes) {
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
            $colorScheme.selectionBackground = if ($Theme.colors.selection) { $Theme.colors.selection } else { "#FFFFFF" }
            
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
            foreach ($profile in $settings.profiles.list) {
                if ($profile.name -match 'PowerShell' -or $profile.commandline -match 'pwsh|powershell') {
                    $profile.colorScheme = "Poshix-$Name"
                }
            }
        }
        
        # Write settings back
        $settings | ConvertTo-Json -Depth 100 | Set-Content -Path $settingsPath -Encoding UTF8
        
        Write-Host "Theme applied to Windows Terminal. Restart terminal to see changes." -ForegroundColor Green
        Write-Host "Backup saved to: $backupPath" -ForegroundColor Gray
    }
    catch {
        Write-Error "Failed to apply theme to Windows Terminal: $_"
        # Restore backup if something went wrong
        if (Test-Path $backupPath) {
            Copy-Item -Path $backupPath -Destination $settingsPath -Force
            Write-Warning "Settings restored from backup"
        }
    }
}

function New-PoshixTheme {
    <#
    .SYNOPSIS
    Create a new custom theme
    .PARAMETER Name
    The name of the theme
    .PARAMETER Colors
    Hashtable of colors in hex format
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Colors
    )
    
    $theme = @{
        name = $Name
        colors = $Colors
    }
    
    $themePath = Join-Path $script:ThemesPath "$Name.theme.json"
    $theme | ConvertTo-Json -Depth 10 | Set-Content -Path $themePath -Encoding UTF8
    
    Write-Host "Theme '$Name' created at: $themePath" -ForegroundColor Green
}

# Make functions global so they're available outside the module
# This is necessary because they're defined after module parse time
Set-Item -Path "function:global:Get-PoshixThemes" -Value ${function:Get-PoshixThemes}
Set-Item -Path "function:global:Get-PoshixTheme" -Value ${function:Get-PoshixTheme}
Set-Item -Path "function:global:Set-PoshixTheme" -Value ${function:Set-PoshixTheme}
Set-Item -Path "function:global:New-PoshixTheme" -Value ${function:New-PoshixTheme}

Write-Verbose "[poshix] Themes plugin loaded - RGB color support and Windows Terminal integration enabled"
