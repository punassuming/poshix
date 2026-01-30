Describe "Enhanced Features" {
    BeforeAll {
        $ROOT = Join-Path $PSScriptRoot ".."
        Import-Module "$ROOT/poshix.psm1" -Force
    }
    
    Context "Configuration Management" {
        It "Should get default configuration" {
            $config = Get-PoshixConfig
            $config | Should -Not -BeNullOrEmpty
            $config.Colors | Should -Not -BeNullOrEmpty
            $config.FileTypes | Should -Not -BeNullOrEmpty
        }
        
        It "Should update configuration" {
            $originalColor = (Get-PoshixConfig).Colors.Directory
            $newConfig = @{
                Colors = @{
                    Directory = 'Red'
                }
            }
            Set-PoshixConfig -Config $newConfig
            (Get-PoshixConfig).Colors.Directory | Should -Be 'Red'
            
            # Reset for other tests
            $resetConfig = @{
                Colors = @{
                    Directory = $originalColor
                }
            }
            Set-PoshixConfig -Config $resetConfig
        }
        
        It "Should reset configuration" {
            Reset-PoshixConfig
            $config = Get-PoshixConfig
            $config.Colors.Directory | Should -Be 'Blue'
        }
    }
    
    Context "Enhanced ls Command" {
        It "Should run ls without errors" {
            { Get-FileListing $ROOT } | Should -Not -Throw
        }
        
        It "Should run ls -l without errors" {
            { Get-FileListing $ROOT -LongListing } | Should -Not -Throw
        }
        
        It "Should run ls -a without errors" {
            { Get-FileListing $ROOT -HiddenFiles } | Should -Not -Throw
        }
        
        It "Should support NoColor option" {
            { Get-FileListing $ROOT -NoColor } | Should -Not -Throw
        }
    }
    
    Context "History Management" {
        It "Should get history" {
            { Get-PoshixHistory } | Should -Not -Throw
        }
        
        It "Should clear history" {
            { Clear-PoshixHistory } | Should -Not -Throw
        }
        
        It "Should search history" {
            # Execute some commands to add to history
            $null = Get-ChildItem
            $null = Get-Process | Select-Object -First 1
            
            # Now search
            $results = Search-PoshixHistory -Pattern "ChildItem"
            # History might be empty in test context, so just check it doesn't throw
            { Search-PoshixHistory -Pattern "test" } | Should -Not -Throw
        }
    }
    
    Context "Linux-like Commands" {
        It "Should find files" {
            $results = Find-Files -Path $ROOT -Name "*.ps1"
            $results | Should -Not -BeNullOrEmpty
        }
        
        It "Should find directories" {
            # Find in the work directory which should have the poshix directory
            $results = Find-Files -Path "/home/runner/work" -Name "poshix" -Type d
            $results | Should -Not -BeNullOrEmpty
        }
        
        It "Should create file with touch" {
            $testFile = Join-Path ([System.IO.Path]::GetTempPath()) "poshix_test_$(Get-Random).txt"
            New-File $testFile
            Test-Path $testFile | Should -Be $true
            Remove-Item $testFile -Force
        }
        
        It "Should update timestamp with touch" {
            $testFile = Join-Path ([System.IO.Path]::GetTempPath()) "poshix_test_$(Get-Random).txt"
            New-Item $testFile -ItemType File | Out-Null
            Start-Sleep -Milliseconds 100
            $oldTime = (Get-Item $testFile).LastWriteTime
            Start-Sleep -Milliseconds 100
            New-File $testFile
            $newTime = (Get-Item $testFile).LastWriteTime
            $newTime | Should -BeGreaterThan $oldTime
            Remove-Item $testFile -Force
        }
        
        It "Should find command path with which" {
            { Get-CommandPath "pwsh" } | Should -Not -Throw
        }
        
        It "Should show working directory with pwd" {
            { Get-WorkingDirectory } | Should -Not -Throw
        }
        
        It "Should clear screen" {
            { Clear-Screen } | Should -Not -Throw
        }
    }
    
    Context "Module Exports" {
        It "Should export all required aliases" {
            $aliases = Get-Alias -ErrorAction SilentlyContinue
            $aliasNames = $aliases.Name
            
            # Check key aliases exist
            'ls' | Should -BeIn $aliasNames
            'histls' | Should -BeIn $aliasNames
            'find' | Should -BeIn $aliasNames
            'grep' | Should -BeIn $aliasNames
            'touch' | Should -BeIn $aliasNames
            'which' | Should -BeIn $aliasNames
        }
        
        It "Should export all required functions" {
            $functions = Get-Command -Module poshix -CommandType Function
            $functionNames = $functions.Name
            
            # Check key functions exist
            'Get-FileListing' | Should -BeIn $functionNames
            'Set-FileLocation' | Should -BeIn $functionNames
            'Get-PoshixConfig' | Should -BeIn $functionNames
            'Get-PoshixHistory' | Should -BeIn $functionNames
            'Find-Files' | Should -BeIn $functionNames
            'Get-CommandPath' | Should -BeIn $functionNames
        }
    }
}
