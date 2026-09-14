# Project-aware integrations for terminal utilities and coding agents.

$script:PoshixAgentToolDefinitions = @{
    Yazi = @{ Command = 'yazi'; Kind = $null; Interactive = $true }
    LazyGit = @{ Command = 'lazygit'; Kind = $null; Interactive = $true }
    Neovim = @{ Command = 'nvim'; Kind = $null; Interactive = $true }
    Herdr = @{ Command = 'herdr'; Kind = $null; Interactive = $true }
    Claude = @{ Command = 'claude'; Kind = 'claude'; Interactive = $true }
    Codex = @{ Command = 'codex'; Kind = 'codex'; Interactive = $true }
    Copilot = @{ Command = 'copilot'; Kind = 'copilot'; Interactive = $true }
}

function Get-PoshixAgentTool {
    <# .SYNOPSIS Return discovered terminal-tool and agent executables. #>
    [CmdletBinding()]
    param([ValidateSet('Yazi', 'LazyGit', 'Neovim', 'Herdr', 'Claude', 'Codex', 'Copilot')][string[]]$Name = @('Yazi', 'LazyGit', 'Neovim', 'Herdr', 'Claude', 'Codex', 'Copilot'))

    foreach ($toolName in $Name) {
        $definition = $script:PoshixAgentToolDefinitions[$toolName]
        $command = Get-Command $definition.Command -ErrorAction SilentlyContinue | Select-Object -First 1
        [PSCustomObject]@{
            Name = $toolName
            CommandName = $definition.Command
            Available = $null -ne $command
            Command = if ($command) { $command.Source } else { $null }
            CommandType = if ($command) { $command.CommandType.ToString() } else { $null }
            Interactive = $definition.Interactive
            HerdrKind = $definition.Kind
            Remediation = if ($command) { $null } else { "Install or add '$($definition.Command)' to PATH for this session." }
        }
    }
}

function Get-PoshixProjectRoot {
    param([string]$Path = (Get-Location).Path)
    $git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $git) { return $Path }
    $root = & $git.Source -C $Path rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $root) { return $root.ToString().Trim() }
    return $Path
}

function Start-PoshixAgent {
    <# .SYNOPSIS Launch an installed coding agent in a chosen project directory. #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][ValidateSet('Claude', 'Codex', 'Copilot')][string]$Tool,
        [string]$WorkingDirectory = (Get-Location).Path,
        [Parameter(Position = 1, ValueFromRemainingArguments)][string[]]$Arguments
    )
    if (-not $Tool) { return Start-PoshixAgentPicker -WorkingDirectory $WorkingDirectory }
    if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) { throw "Working directory does not exist: $WorkingDirectory" }
    $agent = Get-PoshixAgentTool -Name $Tool
    if (-not $agent.Available) { Write-Warning "[poshix] $($agent.Remediation)"; return }
    Push-Location $WorkingDirectory
    try { & $agent.Command @Arguments } finally { Pop-Location }
}

function Start-PoshixAgentPicker {
    <# .SYNOPSIS Select an installed coding agent with fzf and launch it in the current project. #>
    [CmdletBinding()]
    param([string]$WorkingDirectory = (Get-Location).Path)
    if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) { throw "Working directory does not exist: $WorkingDirectory" }
    $agents = @(Get-PoshixAgentTool -Name Claude, Codex, Copilot | Where-Object Available)
    if ($agents.Count -eq 0) { Write-Warning '[poshix] No supported coding agent is installed. Install Claude, Codex, or Copilot and ensure it is on PATH.'; return }
    $fzf = Get-Command fzf -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $fzf) {
        if ($agents.Count -eq 1) { return Start-PoshixAgent -Tool $agents[0].Name -WorkingDirectory $WorkingDirectory }
        Write-Warning '[poshix] fzf is required to choose between installed coding agents. Run: scoop install fzf'
        return
    }
    $escape = [char]27
    $reset = "${escape}[0m"
    $selected = $agents | ForEach-Object { "${escape}[36m$($_.Name)$reset`t${escape}[90m$($_.Command)$reset" } |
        & $fzf.Source --ansi --height '40%' --layout reverse --border --prompt 'Agent> ' --delimiter "`t" --with-nth '1,2'
    if (-not $selected) { return }
    $tool = ([regex]::Replace($selected, '\x1B\[[0-?]*[ -/]*[@-~]', '') -split "`t", 2)[0]
    Start-PoshixAgent -Tool $tool -WorkingDirectory $WorkingDirectory
}

