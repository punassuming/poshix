# Additional common CLI tool completions (cargo, pip, dotnet)

# Cargo (Rust package manager) completions
$cargoSubcommands = @{
    'build' = @('--release', '--debug', '--target', '--manifest-path', '--features', '--all-features', '--no-default-features', '--jobs', '-j', '--verbose', '-v', '--quiet', '-q', '--color', '--frozen', '--locked', '--offline')
    'check' = @('--release', '--target', '--manifest-path', '--features', '--all-features', '--no-default-features', '--jobs', '-j', '--verbose', '-v', '--quiet', '-q', '--color')
    'clean' = @('--manifest-path', '--target', '--release', '--doc', '--verbose', '-v', '--quiet', '-q', '--color')
    'doc' = @('--open', '--no-deps', '--document-private-items', '--release', '--target', '--manifest-path', '--features', '--all-features', '--no-default-features', '--jobs', '-j', '--verbose', '-v')
    'new' = @('--bin', '--lib', '--name', '--vcs', '--edition', '--verbose', '-v', '--quiet', '-q')
    'init' = @('--bin', '--lib', '--name', '--vcs', '--edition', '--verbose', '-v', '--quiet', '-q')
    'add' = @('--dev', '--build', '--target', '--optional', '--no-default-features', '--default-features', '--features', '--rename', '--manifest-path')
    'run' = @('--release', '--target', '--manifest-path', '--features', '--all-features', '--no-default-features', '--jobs', '-j', '--verbose', '-v', '--quiet', '-q', '--bin', '--example')
    'test' = @('--release', '--target', '--manifest-path', '--features', '--all-features', '--no-default-features', '--jobs', '-j', '--verbose', '-v', '--quiet', '-q', '--lib', '--bin', '--test', '--bench', '--doc', '--no-fail-fast')
    'bench' = @('--target', '--manifest-path', '--features', '--all-features', '--no-default-features', '--jobs', '-j', '--verbose', '-v', '--quiet', '-q', '--bench', '--no-fail-fast')
    'update' = @('--aggressive', '--precise', '--manifest-path', '--verbose', '-v', '--quiet', '-q', '--dry-run')
    'search' = @('--limit', '--registry', '--verbose', '-v', '--quiet', '-q')
    'publish' = @('--dry-run', '--token', '--no-verify', '--allow-dirty', '--registry', '--manifest-path', '--verbose', '-v', '--quiet', '-q')
    'install' = @('--version', '--git', '--branch', '--tag', '--rev', '--path', '--bin', '--bins', '--example', '--examples', '--root', '--force', '-f', '--no-track', '--features', '--all-features', '--no-default-features', '--debug', '--verbose', '-v')
    'uninstall' = @('--bin', '--root', '--verbose', '-v', '--quiet', '-q')
    'tree' = @('--manifest-path', '--features', '--all-features', '--no-default-features', '--target', '--invert', '-i', '--prune', '--depth', '--prefix', '--verbose', '-v')
}

Register-ArgumentCompleter -CommandName cargo -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    
    if ($tokens.Count -eq 1 -or ($tokens.Count -eq 2 -and -not $wordToComplete.StartsWith('-'))) {
        $cargoSubcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "cargo $_")
        }
    }
    elseif ($wordToComplete.StartsWith('-')) {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        if ($subcommand -and $cargoSubcommands.ContainsKey($subcommand)) {
            $cargoSubcommands[$subcommand] | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
            }
        }
    }
}

# pip (Python package manager) completions
$pipSubcommands = @{
    'install' = @('-r', '--requirement', '-e', '--editable', '-t', '--target', '--user', '--upgrade', '-U', '--force-reinstall', '--no-deps', '--no-cache-dir', '--index-url', '--extra-index-url', '--pre', '--prefer-binary')
    'uninstall' = @('-r', '--requirement', '-y', '--yes')
    'list' = @('--outdated', '-o', '--uptodate', '-u', '--editable', '-e', '--local', '-l', '--user', '--format', '--not-required', '--exclude-editable')
    'show' = @('-f', '--files', '--verbose', '-v')
    'freeze' = @('-r', '--requirement', '--local', '-l', '--user', '--all', '--exclude-editable')
    'search' = @('-i', '--index')
    'download' = @('-r', '--requirement', '-d', '--dest', '--platform', '--python-version', '--implementation', '--abi', '--no-deps', '--index-url', '--extra-index-url')
    'wheel' = @('-w', '--wheel-dir', '-r', '--requirement', '--no-deps', '--build-option', '--global-option', '--pre', '--prefer-binary')
    'hash' = @('-a', '--algorithm')
    'check' = @()
    'config' = @('list', 'edit', 'get', 'set', 'unset', '--global', '--user', '--site')
    'debug' = @('--verbose', '-v')
    'cache' = @('dir', 'info', 'list', 'remove', 'purge')
}

