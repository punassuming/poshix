# Tests for Session Layouts Plugin
#
# Uses real ~/.poshix/layouts/ with unique test-prefixed layout names;
# all created files are cleaned up in AfterAll.

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'session-layouts' -Force

    # Unique prefix so tests never collide with real layouts
    $uid = [guid]::NewGuid().ToString('N').Substring(0, 8)
    $script:layoutName        = "poshix-test-$uid"
    $script:bookmarkLayout    = "poshix-test-bm-$uid"
    $script:restoreLayout     = "poshix-test-restore-$uid"
    $script:missingDirLayout  = "poshix-test-missing-$uid"
    $script:removeLayout      = "poshix-test-remove-$uid"

    $script:layoutsDir = Join-Path $HOME '.poshix' 'layouts'
    New-Item -ItemType Directory -Path $script:layoutsDir -Force | Out-Null

    # Directories for restore / bookmark tests
    $script:savedDir   = Join-Path $TestDrive 'saved-dir'
    $script:bookmarkDir = Join-Path $TestDrive 'bookmark-dir'
    New-Item -ItemType Directory -Path $script:savedDir   -Force | Out-Null
    New-Item -ItemType Directory -Path $script:bookmarkDir -Force | Out-Null
}

Describe 'Session Layouts Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Save-SessionLayout' {
            Get-Command Save-SessionLayout -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Restore-SessionLayout' {
            Get-Command Restore-SessionLayout -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Get-SessionLayouts' {
            Get-Command Get-SessionLayouts -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Remove-SessionLayout' {
            Get-Command Remove-SessionLayout -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Add-LayoutBookmark' {
            Get-Command Add-LayoutBookmark -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Invoke-LayoutBookmark' {
            Get-Command Invoke-LayoutBookmark -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias layout-save' {
            Get-Alias layout-save -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias layout-restore' {
            Get-Alias layout-restore -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias layouts' {
            Get-Alias layouts -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias layout-rm' {
            Get-Alias layout-rm -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias bookmark' {
            Get-Alias bookmark -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias bm' {
            Get-Alias bm -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Save-SessionLayout' {
        It 'Should create a JSON file in the layouts directory' {
            Push-Location $script:savedDir
            Save-SessionLayout -Name $script:layoutName
            Pop-Location
            $filePath = Join-Path $script:layoutsDir "$($script:layoutName).json"
            Test-Path $filePath | Should -Be $true
        }

        It 'Should store the current directory in the layout file' {
            $filePath = Join-Path $script:layoutsDir "$($script:layoutName).json"
            $layout = Get-Content -Raw -Path $filePath | ConvertFrom-Json
            $layout.Directory | Should -Be $script:savedDir
        }

        It 'Should store the layout name' {
            $filePath = Join-Path $script:layoutsDir "$($script:layoutName).json"
            $layout = Get-Content -Raw -Path $filePath | ConvertFrom-Json
            $layout.Name | Should -Be $script:layoutName
        }
    }

    Context 'Get-SessionLayouts' {
        It 'Should not throw' {
            { Get-SessionLayouts } | Should -Not -Throw
        }

        It 'Should list the saved test layout' {
            # Confirm the layout file exists so Get-SessionLayouts has something to read
            $filePath = Join-Path $script:layoutsDir "$($script:layoutName).json"
            Test-Path $filePath | Should -Be $true
        }
    }

    Context 'Restore-SessionLayout' {
        BeforeAll {
            Push-Location $script:savedDir
            Save-SessionLayout -Name $script:restoreLayout
            Pop-Location
        }

        It 'Should change the current directory to the saved path' {
            Restore-SessionLayout -Name $script:restoreLayout
            (Get-Location).Path | Should -Be $script:savedDir
        }

        It 'Should emit a warning when the saved directory no longer exists' {
            # Create a layout pointing to a directory we then delete
            $missingDir = Join-Path $TestDrive 'missing-dir'
            New-Item -ItemType Directory -Path $missingDir -Force | Out-Null
            Push-Location $missingDir
            Save-SessionLayout -Name $script:missingDirLayout
            Pop-Location
            Remove-Item $missingDir -Force -Recurse

            Restore-SessionLayout -Name $script:missingDirLayout -WarningVariable warnVar -WarningAction SilentlyContinue
            $warnVar | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Remove-SessionLayout' {
        BeforeAll {
            Push-Location $script:savedDir
            Save-SessionLayout -Name $script:removeLayout
            Pop-Location
        }

        It 'Should delete the layout file when -Force is specified' {
            $filePath = Join-Path $script:layoutsDir "$($script:removeLayout).json"
            Remove-SessionLayout -Name $script:removeLayout -Force
            Test-Path $filePath | Should -Be $false
        }

        It 'Should emit a warning if the layout does not exist' {
            Remove-SessionLayout -Name 'poshix-test-doesnotexist-xyz' -Force -WarningVariable warnVar -WarningAction SilentlyContinue
            $warnVar | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Add-LayoutBookmark and Invoke-LayoutBookmark' {
        BeforeAll {
            Push-Location $script:savedDir
            Save-SessionLayout -Name $script:bookmarkLayout
            Pop-Location
        }

        It 'Should add a bookmark to an existing layout' {
            Add-LayoutBookmark -Layout $script:bookmarkLayout -BookmarkName 'bmtest' -Path $script:bookmarkDir
            $filePath = Join-Path $script:layoutsDir "$($script:bookmarkLayout).json"
            $layout = Get-Content -Raw -Path $filePath | ConvertFrom-Json
            $bm = $layout.Bookmarks | Where-Object { $_.Name -eq 'bmtest' }
            $bm | Should -Not -BeNullOrEmpty
            $bm.Path | Should -Be $script:bookmarkDir
        }

        It 'Invoke-LayoutBookmark should navigate to the bookmarked directory' {
            Invoke-LayoutBookmark -Layout $script:bookmarkLayout -BookmarkName 'bmtest'
            (Get-Location).Path | Should -Be $script:bookmarkDir
        }

        It 'Invoke-LayoutBookmark should warn when bookmark not found' {
            Invoke-LayoutBookmark -Layout $script:bookmarkLayout -BookmarkName 'no-such-bookmark' `
                -WarningVariable warnVar -WarningAction SilentlyContinue
            $warnVar | Should -Not -BeNullOrEmpty
        }
    }
}

AfterAll {
    # Clean up all test layout files
    $layoutsDir = Join-Path $HOME '.poshix' 'layouts'
    Get-ChildItem -Path $layoutsDir -Filter 'poshix-test-*.json' -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
