# Docker command completions
# Comprehensive docker completion for common operations

$dockerSubcommands = @{
    # Container commands
    'run' = @('-d', '--detach', '-i', '--interactive', '-t', '--tty', '--rm', '--name', '-p', '--publish', '-P', '--publish-all', '-v', '--volume', '--mount', '-e', '--env', '--env-file', '-w', '--workdir', '-u', '--user', '--network', '--link', '--privileged', '--restart', '-m', '--memory', '--cpus', '--entrypoint', '-h', '--hostname')
    'start' = @('-a', '--attach', '-i', '--interactive')
    'stop' = @('-t', '--time')
    'restart' = @('-t', '--time')
    'kill' = @('-s', '--signal')
    'rm' = @('-f', '--force', '-v', '--volumes', '-l', '--link')
    'exec' = @('-d', '--detach', '-i', '--interactive', '-t', '--tty', '-u', '--user', '-w', '--workdir', '-e', '--env', '--privileged')
    'logs' = @('-f', '--follow', '--tail', '-t', '--timestamps', '--since', '--until', '--details')
    'inspect' = @('-f', '--format', '-s', '--size', '--type')
    'ps' = @('-a', '--all', '-f', '--filter', '--format', '-n', '--last', '-l', '--latest', '-q', '--quiet', '-s', '--size', '--no-trunc')
    'top' = @()
    'stats' = @('-a', '--all', '--format', '--no-stream', '--no-trunc')
    'attach' = @('--detach-keys', '--no-stdin', '--sig-proxy')
    'cp' = @('-L', '--follow-link', '-a', '--archive')
    'create' = @('-i', '--interactive', '-t', '--tty', '--name', '-p', '--publish', '-e', '--env', '--env-file', '-v', '--volume', '--mount', '-w', '--workdir', '-u', '--user', '--network', '--entrypoint', '-h', '--hostname')
    'diff' = @()
    'pause' = @()
    'unpause' = @()
    'port' = @()
    'rename' = @()
    'update' = @('--restart', '-m', '--memory', '--memory-swap', '--memory-reservation', '--cpus', '--cpu-shares')
    'wait' = @()
    
    # Image commands
    'build' = @('-t', '--tag', '-f', '--file', '--build-arg', '--target', '--no-cache', '--pull', '--rm', '--force-rm', '--squash', '--network', '--label', '-q', '--quiet')
    'images' = @('-a', '--all', '-f', '--filter', '--format', '--no-trunc', '-q', '--quiet', '--digests')
    'pull' = @('-a', '--all-tags', '--disable-content-trust', '-q', '--quiet', '--platform')
    'push' = @('--disable-content-trust', '-a', '--all-tags')
    'rmi' = @('-f', '--force', '--no-prune')
    'tag' = @()
    'save' = @('-o', '--output')
    'load' = @('-i', '--input', '-q', '--quiet')
    'import' = @('-c', '--change', '-m', '--message', '--platform')
    'export' = @('-o', '--output')
    'history' = @('--format', '--no-trunc', '-q', '--quiet', '-H', '--human')
    'commit' = @('-a', '--author', '-c', '--change', '-m', '--message', '-p', '--pause')
    
    # Network commands
    'network' = @('create', 'connect', 'disconnect', 'inspect', 'ls', 'prune', 'rm')
    
    # Volume commands
    'volume' = @('create', 'inspect', 'ls', 'prune', 'rm')
    
    # System commands
    'system' = @('df', 'events', 'info', 'prune')
    
    # Compose commands (docker compose)
    'compose' = @('build', 'config', 'create', 'down', 'events', 'exec', 'images', 'kill', 'logs', 'pause', 'port', 'ps', 'pull', 'push', 'restart', 'rm', 'run', 'start', 'stop', 'top', 'unpause', 'up', 'version')
}

