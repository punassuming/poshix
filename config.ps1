# Configuration management for poshix module

# Ensure environment variables are set
if (!$env:USERPROFILE) {
    if ($env:HOME) {
        $env:USERPROFILE = $env:HOME
    } else {
        $env:USERPROFILE = "$env:HOMEDRIVE$env:HOMEPATH"
    }
}

function New-PoshixAnsi256Color {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 255)]
        [int]$Code
    )

    return "$([char]27)[38;5;${Code}m"
}

function Get-PoshixDefaultConfig {
    $directoryColor = New-PoshixAnsi256Color -Code 250
    $hiddenColor = New-PoshixAnsi256Color -Code 240
    $executableColor = New-PoshixAnsi256Color -Code 82
    $programmingColor = New-PoshixAnsi256Color -Code 117
    $dataColor = New-PoshixAnsi256Color -Code 215
    $documentColor = New-PoshixAnsi256Color -Code 141
    $mediaColor = New-PoshixAnsi256Color -Code 211
    $archiveColor = New-PoshixAnsi256Color -Code 203
    $systemColor = New-PoshixAnsi256Color -Code 43
    $miscColor = New-PoshixAnsi256Color -Code 226

    return @{
        # Color scheme for ls
        Colors = @{
            Directory = $directoryColor
            HiddenDirectory = $hiddenColor
            Symlink = 'Cyan'
            FileSymlink = 'DarkGreen'
            HiddenFile = $hiddenColor
            ExecutableFile = $executableColor
            ProgrammingFile = $programmingColor
            DataFile = $dataColor
            DocumentFile = $documentColor
            ImageFile = $mediaColor
            VideoFile = $mediaColor
            AudioFile = $mediaColor
            MediaFile = $mediaColor
            ArchiveFile = $archiveColor
            SystemFile = $systemColor
            MiscFile = $miscColor
            File = 'White'
            FileNoExtension = 'White'
        }
        # File type extensions
        FileTypes = @{
            Executable = @('.bat', '.cmd', '.com', '.sh', '.bash', '.zsh')
            Programming = @('.js', '.jsx', '.ts', '.tsx', '.py', '.ipynb', '.java', '.class', '.c', '.cpp', '.h', '.rs', '.go', '.rb', '.ps1', '.html', '.htm', '.css')
            Data = @('.json', '.xml', '.yaml', '.yml', '.parquet', '.csv', '.tsv', '.xls', '.xlsx', '.ods', '.sql', '.sqlite', '.db', '.mdb', '.accdb')
            Document = @('.txt', '.pdf', '.doc', '.docx', '.rtf', '.odt', '.pages', '.md', '.tex', '.epub')
            Image = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tif', '.tiff', '.svg', '.webp', '.heic')
            Audio = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a')
            Video = @('.mp4', '.mov', '.avi', '.mkv', '.webm', '.wmv', '.flv', '.m4v')
            Archive = @('.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz', '.exe', '.msi', '.app', '.dmg', '.deb', '.rpm', '.apk', '.ipa')
            System = @('.ini', '.cfg', '.conf', '.log', '.iso', '.img', '.vhd', '.vmdk', '.ttf', '.otf', '.woff', '.woff2')
            Misc = @('.ppt', '.pptx', '.odp', '.key', '.torrent', '.bak')
        }
        # Exact filename overrides
        FileNames = @{
            Hidden = @('.git', '.gitignore', '.gitattributes', '.env', '.vscode', '.idea', '.ds_store', '.DS_Store', '.config', '.local', '.ssh', '.npmrc', 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', '.editorconfig', '.babelrc', '.eslintrc')
            Document = @('LICENSE', 'README', 'CHANGELOG')
        }
        # History settings
        History = @{
            MaxSize = 4096
            SavePath = (Join-Path $env:USERPROFILE '.poshix_history')
        }
        # Startup options
        Startup = @{
            Verbose = $false
            LoadHistory = $true
        }
        Prompt = @{
            Segments = @(
                @{ Type = 'user'; Enabled = $false; Color = 'Green' }
                @{ Type = 'host'; Enabled = $false; Color = 'Cyan' }
                @{ Type = 'path'; Enabled = $true; Color = 'Blue'; MaxLength = 50 }
                @{ Type = 'git'; Enabled = $true; Color = 'Green'; DirtyColor = 'Yellow' }
                @{ Type = 'error'; Enabled = $true; Color = 'Red'; Character = '✗' }
                @{ Type = 'time'; Enabled = $false; Color = 'DarkGray'; Format = 'HH:mm:ss' }
                @{ Type = 'char'; Enabled = $true; Color = 'Magenta'; AdminColor = 'Red'; Character = '❯'; AdminCharacter = '#' }
            )
            Separator = ' '
            Newline = $false
        }
        # Plugin settings
        Plugins = @()  # List of enabled plugin names, e.g. @('starship')
        Theme = $null  # Active theme name (null = no theme / use plugin prompt)
    }
}

# Default configuration
$script:PoshixConfig = Get-PoshixDefaultConfig

# Configuration file paths (canonical + legacy fallback)
$script:ConfigPath = Join-Path $env:USERPROFILE '.poshixrc.json'
$script:LegacyConfigPath = Join-Path $env:USERPROFILE '.poshix_config.json'

function Get-PoshixConfig {
    <#
    .SYNOPSIS
    Get the current poshix configuration
    #>
    return $script:PoshixConfig
}

function Set-PoshixConfig {
    <#
    .SYNOPSIS
    Update poshix configuration
    .PARAMETER Config
    Configuration hashtable to merge with current config
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    # Merge configuration (deep merge for nested hashtables)
    foreach ($key in $Config.Keys) {
        if ($script:PoshixConfig.ContainsKey($key) -and $script:PoshixConfig[$key] -is [hashtable] -and $Config[$key] -is [hashtable]) {
            foreach ($subKey in $Config[$key].Keys) {
                $script:PoshixConfig[$key][$subKey] = $Config[$key][$subKey]
            }
        } else {
            $script:PoshixConfig[$key] = $Config[$key]
        }
    }
}

function Save-PoshixConfig {
    <#
    .SYNOPSIS
    Save current configuration to disk
    #>
    try {
        $script:PoshixConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:ConfigPath -Encoding UTF8
        Write-Verbose "Configuration saved to $script:ConfigPath"
    } catch {
        Write-Warning "Failed to save configuration: $_"
    }
}

function Import-PoshixConfig {
    <#
    .SYNOPSIS
    Load configuration from disk
    #>
    $loadPath = $null
    if (Test-Path $script:ConfigPath) {
        $loadPath = $script:ConfigPath
    } elseif (Test-Path $script:LegacyConfigPath) {
        $loadPath = $script:LegacyConfigPath
        Write-Verbose "Using legacy config path: $script:LegacyConfigPath"
    }

    if ($loadPath) {
        try {
            $loaded = Get-Content -Path $loadPath -Raw | ConvertFrom-Json
            # Convert PSCustomObject to hashtable recursively
            $config = ConvertTo-Hashtable $loaded
            Set-PoshixConfig -Config $config
            Write-Verbose "Configuration loaded from $loadPath"
        } catch {
            Write-Warning "Failed to load configuration: $_"
        }
    }
}

function ConvertTo-Hashtable {
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    
    if ($null -eq $InputObject) { return $null }
    
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $collection = @()
        foreach ($item in $InputObject) {
            $collection += ConvertTo-Hashtable $item
        }
        return ,$collection
    } elseif ($InputObject -is [PSCustomObject]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = ConvertTo-Hashtable $property.Value
        }
        return $hash
    } else {
        return $InputObject
    }
}

function Reset-PoshixConfig {
    <#
    .SYNOPSIS
    Reset configuration to defaults
    #>
    $script:PoshixConfig = Get-PoshixDefaultConfig
    Write-Verbose "Configuration reset to defaults"
}
