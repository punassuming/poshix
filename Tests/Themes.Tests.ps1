# Tests for Themes Plugin
BeforeAll {
    # Import the module
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    
    # Enable themes plugin
    Set-PoshixConfig -Config @{ Plugins = @('themes') }
    Import-Module $modulePath -Force
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
}

AfterAll {
    # Clean up
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
