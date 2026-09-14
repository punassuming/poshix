# Command discovery and PSReadLine shortcuts for Poshix.

$script:PoshixKeybindings = @(
    [PSCustomObject]@{ Key = 'Alt+h'; Action = 'Select Herdr layout'; Command = 'Start-PoshixHerdrWorkArea'; Mode = 'Run' }
    [PSCustomObject]@{ Key = 'Alt+y'; Action = 'Open Yazi'; Command = 'Start-PoshixYazi'; Mode = 'Run' }
    [PSCustomObject]@{ Key = 'Alt+f'; Action = 'Open focused Yazi'; Command = 'Start-PoshixYaziFocused'; Mode = 'Run' }
    [PSCustomObject]@{ Key = 'Alt+g'; Action = 'Open LazyGit'; Command = 'Start-PoshixGitUi'; Mode = 'Run' }
    [PSCustomObject]@{ Key = 'Alt+n'; Action = 'Open Neovim'; Command = 'Start-PoshixNeovim'; Mode = 'Run' }
    [PSCustomObject]@{ Key = 'Alt+a'; Action = 'Choose coding agent'; Command = 'Start-PoshixAgentPicker'; Mode = 'Run' }
    [PSCustomObject]@{ Key = 'Alt+v'; Action = 'Save clipboard here'; Command = 'Save-PoshixClipboard'; Mode = 'Run' }
    [PSCustomObject]@{ Key = 'Alt+r'; Action = 'Prepare runtime report'; Command = 'Get-PoshixRuntimeReport'; Mode = 'Insert' }
)

function Get-PoshixClipboardDestination {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][ValidateSet('txt', 'png')][string]$Extension
    )
    $stem = Get-Date -Format 'yyyyMMdd_HHmmss'
    $candidate = Join-Path $Directory "$stem.$Extension"
    $suffix = 1
    while (Test-Path -LiteralPath $candidate) {
        $candidate = Join-Path $Directory "${stem}_$suffix.$Extension"
        $suffix++
    }
    return $candidate
}

function Save-PoshixClipboardImage {
    param([Parameter(Mandatory)][string]$Path)
    if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) { return $false }

    try {
        $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        if (-not (Test-Path -LiteralPath $windowsPowerShell -PathType Leaf)) { return $false }
        $escapedPath = $Path.Replace("'", "''")
        $captureScript = @"
`$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
for (`$attempt = 0; `$attempt -lt 5; `$attempt++) {
    try {
        if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) { exit 2 }
        `$image = [System.Windows.Forms.Clipboard]::GetImage()
        if (`$null -eq `$image) { exit 2 }
        try { `$image.Save('$escapedPath', [System.Drawing.Imaging.ImageFormat]::Png) } finally { `$image.Dispose() }
        exit 0
    } catch [System.Runtime.InteropServices.ExternalException] {
        if (`$attempt -eq 4) { throw }
        Start-Sleep -Milliseconds 40
    }
}
"@
        $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($captureScript))
        & $windowsPowerShell -NoLogo -NoProfile -NonInteractive -STA -EncodedCommand $encodedCommand *> $null
        return ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $Path -PathType Leaf))
    } catch {
        Write-Verbose "[poshix] Clipboard image capture unavailable: $($_.Exception.Message)"
        return $false
    }
}

function Save-PoshixClipboard {
    <# .SYNOPSIS Save clipboard image or text into the current filesystem directory. #>
    [CmdletBinding()]
    param([switch]$PassThru)

    $location = Get-Location
    if ($location.Provider.Name -ne 'FileSystem' -or -not (Test-Path -LiteralPath $location.ProviderPath -PathType Container)) {
        throw '[poshix] Clipboard content can only be saved from a filesystem directory.'
    }

    $imagePath = Get-PoshixClipboardDestination -Directory $location.ProviderPath -Extension png
    if (Save-PoshixClipboardImage -Path $imagePath) {
        Write-Host '[poshix] Saved clipboard image: ' -ForegroundColor Green -NoNewline
        Write-Host $imagePath -ForegroundColor Cyan
        if ($PassThru) { return Get-Item -LiteralPath $imagePath }
        return
    }

    $text = Get-Clipboard -Raw -ErrorAction Stop
    if ([string]::IsNullOrEmpty([string]$text)) {
        Write-Warning '[poshix] The clipboard does not contain an image or text.'
        return
    }
    $textPath = Get-PoshixClipboardDestination -Directory $location.ProviderPath -Extension txt
    Set-Content -LiteralPath $textPath -Value ([string]$text) -Encoding utf8 -NoNewline
    Write-Host '[poshix] Saved clipboard text: ' -ForegroundColor Green -NoNewline
    Write-Host $textPath -ForegroundColor Cyan
    if ($PassThru) { return Get-Item -LiteralPath $textPath }
}

