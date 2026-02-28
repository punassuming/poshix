# session-layouts plugin

Save and restore working directory and shell session layouts for [poshix](https://github.com/nickvdyck/poshix).

Layouts are stored as JSON files in `~/.poshix/layouts/`.  Each layout captures the current working directory, an optional set of environment variables, and a collection of named directory bookmarks.

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `Save-SessionLayout` | `layout-save` | Save the current directory (and optional env vars) as a named layout |
| `Restore-SessionLayout` | `layout-restore` | Restore a saved layout (directory + env vars) |
| `Get-SessionLayouts` | `layouts` | List all saved layouts |
| `Remove-SessionLayout` | `layout-rm` | Delete a saved layout |
| `Add-LayoutBookmark` | `bookmark` | Add a named directory bookmark to a layout |
| `Invoke-LayoutBookmark` | `bm` | Navigate to a bookmarked directory |

## Usage

```powershell
# Save the current directory as a layout named "myproject"
layout-save myproject

# Save with a description and include custom environment variables
layout-save myproject -Description "Main project workspace" -IncludeEnv

# List all saved layouts
layouts

# Restore a layout (tab-completion supported for layout names)
layout-restore myproject

# Remove a layout
layout-rm myproject

# Remove without confirmation prompt
layout-rm myproject -Force

# Add a bookmark for the current directory to a layout
bookmark myproject docs

# Add a bookmark for a specific path
bookmark myproject scripts -Path C:\myproject\scripts

# Navigate to a bookmarked directory
bm myproject docs
```

## Layout file format

```json
{
  "Name": "myproject",
  "Description": "Main project workspace",
  "Directory": "C:\\Users\\you\\myproject",
  "EnvironmentVars": {
    "MY_API_KEY": "...",
    "NODE_ENV": "development"
  },
  "Bookmarks": [
    { "Name": "docs", "Path": "C:\\Users\\you\\myproject\\docs" },
    { "Name": "scripts", "Path": "C:\\Users\\you\\myproject\\scripts" }
  ],
  "CreatedAt": "2024-01-01T00:00:00.0000000+00:00",
  "UpdatedAt": "2024-01-02T00:00:00.0000000+00:00"
}
```

## Enabling the plugin

Add `session-layouts` to the `Plugins` list in your poshix config (`~/.poshix/config.json`):

```json
{
  "Plugins": ["session-layouts"]
}
```

Or load it manually in your profile:

```powershell
Import-PoshixPlugin session-layouts
```
