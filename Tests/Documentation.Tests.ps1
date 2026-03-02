Describe 'Documentation Sync' {
    BeforeAll {
        $root = Join-Path $PSScriptRoot '..'
        $agentsPath = Join-Path $root 'AGENTS.md'
        $readmePath = Join-Path $root 'README.md'
        $exampleConfigPath = Join-Path $root '.poshixrc.json'
    }

    It 'AGENTS includes self-maintenance and README sync rules' {
        $agents = Get-Content -Raw $agentsPath
        $agents | Should Match 'AGENTS self-maintenance rules'
        $agents | Should Match 'README sync rules'
        $agents | Should Match '\.poshixrc\.json'
    }

    It 'README documents canonical config path and template file' {
        $readme = Get-Content -Raw $readmePath
        $readme | Should Match '~/.poshixrc\.json'
        $readme | Should Match '\./\.poshixrc\.json'
    }

    It 'Markdown docs do not use deprecated ~/.poshix/config.json path' {
        $mdFiles = Get-ChildItem -Path $root -Recurse -Filter '*.md' -File
        $matches = $mdFiles | Select-String -Pattern '~/.poshix/config.json'
        $matches | Should BeNullOrEmpty
    }

    It 'Example config file exists and is valid JSON' {
        Test-Path $exampleConfigPath | Should Be $true
        { Get-Content -Raw $exampleConfigPath | ConvertFrom-Json | Out-Null } | Should Not Throw
    }
}
