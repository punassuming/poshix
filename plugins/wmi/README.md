# wmi plugin

The wmi plugin adds PowerShell-friendly WMI discovery and query helpers using the CIM cmdlets available on modern Windows systems.

## Features

- Namespace discovery with `Get-WmiNamespace`
- Class discovery with `Get-WmiClass`
- Generic class queries through `Get-WmiData`
- Practical inventory helpers for system info, services, processes, and disks
- A `wmi` convenience command that dispatches the common workflows

## Configuration

Add `wmi` to the `Plugins` list in your poshix config (`~/.poshixrc.json`):

```json
{
  "Plugins": ["wmi"]
}
```

## Commands

| Command | Alias | Description |
| --- | --- | --- |
| `wmi info` | `wmiinfo` | Show a compact system inventory snapshot |
| `wmi namespaces [root]` | `wmins` | List child WMI namespaces |
| `wmi classes [pattern] [namespace]` | `wmicls` | List classes in a namespace |
| `wmi query <ClassName> [namespace]` | `wmiq` | Query a WMI class |
| `wmi services [name]` | `wmisvc` | List matching services |
| `wmi processes [name]` | `wmiproc` | List matching processes |
| `wmi disks [--all]` | _(none)_ | List logical disks |

## Examples

```powershell
wmi info
wmi namespaces root
wmi classes Win32_* root/cimv2
wmi query Win32_OperatingSystem
wmiq -ClassName Win32_Service -Filter "State = 'Running'" -First 10
wmisvc spooler
wmiproc pwsh
wmi disks
```

All primary commands accept `-ComputerName` so you can query another Windows machine when your environment allows CIM remoting.
