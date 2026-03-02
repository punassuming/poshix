# task-runner plugin

Per-project task discovery and execution for [poshix](https://github.com/nickvdyck/poshix).

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `Get-ProjectTasks` | `tasks` | List all discovered tasks for the current project |
| `Invoke-ProjectTask` | `task` | Run a named task |
| `New-PoshixTaskFile` | `task-init` | Create a `.poshix-tasks` file in the current directory |

## Supported task files

| File | Task runner |
|------|-------------|
| `package.json` | `npm run <name>` |
| `Makefile` | `make <name>` (or `gmake`) |
| `Taskfile.yml` / `Taskfile.yaml` | `task <name>` ([go-task](https://taskfile.dev)) |
| `.poshix-tasks` | shell command from the file |

All supported files in the current directory are discovered simultaneously.

## Usage

```powershell
# List all available tasks
tasks

# Run a task
task build
task test -- --watch

# Pass extra arguments to the underlying runner
task build -- --release

# Create a .poshix-tasks file with example tasks
task-init

# Overwrite an existing .poshix-tasks file
task-init -Force
```

Tab completion is available for the `-Name` parameter on both `task` and `Invoke-ProjectTask`.

## .poshix-tasks format

One task per line in `taskname: command` format. Lines starting with `#` are comments.

```
# .poshix-tasks
build: go build ./...
test: go test ./...
lint: golangci-lint run
deploy: ./scripts/deploy.sh production
```

## Enabling the plugin

Add `task-runner` to the `Plugins` list in your poshix config (`~/.poshix/config.json`):

```json
{
  "Plugins": ["task-runner"]
}
```

Or load it manually in your profile:

```powershell
Import-PoshixPlugin task-runner
```
