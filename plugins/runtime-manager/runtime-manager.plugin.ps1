# Cross-platform diagnostics plus opt-in Windows provisioning for the local toolchain.

$script:PoshixRuntimeManagerRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$script:PoshixToolchainDefinitions = @(
    @{ Name = 'PowerShell'; Category = 'Shell'; Command = 'pwsh'; Winget = 'Microsoft.PowerShell'; Scoop = 'pwsh' },
    @{ Name = 'PSReadLine'; Category = 'Shell'; Command = $null; Winget = $null; Scoop = $null },
    @{ Name = 'Git'; Category = 'Source control'; Command = 'git'; Winget = 'Git.Git'; Scoop = 'git' },
    @{ Name = 'GitHub CLI'; Category = 'Source control'; Command = 'gh'; Winget = 'GitHub.cli'; Scoop = 'gh' },
    @{ Name = 'Node.js'; Category = 'Runtime'; Command = 'node'; Winget = 'OpenJS.NodeJS.LTS'; Scoop = 'nodejs-lts' },
    @{ Name = 'Python'; Category = 'Runtime'; Command = 'python'; Winget = 'Python.Python.3.13'; Scoop = 'python' },
    @{ Name = '.NET SDK'; Category = 'Runtime'; Command = 'dotnet'; Winget = 'Microsoft.DotNet.SDK.10'; Scoop = 'dotnet-sdk' },
    @{ Name = 'Java'; Category = 'Runtime'; Command = 'java'; Winget = 'EclipseAdoptium.Temurin.21.JDK'; Scoop = 'temurin21-jdk' },
    @{ Name = 'Docker'; Category = 'Containers'; Command = 'docker'; Winget = 'Docker.DockerDesktop'; Scoop = 'docker' },
    @{ Name = 'WSL'; Category = 'Windows / WSL'; Command = 'wsl'; Winget = 'Microsoft.WSL'; Scoop = 'wsl' },
    @{ Name = 'kubectl'; Category = 'Kubernetes'; Command = 'kubectl'; Winget = 'Kubernetes.kubectl'; Scoop = 'kubectl' },
    @{ Name = 'OpenSSH'; Category = 'Remote access'; Command = 'ssh'; Winget = $null; Scoop = 'openssh' }
)

function New-PoshixToolchainResult {
    param($Definition, [string]$Status, [string]$Version, [string]$Path, [string]$Source, [string]$Reason, [string]$Remediation)
    [PSCustomObject][ordered]@{
        Name = $Definition.Name; Category = $Definition.Category; Status = $Status; Version = $Version; Path = $Path
        Source = $Source; Reason = $Reason; Remediation = $Remediation
        InstallCommand = if ($Definition.Winget) { "poshix env install '$($Definition.Name)'" } else { $null }
    }
}

