# Configuration management for poshix module

# Ensure environment variables are set
if (!$env:USERPROFILE) { 
    if ($env:HOME) {
        $env:USERPROFILE = $env:HOME
    } else {
        $env:USERPROFILE = "$env:HOMEDRIVE$env:HOMEPATH"
    }
}

# Default configuration
$script:PoshixConfig = @{
    # Color scheme for ls
    Colors = @{
        Directory = 'Blue'
        HiddenDirectory = 'DarkCyan'
        Symlink = 'Cyan'
        FileSymlink = 'DarkGreen'
        HiddenFile = 'DarkGray'
        ExecutableFile = 'Green'
        ArchiveFile = 'Red'
        ImageFile = 'Magenta'
        VideoFile = 'Magenta'
        AudioFile = 'DarkMagenta'
        DocumentFile = 'Yellow'
        File = 'Green'
        FileNoExtension = 'White'
    }
    # File type extensions
    FileTypes = @{
        Executable = @('.exe', '.bat', '.cmd', '.ps1', '.sh', '.bash', '.zsh')
        Archive = @('.zip', '.tar', '.gz', '.bz2', '.7z', '.rar', '.tgz', '.xz')
        Image = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.ico', '.webp')
        Video = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm')
        Audio = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a')
        Document = @('.pdf', '.doc', '.docx', '.txt', '.md', '.rtf', '.odt')
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
}

# Configuration file path
$script:ConfigPath = Join-Path $env:USERPROFILE '.poshix_config.json'

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
    if (Test-Path $script:ConfigPath) {
        try {
            $loaded = Get-Content -Path $script:ConfigPath -Raw | ConvertFrom-Json
            # Convert PSCustomObject to hashtable recursively
            $config = ConvertTo-Hashtable $loaded
            Set-PoshixConfig -Config $config
            Write-Verbose "Configuration loaded from $script:ConfigPath"
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
    # Recreate default config
    $script:PoshixConfig = @{
        Colors = @{
            Directory = 'Blue'
            HiddenDirectory = 'DarkCyan'
            Symlink = 'Cyan'
            FileSymlink = 'DarkGreen'
            HiddenFile = 'DarkGray'
            ExecutableFile = 'Green'
            ArchiveFile = 'Red'
            ImageFile = 'Magenta'
            VideoFile = 'Magenta'
            AudioFile = 'DarkMagenta'
            DocumentFile = 'Yellow'
            File = 'Green'
            FileNoExtension = 'White'
        }
        FileTypes = @{
            Executable = @('.exe', '.bat', '.cmd', '.ps1', '.sh', '.bash', '.zsh')
            Archive = @('.zip', '.tar', '.gz', '.bz2', '.7z', '.rar', '.tgz', '.xz')
            Image = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.ico', '.webp')
            Video = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm')
            Audio = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a')
            Document = @('.pdf', '.doc', '.docx', '.txt', '.md', '.rtf', '.odt')
        }
        History = @{
            MaxSize = 4096
            SavePath = (Join-Path $env:USERPROFILE '.poshix_history')
        }
        Startup = @{
            Verbose = $false
            LoadHistory = $true
        }
    }
    Write-Verbose "Configuration reset to defaults"
}
