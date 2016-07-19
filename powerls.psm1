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

  # get the console buffersize
    $BufferWidth = (Get-Host).ui.rawui.buffersize.width

  # get all the files and folders
  if ($HiddenFiles) {
    $Childs = @(Get-ChildItem $lspath | Sort-Object) 
  }
  else {
    $Childs = @(Get-ChildItem $lspath | Where-Object {$_.Name -notmatch "^\..*$"} | Sort-Object)
  }

  # get the longest string and get the length
    $LargestLength = ($Childs | % { $_.Name.Length } | Measure-Object -Maximum).Maximum

  # keep track of how long our line is so far
    $CurrentColumn = 0

  # for every element, print the line
    foreach ($e in $Childs) {
      $Name = $e.Name

    # determine color we should be printing
    # Blue for folders, Green for files, and Gray for hidden files
      if ($e.PSIsContainer) { #folders
        write-host "$Name/  " -nonewline -foregroundcolor blue
      } elseif ($Name -match "^\..*$") { #hidden files
        write-host "$Name   " -nonewline -foregroundcolor darkgray
      } elseif ($Name -match "\.[^\.]*") { #normal files
        write-host "$Name   " -nonewline -foregroundcolor green
      } else { #others...
        write-host "$Name   " -nonewline -foregroundcolor white
    }
      $CurrentColumn += $LargestLength + 3

      if ( $CurrentColumn + $LargestLength + 3 -ge $BufferWidth ) {
      write-host ""
        $CurrentColumn = 0
      } else {
        write-host -nonewline (" " * ($LargestLength - $Name.length))
    }
  }
    if ($CurrentColumn -ne 0) {
  write-host "" # add newline at bottom
}
}


function ls-short { & Get-ChildItem $args | Format-Wide -AutoSize  }
Set-Alias -Name lss -Value ls-short -Force -Option AllScope

Set-Alias -Name ll -Value gci -Force -Option AllScope

Set-item alias:ls -Value 'PowerLS'

# Human readable sizes in ls
Update-FormatData -pre $PSScriptRoot/formats/Dir.Format.PS1xml

export-modulemember -function PowerLS -alias ls