function Get-PoshixCommandCenterItems {
    $functionPattern = '^(Get|Set|Start|Save|Restore|Remove|Invoke|Find|Search|New|Clear|Export|Import|Test|Enable|Disable|Install|Update)-?(Poshix|Docker|Wsl|WindowsTerminal|Git|Session|Layout|Agent)|^(Get-DockerStatus|Get-DockerBackendInfo|Get-DockerPromptInfo|Get-WslDistribution|Get-WslStatus|Invoke-WslCommand)$'
    $aliases = @(Get-Alias | Where-Object {
        $_.Definition -match $functionPattern -or
        $_.Definition -match '^(Find-Files|Find-InFiles|New-File|Get-CommandPath|Get-WorkingDirectory|Clear-Screen|Set-LocationTo|Get-LocationStack|Invoke-DockerCli|Invoke-DockerCompose)$'
    })
    $functions = @(Get-Command -CommandType Function -ErrorAction SilentlyContinue | Where-Object Name -Match $functionPattern)
    $commandNames = @(
        $functions.Name
        $aliases.Definition
        $script:PoshixKeybindings.Command
    ) | Where-Object { $_ } | Sort-Object -Unique

    $boundKeys = @()
    if (Get-Command Get-PSReadLineKeyHandler -ErrorAction SilentlyContinue) {
        $boundKeys = @(Get-PSReadLineKeyHandler -Bound | Select-Object -ExpandProperty Key)
    }

    foreach ($commandName in $commandNames) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue | Where-Object CommandType -Ne Alias | Select-Object -First 1
        $commandAliases = @($aliases | Where-Object Definition -Eq $commandName | Select-Object -ExpandProperty Name | Sort-Object)
        $commandShortcuts = @($script:PoshixKeybindings | Where-Object Command -Eq $commandName)
        $shortcutLabels = @($commandShortcuts | ForEach-Object {
            $state = if ($_.Key -in $boundKeys) { 'registered' } else { 'not registered' }
            "$($_.Key) ($state)"
        })
        $actions = @($commandShortcuts | Select-Object -ExpandProperty Action -Unique)
        [PSCustomObject]@{
            Section = 'Commands'
            Name = $commandName
            Target = $commandName
            Aliases = $commandAliases -join ', '
            Shortcuts = $shortcutLabels -join ', '
            Mode = @($commandShortcuts | Select-Object -ExpandProperty Mode -Unique) -join ', '
            Status = if ($command) { 'Available' } else { 'Unavailable' }
            Description = if ($actions.Count) { $actions -join '; ' } elseif ($commandAliases.Count) { 'Command alias' } else { [string]$command.CommandType }
        }
    }
}

function Get-PoshixCommandCenter {
    <# .SYNOPSIS Open the searchable Poshix command palette or show its command catalog. #>
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Commands', 'Aliases', 'Shortcuts')][string]$Section = 'All',
        [string]$Filter,
        [switch]$AsObject,
        [switch]$List
    )
    $items = Get-PoshixCommandCenterItems
    if ($Section -eq 'Aliases') { $items = @($items | Where-Object Aliases) }
    elseif ($Section -eq 'Shortcuts') { $items = @($items | Where-Object Shortcuts) }
    if ($Filter) {
        $items = @($items | Where-Object {
            $_.Name -like "*$Filter*" -or $_.Aliases -like "*$Filter*" -or
            $_.Shortcuts -like "*$Filter*" -or $_.Description -like "*$Filter*"
        })
    }
    if ($AsObject) { return $items }
    if (-not $List -and -not $Filter -and $Section -eq 'All' -and (Get-Command fzf -ErrorAction SilentlyContinue)) {
        return Show-PoshixCommandPalette -Items $items
    }
    Write-Host "`nPoshix Command Center" -ForegroundColor Cyan
    if (Get-Command Write-PoshixColorTable -ErrorAction SilentlyContinue) {
        Write-PoshixColorTable -Rows $items -Columns Name, Aliases, Shortcuts, Mode, Status, Description
    } else {
        $items | Select-Object Name, Aliases, Shortcuts, Mode, Status, Description | Format-Table -AutoSize | Out-Host
    }
    Write-Host "Use 'poshix-help' for the searchable palette; -Section Aliases/Shortcuts filters this unified view." -ForegroundColor DarkGray
}

function Show-PoshixCommandPalette {
    <# .SYNOPSIS Search Poshix commands, aliases, and shortcuts in an fzf terminal modal. #>
    [CmdletBinding()]
    param([object[]]$Items = @(Get-PoshixCommandCenterItems))
    $fzf = Get-Command fzf -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $fzf) { Write-Warning '[poshix] fzf is not available; use poshix-help -List or install fzf.'; return }
    $escape = [char]27
    $reset = "${escape}[0m"
    $lines = $Items | ForEach-Object {
        $statusColor = if ($_.Status -eq 'Available') { '32' } else { '31' }
        "${escape}[36m$($_.Name)$reset`t${escape}[95m$($_.Aliases)$reset`t${escape}[34m$($_.Shortcuts)$reset`t${escape}[${statusColor}m$($_.Status)$reset`t${escape}[90m$($_.Description)$reset"
    }
    $selected = $lines | & $fzf.Source --ansi --height '80%' --layout reverse --border --prompt 'Poshix> ' --delimiter "`t" --with-nth '1,2,3,4,5'
    if (-not $selected) { return }
    $plainSelected = [regex]::Replace($selected, '\x1B\[[0-?]*[ -/]*[@-~]', '')
    $fields = $plainSelected -split "`t", 5
    $commandText = $fields[0]
    if ($commandText -and (Get-Command 'Set-PSReadLineKeyHandler' -ErrorAction SilentlyContinue)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($commandText)
    } else {
        Write-Host $commandText -ForegroundColor Cyan
    }
}

