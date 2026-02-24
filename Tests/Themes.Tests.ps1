# Tests for Themes Plugin
BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    
    # Load the themes plugin directly
    Import-PoshixPlugin -Name 'themes' -Force
}

Describe 'Themes Plugin' {
    Context 'Plugin Loading' {
        It 'Should load themes plugin successfully' {
            # Check if theme functions are available as a proxy for plugin being loaded
            Get-Command Get-PoshixThemes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It 'Should export theme functions' {
            Get-Command Get-PoshixThemes -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-PoshixTheme -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Set-PoshixTheme -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command New-PoshixTheme -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Set-WindowsTerminalTmuxKeybindings -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-PoshixThemes' {
        It 'Should list available themes' {
            $themes = Get-PoshixThemes
            $themes | Should -Not -BeNullOrEmpty
            $themes.Count | Should -BeGreaterThan 0
        }
        
        It 'Should include built-in themes' {
            $themes = Get-PoshixThemes
            $themeNames = $themes.Name
            $themeNames | Should -Contain 'dracula'
            $themeNames | Should -Contain 'monokai'
            $themeNames | Should -Contain 'nord'
            $themeNames | Should -Contain 'one-dark'
            $themeNames | Should -Contain 'solarized-dark'
            $themeNames | Should -Contain 'solarized-light'
        }
        
        It 'Should return theme objects with required properties' {
            $themes = Get-PoshixThemes
            $theme = $themes[0]
            $theme.Name | Should -Not -BeNullOrEmpty
            $theme.Path | Should -Not -BeNullOrEmpty
            $theme.Type | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Get-PoshixTheme' {
        It 'Should load a specific theme' {
            $theme = Get-PoshixTheme -Name 'dracula'
            $theme | Should -Not -BeNullOrEmpty
            $theme.name | Should -Be 'Dracula'
        }
        
        It 'Should load theme with colors' {
            $theme = Get-PoshixTheme -Name 'nord'
            $theme.colors | Should -Not -BeNullOrEmpty
            $theme.colors.background | Should -Not -BeNullOrEmpty
            $theme.colors.foreground | Should -Not -BeNullOrEmpty
        }
        
        It 'Should handle non-existent theme' {
            $theme = Get-PoshixTheme -Name 'nonexistent-theme' -ErrorAction SilentlyContinue
            $theme | Should -BeNullOrEmpty
        }
    }
    
    Context 'Set-PoshixTheme' {
        It 'Should apply a theme to Poshix' {
            Set-PoshixTheme -Name 'nord'
            $config = Get-PoshixConfig
            $config.Theme | Should -Be 'nord'
        }
        
        It 'Should update color configuration' {
            Set-PoshixTheme -Name 'dracula'
            $config = Get-PoshixConfig
            $config.Colors | Should -Not -BeNullOrEmpty
        }
        
        It 'Should handle invalid theme name' {
            $theme = Get-PoshixTheme -Name 'invalid-theme' -ErrorAction SilentlyContinue
            $theme | Should -BeNullOrEmpty
        }
    }
    
    Context 'New-PoshixTheme' {
        BeforeAll {
            $script:testThemePath = Join-Path $env:HOME '.poshix' | Join-Path -ChildPath 'themes' | Join-Path -ChildPath 'test-theme.theme.json'
        }
        
        AfterAll {
            if (Test-Path $script:testThemePath) {
                Remove-Item $script:testThemePath -Force
            }
        }
        
        It 'Should create a new theme' {
            $colors = @{
                background = '#1e1e1e'
                foreground = '#d4d4d4'
                black = '#000000'
                red = '#cd3131'
                green = '#0dbc79'
                yellow = '#e5e510'
                blue = '#2472c8'
                magenta = '#bc3fbc'
                cyan = '#11a8cd'
                white = '#e5e5e5'
                brightBlack = '#666666'
                brightRed = '#f14c4c'
                brightGreen = '#23d18b'
                brightYellow = '#f5f543'
                brightBlue = '#3b8eea'
                brightMagenta = '#d670d6'
                brightCyan = '#29b8db'
                brightWhite = '#ffffff'
            }
            
            New-PoshixTheme -Name 'test-theme' -Colors $colors
            Test-Path $script:testThemePath | Should -Be $true
        }
        
        It 'Should make created theme available' {
            $themes = Get-PoshixThemes
            $themes.Name | Should -Contain 'test-theme'
        }
        
        It 'Should be able to load created theme' {
            $theme = Get-PoshixTheme -Name 'test-theme'
            $theme | Should -Not -BeNullOrEmpty
            $theme.colors.background | Should -Be '#1e1e1e'
        }
    }
    
    Context 'Theme File Format' {
        It 'Should have valid JSON format for built-in themes' {
            $themes = Get-PoshixThemes | Where-Object { $_.Type -eq 'Built-in' }
            foreach ($themeInfo in $themes) {
                $content = Get-Content $themeInfo.Path -Raw
                { $content | ConvertFrom-Json } | Should -Not -Throw
            }
        }
        
        It 'Should have required color properties' {
            $theme = Get-PoshixTheme -Name 'dracula'
            $requiredColors = @('background', 'foreground', 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white')
            foreach ($color in $requiredColors) {
                $theme.colors.$color | Should -Not -BeNullOrEmpty
            }
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
