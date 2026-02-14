# npm and yarn command completions

# Helper function to get packages from package.json
function Get-PackageJsonPackages {
    param([string]$WordToComplete)
    
    if (Test-Path 'package.json') {
        try {
            $packageJson = Get-Content 'package.json' -Raw | ConvertFrom-Json
            $packages = @()
            if ($packageJson.dependencies) {
                $packages += $packageJson.dependencies.PSObject.Properties.Name
            }
            if ($packageJson.devDependencies) {
                $packages += $packageJson.devDependencies.PSObject.Properties.Name
            }
            $packages | Where-Object { $_ -like "$WordToComplete*" } | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "package: $_")
            }
        } catch {
            # Ignore errors reading package.json
        }
    }
}

$npmSubcommands = @{
    # Package management
    'install' = @('-g', '--global', '--save', '-S', '--save-dev', '-D', '--save-optional', '-O', '--no-save', '--save-exact', '-E', '--save-bundle', '-B', '--force', '-f', '--legacy-peer-deps', '--dry-run', '--package-lock-only')
    'i' = @('-g', '--global', '--save', '-S', '--save-dev', '-D', '--save-optional', '-O', '--no-save', '--save-exact', '-E', '--save-bundle', '-B', '--force', '-f', '--legacy-peer-deps')
    'uninstall' = @('-g', '--global', '--save', '-S', '--save-dev', '-D', '--save-optional', '-O', '--no-save', '--force', '-f')
    'update' = @('-g', '--global', '--save', '-S', '--save-dev', '-D', '--force', '-f', '--depth')
    'outdated' = @('-g', '--global', '--depth', '--json', '--long', '--parseable')
    'dedupe' = @('--dry-run', '--force', '-f', '--legacy-peer-deps')
    'prune' = @('--production', '--dry-run', '--json')
    
    # Script execution
    'run' = @('--silent', '-s', '--if-present', '--ignore-scripts', '--workspace', '-w', '--workspaces', '--ws')
    'run-script' = @('--silent', '-s', '--if-present', '--ignore-scripts')
    'start' = @()
    'test' = @('--ignore-scripts')
    'restart' = @()
    'stop' = @()
    
    # Package info
    'view' = @('--json')
    'show' = @('--json')
    'info' = @('--json')
    'list' = @('-g', '--global', '--depth', '--json', '--long', '--parseable', '--prod', '--production', '--dev', '--only')
    'ls' = @('-g', '--global', '--depth', '--json', '--long', '--parseable', '--prod', '--production', '--dev', '--only')
    'search' = @('--long', '--json', '--parseable', '--searchopts', '--searchexclude', '--searchlimit')
    
    # Publishing
    'publish' = @('--tag', '--access', '--dry-run', '--otp')
    'unpublish' = @('--force', '-f')
    'deprecate' = @()
    'owner' = @('add', 'rm', 'ls')
    'dist-tag' = @('add', 'rm', 'ls')
    
    # Repository management
    'init' = @('-y', '--yes', '--scope', '--workspace', '-w')
    'version' = @('--allow-same-version', '--commit-hooks', '--git-tag-version', '--json', '--preid', '--sign-git-tag')
    'audit' = @('--audit-level', '--dry-run', '--force', '-f', '--json', '--production', '--only')
    'doctor' = @()
    'fund' = @('--json', '--browser', '--unicode', '--which')
    
    # Configuration
    'config' = @('set', 'get', 'delete', 'list', 'edit', '-g', '--global', '--json')
    'set' = @('-g', '--global')
    'get' = @('-g', '--global')
    
    # Registry
    'login' = @('--registry', '--scope', '--auth-type')
    'logout' = @('--registry', '--scope')
    'adduser' = @('--registry', '--scope', '--auth-type')
    'whoami' = @('--registry')
    
    # Linking
    'link' = @('-g', '--global')
    'unlink' = @('-g', '--global')
    
    # Cache
    'cache' = @('add', 'clean', 'verify')
    
    # Misc
    'help' = @()
    'help-search' = @()
    'exec' = @('--package', '-p', '--call', '-c', '--workspace', '-w', '--workspaces', '--ws')
    'explore' = @()
    'prefix' = @('-g', '--global')
    'root' = @('-g', '--global')
    'bin' = @('-g', '--global')
    'rebuild' = @('-g', '--global')
    'ci' = @('--ignore-scripts', '--no-audit', '--no-optional')
}

