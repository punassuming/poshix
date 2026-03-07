# docker plugin

The docker plugin adds WSL-aware Docker wrappers, Compose shortcuts, and native prompt integration.

## Features

- Route Docker commands through the native CLI or `wsl.exe` based on `Docker.Mode`
- Compose shortcut via `dco`
- Backend inspection with `Get-DockerBackendInfo`
- Prompt status from `Get-DockerPromptInfo`, including Compose project counts when a compose file is present

## Configuration

Add `docker` to the `Plugins` list in your poshix config (`~/.poshixrc.json`):

```json
{
  "Plugins": ["docker", "completions"],
  "Docker": {
    "Mode": "Wsl",
    "Distribution": "Ubuntu",
    "Prompt": {
      "ShowContext": true,
      "ShowProject": true,
      "MaxItems": 2,
      "CacheSeconds": 3
    }
  }
}
```

`Docker.Mode` supports:

- `Auto`: Prefer the native Docker CLI, fall back to WSL
- `Native`: Require the native Docker CLI
- `Wsl`: Always invoke Docker through `wsl.exe`

Set `Docker.Distribution` to target a specific WSL distro. Leave it unset to use the default distro.

## Commands

| Command | Alias | Description |
| --- | --- | --- |
| `Invoke-DockerCli` | `dkr` | Run `docker ...` via the configured backend |
| `Invoke-DockerCompose` | `dco` | Run `docker compose ...` via the configured backend |
| `Get-DockerBackendInfo` | `dinfo` | Show the resolved backend, context, and versions |
| `Get-DockerStatus` | `dps` | Show Compose-aware or global running-container status |
| `Get-DockerPromptInfo` | _(none)_ | Return a compact prompt object for the native prompt engine |

When `Docker.Mode` is `Wsl`, or when no native Docker CLI is available, the plugin also exports a session-local `docker` proxy so existing `docker compose ...` commands continue to work.

## Prompt Segment

Enable the `docker` prompt segment to show container activity:

```powershell
Set-PoshixConfig -Config @{
    Prompt = @{
        Segments = @(
            @{ Type = 'path'; Enabled = $true }
            @{ Type = 'git'; Enabled = $true }
            @{ Type = 'docker'; Enabled = $true; Color = 'DarkCyan'; ActiveColor = 'Cyan'; ShowContext = $true; ShowProject = $true; MaxItems = 2; CacheSeconds = 3 }
            @{ Type = 'char'; Enabled = $true }
        )
    }
}
```

If a compose file is found in the current directory tree, the segment shows `running/total` container counts for that project. Otherwise it falls back to globally running containers and their images.
