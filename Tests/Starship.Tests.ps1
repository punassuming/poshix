Describe "Starship Plugin" {
    BeforeAll {
        $ROOT = Join-Path $PSScriptRoot ".."
    }

    Context "Plugin file structure" {
        It "Should have the plugin script" {
            Test-Path (Join-Path $ROOT "plugins/starship/starship.plugin.ps1") | Should -Be $true
        }

        It "Should have a README" {
            Test-Path (Join-Path $ROOT "plugins/starship/README.md") | Should -Be $true
        }
    }

    Context "Plugin loading" {
        It "Should source without errors when starship is not installed" {
            # Mock the missing command scenario
            $env:POSHIX_PROMPT = $null
            
            # Capture warnings by redirecting Warning stream
            $warnings = @()
            $null = . (Join-Path $ROOT "plugins/starship/starship.plugin.ps1") 3>&1 | ForEach-Object { $warnings += $_ }
            
            # Should not throw
            { . (Join-Path $ROOT "plugins/starship/starship.plugin.ps1") } | Should -Not -Throw
            
            # Should display a warning message about starship not being found
            $warningFound = $false
            foreach ($warn in $warnings) {
                if ($warn -match 'starship binary not found') {
                    $warningFound = $true
                    break
                }
            }
            $warningFound | Should -Be $true
        }
    }
}
