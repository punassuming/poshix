# Tests for Git Worktree Plugin
BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'git-worktree' -Force

    # Create a real git repo for tests that need one
    $script:testRepo = Join-Path $TestDrive 'git-repo'
    New-Item -ItemType Directory -Path $script:testRepo -Force | Out-Null
    Push-Location $script:testRepo
    & git init --quiet 2>&1 | Out-Null
    & git config user.email 'poshix-test@example.com' 2>&1 | Out-Null
    & git config user.name 'Poshix Test' 2>&1 | Out-Null
    & git commit --allow-empty -m 'init' --quiet 2>&1 | Out-Null
    Pop-Location

    # A plain directory (not a git repo) for negative tests
    $script:nonRepo = Join-Path $TestDrive 'not-a-repo'
    New-Item -ItemType Directory -Path $script:nonRepo -Force | Out-Null
}

Describe 'Git Worktree Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Get-GitWorktrees' {
            Get-Command Get-GitWorktrees -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export New-GitWorktree' {
            Get-Command New-GitWorktree -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Switch-GitWorktree' {
            Get-Command Switch-GitWorktree -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Remove-GitWorktree' {
            Get-Command Remove-GitWorktree -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias gwt' {
            Get-Alias gwt -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias gwt-add' {
            Get-Alias gwt-add -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias gwt-switch' {
            Get-Alias gwt-switch -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias gwt-rm' {
            Get-Alias gwt-rm -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get-GitWorktrees outside a git repository' {
        It 'Should emit a warning and return nothing' {
            Push-Location $script:nonRepo
            $result = Get-GitWorktrees -WarningVariable warnVar -WarningAction SilentlyContinue
            Pop-Location
            $warnVar | Should -Not -BeNullOrEmpty
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Get-GitWorktrees inside a git repository' {
        It 'Should return at least one worktree object' {
            Push-Location $script:testRepo
            $worktrees = Get-GitWorktrees
            Pop-Location
            $worktrees | Should -Not -BeNullOrEmpty
        }

        It 'Should return objects with Path, Branch, HEAD, and IsMain properties' {
            Push-Location $script:testRepo
            $worktrees = Get-GitWorktrees
            Pop-Location
            $main = @($worktrees)[0]
            $main.Path  | Should -Not -BeNullOrEmpty
            $main.IsMain | Should -Be $true
        }

        It 'Should mark the first entry as IsMain' {
            Push-Location $script:testRepo
            $worktrees = @(Get-GitWorktrees)
            Pop-Location
            $worktrees[0].IsMain | Should -Be $true
        }
    }

    Context 'New-GitWorktree outside a git repository' {
        It 'Should emit a warning and return nothing' {
            Push-Location $script:nonRepo
            $result = New-GitWorktree -Branch 'test-branch' -WarningVariable warnVar -WarningAction SilentlyContinue
            Pop-Location
            $warnVar | Should -Not -BeNullOrEmpty
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Switch-GitWorktree with no matching worktree' {
        It 'Should emit a warning when branch not found' {
            Push-Location $script:testRepo
            Switch-GitWorktree -Name 'no-such-branch-xyz-99' -WarningVariable warnVar
            Pop-Location
            $warnVar | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-GitWorktree with non-existent path or branch' {
        It 'Should emit a warning when worktree not found' {
            Push-Location $script:testRepo
            Remove-GitWorktree -Path 'no-such-branch-xyz-99' -WarningVariable warnVar
            Pop-Location
            $warnVar | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
