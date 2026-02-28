# task-runner plugin for poshix
# Provides unified task discovery and execution across project types

function Get-ProjectTasks {
    <#
    .SYNOPSIS
    Discover available tasks for the current project.
    .DESCRIPTION
    Collects runnable tasks from package.json, Makefile, Taskfile.yml/yaml,
    and .poshix-tasks and returns pipeline-friendly objects with Source, Name,
    and Description properties.
    #>
    [CmdletBinding()]
    param()

    $tasks = [System.Collections.Generic.List[PSCustomObject]]::new()

    # --- package.json scripts ---
    if (Test-Path 'package.json') {
        Write-Verbose "[poshix] task-runner: reading package.json scripts"
        try {
            $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
            if ($pkg.scripts) {
                $pkg.scripts.PSObject.Properties | ForEach-Object {
                    $desc = if ($_.Value.Length -gt 60) { $_.Value.Substring(0, 57) + '...' } else { $_.Value }
                    $tasks.Add([PSCustomObject]@{
                        Source      = 'package.json'
                        Name        = $_.Name
                        Description = $desc
                    })
                }
            }
        } catch {
            Write-Warning "[poshix] task-runner: failed to parse package.json: $_"
        }
    }

    # --- Makefile targets ---
    if (Test-Path 'Makefile') {
        Write-Verbose "[poshix] task-runner: reading Makefile targets"
        try {
            Get-Content 'Makefile' | Where-Object { $_ -match '^[a-zA-Z][a-zA-Z0-9_-]*:' } | ForEach-Object {
                $target = ($_ -split ':')[0]
                $tasks.Add([PSCustomObject]@{
                    Source      = 'Makefile'
                    Name        = $target
                    Description = "make $target"
                })
            }
        } catch {
            Write-Warning "[poshix] task-runner: failed to parse Makefile: $_"
        }
    }

    # --- Taskfile.yml / Taskfile.yaml ---
    $taskfilePath = @('Taskfile.yml', 'Taskfile.yaml') | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($taskfilePath) {
        Write-Verbose "[poshix] task-runner: reading $taskfilePath tasks"
        try {
            $inTasksBlock = $false
            Get-Content $taskfilePath | ForEach-Object {
                if ($_ -match '^tasks\s*:') {
                    $inTasksBlock = $true
                } elseif ($inTasksBlock -and $_ -match '^  ([a-zA-Z][a-zA-Z0-9_-]*)\s*:') {
                    $tasks.Add([PSCustomObject]@{
                        Source      = $taskfilePath
                        Name        = $Matches[1]
                        Description = "task $($Matches[1])"
                    })
                } elseif ($inTasksBlock -and $_ -match '^[^\s]') {
                    $inTasksBlock = $false
                }
            }
        } catch {
            Write-Warning "[poshix] task-runner: failed to parse ${taskfilePath}: $_"
        }
    }

    # --- .poshix-tasks ---
    if (Test-Path '.poshix-tasks') {
        Write-Verbose "[poshix] task-runner: reading .poshix-tasks"
        try {
            Get-Content '.poshix-tasks' | Where-Object { $_ -match '^\s*[^#\s]' } | ForEach-Object {
                if ($_ -match '^([^:]+):\s*(.+)$') {
                    $name = $Matches[1].Trim()
                    $cmd  = $Matches[2].Trim()
                    $desc = if ($cmd.Length -gt 60) { $cmd.Substring(0, 57) + '...' } else { $cmd }
                    $tasks.Add([PSCustomObject]@{
                        Source      = '.poshix-tasks'
                        Name        = $name
                        Description = $desc
                    })
                }
            }
        } catch {
            Write-Warning "[poshix] task-runner: failed to parse .poshix-tasks: $_"
        }
    }

    if ($tasks.Count -eq 0) {
        Write-Host "No task files found in the current directory." -ForegroundColor Yellow
        Write-Host "Supported files: package.json, Makefile, Taskfile.yml, .poshix-tasks" -ForegroundColor Yellow
        Write-Host "Run 'task-init' to create a .poshix-tasks file." -ForegroundColor Yellow
        return
    }

    $tasks | Format-Table -GroupBy Source -Property Name, Description -AutoSize
}

