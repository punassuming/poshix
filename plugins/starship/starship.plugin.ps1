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

$contextScript = Join-Path $PSScriptRoot 'starship-context.ps1'
if (Test-Path -LiteralPath $contextScript) {
    . $contextScript
}

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
    # Initialize Starship for PowerShell
    Invoke-Expression (&starship init powershell)

    # Starship writes Unix LF characters in its rendered prompt. In a Windows
    # console, LF advances to the next row without returning to column zero,
    # which indents every line after the first. Keep Starship's generated
    # prompt function intact and normalize only bare line feeds at its output.
    $starshipPromptScriptBlock = (Get-Command prompt -CommandType Function).ScriptBlock
    $normalizedStarshipPrompt = {
        $originalSuccess = $global:?
        $originalExitCode = $global:LASTEXITCODE
        if (Get-Command Update-PoshixStarshipEnvironment -ErrorAction SilentlyContinue) {
            Update-PoshixStarshipEnvironment
        }
        $global:LASTEXITCODE = $originalExitCode
        if ($originalSuccess) {
            $null = Get-Variable PWD -ErrorAction SilentlyContinue
            $promptOutput = & $starshipPromptScriptBlock
        } else {
            Write-Error '' -ErrorAction Ignore
            $promptOutput = & $starshipPromptScriptBlock
        }
        $promptOutput -replace "(?<!`r)`n", "`r`n"
    }.GetNewClosure()
    Set-Item -Path function:global:prompt -Value $normalizedStarshipPrompt

    # Starship determines this value while rendering its first prompt.  That is
    # one prompt too late for a multiline format: the initial PowerShell prompt
    # is written before PSReadLine can account for the additional row, so the
    # prompt character can inherit the preceding line's column.  Seed the
    # standard two-line layout now; Starship recalculates it on each render.
    if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
        Set-PSReadLineOption -ExtraPromptLineCount 1
    }

    # Advertise the active provider for Poshix prompt-selection compatibility.
    # This is control state; the Starship configuration does not render it.
    $env:POSHIX_PROMPT = 'starship'
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
