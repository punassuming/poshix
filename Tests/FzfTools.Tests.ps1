# Tests for FzfTools Plugin
BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'fzf-tools' -Force
}

Describe 'FzfTools Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Test-FzfAvailable' {
            Get-Command Test-FzfAvailable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Find-FzfHistory' {
            Get-Command Find-FzfHistory -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Find-FzfFile' {
            Get-Command Find-FzfFile -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Find-FzfBranch' {
            Get-Command Find-FzfBranch -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Find-FzfProcess' {
            Get-Command Find-FzfProcess -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias fh' {
            Get-Alias fh -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias ff' {
            Get-Alias ff -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias fb' {
            Get-Alias fb -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias fp' {
            Get-Alias fp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-FzfAvailable when fzf is not installed' {
        It 'Should return false' {
            # fzf is not expected to be installed in the test environment
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            $result = Test-FzfAvailable -WarningVariable warnVar -WarningAction SilentlyContinue
            $result | Should -Be $false
        }

        It 'Should emit a warning' {
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            $output = Test-FzfAvailable 3>&1
            $warnings = @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
            $warnings | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Functions return early and do not throw when fzf is not available' {
        It 'Find-FzfHistory should not throw' {
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            { Find-FzfHistory -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-FzfFile should not throw' {
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            { Find-FzfFile -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-FzfBranch should not throw' {
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            { Find-FzfBranch -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-FzfProcess should not throw' {
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            { Find-FzfProcess -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Find-FzfHistory should return nothing' {
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            $result = Find-FzfHistory -WarningAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Find-FzfFile should return nothing' {
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            $result = Find-FzfFile -WarningAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Find-FzfBranch should return nothing' {
            if (Get-Command fzf -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'fzf is installed in this environment'
                return
            }
            $result = Find-FzfBranch -WarningAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