$yarnSubcommands = @{
    # Package management
    'add' = @('-D', '--dev', '-P', '--peer', '-O', '--optional', '-E', '--exact', '-T', '--tilde', '--ignore-workspace-root-check', '--audit', '--no-lockfile')
    'remove' = @('--ignore-workspace-root-check', '--audit')
    'upgrade' = @('--latest', '-L', '--pattern', '--scope', '-S', '--exact', '-E', '--tilde', '-T', '--audit')
    'upgrade-interactive' = @('--latest', '-L')
    'install' = @('--force', '--flat', '--har', '--ignore-scripts', '--modules-folder', '--no-lockfile', '--production', '--pure-lockfile', '--frozen-lockfile', '--check-files', '--audit', '--offline')
    
    # Script execution
    'run' = @()
    'start' = @()
    'test' = @()
    
    # Package info
    'info' = @('--json')
    'list' = @('--depth', '--pattern')
    'why' = @()
    'outdated' = @()
    
    # Publishing
    'publish' = @('--access', '--tag', '--new-version', '--no-git-tag-version', '--no-commit-hooks')
    
    # Workspaces
    'workspace' = @()
    'workspaces' = @('info', 'run')
    
    # Linking
    'link' = @()
    'unlink' = @()
    
    # Cache
    'cache' = @('clean', 'dir', 'list')
    
    # Configuration
    'config' = @('set', 'get', 'delete', 'list', '-g', '--global')
    
    # Misc
    'init' = @('-y', '--yes', '-p', '--private')
    'version' = @('--new-version', '--major', '--minor', '--patch', '--premajor', '--preminor', '--prepatch', '--prerelease', '--no-git-tag-version', '--no-commit-hooks')
    'bin' = @()
    'audit' = @('--level', '--groups')
    'help' = @()
    'import' = @()
    'pack' = @('--filename', '-f')
}

# Register npm completer
Register-ArgumentCompleter -CommandName npm -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    
    # Complete subcommands
    if ($tokens.Count -eq 1 -or ($tokens.Count -eq 2 -and -not $wordToComplete.StartsWith('-'))) {
        $npmSubcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "npm $_")
        }
    }
    # Complete options
    elseif ($wordToComplete.StartsWith('-')) {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        
        if ($subcommand -and $npmSubcommands.ContainsKey($subcommand)) {
            $npmSubcommands[$subcommand] | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
            }
        }
    }
    # Complete scripts from package.json
    else {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        
        if ($subcommand -in @('run', 'run-script') -and (Test-Path 'package.json')) {
            try {
                $packageJson = Get-Content 'package.json' -Raw | ConvertFrom-Json
                if ($packageJson.scripts) {
                    $packageJson.scripts.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "script: $_")
                    }
                }
            } catch {
                # Ignore errors reading package.json
            }
        }
        # Complete package names for uninstall
        elseif ($subcommand -in @('uninstall', 'remove', 'rm', 'un')) {
            Get-PackageJsonPackages -WordToComplete $wordToComplete
        }
    }
}

# Register yarn completer
Register-ArgumentCompleter -CommandName yarn -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    
    # Complete subcommands
    if ($tokens.Count -eq 1 -or ($tokens.Count -eq 2 -and -not $wordToComplete.StartsWith('-'))) {
        # Yarn commands
        $yarnSubcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "yarn $_")
        }
        
        # Also suggest scripts from package.json
        if (Test-Path 'package.json') {
            try {
                $packageJson = Get-Content 'package.json' -Raw | ConvertFrom-Json
                if ($packageJson.scripts) {
                    $packageJson.scripts.PSObject.Properties.Name | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "script: $_")
                    }
                }
            } catch {
                # Ignore errors reading package.json
            }
        }
    }
    # Complete options
    elseif ($wordToComplete.StartsWith('-')) {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        
        if ($subcommand -and $yarnSubcommands.ContainsKey($subcommand)) {
            $yarnSubcommands[$subcommand] | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
            }
        }
    }
    # Complete package names for remove
    else {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        
        if ($subcommand -in @('remove', 'upgrade', 'why')) {
            Get-PackageJsonPackages -WordToComplete $wordToComplete
        }
    }
}

Write-Verbose "[poshix-completions] npm and yarn completions registered"
