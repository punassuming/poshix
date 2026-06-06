# walkthrough.ps1 — interactive onboarding wizard for poshix
# Exports: Invoke-PoshixWalkthrough (alias: poshix-setup)
# All helpers stay in module scope and are not exported.

function Test-PoshixToolInstalled {
    param([Parameter(Mandatory)][string]$Name)

    switch ($Name) {
        'wsl' {
            return [bool](
                (Get-Command wsl     -CommandType Application -ErrorAction SilentlyContinue) -or
                (Get-Command wsl.exe -CommandType Application -ErrorAction SilentlyContinue)
            )
        }
        'CimAvailable' {
            try { $null = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop; return $true }
            catch { return $false }
        }
        'AutoHotkey' {
            foreach ($n in @('AutoHotkey.exe', 'AutoHotkey64.exe', 'AutoHotkeyU64.exe')) {
                if (Get-Command $n -CommandType Application -ErrorAction SilentlyContinue) { return $true }
            }
            return $false
        }
        'TortoiseGit' {
            return [bool](Get-Command TortoiseGitProc.exe -CommandType Application -ErrorAction SilentlyContinue)
        }
        default {
            return [bool](Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue)
        }
    }
}

function Get-PoshixWalkthroughDetectedTools {
    $isWin = if ($PSVersionTable.PSVersion.Major -ge 6) { $IsWindows } else { $true }

    $inProjectDir = $false
    try {
        $null = & git rev-parse --git-dir 2>&1
        $inProjectDir = ($LASTEXITCODE -eq 0)
    } catch { }

    return @{
        git          = (Test-PoshixToolInstalled 'git')
        docker       = (Test-PoshixToolInstalled 'docker')
        kubectl      = (Test-PoshixToolInstalled 'kubectl')
        fzf          = (Test-PoshixToolInstalled 'fzf')
        starship     = (Test-PoshixToolInstalled 'starship')
        wsl          = (Test-PoshixToolInstalled 'wsl')
        AutoHotkey   = (Test-PoshixToolInstalled 'AutoHotkey')
        TortoiseGit  = (Test-PoshixToolInstalled 'TortoiseGit')
        IsWindows    = $isWin
        InProjectDir = $inProjectDir
        CimAvailable = (Test-PoshixToolInstalled 'CimAvailable')
    }
}

