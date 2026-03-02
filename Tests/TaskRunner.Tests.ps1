# Tests for Task Runner Plugin
BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'task-runner' -Force

    # Subdirectories under TestDrive for isolation
    $script:emptyDir      = Join-Path $TestDrive 'empty'
    $script:npmDir        = Join-Path $TestDrive 'npm-project'
    $script:makeDir       = Join-Path $TestDrive 'make-project'
    $script:poshixDir     = Join-Path $TestDrive 'poshix-project'
    $script:taskInitDir   = Join-Path $TestDrive 'task-init'

    foreach ($d in @($script:emptyDir, $script:npmDir, $script:makeDir, $script:poshixDir, $script:taskInitDir)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }

    # package.json with a "test" script
    @{ scripts = [ordered]@{ test = 'echo test'; build = 'echo build' } } |
        ConvertTo-Json | Set-Content -Path (Join-Path $script:npmDir 'package.json') -Encoding UTF8

    # Makefile with targets
    @"
build:
	echo building

test:
	echo testing

.PHONY: build test
"@ | Set-Content -Path (Join-Path $script:makeDir 'Makefile') -Encoding UTF8

    # .poshix-tasks file
    @"
# poshix task file
greet: echo hello
deploy: echo deploying
"@ | Set-Content -Path (Join-Path $script:poshixDir '.poshix-tasks') -Encoding UTF8
}

Describe 'Task Runner Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Get-ProjectTasks' {
            Get-Command Get-ProjectTasks -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Invoke-ProjectTask' {
            Get-Command Invoke-ProjectTask -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export New-PoshixTaskFile' {
            Get-Command New-PoshixTaskFile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias tasks' {
            Get-Alias tasks -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias task' {
            Get-Alias task -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias task-init' {
            Get-Alias task-init -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-ProjectTasks in an empty directory' {
        It 'Should not throw' {
            Push-Location $script:emptyDir
            { Get-ProjectTasks } | Should -Not -Throw
            Pop-Location
        }

        It 'Should return nothing to the pipeline (message printed via Write-Host)' {
            Push-Location $script:emptyDir
            $result = Get-ProjectTasks
            Pop-Location
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Get-ProjectTasks with package.json' {
        It 'Should not throw' {
            Push-Location $script:npmDir
            { Get-ProjectTasks } | Should -Not -Throw
            Pop-Location
        }

        It 'Invoke-ProjectTask should find a script defined in package.json' {
            Push-Location $script:npmDir
            # If the task is found it will NOT produce a "no task named" warning
            Invoke-ProjectTask -Name 'test' -WarningVariable warnVar -WarningAction SilentlyContinue 2>&1 | Out-Null
            Pop-Location
            $warnVar | Where-Object { $_ -match 'no task named' } | Should -BeNullOrEmpty
        }
    }

    Context 'Get-ProjectTasks with Makefile' {
        It 'Should not throw' {
            Push-Location $script:makeDir
            { Get-ProjectTasks } | Should -Not -Throw
            Pop-Location
        }

        It 'Invoke-ProjectTask should find a target defined in Makefile' {
            Push-Location $script:makeDir
            Invoke-ProjectTask -Name 'build' -WarningVariable warnVar -WarningAction SilentlyContinue 2>&1 | Out-Null
            Pop-Location
            $warnVar | Where-Object { $_ -match 'no task named' } | Should -BeNullOrEmpty
        }
    }

    Context 'Get-ProjectTasks with .poshix-tasks' {
        It 'Should not throw' {
            Push-Location $script:poshixDir
            { Get-ProjectTasks } | Should -Not -Throw
            Pop-Location
        }

        It 'Invoke-ProjectTask should execute a task defined in .poshix-tasks' {
            Push-Location $script:poshixDir
            Invoke-ProjectTask -Name 'greet' -WarningVariable warnVar -WarningAction SilentlyContinue 2>&1 | Out-Null
            Pop-Location
            $warnVar | Where-Object { $_ -match 'no task named' } | Should -BeNullOrEmpty
        }
    }

    Context 'Invoke-ProjectTask when task does not exist' {
        It 'Should emit a warning' {
            Push-Location $script:emptyDir
            Invoke-ProjectTask -Name 'nonexistent-task-xyz' -WarningVariable warnVar -WarningAction SilentlyContinue
            Pop-Location
            $warnVar | Should -Not -BeNullOrEmpty
        }
    }

    Context 'New-PoshixTaskFile' {
        It 'Should create a .poshix-tasks file' {
            Push-Location $script:taskInitDir
            New-PoshixTaskFile
            $exists = Test-Path '.poshix-tasks'
            Pop-Location
            $exists | Should -Be $true
        }

        It 'Should warn if .poshix-tasks already exists without -Force' {
            Push-Location $script:taskInitDir
            # File already exists from previous test
            New-PoshixTaskFile -WarningVariable warnVar -WarningAction SilentlyContinue
            Pop-Location
            $warnVar | Should -Not -BeNullOrEmpty
        }

        It 'Should overwrite when -Force is specified' {
            Push-Location $script:taskInitDir
            { New-PoshixTaskFile -Force } | Should -Not -Throw
            Pop-Location
        }
    }
}

AfterAll {
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