function Get-PoshixToolchainCommand {
    param([string]$Name)
    Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Get-PoshixRuntimeManagerConfig {
    if (Get-Command Get-PoshixConfig -ErrorAction SilentlyContinue) { return Get-PoshixConfig }
    return $null
}

function Get-PoshixCommandVersion {
    param($Command)
    if (-not $Command) { return $null }
    try {
        $output = & $Command.Source --version 2>$null | Select-Object -First 1
        if ($LASTEXITCODE -eq 0 -and $output) { return $output.ToString().Trim() }
    } catch {}
    return $null
}

function Get-PoshixToolchain {
    <# .SYNOPSIS Discover local developer tools without installing or changing them. #>
    [CmdletBinding()]
    param([string[]]$Name)

    $definitions = if ($Name) { $script:PoshixToolchainDefinitions | Where-Object { $_.Name -in $Name } } else { $script:PoshixToolchainDefinitions }
    foreach ($definition in $definitions) {
        if ($definition.Name -eq 'PowerShell') {
            New-PoshixToolchainResult $definition 'Available' $PSVersionTable.PSVersion.ToString() $PSHOME 'Current session' $null $null
            continue
        }
        if ($definition.Name -eq 'PSReadLine') {
            $module = Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
            if ($module) { New-PoshixToolchainResult $definition 'Available' $module.Version.ToString() $module.ModuleBase 'PowerShell module' $null $null }
            else { New-PoshixToolchainResult $definition 'Missing' $null $null $null 'PSReadLine is not installed.' 'Install-Module PSReadLine -Scope CurrentUser' }
            continue
        }
        if ($definition.Name -eq 'Docker' -and (Get-Command Resolve-PoshixDockerBackend -ErrorAction SilentlyContinue)) {
            $docker = Resolve-PoshixDockerBackend
            $status = if ($docker.Status -eq 'Available') { 'Available' } elseif ($docker.Status -eq 'Checking') { 'Checking' } elseif ($docker.Status -eq 'NotFound') { 'Missing' } else { 'Unavailable' }
            New-PoshixToolchainResult $definition $status $docker.Version $docker.Command $docker.Source $docker.Reason $docker.Remediation
            continue
        }
        if ($definition.Name -eq 'WSL' -and (Get-Command Get-WslStatus -ErrorAction SilentlyContinue)) {
            $wsl = Get-WslStatus
            $status = if ($wsl.Status -eq 'Available') { 'Available' } elseif ($wsl.Status -eq 'AccessDenied') { 'Unavailable' } else { 'Missing' }
            $wslCommand = Get-PoshixToolchainCommand 'wsl'
            New-PoshixToolchainResult $definition $status $wsl.DefaultVersion $wslCommand.Source 'WSL probe' $wsl.Reason $(if ($status -ne 'Available') { 'Run: wsl --install, then restart this shell.' } else { $null })
            continue
        }
        $command = Get-PoshixToolchainCommand $definition.Command
        if (-not $command) {
            New-PoshixToolchainResult $definition 'Missing' $null $null $null "'$($definition.Command)' was not found on PATH." "Install $($definition.Name), then restart this shell."
            continue
        }
        $status = 'Available'; $reason = $null
        New-PoshixToolchainResult $definition $status (Get-PoshixCommandVersion $command) $command.Source $command.CommandType.ToString() $reason $(if ($reason) { 'Run: gh auth login' } else { $null })
    }

    if (-not $Name -and (Get-Command Get-PoshixAgentTool -ErrorAction SilentlyContinue)) {
        Get-PoshixAgentTool | ForEach-Object {
            [PSCustomObject][ordered]@{ Name = $_.Name; Category = 'Agent tools'; Status = if ($_.Available) { 'Available' } else { 'Missing' }; Version = $null; Path = $_.Command; Source = $_.CommandType; Reason = $null; Remediation = $_.Remediation; InstallCommand = $null }
        }
    }
}

function Test-PoshixToolchain {
    <# .SYNOPSIS Return toolchain diagnostics, or a single healthy/unhealthy result. #>
    [CmdletBinding()]
    param([string[]]$Name, [switch]$Healthy)
    $result = @(Get-PoshixToolchain -Name $Name)
    if ($Healthy) { return ($result | Where-Object Status -ne 'Available').Count -eq 0 }
    $result
}

function Get-PoshixDoctorReport {
    <# .SYNOPSIS Produce a stable, automation-friendly Poshix environment report. #>
    [CmdletBinding()]
    param([switch]$AsJson)
    $tools = @(Get-PoshixToolchain)
    $pluginProfile = if (Get-Command Get-PoshixPluginLoadProfile -ErrorAction SilentlyContinue) { @(Get-PoshixPluginLoadProfile) } else { @() }
    $report = [PSCustomObject][ordered]@{
        GeneratedAt = (Get-Date).ToUniversalTime().ToString('o'); Host = $env:COMPUTERNAME; PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Tools = $tools
        Plugins = $pluginProfile
        Summary = [PSCustomObject][ordered]@{ Available = @($tools | Where-Object Status -eq 'Available').Count; Missing = @($tools | Where-Object Status -eq 'Missing').Count; Attention = @($tools | Where-Object Status -notin @('Available', 'Missing')).Count; PluginCount = $pluginProfile.Count; PluginLoadMilliseconds = [math]::Round((@($pluginProfile | Measure-Object LoadMilliseconds -Sum).Sum), 1) }
    }
    if ($AsJson) { return $report | ConvertTo-Json -Depth 8 }
    $report
}

function Get-PoshixTableCellColor {
    param([string]$Column, [string]$Value)
    if ($Column -eq 'Status') {
        if ($Value -in @('Available', 'Loaded', 'Ready')) { return 'Green' }
        if ($Value -in @('Missing', 'Failed', 'NotFound')) { return 'Red' }
        return 'Yellow'
    }
    if ($Column -eq 'LoadMilliseconds') {
        $milliseconds = 0.0
        if ([double]::TryParse($Value, [ref]$milliseconds)) {
            if ($milliseconds -ge 200) { return 'Red' }
            if ($milliseconds -ge 75) { return 'Yellow' }
            return 'Green'
        }
    }
    switch ($Column) {
        'Name' { 'Cyan' }
        'Command' { 'Cyan' }
        'Target' { 'Magenta' }
        'Path' { 'DarkGray' }
        'Category' { 'DarkGray' }
        'Reason' { 'Yellow' }
        'Remediation' { 'Magenta' }
        'Effects' { if ($Value -eq 'None') { 'DarkGreen' } else { 'Yellow' } }
        default { 'White' }
    }
}

function Write-PoshixColorTable {
    <# .SYNOPSIS Render objects in a compact, semantic-color terminal table. #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Rows, [Parameter(Mandatory)][string[]]$Columns, [int]$MaximumColumnWidth = 34)
    if ($Rows.Count -eq 0) { Write-Host '  (none)' -ForegroundColor DarkGray; return }
    $displayRows = foreach ($row in $Rows) {
        $values = [ordered]@{}
        foreach ($column in $Columns) {
            $value = $row.$column
            $text = if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) { '-' } else { [string]$value }
            if ($text.Length -gt $MaximumColumnWidth) { $text = $text.Substring(0, $MaximumColumnWidth - 1) + '…' }
            $values[$column] = $text
        }
        [PSCustomObject]$values
    }
    $widths = @{}
    foreach ($column in $Columns) {
        $widths[$column] = [Math]::Max($column.Length, (@($displayRows | ForEach-Object { $_.$column.Length } | Measure-Object -Maximum).Maximum))
    }
    foreach ($column in $Columns) { Write-Host $column.PadRight($widths[$column] + 2) -NoNewline -ForegroundColor Blue }
    Write-Host ''
    foreach ($row in $displayRows) {
        foreach ($column in $Columns) {
            Write-Host $row.$column.PadRight($widths[$column] + 2) -NoNewline -ForegroundColor (Get-PoshixTableCellColor -Column $column -Value $row.$column)
        }
        Write-Host ''
    }
}

