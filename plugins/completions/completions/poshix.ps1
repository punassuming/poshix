# Poshix command completions for built-in commands

# cd completion - suggest directories and special targets
Register-ArgumentCompleter -CommandName cd -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
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

# find completion
Register-ArgumentCompleter -CommandName find,Find-Files -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    
    # Complete options
    if ($wordToComplete.StartsWith('-')) {
        $options = @('-Name', '-Type', '-Extension', '-Path')
        $options | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
    }
}

# grep completion
Register-ArgumentCompleter -CommandName grep,Find-InFiles -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    # Complete options
    if ($wordToComplete.StartsWith('-')) {
        $options = @('-Pattern', '-Path', '-Include', '-Recurse', '-CaseSensitive', '-LineNumber')
        $options | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
    }
}

# ls completion
Register-ArgumentCompleter -CommandName ls -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    # Complete options
    if ($wordToComplete.StartsWith('-')) {
        $options = @('-l', '-a', '-X', '-t', '-S', '-U', '-R', '--NoColor')
        $options | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
    }
    # Complete with paths
    else {
        Get-ChildItem -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "$wordToComplete*" } | 
            ForEach-Object {
                $name = if ($_.Name -match '\s') { "`"$($_.Name)`"" } else { $_.Name }
                $type = if ($_.PSIsContainer) { 'ProviderContainer' } else { 'ProviderItem' }
                [System.Management.Automation.CompletionResult]::new($name, $_.Name, $type, $_.Name)
            }
    }
}

# Config commands completion
Register-ArgumentCompleter -CommandName Set-PoshixConfig,Get-PoshixConfig,Save-PoshixConfig,Reset-PoshixConfig -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    if ($wordToComplete.StartsWith('-')) {
        $options = @('-Config', '-Verbose')
        $options | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
    }
}

# Plugin commands completion
Register-ArgumentCompleter -CommandName Import-PoshixPlugin,Remove-PoshixPlugin -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    
    if ($wordToComplete.StartsWith('-')) {
        $options = @('-Name', '-Force', '-Verbose')
        $options | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
    }
    else {
        # Complete with available plugin names
        try {
            $customPluginPath = Join-Path $env:USERPROFILE ".poshix/plugins"
            $builtinPluginPath = Join-Path $PSScriptRoot "../.."
            
            $plugins = @()
            
            # Get built-in plugins
            if (Test-Path "$builtinPluginPath/plugins") {
                Get-ChildItem "$builtinPluginPath/plugins" -Directory -ErrorAction SilentlyContinue | 
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
    }
}

# History commands completion
Register-ArgumentCompleter -CommandName histls,Get-PoshixHistory,Invoke-PoshixHistory,rinvoke,Search-PoshixHistory,hgrep -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    if ($wordToComplete.StartsWith('-')) {
        $options = @('-Pattern', '-Id', '-Count', '-Verbose')
        $options | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
    }
}

Write-Verbose "[poshix-completions] Poshix command completions registered"
