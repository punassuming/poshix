Describe 'Runtime command discovery' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'utils.ps1')
    }

    It 'returns structured evidence for a missing command' {
        $result = Resolve-PoshixCommand -Name 'poshix-command-that-does-not-exist'
        $result.Status | Should -Be 'NotFound'
        $result.Reason | Should -Match 'not found'
        $result.Remediation | Should -Match 'PATH'
    }

    It 'serializes an agent-safe runtime report as JSON' {
        $report = Get-PoshixRuntimeReport -AsJson | ConvertFrom-Json
        $report.Commands.Name | Should -Contain 'docker'
        $report.Commands.Name | Should -Contain 'kubectl'
        $report.Wsl.Status | Should -Not -BeNullOrEmpty
    }
}