function Show-PoshixDoctorReport {
    <# .SYNOPSIS Render the Poshix doctor report for an interactive terminal. #>
    [CmdletBinding()]
    param()
    $report = Get-PoshixDoctorReport
    Write-Host "`nPoshix Doctor" -ForegroundColor Cyan
    Write-Host ("{0}  PowerShell {1}" -f $report.Host, $report.PowerShellVersion) -ForegroundColor DarkGray
    Write-Host ("Tools: {0} available, {1} missing, {2} need attention" -f $report.Summary.Available, $report.Summary.Missing, $report.Summary.Attention) -ForegroundColor $(if ($report.Summary.Missing -or $report.Summary.Attention) { 'Yellow' } else { 'Green' })

    Write-Host "`nToolchain" -ForegroundColor Yellow
    Write-PoshixColorTable -Rows @($report.Tools) -Columns Name, Category, Status, Version

    $needsAttention = @($report.Tools | Where-Object { $_.Status -ne 'Available' })
    if ($needsAttention.Count) {
        Write-Host "Needs attention" -ForegroundColor Yellow
        Write-PoshixColorTable -Rows $needsAttention -Columns Name, Status, Reason, Remediation
    }

    if ($report.Plugins.Count) {
        Write-Host ("Slowest plugins ({0} total, {1} ms overall)" -f $report.Summary.PluginCount, $report.Summary.PluginLoadMilliseconds) -ForegroundColor Yellow
        Write-PoshixColorTable -Rows @($report.Plugins | Select-Object -First 5) -Columns Name, Status, LoadMilliseconds, Path
        if ($report.Plugins.Count -gt 5) { Write-Host "Run 'poshix doctor --plugins' for all plugin timings." -ForegroundColor DarkGray }
    }
    Write-Host "Run 'poshix doctor --json' for automation-friendly output." -ForegroundColor DarkGray
}

function Get-PoshixConfiguredPackageManagers {
    $config = Get-PoshixRuntimeManagerConfig
    $configured = if ($config -and $config.PackageManagers) { @($config.PackageManagers) } else { @('winget', 'scoop') }
    foreach ($manager in $configured) { if (Get-PoshixToolchainCommand $manager) { $manager } }
}