# Docker compose subcommand options
$dockerComposeSubcommands = @{
    'up' = @('-d', '--detach', '--build', '--force-recreate', '--no-recreate', '--no-build', '--no-start', '--abort-on-container-exit', '--remove-orphans', '-V', '--renew-anon-volumes', '--scale')
    'down' = @('-v', '--volumes', '--rmi', '--remove-orphans', '-t', '--timeout')
    'build' = @('--build-arg', '--no-cache', '--pull', '--parallel', '--progress', '-q', '--quiet')
    'ps' = @('-a', '--all', '--services', '--filter', '--format', '-q', '--quiet')
    'logs' = @('-f', '--follow', '--tail', '-t', '--timestamps', '--since', '--until', '--no-log-prefix')
    'exec' = @('-d', '--detach', '-e', '--env', '-T', '--no-TTY', '-u', '--user', '-w', '--workdir', '--privileged')
    'run' = @('-d', '--detach', '--name', '-e', '--env', '--rm', '-p', '--publish', '-v', '--volume', '-w', '--workdir', '-u', '--user', '--entrypoint', '--no-deps', '-T', '--no-TTY')
    'start' = @()
    'stop' = @('-t', '--timeout')
    'restart' = @('-t', '--timeout')
    'kill' = @('-s', '--signal')
    'rm' = @('-f', '--force', '-s', '--stop', '-v', '--volumes')
}

Register-ArgumentCompleter -Native -CommandName docker -ScriptBlock ({
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $tokens = $commandAst.CommandElements | ForEach-Object { $_.ToString() }
    $completingIndex = if ($wordToComplete) { $tokens.Count - 1 } else { $tokens.Count }
    
    # Complete main subcommands
    if ($completingIndex -eq 1 -and -not $wordToComplete.StartsWith('-')) {
        $dockerSubcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "docker $_")
        }
    }
    # Complete options
    elseif ($wordToComplete.StartsWith('-')) {
        $subcommand = if ($completingIndex -gt 1) { $tokens[1] } else { $null }
        
        if ($subcommand -and $dockerSubcommands.ContainsKey($subcommand)) {
            $dockerSubcommands[$subcommand] | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
            }
        }
    }
    # Context-specific completions
    else {
        $subcommand = if ($completingIndex -gt 1) { $tokens[1] } else { $null }
        
        switch ($subcommand) {
            'start' {
                # Complete with stopped containers
                & docker ps -a --filter "status=exited" --format "{{.Names}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "container: $_")
                }
            }
            'stop' {
                # Complete with running containers
                & docker ps --format "{{.Names}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "container: $_")
                }
            }
            'restart' {
                # Complete with all containers
                & docker ps -a --format "{{.Names}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "container: $_")
                }
            }
            'kill' {
                # Complete with running containers
                & docker ps --format "{{.Names}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "container: $_")
                }
            }
            'rm' {
                # Complete with stopped containers
                & docker ps -a --filter "status=exited" --format "{{.Names}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "container: $_")
                }
            }
            'exec' {
                # Complete with running containers
                & docker ps --format "{{.Names}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "container: $_")
                }
            }
            'logs' {
                # Complete with all containers
                & docker ps -a --format "{{.Names}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "container: $_")
                }
            }
            'run' {
                # Complete with image names
                & docker images --format "{{.Repository}}:{{.Tag}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "image: $_")
                }
            }
            'rmi' {
                # Complete with image names
                & docker images --format "{{.Repository}}:{{.Tag}}" 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "image: $_")
                }
            }
            'pull' {
                # Could integrate with Docker Hub API for popular images, but that's overkill
                # Just provide common images as examples
                $commonImages = @('nginx', 'alpine', 'ubuntu', 'debian', 'node', 'python', 'postgres', 'mysql', 'redis', 'mongo')
                $commonImages | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "image: $_")
                }
            }
        }
    }
}.GetNewClosure())

Write-Verbose "[poshix-completions] Docker completions registered"
