@{
    RootModule = 'poshix.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'c810af0e-2803-46a4-a0e8-8c80beed1b99'
    Author = 'Poshix contributors'
    CompanyName = 'Poshix'
    Copyright = '(c) 2026 Poshix contributors. All rights reserved.'
    Description = 'A Windows-first PowerShell shell framework with POSIX commands, runtime diagnostics, and developer workflow plugins.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport = '*'
    AliasesToExport = '*'
    CmdletsToExport = @()
    VariablesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('powershell', 'shell', 'windows', 'wsl', 'developer-tools')
            LicenseUri = 'https://github.com/punassuming/poshix/blob/main/LICENSE'
            ProjectUri = 'https://github.com/punassuming/poshix'
            IconUri = ''
            ReleaseNotes = 'Initial release foundation with runtime manager support.'
        }
    }
}
