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
        Register-ArgumentCompleter -Native -CommandName $Command -ScriptBlock $ScriptBlock
    } else {
        # Capture variables into local scope so GetNewClosure() can close over them
        $capturedOptions = $Options
        $capturedSubcommands = $Subcommands
        $completerScript = ({
            param($wordToComplete, $commandAst, $cursorPosition)

            $options = $capturedOptions
            $subcommands = $capturedSubcommands

            # Get all tokens from the AST command elements
            $tokens = $commandAst.CommandElements | ForEach-Object { $_.ToString() }
            # Determine how many complete tokens precede the word being completed
            $completingIndex = if ($wordToComplete) { $tokens.Count - 1 } else { $tokens.Count }

            # If we have subcommands and we're at the subcommand position
            if ($subcommands.Count -gt 0 -and $completingIndex -eq 1 -and -not $wordToComplete.StartsWith('-')) {
                $subcommands.Keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                }
            }
            # Complete options
            elseif ($wordToComplete.StartsWith('-')) {
                # Check if we're in a subcommand context
                $currentSubcommand = if ($completingIndex -gt 1 -and $tokens.Count -gt 1) { $tokens[1] } else { $null }

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
            elseif ($completingIndex -gt 1 -and $tokens.Count -gt 1 -and $subcommands.ContainsKey($tokens[1])) {
                $subcommands[$tokens[1]] | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterName', $_)
                }
            }
        }.GetNewClosure())
        Register-ArgumentCompleter -Native -CommandName $Command -ScriptBlock $completerScript
    }
}

Write-Verbose "[poshix-completions] Completions plugin loaded"

# Export to global scope to work around PowerShell module export timing limitations
Set-Item -Path "function:global:Register-PoshixCompletion" -Value ${function:Register-PoshixCompletion}
