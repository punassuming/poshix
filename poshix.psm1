param([switch]$NoVersionWarn = $false, [switch]$Verbose = $false)

# Store the module root path for use by plugin/theme loaders
$script:PoshixPath = $PSScriptRoot

# $cdHistory = Join-Path -Path $Env:USERPROFILE -ChildPath '\.cdHistory'

# if (Get-Module poshix) { return }

# Enhanced startup with better error handling
try {
    Push-Location $psScriptRoot
    
    # Load core utilities first
    . .\utils.ps1
    
    # Load configuration system
    . .\config.ps1
    
    # Load plugin system
    . .\lib\plugin-loader.ps1
    
    # Load enhanced commands
    . .\ls.ps1
    . .\cd.ps1
    . .\history.ps1
    . .\commands.ps1
    
    Pop-Location
    
    if ($Verbose) {
        Write-Host "Poshix module loaded successfully" -ForegroundColor Green
    }
} catch {
    Write-Error "Failed to load poshix module: $_"
    Pop-Location
    return
}

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

# Human readable sizes in ls
try {
    Update-FormatData -pre $PSScriptRoot/formats/Dir.Format.PS1xml
} catch {
    Write-Warning "Failed to load format data: $_"
}


# Saving Previous alias
$orig_cd = $null
$orig_ls = $null
try {
  $orig_cd = (Get-Alias -Name 'cd' -ErrorAction Stop).Definition
} catch {
  # cd alias doesn't exist, use default
  $orig_cd = 'Set-Location'
}
try {
  $orig_ls = (Get-Alias -Name 'ls' -ErrorAction Stop).Definition
} catch {
  # ls alias doesn't exist, use default
  $orig_ls = 'Get-ChildItem'
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  set-item alias:cd -value $orig_cd -ErrorAction SilentlyContinue
  set-item alias:ls -value $orig_ls -ErrorAction SilentlyContinue
  # Export history on module removal if configured
  try {
    $config = Get-PoshixConfig
    if ($config.History.SavePath) {
      Export-PoshixHistory -Path $config.History.SavePath
    }
  } catch {
    # Silently continue if config not available during removal
  }
}


# Writing new alias
Set-item alias:cd -Value 'Set-FileLocation'
Set-item alias:ls -Value 'Get-FileListing'

# Load user configuration if it exists
try {
    Import-PoshixConfig
} catch {
    Write-Warning "Failed to import configuration: $_"
}

# Load history if configured
try {
    $config = Get-PoshixConfig
    if ($config -and $config.Startup -and $config.Startup.LoadHistory) {
        Import-PoshixHistory -Path $config.History.SavePath
    }
} catch {
    # Silently continue if history loading fails
}

# Load enabled plugins from config
try {
    $config = Get-PoshixConfig
    if ($config -and $config.Plugins -and $config.Plugins.Count -gt 0) {
        Import-PoshixPlugin -Name $config.Plugins
    }
} catch {
    Write-Warning "Failed to load plugins: $_"
}

Export-ModuleMember `
  -Alias @(
    'ls',
    'cd',
    'gls',
    '..',
    'cdto',
    'histls',
    'rinvoke',
    'hgrep',
    'find',
    'grep',
    'touch',
    'which',
    'poshpwd',
    'clear'
  ) -Function @(
    'Get-FileListing',
    'Set-FileLocation',
    'Get-LocationStack',
    'Set-LocationTo',
    'Get-PoshixHistory',
    'Invoke-PoshixHistory',
    'Search-PoshixHistory',
    'Clear-PoshixHistory',
    'Export-PoshixHistory',
    'Import-PoshixHistory',
    'Get-PoshixConfig',
    'Set-PoshixConfig',
    'Save-PoshixConfig',
    'Import-PoshixConfig',
    'Reset-PoshixConfig',
    'Find-Files',
    'Find-InFiles',
    'New-File',
    'Get-CommandPath',
    'Get-WorkingDirectory',
    'Clear-Screen',
    'Import-PoshixPlugin',
    'Remove-PoshixPlugin',
    'Get-PoshixPlugin'
  )
