BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'wsl' -Force
}

Describe 'WSL Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Get-WslDistribution' {
            Get-Command Get-WslDistribution -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Invoke-WslCommand' {
            Get-Command Invoke-WslCommand -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Get-WslStatus' {
            Get-Command Get-WslStatus -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export alias wslls' {
            Get-Alias wslls -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export alias wslx' {
            Get-Alias wslx -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Parsers' {
        It 'Should parse installed distro tables' {
            $parsed = ConvertFrom-PoshixWslDistributionText -Lines @(
                '  NAME      STATE    VERSION'
                '* Ubuntu    Running  2'
                '  Debian    Stopped  2'
            )

            $parsed.Count | Should -Be 2
            $parsed[0].Name | Should -Be 'Ubuntu'
            $parsed[0].IsDefault | Should -Be $true
            $parsed[1].State | Should -Be 'Stopped'
        }

        It 'Should parse online distro tables' {
            $parsed = ConvertFrom-PoshixWslOnlineDistributionText -Lines @(
                'NAME                FRIENDLY NAME'
                'Ubuntu-24.04        Ubuntu 24.04 LTS'
            )

            $parsed.Count | Should -Be 1
            $parsed[0].Name | Should -Be 'Ubuntu-24.04'
            $parsed[0].FriendlyName | Should -Be 'Ubuntu 24.04 LTS'
        }

        It 'Should parse WSL status output' {
            $status = ConvertFrom-PoshixWslStatusText -Lines @(
                'Default Distribution: Ubuntu'
                'Default Version: 2'
                'WSL1 is not supported with your current machine configuration.'
            )

            $status.DefaultDistribution | Should -Be 'Ubuntu'
            $status.DefaultVersion | Should -Be '2'
            $status.Notes.Count | Should -Be 1
        }
    }
}

AfterAll {
    Remove-Item Alias:\wslls -ErrorAction SilentlyContinue
    Remove-Item Alias:\wslx -ErrorAction SilentlyContinue
    Remove-Item Alias:\wslinfo -ErrorAction SilentlyContinue
    Remove-Item Function:\global:wsl -ErrorAction SilentlyContinue
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
