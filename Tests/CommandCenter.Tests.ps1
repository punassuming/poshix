Describe 'command-center plugin' {
    BeforeAll {
        function Get-PoshixConfig { @{ Keybindings = @{ Enabled = $false } } }
        . (Join-Path $PSScriptRoot '..' 'plugins' 'command-center' 'command-center.plugin.ps1')
    }

    It 'exports the command center and help alias' {
        Get-Command Get-PoshixCommandCenter -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        (Get-Alias poshix-help).Definition | Should -Be 'Get-PoshixCommandCenter'
    }

    It 'returns keyboard shortcut metadata as objects' {
        $shortcuts = @(Get-PoshixCommandCenter -Section Shortcuts -AsObject)
        $shortcuts.Count | Should -Be 8
        $shortcuts.Name | Should -Contain 'Start-PoshixHerdrWorkArea'
        $shortcuts.Name | Should -Contain 'Save-PoshixClipboard'
        ($shortcuts | Where-Object Name -eq 'Save-PoshixClipboard').Shortcuts | Should -Match 'Alt\+v'
    }

    It 'combines aliases and shortcuts with their target commands' {
        $item = Get-PoshixCommandCenter -AsObject | Where-Object Name -eq 'Get-PoshixCommandCenter'
        $item.Aliases | Should -Match 'poshix-help'
        $item.Section | Should -Be 'Commands'
    }
}
