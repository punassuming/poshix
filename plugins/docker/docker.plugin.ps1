# docker plugin for poshix
# WSL-aware Docker helpers and prompt integration

$script:PoshixDockerPromptCache = @{}

function Get-PoshixDockerSettings {
    $settings = @{
        Mode = 'Auto'
        Distribution = $null
        Prompt = @{
            ShowContext = $true
            ShowProject = $true
            MaxItems = 2
            CacheSeconds = 3
        }
    }

    try {
        $config = Get-PoshixConfig
    } catch {
        return $settings
    }

    if (-not $config -or -not $config.Docker) {
        return $settings
    }

    if ($config.Docker.Mode) {
        $settings.Mode = [string]$config.Docker.Mode
    }

    if ($config.Docker.ContainsKey('Distribution')) {
        $settings.Distribution = $config.Docker.Distribution
    }

    if ($config.Docker.Prompt) {
        foreach ($key in $config.Docker.Prompt.Keys) {
            $settings.Prompt[$key] = $config.Docker.Prompt[$key]
        }
    }

    return $settings
}

function Get-PoshixDockerNativeCommand {
    $nativeDocker = Get-Command docker -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $nativeDocker) {
        $nativeDocker = Get-Command docker.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    return $nativeDocker
}

function Get-PoshixWslCommand {
    $wslCommand = Get-Command wsl -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $wslCommand) {
        $wslCommand = Get-Command wsl.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    }

    return $wslCommand
}

function Resolve-PoshixDockerBackend {
    [CmdletBinding()]
    param()

    $settings = Get-PoshixDockerSettings
    $mode = if ($settings.Mode) { $settings.Mode.ToLowerInvariant() } else { 'auto' }
    $nativeDocker = Get-PoshixDockerNativeCommand
    $wslCommand = Get-PoshixWslCommand

    switch ($mode) {
        'native' {
            if ($nativeDocker) {
                return [PSCustomObject]@{
                    Mode = 'Native'
                    Command = $nativeDocker.Source
                    BaseArguments = @()
                    Distribution = $null
                }
            }
        }
        'wsl' {
            if ($wslCommand) {
                $baseArguments = @()
                if ($settings.Distribution) {
                    $baseArguments += @('-d', [string]$settings.Distribution)
                }
                $baseArguments += @('--', 'docker')

                return [PSCustomObject]@{
                    Mode = 'Wsl'
                    Command = $wslCommand.Source
                    BaseArguments = $baseArguments
                    Distribution = $settings.Distribution
                }
            }
        }
        default {
            if ($settings.Distribution -and $wslCommand) {
                $baseArguments = @('-d', [string]$settings.Distribution, '--', 'docker')
                return [PSCustomObject]@{
                    Mode = 'Wsl'
                    Command = $wslCommand.Source
                    BaseArguments = $baseArguments
                    Distribution = $settings.Distribution
                }
            }

            if ($nativeDocker) {
                return [PSCustomObject]@{
                    Mode = 'Native'
                    Command = $nativeDocker.Source
                    BaseArguments = @()
                    Distribution = $null
                }
            }

            if ($wslCommand) {
                return [PSCustomObject]@{
                    Mode = 'Wsl'
                    Command = $wslCommand.Source
                    BaseArguments = @('--', 'docker')
                    Distribution = $null
                }
            }
        }
    }

    return $null
}

function Invoke-PoshixDockerPassthrough {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $backend = Resolve-PoshixDockerBackend
    if (-not $backend) {
        Write-Warning "[poshix] Docker backend not available. Install docker or enable WSL and set Docker.Mode = 'Wsl'."
        return
    }

    & $backend.Command @($backend.BaseArguments + $Arguments)
}

function Invoke-PoshixDockerCapture {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $backend = Resolve-PoshixDockerBackend
    if (-not $backend) {
        return [PSCustomObject]@{
            Available = $false
            ExitCode = 127
            Output = @()
            Backend = $null
        }
    }

    $output = & $backend.Command @($backend.BaseArguments + $Arguments) 2>&1
    $exitCode = $LASTEXITCODE

    return [PSCustomObject]@{
        Available = $true
        ExitCode = $exitCode
        Output = @($output)
        Backend = $backend
    }
}