function Start-PoshixYazi {
    <# .SYNOPSIS Open Yazi and apply its selected cwd when it exits. #>
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path, [string[]]$Arguments = @())
    $yazi = Get-PoshixAgentTool -Name Yazi
    if (-not $yazi.Available) { Write-Warning "[poshix] $($yazi.Remediation)"; return }
    $cwdFile = Join-Path ([System.IO.Path]::GetTempPath()) ("poshix-yazi-" + [guid]::NewGuid().ToString('N'))
    try {
        & $yazi.Command $Path @Arguments "--cwd-file=$cwdFile"
        if (Test-Path -LiteralPath $cwdFile) {
            $selectedDirectory = (Get-Content -LiteralPath $cwdFile -Raw).Trim()
            if ($selectedDirectory -and (Test-Path -LiteralPath $selectedDirectory -PathType Container)) { Set-Location -LiteralPath $selectedDirectory }
        }
    } finally {
        if (Test-Path -LiteralPath $cwdFile) { Remove-Item -LiteralPath $cwdFile -Force }
    }
}

function Start-PoshixYaziFocused {
    <# .SYNOPSIS Open Yazi's current-folder-only view and follow its cwd on exit. #>
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path, [string[]]$Arguments = @())
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw "Directory does not exist: $Path" }
    $yazi = Get-PoshixAgentTool -Name Yazi
    if (-not $yazi.Available) { Write-Warning "[poshix] $($yazi.Remediation)"; return }

    $cwdFile = Join-Path ([System.IO.Path]::GetTempPath()) ("poshix-yazi-cwd-" + [guid]::NewGuid().ToString('N'))
    $configDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("poshix-yazi-focus-" + [guid]::NewGuid().ToString('N'))
    $previousConfigHome = $env:YAZI_CONFIG_HOME
    try {
        New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
        @"
# Temporary Poshix focused-Yazi configuration. It is removed on exit.
[mgr]
ratio = [0, 1, 0]
"@ | Set-Content -LiteralPath (Join-Path $configDirectory 'yazi.toml') -Encoding UTF8
        $env:YAZI_CONFIG_HOME = $configDirectory
        & $yazi.Command $Path @Arguments "--cwd-file=$cwdFile"
        if (Test-Path -LiteralPath $cwdFile) {
            $selectedDirectory = (Get-Content -LiteralPath $cwdFile -Raw).Trim()
            if ($selectedDirectory -and (Test-Path -LiteralPath $selectedDirectory -PathType Container)) { Set-Location -LiteralPath $selectedDirectory }
        }
    } finally {
        $env:YAZI_CONFIG_HOME = $previousConfigHome
        if (Test-Path -LiteralPath $cwdFile) { Remove-Item -LiteralPath $cwdFile -Force }
        if (Test-Path -LiteralPath $configDirectory) { Remove-Item -LiteralPath $configDirectory -Recurse -Force }
    }
}

function Start-PoshixGitUi {
    <# .SYNOPSIS Open LazyGit at the current repository root. #>
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path, [string[]]$Arguments = @())
    $lazygit = Get-PoshixAgentTool -Name LazyGit
    if (-not $lazygit.Available) { Write-Warning "[poshix] $($lazygit.Remediation)"; return }
    & $lazygit.Command --path (Get-PoshixProjectRoot $Path) @Arguments
}

function Start-PoshixNeovim {
    <# .SYNOPSIS Toggle into Neovim at the current directory; exit Neovim to return to PowerShell. #>
    [CmdletBinding()]
    param([string]$Path = (Get-Location).Path, [string[]]$Arguments = @())
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { throw "Directory does not exist: $Path" }
    $neovim = Get-PoshixAgentTool -Name Neovim
    if (-not $neovim.Available) { Write-Warning "[poshix] $($neovim.Remediation)"; return }
    Push-Location -LiteralPath $Path
    try { & $neovim.Command @Arguments } finally { Pop-Location }
}

function Get-PoshixHerdrIntegration {
    <# .SYNOPSIS Report whether Herdr controls this calling pane without inspecting other sessions. #>
    [CmdletBinding()]
    param()
    $herdr = Get-PoshixAgentTool -Name Herdr
    [PSCustomObject]@{
        Available = $herdr.Available
        InManagedPane = $env:HERDR_ENV -eq '1'
        Command = $herdr.Command
        Status = if (-not $herdr.Available) { 'NotFound' } elseif ($env:HERDR_ENV -eq '1') { 'Ready' } else { 'OutsideHerdr' }
        Remediation = if (-not $herdr.Available) { $herdr.Remediation } elseif ($env:HERDR_ENV -ne '1') { 'Open this shell inside a Herdr-managed pane before controlling panes, agents, or workspaces.' } else { $null }
    }
}

