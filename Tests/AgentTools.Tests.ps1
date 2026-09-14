Describe 'agent-tools plugin' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'plugins' 'agent-tools' 'agent-tools.plugin.ps1')
    }

    It 'exports the tool inventory and safe launchers' {
        Get-Command Get-PoshixAgentTool -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        Get-Command Start-PoshixYazi -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        Get-Command Start-PoshixGitUi -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        Get-Command Start-PoshixAgentWorkspace -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'reports a safe non-control state outside Herdr' {
        $original = $env:HERDR_ENV
        try {
            Remove-Item Env:HERDR_ENV -ErrorAction SilentlyContinue
            (Get-PoshixHerdrIntegration).Status | Should -Be 'OutsideHerdr'
        } finally {
            if ($original) { $env:HERDR_ENV = $original } else { Remove-Item Env:HERDR_ENV -ErrorAction SilentlyContinue }
        }
    }
}