function Install-PoshixToolchain {
    <# .SYNOPSIS Explicitly install a supported tool using an installed Windows package manager. #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory, Position = 0)][string[]]$Name, [string]$PackageManager)
    foreach ($requestedName in $Name) {
        $definition = $script:PoshixToolchainDefinitions | Where-Object Name -eq $requestedName | Select-Object -First 1
        if (-not $definition) { Write-Error "[poshix] '$requestedName' is not a provisionable Poshix tool."; continue }
        if ($definition.Name -eq 'PSReadLine') {
            if ($PSCmdlet.ShouldProcess('PSReadLine', 'Install PowerShell module for CurrentUser')) { Install-Module PSReadLine -Scope CurrentUser -Force }
            continue
        }
        $managers = if ($PackageManager) { @($PackageManager) } else { @(Get-PoshixConfiguredPackageManagers) }
        $manager = $managers | Where-Object { ($_.ToLowerInvariant() -eq 'winget' -and $definition.Winget) -or ($_.ToLowerInvariant() -eq 'scoop' -and $definition.Scoop) } | Select-Object -First 1
        if (-not $manager) { Write-Error "[poshix] No configured, installed package manager can install $($definition.Name)."; continue }
        $package = if ($manager -eq 'winget') { $definition.Winget } else { $definition.Scoop }
        if ($PSCmdlet.ShouldProcess($definition.Name, "Install via $manager package '$package'")) {
            if ($manager -eq 'winget') { & winget install --id $package --exact --accept-package-agreements --accept-source-agreements }
            else { & scoop install $package }
        }
    }
}

function Get-PoshixVersion {
    $manifest = Import-PowerShellDataFile -Path (Join-Path $script:PoshixRuntimeManagerRoot 'Poshix.psd1')
    $manifest.ModuleVersion
}

function Get-PoshixUpdateStatus {
    <# .SYNOPSIS Read the throttled update cache; use -Check to query GitHub now. #>
    [CmdletBinding()]
    param([switch]$Check)
    $cacheDirectory = Join-Path $HOME '.poshix'
    $cachePath = Join-Path $cacheDirectory 'update.json'
    $cache = $null
    if (Test-Path -LiteralPath $cachePath) { try { $cache = Get-Content $cachePath -Raw | ConvertFrom-Json } catch {} }
    if ($Check) {
        try {
            $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/punassuming/poshix/releases/latest' -Headers @{ 'User-Agent' = 'Poshix' } -TimeoutSec 5
            $cache = [PSCustomObject]@{ CheckedAt = (Get-Date).ToUniversalTime().ToString('o'); LatestVersion = $release.tag_name.TrimStart('v'); ReleaseUrl = $release.html_url; Error = $null }
            if (-not (Test-Path -LiteralPath $cacheDirectory)) { New-Item -ItemType Directory -Path $cacheDirectory -Force | Out-Null }
            $cache | ConvertTo-Json | Set-Content -LiteralPath $cachePath -Encoding UTF8
        } catch {
            if (-not $cache) { $cache = [PSCustomObject]@{ CheckedAt = $null; LatestVersion = $null; ReleaseUrl = $null; Error = $_.Exception.Message } }
        }
    }
    if (-not $cache) { $cache = [PSCustomObject]@{ CheckedAt = $null; LatestVersion = $null; ReleaseUrl = $null; Error = $null } }
    $local = Get-PoshixVersion
    [PSCustomObject][ordered]@{ LocalVersion = $local; LatestVersion = $cache.LatestVersion; UpdateAvailable = if ($cache.LatestVersion) { [version]$cache.LatestVersion -gt [version]$local } else { $false }; CheckedAt = $cache.CheckedAt; ReleaseUrl = $cache.ReleaseUrl; Error = $cache.Error }
}

function Update-Poshix {
    <# .SYNOPSIS Update Poshix only when explicitly invoked. #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param([switch]$Check)
    if ($Check) { return Get-PoshixUpdateStatus -Check }
    if (Test-Path -LiteralPath (Join-Path $script:PoshixRuntimeManagerRoot '.git')) {
        if ($PSCmdlet.ShouldProcess($script:PoshixRuntimeManagerRoot, 'Fast-forward pull from the configured Git remote')) { & git -C $script:PoshixRuntimeManagerRoot pull --ff-only }
        return
    }
    if ($PSCmdlet.ShouldProcess('Poshix', 'Update PowerShell Gallery module for CurrentUser')) { Update-Module Poshix -Scope CurrentUser }
}