function Find-PoshixDockerComposeFile {
    [CmdletBinding()]
    param(
        [string]$StartPath = (Get-Location).Path
    )

    $composeNames = @('compose.yml', 'compose.yaml', 'docker-compose.yml', 'docker-compose.yaml')
    $currentPath = $StartPath

    while ($currentPath) {
        foreach ($composeName in $composeNames) {
            $candidate = Join-Path $currentPath $composeName
            if (Test-Path $candidate -PathType Leaf) {
                return $candidate
            }
        }

        $parentPath = Split-Path $currentPath -Parent
        if (-not $parentPath -or $parentPath -eq $currentPath) {
            break
        }

        $currentPath = $parentPath
    }

    return $null
}

function Get-PoshixDockerContextName {
    $contextResult = Invoke-PoshixDockerCapture -Arguments @('context', 'show')
    if (-not $contextResult.Available -or $contextResult.ExitCode -ne 0) {
        return $null
    }

    $contextName = ($contextResult.Output | Select-Object -First 1).ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($contextName)) {
        return $null
    }

    return $contextName
}

function Get-PoshixDockerComposeStatus {
    param(
        [Parameter(Mandatory)]
        [string]$ComposeDirectory,

        [string]$Context
    )

    Push-Location $ComposeDirectory
    try {
        $result = Invoke-PoshixDockerCapture -Arguments @('compose', 'ps', '-a', '--format', 'json')
    } finally {
        Pop-Location
    }

    if (-not $result.Available -or $result.ExitCode -ne 0) {
        return $null
    }

    $jsonText = ($result.Output -join "`n").Trim()
    if ([string]::IsNullOrWhiteSpace($jsonText)) {
        return $null
    }

    try {
        $containers = @($jsonText | ConvertFrom-Json)
    } catch {
        return $null
    }

    if ($containers.Count -eq 0) {
        return $null
    }

    $runningContainers = @($containers | Where-Object { $_.State -eq 'running' })
    $items = @(
        $runningContainers |
        ForEach-Object {
            if ($_.Service) {
                $_.Service
            } elseif ($_.Name) {
                $_.Name
            }
        } |
        Where-Object { $_ } |
        Select-Object -Unique
    )

    return [PSCustomObject]@{
        Available = $true
        Scope = 'Compose'
        Project = if ($containers[0].Project) { $containers[0].Project } else { Split-Path $ComposeDirectory -Leaf }
        Context = $Context
        RunningContainers = $runningContainers.Count
        TotalContainers = $containers.Count
        Items = $items
        ComposeDirectory = $ComposeDirectory
        BackendMode = $result.Backend.Mode
        Distribution = $result.Backend.Distribution
    }
}

function Get-PoshixDockerGlobalStatus {
    param(
        [string]$Context
    )

    $result = Invoke-PoshixDockerCapture -Arguments @('ps', '--format', '{{.Image}}|{{.Names}}|{{.Status}}')
    if (-not $result.Available -or $result.ExitCode -ne 0) {
        return $null
    }

    $containers = @(
        $result.Output |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object {
            $parts = $_.ToString().Split('|')
            [PSCustomObject]@{
                Image = if ($parts.Count -gt 0) { $parts[0] } else { $null }
                Name = if ($parts.Count -gt 1) { $parts[1] } else { $null }
                Status = if ($parts.Count -gt 2) { $parts[2] } else { $null }
            }
        }
    )

    if ($containers.Count -eq 0) {
        return $null
    }

    return [PSCustomObject]@{
        Available = $true
        Scope = 'Global'
        Project = $null
        Context = $Context
        RunningContainers = $containers.Count
        TotalContainers = $containers.Count
        Items = @(
            $containers |
            ForEach-Object { $_.Image } |
            Where-Object { $_ } |
            Select-Object -Unique
        )
        BackendMode = $result.Backend.Mode
        Distribution = $result.Backend.Distribution
    }
}

function Test-DockerAvailable {
    [CmdletBinding()]
    param()

    $result = Invoke-PoshixDockerCapture -Arguments @('version', '--format', '{{.Server.Version}}')
    if (-not $result.Available -or $result.ExitCode -ne 0) {
        Write-Warning "[poshix] Docker is not available from the configured backend."
        return $false
    }

    return $true
}

function Invoke-DockerCli {
    <#
    .SYNOPSIS
    Run docker using the configured native or WSL backend.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    Invoke-PoshixDockerPassthrough -Arguments $Arguments
}

