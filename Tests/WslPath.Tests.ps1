Describe 'WSL path conversion' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..' 'plugins' 'wsl' 'wsl.plugin.ps1')
    }

    It 'maps an absolute Windows path to the WSL mount' {
        ConvertTo-PoshixWslPath 'C:\src\app' | Should -Be '/mnt/c/src/app'
    }

    It 'preserves Linux paths' {
        ConvertTo-PoshixWslPath '/home/user/app' | Should -Be '/home/user/app'
    }

    It 'rejects UNC paths' {
        { ConvertTo-PoshixWslPath '\\server\share' } | Should -Throw
    }
}
