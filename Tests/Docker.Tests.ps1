BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'docker' -Force
}

Describe 'Docker Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Invoke-DockerCli' {
            Get-Command Invoke-DockerCli -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Invoke-DockerCompose' {
            Get-Command Invoke-DockerCompose -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Get-DockerBackendInfo' {
            Get-Command Get-DockerBackendInfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Get-DockerStatus' {
            Get-Command Get-DockerStatus -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Get-DockerPromptInfo' {
            Get-Command Get-DockerPromptInfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export alias dkr' {
            Get-Alias dkr -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export alias dco' {
            Get-Alias dco -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export alias dps' {
            Get-Alias dps -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Status helpers' {
        It 'Get-DockerBackendInfo should not throw' {
            { Get-DockerBackendInfo -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Get-DockerStatus should not throw' {
            { Get-DockerStatus -Quiet } | Should -Not -Throw
        }

        It 'Get-DockerPromptInfo should not throw' {
            { Get-DockerPromptInfo } | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Item Function:\global:docker -ErrorAction SilentlyContinue
    Remove-Item Function:\global:docker-compose -ErrorAction SilentlyContinue
    Remove-Item Alias:\dkr -ErrorAction SilentlyContinue
    Remove-Item Alias:\dco -ErrorAction SilentlyContinue
    Remove-Item Alias:\dps -ErrorAction SilentlyContinue
    Remove-Item Alias:\dinfo -ErrorAction SilentlyContinue
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
