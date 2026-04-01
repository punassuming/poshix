# Tests for TortoiseGit Plugin
BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'tortoisegit' -Force
}

Describe 'TortoiseGit Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Get-TortoiseGitCommand' {
            Get-Command Get-TortoiseGitCommand -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Test-TortoiseGitAvailable' {
            Get-Command Test-TortoiseGitAvailable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Invoke-TortoiseGit' {
            Get-Command Invoke-TortoiseGit -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Invoke-TortoiseGitDiff' {
            Get-Command Invoke-TortoiseGitDiff -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias tgit' {
            Get-Alias tgit -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias tgitdiff' {
            Get-Alias tgitdiff -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Availability checks when TortoiseGit is not installed' {
        It 'Should return false and emit warning' {
            if (Get-TortoiseGitCommand) {
                Set-ItResult -Skipped -Because 'TortoiseGit is installed in this environment'
                return
            }
            $output = Test-TortoiseGitAvailable 3>&1
            $result = $output | Where-Object { $_ -is [bool] } | Select-Object -Last 1
            $warnings = @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
            $result | Should -Be $false
            $warnings | Should -Not -BeNullOrEmpty
        }

        It 'Invoke-TortoiseGit should not throw' {
            if (Get-TortoiseGitCommand) {
                Set-ItResult -Skipped -Because 'TortoiseGit is installed in this environment'
                return
            }
            { Invoke-TortoiseGit -Command log -Path '.' -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Invoke-TortoiseGitDiff should not throw' {
            if (Get-TortoiseGitCommand) {
                Set-ItResult -Skipped -Because 'TortoiseGit is installed in this environment'
                return
            }
            { Invoke-TortoiseGitDiff -Path '.' -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Invoke-TortoiseGitDiff parameter validation' {
        It 'Should warn and return when Path does not exist' {
            if (Get-TortoiseGitCommand) {
                Set-ItResult -Skipped -Because 'TortoiseGit is installed in this environment'
                return
            }
            $warnings = @(Invoke-TortoiseGitDiff -Path 'C:\nonexistent\path\file.txt' 3>&1 |
                Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
            $warnings | Should -Not -BeNullOrEmpty
        }

        It 'Should warn and return when Path2 does not exist' {
            if (Get-TortoiseGitCommand) {
                Set-ItResult -Skipped -Because 'TortoiseGit is installed in this environment'
                return
            }
            $warnings = @(Invoke-TortoiseGitDiff -Path '.' -Path2 'C:\nonexistent\path\file.txt' -WarningAction Continue 3>&1 |
                Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
            $warnings | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invoke-TortoiseGit uses Start-Process (non-blocking)' {
        It 'Invoke-TortoiseGit body should use Start-Process' {
            $def = (Get-Command Invoke-TortoiseGit).ScriptBlock.ToString()
            $def | Should -Match 'Start-Process'
        }
        It 'Invoke-TortoiseGitDiff body should use Start-Process' {
            $def = (Get-Command Invoke-TortoiseGitDiff).ScriptBlock.ToString()
            $def | Should -Match 'Start-Process'
        }
    }
}

AfterAll {
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
