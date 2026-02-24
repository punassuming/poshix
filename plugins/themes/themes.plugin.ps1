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
        if (-not (Get-Command Set-WindowsTerminalTheme -ErrorAction SilentlyContinue)) {
            Import-PoshixPlugin -Name 'windows-terminal' -ErrorAction SilentlyContinue
        }

        if (Get-Command Set-WindowsTerminalTheme -ErrorAction SilentlyContinue) {
            Set-WindowsTerminalTheme -Theme $theme -Name $Name
        } else {
            Write-Warning "Windows Terminal integration requires the windows-terminal plugin."
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
# This is necessary because they're defined dynamically after module parse time.
# PowerShell's Export-ModuleMember only exports functions that exist when the script is parsed,
# not functions defined during execution (like plugin functions loaded at runtime).
# This is a known limitation of PowerShell's module system when loading code dynamically.
Set-Item -Path "function:global:Get-PoshixThemes" -Value ${function:Get-PoshixThemes}
Set-Item -Path "function:global:Get-PoshixTheme" -Value ${function:Get-PoshixTheme}
Set-Item -Path "function:global:Set-PoshixTheme" -Value ${function:Set-PoshixTheme}
Set-Item -Path "function:global:New-PoshixTheme" -Value ${function:New-PoshixTheme}

Write-Verbose "[poshix] Themes plugin loaded - RGB color support and Windows Terminal integration enabled"
