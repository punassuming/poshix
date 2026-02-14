# Poshix Themes Plugin

The Themes plugin provides comprehensive theming capabilities for Poshix with full RGB color support (color3d) and Windows Terminal integration.

## Features

- **RGB Color Support**: Define themes with full hex color values (#RRGGBB)
- **Windows Terminal Integration**: Automatically applies themes to Windows Terminal settings
- **Built-in Themes**: Multiple professional themes included
- **Custom Themes**: Create your own themes easily
- **Automatic Color Mapping**: Intelligent conversion from RGB to ANSI colors for Poshix output

## Installation

The themes plugin is included with Poshix. To enable it, add it to your configuration:

```powershell
Set-PoshixConfig -Config @{ Plugins = @('themes') }
Save-PoshixConfig
```

Then reload your PowerShell session or run:

```powershell
Import-Module poshix -Force
```

## Usage

### List Available Themes

```powershell
Get-PoshixThemes
```

This will show all available themes (both built-in and user-created).

### View a Theme

```powershell
Get-PoshixTheme -Name dracula
```

### Apply a Theme

Apply to Poshix only:

```powershell
Set-PoshixTheme -Name dracula
```

Apply to both Poshix and Windows Terminal:

```powershell
Set-PoshixTheme -Name dracula -ApplyToTerminal
```

When applying to Windows Terminal, the plugin will:
1. Backup your existing settings.json
2. Add the theme as a color scheme
3. Apply it to all PowerShell profiles
4. Notify you to restart the terminal

### Create a Custom Theme

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

New-PoshixTheme -Name 'my-theme' -Colors $colors
```

## Built-in Themes

The following themes are included:

- **dracula** - Popular dark theme with purple accents
- **monokai** - Classic dark theme from Sublime Text
- **nord** - Arctic, north-bluish color palette
- **solarized-dark** - Precision colors for machines and people
- **solarized-light** - Light variant of Solarized
- **one-dark** - Atom's iconic One Dark theme

## Theme File Format

Themes are stored as JSON files with the following structure:

```json
{
  "name": "Theme Name",
  "colors": {
    "background": "#282a36",
    "foreground": "#f8f8f2",
    "cursor": "#f8f8f2",
    "selection": "#44475a",
    "black": "#21222c",
    "red": "#ff5555",
    "green": "#50fa7b",
    "yellow": "#f1fa8c",
    "blue": "#bd93f9",
    "magenta": "#ff79c6",
    "cyan": "#8be9fd",
    "white": "#f8f8f2",
    "brightBlack": "#6272a4",
    "brightRed": "#ff6e6e",
    "brightGreen": "#69ff94",
    "brightYellow": "#ffffa5",
    "brightBlue": "#d6acff",
    "brightMagenta": "#ff92df",
    "brightCyan": "#a4ffff",
    "brightWhite": "#ffffff"
  },
  "prompt": {
    "Segments": [
      {
        "Type": "path",
        "Enabled": true,
        "Color": "Cyan"
      },
      {
        "Type": "git",
        "Enabled": true,
        "Color": "Magenta",
        "DirtyColor": "Yellow"
      }
    ]
  }
}
```

### Color Properties

- **background**: Terminal background color
- **foreground**: Default text color
- **cursor**: Cursor color
- **selection**: Selection background color
- **black** through **white**: Standard ANSI colors (0-7)
- **brightBlack** through **brightWhite**: Bright ANSI colors (8-15)

All colors should be in hex format (#RRGGBB).

### Prompt Configuration

The optional `prompt` section allows you to define custom prompt segment configurations for the theme.

## Theme Storage

- **Built-in themes**: `plugins/themes/themes/*.theme.json`
- **User themes**: `~/.poshix/themes/*.theme.json`

User themes take precedence over built-in themes with the same name.

## Windows Terminal Integration

When you use `-ApplyToTerminal`, the plugin:

1. Locates your Windows Terminal settings.json file
2. Creates a backup (settings.json.backup)
3. Adds the theme to the `schemes` array with prefix "Poshix-"
4. Updates all PowerShell profiles to use the theme
5. Notifies you to restart Windows Terminal

### Settings File Locations

The plugin searches for settings in:
- `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
- `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json`

### Safety

- A backup is always created before modifying settings
- If an error occurs, settings are restored from backup
- Only PowerShell profiles are modified

## Color3D Support

The "color3d" capability refers to the full RGB color space support (Red, Green, Blue - 3 dimensions of color). Themes use hex color codes (#RRGGBB) which provide:

- 256 levels per channel
- Over 16 million possible colors
- Precise color matching across terminals
- True color support in modern terminals

When applying themes to Poshix's internal tools (ls, prompt), colors are intelligently mapped to the nearest ANSI color name for maximum compatibility.

## Examples

### Quick Theme Switch

```powershell
# Switch to Dracula
Set-PoshixTheme dracula -ApplyToTerminal

# Switch to Nord
Set-PoshixTheme nord -ApplyToTerminal

# Switch to One Dark (Poshix only)
Set-PoshixTheme one-dark
```

### Browse Themes

```powershell
# List all themes
Get-PoshixThemes | Format-Table

# Preview a theme's colors
$theme = Get-PoshixTheme -Name dracula
$theme.colors | ConvertTo-Json
```

## Troubleshooting

### Theme Not Applied to Windows Terminal

- Ensure Windows Terminal is installed
- Check that the settings.json file exists
- Try manually restarting Windows Terminal
- Check the backup file (settings.json.backup) if needed

### Colors Look Wrong

- Ensure your terminal supports true color
- Try restarting your terminal
- Check if another theme or color profile is overriding settings

### Theme File Not Found

- Verify the theme name with `Get-PoshixThemes`
- Check that the .theme.json file is properly formatted
- Ensure the file is in the correct directory

## Contributing Themes

To contribute a new theme:

1. Create a `.theme.json` file following the format above
2. Test it with `Set-PoshixTheme -Name your-theme`
3. Submit a pull request with the theme file in `plugins/themes/themes/`

Popular theme sources:
- [Windows Terminal Themes](https://windowsterminalthemes.dev/)
- [iTerm2 Color Schemes](https://iterm2colorschemes.com/)
- [Base16 Themes](https://github.com/chriskempson/base16)
