# Tests for AutoHotkey Plugin
BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'poshix.psm1'
    Import-Module $modulePath -Force
    Import-PoshixPlugin -Name 'autohotkey' -Force
}

Describe 'AutoHotkey Plugin' {
    Context 'Plugin Loading' {
        It 'Should export Get-AutoHotkeyCommand' {
            Get-Command Get-AutoHotkeyCommand -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Test-AutoHotkeyAvailable' {
            Get-Command Test-AutoHotkeyAvailable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Start-AutoHotkeyScript' {
            Get-Command Start-AutoHotkeyScript -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export Edit-AutoHotkeyScript' {
            Get-Command Edit-AutoHotkeyScript -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias ahk' {
            Get-Alias ahk -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        It 'Should export alias ahk-edit' {
            Get-Alias ahk-edit -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Availability checks when AutoHotkey is not installed' {
        It 'Should return false and emit warning' {
            if (Get-AutoHotkeyCommand) {
                Set-ItResult -Skipped -Because 'AutoHotkey is installed in this environment'
                return
            }
            $output = Test-AutoHotkeyAvailable 3>&1
            $result = $output | Where-Object { $_ -is [bool] } | Select-Object -Last 1
            $warnings = @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
            $result | Should -Be $false
            $warnings | Should -Not -BeNullOrEmpty
        }

        It 'Start-AutoHotkeyScript should not throw' {
            if (Get-AutoHotkeyCommand) {
                Set-ItResult -Skipped -Because 'AutoHotkey is installed in this environment'
                return
            }
            { Start-AutoHotkeyScript -Path 'missing.ahk' -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }
}

AfterAll {
    Remove-Module poshix -Force -ErrorAction SilentlyContinue
}