function Get-PoshixAgentWorkspaceDirectory { Join-Path $HOME '.poshix' 'agent-workspaces' }
function Get-PoshixAgentWorkspacePath { param([string]$Name) Join-Path (Get-PoshixAgentWorkspaceDirectory) "$Name.json" }

function Save-PoshixAgentWorkspace {
    <# .SYNOPSIS Save a named Herdr agent workspace definition. #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Name,
        [Parameter(Mandatory)][hashtable[]]$Agent,
        [string]$Directory = (Get-Location).Path,
        [string]$Description = ''
    )
    if ($Name -match '[\\/:*?"<>|]') { throw "Workspace name contains invalid filename characters: $Name" }
    foreach ($item in $Agent) {
        if ($item.Tool -notin @('Claude', 'Codex', 'Copilot')) { throw 'Agent Tool must be Claude, Codex, or Copilot.' }
        if (-not $item.Name -or $item.Name -notmatch '^[a-z][a-z0-9_-]{0,31}$') { throw 'Agent Name must match [a-z][a-z0-9_-]{0,31}.' }
        if ($item.Direction -and $item.Direction -notin @('right', 'down')) { throw 'Agent Direction must be right or down.' }
    }
    $workspaceDirectory = Get-PoshixAgentWorkspaceDirectory
    if (-not (Test-Path -LiteralPath $workspaceDirectory)) { New-Item -ItemType Directory -Path $workspaceDirectory -Force | Out-Null }
    [ordered]@{ Name = $Name; Description = $Description; Directory = $Directory; Agents = $Agent; UpdatedAt = (Get-Date).ToUniversalTime().ToString('o') } |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Get-PoshixAgentWorkspacePath $Name) -Encoding UTF8
}

function Start-PoshixAgentWorkspace {
    <# .SYNOPSIS Create sibling Herdr panes and start the declared agents. #>
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Name)
    $integration = Get-PoshixHerdrIntegration
    if ($integration.Status -ne 'Ready') { Write-Warning "[poshix] $($integration.Remediation)"; return }
    $path = Get-PoshixAgentWorkspacePath $Name
    if (-not (Test-Path -LiteralPath $path)) { Write-Warning "[poshix] Agent workspace '$Name' was not found."; return }
    $workspace = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if (-not (Test-Path -LiteralPath $workspace.Directory -PathType Container)) { Write-Warning "[poshix] Workspace directory does not exist: $($workspace.Directory)"; return }
    foreach ($agent in @($workspace.Agents)) {
        $tool = Get-PoshixAgentTool -Name $agent.Tool
        if (-not $tool.Available) { Write-Warning "[poshix] Cannot start $($agent.Name): $($tool.Remediation)"; return }
    }
    foreach ($agent in @($workspace.Agents)) {
        $split = & $integration.Command pane split --current --direction $(if ($agent.Direction) { $agent.Direction } else { 'right' }) --cwd $workspace.Directory --no-focus 2>&1
        if ($LASTEXITCODE -ne 0) { Write-Error "[poshix] Herdr pane split failed: $($split -join ' ')"; return }
        $paneId = (($split -join "`n") | ConvertFrom-Json).result.pane.pane_id
        $tool = Get-PoshixAgentTool -Name $agent.Tool
        $startArguments = @('agent', 'start', $agent.Name, '--kind', $tool.HerdrKind, '--pane', $paneId)
        if ($agent.Arguments) { $startArguments += @('--') + @($agent.Arguments) }
        & $integration.Command @startArguments
        if ($LASTEXITCODE -ne 0) { Write-Error "[poshix] Herdr could not start agent '$($agent.Name)'."; return }
    }
}

