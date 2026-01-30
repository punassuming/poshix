Describe "Importing" {
    Context "When importing the module" {
        It "Should have no warnings" {
            $ROOT = $PSScriptRoot
            $warn = $false
            $out = (pwsh -noprofile -Command "Import-Module $ROOT\..\poshix.psm1")
            $out | % { $warn = $warn -or ($_ -Match "WARNING") }
            $warn | Should -Be $false
        }
    }
}
