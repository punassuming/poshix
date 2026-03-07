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
- **256-color light gray** for directories
- **256-color muted gray** for hidden files and hidden directories
- **256-color green** for executable files without a more specific file type mapping
- **256-color sky blue** for programming and web files (`.js`, `.ts`, `.py`, `.ps1`, `.html`, `.css`, etc.)
- **256-color soft orange** for data and database files (`.json`, `.yaml`, `.csv`, `.sql`, `.db`, etc.)
- **256-color muted purple** for documents and text files (`.pdf`, `.docx`, `.md`, `README`, `LICENSE`, etc.)
- **256-color soft pink** for image, audio, and video files
- **256-color muted red** for archives and installers (`.zip`, `.tar`, `.7z`, `.msi`, `.exe`, etc.)
- **256-color teal** for system, disk, config, and font files
- **256-color yellow** for presentations, torrents, and backups
- **White** for other files with extensions
- **White** for files with no extension

Exact filename overrides are also supported through `FileNames`, so dotfiles like `.gitignore` and extensionless docs like `README` can have dedicated colors without changing global extension rules.

**Customize Colors**: Use `Set-PoshixConfig` to customize colors, exact filename overrides, and file type associations. `ls` accepts either standard PowerShell color names or ANSI escape sequences such as `"\u001b[38;5;117m"`.

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
- **Docker integration**: Optional prompt segment for Compose-aware container status
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
- **docker**: Docker or Docker Compose status from the `docker` plugin
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
            @{ Type = 'docker'; Enabled = $true; Color = 'DarkCyan'; ActiveColor = 'Cyan'; ShowContext = $true; ShowProject = $true; MaxItems = 2; CacheSeconds = 3 }
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

Poshix loads configuration from:

`~/.poshixrc.json`

Backward compatibility: if `~/.poshixrc.json` does not exist, poshix will read `~/.poshix_config.json`.

This repository includes an up-to-date template:

`./.poshixrc.json`

The default in-memory config starts with `Plugins = @()`, so poshix does not auto-enable plugins unless you opt in. The `./.poshixrc.json` file in the repository root is a reference starter profile that demonstrates enabling multiple built-in plugins and prompt settings.

Docker backend selection is configured under `Docker`:

```powershell
$config = @{
    Docker = @{
        Mode = 'Wsl'          # Auto, Native, or Wsl
        Distribution = 'Ubuntu'
        Prompt = @{
            ShowContext = $true
            ShowProject = $true
            MaxItems = 2
            CacheSeconds = 3
        }
    }
}
Set-PoshixConfig -Config $config
Save-PoshixConfig
```

You can copy the root template to your user config path and then customize:

```powershell
Copy-Item .\.poshixrc.json "$HOME\.poshixrc.json" -Force
```

### Get Current Configuration
```powershell
Get-PoshixConfig
```

### Customize Colors
```powershell
$config = @{
    Colors = @{
        Directory = "$([char]27)[38;5;250m"
        ProgrammingFile = "$([char]27)[38;5;117m"
    }
    FileNames = @{
        Document = @('README', 'LICENSE')
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
    plugin.json                 # Optional: Metadata for discovery (description, commands, dependencies)
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
Get-PoshixPlugin -Available -Detailed
Get-PoshixPluginCatalog | Format-Table Name, Description, Commands
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

### Plugin Discovery

Poshix now includes lightweight plugin metadata manifests inspired by the catalog-style discovery found in frameworks like Oh My Zsh and Oh My Fish. Use them to quickly inspect what each built-in plugin adds before you enable it:

```powershell
# Quick catalog view
Get-PoshixPlugin -Available -Detailed

# Structured metadata for scripting / custom formatting
Get-PoshixPluginCatalog |
    Sort-Object Name |
    Format-Table Name, Description, Commands, Requires
```

The built-in `plugin.json` manifests surface:

- A short plugin description
- Common commands or aliases exposed by the plugin
- External dependencies or prerequisites when applicable

## Themes Plugin

The Themes plugin provides comprehensive theming capabilities with full RGB color support (color3d) and Windows Terminal integration.

### Features

- **RGB Color Support**: Define themes with full hex color values (#RRGGBB) for true color support
- **Windows Terminal Integration**: Optional integration through the `windows-terminal` plugin
- **Built-in Themes**: Professional themes included (Dracula, Monokai, Nord, Solarized, One Dark)
- **Custom Themes**: Create your own themes easily
- **Automatic Color Mapping**: Intelligent color application to Poshix tools

### Enabling the Themes Plugin

```powershell
$config = @{
    Plugins = @('themes')
}
Set-PoshixConfig -Config $config
Save-PoshixConfig
```

Then reload your PowerShell session or run `Import-Module poshix -Force`.

### Using Themes

```powershell
# List available themes
Get-PoshixThemes