function Invoke-PoshixHerdrJson {
    param([Parameter(Mandatory)][string]$Command, [Parameter(Mandatory)][string[]]$Arguments, [switch]$Trace, [ValidateRange(0,60)][int]$TimeoutSeconds = 0)
    $started = [DateTime]::UtcNow
    if ($Trace) { Write-Host "[poshix/herdr] START $Command $($Arguments -join ' ')" -ForegroundColor DarkGray }
    if ($TimeoutSeconds -gt 0) {
        $startInfo=[Diagnostics.ProcessStartInfo]::new();$startInfo.FileName=$Command;$startInfo.UseShellExecute=$false;$startInfo.CreateNoWindow=$true;$startInfo.RedirectStandardOutput=$true;$startInfo.RedirectStandardError=$true
        if($startInfo.PSObject.Properties.Name -contains 'ArgumentList'){foreach($argument in $Arguments){[void]$startInfo.ArgumentList.Add($argument)}}else{$startInfo.Arguments=($Arguments|ForEach-Object{'"'+($_ -replace '(\\*)"','$1$1\"' -replace '(\\+)$','$1$1')+'"'}) -join ' '}
        $process=[Diagnostics.Process]::new();$process.StartInfo=$startInfo;[void]$process.Start();$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        if(-not $process.WaitForExit($TimeoutSeconds*1000)){try{$process.Kill($true)}catch{$process.Kill()};$process.WaitForExit();throw "Herdr command timed out after $TimeoutSeconds seconds: $Command $($Arguments -join ' ')"}
        $output=$stdout.GetAwaiter().GetResult();$errorOutput=$stderr.GetAwaiter().GetResult();if($errorOutput){$output=($output+"`n"+$errorOutput).Trim()};$exitCode=$process.ExitCode;$process.Dispose()
    } else {
        $output = & $Command @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    if ($Trace) { Write-Host "[poshix/herdr] END   exit=$exitCode elapsed=$([math]::Round(([DateTime]::UtcNow - $started).TotalSeconds,2))s" -ForegroundColor DarkGray }
    if ($exitCode -ne 0) { throw "Herdr command failed: $($output -join ' ')" }
    try { ($output -join "`n") | ConvertFrom-Json } catch { throw "Herdr returned invalid JSON: $($output -join ' ')" }
}

function Get-PoshixHerdrLayoutTemplate {
    [CmdletBinding()]
    param([string]$Name)
    Get-PoshixHerdrWorkspaceTemplate -Name $Name
}

function Select-PoshixHerdrLayoutTemplate {
    [CmdletBinding()]
    param()
    Select-PoshixHerdrWorkspaceTemplate
}

function Get-PoshixHerdrTemplatePath {
    Join-Path (Join-Path $HOME '.poshix') 'herdr-templates.json'
}

function Write-PoshixHerdrTemplate {
    param([Parameter(Mandatory)]$Entry)
    $path=Get-PoshixHerdrTemplatePath; $dir=Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $templates=@(); if(Test-Path -LiteralPath $path){try{$templates=@(Get-Content $path -Raw|ConvertFrom-Json)}catch{throw "Invalid Herdr template file: $path"}}
    $templates=@($templates|Where-Object Name -ne $Entry.Name)+$Entry
    $temporary=Join-Path $dir ('.herdr-templates.'+[guid]::NewGuid().ToString('N')+'.tmp')
    try {
        $templates|ConvertTo-Json -Depth 32|Set-Content -LiteralPath $temporary -Encoding utf8
        Get-Content -LiteralPath $temporary -Raw|ConvertFrom-Json|Out-Null
        if(Test-Path -LiteralPath $path){[IO.File]::Replace($temporary,$path,$null)}else{[IO.File]::Move($temporary,$path)}
    } finally { if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue} }
}

function Save-PoshixHerdrTemplate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._-]{0,63}$')][string]$Name,
        [string]$Description = '',
        [object[]]$Panes,
        [object]$Layout
    )
    if (-not $Panes -and -not $Layout) { throw 'Provide Panes or Layout.' }
    foreach ($pane in $Panes) {
        if (-not $pane.Command -and -not $pane.DefaultShell) { throw 'Each pane must include a Command or DefaultShell.' }
        if ($pane.Direction -and $pane.Direction -notin @('right','down')) { throw "Herdr supports only right and down split directions; got '$($pane.Direction)'." }
    }
    function Test-TemplateNode($Node, [int]$Depth=0) {
        if ($Depth -gt 32) { throw 'Template nesting exceeds 32 levels.' }
        $children=@($Node.Children)
        if ($Node.Command -or $Node.DefaultShell -or $children.Count -eq 0) { return }
        if ($children.Count -ne 2) { throw 'Every layout split must contain exactly two children.' }
        if ($Node.Direction -notin @('right','down')) { throw "Invalid layout direction '$($Node.Direction)'." }
        if ($null -ne $Node.Ratio -and ([double]$Node.Ratio -le 0 -or [double]$Node.Ratio -ge 1)) { throw 'Split ratios must be greater than 0 and less than 1.' }
        foreach($child in $children){Test-TemplateNode $child ($Depth+1)}
    }
    if ($Layout) { Test-TemplateNode $Layout }
    $entry = [PSCustomObject][ordered]@{ Name = $Name; Description = $Description; Panes = @($Panes); Layout = $Layout }
    Write-Host "`nProposed Herdr template: $Name" -ForegroundColor Cyan
    $entry | ConvertTo-Json -Depth 12 | Write-Host
    if ((Read-Host 'Save this template? [Y/N]') -notmatch '^[Yy]$') { Write-Host 'Template not saved.' -ForegroundColor Yellow; return }
    $path=Get-PoshixHerdrTemplatePath
    if ($PSCmdlet.ShouldProcess($path, "Save Herdr template '$Name'")) { Write-PoshixHerdrTemplate -Entry $entry }
    $entry
}