function Invoke-DockerCompose {
    <#
    .SYNOPSIS
    Run docker compose using the configured native or WSL backend.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    Invoke-PoshixDockerPassthrough -Arguments (@('compose') + $Arguments)
}

function Get-DockerBackendInfo {
    <#
    .SYNOPSIS
    Show which Docker backend poshix will use.
    #>
    [CmdletBinding()]
    param()

    $backend = Resolve-PoshixDockerBackend
    if (-not $backend) {
        Write-Warning "[poshix] Docker backend not available."
        return
    }

    $context = Get-PoshixDockerContextName
    $versionResult = Invoke-PoshixDockerCapture -Arguments @('version', '--format', '{{.Client.Version}}|{{.Server.Version}}')
    $clientVersion = $null
    $serverVersion = $null
    if ($versionResult.Available -and $versionResult.ExitCode -eq 0 -and $versionResult.Output.Count -gt 0) {
        $versionParts = $versionResult.Output[0].ToString().Split('|')
        if ($versionParts.Count -gt 0) { $clientVersion = $versionParts[0] }
        if ($versionParts.Count -gt 1) { $serverVersion = $versionParts[1] }
    }

    return [PSCustomObject]@{
        Mode = $backend.Mode
        Command = $backend.Command
        Distribution = $backend.Distribution
        Context = $context
        ClientVersion = $clientVersion
        ServerVersion = $serverVersion
    }
}

function Get-DockerStatus {
    <#
    .SYNOPSIS
    Show Docker status for the current Compose project or globally running containers.
    #>
    [CmdletBinding()]
    param(
        [switch]$CurrentProjectOnly,
        [switch]$Quiet
    )

    $backend = Resolve-PoshixDockerBackend
    if (-not $backend) {
        if (-not $Quiet) {
            Write-Warning "[poshix] Docker backend not available."
        }
        return
    }

    $context = Get-PoshixDockerContextName
    $composeFile = Find-PoshixDockerComposeFile
    if ($composeFile) {
        $composeStatus = Get-PoshixDockerComposeStatus -ComposeDirectory (Split-Path $composeFile -Parent) -Context $context
        if ($composeStatus) {
            return $composeStatus
        }
    }

    if ($CurrentProjectOnly) {
        return
    }

    $globalStatus = Get-PoshixDockerGlobalStatus -Context $context
    if (-not $globalStatus -and -not $Quiet) {
        Write-Warning "[poshix] No running Docker containers found."
    }

    return $globalStatus
}

function Get-DockerPromptInfo {
    <#
    .SYNOPSIS
    Return a compact Docker status object for prompt segments.
    #>
    [CmdletBinding()]
    param(
        [Nullable[bool]]$ShowContext,
        [Nullable[bool]]$ShowProject,
        [int]$MaxItems,
        [int]$CacheSeconds
    )

    $settings = Get-PoshixDockerSettings
    $resolvedPrompt = @{
        ShowContext = [bool]$settings.Prompt.ShowContext
        ShowProject = [bool]$settings.Prompt.ShowProject
        MaxItems = [int]$settings.Prompt.MaxItems
        CacheSeconds = [int]$settings.Prompt.CacheSeconds
    }

    if ($PSBoundParameters.ContainsKey('ShowContext')) {
        $resolvedPrompt.ShowContext = [bool]$ShowContext
    }
    if ($PSBoundParameters.ContainsKey('ShowProject')) {
        $resolvedPrompt.ShowProject = [bool]$ShowProject
    }
    if ($PSBoundParameters.ContainsKey('MaxItems')) {
        $resolvedPrompt.MaxItems = $MaxItems
    }
    if ($PSBoundParameters.ContainsKey('CacheSeconds')) {
        $resolvedPrompt.CacheSeconds = $CacheSeconds
    }

    $cacheKey = '{0}|{1}|{2}|{3}' -f (Get-Location).Path, $resolvedPrompt.ShowContext, $resolvedPrompt.ShowProject, $resolvedPrompt.MaxItems
    $cached = $script:PoshixDockerPromptCache[$cacheKey]
    if ($cached -and ((Get-Date) - $cached.Timestamp).TotalSeconds -lt $resolvedPrompt.CacheSeconds) {
        return $cached.Value
    }

    $status = Get-DockerStatus -Quiet
    if (-not $status) {
        return $null
    }

    if ($status.RunningContainers -eq 0 -and $status.TotalContainers -eq 0) {
        return $null
    }

    $text = 'docker'
    if ($resolvedPrompt.ShowContext -and $status.Context) {
        $text += "[$($status.Context)]"
    }
    if ($resolvedPrompt.ShowProject -and $status.Project) {
        $text += " $($status.Project)"
    }

    if ($status.Scope -eq 'Compose') {
        $text += " $($status.RunningContainers)/$($status.TotalContainers)"
    } else {
        $text += " $($status.RunningContainers)"
    }

    $displayItems = @($status.Items | Select-Object -First $resolvedPrompt.MaxItems)
    if ($displayItems.Count -gt 0) {
        $text += " " + ($displayItems -join ',')
    }
    if ($status.Items.Count -gt $resolvedPrompt.MaxItems) {
        $text += ",+$($status.Items.Count - $resolvedPrompt.MaxItems)"
    }

    $promptInfo = [PSCustomObject]@{
        Text = $text
        RunningContainers = $status.RunningContainers
        TotalContainers = $status.TotalContainers
        Context = $status.Context
        Project = $status.Project
        Scope = $status.Scope
        Items = $status.Items
    }

    $script:PoshixDockerPromptCache[$cacheKey] = @{
        Timestamp = Get-Date
        Value = $promptInfo
    }

    return $promptInfo
}

