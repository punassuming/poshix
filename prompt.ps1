# Poshix Segment-Based Prompt Engine
# Provides a modular, customizable prompt system

# Segment functions - each returns a hashtable with text and color
function Get-PromptUserSegment {
    param([hashtable]$Config)
    
    $userName = [System.Environment]::UserName
    $color = if ($Config.Color) { $Config.Color } else { 'Green' }
    
    return @{
        Text = $userName
        Color = $color
    }
}

function Get-PromptHostSegment {
    param([hashtable]$Config)
    
    $hostName = [System.Environment]::MachineName
    $color = if ($Config.Color) { $Config.Color } else { 'Cyan' }
    
    return @{
        Text = $hostName
        Color = $color
    }
}

function Get-PromptPathSegment {
    param([hashtable]$Config)
    
    $path = Get-Location
    $displayPath = $path.Path
    
    # Shorten home directory to ~ (case-insensitive for Windows compatibility)
    if ($displayPath.StartsWith($env:HOME, [StringComparison]::OrdinalIgnoreCase)) {
        $displayPath = "~" + $displayPath.Substring($env:HOME.Length)
    }
    
    # Optionally shorten long paths
    if ($Config.MaxLength -and $displayPath.Length -gt $Config.MaxLength) {
        $parts = $displayPath.Split([IO.Path]::DirectorySeparatorChar)
        if ($parts.Count -gt 3) {
            # Preserve ~ at the beginning if present
            if ($parts[0] -eq '~') {
                $displayPath = '~' + [IO.Path]::DirectorySeparatorChar + '...' + [IO.Path]::DirectorySeparatorChar + $parts[-1]
            } else {
                $displayPath = $parts[0] + [IO.Path]::DirectorySeparatorChar + '...' + [IO.Path]::DirectorySeparatorChar + $parts[-1]
            }
        }
    }
    
    $color = if ($Config.Color) { $Config.Color } else { 'Blue' }
    
    return @{
        Text = $displayPath
        Color = $color
    }
}

function Get-PromptGitSegment {
    param([hashtable]$Config)
    
    # Check if we're in a git repository
    $gitStatus = $null
    try {
        $gitStatus = git rev-parse --is-inside-work-tree 2>$null
    } catch {
        return $null
    }
    
    if (-not $gitStatus) {
        return $null
    }
    
    # Get current branch
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) {
        return $null
    }
    
    # Get status
    $isDirty = $false
    $statusOutput = git status --porcelain 2>$null
    if ($statusOutput) {
        $isDirty = $true
    }
    
    $color = if ($isDirty) { 
        if ($Config.DirtyColor) { $Config.DirtyColor } else { 'Yellow' }
    } else { 
        if ($Config.Color) { $Config.Color } else { 'Green' }
    }
    
    $statusChar = if ($isDirty) { '*' } else { '' }
    
    return @{
        Text = "$branch$statusChar"
        Color = $color
    }
}

function Get-PromptTimeSegment {
    param([hashtable]$Config)
    
    $format = if ($Config.Format) { $Config.Format } else { 'HH:mm:ss' }
    $time = Get-Date -Format $format
    $color = if ($Config.Color) { $Config.Color } else { 'DarkGray' }
    
    return @{
        Text = $time
        Color = $color
    }
}

function Get-PromptErrorSegment {
    param([hashtable]$Config)
    
    if ($global:?) {
        return $null
    }
    
    $color = if ($Config.Color) { $Config.Color } else { 'Red' }
    $char = if ($Config.Character) { $Config.Character } else { '✗' }
    
    return @{
        Text = $char
        Color = $color
    }
}

function Get-PromptCharSegment {
    param([hashtable]$Config)
    
    # Cross-platform admin/root check
    $isAdmin = $false
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        try {
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } catch {
            # On non-Windows platforms or if the check fails
            $isAdmin = $false
        }
    } else {
        # On Linux/Mac, check if user ID is 0 (root)
        $isAdmin = (id -u) -eq 0
    }
    
    $char = if ($isAdmin) {
        if ($Config.AdminCharacter) { $Config.AdminCharacter } else { '#' }
    } else {
        if ($Config.Character) { $Config.Character } else { '❯' }
    }
    
    $color = if ($isAdmin) {
        if ($Config.AdminColor) { $Config.AdminColor } else { 'Red' }
    } else {
        if ($Config.Color) { $Config.Color } else { 'Magenta' }
    }
    
    return @{
        Text = $char
        Color = $color
    }
}

