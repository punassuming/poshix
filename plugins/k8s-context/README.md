# k8s-context plugin

Kubernetes context and namespace management helpers for [poshix](https://github.com/nickvdyck/poshix).

## Requirements

- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) must be installed and available in `PATH`.

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `Invoke-KubeContext` | `kctx` | Show current context, switch context, or list all contexts |
| `Invoke-KubeNamespace` | `kns` | Show current namespace, set namespace, or list all namespaces |
| `Get-KubeContextInfo` | `kinfo` | Show current context, namespace, and cluster as a formatted summary |
| `Get-KubePromptInfo` | _(none)_ | Return a compact `⎈ context/namespace` string for prompt segments |

## Usage

```powershell
# Show the current context
kctx

# Switch to a different context (tab-completion supported)
kctx -Name my-cluster

# List all contexts (current marked with *)
kctx -List

# Show the current namespace
kns

# Set the namespace for the current context (tab-completion supported)
kns -Name kube-system

# List all namespaces
kns -List

# Show full context summary (context, namespace, cluster)
kinfo

# Use in a custom prompt
function prompt {
    $k8s = Get-KubePromptInfo
    if ($k8s) { Write-Host " $k8s " -NoNewline -ForegroundColor Blue }
    "> "
}
```

## Enabling the plugin

Add `k8s-context` to the `Plugins` list in your poshix config (`~/.poshix/config.json`):

```json
{
  "Plugins": ["k8s-context"]
}
```

Or load it manually in your profile:

```powershell
Import-PoshixPlugin k8s-context
```
