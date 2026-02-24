# Poshix command completions for built-in commands

# cd completion - suggest special targets and directories
# Register on the actual function (cd is an alias for Set-FileLocation)
Register-ArgumentCompleter -CommandName Set-FileLocation -ParameterName cdPath -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # Special cd targets
    $specialTargets = @('-', '..', '../..', '../../..', '~')

    # Complete with special targets
    $specialTargets | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }

    # Complete with directories
    Get-ChildItem -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$wordToComplete*" } |
        ForEach-Object {
            $name = if ($_.Name -match '\s') { "`"$($_.Name)`"" } else { $_.Name }
            [System.Management.Automation.CompletionResult]::new($name, $_.Name, 'ProviderContainer', $_.Name)
        }
}

# ls completion - complete the path argument
# Register on the actual function (ls is an alias for Get-FileListing)
Register-ArgumentCompleter -CommandName Get-FileListing -ParameterName lspath -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    Get-ChildItem -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "$wordToComplete*" } |
        ForEach-Object {
            $name = if ($_.Name -match '\s') { "`"$($_.Name)`"" } else { $_.Name }
            $type = if ($_.PSIsContainer) { 'ProviderContainer' } else { 'ProviderItem' }
            [System.Management.Automation.CompletionResult]::new($name, $_.Name, $type, $_.Name)
        }
}

# Plugin commands completion - complete the -Name parameter with available plugin names
# Pre-compute the built-in plugins path so GetNewClosure() can capture it
$script:_poshixCompletionsPluginsRoot = if ($PSScriptRoot) {
    # poshix.ps1 is at plugins/completions/completions/ - go up two levels to plugins/
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
} else { $null }

Register-ArgumentCompleter -CommandName Import-PoshixPlugin,Remove-PoshixPlugin -ParameterName Name -ScriptBlock ({
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    try {
        $customPluginPath = Join-Path $env:USERPROFILE ".poshix/plugins"
        $builtinPluginPath = $script:_poshixCompletionsPluginsRoot

        $plugins = @()

        # Get built-in plugins
        if ($builtinPluginPath -and (Test-Path $builtinPluginPath)) {
            Get-ChildItem $builtinPluginPath -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { $plugins += $_.Name }
        }

        # Get custom plugins
        if (Test-Path $customPluginPath) {
            Get-ChildItem $customPluginPath -Directory -ErrorAction SilentlyContinue |
                ForEach-Object {
                    if ($_.Name -notin $plugins) {
                        $plugins += $_.Name
                    }
                }
        }

        $plugins | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "plugin: $_")
        }
    } catch {
        # Ignore errors
    }
}.GetNewClosure())

Write-Verbose "[poshix-completions] Poshix command completions registered"
