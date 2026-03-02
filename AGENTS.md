# AGENTS

## Configuration Example Maintenance

When changing Poshix functionality that affects configuration behavior, you must update `./.poshixrc.json` in the same change.

## Documentation Sync Policy

Treat this file and `README.md` as living documentation. When behavior changes, update docs in the same change set.

### AGENTS self-maintenance rules

- If contributor workflow, maintenance expectations, or documentation rules change, update `AGENTS.md`.
- If a rule in `AGENTS.md` no longer matches repository behavior, fix `AGENTS.md` immediately.
- Do not defer AGENTS fixes to a follow-up PR when the mismatch is discovered during active work.

### README sync rules

- Update `README.md` for any user-facing change to commands, aliases, plugin behavior, configuration keys, configuration paths, setup steps, or defaults.
- Keep the built-in plugin documentation in `README.md` aligned with the actual `plugins/` directory and exported behavior.
- Keep all configuration examples consistent with `config.ps1`, `prompt.ps1`, and `./.poshixrc.json`.
- For changes to `config.ps1`, `prompt.ps1`, or `plugins/`, explicitly review both `README.md` and `AGENTS.md` before merging.

### Trigger conditions

Update the example config whenever any of the following changes:

- Default config schema in `config.ps1` (new/removed/renamed keys under `Colors`, `FileTypes`, `History`, `Startup`, `Prompt`, `Plugins`, `Theme`).
- Prompt segment behavior or settings in `prompt.ps1` (segment types, supported properties, defaults).
- Built-in plugin surface in `plugins/*` that affects recommended plugin enablement.
- Plugin names added/removed/renamed in the built-in `plugins/` directory.
- Theme integration behavior that changes expected `Theme` or prompt config usage.

### Required update workflow

1. Edit `./.poshixrc.json` to reflect current functionality.
2. Keep all built-in plugins represented in the `Plugins` array unless there is a documented reason not to.
3. Ensure the file is valid JSON:
   - `Get-Content -Raw ./.poshixrc.json | ConvertFrom-Json | Out-Null`
4. Keep `README.md` examples consistent with the config model when relevant.

### PR/commit checklist

- [ ] `.poshixrc.json` reviewed for required updates.
- [ ] JSON validation command executed successfully.
- [ ] Any config-related README examples adjusted to match current behavior.
- [ ] `README.md` reviewed and updated for user-facing changes.
- [ ] `AGENTS.md` reviewed and updated if maintenance/documentation rules changed.
