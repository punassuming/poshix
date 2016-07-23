# Poshix
Powershell implementation of common posix commands

If you want to install from a copy of this repo, follow the directions under [module usage](#module usage)

## cd

Change directory implementation similar to zsh

### Features
- Remember directory stack, support `cd -` to go to previous directory
- Allow automatic directory globbing, allowing `cd /u/r/d` to automatically traverse to the common file path
- Go to parent directory, smart traversal to parent with matching text using `..`

## ls

### Features
- Wrapped ls similar to posix
- Colored output based on filetype
- Human readable file size
- Complete listing with `ls -l`
- Show hidden files `ls -a`
- Sort by Extension `-X`, Time `-t`, or Size `-S`, or no sorting with `-U`

### ls Colors

Colored output for symlink, dir, hidden, and files

Right now only does 6 different colors:
- Cyan for Symlinks
- Blue for Directories
- Gray for Hidden files
- Green for Files
- White for files with no extension

## Module Usage
From the root directory, run:
```powershell
import-module poshix
```