Register-ArgumentCompleter -CommandName pip -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    
    if ($tokens.Count -eq 1 -or ($tokens.Count -eq 2 -and -not $wordToComplete.StartsWith('-'))) {
        $pipSubcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "pip $_")
        }
    }
    elseif ($wordToComplete.StartsWith('-')) {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        if ($subcommand -and $pipSubcommands.ContainsKey($subcommand)) {
            $pipSubcommands[$subcommand] | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
            }
        }
    }
    else {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        # For uninstall/show, complete with installed packages
        if ($subcommand -in @('uninstall', 'show')) {
            try {
                pip list --format=freeze 2>$null | ForEach-Object {
                    $pkg = $_ -split '==' | Select-Object -First 1
                    if ($pkg -like "$wordToComplete*") {
                        [System.Management.Automation.CompletionResult]::new($pkg, $pkg, 'ParameterValue', "package: $pkg")
                    }
                }
            } catch {
                # Ignore errors
            }
        }
    }
}

# dotnet CLI completions
$dotnetSubcommands = @{
    'new' = @('console', 'classlib', 'web', 'mvc', 'webapi', 'razor', 'angular', 'react', 'blazorserver', 'blazorwasm', '--list', '-l', '--force', '-f', '--name', '-n', '--output', '-o', '--framework', '-f', '--language', '-lang')
    'restore' = @('--source', '-s', '--packages', '--force', '--no-cache', '--disable-parallel', '--verbosity', '-v')
    'build' = @('--configuration', '-c', '--framework', '-f', '--runtime', '-r', '--output', '-o', '--no-restore', '--no-dependencies', '--verbosity', '-v', '--force', '--no-incremental')
    'publish' = @('--configuration', '-c', '--framework', '-f', '--runtime', '-r', '--output', '-o', '--no-restore', '--no-build', '--self-contained', '--no-self-contained', '--verbosity', '-v')
    'run' = @('--configuration', '-c', '--framework', '-f', '--runtime', '-r', '--project', '-p', '--no-restore', '--no-build', '--verbosity', '-v')
    'test' = @('--configuration', '-c', '--framework', '-f', '--runtime', '-r', '--output', '-o', '--no-restore', '--no-build', '--verbosity', '-v', '--logger', '-l', '--filter', '--collect')
    'pack' = @('--configuration', '-c', '--output', '-o', '--no-restore', '--no-build', '--include-symbols', '--include-source', '--serviceable', '--verbosity', '-v')
    'clean' = @('--configuration', '-c', '--framework', '-f', '--runtime', '-r', '--output', '-o', '--verbosity', '-v')
    'add' = @('package', 'reference')
    'remove' = @('package', 'reference')
    'list' = @('reference', 'package')
    'sln' = @('add', 'remove', 'list')
    'nuget' = @('delete', 'locals', 'push', 'add', 'update', 'remove', 'disable', 'enable', 'list')
    'tool' = @('install', 'uninstall', 'update', 'list', 'run', 'restore', 'search', '--global', '-g', '--local', '--tool-path')
    'watch' = @('--configuration', '-c', '--framework', '-f', '--project', '-p', '--no-restore', '--verbosity', '-v')
}

Register-ArgumentCompleter -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    
    if ($tokens.Count -eq 1 -or ($tokens.Count -eq 2 -and -not $wordToComplete.StartsWith('-'))) {
        $dotnetSubcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "dotnet $_")
        }
    }
    elseif ($wordToComplete.StartsWith('-')) {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        if ($subcommand -and $dotnetSubcommands.ContainsKey($subcommand)) {
            $dotnetSubcommands[$subcommand] | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
            }
        }
    }
}

Write-Verbose "[poshix-completions] cargo, pip, and dotnet completions registered"
