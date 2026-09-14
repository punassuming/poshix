# wsl plugin

The wsl plugin adds PowerShell-friendly WSL discovery and execution helpers while preserving normal `wsl.exe` passthrough behavior.

## Features

- `wsl list` and `wsl status` shortcuts for structured discovery from PowerShell
- `Get-WslDistribution` for installed or online distro inventory
- `Invoke-WslCommand` for parameterized execution in a specific distro or user context
- Native `wsl.exe` passthrough for everything the plugin does not special-case

## Configuration

Add `wsl` to the `Plugins` list in your poshix config (`~/.poshixrc.json`):

```json
{
  "Plugins": ["wsl"]
}
```

## Commands

| Command | Alias | Description |
| --- | --- | --- |
| `wsl list` | _(none)_ | Show installed distros |
| `wsl list online` | _(none)_ | Show online/installable distros |
| `wsl status` | _(none)_ | Show default distro/version plus installed distro inventory |
| `Get-WslDistribution` | `wslls` | Return installed or online distros as objects |
| `Invoke-WslCommand` | `wslx` | Run a command in WSL with optional distro/user/working-directory targeting |
| `Get-WslStatus` | `wslinfo` | Return structured WSL status details |

## Examples

```powershell
wsl list
wsl list online
wsl status
wsl -d Ubuntu -- uname -a
wslx -Distribution Ubuntu -Command 'pwd'
wslx -Distribution Ubuntu -User root -Command 'id'
wslx -Distribution Ubuntu -WorkingDirectory C:\src\app -Capture -Command 'pwd'
```

Any `wsl` invocation that does not match `list`, `ls`, or `status` is passed through directly to `wsl.exe`.

`-WorkingDirectory` accepts absolute Windows drive paths and Linux paths. `-Capture` returns structured output and exit status for automation; WSL access-denied failures are reported as status data instead of being confused with a missing distro.
