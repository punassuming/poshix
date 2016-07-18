<#
  .Synopsis
  Powershell unix-like ls
  Written by Jesse Jurman (JRJurman)

  .Description
  A colorful ls

  .Parameter Lspath
  The path to show

  .Example
  # List the current directory
  PowerLS

  .Example
  # List the parent directory
  PowerLS ../
#>
function PowerLS {
  param(
    [Parameter(Position=0)]
    [string]$lspath = ".",
    [Alias('a')]
    [switch]
    $HiddenFiles = $null
  )
  # write-host "" # add newline at top

  # get the console buffersize
  $buffer = Get-Host
  $bufferwidth = $buffer.ui.rawui.buffersize.width

  # get all the files and folders
  if ($HiddenFiles) {
    $childs = Get-ChildItem $lspath 
  }
  else {
    $childs = Get-ChildItem $lspath -Exclude ".*"
  }

  # get the longest string and get the length
  $lnStr = $childs | select-object Name | sort-object { "$_".length } -descending | select-object -first 1
  $len = $lnStr.name.length

  # keep track of how long our line is so far
  $count = 0

  # extra space to give some breather space
  $breather = 2

  # for every element, print the line
  foreach ($e in $childs) {

    $newName = $e.name + (" "*($len - $e.name.length+$breather))
    $count += $newName.length

    # determine color we should be printing
    # Blue for folders, Green for files, and Gray for hidden files
    if (Test-Path ($lspath + "\" + $e) -pathtype container) { #folders
      write-host $newName -nonewline -foregroundcolor blue
    }
    elseif ($newName -match "^\..*$") { #hidden files
      write-host $newName -nonewline -foregroundcolor darkgray
    }
    elseif ($newName -match "\.[^\.]*") { #normal files
      write-host $newName -nonewline -foregroundcolor green
    }
    else { #others...
      write-host $newName -nonewline -foregroundcolor white
    }

    if ( $count -ge ($bufferwidth - ($len+$breather)) ) {
      write-host ""
      $count = 0
    }

  }

  write-host "" # add newline at bottom
  # write-host "" # add newline at bottom

}


function ls-short { & Get-ChildItem $args | Format-Wide -AutoSize  }
Set-Alias -Name lss -Value ls-short -Force -Option AllScope

Set-Alias -Name ll -Value gci -Force -Option AllScope

Set-item alias:ls -Value 'PowerLS'

# Human readable sizes in ls
Update-FormatData -pre $PSScriptRoot/formats/Dir.Format.PS1xml

export-modulemember -function PowerLS -alias ls
