# session-layouts plugin for poshix
# Save and restore working directory and shell session layouts

$script:LayoutsDir = Join-Path $HOME '.poshix' 'layouts'

function Initialize-SessionLayoutsDir {
    if (-not (Test-Path $script:LayoutsDir)) {
        New-Item -ItemType Directory -Path $script:LayoutsDir -Force | Out-Null
        Write-Verbose "[poshix] session-layouts: created layouts directory at '$script:LayoutsDir'"
    }
}

function Get-SessionLayoutPath {
    param([string]$Name)
    Join-Path $script:LayoutsDir "$Name.json"
}

function Read-SessionLayout {
    param([string]$Name)
    $path = Get-SessionLayoutPath $Name
    if (-not (Test-Path $path)) {
        Write-Warning "[poshix] session-layouts: layout '$Name' not found at '$path'"
        return $null
    }
    Get-Content -Raw -Path $path | ConvertFrom-Json
}

function Save-SessionLayout {
    <#
    .SYNOPSIS
    Save the current session state as a named layout.
    .DESCRIPTION
    Saves the current working directory (and optionally environment variables)
    to ~/.poshix/layouts/<Name>.json.
    .PARAMETER Name
    The name of the layout to save.
    .PARAMETER Description
    An optional description for this layout.
    .PARAMETER IncludeEnv
    When specified, captures non-system environment variables into the layout.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [string]$Description = '',

        [Parameter()]
        [switch]$IncludeEnv
    )

    Initialize-SessionLayoutsDir

    Write-Verbose "[poshix] session-layouts: saving layout '$Name'"

    $envVars = @{}
    if ($IncludeEnv) {
        $systemPrefixes = @('PATH', 'PATHEXT', 'WINDIR', 'SYSTEMROOT', 'SYSTEMDRIVE',
                            'COMSPEC', 'TEMP', 'TMP', 'USERPROFILE', 'HOMEDRIVE',
                            'HOMEPATH', 'APPDATA', 'LOCALAPPDATA', 'PROGRAMFILES',
                            'PROGRAMFILES(X86)', 'COMMONPROGRAMFILES', 'PROGRAMDATA',
                            'ALLUSERSPROFILE', 'PUBLIC', 'COMPUTERNAME', 'USERNAME',
                            'USERDOMAIN', 'PROCESSOR_ARCHITECTURE', 'NUMBER_OF_PROCESSORS',
                            'OS', 'PSMODULEPATH')
        Get-ChildItem Env: | Where-Object {
            $name = $_.Name.ToUpper()
            -not ($systemPrefixes | Where-Object { $name -eq $_.ToUpper() })
        } | ForEach-Object {
            $envVars[$_.Name] = $_.Value
        }
        Write-Verbose "[poshix] session-layouts: captured $($envVars.Count) environment variable(s)"
    }

    $path = Get-SessionLayoutPath $Name
    $existing = if (Test-Path $path) { Get-Content -Raw -Path $path | ConvertFrom-Json } else { $null }
    $createdAt = if ($existing) { $existing.CreatedAt } else { (Get-Date -Format 'o') }

    $layout = [ordered]@{
        Name            = $Name
        Description     = $Description
        Directory       = (Get-Location).Path
        EnvironmentVars = $envVars
        Bookmarks       = if ($existing -and $existing.Bookmarks) { $existing.Bookmarks } else { @() }
        CreatedAt       = $createdAt
        UpdatedAt       = (Get-Date -Format 'o')
    }

    $layout | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding UTF8
    Write-Host "Layout '$Name' saved (directory: $($layout.Directory))" -ForegroundColor Green
}

