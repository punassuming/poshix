# Git command completions
# Comprehensive git completion inspired by zsh and fish

$gitSubcommands = @{
    # Working with changes
    'add' = @('-A', '--all', '-f', '--force', '-i', '--interactive', '-p', '--patch', '-u', '--update', '-v', '--verbose', '-n', '--dry-run')
    'commit' = @('-a', '--all', '-m', '--message', '--amend', '-v', '--verbose', '-s', '--signoff', '--no-verify', '-n', '--no-edit', '-e', '--edit', '--fixup', '--squash')
    'status' = @('-s', '--short', '-b', '--branch', '--porcelain', '-u', '--untracked-files', '--ignored')
    'diff' = @('--cached', '--staged', '--stat', '--numstat', '--shortstat', '--name-only', '--name-status', '-w', '--ignore-all-space', '-b', '--ignore-space-change')
    'restore' = @('-s', '--source', '-S', '--staged', '-W', '--worktree', '-p', '--patch')
    'reset' = @('--soft', '--mixed', '--hard', '--merge', '--keep', '-p', '--patch')
    'rm' = @('-f', '--force', '-r', '--recursive', '--cached', '--dry-run', '-q', '--quiet')
    'mv' = @('-f', '--force', '-k', '-n', '--dry-run', '-v', '--verbose')
    
    # Branching and merging
    'branch' = @('-a', '--all', '-r', '--remotes', '-d', '--delete', '-D', '-m', '--move', '-M', '--copy', '-C', '-l', '--list', '-v', '--verbose', '--merged', '--no-merged')
    'checkout' = @('-b', '-B', '--orphan', '-f', '--force', '-t', '--track', '--no-track', '-m', '--merge', '-p', '--patch', '--detach')
    'switch' = @('-c', '--create', '-C', '--force-create', '-d', '--detach', '-f', '--force', '-m', '--merge', '-t', '--track', '--no-track')
    'merge' = @('--ff', '--no-ff', '--ff-only', '--squash', '--abort', '--continue', '--quit', '-m', '--message', '-v', '--verbose', '-s', '--strategy', '--no-commit')
    'rebase' = @('-i', '--interactive', '--continue', '--abort', '--skip', '--edit-todo', '--onto', '--root', '-p', '--preserve-merges', '-x', '--exec')
    'cherry-pick' = @('-e', '--edit', '-n', '--no-commit', '--continue', '--abort', '--quit', '-x', '-m', '--mainline')
    
    # Sharing and updating
    'clone' = @('--bare', '--mirror', '--depth', '--shallow-since', '--shallow-exclude', '--branch', '-b', '--single-branch', '--no-tags', '--recurse-submodules', '-j', '--jobs')
    'fetch' = @('--all', '--append', '--depth', '--shallow-since', '--shallow-exclude', '-f', '--force', '-k', '--keep', '-p', '--prune', '--dry-run', '-t', '--tags', '--no-tags')
    'pull' = @('--rebase', '--no-rebase', '--ff', '--no-ff', '--ff-only', '--all', '--append', '-f', '--force', '-k', '--keep', '-p', '--prune', '-t', '--tags', '--no-tags')
    'push' = @('-u', '--set-upstream', '-f', '--force', '--force-with-lease', '--all', '--mirror', '--dry-run', '--tags', '--follow-tags', '--no-verify', '-d', '--delete', '--prune')
    'remote' = @('add', 'rename', 'remove', 'set-head', 'set-branches', 'get-url', 'set-url', 'show', 'prune', 'update', '-v', '--verbose')
    
    # Inspection and comparison
    'log' = @('--oneline', '--graph', '--all', '--decorate', '--follow', '--stat', '--numstat', '--shortstat', '--name-only', '--name-status', '--abbrev-commit', '--pretty', '--format', '-p', '--patch', '-n', '--max-count', '--since', '--until', '--author', '--grep')
    'show' = @('--stat', '--numstat', '--shortstat', '--name-only', '--name-status', '--abbrev-commit', '--pretty', '--format', '-p', '--patch')
    'blame' = @('-L', '-e', '--show-email', '-w', '--ignore-whitespace', '-M', '-C', '--date', '--abbrev')
    'grep' = @('-i', '--ignore-case', '-w', '--word-regexp', '-v', '--invert-match', '-n', '--line-number', '-l', '--files-with-matches', '-L', '--files-without-match', '-c', '--count', '--all-match', '--and', '--or', '--not')
    'bisect' = @('start', 'bad', 'good', 'skip', 'reset', 'visualize', 'view', 'replay', 'log', 'run')
    
    # Repository administration
    'init' = @('--bare', '--shared', '--template', '--separate-git-dir', '--initial-branch', '-b')
    'config' = @('--global', '--system', '--local', '--file', '--get', '--get-all', '--get-regexp', '--add', '--unset', '--unset-all', '--rename-section', '--remove-section', '--list', '-l', '-e', '--edit')
    'tag' = @('-a', '--annotate', '-s', '--sign', '-m', '--message', '-f', '--force', '-d', '--delete', '-l', '--list', '-n', '--verify')
    'stash' = @('push', 'save', 'pop', 'apply', 'drop', 'clear', 'list', 'show', 'branch', '-u', '--include-untracked', '-a', '--all', '-k', '--keep-index', '-p', '--patch')
    'clean' = @('-d', '-f', '--force', '-i', '--interactive', '-n', '--dry-run', '-q', '--quiet', '-x', '-X')
    
    # Plumbing commands
    'rev-parse' = @('--abbrev-ref', '--short', '--symbolic-full-name', '--verify', '--quiet', '--sq', '--not', '--all', '--branches', '--tags', '--remotes')
    'rev-list' = @('--all', '--branches', '--tags', '--remotes', '--max-count', '--skip', '--since', '--until', '--author', '--grep', '--reverse')
}

