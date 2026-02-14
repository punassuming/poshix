BeforeAll {
    # Import the module
    Import-Module "$PSScriptRoot/../poshix.psm1" -Force
    
    # Load the completions plugin
    Import-PoshixPlugin -Name 'completions' -Verbose
}

Describe "Completions Plugin" {
    Context "Plugin Loading" {
        It "Should load completions plugin successfully" {
            # Check if the plugin files exist
            $pluginPath = "$PSScriptRoot/../plugins/completions/completions.plugin.ps1"
            Test-Path $pluginPath | Should -Be $true
            
            # Check if completion files exist
            $completionsDir = "$PSScriptRoot/../plugins/completions/completions"
            Test-Path $completionsDir | Should -Be $true
            Test-Path "$completionsDir/git.ps1" | Should -Be $true
            Test-Path "$completionsDir/docker.ps1" | Should -Be $true
        }
    }
    
    Context "Git Completions" {
        It "Should complete git subcommands" {
            # Test that we can complete git commands
            $result = TabExpansion2 -inputScript 'git com' -cursorColumn 7
            
            # Check that we get some completions
            $result | Should -Not -BeNullOrEmpty
            $result.CompletionMatches | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Docker Completions" {
        It "Should complete docker subcommands" {
            $result = TabExpansion2 -inputScript 'docker ps' -cursorColumn 9
            
            # Check that we get some completions
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "npm Completions" {
        It "Should complete npm subcommands" {
            $result = TabExpansion2 -inputScript 'npm i' -cursorColumn 5
            
            # Check that we get some completions
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "kubectl Completions" {
        It "Should complete kubectl subcommands" {
            $result = TabExpansion2 -inputScript 'kubectl g' -cursorColumn 9
            
            # Check that we get some completions  
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Additional Tool Completions" {
        It "Should have cargo completions file" {
            $completionsDir = "$PSScriptRoot/../plugins/completions/completions"
            Test-Path "$completionsDir/misc.ps1" | Should -Be $true
        }
        
        It "Should have poshix command completions file" {
            $completionsDir = "$PSScriptRoot/../plugins/completions/completions"
            Test-Path "$completionsDir/poshix.ps1" | Should -Be $true
        }
    }
}
