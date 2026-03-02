# Tab completions for git-worktree plugin
# Completes branch names from existing worktrees for gwt-switch and gwt-rm

Register-ArgumentCompleter -CommandName 'gwt-switch' -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $raw = & git worktree list --porcelain 2>$null
    if ($LASTEXITCODE -ne 0) { return }

    $branches = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $raw) {
        if ($line -match '^branch refs/heads/(.+)$') {
            $branches.Add($Matches[1])
        }
    }

    $branches | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName 'gwt-rm' -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $raw = & git worktree list --porcelain 2>$null
    if ($LASTEXITCODE -ne 0) { return }

    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $raw) {
        if ($line -match '^branch refs/heads/(.+)$') {
            $values.Add($Matches[1])
        } elseif ($line -match '^worktree (.+)$') {
            $values.Add($Matches[1])
        }
    }

    $values | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
