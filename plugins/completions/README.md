# Completions Plugin

Extensive CLI command completion framework for common utilities, inspired by best practices from zsh, fish, and PowerShell ecosystems.

## Features

- **Comprehensive coverage**: Completions for git, docker, npm, yarn, kubectl, cargo, pip, dotnet, and poshix commands
- **Context-aware**: Suggests relevant options, subcommands, and arguments based on current context
- **Dynamic completions**: Queries live data (e.g., running containers, git branches) when available
- **Fuzzy matching**: Supports PowerShell's natural prefix-based completion
- **Extensible**: Easy to add new completions following established patterns

## Supported Commands

### Version Control
- **git**: Comprehensive git command completions with subcommands, options, branches, and files

### Containers
- **docker**: Docker CLI with container, image, network, and volume completions
- **kubectl**: Kubernetes CLI with resource types, contexts, and live cluster resources

### Package Managers
- **npm**: Node.js package manager with subcommands, options, and package.json script awareness
- **yarn**: Alternative Node.js package manager with similar features
- **pip**: Python package manager with installed package awareness
- **cargo**: Rust package manager with build, test, and publish commands
- **dotnet**: .NET CLI with project management and build commands

### Poshix Commands
- **cd**: Directory navigation with special targets (-, .., ~)
- **ls**: Enhanced listing with options
- **find**: File search with filters
- **grep**: Text search with patterns
- **Config commands**: Poshix configuration management
- **Plugin commands**: Plugin loading and management
- **History commands**: Command history operations

## Usage

### Enabling the Plugin

Add to your poshix config:

```powershell
$config = @{
    Plugins = @('completions')
}
Set-PoshixConfig -Config $config
Save-PoshixConfig
```

Or load manually:

```powershell
Import-PoshixPlugin -Name 'completions'
```

### Using Completions

Once loaded, completions work automatically with PowerShell's tab completion:

```powershell
# Git completions
git co<Tab>          # Suggests: commit, config, checkout
git commit -<Tab>    # Suggests: -m, --message, -a, --all, --amend, etc.
git checkout <Tab>   # Suggests branches

# Docker completions
docker ru<Tab>       # Suggests: run
docker run -<Tab>    # Suggests: -d, --detach, -i, --interactive, etc.
docker ps -<Tab>     # Suggests: -a, --all, -f, --filter, etc.

# npm completions
npm in<Tab>          # Suggests: install, init, info
npm install -<Tab>   # Suggests: -g, --global, --save, --save-dev, etc.
npm run <Tab>        # Suggests scripts from package.json

# kubectl completions
kubectl g<Tab>       # Suggests: get
kubectl get <Tab>    # Suggests: pods, services, deployments, etc.
kubectl get pods <Tab>  # Suggests actual pod names from cluster

# Poshix command completions
cd <Tab>             # Suggests directories and special targets (-, .., ~)
ls -<Tab>            # Suggests: -l, -a, -X, -t, -S, etc.
Import-PoshixPlugin <Tab>  # Suggests available plugins
```

## Architecture

### Plugin Structure

```
plugins/completions/
├── completions.plugin.ps1    # Main plugin file with helper functions
├── completions/              # Individual completion scripts
│   ├── git.ps1              # Git completions
│   ├── docker.ps1           # Docker completions
│   ├── npm.ps1              # npm and yarn completions
│   ├── kubectl.ps1          # Kubernetes CLI completions
│   ├── misc.ps1             # cargo, pip, dotnet completions
│   └── poshix.ps1           # Poshix command completions
└── README.md                # This file
```

### How It Works

The plugin uses PowerShell's `Register-ArgumentCompleter` to register completion handlers for each command. When you press Tab:

1. PowerShell invokes the registered completion handler
2. The handler analyzes the command line context
3. Based on the context, it suggests:
   - Subcommands (if at the subcommand position)
   - Options (if typing a flag starting with -)
   - Arguments (files, branches, packages, etc.)
4. PowerShell presents the suggestions to you

### Best Practices Applied

Inspired by zsh, fish, and PowerShell ecosystems:

- **Progressive disclosure**: Show the most relevant options first
- **Context awareness**: Different completions based on command structure
- **Live data**: Query actual resources when possible (git branches, docker containers)
- **Descriptions**: Provide tooltips where helpful
- **Performance**: Lazy-load and cache where appropriate
- **Graceful degradation**: Handle errors silently when commands aren't available

## Extending with Custom Completions

To add completions for a new command, create a new `.ps1` file in the `completions/` directory:

```powershell
# completions/mycommand.ps1

Register-ArgumentCompleter -CommandName mycommand -ScriptBlock {
    param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    # Your completion logic here
    # Example: suggest some options
    $options = @('--help', '--version', '--verbose')
    $options | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
    }
}
```

The file will be automatically loaded when the plugin loads.

## Notes

- Completions are registered globally in your PowerShell session
- Some dynamic completions (like git branches or docker containers) require the respective tool to be installed and accessible
- Errors in fetching dynamic data are handled silently to avoid disrupting the completion experience
- PowerShell's completion is prefix-based, not fuzzy like zsh/fish, but still very effective

## Contributing

To add more commands or improve existing completions:

1. Add a new file in `completions/` or modify an existing one
2. Follow the established patterns for consistency
3. Test your completions thoroughly
4. Consider both common and advanced use cases

## Credits

Inspired by:
- [zsh-completions](https://github.com/zsh-users/zsh-completions)
- [fish shell](https://fishshell.com/) completions
- [posh-git](https://github.com/dahlbyk/posh-git)
- PowerShell's native completion system