function Get-PoshixWalkthroughPluginMap {
    param([Parameter(Mandatory)][hashtable]$DetectedTools)

    return @(
        [PSCustomObject]@{ Name='autohotkey';       Description='Helpers for launching and editing AutoHotkey scripts.';                       Recommended=$DetectedTools.AutoHotkey;                              RecommendReason='AutoHotkey detected';        Selected=$DetectedTools.AutoHotkey }
        [PSCustomObject]@{ Name='completions';      Description='Extensive CLI tab-completion for git, docker, kubectl, npm, and more.';        Recommended=($DetectedTools.git -or $DetectedTools.docker);         RecommendReason='developer tools detected';   Selected=($DetectedTools.git -or $DetectedTools.docker) }
        [PSCustomObject]@{ Name='docker';           Description='WSL-aware Docker helpers with Compose shortcuts and prompt status.';           Recommended=$DetectedTools.docker;                                  RecommendReason='docker detected';            Selected=$DetectedTools.docker }
        [PSCustomObject]@{ Name='fzf-tools';        Description='Fuzzy-finding wrappers for history, files, branches, and processes.';         Recommended=$DetectedTools.fzf;                                     RecommendReason='fzf detected';               Selected=$DetectedTools.fzf }
        [PSCustomObject]@{ Name='git-worktree';     Description='Git worktree management helpers for create, switch, and prune workflows.';     Recommended=$DetectedTools.git;                                     RecommendReason='git detected';               Selected=$DetectedTools.git }
        [PSCustomObject]@{ Name='k8s-context';      Description='Kubernetes context and namespace management with prompt info.';                Recommended=$DetectedTools.kubectl;                                 RecommendReason='kubectl detected';           Selected=$DetectedTools.kubectl }
        [PSCustomObject]@{ Name='session-layouts';  Description='Save and restore bookmarks and working directory session layouts.';           Recommended=$true;                                                  RecommendReason='recommended for all users';  Selected=$true }
        [PSCustomObject]@{ Name='starship';         Description='Integrates the Starship cross-shell prompt with poshix.';                     Recommended=$DetectedTools.starship;                                RecommendReason='starship detected';          Selected=$DetectedTools.starship }
        [PSCustomObject]@{ Name='task-runner';      Description='Per-project task discovery and execution across common task formats.';         Recommended=$true;                                                  RecommendReason='recommended for all users';  Selected=$true }
        [PSCustomObject]@{ Name='themes';           Description='RGB color themes for poshix with optional Windows Terminal integration.';     Recommended=$true;                                                  RecommendReason='recommended for all users';  Selected=$true }
        [PSCustomObject]@{ Name='tortoisegit';      Description='Opens TortoiseGit dialogs from PowerShell without blocking the terminal.';    Recommended=$DetectedTools.TortoiseGit;                             RecommendReason='TortoiseGit detected';       Selected=$DetectedTools.TortoiseGit }
        [PSCustomObject]@{ Name='windows-terminal'; Description='Windows Terminal settings integration for themes and tmux-like keybindings.'; Recommended=$DetectedTools.IsWindows;                               RecommendReason='Windows detected';           Selected=$DetectedTools.IsWindows }
        [PSCustomObject]@{ Name='wmi';              Description='WMI/CIM discovery and query helpers for system inventory.';                   Recommended=$DetectedTools.CimAvailable;                            RecommendReason='CIM/WMI available';          Selected=$DetectedTools.CimAvailable }
        [PSCustomObject]@{ Name='wsl';              Description='WSL discovery and execution helpers with a PowerShell-friendly wsl command.'; Recommended=$DetectedTools.wsl;                                     RecommendReason='WSL detected';               Selected=$DetectedTools.wsl }
        [PSCustomObject]@{ Name='wsl-tmux';         Description='Open a WSL tmux session anchored to the current directory.';                  Recommended=$DetectedTools.wsl;                                     RecommendReason='WSL detected';               Selected=$DetectedTools.wsl }
    )
}

function Get-PoshixPromptPresets {
    return @(
        [PSCustomObject]@{
            Name        = 'Minimal'
            Description = 'Just the prompt character and error indicator.'
            Preview     = '✗ ❯ '
            Config      = @{
                Segments  = @(
                    @{ Type = 'error'; Enabled = $true; Color = 'Red';     Character = '✗' }
                    @{ Type = 'char';  Enabled = $true; Color = 'Magenta'; AdminColor = 'Red'; Character = '❯'; AdminCharacter = '#' }
                )
                Separator = ' '
                Newline   = $false
            }
        }
        [PSCustomObject]@{
            Name        = 'Standard'
            Description = 'Path, git branch, error indicator, and prompt character.'
            Preview     = '~/projects/myapp  main  ❯ '
            Config      = @{
                Segments  = @(
                    @{ Type = 'path';  Enabled = $true; Color = 'Blue';    MaxLength = 50 }
                    @{ Type = 'git';   Enabled = $true; Color = 'Green';   DirtyColor = 'Yellow' }
                    @{ Type = 'error'; Enabled = $true; Color = 'Red';     Character = '✗' }
                    @{ Type = 'char';  Enabled = $true; Color = 'Magenta'; AdminColor = 'Red'; Character = '❯'; AdminCharacter = '#' }
                )
                Separator = ' '
                Newline   = $false
            }
        }
        [PSCustomObject]@{
            Name        = 'Full'
            Description = 'User, host, path, git, error, time, and prompt character.'
            Preview     = 'user@host  ~/projects/myapp  main  ✗  12:34:56  ❯ '
            Config      = @{
                Segments  = @(
                    @{ Type = 'user';  Enabled = $true; Color = 'Green' }
                    @{ Type = 'host';  Enabled = $true; Color = 'Cyan' }
                    @{ Type = 'path';  Enabled = $true; Color = 'Blue';    MaxLength = 50 }
                    @{ Type = 'git';   Enabled = $true; Color = 'Green';   DirtyColor = 'Yellow' }
                    @{ Type = 'error'; Enabled = $true; Color = 'Red';     Character = '✗' }
                    @{ Type = 'time';  Enabled = $true; Color = 'DarkGray'; Format = 'HH:mm:ss' }
                    @{ Type = 'char';  Enabled = $true; Color = 'Magenta'; AdminColor = 'Red'; Character = '❯'; AdminCharacter = '#' }
                )
                Separator = ' '
                Newline   = $false
            }
        }
    )
}