function Save-PoshixHerdrCurrentTemplate {
    <# .SYNOPSIS Capture the current Herdr tab's panes as a reusable template. #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param([Parameter(Mandatory)][string]$Name, [string]$Description = '')
    $integration = Get-PoshixHerdrIntegration
    if ($integration.Status -ne 'Ready') { Write-Warning "[poshix] $($integration.Remediation)"; return }
    try {
        $response = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments @('pane','layout','--current') -Trace -TimeoutSeconds 5
    } catch { Write-Warning "[poshix] Could not inspect the current Herdr pane: $_"; return }
    $model = $response.result.layout
    if (-not $model -or -not $model.area -or -not $model.panes) { Write-Warning '[poshix] Herdr returned no current-tab geometry; template was not saved.'; return }

    $paneCommands = @{}
    foreach ($pane in @($model.panes)) {
        $id = [string]$pane.pane_id
        Write-Host "[poshix/herdr] inspect pane=$id" -ForegroundColor DarkGray
        $command = $null; $arguments = @()
        try {
            $procInfo = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments @('pane','process-info','--pane',$id) -TimeoutSeconds 3
            $processes = @($procInfo.result.process_info.foreground_processes)
            $active = $processes | Where-Object { $_.name -and $_.name -notmatch '^(pwsh|powershell|cmd|conhost)(\.exe)?$' } | Select-Object -Last 1
            if ($active) { $command = [IO.Path]::GetFileNameWithoutExtension([string]$active.name); $arguments = @($active.argv | Select-Object -Skip 1) }
        } catch { Write-Verbose "[poshix/herdr] process-info pane=$id failed: $($_.Exception.Message)" }
        if (-not $command) {
            try {
                $detail = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments @('pane','get',$id) -TimeoutSeconds 3
                $info = $detail.result.pane
                if ($info.command) { $command = $info.command }
                elseif ($info.agent) { $command = [string]$info.agent }
                elseif ([string]$info.terminal_title_stripped -match '(?i)(yazi|lazygit|nvim|neovim|claude|codex|copilot)') { $command = $Matches[1].ToLowerInvariant() }
            } catch { Write-Verbose "[poshix/herdr] pane-get pane=$id failed: $($_.Exception.Message)" }
        }
        $paneCommands[$id] = [PSCustomObject][ordered]@{ Command = if ($command) { $command } else { 'pwsh' }; Arguments = @($arguments) }
        Write-Host "[poshix/herdr] selected pane=$id command=$($paneCommands[$id].Command)" -ForegroundColor DarkGray
    }

    function Get-RegionBounds([object[]]$Items) {
        $minX=($Items|Measure-Object {$_.rect.x} -Minimum).Minimum; $minY=($Items|Measure-Object {$_.rect.y} -Minimum).Minimum
        $maxX=($Items|ForEach-Object {$_.rect.x+$_.rect.width}|Measure-Object -Maximum).Maximum; $maxY=($Items|ForEach-Object {$_.rect.y+$_.rect.height}|Measure-Object -Maximum).Maximum
        [PSCustomObject]@{ x=$minX; y=$minY; width=$maxX-$minX; height=$maxY-$minY }
    }
    function Convert-Region([object[]]$Items, $Region, [int]$Depth=0) {
        $Items=@($Items); if ($Depth -gt 32 -or $Items.Count -eq 0) { throw 'Herdr layout exceeds capture limits.' }
        if ($Items.Count -eq 1) {
            $leaf=$paneCommands[[string]$Items[0].pane_id]
            if ($leaf.Command -eq 'pwsh') { return [PSCustomObject][ordered]@{ DefaultShell=$true } }
            return [PSCustomObject][ordered]@{ Command=$leaf.Command; Arguments=@($leaf.Arguments) }
        }
        $split=@($model.splits | Where-Object { $_.rect.x -eq $Region.x -and $_.rect.y -eq $Region.y -and $_.rect.width -eq $Region.width -and $_.rect.height -eq $Region.height })[0]
        if (-not $split) { throw "Cannot reconstruct a split containing $($Items.Count) panes." }
        $ratio=if ($null -ne $split.ratio) {[double]$split.ratio}else{0.5}; $vertical=$split.direction -eq 'right'; $boundary=if($vertical){$Region.x+$Region.width*$ratio}else{$Region.y+$Region.height*$ratio}
        $first=@($Items|Where-Object { if($vertical){$_.rect.x+($_.rect.width/2)-lt $boundary}else{$_.rect.y+($_.rect.height/2)-lt $boundary} }); $second=@($Items|Where-Object { $_ -notin $first })
        if (-not $first -or -not $second) { throw "Split '$($split.id)' did not partition its panes." }
        [PSCustomObject][ordered]@{ Direction=[string]$split.direction; Ratio=$ratio; Children=@((Convert-Region $first (Get-RegionBounds $first) ($Depth+1)),(Convert-Region $second (Get-RegionBounds $second) ($Depth+1))) }
    }

    try { $proposal=Convert-Region @($model.panes) $model.area } catch { Write-Warning "[poshix] Could not construct template: $_"; return }
    $proposalJson=$proposal|ConvertTo-Json -Depth 12
    Write-Host "`nProposed Herdr template: $Name" -ForegroundColor Cyan
    $proposalJson | Write-Host
    $answer = Read-Host 'Save this template? [Y/N]'
    if ($answer -notmatch '^[Yy]$') { Write-Host 'Template not saved.' -ForegroundColor Yellow; return }
    $entry=[PSCustomObject][ordered]@{Name=$Name;Description=$Description;Panes=@();Layout=$proposal}
    if($PSCmdlet.ShouldProcess((Get-PoshixHerdrTemplatePath),"Save Herdr template '$Name'")){Write-PoshixHerdrTemplate -Entry $entry}
}

