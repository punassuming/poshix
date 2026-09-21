Describe "Starship Plugin" {
    BeforeAll {
        $ROOT = Join-Path $PSScriptRoot ".."
    }

    Context "Plugin file structure" {
        It "Should have the plugin script" {
            Test-Path (Join-Path $ROOT "plugins/starship/starship.plugin.ps1") | Should -Be $true
        }

        It "Should have a README" {
            Test-Path (Join-Path $ROOT "plugins/starship/README.md") | Should -Be $true
        }

        It "Should have the context bridge" {
            Test-Path (Join-Path $ROOT "plugins/starship/starship-context.ps1") | Should -Be $true
        }
    }

    Context "Low-latency context bridge" {
        BeforeAll {
            . (Join-Path $ROOT "plugins/starship/starship-context.ps1")
        }

        It "Reads an attached branch directly from HEAD" {
            $repo = Join-Path $TestDrive 'attached'
            $gitDirectory = Join-Path $repo '.git'
            $null = New-Item -ItemType Directory -Path $gitDirectory
            Set-Content -LiteralPath (Join-Path $gitDirectory 'HEAD') -Value 'ref: refs/heads/feature/context'

            $context = Resolve-PoshixGitContext -Path $repo

            $context.Root | Should -Be $repo
            $context.Branch | Should -Be 'feature/context'
        }

        It "Builds a compact home-relative directory" {
            $homePath = Join-Path $TestDrive 'home'
            $path = Join-Path $homePath 'one\two\three\four'

            Get-PoshixStarshipDirectory -Path $path -HomePath $homePath -MaxSegments 3 |
                Should -Be ('two{0}three{0}four' -f [IO.Path]::DirectorySeparatorChar)
        }

        It "Uses a short commit id for a detached HEAD" {
            $repo = Join-Path $TestDrive 'detached'
            $gitDirectory = Join-Path $repo '.git'
            $null = New-Item -ItemType Directory -Path $gitDirectory
            Set-Content -LiteralPath (Join-Path $gitDirectory 'HEAD') -Value '0123456789abcdef'

            (Resolve-PoshixGitContext -Path $repo).Branch | Should -Be '01234567'
        }

        It "Follows a worktree gitdir pointer" {
            $repo = Join-Path $TestDrive 'worktree'
            $metadata = Join-Path $TestDrive 'metadata'
            $null = New-Item -ItemType Directory -Path $repo, $metadata
            Set-Content -LiteralPath (Join-Path $repo '.git') -Value 'gitdir: ../metadata'
            Set-Content -LiteralPath (Join-Path $metadata 'HEAD') -Value 'ref: refs/heads/worktree-branch'

            (Resolve-PoshixGitContext -Path $repo).Branch | Should -Be 'worktree-branch'
        }

        It "Clears Git variables after leaving a repository" {
            $repo = Join-Path $TestDrive 'clear-vars'
            $outside = Join-Path $TestDrive 'outside'
            $gitDirectory = Join-Path $repo '.git'
            $null = New-Item -ItemType Directory -Path $gitDirectory, $outside
            Set-Content -LiteralPath (Join-Path $gitDirectory 'HEAD') -Value 'ref: refs/heads/main'

            Push-Location $repo
            try {
                Update-PoshixStarshipEnvironment
                $env:POSHIX_GIT_BRANCH | Should -Be 'main'
            } finally {
                Pop-Location
            }

            Push-Location $outside
            try {
                Update-PoshixStarshipEnvironment
                $env:POSHIX_GIT_BRANCH | Should -BeNullOrEmpty
                $env:POSHIX_GIT_DIRTY | Should -BeNullOrEmpty
            } finally {
                Pop-Location
            }
        }
    }

    Context "Plugin loading" {
        It "Should source without errors when starship is not installed" {
            # Mock the missing command scenario
            $env:POSHIX_PROMPT = $null
            
            # Capture warnings by redirecting Warning stream
            $warnings = @()
            $null = . (Join-Path $ROOT "plugins/starship/starship.plugin.ps1") 3>&1 | ForEach-Object { $warnings += $_ }
            
            # Should not throw
            { . (Join-Path $ROOT "plugins/starship/starship.plugin.ps1") } | Should -Not -Throw
            
            # Should display a warning message about starship not being found
            $warningFound = $false
            foreach ($warn in $warnings) {
                if ($warn -match 'starship binary not found') {
                    $warningFound = $true
                    break
                }
            }
            $warningFound | Should -Be $true
        }
    }
}