function Invoke-ProjectTask {
    <#
    .SYNOPSIS
    Run a named task from the current project.
    .DESCRIPTION
    Discovers tasks from package.json, Makefile, Taskfile.yml/yaml, and
    .poshix-tasks, then executes the task matching -Name using the
    appropriate runner.
    .PARAMETER Name
    The name of the task to run.
    .PARAMETER Args
    Additional arguments forwarded to the underlying task runner.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Args
    )

    Write-Verbose "[poshix] task-runner: looking for task '$Name'"

    # --- package.json ---
    if (Test-Path 'package.json') {
        try {
            $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
            if ($pkg.scripts -and $pkg.scripts.PSObject.Properties[$Name]) {
                $cmdArgs = @('run', $Name)
                if ($Args) { $cmdArgs += '--'; $cmdArgs += $Args }
                Write-Host "npm $($cmdArgs -join ' ')" -ForegroundColor Cyan
                & npm @cmdArgs
                return
            }
        } catch {
            Write-Warning "[poshix] task-runner: failed to parse package.json: $_"
        }
    }

    # --- Makefile ---
    if (Test-Path 'Makefile') {
        $isTarget = Get-Content 'Makefile' |
            Where-Object { $_ -match '^[a-zA-Z][a-zA-Z0-9_-]*:' } |
            ForEach-Object { ($_ -split ':')[0] } |
            Where-Object { $_ -eq $Name }

        if ($isTarget) {
            $makeCmd = Get-Command make -ErrorAction SilentlyContinue
            if (-not $makeCmd) { $makeCmd = Get-Command gmake -ErrorAction SilentlyContinue }
            if (-not $makeCmd) {
                Write-Warning "[poshix] task-runner: make/gmake is not available in PATH"
                return
            }
            $cmdArgs = @($Name) + $Args
            Write-Host "$($makeCmd.Name) $($cmdArgs -join ' ')" -ForegroundColor Cyan
            & $makeCmd.Name @cmdArgs
            return
        }
    }

    # --- Taskfile.yml / Taskfile.yaml ---
    $taskfilePath = @('Taskfile.yml', 'Taskfile.yaml') | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($taskfilePath) {
        $inTasksBlock = $false
        $found = $false
        Get-Content $taskfilePath | ForEach-Object {
            if ($_ -match '^tasks\s*:') {
                $inTasksBlock = $true
            } elseif ($inTasksBlock -and $_ -match '^  ([a-zA-Z][a-zA-Z0-9_-]*)\s*:') {
                if ($Matches[1] -eq $Name) { $found = $true }
            } elseif ($inTasksBlock -and $_ -match '^[^\s]') {
                $inTasksBlock = $false
            }
        }
        if ($found) {
            if (-not (Get-Command task -ErrorAction SilentlyContinue)) {
                Write-Warning "[poshix] task-runner: go-task ('task') is not available in PATH"
                return
            }
            $cmdArgs = @($Name) + $Args
            Write-Host "task $($cmdArgs -join ' ')" -ForegroundColor Cyan
            & task @cmdArgs
            return
        }
    }

    # --- .poshix-tasks ---
    if (Test-Path '.poshix-tasks') {
        $matched = $null
        Get-Content '.poshix-tasks' | Where-Object { $_ -match '^\s*[^#\s]' } | ForEach-Object {
            if ($_ -match '^([^:]+):\s*(.+)$' -and $Matches[1].Trim() -eq $Name) {
                $matched = $Matches[2].Trim()
            }
        }
        if ($null -ne $matched) {
            $fullCmd = if ($Args) { "$matched $($Args -join ' ')" } else { $matched }
            Write-Host $fullCmd -ForegroundColor Cyan
            # .poshix-tasks is a user-authored file in the project repo; the user is
            # responsible for its contents, making Invoke-Expression acceptable here.
            Invoke-Expression $fullCmd
            return
        }
    }

    Write-Warning "[poshix] task-runner: no task named '$Name' found in this project"
}

function New-PoshixTaskFile {
    <#
    .SYNOPSIS
    Create a .poshix-tasks file in the current directory.
    .DESCRIPTION
    Scaffolds a .poshix-tasks file with example tasks. Use -Force to overwrite
    an existing file.
    .PARAMETER Force
    Overwrite an existing .poshix-tasks file.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Force
    )

    if ((Test-Path '.poshix-tasks') -and -not $Force) {
        Write-Warning "[poshix] task-runner: .poshix-tasks already exists. Use -Force to overwrite."
        return
    }

    $content = @'
# .poshix-tasks — project task definitions for poshix task-runner
# Format: taskname: command
# Lines starting with # are comments.

build: echo "Building project..."
test: echo "Running tests..."
clean: echo "Cleaning build artifacts..."
'@

    if ($PSCmdlet.ShouldProcess('.poshix-tasks', 'Create task file')) {
        Set-Content -Path '.poshix-tasks' -Value $content
        Write-Host "Created .poshix-tasks in $((Get-Location).Path)" -ForegroundColor Green
        Write-Host "Edit the file to define your project tasks, then run 'tasks' to see them." -ForegroundColor Green
    }
}

# Export functions to global scope
Set-Item -Path "function:global:Get-ProjectTasks"    -Value ${function:Get-ProjectTasks}
Set-Item -Path "function:global:Invoke-ProjectTask"  -Value ${function:Invoke-ProjectTask}
Set-Item -Path "function:global:New-PoshixTaskFile"  -Value ${function:New-PoshixTaskFile}

# Export aliases to global scope
Set-Alias -Name tasks     -Value Get-ProjectTasks   -Scope Global
Set-Alias -Name task      -Value Invoke-ProjectTask  -Scope Global
Set-Alias -Name task-init -Value New-PoshixTaskFile  -Scope Global

Write-Verbose "[poshix] task-runner plugin loaded"
