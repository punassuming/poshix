# Additional Linux-like commands for poshix

function Find-Files {
    <#
    .SYNOPSIS
    Find files similar to Unix find command
    .DESCRIPTION
    Search for files matching criteria
    .PARAMETER Path
    Path to search in
    .PARAMETER Name
    File name pattern to match
    .PARAMETER Type
    Type of item to find (f=file, d=directory)
    .PARAMETER Extension
    File extension to match
    .EXAMPLE
    Find-Files -Path . -Name "*.ps1"
    .EXAMPLE
    Find-Files -Path . -Type d
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Path = ".",
        [Parameter()]
        [string]$Name,
        [Parameter()]
        [ValidateSet('f', 'd', 'file', 'directory')]
        [string]$Type,
        [Parameter()]
        [string]$Extension
    )
    
    $items = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    
    if ($Name) {
        $items = $items | Where-Object { $_.Name -like $Name }
    }
    
    if ($Extension) {
        $items = $items | Where-Object { $_.Extension -eq $Extension }
    }
    
    if ($Type) {
        switch ($Type) {
            'f' { $items = $items | Where-Object { -not $_.PSIsContainer } }
            'file' { $items = $items | Where-Object { -not $_.PSIsContainer } }
            'd' { $items = $items | Where-Object { $_.PSIsContainer } }
            'directory' { $items = $items | Where-Object { $_.PSIsContainer } }
        }
    }
    
    return $items
}

function Find-InFiles {
    <#
    .SYNOPSIS
    Search for text in files (grep-like functionality)
    .DESCRIPTION
    Search for patterns in file contents
    .PARAMETER Pattern
    Pattern to search for
    .PARAMETER Path
    Path to search in
    .PARAMETER Include
    File pattern to include
    .PARAMETER Recurse
    Search recursively
    .PARAMETER CaseSensitive
    Use case-sensitive matching
    .EXAMPLE
    Find-InFiles -Pattern "function" -Path . -Include "*.ps1" -Recurse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Pattern,
        [Parameter(Position=1)]
        [string]$Path = ".",
        [Parameter()]
        [string]$Include = "*",
        [Parameter()]
        [switch]$Recurse,
        [Parameter()]
        [switch]$CaseSensitive,
        [Parameter()]
        [switch]$LineNumber
    )
    
    $searchParams = @{
        Path = $Path
        Pattern = $Pattern
        Include = $Include
    }
    
    if ($Recurse) {
        $searchParams['Recurse'] = $true
    }
    
    if ($CaseSensitive) {
        $searchParams['CaseSensitive'] = $true
    }
    
    Select-String @searchParams | ForEach-Object {
        if ($LineNumber) {
            Write-Host "$($_.Path):$($_.LineNumber):" -NoNewline -ForegroundColor Cyan
            Write-Host " $($_.Line)"
        } else {
            Write-Host "$($_.Path): " -NoNewline -ForegroundColor Cyan
            Write-Host "$($_.Line)"
        }
    }
}

function New-File {
    <#
    .SYNOPSIS
    Create a new file or update timestamp (like Unix touch)
    .DESCRIPTION
    Create empty file or update timestamp of existing file
    .PARAMETER Path
    Path to the file
    .EXAMPLE
    New-File test.txt
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string[]]$Path
    )
    
    foreach ($file in $Path) {
        if (Test-Path $file) {
            (Get-Item $file).LastWriteTime = Get-Date
            Write-Verbose "Updated timestamp for $file"
        } else {
            New-Item -Path $file -ItemType File | Out-Null
            Write-Verbose "Created $file"
        }
    }
}

function Get-CommandPath {
    <#
    .SYNOPSIS
    Find the path of a command (like Unix which)
    .DESCRIPTION
    Locate the executable path of a command
    .PARAMETER Name
    Command name to find
    .EXAMPLE
    Get-CommandPath pwsh
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )
    
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        switch ($cmd.CommandType) {
            'Application' { 
                Write-Host $cmd.Source -ForegroundColor Green
            }
            'Cmdlet' {
                Write-Host "$($cmd.ModuleName)\$($cmd.Name)" -ForegroundColor Yellow
            }
            'Function' {
                Write-Host "Function: $($cmd.Name)" -ForegroundColor Cyan
            }
            'Alias' {
                Write-Host "Alias: $($cmd.Name) -> $($cmd.Definition)" -ForegroundColor Magenta
            }
            default {
                Write-Host "$($cmd.CommandType): $($cmd.Name)" -ForegroundColor White
            }
        }
    } else {
        Write-Host "$Name not found" -ForegroundColor Red
        return $null
    }
}

function Get-WorkingDirectory {
    <#
    .SYNOPSIS
    Print working directory (enhanced pwd)
    .DESCRIPTION
    Display current directory with optional formatting
    .PARAMETER Logical
    Display logical path
    .PARAMETER Physical
    Display physical path (resolve symlinks)
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Logical,
        [Parameter()]
        [switch]$Physical
    )
    
    if ($Physical) {
        # Resolve any symlinks
        $path = (Get-Item -Path (Get-Location)).FullName
        Write-Host $path -ForegroundColor Green
    } else {
        Write-Host (Get-Location).Path -ForegroundColor Green
    }
}

function Clear-Screen {
    <#
    .SYNOPSIS
    Clear the screen (unified clear/cls)
    #>
    [CmdletBinding()]
    param()
    
    Clear-Host
}

# Set up aliases for Linux-like commands
Set-Alias -Name find -Value Find-Files
Set-Alias -Name grep -Value Find-InFiles
Set-Alias -Name touch -Value New-File
Set-Alias -Name which -Value Get-CommandPath
# Note: pwd is a built-in PowerShell alias, using poshpwd to avoid conflicts
Set-Alias -Name poshpwd -Value Get-WorkingDirectory
Set-Alias -Name clear -Value Clear-Screen