# Main prompt function
function Get-PoshixPrompt {
    # Don't override if Starship or another prompt is active
    if ($env:POSHIX_PROMPT -and $env:POSHIX_PROMPT -ne 'poshix') {
        return
    }
    
    $config = Get-PoshixConfig
    $promptConfig = if ($config.Prompt) { $config.Prompt } else { @{} }
    
    # Default segment configuration
    $defaultSegments = @(
        @{ Type = 'user'; Enabled = $false }
        @{ Type = 'host'; Enabled = $false }
        @{ Type = 'path'; Enabled = $true; MaxLength = 50 }
        @{ Type = 'git'; Enabled = $true }
        @{ Type = 'error'; Enabled = $true }
        @{ Type = 'time'; Enabled = $false }
        @{ Type = 'char'; Enabled = $true }
    )
    
    # Merge with user configuration
    $segments = if ($promptConfig.Segments) { $promptConfig.Segments } else { $defaultSegments }
    
    # Build prompt string
    $promptText = ""
    $isFirstSegment = $true
    
    foreach ($segmentConfig in $segments) {
        if (-not $segmentConfig.Enabled) {
            continue
        }
        
        $segment = $null
        switch ($segmentConfig.Type) {
            'user' { $segment = Get-PromptUserSegment -Config $segmentConfig }
            'host' { $segment = Get-PromptHostSegment -Config $segmentConfig }
            'path' { $segment = Get-PromptPathSegment -Config $segmentConfig }
            'git'  { $segment = Get-PromptGitSegment -Config $segmentConfig }
            'time' { $segment = Get-PromptTimeSegment -Config $segmentConfig }
            'error' { $segment = Get-PromptErrorSegment -Config $segmentConfig }
            'char' { $segment = Get-PromptCharSegment -Config $segmentConfig }
        }
        
        if (-not $segment) {
            continue
        }
        
        # Add separator between segments (except for char segment)
        if (-not $isFirstSegment -and $segmentConfig.Type -ne 'char') {
            $separator = if ($promptConfig.Separator) { $promptConfig.Separator } else { ' ' }
            $promptText += $separator
        }
        
        # Format segment with color
        $esc = [char]27
        $colorCode = switch ($segment.Color) {
            'Black'       { '30' }
            'DarkRed'     { '31' }
            'DarkGreen'   { '32' }
            'DarkYellow'  { '33' }
            'DarkBlue'    { '34' }
            'DarkMagenta' { '35' }
            'DarkCyan'    { '36' }
            'Gray'        { '37' }
            'DarkGray'    { '90' }
            'Red'         { '91' }
            'Green'       { '92' }
            'Yellow'      { '93' }
            'Blue'        { '94' }
            'Magenta'     { '95' }
            'Cyan'        { '96' }
            'White'       { '97' }
            default       { '97' }
        }
        
        # Add newline before char segment if configured
        if ($segmentConfig.Type -eq 'char') {
            if ($promptConfig.Newline) {
                $promptText += "`n"
            } else {
                $promptText += " "
            }
        }
        
        $promptText += "$esc[${colorCode}m$($segment.Text)$esc[0m"
        $isFirstSegment = $false
    }
    
    # Add trailing space after char
    $promptText += " "
    
    return $promptText
}

# PowerShell prompt function
function global:prompt {
    Get-PoshixPrompt
}

# Initialize prompt
function Initialize-PoshixPrompt {
    # Only initialize if no other prompt system is active
    if (-not $env:POSHIX_PROMPT) {
        $env:POSHIX_PROMPT = 'poshix'
        Write-Verbose "[poshix] Native prompt engine activated"
    }
}
