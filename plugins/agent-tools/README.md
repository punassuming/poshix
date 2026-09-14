# agent-tools plugin

Project-aware, safe launchers for Yazi, LazyGit, Herdr, Claude Code, Codex, and GitHub Copilot CLI.

## Commands

- `Get-PoshixAgentTool` reports executable paths and availability.
- `y` / `Start-PoshixYazi` opens Yazi and changes PowerShell to Yazi's final directory.
- `lg` / `Start-PoshixGitUi` opens LazyGit at the current repository root.
- `agent` opens an `fzf` picker of installed Claude, Codex, and Copilot CLIs; `agent Claude|Codex|Copilot` launches one directly.
- `yf` / `Start-PoshixYaziFocused` opens a temporary current-folder-only, preview-free Yazi layout and follows its final directory on exit.
- `hlayout` / `Start-PoshixHerdrPaneLayout` opens an fzf picker for generic pane-only layouts and never assumes a particular command.
- `hwork` / `Start-PoshixHerdrWorkArea` discovers native Poshix templates and applies the selected layout through Herdr's built-in pane APIs. Create templates with `Save-PoshixHerdrTemplate`; each pane accepts any `Command`, optional `Arguments`, and a split `Direction`.
- `Save-PoshixHerdrCurrentTemplate` captures the current Herdr tab's pane geometry as a starting template. Commands are intentionally saved as `pwsh` placeholders; edit them afterward with `Save-PoshixHerdrTemplate`.
- `Get-PoshixHerdrIntegration` checks whether the calling shell is a Herdr pane.
- `Save-PoshixAgentWorkspace` and `Start-PoshixAgentWorkspace` manage named agent-pane definitions.

Agent workspaces are stored in `~/.poshix/agent-workspaces/`. Starting one requires `HERDR_ENV=1`; Poshix will never control a Herdr session from outside a managed pane. Poshix does not add unsafe permission-bypass flags or supply credentials to agent CLIs.

The layout helpers require `HERDR_ENV=1` and use Herdr's returned tab/pane IDs rather than guessing from screen order. Templates are stored in `~/.poshix/herdr-templates.json` and do not require any additional Herdr plugin.
