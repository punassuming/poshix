Describe "Plugin Loader" {
    BeforeAll {
        $ROOT = Join-Path $PSScriptRoot ".."
        Import-Module "$ROOT/poshix.psm1" -Force
    }
    
    Context "Plugin Discovery" {
        It "Should export Import-PoshixPlugin function" {
            Get-Command Import-PoshixPlugin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should export Remove-PoshixPlugin function" {
            Get-Command Remove-PoshixPlugin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should export Get-PoshixPlugin function" {
            Get-Command Get-PoshixPlugin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Plugin Loading" {
        It "Should warn when plugin not found" {
            $warning = $null
            Import-PoshixPlugin -Name 'nonexistent-plugin-xyz' -WarningVariable warning -WarningAction SilentlyContinue
            $warning | Should -Not -BeNullOrEmpty
        }
        
        It "Should track loaded plugins" {
            # Get-PoshixPlugin should not throw
            { Get-PoshixPlugin -Loaded } | Should -Not -Throw
        }
    }
    
    Context "Configuration Integration" {
        It "Should have Plugins key in default config" {
            $config = Get-PoshixConfig
            $config.ContainsKey('Plugins') | Should -Be $true
        }
        
        It "Should have Theme key in default config" {
            $config = Get-PoshixConfig
            $config.ContainsKey('Theme') | Should -Be $true
        }
    }
}
