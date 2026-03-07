BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'wmi' -Force
}

Describe 'WMI Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Get-WmiNamespace' {
            Get-Command Get-WmiNamespace -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Get-WmiClass' {
            Get-Command Get-WmiClass -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Get-WmiData' {
            Get-Command Get-WmiData -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Get-WmiSystemInfo' {
            Get-Command Get-WmiSystemInfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export alias wmiq' {
            Get-Alias wmiq -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export alias wmiinfo' {
            Get-Alias wmiinfo -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Helpers' {
        It 'Should normalize WMI namespaces' {
            (Normalize-PoshixWmiNamespace -Namespace 'root\\cimv2') | Should -Be 'root/cimv2'
        }

        It 'Should join namespace paths' {
            (Join-PoshixWmiNamespacePath -Parent 'root/cimv2' -Child 'Security') | Should -Be 'root/cimv2/Security'
        }
    }
}

AfterAll {
    Remove-Item Alias:\wmiq -ErrorAction SilentlyContinue
    Remove-Item Alias:\wmiinfo -ErrorAction SilentlyContinue
    Remove-Item Alias:\wmicls -ErrorAction SilentlyContinue
    Remove-Item Alias:\wmins -ErrorAction SilentlyContinue
    Remove-Item Alias:\wmisvc -ErrorAction SilentlyContinue
    Remove-Item Alias:\wmiproc -ErrorAction SilentlyContinue
    Remove-Item Function:\global:wmi -ErrorAction SilentlyContinue
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
