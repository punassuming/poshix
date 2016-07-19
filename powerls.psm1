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
    $HiddenFiles = $null,
    [Alias('S')]
    [switch]
    $SortSize = $null,
    [Alias('t')]
    [switch]
    $SortTime = $null,
    [Alias('l')]
    [switch]
    $LongListing = $null
  )

  # get the console buffersize
  $BufferWidth = (Get-Host).ui.rawui.buffersize.width

  if ($SortSize -and $SortTime) {
    write-host "Can only include one sorting parameter."
  }

  # get all the files and folders
  if ($HiddenFiles) {
    $Childs = @(Get-ChildItem $lspath)
  }
  else {
    $Childs = @(Get-ChildItem $lspath | Where-Object {$_.Name -notmatch "^\..*$"})
  }

  if ($SortSize) {
    $Childs = @($Childs | Sort-Object -property length)
  } elseif ($SortTime) {
    $Childs = @($Childs | Sort-Object -property LastWriteTime)
  } else {
    $Childs = @($Childs | Sort-Object)
  }

  # get the longest string and get the length
  $LargestLength = ($Childs | % { $_.Name.Length } | Measure-Object -Maximum).Maximum

  # keep track of how long our line is so far
  $CurrentColumn = 0

  # for every element, print the line
  if ($LongListing) {
    Write-Host ("total: {0:n2}K" -f $($($Childs | Measure-Object -property length -sum).sum / 1KB))
  }

  foreach ($e in $Childs) {

    if ($LongListing) {
      write-host ("{0,-6}  {1,22} {2,16} " -f $e.mode,`
        ([String]::Format("{0,10} {1,8}",`
        $e.LastWriteTime.ToString("d"),`
        $e.LastWriteTime.ToString("HH:mm:ss"))),`
        $(Human-FileSize($e))) -nonewline
    }
    $Name = $e.Name

    # determine color we should be printing
    # Blue for folders, Green for files, and Gray for hidden files
    if ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) { #links
      write-host "$Name" -nonewline -foregroundcolor teal
      write-host "@  " -nonewline -foregroundcolor white
    } elseif ($e.PSIsContainer) { #folders
      write-host "$Name" -nonewline -foregroundcolor blue
      write-host "/  " -nonewline -foregroundcolor white
    } elseif ($Name -match "^\..*$") { #hidden files
      write-host "$Name   " -nonewline -foregroundcolor darkgray
    } elseif ($Name -match "\.[^\.]*") { #normal files
      write-host "$Name   " -nonewline -foregroundcolor green
    } else { #others...
      write-host "$Name   " -nonewline -foregroundcolor white
    }
    if ($LongListing) {
      write-host ""
    } else {
      $CurrentColumn += $LargestLength + 3
      if ( $CurrentColumn + $LargestLength + 3 -ge $BufferWidth ) {
        write-host ""
        $CurrentColumn = 0
      } else {
        write-host -nonewline (" " * ($LargestLength - $Name.length))
      }
    }
  }
  if ($CurrentColumn -ne 0) {
    write-host "" # add newline at bottom
  }
}

Function Human-FileSize() {
  Param ($file)
  if(!$file.PSIsContainer) {
    switch($file.length) {
      { $_ -gt 1tb }
      { "{0:n1} T" -f ($_ / 1TB) }
      { $_ -gt 1gb }
      { "{0:n1} G" -f ($_ / 1GB) }
      { $_ -gt 1mb }
      { "{0:n1} M " -f ($_ / 1MB) }
      { $_ -gt 1kb }
      { "{0:n1} K " -f ($_ / 1KB) }
      default
      { "{0:n1} B " -f $_}
    }
  } elseif ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) { #links
    "<SYMLINK> "
  } else { #directory
    "<DIR> "
  }
}

function ls-short { & Get-ChildItem $args | Format-Wide -AutoSize  }
Set-Alias -Name lss -Value ls-short -Force -Option AllScope

Set-Alias -Name ll -Value gci -Force -Option AllScope
# Set-Alias -Name ls -Value PowerLS -Force -Option AllScope

# Set-item alias:ls -Value 'PowerLS'
Set-item alias:ls -Value 'PowerLS'

# Human readable sizes in ls
Update-FormatData -pre $PSScriptRoot/formats/Dir.Format.PS1xml

export-modulemember -function PowerLS -alias ls
