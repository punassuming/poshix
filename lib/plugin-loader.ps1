# Plugin loader for poshix
# Inspired by ohmyzsh plugin loading and oh-my-fish's require system

# Track loaded plugins
$script:LoadedPlugins = @{}

function Import-PoshixPlugin {
    <#
    .SYNOPSIS
    Load one or more poshix plugins by name.
    .DESCRIPTION
    Searches for plugins in the built-in plugins directory and the user's custom
    plugins directory (~/.poshix/plugins/). Plugins follow the convention:
    plugins/<name>/<name>.plugin.ps1
    .PARAMETER Name
    One or more plugin names to load.
    .PARAMETER Force
    Reload plugins even if already loaded.
    .EXAMPLE
    Import-PoshixPlugin -Name 'git','docker'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string[]]$Name,
        [switch]$Force
    )
    
    $customPluginPath = Join-Path $env:USERPROFILE ".poshix/plugins"
    $builtinPluginPath = Join-Path $script:PoshixPath "plugins"
    
    foreach ($plugin in $Name) {
        # Skip if already loaded unless Force
        if ($script:LoadedPlugins.ContainsKey($plugin) -and -not $Force) {
            Write-Verbose "[poshix] Plugin '$plugin' already loaded. Use -Force to reload."
            continue
        }
        
        $pluginPaths = @(
            (Join-Path $customPluginPath "$plugin/$plugin.plugin.ps1"),
            (Join-Path $builtinPluginPath "$plugin/$plugin.plugin.ps1")
        )
        
        $loaded = $false
        foreach ($pluginFile in $pluginPaths) {
            if (Test-Path $pluginFile) {
                try {
                    . $pluginFile
                    
                    # Auto-register completions if they exist
                    $completionsDir = Join-Path (Split-Path $pluginFile -Parent) "completions"
                    if (Test-Path $completionsDir) {
                        Get-ChildItem "$completionsDir/*.ps1" -ErrorAction SilentlyContinue | 
                            ForEach-Object { . $_.FullName }
                    }
                    
                    $script:LoadedPlugins[$plugin] = @{
                        Path = $pluginFile
                        LoadedAt = Get-Date
                    }
                    $loaded = $true
                    Write-Verbose "[poshix] Loaded plugin: $plugin from $pluginFile"
                    break
                } catch {
                    Write-Warning "[poshix] Failed to load plugin '$plugin': $_"
                }
            }
        }
        
        if (-not $loaded) {
            Write-Warning "[poshix] Plugin '$plugin' not found"
        }
    }
}

function Remove-PoshixPlugin {
    <#
    .SYNOPSIS
    Unload a plugin from the current session (best effort).
    .DESCRIPTION
    Removes the plugin from the loaded plugins tracker. Note that functions
    and aliases defined by the plugin may remain in the session.
    .PARAMETER Name
    Plugin name to unload.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Name
    )
    
    if ($script:LoadedPlugins.ContainsKey($Name)) {
        $script:LoadedPlugins.Remove($Name)
        Write-Verbose "[poshix] Unloaded plugin: $Name"
    } else {
        Write-Warning "[poshix] Plugin '$Name' is not loaded"
    }
}

function Get-PoshixPlugin {
    <#
    .SYNOPSIS
    List available and/or loaded plugins.
    .PARAMETER Loaded
    Show only currently loaded plugins.
    .PARAMETER Available
    Show all available plugins (built-in and custom).
    #>
    [CmdletBinding()]
    param(
        [switch]$Loaded,
        [switch]$Available
    )
    
    if ($Loaded -or (-not $Available -and -not $Loaded)) {
        Write-Host "`nLoaded Plugins:" -ForegroundColor Cyan
        if ($script:LoadedPlugins.Count -eq 0) {
            Write-Host "  (none)" -ForegroundColor DarkGray
        } else {
            foreach ($name in $script:LoadedPlugins.Keys | Sort-Object) {
                $info = $script:LoadedPlugins[$name]
                Write-Host "  $name" -ForegroundColor Green -NoNewline
                Write-Host " ($($info.Path))" -ForegroundColor DarkGray
            }
        }
    }
    
    if ($Available) {
        $customPluginPath = Join-Path $env:USERPROFILE ".poshix/plugins"
        $builtinPluginPath = Join-Path $script:PoshixPath "plugins"
        
        Write-Host "`nBuilt-in Plugins:" -ForegroundColor Cyan
        if (Test-Path $builtinPluginPath) {
            Get-ChildItem $builtinPluginPath -Directory | ForEach-Object {
                $status = if ($script:LoadedPlugins.ContainsKey($_.Name)) { "[loaded]" } else { "" }
                Write-Host "  $($_.Name) " -ForegroundColor Green -NoNewline
                Write-Host $status -ForegroundColor Yellow
            }
        } else {
            Write-Host "  (none)" -ForegroundColor DarkGray
        }
        
        Write-Host "`nCustom Plugins ($customPluginPath):" -ForegroundColor Cyan
        if (Test-Path $customPluginPath) {
            Get-ChildItem $customPluginPath -Directory | ForEach-Object {
                $status = if ($script:LoadedPlugins.ContainsKey($_.Name)) { "[loaded]" } else { "" }
                Write-Host "  $($_.Name) " -ForegroundColor Green -NoNewline
                Write-Host $status -ForegroundColor Yellow
            }
        } else {
            Write-Host "  (none - directory not found)" -ForegroundColor DarkGray
        }
    }
}
