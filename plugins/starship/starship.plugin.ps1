# Starship prompt integration for poshix
# https://starship.rs
#
# This plugin integrates the Starship cross-shell prompt with poshix.
# Starship must be installed separately: https://starship.rs/guide/#installation
#
# When enabled, this plugin replaces the poshix native prompt with Starship.
# Configure Starship via ~/.config/starship.toml
#
# Installation:
#   winget install --id Starship.Starship
#   # or
#   scoop install starship
#   # or
#   choco install starship

function Test-PoshixInteractiveStarshipHost {
    if ($env:TERM -eq 'dumb') { return $false }
    foreach ($variableName in @('AI_AGENT', 'OPENAI_API_KEY', 'OPENAI_API_BASE', 'OPENAI_API_TYPE', 'GITHUB_ACTIONS', 'CI')) {
        if (-not [string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($variableName))) { return $false }
    }
    try {
        if ([Console]::IsOutputRedirected -or [Console]::IsInputRedirected -or [Console]::IsErrorRedirected) { return $false }
    } catch { return $false }
    return $Host.Name -eq 'ConsoleHost' -and $Host.UI.SupportsVirtualTerminal
}

if ($global:__PoshixStarshipInitialized) {
    Write-Verbose '[poshix] Starship already initialized; skipping duplicate initialization.'
} elseif (-not (Test-PoshixInteractiveStarshipHost)) {
    Write-Verbose '[poshix] Starship skipped for a non-interactive or dumb terminal.'
} elseif (Get-Command starship -ErrorAction SilentlyContinue) {
    # Store the fact that we're using Starship for other plugins to check
    $env:POSHIX_PROMPT = 'starship'
    
    # Initialize Starship for PowerShell
    Invoke-Expression (&starship init powershell)
    $global:__PoshixStarshipInitialized = $true
    
    Write-Verbose "[poshix] Starship prompt activated"
} else {
    Write-Warning @"
[poshix] Starship plugin enabled but starship binary not found.
Install Starship from https://starship.rs or via:
  winget install --id Starship.Starship
  scoop install starship
  choco install starship
"@
}
