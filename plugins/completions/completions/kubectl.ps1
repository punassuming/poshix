# kubectl (Kubernetes CLI) command completions

$kubectlSubcommands = @{
    # Basic commands
    'create' = @('-f', '--filename', '--dry-run', '-o', '--output', '--save-config', '--validate', '--edit', '--windows-line-endings')
    'expose' = @('--port', '--protocol', '--target-port', '--name', '--external-ip', '--type', '--selector', '-l', '--labels', '--dry-run', '-o', '--output')
    'run' = @('--image', '--port', '--replicas', '--dry-run', '-o', '--output', '--command', '--env', '--expose', '--restart', '--rm', '-i', '--stdin', '-t', '--tty', '--labels', '-l')
    'set' = @('env', 'image', 'resources', 'selector', 'serviceaccount', 'subject')
    
    # Deploy commands
    'rollout' = @('history', 'pause', 'restart', 'resume', 'status', 'undo')
    'scale' = @('--replicas', '--resource-version', '--current-replicas', '-f', '--filename', '--selector', '-l', '--all', '--dry-run', '-o', '--output')
    'autoscale' = @('--min', '--max', '--cpu-percent', '--name', '-f', '--filename', '--dry-run', '-o', '--output')
    
    # Cluster management
    'certificate' = @('approve', 'deny')
    'cluster-info' = @('dump')
    'top' = @('node', 'pod')
    'cordon' = @('--dry-run', '--selector', '-l')
    'uncordon' = @('--dry-run', '--selector', '-l')
    'drain' = @('--force', '--grace-period', '--ignore-daemonsets', '--timeout', '--delete-emptydir-data', '--selector', '-l', '--dry-run')
    'taint' = @('--all', '--overwrite', '--selector', '-l', '--dry-run', '-o', '--output')
    
    # Troubleshooting
    'describe' = @('-f', '--filename', '--selector', '-l', '--all-namespaces', '-A', '--show-events')
    'logs' = @('-f', '--follow', '--tail', '--since', '--since-time', '--timestamps', '--previous', '-p', '--container', '-c', '--all-containers', '--prefix', '--selector', '-l')
    'attach' = @('-c', '--container', '-i', '--stdin', '-t', '--tty', '--pod-running-timeout')
    'exec' = @('-c', '--container', '-i', '--stdin', '-t', '--tty', '--pod-running-timeout')
    'port-forward' = @('--address', '--pod-running-timeout')
    'proxy' = @('--port', '--address', '--accept-hosts', '--accept-paths', '--reject-methods', '--reject-paths', '--api-prefix', '--www', '--www-prefix', '--disable-filter')
    'cp' = @('-c', '--container', '--no-preserve', '--retries')
    'auth' = @('can-i', 'reconcile', 'whoami')
    'debug' = @('--arguments-only', '--attach', '-c', '--container', '--copy-to', '--env', '--image', '--image-pull-policy', '--quiet', '-q', '--replace', '--same-node', '--set-image', '--share-processes', '--stdin', '-i', '--target', '--tty', '-t')
    
    # Advanced commands
    'diff' = @('-f', '--filename', '--force-conflicts', '--server-side', '--field-manager')
    'apply' = @('-f', '--filename', '--dry-run', '-o', '--output', '--force', '--grace-period', '--timeout', '--wait', '--prune', '--prune-whitelist', '--selector', '-l', '--all', '--cascade', '--field-manager', '--server-side', '--validate')
    'patch' = @('-f', '--filename', '-p', '--patch', '--type', '--dry-run', '-o', '--output', '--local')
    'replace' = @('-f', '--filename', '--force', '--cascade', '--grace-period', '--timeout', '--wait', '--dry-run', '-o', '--output')
    'wait' = @('--for', '--timeout', '-f', '--filename', '--selector', '-l', '--all', '--all-namespaces', '-A')
    'kustomize' = @('--enable-alpha-plugins', '--enable-helm', '--helm-command', '--load-restrictor', '--mount', '--network', '--network-name', '--reorder', '--as-current-user', '--env')
    
    # Resource management
    'get' = @('-o', '--output', '--show-kind', '--show-labels', '--selector', '-l', '-A', '--all-namespaces', '-w', '--watch', '--watch-only', '--chunk-size', '--field-selector', '--ignore-not-found', '--no-headers', '--output-watch-events', '--raw', '--sort-by')
    'edit' = @('-f', '--filename', '-o', '--output', '--save-config', '--validate', '--windows-line-endings')
    'delete' = @('-f', '--filename', '--cascade', '--force', '--grace-period', '--ignore-not-found', '--now', '--timeout', '--wait', '--selector', '-l', '--all', '--all-namespaces', '-A', '--dry-run', '-o', '--output', '--field-selector')
    
    # Settings
    'label' = @('--all', '--overwrite', '--resource-version', '--selector', '-l', '--dry-run', '-o', '--output', '--field-manager', '--list')
    'annotate' = @('--all', '--overwrite', '--resource-version', '--selector', '-l', '--dry-run', '-o', '--output', '--field-manager', '--list')
    'completion' = @('bash', 'zsh', 'fish', 'powershell')
    
    # Other commands
    'api-resources' = @('--api-group', '--cached', '--namespaced', '--no-headers', '-o', '--output', '--sort-by', '--verbs')
    'api-versions' = @()
    'config' = @('current-context', 'delete-cluster', 'delete-context', 'delete-user', 'get-clusters', 'get-contexts', 'get-users', 'rename-context', 'set', 'set-cluster', 'set-context', 'set-credentials', 'unset', 'use-context', 'view')
    'plugin' = @('list')
    'version' = @('--client', '--output', '-o', '--short')
    'explain' = @('--api-version', '--recursive')
}

