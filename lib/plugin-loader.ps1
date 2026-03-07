# Plugin loader for poshix
# Inspired by ohmyzsh plugin loading and oh-my-fish's require system

# Track loaded plugins
$script:LoadedPlugins = @{}

function Get-PoshixPluginMetadata {
    param(
        [Parameter(Mandatory)]
        [string]$PluginDirectory,

        [Parameter(Mandatory)]
        [string]$Scope
    )

    $pluginName = Split-Path $PluginDirectory -Leaf
    $pluginFile = Join-Path $PluginDirectory "$pluginName.plugin.ps1"
    if (-not (Test-Path $pluginFile)) {
        return $null
    }

    $metadataPath = Join-Path $PluginDirectory "plugin.json"
    $readmePath = Join-Path $PluginDirectory "README.md"
    $metadata = $null

    if (Test-Path $metadataPath) {
        try {
            $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "[poshix] Failed to parse plugin metadata for '$pluginName': $_"
        }
    }

    $description = $null
    if ($metadata -and $metadata.Description) {
        $description = $metadata.Description
    } elseif (Test-Path $readmePath) {
        $description = Get-Content $readmePath |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and $_ -notmatch '^#' } |
            Select-Object -First 1
    }

    $commands = @()
    if ($metadata -and $null -ne $metadata.Commands) {
        $commands = @($metadata.Commands) | Where-Object { $_ }
    }

    $requires = @()
    if ($metadata -and $null -ne $metadata.Requires) {
        $requires = @($metadata.Requires) | Where-Object { $_ }
    }

    [PSCustomObject]@{
        Name = $pluginName
        Scope = $Scope
        Loaded = $script:LoadedPlugins.ContainsKey($pluginName)
        Description = $description
        Commands = $commands
        Requires = $requires
        Path = $pluginFile
        MetadataPath = if (Test-Path $metadataPath) { $metadataPath } else { $null }
        ReadmePath = if (Test-Path $readmePath) { $readmePath } else { $null }
    }
}

function Get-PoshixPluginCatalog {
    <#
    .SYNOPSIS
    Get structured metadata for available poshix plugins.
    .DESCRIPTION
    Scans built-in and custom plugin directories and returns plugin metadata that
    can be used for discovery, documentation, or richer CLI views.
    #>
    [CmdletBinding()]
    param()

    $catalog = @()
    $pluginSources = @(
        @{ Scope = 'Built-in'; Path = (Join-Path $script:PoshixPath "plugins") },
        @{ Scope = 'Custom'; Path = (Join-Path $env:USERPROFILE ".poshix/plugins") }
    )

    foreach ($source in $pluginSources) {
        if (-not (Test-Path $source.Path)) {
            continue
        }

        $catalog += Get-ChildItem $source.Path -Directory | ForEach-Object {
            Get-PoshixPluginMetadata -PluginDirectory $_.FullName -Scope $source.Scope
        }
    }

    $catalog | Where-Object { $_ } | Sort-Object Scope, Name
}

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
        [switch]$Available,
        [switch]$Detailed
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
        $catalog = Get-PoshixPluginCatalog

        Write-Host "`nBuilt-in Plugins:" -ForegroundColor Cyan
        $builtInPlugins = @($catalog | Where-Object Scope -eq 'Built-in')
        if ($builtInPlugins.Count -gt 0) {
            foreach ($plugin in $builtInPlugins) {
                $status = if ($plugin.Loaded) { "[loaded]" } else { "" }
                Write-Host "  $($plugin.Name) " -ForegroundColor Green -NoNewline
                if ($status -and $Detailed) {
                    Write-Host "$status " -ForegroundColor Yellow -NoNewline
                }

                if ($Detailed -and $plugin.Description) {
                    Write-Host "- $($plugin.Description)" -ForegroundColor DarkGray
                    if ($plugin.Commands.Count -gt 0) {
                        Write-Host "    Commands: $($plugin.Commands -join ', ')" -ForegroundColor DarkGray
                    }
                    if ($plugin.Requires.Count -gt 0) {
                        Write-Host "    Requires: $($plugin.Requires -join ', ')" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host $status -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  (none)" -ForegroundColor DarkGray
        }

        Write-Host "`nCustom Plugins ($customPluginPath):" -ForegroundColor Cyan
        $customPlugins = @($catalog | Where-Object Scope -eq 'Custom')
        if ($customPlugins.Count -gt 0) {
            foreach ($plugin in $customPlugins) {
                $status = if ($plugin.Loaded) { "[loaded]" } else { "" }
                Write-Host "  $($plugin.Name) " -ForegroundColor Green -NoNewline
                if ($status -and $Detailed) {
                    Write-Host "$status " -ForegroundColor Yellow -NoNewline
                }

                if ($Detailed -and $plugin.Description) {
                    Write-Host "- $($plugin.Description)" -ForegroundColor DarkGray
                    if ($plugin.Commands.Count -gt 0) {
                        Write-Host "    Commands: $($plugin.Commands -join ', ')" -ForegroundColor DarkGray
                    }
                    if ($plugin.Requires.Count -gt 0) {
                        Write-Host "    Requires: $($plugin.Requires -join ', ')" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host $status -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  (none - directory not found)" -ForegroundColor DarkGray
        }
    }
}
