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

The plugin exposes low-latency Poshix context through these variables:

- `POSHIX_GIT_BRANCH`: the branch read directly from `.git/HEAD`, without a Git process.
- `POSHIX_GIT_DIRTY`: `*` when the asynchronously cached `git status` reports changes.
- `POSHIX_DIRECTORY`: the current home-relative path, shortened to the configured depth.
- `POSHIX_SESSION`: slash-separated `admin`, `wsl:<distribution>`, and `ssh` markers when applicable.

`POSHIX_PROMPT=starship` remains internal integration state and does not need a
visible Starship segment. Docker and Kubernetes continue to use Starship's
native `docker_context` and `kubernetes` modules.

Example `starship.toml`:

```toml
format = "$env_var$all"

[directory]
disabled = true

[env_var.POSHIX_DIRECTORY]
variable = "POSHIX_DIRECTORY"
format = "[$env_value](cyan bold) "

[env_var.POSHIX_GIT_BRANCH]
variable = "POSHIX_GIT_BRANCH"
format = "on [ $env_value](bold purple) "

[env_var.POSHIX_GIT_DIRTY]
variable = "POSHIX_GIT_DIRTY"
format = "[$env_value](bold red) "

[env_var.POSHIX_SESSION]
variable = "POSHIX_SESSION"
format = "as [$env_value](bold yellow) "

[git_branch]
disabled = true

[git_status]
disabled = true

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
```

The dirty-state probe runs in the background and reuses its last result for the
configured cache interval, so rendering a prompt never waits for `git status`.
Configure the bridge in `.poshixrc.json` or with `Set-PoshixConfig`:

```json
{
  "Starship": {
    "ContextEnabled": true,
    "Directory": true,
    "DirectorySegments": 3,
    "GitDirty": true,
    "GitDirtyCacheSeconds": 10,
    "SessionContext": true
  }
}
```

Use `Get-PoshixStarshipContext` to inspect the current values and
`Update-PoshixStarshipEnvironment -Force` to request a fresh dirty-state probe.

## ⚠️ Note

Enabling this plugin will override any poshix native prompt/theme settings.

On Windows, Poshix normalizes Starship's bare line feeds to carriage-return
line feeds so every prompt row starts in column zero. It also pre-seeds
PSReadLine's extra prompt-line count during startup for the standard two-line
layout; Starship recalculates the count on later renders.

After successful initialization, the plugin exports `POSHIX_PROMPT=starship`.
This prevents Poshix's native prompt from replacing Starship; it is not intended
for display.