function Get-PoshixHerdrWorkspaceTemplate {
    [CmdletBinding()]
    param([string]$Name)
    $path = Get-PoshixHerdrTemplatePath
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { return @() }
    try { $items = @(Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json) } catch { Write-Warning "[poshix] Invalid Herdr template file: $path"; return @() }
    if ($Name) { $items | Where-Object Name -eq $Name | Select-Object -First 1 } else { $items }
}

function Select-PoshixHerdrWorkspaceTemplate {
    [CmdletBinding()]
    param()
    $items = @(Get-PoshixHerdrWorkspaceTemplate)
    if (-not $items) { Write-Warning '[poshix] No Herdr templates found. Create one with Save-PoshixHerdrTemplate.'; return }
    $fzf = Get-Command fzf -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $fzf) { Write-Warning '[poshix] fzf is required to select a Herdr workspace template. Specify -Layout explicitly.'; return }
    $selected = $items | ForEach-Object { "$($_.Name)`t$($_.Description)" } | & $fzf.Source --ansi --height '50%' --layout reverse --border --prompt 'Herdr template> ' --delimiter "`t" --with-nth '1,2'
    if ($selected) { ($selected -split "`t", 2)[0] }
}

function Invoke-PoshixHerdrWorkspaceTemplate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param([string]$Layout, [switch]$Validate)
    $integration = Get-PoshixHerdrIntegration
    if ($integration.Status -ne 'Ready') { Write-Warning "[poshix] $($integration.Remediation)"; return }
    $action = if ($Validate) { 'validate' } else { 'apply' }
    if (-not $Layout -and -not $Validate) { $Layout = Select-PoshixHerdrWorkspaceTemplate }
    if (-not $Layout -and -not $Validate) { return }
    $template = if ($Layout) { Get-PoshixHerdrWorkspaceTemplate -Name $Layout } else { $null }
    if ($Layout -and -not $template) { throw "Unknown Herdr workspace template '$Layout'. Use Get-PoshixHerdrWorkspaceTemplate." }
    if ($Validate) { return Get-PoshixHerdrWorkspaceTemplate }
    if (-not $PSCmdlet.ShouldProcess("Herdr workspace template '$Layout'", $action)) { return }
    $tabResponse = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments @('tab','create','--cwd',(Get-Location).Path,'--label',$Layout,'--focus')
    $root = $tabResponse.result.root_pane.pane_id; $created = @($root); $script:PoshixCreatedPanes = @($root)
    function Start-CapturedNode($node, [string]$paneId) {
        if ($node.DefaultShell -or [string]$node.Command -match '^(pwsh|powershell)(\.exe)?$') { return }
        if ($node.Command) { $run = @('pane','run',$paneId,[string]$node.Command) + @($node.Arguments); Invoke-PoshixHerdrJson -Command $integration.Command -Arguments $run | Out-Null; return }
        $children = @($node.Children); if (-not $children) { return }
        Start-CapturedNode $children[0] $paneId
        for ($j=1; $j -lt $children.Count; $j++) {
            $direction = if ($node.Direction) { [string]$node.Direction } else { 'right' }
            $splitArgs = @('pane','split','--pane',$paneId,'--direction',$direction,'--cwd',(Get-Location).Path,'--no-focus')
            if ($null -ne $node.Ratio) { $splitArgs += @('--ratio',([string]::Format([Globalization.CultureInfo]::InvariantCulture,'{0:0.####}',[double]$node.Ratio))) }
            $response = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments $splitArgs
            $childPane = $response.result.pane.pane_id; $script:PoshixCreatedPanes += $childPane
            Start-CapturedNode $children[$j] $childPane
        }
    }
    if ($template.Layout) { Start-CapturedNode $template.Layout $root } else {
        $paneDefs = @($template.Panes); if ($paneDefs.Count -gt 0) { Start-CapturedNode $paneDefs[0] $root }
        for ($i=1; $i -lt $paneDefs.Count; $i++) { $response = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments @('pane','split','--pane',$root,'--direction',($(if($paneDefs[$i].Direction){$paneDefs[$i].Direction}else{'right'})),'--cwd',(Get-Location).Path,'--no-focus'); $child=$response.result.pane.pane_id; $script:PoshixCreatedPanes += $child; Start-CapturedNode $paneDefs[$i] $child }
    }
    [PSCustomObject][ordered]@{ Layout=$Layout; Tab=$tabResponse.result.tab; Panes=@($script:PoshixCreatedPanes) }
}