function Invoke-PoshixDockerProxy {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    Invoke-DockerCli -Arguments $Arguments
}

function Invoke-PoshixDockerComposeProxy {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    Invoke-DockerCompose -Arguments $Arguments
}

Set-Item -Path "function:global:Get-PoshixDockerSettings" -Value ${function:Get-PoshixDockerSettings}
Set-Item -Path "function:global:Get-PoshixDockerNativeCommand" -Value ${function:Get-PoshixDockerNativeCommand}
Set-Item -Path "function:global:Get-PoshixWslCommand" -Value ${function:Get-PoshixWslCommand}
Set-Item -Path "function:global:Resolve-PoshixDockerBackend" -Value ${function:Resolve-PoshixDockerBackend}
Set-Item -Path "function:global:Invoke-PoshixDockerPassthrough" -Value ${function:Invoke-PoshixDockerPassthrough}
Set-Item -Path "function:global:Invoke-PoshixDockerCapture" -Value ${function:Invoke-PoshixDockerCapture}
Set-Item -Path "function:global:Find-PoshixDockerComposeFile" -Value ${function:Find-PoshixDockerComposeFile}
Set-Item -Path "function:global:Get-PoshixDockerContextName" -Value ${function:Get-PoshixDockerContextName}
Set-Item -Path "function:global:Get-PoshixDockerComposeStatus" -Value ${function:Get-PoshixDockerComposeStatus}
Set-Item -Path "function:global:Get-PoshixDockerGlobalStatus" -Value ${function:Get-PoshixDockerGlobalStatus}
Set-Item -Path "function:global:Test-DockerAvailable" -Value ${function:Test-DockerAvailable}
Set-Item -Path "function:global:Invoke-DockerCli" -Value ${function:Invoke-DockerCli}
Set-Item -Path "function:global:Invoke-DockerCompose" -Value ${function:Invoke-DockerCompose}
Set-Item -Path "function:global:Get-DockerBackendInfo" -Value ${function:Get-DockerBackendInfo}
Set-Item -Path "function:global:Get-DockerStatus" -Value ${function:Get-DockerStatus}
Set-Item -Path "function:global:Get-DockerPromptInfo" -Value ${function:Get-DockerPromptInfo}

Set-Alias -Name dkr -Value Invoke-DockerCli -Scope Global
Set-Alias -Name dco -Value Invoke-DockerCompose -Scope Global
Set-Alias -Name dps -Value Get-DockerStatus -Scope Global
Set-Alias -Name dinfo -Value Get-DockerBackendInfo -Scope Global

$nativeDocker = Get-PoshixDockerNativeCommand
$settings = Get-PoshixDockerSettings
$shouldProxyDocker = ($settings.Mode -eq 'Wsl') -or (-not $nativeDocker -and (Get-PoshixWslCommand))
if ($shouldProxyDocker) {
    Set-Item -Path "function:global:docker" -Value ${function:Invoke-PoshixDockerProxy}
    Set-Item -Path "function:global:docker-compose" -Value ${function:Invoke-PoshixDockerComposeProxy}
}

Write-Verbose "[poshix] docker plugin loaded"
