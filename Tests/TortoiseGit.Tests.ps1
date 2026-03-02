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
        It 'Should export alias tgit' {
            Get-Alias tgit -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
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
    }
}

AfterAll {
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