function Set-PoshixInsertKeyHandler {
    param([Parameter(Mandatory)][string]$Chord, [Parameter(Mandatory)][string]$Text)
    Set-PSReadLineKeyHandler -Chord $Chord -ScriptBlock ([scriptblock]::Create("[Microsoft.PowerShell.PSConsoleReadLine]::Insert('$($Text.Replace("'", "''"))')"))
}

function Set-PoshixRunKeyHandler {
    param([Parameter(Mandatory)][string]$Chord, [Parameter(Mandatory)][string]$Command)
    Set-PSReadLineKeyHandler -Chord $Chord -ScriptBlock ([scriptblock]::Create(@"
[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
if (Get-Command '$Command' -ErrorAction SilentlyContinue) {
    & '$Command'
} else {
    Write-Warning '[poshix] $Command is unavailable. Load agent-tools or install its required tool.'
}
[Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
"@))
}

function Enable-PoshixKeybindings {
    <# .SYNOPSIS Register Poshix PSReadLine keyboard shortcuts for this session. #>
    [CmdletBinding()]
    param()
    if (-not (Get-Command Set-PSReadLineKeyHandler -ErrorAction SilentlyContinue)) {
        Write-Verbose '[poshix] PSReadLine is unavailable; keyboard shortcuts were not registered.'
        return $false
    }
    Set-PoshixRunKeyHandler -Chord 'Alt+h' -Command 'Start-PoshixHerdrWorkArea'
    Set-PoshixRunKeyHandler -Chord 'Alt+y' -Command 'Start-PoshixYazi'
    Set-PoshixRunKeyHandler -Chord 'Alt+f' -Command 'Start-PoshixYaziFocused'
    Set-PoshixRunKeyHandler -Chord 'Alt+g' -Command 'Start-PoshixGitUi'
    Set-PoshixRunKeyHandler -Chord 'Alt+n' -Command 'Start-PoshixNeovim'
    Set-PoshixRunKeyHandler -Chord 'Alt+a' -Command 'Start-PoshixAgentPicker'
    Set-PoshixRunKeyHandler -Chord 'Alt+v' -Command 'Save-PoshixClipboard'
    Set-PoshixInsertKeyHandler -Chord 'Alt+r' -Text 'Get-PoshixRuntimeReport'
    return $true
}

function Disable-PoshixKeybindings {
    <# .SYNOPSIS Remove Poshix-specific PSReadLine shortcuts from this session. #>
    [CmdletBinding()]
    param()
    if (-not (Get-Command Remove-PSReadLineKeyHandler -ErrorAction SilentlyContinue)) { return $false }
    foreach ($shortcut in $script:PoshixKeybindings) { Remove-PSReadLineKeyHandler -Chord $shortcut.Key -ErrorAction SilentlyContinue }
    return $true
}

# Global command-center functions depend on these helpers after the plugin scope
# has returned, so export the complete call chain.
Set-Item -Path 'function:global:Get-PoshixCommandCenterItems' -Value ${function:Get-PoshixCommandCenterItems}
Set-Item -Path 'function:global:Get-PoshixClipboardDestination' -Value ${function:Get-PoshixClipboardDestination}
Set-Item -Path 'function:global:Save-PoshixClipboardImage' -Value ${function:Save-PoshixClipboardImage}
Set-Item -Path 'function:global:Save-PoshixClipboard' -Value ${function:Save-PoshixClipboard}
Set-Item -Path 'function:global:Set-PoshixInsertKeyHandler' -Value ${function:Set-PoshixInsertKeyHandler}
Set-Item -Path 'function:global:Set-PoshixRunKeyHandler' -Value ${function:Set-PoshixRunKeyHandler}
Set-Item -Path 'function:global:Show-PoshixCommandPalette' -Value ${function:Show-PoshixCommandPalette}
Set-Item -Path 'function:global:Get-PoshixCommandCenter' -Value ${function:Get-PoshixCommandCenter}
Set-Item -Path 'function:global:Enable-PoshixKeybindings' -Value ${function:Enable-PoshixKeybindings}
Set-Item -Path 'function:global:Disable-PoshixKeybindings' -Value ${function:Disable-PoshixKeybindings}
Set-Alias -Name poshix-help -Value Get-PoshixCommandCenter -Scope Global -Force

$config = Get-PoshixConfig
if (-not $config.Keybindings -or $config.Keybindings.Enabled -ne $false) { Enable-PoshixKeybindings | Out-Null }
Write-Verbose '[poshix] command-center plugin loaded'
