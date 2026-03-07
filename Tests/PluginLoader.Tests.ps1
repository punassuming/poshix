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

        It "Should export Get-PoshixPluginCatalog function" {
            Get-Command Get-PoshixPluginCatalog -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
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

        It "Should show detailed available plugins without throwing" {
            { Get-PoshixPlugin -Available -Detailed } | Should -Not -Throw
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

    Context "Plugin Catalog" {
        It "Should return metadata for all built-in plugins" {
            $catalog = Get-PoshixPluginCatalog | Where-Object Scope -eq 'Built-in'

            $catalog.Name | Should -Contain 'completions'
            $catalog.Name | Should -Contain 'docker'
            $catalog.Name | Should -Contain 'themes'
            $catalog.Name | Should -Contain 'windows-terminal'
            $catalog.Name | Should -Contain 'git-worktree'
            $catalog.Name | Should -Contain 'fzf-tools'
            $catalog.Name | Should -Contain 'k8s-context'
            $catalog.Name | Should -Contain 'task-runner'
            $catalog.Name | Should -Contain 'session-layouts'
            $catalog.Name | Should -Contain 'autohotkey'
            $catalog.Name | Should -Contain 'tortoisegit'
            $catalog.Name | Should -Contain 'starship'
        }

        It "Should load plugin metadata from plugin.json" {
            $plugin = Get-PoshixPluginCatalog | Where-Object Name -eq 'fzf-tools' | Select-Object -First 1

            $plugin.Description | Should -Be 'Fuzzy-finding wrappers for history, files, branches, and processes.'
            $plugin.Commands | Should -Contain 'fh'
            $plugin.Requires | Should -Contain 'fzf'
            $plugin.MetadataPath | Should -Match 'plugin\.json$'
        }

        It "Should have valid JSON metadata for built-in plugins" {
            $metadataFiles = Get-ChildItem -Path (Join-Path $ROOT 'plugins') -Recurse -Filter 'plugin.json' -File

            $metadataFiles.Count | Should -BeGreaterThan 0
            foreach ($file in $metadataFiles) {
                { Get-Content -Raw $file.FullName | ConvertFrom-Json | Out-Null } | Should -Not -Throw
            }
        }
    }
}