function Invoke-PoshixWalkthroughReadYesNo {
    param(
        [string]$Prompt,
        [bool]$Default = $true
    )

    $hint = if ($Default) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $raw = Read-Host "$Prompt $hint"
        if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
        switch ($raw.Trim().ToLowerInvariant()) {
            'y'   { return $true  }
            'yes' { return $true  }
            'n'   { return $false }
            'no'  { return $false }
            default { Write-Host "  Please enter y or n." -ForegroundColor DarkGray }
        }
    }
}

function Invoke-PoshixWalkthroughHeader {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Poshix Setup Walkthrough" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Press Enter to accept defaults" -ForegroundColor DarkGray
    Write-Host "───────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
}

function Invoke-PoshixWalkthroughStep1Profile {
    Write-Host "[1/6] Profile Setup" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path $PROFILE)) {
        Write-Host "  Profile not found: $PROFILE" -ForegroundColor DarkGray
        $create = Invoke-PoshixWalkthroughReadYesNo "  Create profile and add poshix import?" $true
        if ($create) {
            $dir = Split-Path $PROFILE -Parent
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
            Add-Content -Path $PROFILE -Value "`nImport-Module poshix"
            Write-Host "  Created $PROFILE and added poshix import." -ForegroundColor Green
        }
        Write-Host ""
        return
    }

    if (Select-String -Path $PROFILE -Pattern 'Import-Module\s+poshix|ipmo\s+poshix' -Quiet) {
        Write-Host "  [OK] poshix is already in your profile." -ForegroundColor Green
        Write-Host ""
        return
    }

    Write-Host "  Profile: $PROFILE" -ForegroundColor DarkGray
    Write-Host "  poshix import not found in profile." -ForegroundColor Yellow
    $add = Invoke-PoshixWalkthroughReadYesNo "  Add 'Import-Module poshix' to your profile?" $true
    if ($add) {
        Add-Content -Path $PROFILE -Value "`nImport-Module poshix"
        Write-Host "  Added import to $PROFILE" -ForegroundColor Green
    }
    Write-Host ""
}