function Restore-SessionLayout {
    <#
    .SYNOPSIS
    Restore a previously saved session layout.
    .DESCRIPTION
    Changes the current directory to the one stored in the layout and,
    if the layout includes environment variables, restores them.
    .PARAMETER Name
    The name of the layout to restore.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    Write-Verbose "[poshix] session-layouts: restoring layout '$Name'"

    $layout = Read-SessionLayout $Name
    if (-not $layout) { return }

    if (Test-Path $layout.Directory) {
        Set-Location $layout.Directory
        Write-Host "Restored directory: $($layout.Directory)" -ForegroundColor Cyan
    } else {
        Write-Warning "[poshix] session-layouts: saved directory '$($layout.Directory)' no longer exists"
    }

    $envVars = $layout.EnvironmentVars
    if ($envVars) {
        $props = $envVars | Get-Member -MemberType NoteProperty -ErrorAction SilentlyContinue
        if ($props) {
            $props | ForEach-Object {
                $varName  = $_.Name
                $varValue = $envVars.$varName
                Set-Item -Path "env:$varName" -Value $varValue
            }
            Write-Host "Restored $($props.Count) environment variable(s)" -ForegroundColor Cyan
        }
    }
}

function Get-SessionLayouts {
    <#
    .SYNOPSIS
    List all saved session layouts.
    .DESCRIPTION
    Displays a table of all layouts stored in ~/.poshix/layouts/ with their
    name, directory, description, and creation timestamp.
    #>
    [CmdletBinding()]
    param()

    Initialize-SessionLayoutsDir

    Write-Verbose "[poshix] session-layouts: listing layouts in '$script:LayoutsDir'"

    $files = Get-ChildItem -Path $script:LayoutsDir -Filter '*.json' -ErrorAction SilentlyContinue
    if (-not $files) {
        Write-Host "No layouts found. Use 'layout-save <name>' to create one." -ForegroundColor Yellow
        return
    }

    $files | ForEach-Object {
        $layout = Get-Content -Raw -Path $_.FullName | ConvertFrom-Json
        [PSCustomObject]@{
            Name        = $layout.Name
            Directory   = $layout.Directory
            Description = $layout.Description
            CreatedAt   = $layout.CreatedAt
        }
    } | Format-Table -AutoSize
}

function Remove-SessionLayout {
    <#
    .SYNOPSIS
    Remove a saved session layout.
    .DESCRIPTION
    Deletes the layout file for the given name. Prompts for confirmation
    unless -Force is supplied.
    .PARAMETER Name
    The name of the layout to remove.
    .PARAMETER Force
    Skip the confirmation prompt.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter()]
        [switch]$Force
    )

    $path = Get-SessionLayoutPath $Name
    if (-not (Test-Path $path)) {
        Write-Warning "[poshix] session-layouts: layout '$Name' not found"
        return
    }

    if ($Force -or $PSCmdlet.ShouldProcess($Name, 'Remove layout')) {
        Remove-Item -Path $path -Force
        Write-Host "Layout '$Name' removed." -ForegroundColor Green
        Write-Verbose "[poshix] session-layouts: removed layout '$Name'"
    }
}

function Add-LayoutBookmark {
    <#
    .SYNOPSIS
    Add a named directory bookmark to an existing layout.
    .DESCRIPTION
    Appends a {Name, Path} bookmark to the specified layout file.
    If a bookmark with the same name already exists it is replaced.
    .PARAMETER Layout
    The layout to add the bookmark to.
    .PARAMETER BookmarkName
    The short name for the bookmark.
    .PARAMETER Path
    The directory path to bookmark. Defaults to the current directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Layout,

        [Parameter(Mandatory, Position = 1)]
        [string]$BookmarkName,

        [Parameter()]
        [string]$Path = (Get-Location).Path
    )

    Write-Verbose "[poshix] session-layouts: adding bookmark '$BookmarkName' to layout '$Layout'"

    $layoutPath = Get-SessionLayoutPath $Layout
    if (-not (Test-Path $layoutPath)) {
        Write-Warning "[poshix] session-layouts: layout '$Layout' not found"
        return
    }

    $layoutData = Get-Content -Raw -Path $layoutPath | ConvertFrom-Json

    # Convert existing bookmarks to a mutable list
    $bookmarks = [System.Collections.Generic.List[PSCustomObject]]::new()
    if ($layoutData.Bookmarks) {
        foreach ($bm in $layoutData.Bookmarks) {
            if ($bm.Name -ne $BookmarkName) {
                $bookmarks.Add($bm)
            }
        }
    }
    $bookmarks.Add([PSCustomObject]@{ Name = $BookmarkName; Path = $Path })

    $updated = [ordered]@{
        Name            = $layoutData.Name
        Description     = $layoutData.Description
        Directory       = $layoutData.Directory
        EnvironmentVars = $layoutData.EnvironmentVars
        Bookmarks       = $bookmarks
        CreatedAt       = $layoutData.CreatedAt
        UpdatedAt       = (Get-Date -Format 'o')
    }

    $updated | ConvertTo-Json -Depth 5 | Set-Content -Path $layoutPath -Encoding UTF8
    Write-Host "Bookmark '$BookmarkName' -> '$Path' added to layout '$Layout'" -ForegroundColor Green
}

