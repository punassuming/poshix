# Tests for Windows Terminal Plugin
BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force

    # Load required plugins
    Import-PoshixPlugin -Name 'themes','windows-terminal' -Force
}

Describe 'Windows Terminal Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Windows Terminal functions' {
            Get-Command Set-WindowsTerminalTheme -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Set-WindowsTerminalTmuxKeybindings -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Set-WindowsTerminalTheme' {
        BeforeAll {
            $script:wtSettingsDir = Join-Path $TestDrive 'WindowsTerminal'
            New-Item -ItemType Directory -Path $script:wtSettingsDir -Force | Out-Null
            $script:wtSettingsPath = Join-Path $script:wtSettingsDir 'settings.json'
            
            # Minimal settings.json without colorScheme on any profile
            $script:initialSettings = @{
                '$help' = 'https://aka.ms/terminal-documentation'
                profiles = @{
                    defaults = @{}
                    list = @(
                        @{
                            guid = '{61c54bbd-c2c6-5271-96e7-009a87ff44bf}'
                            name = 'Windows PowerShell'
                            commandline = 'powershell.exe'
                            hidden = $false
                        },
                        @{
                            guid = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'
                            name = 'PowerShell'
                            commandline = 'pwsh.exe'
                            hidden = $false
                        },
                        @{
                            guid = '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}'
                            name = 'Command Prompt'
                            commandline = 'cmd.exe'
                            hidden = $false
                        }
                    )
                }
                schemes = @()
            }
            $script:initialSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $script:wtSettingsPath -Encoding UTF8
        }
        
        AfterEach {
            # Restore initial settings after each test
            $script:initialSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $script:wtSettingsPath -Encoding UTF8
            # Remove backup if created
            if (Test-Path "$script:wtSettingsPath.backup") {
                Remove-Item "$script:wtSettingsPath.backup" -Force
            }
        }
        
        It 'Should add the theme as a color scheme' {
            $theme = Get-PoshixTheme -Name 'dracula'
            Set-WindowsTerminalTheme -Theme $theme -Name 'dracula' -SettingsPath $script:wtSettingsPath
            
            $updated = Get-Content $script:wtSettingsPath -Raw | ConvertFrom-Json
            $scheme = $updated.schemes | Where-Object { $_.name -eq 'Poshix-dracula' }
            $scheme | Should -Not -BeNullOrEmpty
            $scheme.background | Should -Be '#282a36'
        }
        
        It 'Should set colorScheme on PowerShell profiles that lack it' {
            $theme = Get-PoshixTheme -Name 'nord'
            Set-WindowsTerminalTheme -Theme $theme -Name 'nord' -SettingsPath $script:wtSettingsPath
            
            $updated = Get-Content $script:wtSettingsPath -Raw | ConvertFrom-Json
            $psProfiles = $updated.profiles.list | Where-Object { $_.commandline -match 'pwsh|powershell' }
            foreach ($p in $psProfiles) {
                $p.colorScheme | Should -Be 'Poshix-nord'
            }
        }
        
        It 'Should create a backup of the settings file' {
            $theme = Get-PoshixTheme -Name 'dracula'
            Set-WindowsTerminalTheme -Theme $theme -Name 'dracula' -SettingsPath $script:wtSettingsPath
            
            Test-Path "$script:wtSettingsPath.backup" | Should -Be $true
        }
        
        It 'Should not modify non-PowerShell profiles' {
            $theme = Get-PoshixTheme -Name 'dracula'
            Set-WindowsTerminalTheme -Theme $theme -Name 'dracula' -SettingsPath $script:wtSettingsPath
            
            $updated = Get-Content $script:wtSettingsPath -Raw | ConvertFrom-Json
            $cmdProfile = $updated.profiles.list | Where-Object { $_.name -eq 'Command Prompt' }
            $cmdProfile.PSObject.Properties['colorScheme'] | Should -BeNullOrEmpty
        }
        
        It 'Should handle settings with empty schemes array' {
            # Verify that empty schemes array is handled correctly (not re-initialized)
            $theme = Get-PoshixTheme -Name 'nord'
            { Set-WindowsTerminalTheme -Theme $theme -Name 'nord' -SettingsPath $script:wtSettingsPath } | Should -Not -Throw
            
            $updated = Get-Content $script:wtSettingsPath -Raw | ConvertFrom-Json
            ($updated.schemes | Where-Object { $_.name -eq 'Poshix-nord' }) | Should -Not -BeNullOrEmpty
        }
        
        It 'Should replace existing Poshix scheme of same name' {
            $theme = Get-PoshixTheme -Name 'dracula'
            # Apply twice
            Set-WindowsTerminalTheme -Theme $theme -Name 'dracula' -SettingsPath $script:wtSettingsPath
            Set-WindowsTerminalTheme -Theme $theme -Name 'dracula' -SettingsPath $script:wtSettingsPath
            
            $updated = Get-Content $script:wtSettingsPath -Raw | ConvertFrom-Json
            $schemes = @($updated.schemes | Where-Object { $_.name -eq 'Poshix-dracula' })
            $schemes.Count | Should -Be 1
        }
    }

    Context 'Set-WindowsTerminalTmuxKeybindings' {
        BeforeAll {
            $script:wtSettingsDir = Join-Path $TestDrive 'WindowsTerminalTmux'
            New-Item -ItemType Directory -Path $script:wtSettingsDir -Force | Out-Null
            $script:wtTmuxSettingsPath = Join-Path $script:wtSettingsDir 'settings.json'

            $script:initialTmuxSettings = @{
                '$help' = 'https://aka.ms/terminal-documentation'
                profiles = @{
                    defaults = @{}
                    list = @()
                }
                actions = @()
            }
            $script:initialTmuxSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $script:wtTmuxSettingsPath -Encoding UTF8
        }

        AfterEach {
            $script:initialTmuxSettings | ConvertTo-Json -Depth 10 | Set-Content -Path $script:wtTmuxSettingsPath -Encoding UTF8
            if (Test-Path "$script:wtTmuxSettingsPath.backup") {
                Remove-Item "$script:wtTmuxSettingsPath.backup" -Force
            }
        }

        It 'Should add tmux-style split and navigation actions' {
            Set-WindowsTerminalTmuxKeybindings -SettingsPath $script:wtTmuxSettingsPath

            $updated = Get-Content $script:wtTmuxSettingsPath -Raw | ConvertFrom-Json
            ($updated.actions | Where-Object { $_.name -eq 'Poshix: Split pane up' }).keys | Should -Be 'alt+shift+up'
            ($updated.actions | Where-Object { $_.name -eq 'Poshix: Split pane down' }).keys | Should -Be 'alt+shift+down'
            ($updated.actions | Where-Object { $_.name -eq 'Poshix: Focus pane left' }).keys | Should -Be 'alt+left'
            ($updated.actions | Where-Object { $_.name -eq 'Poshix: Focus pane right' }).keys | Should -Be 'alt+right'
        }

        It 'Should replace existing Poshix tmux-style actions' {
            Set-WindowsTerminalTmuxKeybindings -SettingsPath $script:wtTmuxSettingsPath
            Set-WindowsTerminalTmuxKeybindings -SettingsPath $script:wtTmuxSettingsPath

            $updated = Get-Content $script:wtTmuxSettingsPath -Raw | ConvertFrom-Json
            @($updated.actions | Where-Object { $_.name -match '^Poshix: ' }).Count | Should -Be 8
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