$script:PoshixHerdrPaneTemplates = @(
    [PSCustomObject]@{ Name = 'single'; Description = 'One empty pane'; Splits = 'none' }
    [PSCustomObject]@{ Name = 'split-right'; Description = 'Two panes side by side'; Splits = 'right' }
    [PSCustomObject]@{ Name = 'split-down'; Description = 'Two panes stacked vertically'; Splits = 'down' }
    [PSCustomObject]@{ Name = 'top-bottom-right'; Description = 'Top and bottom panes with a right column'; Splits = 'down + right' }
)

function Get-PoshixHerdrPaneTemplate {
    [CmdletBinding()]
    param([string]$Name)
    if ($Name) { return $script:PoshixHerdrPaneTemplates | Where-Object Name -eq $Name | Select-Object -First 1 }
    $script:PoshixHerdrPaneTemplates
}

function Select-PoshixHerdrPaneTemplate {
    [CmdletBinding()]
    param()
    $fzf = Get-Command fzf -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $fzf) { Write-Warning '[poshix] fzf is required to select a pane layout. Specify -Layout explicitly.'; return }
    $selected = Get-PoshixHerdrPaneTemplate | ForEach-Object { "$($_.Name)`t$($_.Description)`t$($_.Splits)" } |
        & $fzf.Source --height '40%' --layout reverse --border --prompt 'Pane layout> ' --delimiter "`t" --with-nth '1,2,3'
    if ($selected) { return ($selected -split "`t", 2)[0] }
}

