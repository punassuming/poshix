# Starship Plugin

Integrates [Starship](https://starship.rs) — a minimal, blazing-fast, and infinitely customizable cross-shell prompt — with poshix.

## Prerequisites

Install Starship before enabling this plugin:

```powershell
winget install --id Starship.Starship
# or
scoop install starship
# or
choco install starship
```

## Usage

Add `starship` to your poshix plugins list in your configuration, or source the plugin manually:

```powershell
. path/to/poshix/plugins/starship/starship.plugin.ps1
```

## Configuration

Starship is configured via `~/.config/starship.toml`. See the [Starship Configuration Guide](https://starship.rs/config/) for all options.

Example `starship.toml`:

```toml
format = "$username$hostname$directory$git_branch$git_status$character"

[directory]
truncation_length = 3
style = "blue bold"

[git_branch]
symbol = "🌱 "

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

## ⚠️ Note

Enabling this plugin will override any poshix native prompt/theme settings.