function Invoke-PoshixWalkthroughStep2Tools {
    param([Parameter(Mandatory)][hashtable]$DetectedTools)

    Write-Host "[2/6] Tool Detection" -ForegroundColor Cyan
    Write-Host ""

    $toolRows = [ordered]@{
        git          = @{ Label = 'git';         Unlocks = 'git-worktree, completions' }
        docker       = @{ Label = 'docker';      Unlocks = 'docker, completions' }
        kubectl      = @{ Label = 'kubectl';     Unlocks = 'k8s-context, completions' }
        fzf          = @{ Label = 'fzf';         Unlocks = 'fzf-tools' }
        starship     = @{ Label = 'starship';    Unlocks = 'starship' }
        wsl          = @{ Label = 'wsl';         Unlocks = 'wsl, wsl-tmux, docker' }
        AutoHotkey   = @{ Label = 'AutoHotkey';  Unlocks = 'autohotkey' }
        TortoiseGit  = @{ Label = 'TortoiseGit'; Unlocks = 'tortoisegit' }
        CimAvailable = @{ Label = 'CIM/WMI';     Unlocks = 'wmi' }
        IsWindows    = @{ Label = 'Windows OS';  Unlocks = 'windows-terminal' }
    }

    foreach ($key in $toolRows.Keys) {
        $row   = $toolRows[$key]
        $found = $DetectedTools[$key]
        if ($found) {
            Write-Host "  [+] " -ForegroundColor Green -NoNewline
            Write-Host "$($row.Label)  " -NoNewline
            Write-Host "-> " -ForegroundColor DarkGray -NoNewline
            Write-Host $row.Unlocks -ForegroundColor Cyan
        } else {
            Write-Host "  [-] " -ForegroundColor DarkGray -NoNewline
            Write-Host $row.Label -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Read-Host "  Press Enter to continue"
    Write-Host ""
}

function Invoke-PoshixWalkthroughStep3Plugins {
    param([Parameter(Mandatory)][System.Collections.Generic.List[PSCustomObject]]$PluginList)

    Write-Host "[3/6] Plugin Selection" -ForegroundColor Cyan
    Write-Host "  Toggle by number (e.g. 3  or  1,4,7), 'all', 'none', or Enter to accept." -ForegroundColor DarkGray
    Write-Host ""

    function Show-WTPluginList {
        param([System.Collections.Generic.List[PSCustomObject]]$List)
        for ($i = 0; $i -lt $List.Count; $i++) {
            $p   = $List[$i]
            $num = '{0,2}' -f ($i + 1)
            if ($p.Selected) {
                Write-Host "  $num. " -NoNewline
                Write-Host "[*] " -ForegroundColor Green -NoNewline
                Write-Host $p.Name -NoNewline
                if ($p.Recommended) {
                    Write-Host "  (recommended: $($p.RecommendReason))" -ForegroundColor DarkGray -NoNewline
                }
                Write-Host ""
            } else {
                Write-Host "  $num. " -NoNewline
                Write-Host "[ ] " -ForegroundColor DarkGray -NoNewline
                Write-Host "$($p.Name)  " -ForegroundColor DarkGray -NoNewline
                Write-Host "— $($p.Description)" -ForegroundColor DarkGray
            }
        }
    }

    Show-WTPluginList -List $PluginList

    while ($true) {
        Write-Host ""
        $choice = (Read-Host "  Selection").Trim()

        if ([string]::IsNullOrWhiteSpace($choice)) { break }

        switch ($choice.ToLowerInvariant()) {
            'all' {
                for ($i = 0; $i -lt $PluginList.Count; $i++) { $PluginList[$i].Selected = $true }
            }
            'none' {
                for ($i = 0; $i -lt $PluginList.Count; $i++) { $PluginList[$i].Selected = $false }
            }
            default {
                $tokens = $choice -split '[,\s]+' | Where-Object { $_ -match '^\d+$' }
                foreach ($token in $tokens) {
                    $idx = [int]$token - 1
                    if ($idx -ge 0 -and $idx -lt $PluginList.Count) {
                        $PluginList[$idx].Selected = -not $PluginList[$idx].Selected
                    } else {
                        Write-Host "  '$token' is out of range (1-$($PluginList.Count))." -ForegroundColor DarkGray
                    }
                }
            }
        }

        Write-Host ""
        Show-WTPluginList -List $PluginList
    }

    $selected = @($PluginList | Where-Object { $_.Selected } | Select-Object -ExpandProperty Name)

    Write-Host ""
    if ($selected.Count -gt 0) {
        Write-Host "  Selected ($($selected.Count)): " -NoNewline
        Write-Host ($selected -join ', ') -ForegroundColor Green
    } else {
        Write-Host "  No plugins selected." -ForegroundColor DarkGray
    }
    Write-Host ""

    return $selected
}

function Invoke-PoshixWalkthroughStep4Prompt {
    param([Parameter(Mandatory)][PSCustomObject[]]$Presets)

    Write-Host "[4/6] Prompt Style" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $Presets.Count; $i++) {
        $p      = $Presets[$i]
        $label  = if ($i -eq 1) { "$($i + 1). $($p.Name) (default)" } else { "$($i + 1). $($p.Name)" }
        Write-Host "  $label" -ForegroundColor Cyan
        Write-Host "     $($p.Description)" -ForegroundColor DarkGray
        Write-Host "     $($p.Preview)"
        Write-Host ""
    }

    while ($true) {
        $raw = (Read-Host "  Choose preset [1-$($Presets.Count)]").Trim()
        if ([string]::IsNullOrWhiteSpace($raw)) {
            Write-Host "  Using: $($Presets[1].Name)" -ForegroundColor Green
            Write-Host ""
            return $Presets[1].Config
        }
        if ($raw -match '^\d+$') {
            $idx = [int]$raw - 1
            if ($idx -ge 0 -and $idx -lt $Presets.Count) {
                Write-Host "  Using: $($Presets[$idx].Name)" -ForegroundColor Green
                Write-Host ""
                return $Presets[$idx].Config
            }
        }
        Write-Host "  Enter a number between 1 and $($Presets.Count)." -ForegroundColor DarkGray
    }
}

function Invoke-PoshixWalkthroughStep5Save {
    param(
        [Parameter(Mandatory)][string[]]$SelectedPlugins,
        [Parameter(Mandatory)][hashtable]$PromptConfig,
        [switch]$SkipSave
    )

    Write-Host "[5/6] Save Configuration" -ForegroundColor Cyan
    Write-Host ""

    $pluginSummary = if ($SelectedPlugins.Count -gt 0) { $SelectedPlugins -join ', ' } else { '(none)' }
    Write-Host "  Plugins : $pluginSummary" -ForegroundColor DarkGray
    Write-Host "  Prompt  : $($PromptConfig.Segments.Count) segment(s)" -ForegroundColor DarkGray
    Write-Host "  File    : $(Join-Path $env:USERPROFILE '.poshixrc.json')" -ForegroundColor DarkGray
    Write-Host ""

    if ($SkipSave) {
        Write-Host "  [dry-run] Skipping save." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    $confirm = Invoke-PoshixWalkthroughReadYesNo "  Save configuration?" $true
    if ($confirm) {
        Set-PoshixConfig -Config @{ Plugins = $SelectedPlugins }
        Set-PoshixConfig -Config @{ Prompt  = $PromptConfig }
        Save-PoshixConfig
        Write-Host "  Configuration saved." -ForegroundColor Green
    } else {
        Write-Host "  Configuration not saved." -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Invoke-PoshixWalkthroughStep6QuickStart {
    param([string[]]$EnabledPlugins)

    Write-Host "[6/6] Quick Start" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "  Core commands:" -ForegroundColor DarkGray
    Write-Host "    ls, ls -l, ls -a   " -ForegroundColor White -NoNewline
    Write-Host " Enhanced directory listing" -ForegroundColor DarkGray
    Write-Host "    cd <path>          " -ForegroundColor White -NoNewline
    Write-Host " Change directory with history" -ForegroundColor DarkGray
    Write-Host "    grep <pattern>     " -ForegroundColor White -NoNewline
    Write-Host " Search files or piped input" -ForegroundColor DarkGray
    Write-Host "    poshix-setup       " -ForegroundColor White -NoNewline
    Write-Host " Re-run this walkthrough" -ForegroundColor DarkGray
    Write-Host "    Get-PoshixConfig   " -ForegroundColor White -NoNewline
    Write-Host " View current configuration" -ForegroundColor DarkGray
    Write-Host ""

    if ($EnabledPlugins -contains 'session-layouts') {
        Write-Host "  Session Layouts:" -ForegroundColor DarkGray
        Write-Host "    layout-save <name>  " -ForegroundColor White -NoNewline
        Write-Host " Save current directory layout" -ForegroundColor DarkGray
        Write-Host "    layout-restore      " -ForegroundColor White -NoNewline
        Write-Host " Restore a saved layout" -ForegroundColor DarkGray
        Write-Host "    bm <name>           " -ForegroundColor White -NoNewline
        Write-Host " Quick directory bookmark" -ForegroundColor DarkGray
        Write-Host ""
    }

    if ($EnabledPlugins -contains 'fzf-tools') {
        Write-Host "  Fuzzy Finding (fzf-tools):" -ForegroundColor DarkGray
        Write-Host "    fh  " -ForegroundColor White -NoNewline
        Write-Host " Fuzzy history search" -ForegroundColor DarkGray
        Write-Host "    ff  " -ForegroundColor White -NoNewline
        Write-Host " Fuzzy file finder" -ForegroundColor DarkGray
        Write-Host "    fb  " -ForegroundColor White -NoNewline
        Write-Host " Fuzzy git branch checkout" -ForegroundColor DarkGray
        Write-Host "    fp  " -ForegroundColor White -NoNewline
        Write-Host " Fuzzy process kill" -ForegroundColor DarkGray
        Write-Host ""
    }

    if ($EnabledPlugins -contains 'git-worktree') {
        Write-Host "  Git Worktrees:" -ForegroundColor DarkGray
        Write-Host "    gwt         " -ForegroundColor White -NoNewline
        Write-Host " List worktrees" -ForegroundColor DarkGray
        Write-Host "    gwt-add     " -ForegroundColor White -NoNewline
        Write-Host " Create a new worktree" -ForegroundColor DarkGray
        Write-Host "    gwt-switch  " -ForegroundColor White -NoNewline
        Write-Host " Switch between worktrees" -ForegroundColor DarkGray
        Write-Host ""
    }

    if ($EnabledPlugins -contains 'task-runner') {
        Write-Host "  Task Runner:" -ForegroundColor DarkGray
        Write-Host "    tasks       " -ForegroundColor White -NoNewline
        Write-Host " List tasks in current project" -ForegroundColor DarkGray
        Write-Host "    task <name> " -ForegroundColor White -NoNewline
        Write-Host " Run a task" -ForegroundColor DarkGray
        Write-Host ""
    }

    if ($EnabledPlugins -contains 'themes') {
        Write-Host "  Themes:" -ForegroundColor DarkGray
        Write-Host "    Get-PoshixThemes    " -ForegroundColor White -NoNewline
        Write-Host " List available themes" -ForegroundColor DarkGray
        Write-Host "    Set-PoshixTheme     " -ForegroundColor White -NoNewline
        Write-Host " Apply a color theme" -ForegroundColor DarkGray
        Write-Host ""
    }

    if ($EnabledPlugins -contains 'wsl-tmux') {
        Write-Host "  WSL + tmux:" -ForegroundColor DarkGray
        Write-Host "    wtmux               " -ForegroundColor White -NoNewline
        Write-Host " Open WSL tmux in current directory" -ForegroundColor DarkGray
        Write-Host ""
    }

    if ($EnabledPlugins -contains 'docker') {
        Write-Host "  Docker:" -ForegroundColor DarkGray
        Write-Host "    dkr, dco, dps  " -ForegroundColor White -NoNewline
        Write-Host " Docker and Compose shortcuts" -ForegroundColor DarkGray
        Write-Host ""
    }

    Write-Host "  Get help:  Get-Help <command> -Full" -ForegroundColor DarkGray
    Write-Host "  Plugins:   Get-PoshixPlugin -Available -Detailed" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Setup complete. Open a new terminal or run: Import-Module poshix" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-PoshixWalkthrough {
    <#
    .SYNOPSIS
    Interactive setup walkthrough for poshix.
    .DESCRIPTION
    Guides you through profile integration, tool detection, plugin selection,
    prompt style, and saves the resulting configuration to ~/.poshixrc.json.
    .PARAMETER SkipProfile
    Skip step 1 (profile setup).
    .PARAMETER SkipSave
    Complete the walkthrough without writing the configuration file (dry-run).
    .EXAMPLE
    poshix-setup
    .EXAMPLE
    poshix-setup -SkipProfile -SkipSave
    #>
    [CmdletBinding()]
    param(
        [switch]$SkipProfile,
        [switch]$SkipSave
    )

    Invoke-PoshixWalkthroughHeader

    $tools = Get-PoshixWalkthroughDetectedTools

    if (-not $SkipProfile) {
        Invoke-PoshixWalkthroughStep1Profile
    }

    Invoke-PoshixWalkthroughStep2Tools -DetectedTools $tools

    $pluginList = [System.Collections.Generic.List[PSCustomObject]](Get-PoshixWalkthroughPluginMap -DetectedTools $tools)
    $selected   = Invoke-PoshixWalkthroughStep3Plugins -PluginList $pluginList

    $prompt = Invoke-PoshixWalkthroughStep4Prompt -Presets (Get-PoshixPromptPresets)

    Invoke-PoshixWalkthroughStep5Save -SelectedPlugins $selected -PromptConfig $prompt -SkipSave:$SkipSave

    Invoke-PoshixWalkthroughStep6QuickStart -EnabledPlugins $selected
}

Set-Item -Path "function:global:Invoke-PoshixWalkthrough" -Value ${function:Invoke-PoshixWalkthrough}
Set-Alias -Name poshix-setup -Value Invoke-PoshixWalkthrough -Scope Global

Write-Verbose "[poshix] walkthrough loaded"
