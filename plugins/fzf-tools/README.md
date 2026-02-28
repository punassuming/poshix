# fzf-tools plugin

Fuzzy-finding wrappers for [poshix](https://github.com/nickvdyck/poshix), powered by [fzf](https://github.com/junegunn/fzf).

## Requirements

- **fzf** must be installed and available in `PATH`.

  ```powershell
  # Windows
  winget install --id junegunn.fzf
  # or
  scoop install fzf
  # or
  choco install fzf

  # macOS / Linux
  brew install fzf
  ```

## Enabling the plugin

Add `fzf-tools` to the `Plugins` list in your poshix config (`~/.poshix/config.json`):

```json
{
  "Plugins": ["fzf-tools"]
}
```

Or load it manually in your profile:

```powershell
Import-PoshixPlugin fzf-tools
```

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `Find-FzfHistory` | `fh` | Fuzzy search command history |
| `Find-FzfFile` | `ff` | Fuzzy search files recursively |
| `Find-FzfBranch` | `fb` | Fuzzy search git branches and check one out |
| `Find-FzfProcess` | `fp` | Fuzzy search processes and kill selected ones |

## Usage

### `Find-FzfHistory` / `fh`

Fuzzy search through your PowerShell session history. The selected command is
copied to the clipboard and inserted into the readline buffer.

```powershell
fh
```

### `Find-FzfFile` / `ff`

Recursively search for files under a directory with a `cat` preview pane.
The selected path is returned to the pipeline and inserted into the readline buffer.

```powershell
# Search in current directory
ff

# Search under a specific path
ff -Path C:\Projects

# Search with a glob filter
ff -Path ./src -Filter "*.ps1"

# Use the result directly
$file = ff -Path ./logs
```

### `Find-FzfBranch` / `fb`

List all local and remote git branches and check out the selected one.
Remote-tracking prefixes (`remotes/origin/`) are stripped automatically.

```powershell
fb
```

### `Find-FzfProcess` / `fp`

List running processes sorted by CPU usage (multi-select with `Tab`).
Prompts for confirmation before killing the selected processes.

```powershell
fp
```
