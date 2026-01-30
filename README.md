# Poshix
Powershell implementation of common posix commands

If you want to install from a copy of this repo, follow the directions under [module usage](#module-usage)

## Features

### Enhanced Startup and Execution
- Robust error handling during module initialization
- Configuration management system for persistent settings
- Verbose startup logging option
- Automatic history loading on startup
- Graceful cleanup on module removal

## cd

Change directory implementation similar to zsh

### Features
- Remember directory stack, support `cd -` to go to previous directory
- Allow automatic directory globbing, allowing `cd /u/r/d` to automatically traverse to the common file path
- Go to parent directory, smart traversal to parent with matching text using `..`

## ls

### Features
- Wrapped ls similar to posix
- **Configurable colored output based on filetype**
- Human readable file size
- Complete listing with `ls -l`
- Show hidden files `ls -a`
- Sort by Extension `-X`, Time `-t`, or Size `-S`, or no sorting with `-U`
- Disable colors with `--NoColor` option

### ls Colors

Colored output with extensive file type detection:
- **Cyan** for Symlinks
- **Blue** for Directories
- **DarkCyan** for Hidden directories
- **DarkGray** for Hidden files
- **Green** for Executable files (.exe, .bat, .cmd, .ps1, .sh)
- **Red** for Archive files (.zip, .tar, .gz, .7z, etc.)
- **Magenta** for Image files (.jpg, .png, .gif, etc.)
- **Magenta** for Video files (.mp4, .avi, .mkv, etc.)
- **DarkMagenta** for Audio files (.mp3, .wav, .flac, etc.)
- **Yellow** for Document files (.pdf, .doc, .txt, etc.)
- **Green** for other files with extensions
- **White** for files with no extension

**Customize Colors**: Use `Set-PoshixConfig` to customize colors and file type associations.

## History Management

Enhanced command history integration with PowerShell's built-in history:

### Commands
- `histls` or `Get-PoshixHistory` - View command history
- `rinvoke <id>` or `Invoke-PoshixHistory <id>` - Re-run a command from history
- `hgrep <pattern>` or `Search-PoshixHistory <pattern>` - Search history
- `Clear-PoshixHistory` - Clear history
- `Export-PoshixHistory` - Save history to file
- `Import-PoshixHistory` - Load history from file

History is automatically saved on module unload and loaded on startup.

## Additional Linux-like Commands

### find
Search for files similar to Unix find command
```powershell
find -Name "*.ps1"           # Find all .ps1 files
find -Type d                 # Find all directories
find -Extension .txt         # Find all .txt files
```

### grep
Search for text in files (grep-like functionality)
```powershell
grep "function" . -Include "*.ps1" -Recurse
grep "error" . -Recurse -LineNumber
```

### touch
Create a new file or update timestamp
```powershell
touch newfile.txt            # Create new file
touch existingfile.txt       # Update timestamp
```

### which
Find the path of a command
```powershell
which pwsh                   # Find pwsh executable
which ls                     # Find ls command (shows alias)
```

### pwd
Enhanced print working directory
```powershell
poshpwd                      # Show current directory
Get-WorkingDirectory -Physical  # Show physical path (resolve symlinks)
```

**Note:** The standard `pwd` alias is preserved to maintain PowerShell compatibility. Use `poshpwd` for the enhanced version.

### clear
Clear the screen (unified clear/cls)
```powershell
clear                        # Clear screen
```

## Configuration

### Get Current Configuration
```powershell
Get-PoshixConfig
```

### Customize Colors
```powershell
$config = @{
    Colors = @{
        Directory = 'Cyan'
        ExecutableFile = 'Yellow'
    }
}
Set-PoshixConfig -Config $config
Save-PoshixConfig  # Save to disk
```

### Reset Configuration
```powershell
Reset-PoshixConfig
```

## Module Usage
From the root directory, run:
```powershell
import-module poshix
```

Or for verbose output:
```powershell
import-module poshix -Verbose
```
