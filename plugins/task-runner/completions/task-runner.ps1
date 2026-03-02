# Tab completions for task-runner plugin
# Completes task names from Get-ProjectTasks for 'task' and 'Invoke-ProjectTask'

$_taskNameCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $taskNames = [System.Collections.Generic.List[string]]::new()

    # package.json
    if (Test-Path 'package.json') {
        try {
            $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
            if ($pkg.scripts) {
                $pkg.scripts.PSObject.Properties | ForEach-Object { $taskNames.Add($_.Name) }
            }
        } catch {}
    }

    # Makefile
    if (Test-Path 'Makefile') {
        try {
            Get-Content 'Makefile' | Where-Object { $_ -match '^[a-zA-Z][a-zA-Z0-9_-]*:' } | ForEach-Object {
                $taskNames.Add(($_ -split ':')[0])
            }
        } catch {}
    }

    # Taskfile.yml / Taskfile.yaml
    $taskfilePath = @('Taskfile.yml', 'Taskfile.yaml') | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($taskfilePath) {
        try {
            $inTasksBlock = $false
            Get-Content $taskfilePath | ForEach-Object {
                if ($_ -match '^tasks\s*:') {
                    $inTasksBlock = $true
                } elseif ($inTasksBlock -and $_ -match '^  ([a-zA-Z][a-zA-Z0-9_-]*)\s*:') {
                    $taskNames.Add($Matches[1])
                } elseif ($inTasksBlock -and $_ -match '^[^\s]') {
                    $inTasksBlock = $false
                }
            }
        } catch {}
    }

    # .poshix-tasks
    if (Test-Path '.poshix-tasks') {
        try {
            Get-Content '.poshix-tasks' | Where-Object { $_ -match '^\s*[^#\s]' } | ForEach-Object {
                if ($_ -match '^([^:]+):') {
                    $taskNames.Add($Matches[1].Trim())
                }
            }
        } catch {}
    }

    $taskNames | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName 'Invoke-ProjectTask' -ParameterName Name -ScriptBlock $_taskNameCompleter
Register-ArgumentCompleter -CommandName 'task'               -ParameterName Name -ScriptBlock $_taskNameCompleter