function Invoke-LayoutBookmark {
    <#
    .SYNOPSIS
    Navigate to a bookmarked directory in a layout.
    .DESCRIPTION
    Looks up the named bookmark in the specified layout and changes the
    current directory to its saved path.
    .PARAMETER Layout
    The layout containing the bookmark.
    .PARAMETER BookmarkName
    The name of the bookmark to navigate to.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Layout,

        [Parameter(Mandatory, Position = 1)]
        [string]$BookmarkName
    )

    Write-Verbose "[poshix] session-layouts: navigating to bookmark '$BookmarkName' in layout '$Layout'"

    $layoutData = Read-SessionLayout $Layout
    if (-not $layoutData) { return }

    if (-not $layoutData.Bookmarks) {
        Write-Warning "[poshix] session-layouts: layout '$Layout' has no bookmarks"
        return
    }

    $bookmark = $layoutData.Bookmarks | Where-Object { $_.Name -eq $BookmarkName } | Select-Object -First 1
    if (-not $bookmark) {
        Write-Warning "[poshix] session-layouts: bookmark '$BookmarkName' not found in layout '$Layout'"
        return
    }

    if (Test-Path $bookmark.Path) {
        Set-Location $bookmark.Path
        Write-Host "Navigated to '$($bookmark.Path)'" -ForegroundColor Cyan
    } else {
        Write-Warning "[poshix] session-layouts: bookmarked path '$($bookmark.Path)' no longer exists"
    }
}

# Export internal helper functions to global scope (required for globally-exported
# public functions to resolve them at call time in the poshix plugin architecture)
Set-Item -Path "function:global:Initialize-SessionLayoutsDir" -Value ${function:Initialize-SessionLayoutsDir}
Set-Item -Path "function:global:Get-SessionLayoutPath"        -Value ${function:Get-SessionLayoutPath}
Set-Item -Path "function:global:Read-SessionLayout"           -Value ${function:Read-SessionLayout}

# Export public functions to global scope
Set-Item -Path "function:global:Save-SessionLayout"    -Value ${function:Save-SessionLayout}
Set-Item -Path "function:global:Restore-SessionLayout" -Value ${function:Restore-SessionLayout}
Set-Item -Path "function:global:Get-SessionLayouts"    -Value ${function:Get-SessionLayouts}
Set-Item -Path "function:global:Remove-SessionLayout"  -Value ${function:Remove-SessionLayout}
Set-Item -Path "function:global:Add-LayoutBookmark"    -Value ${function:Add-LayoutBookmark}
Set-Item -Path "function:global:Invoke-LayoutBookmark" -Value ${function:Invoke-LayoutBookmark}

# Export aliases to global scope
Set-Alias -Name layout-save    -Value Save-SessionLayout    -Scope Global
Set-Alias -Name layout-restore -Value Restore-SessionLayout -Scope Global
Set-Alias -Name layouts        -Value Get-SessionLayouts    -Scope Global
Set-Alias -Name layout-rm      -Value Remove-SessionLayout  -Scope Global
Set-Alias -Name bookmark       -Value Add-LayoutBookmark    -Scope Global
Set-Alias -Name bm             -Value Invoke-LayoutBookmark -Scope Global

Write-Verbose "[poshix] session-layouts plugin loaded"