# View a theme's definition
Get-PoshixTheme -Name dracula

# Apply a theme (Poshix only)
Set-PoshixTheme -Name nord

# Apply a theme to both Poshix and Windows Terminal
Set-PoshixTheme -Name dracula -ApplyToTerminal
```

### Built-in Themes

- **dracula** - Popular dark theme with purple accents
- **monokai** - Classic dark theme from Sublime Text  
- **nord** - Arctic, north-bluish color palette
- **solarized-dark** - Precision colors for machines and people
- **solarized-light** - Light variant of Solarized
- **one-dark** - Atom's iconic One Dark theme

### Creating Custom Themes

```powershell
$colors = @{
    background = '#1e1e1e'
    foreground = '#d4d4d4'
    black = '#000000'
    red = '#cd3131'
    green = '#0dbc79'
    yellow = '#e5e510'
    blue = '#2472c8'
    magenta = '#bc3fbc'
    cyan = '#11a8cd'
    white = '#e5e5e5'
    brightBlack = '#666666'
    brightRed = '#f14c4c'
    brightGreen = '#23d18b'
    brightYellow = '#f5f543'
    brightBlue = '#3b8eea'
    brightMagenta = '#d670d6'
    brightCyan = '#29b8db'
    brightWhite = '#ffffff'
}

New-PoshixTheme -Name 'my-custom-theme' -Colors $colors
```

See `plugins/themes/README.md` for detailed documentation on theme format.

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

3. Optionally add `plugin.json` so the plugin shows up in discovery views:
```json
{
  "Name": "myplugin",
  "Description": "Short summary used by Get-PoshixPluginCatalog.",
  "Commands": ["myfeat", "Get-MyFeature"],
  "Requires": []
}
```

4. Enable your plugin:
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

#### docker
WSL-aware Docker helpers with Compose shortcuts and prompt status support.

```powershell
# Enable in config
$config = @{
    Plugins = @('docker', 'completions')
    Docker = @{
        Mode = 'Wsl'
        Distribution = 'Ubuntu'
    }
}
Set-PoshixConfig -Config $config
Save-PoshixConfig

# Generic Docker and Compose wrappers
dkr ps
dco up -d

# Inspect backend and prompt status details
Get-DockerBackendInfo
dps
```

When `Docker.Mode` is `Wsl`, or when no native Docker CLI is available, the plugin also exposes a `docker` command proxy for the current session so existing `docker compose ...` workflows keep working.

`Get-DockerPromptInfo` returns a compact Compose-aware status string for use by the native prompt engine.

See [plugins/docker/README.md](plugins/docker/README.md) for details.

#### wsl
WSL discovery and execution helpers with a PowerShell-friendly `wsl` command surface.

```powershell
# Enable in config
$config = @{
    Plugins = @('wsl')
}
Set-PoshixConfig -Config $config
Save-PoshixConfig

# Discover installed and online distros
wsl list
wsl list online
wsl status

# Execute inside WSL
wsl -d Ubuntu -- uname -a
wslx -Distribution Ubuntu -Command 'pwd'
```

The plugin special-cases `wsl list`, `wsl ls`, and `wsl status`, and passes all other invocations directly through to `wsl.exe`.

See [plugins/wsl/README.md](plugins/wsl/README.md) for details.

#### wmi
WMI/CIM discovery and query helpers for Windows inventory, namespaces, services, processes, and disks.

```powershell
# Enable in config
$config = @{
    Plugins = @('wmi')
}
Set-PoshixConfig -Config $config
Save-PoshixConfig

# Explore the WMI surface
wmi info
wmi namespaces root
wmi classes Win32_* root/cimv2
wmi query Win32_OperatingSystem

