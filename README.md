# Poshix
Powershell implementation of common posix commands

If you want to install from a copy of this repo, follow the directions under [module usage](#module-usage)

## Features

### Enhanced Startup and Execution
- Robust error handling during module initialization
- Configuration management system for persistent settings
- Verbose startup logging option
- Automatic history loading on startup
- Graceful cleanup on module removal

## cd

Change directory implementation similar to zsh

### Features
- Remember directory stack, support `cd -` to go to previous directory
- Allow automatic directory globbing, allowing `cd /u/r/d` to automatically traverse to the common file path
- Go to parent directory, smart traversal to parent with matching text using `..`

## ls

### Features
- Wrapped ls similar to posix
- **Configurable colored output based on filetype**
- Human readable file size
- Complete listing with `ls -l`
- Show hidden files `ls -a`
- Sort by Extension `-X`, Time `-t`, or Size `-S`, or no sorting with `-U`
- Disable colors with `--NoColor` option

### ls Colors

Colored output with extensive file type detection:
- **Cyan** for Symlinks
- **Blue** for Directories
- **DarkCyan** for Hidden directories
- **DarkGray** for Hidden files
- **Green** for Executable files (.exe, .bat, .cmd, .ps1, .sh)
- **Red** for Archive files (.zip, .tar, .gz, .7z, etc.)
- **Magenta** for Image files (.jpg, .png, .gif, etc.)
- **Magenta** for Video files (.mp4, .avi, .mkv, etc.)
- **DarkMagenta** for Audio files (.mp3, .wav, .flac, etc.)
- **Yellow** for Document files (.pdf, .doc, .txt, etc.)
- **Green** for other files with extensions
- **White** for files with no extension

**Customize Colors**: Use `Set-PoshixConfig` to customize colors and file type associations.

## History Management

Enhanced command history integration with PowerShell's built-in history:

### Commands
- `histls` or `Get-PoshixHistory` - View command history
- `rinvoke <id>` or `Invoke-PoshixHistory <id>` - Re-run a command from history
- `hgrep <pattern>` or `Search-PoshixHistory <pattern>` - Search history
- `Clear-PoshixHistory` - Clear history
- `Export-PoshixHistory` - Save history to file
- `Import-PoshixHistory` - Load history from file

History is automatically saved on module unload and loaded on startup.

## Prompt Engine

Poshix includes a built-in segment-based prompt engine that displays contextual information in your shell prompt.

### Features

- **Modular segments**: Each piece of information (path, git status, time, etc.) is a separate segment
- **Colored output**: Each segment can have custom colors
- **Git integration**: Automatically shows branch and dirty status when in a git repository
- **Cross-platform**: Works on Windows, Linux, and macOS
- **Configurable**: Customize which segments to show and their appearance
- **Plugin-compatible**: Automatically disabled when using Starship or other prompt plugins

### Default Prompt

The default prompt shows:
- Current directory path (with home directory shortened to `~`)
- Git branch and status (if in a git repository)
- Error indicator (if previous command failed)
- Prompt character (`❯` for normal user, `#` for admin/root)

Example: `~/work/poshix/poshix copilot/implement-segment-based-prompt-engine* ❯`

### Available Segments

- **user**: Current username
- **host**: Computer/hostname
- **path**: Current directory (with home shortening and optional length limit)
- **git**: Git branch and dirty status (`*` when uncommitted changes)
- **time**: Current time
- **error**: Error indicator when previous command failed
- **char**: Prompt character (changes for admin/root)

### Customizing the Prompt

Configure segments via the config system:

```powershell
$promptConfig = @{
    Prompt = @{
        Segments = @(
            @{ Type = 'user'; Enabled = $true; Color = 'Green' }
            @{ Type = 'host'; Enabled = $true; Color = 'Cyan' }
            @{ Type = 'path'; Enabled = $true; Color = 'Blue'; MaxLength = 50 }
            @{ Type = 'git'; Enabled = $true; Color = 'Green'; DirtyColor = 'Yellow' }
            @{ Type = 'time'; Enabled = $true; Color = 'DarkGray'; Format = 'HH:mm:ss' }
            @{ Type = 'error'; Enabled = $true; Color = 'Red'; Character = '✗' }
            @{ Type = 'char'; Enabled = $true; Color = 'Magenta'; AdminColor = 'Red'; Character = '❯'; AdminCharacter = '#' }
        )
        Separator = ' '     # Separator between segments
        Newline = $false    # If true, prompt character appears on a new line
    }
}
Set-PoshixConfig -Config $promptConfig
Save-PoshixConfig
```

### Disabling Segments

To disable a segment, set `Enabled = $false`:

```powershell
$config = Get-PoshixConfig
$config.Prompt.Segments[0].Enabled = $false  # Disable first segment
Set-PoshixConfig -Config $config
```

### Using with Starship

The native prompt engine automatically defers to Starship if the Starship plugin is enabled:

```powershell
Import-PoshixPlugin -Name 'starship'
```

When Starship is active, the native prompt engine remains dormant.

## Additional Linux-like Commands

### find
Search for files similar to Unix find command
```powershell
find -Name "*.ps1"           # Find all .ps1 files
find -Type d                 # Find all directories
find -Extension .txt         # Find all .txt files
```

### grep
Search for text in files (grep-like functionality)
```powershell
grep "function" . -Include "*.ps1" -Recurse
grep "error" . -Recurse -LineNumber
```

### touch
Create a new file or update timestamp
```powershell
touch newfile.txt            # Create new file
touch existingfile.txt       # Update timestamp
```

### which
Find the path of a command
```powershell
which pwsh                   # Find pwsh executable
which ls                     # Find ls command (shows alias)
```

### pwd
Enhanced print working directory
```powershell
poshpwd                      # Show current directory
Get-WorkingDirectory -Physical  # Show physical path (resolve symlinks)
```

**Note:** The standard `pwd` alias is preserved to maintain PowerShell compatibility. Use `poshpwd` for the enhanced version.

### clear
Clear the screen (unified clear/cls)
```powershell
clear                        # Clear screen
```

## Configuration

### Get Current Configuration
```powershell
Get-PoshixConfig
```

### Customize Colors
```powershell
$config = @{
    Colors = @{
        Directory = 'Cyan'
        ExecutableFile = 'Yellow'
    }
}
Set-PoshixConfig -Config $config
Save-PoshixConfig  # Save to disk
```

### Reset Configuration
```powershell
Reset-PoshixConfig
```

## Plugins

Poshix supports a convention-based plugin system inspired by [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) and [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish). Plugins extend poshix functionality without modifying the core module.

### Plugin Convention

Each plugin follows a simple directory structure:

```
plugins/
  <plugin-name>/
    <plugin-name>.plugin.ps1    # Required: Main entry point, dot-sourced on load
    completions/                 # Optional: Tab completion scripts, auto-registered
      *.ps1
    README.md                   # Recommended: Documentation
    plugin.json                 # Optional: Metadata (description, version, dependencies)
```

### Enabling Plugins

Plugins can be loaded in two ways:

1. **Configure in your config** (automatically loaded on startup):
```powershell
$config = @{
    Plugins = @('starship', 'git')
}
Set-PoshixConfig -Config $config
Save-PoshixConfig
```

2. **Load manually in your session**:
```powershell
Import-PoshixPlugin -Name 'starship'
Import-PoshixPlugin -Name 'git','docker'  # Load multiple plugins
```

### Plugin Locations

Poshix searches for plugins in two locations (in order):
1. **Custom plugins**: `~/.poshix/plugins/<plugin-name>/`
2. **Built-in plugins**: `<poshix-root>/plugins/<plugin-name>/`

This allows you to override built-in plugins or create your own.

### Managing Plugins

#### List Plugins
```powershell
Get-PoshixPlugin              # Show loaded plugins (default)
Get-PoshixPlugin -Loaded      # Show only loaded plugins
Get-PoshixPlugin -Available   # Show all available plugins (built-in and custom)
```

#### Unload a Plugin
```powershell
Remove-PoshixPlugin -Name 'starship'
```

**Note**: Unloading only removes the plugin from tracking. Functions and aliases defined by the plugin may remain in the session.

#### Reload a Plugin
```powershell
Import-PoshixPlugin -Name 'starship' -Force
```

### Creating Custom Plugins

1. Create your plugin directory structure:
```powershell
# For personal plugins
mkdir ~/.poshix/plugins/myplugin
New-Item ~/.poshix/plugins/myplugin/myplugin.plugin.ps1
```

2. Add your plugin logic to `myplugin.plugin.ps1`:
```powershell
# myplugin.plugin.ps1
function Get-MyFeature {
    Write-Host "My custom feature!"
}

# Export the function if needed
Export-ModuleMember -Function 'Get-MyFeature'

# Or create an alias
Set-Alias myfeat Get-MyFeature
```

3. Enable your plugin:
```powershell
Import-PoshixPlugin -Name 'myplugin'
```

### Built-in Plugins

#### Completions
Extensive CLI command completion framework for common utilities, inspired by best practices from zsh, fish, and PowerShell ecosystems.

**Supported commands**: git, docker, npm, yarn, kubectl, cargo, pip, dotnet, and poshix commands

```powershell
# Enable in config
$config = @{ Plugins = @('completions') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

# Or load manually
Import-PoshixPlugin -Name 'completions'
```

**Features**:
- Context-aware completions (subcommands, options, and arguments)
- Dynamic completions that query live data (git branches, docker containers, kubectl resources)
- Support for package manager scripts (npm run, yarn scripts from package.json)
- Built-in completions for poshix commands (cd, ls, find, grep, config, plugins)

**Examples**:
```powershell
git co<Tab>          # Suggests: commit, config, checkout
git commit -<Tab>    # Suggests: -m, --message, -a, --all, --amend, etc.
docker run -<Tab>    # Suggests: -d, --detach, -i, --interactive, etc.
kubectl get <Tab>    # Suggests: pods, services, deployments, etc.
npm run <Tab>        # Suggests scripts from package.json
```

See [plugins/completions/README.md](plugins/completions/README.md) for detailed documentation.

#### Starship
Modern cross-shell prompt with extensive customization.

```powershell
# Enable in config
$config = @{ Plugins = @('starship') }
Set-PoshixConfig -Config $config
Save-PoshixConfig
```

Requires [Starship](https://starship.rs) to be installed separately.

### Plugin Auto-Registration Features

When a plugin is loaded, poshix automatically:
- Dot-sources the main plugin file (`<plugin-name>.plugin.ps1`)
- Auto-loads any completion scripts from `completions/*.ps1`
- Tracks the plugin as loaded to prevent duplicate loading

## Module Usage
From the root directory, run:
```powershell
import-module poshix
```

Or for verbose output:
```powershell
import-module poshix -Verbose
```
