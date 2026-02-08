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
            # Plugin should warn but not throw
            { . (Join-Path $ROOT "plugins/starship/starship.plugin.ps1") } | Should -Not -Throw
        }
    }
}