# Focused inventory helpers
wmisvc spooler
wmiproc pwsh
wmi disks
```

The plugin uses the CIM cmdlets under the hood, so you get WMI-style discovery without depending on the deprecated `Get-WmiObject` workflow.

See [plugins/wmi/README.md](plugins/wmi/README.md) for details.

#### Starship
Modern cross-shell prompt with extensive customization.

```powershell
# Enable in config
$config = @{ Plugins = @('starship') }
Set-PoshixConfig -Config $config
Save-PoshixConfig
```

Requires [Starship](https://starship.rs) to be installed separately.

#### Windows Terminal
Windows Terminal settings integration for theme application and tmux-like pane keybindings.

```powershell
# Enable in config
$config = @{ Plugins = @('themes', 'windows-terminal') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

# Or load manually
Import-PoshixPlugin -Name 'windows-terminal'

# Apply tmux-like pane split/navigation keybindings
Set-WindowsTerminalTmuxKeybindings
```

Keybindings:
- Split pane: `Alt+Shift+↑/↓/←/→`
- Move pane focus: `Alt+↑/↓/←/→`

See [plugins/windows-terminal/README.md](plugins/windows-terminal/README.md) for details.

#### git-worktree
Git worktree management helpers for fast create/switch/prune workflows.

```powershell
# Enable in config
$config = @{ Plugins = @('git-worktree') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

# Or load manually
Import-PoshixPlugin -Name 'git-worktree'

# List all worktrees
gwt

# Create a new worktree and cd into it
gwt-add -Branch feature/my-feature

# Switch to an existing worktree by branch name
gwt-switch feature/my-feature

# Remove a worktree
gwt-rm feature/my-feature
```

See [plugins/git-worktree/README.md](plugins/git-worktree/README.md) for details.

#### fzf-tools
Fuzzy-finding wrappers using [fzf](https://github.com/junegunn/fzf) for history, files, branches, and processes.

Requires fzf: `winget install junegunn.fzf` / `scoop install fzf` / `choco install fzf`

```powershell
# Enable in config
$config = @{ Plugins = @('fzf-tools') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

fh   # fuzzy search command history → insert selected into readline buffer
ff   # fuzzy find files under current directory
fb   # fuzzy pick a git branch and check it out
fp   # fuzzy select running processes and kill them
```

See [plugins/fzf-tools/README.md](plugins/fzf-tools/README.md) for details.

#### k8s-context
Kubernetes context and namespace management with prompt indicator support.

```powershell
# Enable in config
$config = @{ Plugins = @('k8s-context') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

kctx               # show current context
kctx -List         # list all contexts
kctx -Name prod    # switch to 'prod' context
kns                # show current namespace
kns -Name staging  # switch to 'staging' namespace
kinfo              # show context, namespace, and cluster
```

`Get-KubePromptInfo` returns `⎈ context/namespace` for use in custom prompt segments.

See [plugins/k8s-context/README.md](plugins/k8s-context/README.md) for details.

#### task-runner
Unified project task discovery and execution across `package.json`, `Makefile`, `Taskfile.yml`, and `.poshix-tasks`.

```powershell
# Enable in config
$config = @{ Plugins = @('task-runner') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

tasks             # list all available tasks in the current project
task build        # run the 'build' task
task test -- -v   # run 'test' with extra args
task-init         # scaffold a .poshix-tasks file
```

See [plugins/task-runner/README.md](plugins/task-runner/README.md) for details.

#### autohotkey
Helpers for launching and editing AutoHotkey scripts.

```powershell
# Enable in config
$config = @{ Plugins = @('autohotkey') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

ahk .\main.ahk                  # run script
ahk .\main.ahk -- myArg         # run script with extra args
ahk-edit .\main.ahk             # open script in default editor
```

See [plugins/autohotkey/README.md](plugins/autohotkey/README.md) for details.

#### tortoisegit
Helper command for opening TortoiseGit dialogs from PowerShell.

```powershell
# Enable in config
$config = @{ Plugins = @('tortoisegit') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

tgit                 # open log dialog for current directory
tgit commit .        # open commit dialog
tgit push .          # open push dialog
```

See [plugins/tortoisegit/README.md](plugins/tortoisegit/README.md) for details.

#### session-layouts
Save and restore shell session state (working directory, environment variables, directory bookmarks).

```powershell
# Enable in config
$config = @{ Plugins = @('session-layouts') }
Set-PoshixConfig -Config $config
Save-PoshixConfig

layout-save myproject               # save current directory as 'myproject'
layout-restore myproject            # restore directory from 'myproject'
layouts                             # list all saved layouts
layout-rm myproject                 # delete a layout
bookmark myproject docs ~/docs      # add a bookmark to a layout
bm myproject docs                   # cd to a bookmarked directory
```

See [plugins/session-layouts/README.md](plugins/session-layouts/README.md) for details.

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