function Start-PoshixHerdrPaneLayout {
    <# .SYNOPSIS Create a new Herdr tab using panes and splits only; no commands are started. #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param([string]$Layout, [string]$WorkingDirectory = (Get-Location).Path, [string]$TabName = 'Poshix panes')
    if (-not $Layout) { $Layout = Select-PoshixHerdrPaneTemplate }
    $template = Get-PoshixHerdrPaneTemplate -Name $Layout
    if (-not $template) { throw "Unknown pane layout '$Layout'. Choose one with Get-PoshixHerdrPaneTemplate." }
    $integration = Get-PoshixHerdrIntegration
    if ($integration.Status -ne 'Ready') { Write-Warning "[poshix] $($integration.Remediation)"; return }
    if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) { throw "Working directory does not exist: $WorkingDirectory" }
    if (-not $PSCmdlet.ShouldProcess("Herdr tab '$TabName'", "Create pane layout '$Layout'")) { return }
    $tabResponse = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments @('tab', 'create', '--cwd', $WorkingDirectory, '--label', $TabName, '--focus')
    $rootPane = $tabResponse.result.root_pane.pane_id
    if (-not $rootPane) { throw 'Herdr did not return the new tab root pane ID.' }
    $created = @($rootPane)
    if ($Layout -in @('split-right', 'split-down', 'top-bottom-right')) {
        $direction = if ($Layout -eq 'split-down' -or $Layout -eq 'top-bottom-right') { 'down' } else { 'right' }
        $first = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments @('pane', 'split', '--pane', $rootPane, '--direction', $direction, '--cwd', $WorkingDirectory, '--no-focus')
        $created += $first.result.pane.pane_id
    }
    if ($Layout -eq 'top-bottom-right') {
        $right = Invoke-PoshixHerdrJson -Command $integration.Command -Arguments @('pane', 'split', '--pane', $rootPane, '--direction', 'right', '--cwd', $WorkingDirectory, '--no-focus')
        $created += $right.result.pane.pane_id
    }
    [PSCustomObject][ordered]@{ Layout = $Layout; Tab = $tabResponse.result.tab; Panes = $created; Directory = $WorkingDirectory }
}

function Start-PoshixHerdrWorkArea {
    <# .SYNOPSIS Select and launch a complete Herdr work area (layout plus tools). #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param([string]$Layout, [string]$WorkingDirectory = (Get-Location).Path, [string]$Distribution, [string]$TabName = 'Poshix work area', [string]$AgentName = 'claude')
    Invoke-PoshixHerdrWorkspaceTemplate -Layout $Layout -Confirm:$false
}

function Start-PoshixHerdrLayout {
    <# .SYNOPSIS Create a new Herdr tab from a rigid, selectable layout template. #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [string]$Layout,
        [string]$WorkingDirectory = (Get-Location).Path,
        [string]$Distribution,
        [string]$TabName = 'Poshix dev layout',
        [string]$AgentName = 'claude'
    )
    Invoke-PoshixHerdrWorkspaceTemplate -Layout $Layout -Confirm:$false
}

foreach ($functionName in @('Get-PoshixAgentTool', 'Get-PoshixProjectRoot', 'Start-PoshixAgent', 'Start-PoshixAgentPicker', 'Start-PoshixYazi', 'Start-PoshixYaziFocused', 'Start-PoshixGitUi', 'Start-PoshixNeovim', 'Get-PoshixHerdrIntegration', 'Save-PoshixAgentWorkspace', 'Start-PoshixAgentWorkspace', 'Invoke-PoshixHerdrJson', 'Get-PoshixHerdrLayoutTemplate', 'Select-PoshixHerdrLayoutTemplate', 'Get-PoshixHerdrTemplatePath', 'Save-PoshixHerdrTemplate', 'Save-PoshixHerdrCurrentTemplate', 'Get-PoshixHerdrWorkspaceTemplate', 'Select-PoshixHerdrWorkspaceTemplate', 'Invoke-PoshixHerdrWorkspaceTemplate', 'Get-PoshixHerdrPaneTemplate', 'Select-PoshixHerdrPaneTemplate', 'Start-PoshixHerdrPaneLayout', 'Start-PoshixHerdrLayout', 'Start-PoshixHerdrWorkArea')) {
    Set-Item -Path "function:global:$functionName" -Value (Get-Item -Path "function:$functionName").ScriptBlock
}

Set-Alias -Name y -Value Start-PoshixYazi -Scope Global -Force
Set-Alias -Name yf -Value Start-PoshixYaziFocused -Scope Global -Force
Set-Alias -Name lg -Value Start-PoshixGitUi -Scope Global -Force
Set-Alias -Name agent -Value Start-PoshixAgent -Scope Global -Force
Set-Alias -Name hlayout -Value Start-PoshixHerdrPaneLayout -Scope Global -Force
Set-Alias -Name hwork -Value Start-PoshixHerdrWorkArea -Scope Global -Force
Write-Verbose '[poshix] agent-tools plugin loaded'