# Common resource types for kubectl
$kubectlResources = @(
    'pods', 'po', 'services', 'svc', 'deployments', 'deploy', 'replicasets', 'rs',
    'statefulsets', 'sts', 'daemonsets', 'ds', 'jobs', 'cronjobs', 'cj',
    'nodes', 'no', 'namespaces', 'ns', 'persistentvolumes', 'pv', 'persistentvolumeclaims', 'pvc',
    'configmaps', 'cm', 'secrets', 'ingresses', 'ing', 'networkpolicies', 'netpol',
    'serviceaccounts', 'sa', 'roles', 'rolebindings', 'clusterroles', 'clusterrolebindings',
    'endpoints', 'ep', 'events', 'ev', 'limitranges', 'limits', 'resourcequotas', 'quota',
    'horizontalpodautoscalers', 'hpa', 'poddisruptionbudgets', 'pdb'
)

Register-ArgumentCompleter -CommandName kubectl -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
    
    # Complete subcommands
    if ($tokens.Count -eq 1 -or ($tokens.Count -eq 2 -and -not $wordToComplete.StartsWith('-'))) {
        $kubectlSubcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "kubectl $_")
        }
    }
    # Complete options
    elseif ($wordToComplete.StartsWith('-')) {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        
        # Global options
        $globalOptions = @(
            '--context', '--cluster', '--user', '--namespace', '-n',
            '--kubeconfig', '--request-timeout', '-v', '--v',
            '--as', '--as-group', '--certificate-authority', '--client-certificate',
            '--client-key', '--insecure-skip-tls-verify', '--tls-server-name',
            '--token', '--cache-dir'
        )
        
        $options = $globalOptions
        if ($subcommand -and $kubectlSubcommands.ContainsKey($subcommand)) {
            $options = $options + $kubectlSubcommands[$subcommand]
        }
        
        $options | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
    }
    # Complete resource types and names
    else {
        $subcommand = if ($tokens.Count -gt 1) { $tokens[1] } else { $null }
        
        # For commands that work with resources, suggest resource types
        if ($subcommand -in @('get', 'describe', 'delete', 'edit', 'logs', 'exec', 'port-forward', 'scale', 'autoscale', 'label', 'annotate', 'patch', 'replace')) {
            # Check if we already have a resource type
            $hasResourceType = $false
            $resourceType = $null
            
            for ($i = 2; $i -lt $tokens.Count; $i++) {
                if ($tokens[$i] -in $kubectlResources) {
                    $hasResourceType = $true
                    $resourceType = $tokens[$i]
                    break
                }
            }
            
            if (-not $hasResourceType) {
                # Suggest resource types
                $kubectlResources | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "resource: $_")
                }
            } else {
                # Try to complete with actual resource names from cluster
                try {
                    $namespace = if ($fakeBoundParameters.ContainsKey('namespace')) { $fakeBoundParameters['namespace'] } else { $null }
                    $namespaceArg = if ($namespace) { "-n $namespace" } else { '' }
                    
                    $cmd = "kubectl get $resourceType $namespaceArg -o name 2>`$null"
                    $resources = Invoke-Expression $cmd 2>$null
                    $resources | ForEach-Object { 
                        $name = $_ -replace '^[^/]+/', ''
                        if ($name -like "$wordToComplete*") {
                            [System.Management.Automation.CompletionResult]::new($name, $name, 'ParameterValue', $name)
                        }
                    }
                } catch {
                    # Ignore errors if kubectl is not available or cluster is not reachable
                }
            }
        }
        # For 'config use-context', suggest contexts
        elseif ($tokens.Count -ge 3 -and $tokens[1] -eq 'config' -and $tokens[2] -eq 'use-context') {
            try {
                kubectl config get-contexts -o name 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "context: $_")
                }
            } catch {
                # Ignore errors
            }
        }
        # For 'config set-context', suggest contexts
        elseif ($tokens.Count -ge 3 -and $tokens[1] -eq 'config' -and $tokens[2] -eq 'set-context') {
            try {
                kubectl config get-contexts -o name 2>$null | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "context: $_")
                }
            } catch {
                # Ignore errors
            }
        }
    }
}

Write-Verbose "[poshix-completions] kubectl completions registered"