# Common git global options
$gitGlobalOptions = @(
    '-C', '--git-dir', '--work-tree', '--no-pager', '--no-replace-objects',
    '--bare', '--literal-pathspecs', '--glob-pathspecs', '--noglob-pathspecs',
    '--help', '-h', '--version'
)

Register-ArgumentCompleter -Native -CommandName git -ScriptBlock ({
    param($wordToComplete, $commandAst, $cursorPosition)
    
    $tokens = $commandAst.CommandElements | ForEach-Object { $_.ToString() }
    # Number of complete tokens before the word being completed
    $completingIndex = if ($wordToComplete) { $tokens.Count - 1 } else { $tokens.Count }
    
    # If completing the subcommand (position 1)
    if ($completingIndex -eq 1 -and -not $wordToComplete.StartsWith('-')) {
        $gitSubcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "git $_")
        }
    }
    # If completing options
    elseif ($wordToComplete.StartsWith('-')) {
        # Determine if we're in a subcommand
        $subcommand = if ($completingIndex -gt 1) { $tokens[1] } else { $null }
        
        # Complete global options
        $options = $gitGlobalOptions
        
        # Add subcommand-specific options if we're in a subcommand
        if ($subcommand -and $gitSubcommands.ContainsKey($subcommand)) {
            $options = $options + $gitSubcommands[$subcommand]
        }
        
        $options | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
        }
    }
    # File/branch completion for specific commands
    else {
        $subcommand = if ($completingIndex -gt 1) { $tokens[1] } else { $null }
        
        switch ($subcommand) {
            'checkout' {
                # Complete with branches and files
                & git branch -a 2>$null | ForEach-Object { $_.Trim('* ') } | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "branch: $_")
                }
            }
            'switch' {
                # Complete with branches
                & git branch -a 2>$null | ForEach-Object { $_.Trim('* ') } | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "branch: $_")
                }
            }
            'merge' {
                # Complete with branches
                & git branch -a 2>$null | ForEach-Object { $_.Trim('* ') } | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "branch: $_")
                }
            }
            'add' {
                # Complete with modified/untracked files
                & git status --porcelain 2>$null | ForEach-Object { 
                    $_.Substring(3).Trim('"')
                } | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "file: $_")
                }
            }
            'restore' {
                # Complete with modified files
                & git status --porcelain 2>$null | Where-Object { $_ -match '^\s*M' } | ForEach-Object { 
                    $_.Substring(3).Trim('"')
                } | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "file: $_")
                }
            }
            'diff' {
                # Complete with branches and files
                & git branch -a 2>$null | ForEach-Object { $_.Trim('* ') } | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "branch: $_")
                }
            }
        }
    }
}.GetNewClosure())

Write-Verbose "[poshix-completions] Git completions registered"
