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

        It "Should export Register-PoshixCompletion helper function" {
            Get-Command Register-PoshixCompletion -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Git Completions" {
        It "Should complete git subcommands matching prefix" {
            $result = TabExpansion2 -inputScript 'git com' -cursorColumn 7
            $result.CompletionMatches | Should -Not -BeNullOrEmpty
            # Should contain 'commit' and NOT return file-system paths
            $result.CompletionMatches.CompletionText | Should -Contain 'commit'
            $result.CompletionMatches | Where-Object { $_.ResultType -in 'ProviderItem','ProviderContainer' } | Should -BeNullOrEmpty
        }

        It "Should complete git subcommand options" {
            $result = TabExpansion2 -inputScript 'git commit --am' -cursorColumn 15
            $result.CompletionMatches.CompletionText | Should -Contain '--amend'
        }

        It "Should complete all git subcommands when no prefix" {
            $result = TabExpansion2 -inputScript 'git ' -cursorColumn 4
            $result.CompletionMatches.CompletionText | Should -Contain 'commit'
            $result.CompletionMatches.CompletionText | Should -Contain 'checkout'
            $result.CompletionMatches.CompletionText | Should -Contain 'status'
        }
    }
    
    Context "Docker Completions" {
        It "Should complete docker subcommands matching prefix" {
            $result = TabExpansion2 -inputScript 'docker ps' -cursorColumn 9
            $result.CompletionMatches.CompletionText | Should -Contain 'ps'
            $result.CompletionMatches | Where-Object { $_.ResultType -in 'ProviderItem','ProviderContainer' } | Should -BeNullOrEmpty
        }

        It "Should complete docker run options" {
            $result = TabExpansion2 -inputScript 'docker run --det' -cursorColumn 15
            $result.CompletionMatches.CompletionText | Should -Contain '--detach'
        }
    }
    
    Context "npm Completions" {
        It "Should complete npm subcommands matching prefix" {
            $result = TabExpansion2 -inputScript 'npm i' -cursorColumn 5
            $result.CompletionMatches.CompletionText | Should -Contain 'install'
            $result.CompletionMatches | Where-Object { $_.ResultType -in 'ProviderItem','ProviderContainer' } | Should -BeNullOrEmpty
        }

        It "Should complete npm install options" {
            $result = TabExpansion2 -inputScript 'npm install --glob' -cursorColumn 18
            $result.CompletionMatches.CompletionText | Should -Contain '--global'
        }
    }
    
    Context "kubectl Completions" {
        It "Should complete kubectl subcommands matching prefix" {
            $result = TabExpansion2 -inputScript 'kubectl g' -cursorColumn 9
            $result.CompletionMatches.CompletionText | Should -Contain 'get'
            $result.CompletionMatches | Where-Object { $_.ResultType -in 'ProviderItem','ProviderContainer' } | Should -BeNullOrEmpty
        }

        It "Should complete kubectl get resource types" {
            $result = TabExpansion2 -inputScript 'kubectl get po' -cursorColumn 14
            $result.CompletionMatches.CompletionText | Should -Contain 'pods'
        }
    }

    Context "cargo Completions" {
        It "Should complete cargo subcommands matching prefix" {
            $result = TabExpansion2 -inputScript 'cargo b' -cursorColumn 7
            $result.CompletionMatches.CompletionText | Should -Contain 'build'
            $result.CompletionMatches | Where-Object { $_.ResultType -in 'ProviderItem','ProviderContainer' } | Should -BeNullOrEmpty
        }

        It "Should complete cargo build options" {
            $result = TabExpansion2 -inputScript 'cargo build --rel' -cursorColumn 17
            $result.CompletionMatches.CompletionText | Should -Contain '--release'
        }
    }

    Context "pip Completions" {
        It "Should complete pip subcommands matching prefix" {
            $result = TabExpansion2 -inputScript 'pip in' -cursorColumn 6
            $result.CompletionMatches.CompletionText | Should -Contain 'install'
            $result.CompletionMatches | Where-Object { $_.ResultType -in 'ProviderItem','ProviderContainer' } | Should -BeNullOrEmpty
        }
    }

    Context "yarn Completions" {
        It "Should complete yarn subcommands matching prefix" {
            $result = TabExpansion2 -inputScript 'yarn ad' -cursorColumn 7
            $result.CompletionMatches.CompletionText | Should -Contain 'add'
            $result.CompletionMatches | Where-Object { $_.ResultType -in 'ProviderItem','ProviderContainer' } | Should -BeNullOrEmpty
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

    Context "Register-PoshixCompletion Helper" {
        It "Should register subcommand completions via helper" {
            Register-PoshixCompletion -Command 'testhelper' -Subcommands @{
                'build' = @('--release')
                'test'  = @('--filter')
            }
            $result = TabExpansion2 -inputScript 'testhelper b' -cursorColumn 12
            $result.CompletionMatches.CompletionText | Should -Contain 'build'
        }

        It "Should register option completions via helper" {
            Register-PoshixCompletion -Command 'testhelper2' -Options @('--verbose', '--quiet')
            $result = TabExpansion2 -inputScript 'testhelper2 --ver' -cursorColumn 16
            $result.CompletionMatches.CompletionText | Should -Contain '--verbose'
        }

        It "Should register subcommand-specific options via helper" {
            Register-PoshixCompletion -Command 'testhelper3' -Subcommands @{
                'build' = @('--release', '--debug')
            }
            $result = TabExpansion2 -inputScript 'testhelper3 build --rel' -cursorColumn 22
            $result.CompletionMatches.CompletionText | Should -Contain '--release'
        }
    }
}
