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

if (Get-Command starship -ErrorAction SilentlyContinue) {
    # Store the fact that we're using Starship for other plugins to check
    $env:POSHIX_PROMPT = 'starship'
    
    # Initialize Starship for PowerShell
    Invoke-Expression (&starship init powershell)
    
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
