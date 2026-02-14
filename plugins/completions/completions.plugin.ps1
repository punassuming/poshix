# Completions Plugin for Poshix
# Provides extensive CLI command completion framework for common utilities
# Inspired by zsh, fish, and PowerShell best practices

# Helper function to create simple command completions
function Register-PoshixCompletion {
    <#
    .SYNOPSIS
    Register a completion for a command with options and subcommands.
    .DESCRIPTION
    Simplifies registration of argument completers for commands.
    .PARAMETER Command
    The command name to register completion for.
    .PARAMETER Options
    Array of option strings (e.g., @('-h', '--help', '-v', '--version'))
    .PARAMETER Subcommands
    Hashtable of subcommands with their options (e.g., @{ 'add' = @('-f', '--force') })
    .PARAMETER ScriptBlock
    Custom scriptblock for advanced completion logic.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        
        [Parameter()]
        [string[]]$Options = @(),
        
        [Parameter()]
        [hashtable]$Subcommands = @{},
        
        [Parameter()]
        [scriptblock]$ScriptBlock
    )
    
    if ($ScriptBlock) {
        Register-ArgumentCompleter -CommandName $Command -ScriptBlock $ScriptBlock
    } else {
        $completerScript = {
            param($commandName, $wordToComplete, $commandAst, $fakeBoundParameters)
            
            $command = $using:Command
            $options = $using:Options
            $subcommands = $using:Subcommands
            
            # Get all tokens in the command line
            $tokens = $commandAst.ToString().Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
            
            # Determine context: are we completing a subcommand or options?
            $completingSubcommand = ($tokens.Count -le 2) -or ($tokens[-1].StartsWith('-'))
            
            # If we have subcommands and we're at the subcommand position
            if ($subcommands.Count -gt 0 -and $tokens.Count -eq 2 -and -not $wordToComplete.StartsWith('-')) {
                $subcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            }
            # Complete options
            elseif ($wordToComplete.StartsWith('-')) {
                # Check if we're in a subcommand context
                $currentSubcommand = $null
                if ($tokens.Count -gt 2) {
                    $currentSubcommand = $tokens[1]
                }
                
                # Get relevant options
                $relevantOptions = $options
                if ($currentSubcommand -and $subcommands.ContainsKey($currentSubcommand)) {
                    $relevantOptions = $relevantOptions + $subcommands[$currentSubcommand]
                }
                
                $relevantOptions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
                }
            }
            # If in subcommand, suggest its options
            elseif ($tokens.Count -gt 2 -and $subcommands.ContainsKey($tokens[1])) {
                $subcommands[$tokens[1]] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
                }
            }
        }
        Register-ArgumentCompleter -CommandName $Command -ScriptBlock $completerScript
    }
}

Write-Verbose "[poshix-completions] Completions plugin loaded"
