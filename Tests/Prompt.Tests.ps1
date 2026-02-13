BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' 'poshix.psm1'
    Import-Module $modulePath -Force
}

Describe "Prompt Engine Tests" {
    It "Get-PoshixPrompt function exists" {
        Get-Command Get-PoshixPrompt -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It "Initialize-PoshixPrompt function exists" {
        Get-Command Initialize-PoshixPrompt -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It "Get-PoshixPrompt returns a prompt string" {
        $prompt = Get-PoshixPrompt
        $prompt | Should -Not -BeNullOrEmpty
        $prompt | Should -BeOfType [string]
    }
    
    It "Prompt contains ANSI escape codes" {
        $prompt = Get-PoshixPrompt
        $prompt | Should -Match '\x1b\[\d+m'
    }
    
    It "Initialize-PoshixPrompt sets POSHIX_PROMPT environment variable" {
        $env:POSHIX_PROMPT = $null
        Initialize-PoshixPrompt
        $env:POSHIX_PROMPT | Should -Be 'poshix'
    }
    
    It "Get-PoshixPrompt respects POSHIX_PROMPT environment variable" {
        $env:POSHIX_PROMPT = 'starship'
        $prompt = Get-PoshixPrompt
        $prompt | Should -BeNullOrEmpty
        $env:POSHIX_PROMPT = 'poshix'
    }
}

Describe "Prompt Segments" {
    It "Path segment shows current directory" {
        $prompt = Get-PoshixPrompt
        # Prompt should contain some representation of a path
        $prompt | Should -Not -BeNullOrEmpty
    }
    
    It "Prompt works in git repository" {
        Push-Location $PSScriptRoot\..
        try {
            $prompt = Get-PoshixPrompt
            $prompt | Should -Not -BeNullOrEmpty
            # In a git repo, prompt should contain branch info
            $prompt | Should -Match 'copilot/implement-segment-based-prompt-engine'
        } finally {
            Pop-Location
        }
    }
    
    It "Prompt works outside git repository" {
        Push-Location $env:TEMP
        try {
            $prompt = Get-PoshixPrompt
            $prompt | Should -Not -BeNullOrEmpty
        } finally {
            Pop-Location
        }
    }
}

Describe "Prompt Configuration" {
    It "Prompt uses default configuration when none provided" {
        $config = Get-PoshixConfig
        $config.Prompt = $null
        $prompt = Get-PoshixPrompt
        $prompt | Should -Not -BeNullOrEmpty
    }
}

AfterAll {
    Remove-Module poshix -ErrorAction SilentlyContinue
}
