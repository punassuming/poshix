# tortoisegit plugin

Helper commands for opening TortoiseGit dialogs without blocking the terminal.

## Commands

- `Invoke-TortoiseGit [command] [path]` (alias: `tgit`) — open any TortoiseGit dialog
- `Invoke-TortoiseGitDiff [path] [-Path2 <file>] [-StartRevision <rev>] [-EndRevision <rev>]` (alias: `tgitdiff`) — open the TortoiseGit visual diff tool

### `tgit` examples

```powershell
tgit                          # open log dialog for current directory
tgit commit .                 # open commit dialog
tgit push C:\src\my-repo      # open push dialog for a specific repo
```

### `tgitdiff` examples

```powershell
tgitdiff                                    # working-copy diff for current directory
tgitdiff .\src\app.ps1                      # working-copy diff for a specific file
tgitdiff .\src\app.ps1 -StartRevision HEAD  # diff working copy against HEAD
tgitdiff .\src\app.ps1 -StartRevision HEAD~1 -EndRevision HEAD  # diff between two revisions
tgitdiff .\old.ps1 -Path2 .\new.ps1         # compare two files directly
```

## Notes

- Requires TortoiseGit (`TortoiseGitProc.exe`).
- All dialogs are launched in the background so the terminal is immediately returned.