function Get-PoshixHelp {
    <# .SYNOPSIS Return the built-in Poshix command catalog as structured objects. #>
    [CmdletBinding()]
    param()
    @(
        [PSCustomObject][ordered]@{ Command = 'poshix help'; Purpose = 'Show this catalog.'; Effects = 'None' }
        [PSCustomObject][ordered]@{ Command = 'poshix doctor [--json|--plugins]'; Purpose = 'Diagnose tools and plugin load time.'; Effects = 'None' }
        [PSCustomObject][ordered]@{ Command = 'poshix env [list|install <tool>]'; Purpose = 'List or install supported tools.'; Effects = 'Install confirms' }
        [PSCustomObject][ordered]@{ Command = 'poshix update [--check]'; Purpose = 'Check for a release or update.'; Effects = 'Update confirms' }
        [PSCustomObject][ordered]@{ Command = 'poshix version'; Purpose = 'Show local module version.'; Effects = 'None' }
        [PSCustomObject][ordered]@{ Command = 'poshix-help [-Section <name>]'; Purpose = 'Open commands, aliases, shortcuts.'; Effects = 'Needs command-center' }
    )
}

function Invoke-Poshix {
    <# .SYNOPSIS Poshix command-line entry point: help, doctor, env, update, version. #>
    [CmdletBinding()]
    param([Parameter(Position = 0)][string]$Command = 'doctor', [Parameter(Position = 1, ValueFromRemainingArguments)][string[]]$Arguments)
    switch ($Command.ToLowerInvariant()) {
        'help' {
            if (Get-Command Get-PoshixCommandCenter -ErrorAction SilentlyContinue) { Get-PoshixCommandCenter }
            else {
                Write-Host "`nPoshix Command Catalog" -ForegroundColor Cyan
                Write-PoshixColorTable -Rows @(Get-PoshixHelp) -Columns Command, Purpose, Effects
                Write-Host "Enable the 'command-center' plugin for aliases and keyboard shortcuts." -ForegroundColor DarkGray
            }
        }
        'doctor' {
            if ($Arguments -contains '--json') { Get-PoshixDoctorReport -AsJson }
            elseif ($Arguments -contains '--plugins') {
                Write-PoshixColorTable -Rows @(Get-PoshixPluginLoadProfile) -Columns Name, Status, LoadMilliseconds, Path, Error
            }
            else { Show-PoshixDoctorReport }
        }
        'env' { if ($Arguments.Count -eq 0 -or $Arguments[0] -eq 'list') { Get-PoshixToolchain } elseif ($Arguments[0] -eq 'install' -and $Arguments.Count -gt 1) { Install-PoshixToolchain -Name $Arguments[1] } else { throw 'Usage: poshix env [list|install <tool>]' } }
        'update' { if ($Arguments -contains '--check') { Update-Poshix -Check } else { Update-Poshix } }
        'version' { Get-PoshixVersion }
        default { throw 'Usage: poshix [help|doctor [--json|--plugins]|env|update|version]' }
    }
}

# Public commands are intentionally global so they remain available after plugin
# loading. Their implementation calls these helpers, which must share that scope.
foreach ($functionName in @('New-PoshixToolchainResult', 'Get-PoshixToolchainCommand', 'Get-PoshixRuntimeManagerConfig', 'Get-PoshixCommandVersion', 'Get-PoshixConfiguredPackageManagers', 'Get-PoshixToolchain', 'Test-PoshixToolchain', 'Get-PoshixDoctorReport', 'Get-PoshixTableCellColor', 'Write-PoshixColorTable', 'Show-PoshixDoctorReport', 'Install-PoshixToolchain', 'Get-PoshixUpdateStatus', 'Update-Poshix', 'Get-PoshixHelp', 'Invoke-Poshix', 'Get-PoshixVersion')) {
    Set-Item -Path "function:global:$functionName" -Value (Get-Item -Path "function:$functionName").ScriptBlock
}
Set-Alias -Name poshix -Value Invoke-Poshix -Scope Global -Force

Write-Verbose '[poshix] runtime-manager plugin loaded'
