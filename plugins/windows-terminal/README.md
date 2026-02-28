# Poshix Windows Terminal Plugin

Windows Terminal settings integration for Poshix themes and tmux-like pane keybindings.

## Installation

Enable the plugin in your config:

```powershell
Set-PoshixConfig -Config @{ Plugins = @('windows-terminal') }
Save-PoshixConfig
```

## Commands

### Apply a Poshix theme to Windows Terminal

```powershell
$theme = Get-PoshixTheme -Name dracula
Set-WindowsTerminalTheme -Theme $theme -Name dracula
```

### Add tmux-like pane keybindings

```powershell
Set-WindowsTerminalTmuxKeybindings
```

Keybindings:
- Split pane: `Alt+Shift+↑/↓/←/→`
- Move pane focus: `Alt+↑/↓/←/→`

## Safety

- Creates `settings.json.backup` before writing changes
- Restores from backup on write failures
- Writes JSON as UTF-8 with BOM for Windows Terminal compatibility
