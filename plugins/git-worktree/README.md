# git-worktree plugin

Git worktree management helpers for [poshix](https://github.com/nickvdyck/poshix).

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `Get-GitWorktrees` | `gwt` | List all worktrees as a formatted table |
| `New-GitWorktree` | `gwt-add` | Create a new worktree and cd into it |
| `Switch-GitWorktree` | `gwt-switch` | cd into an existing worktree by branch/path |
| `Remove-GitWorktree` | `gwt-rm` | Remove a worktree |

## Usage

```powershell
# List all worktrees
gwt

# Create a worktree for branch "feature/my-feature" at ../feature-my-feature
gwt-add -Branch feature/my-feature

# Create a worktree at a custom path
gwt-add -Branch hotfix/urgent -Path C:\Work\hotfix-urgent

# Switch to (cd into) a worktree by branch name or partial match
gwt-switch main
gwt-switch feature/my-feature

# Remove a worktree by branch name
gwt-rm feature/my-feature

# Remove a worktree by path, forcing removal of unclean worktree
gwt-rm -Path C:\Work\hotfix-urgent -Force
```

Tab completion is available for `-Name` on `gwt-switch` and `-Path`/`-Name` on `gwt-rm`.

## Enabling the plugin

Add `git-worktree` to the `Plugins` list in your poshix config (`~/.poshix/config.json`):

```json
{
  "Plugins": ["git-worktree"]
}
```

Or load it manually in your profile:

```powershell
Import-PoshixPlugin git-worktree
```
