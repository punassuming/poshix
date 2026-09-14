# command-center plugin

Use `poshix-help` or `Get-PoshixCommandCenter` to open the live Poshix command palette. Each command appears once with its related aliases, shortcuts, shortcut mode, availability, and description in the same row. When `fzf` is available, it opens a searchable terminal modal; select an item to insert its command into the current input buffer. Use `-List`, `-Section`, or `-Filter` for a static table, and `-AsObject` for scripting. `-Section Aliases` and `-Section Shortcuts` filter the unified command rows instead of producing disconnected lists.

When PSReadLine is available, the plugin registers these session-only bindings:

| Shortcut | Behavior |
| --- | --- |
| `Alt+h` | Open the Herdr layout/work-area selector |
| `Alt+y` | Open Yazi; apply its selected directory when it exits |
| `Alt+f` | Open focused Yazi: current folder only, without preview, with cwd handoff |
| `Alt+v` | Save the clipboard image or text into the current folder with a timestamp filename |
| `Alt+g` | Open LazyGit at the current repository root |
| `Alt+n` | Open Neovim at the current directory |
| `Alt+a` | Choose and launch an installed coding agent |
| `Alt+r` | Insert `Get-PoshixRuntimeReport` |

Set `Keybindings.Enabled` to `false` in `.poshixrc.json` to disable automatic registration. Use `Disable-PoshixKeybindings` to remove them from the current session.
