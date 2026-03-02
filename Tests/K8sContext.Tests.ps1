# Tests for K8s Context Plugin
BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'k8s-context' -Force
}

Describe 'K8s Context Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Test-KubectlAvailable' {
            Get-Command Test-KubectlAvailable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Invoke-KubeContext' {
            Get-Command Invoke-KubeContext -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Invoke-KubeNamespace' {
            Get-Command Invoke-KubeNamespace -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Get-KubeContextInfo' {
            Get-Command Get-KubeContextInfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Get-KubePromptInfo' {
            Get-Command Get-KubePromptInfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias kctx' {
            Get-Alias kctx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias kns' {
            Get-Alias kns -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias kinfo' {
            Get-Alias kinfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Test-KubectlAvailable when kubectl is not installed' {
        It 'Should return false' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            $result = Test-KubectlAvailable -WarningVariable warnVar 3>&1
            $result | Should -Be $false
        }

        It 'Should emit a warning' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            Test-KubectlAvailable -WarningVariable warnVar 3>&1 | Out-Null
            $warnVar | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Functions return gracefully when kubectl is not available' {
        It 'Invoke-KubeContext should not throw' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            { Invoke-KubeContext -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Invoke-KubeContext should return nothing' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            $result = Invoke-KubeContext -WarningAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Invoke-KubeNamespace should not throw' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            { Invoke-KubeNamespace -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Invoke-KubeNamespace should return nothing' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            $result = Invoke-KubeNamespace -WarningAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Get-KubeContextInfo should not throw' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            { Get-KubeContextInfo -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Get-KubeContextInfo should return nothing' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            $result = Get-KubeContextInfo -WarningAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }

        It 'Get-KubePromptInfo should return an empty string when kubectl is absent' {
            if (Get-Command kubectl -ErrorAction SilentlyContinue) {
                Set-ItResult -Skipped -Because 'kubectl is installed in this environment'
                return
            }
            $result = Get-KubePromptInfo
            $result | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
