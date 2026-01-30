<#
  .Synopsis
  Powershell unix-like ls
  Originally Written by Jesse Jurman (JRJurman)
  Current Implementation by Rich Alesi (ralesi)

  .Description
  A colorful ls

  .Parameter Lspath
  The path to show

  .Example
  # List the current directory
  poshls

  .Example
  # List the parent directory
  poshls ../
#>
function Get-FileListing {
  [CmdletBinding()]
  param(
    [Parameter(Position=0)]
    [string]$lspath = ".",
    [Alias('a')]
    [switch]
    $HiddenFiles = $null,
    [Alias('S')]
    [switch]
    $SortSize = $null,
    [Alias('X')]
    [switch]
    $SortExtension = $null,
    [Alias('t')]
    [switch]
    $SortTime = $null,
    [Alias('U')]
    [switch]
    $NoSort = $null,
    [Alias('l')]
    [switch]
    $LongListing = $null,
    [Alias('la','al')]
    [switch]
    $LongAll = $null,
    [Parameter()]
    [switch]
    $NoColor = $null
  )

  # for testing
  # write-host ($PSCmdlet.MyInvocation | out-string)

  if ($LongAll) {
    $LongListing = $true
    $HiddenFiles = $true
  }

  # get the console buffersize
  $BufferWidth = (Get-Host).ui.rawui.buffersize.width

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
  } elseif ($SortExtension) {
    $Childs = @($Childs | Sort-Object -property Extension)
  } elseif (-not $NoSort){
    $Childs = @($Childs | Sort-Object)
  } else {}

  # get the longest string and get the length
  $LargestLength = ($Childs | % { $_.Name.Length } | Measure-Object -Maximum).Maximum

  # keep track of how long our line is so far
  $CurrentColumn = 0

  # for every element, print the line

  $jlist = $null
  if ($LongListing) {
    Write-Host ("total: {0:n2}K" -f $($($Childs | Where-Object -property length | Measure-Object -property length -sum).sum / 1KB))
    $jlist = junctions
  }


  if ($PSCmdlet.MyInvocation.PipelineLength -gt 1) {

    return $Childs

  } else {

    foreach ($e in $Childs) {

      if ($LongListing) {
        write-host ("{0,-6}  {1,22} {2,16} " -f $e.mode,`
          ([String]::Format("{0,10} {1,8}",`
          $e.LastWriteTime.ToString("d"),`
          $e.LastWriteTime.ToString("HH:mm:ss"))),`
          $(hfs($e))) -nonewline
      }
      $Name = $e.Name

      $target = $null

      foreach ($j in $jlist) {
        if ($j[0] -eq $e.Name) {
          $target = $j[1]
        }
      }
      
      # Get color configuration
      $config = Get-PoshixConfig
      $colors = $config.Colors
      $fileTypes = $config.FileTypes
      
      # Determine file type and color
      $color = 'White'
      $suffix = '   '
      
      if ($NoColor) {
        $color = 'White'
      } elseif (($e.Attributes -band [IO.FileAttributes]::ReparsePoint) -and ($e -is [System.IO.DirectoryInfo])) {
        # dir links
        $color = $colors.Symlink
        $suffix = '@  '
      } elseif ($e.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        # file links
        $color = $colors.FileSymlink
        $suffix = '@  '
      } elseif (($Name -match "^\..*$") -and ($e -is [System.IO.DirectoryInfo])) {
        # hidden folders
        $color = $colors.HiddenDirectory
        $suffix = '/  '
      } elseif ($e -is [System.IO.DirectoryInfo]) {
        # folders
        $color = $colors.Directory
        $suffix = '/  '
      } elseif ($Name -match "^\..*$") {
        # hidden files
        $color = $colors.HiddenFile
      } else {
        # Determine file type by extension
        $ext = $e.Extension.ToLower()
        $fileType = $null
        
        foreach ($type in $fileTypes.Keys) {
          if ($fileTypes[$type] -contains $ext) {
            $fileType = $type
            break
          }
        }
        
        if ($fileType -and $colors.ContainsKey("${fileType}File")) {
          $color = $colors["${fileType}File"]
        } elseif ($ext) {
          $color = $colors.File
        } else {
          $color = $colors.FileNoExtension
        }
      }
      
      # Print with determined color
      write-host "$Name" -nonewline -foregroundcolor $color
      write-host $suffix -nonewline -foregroundcolor white
      
      # Print symlink target if applicable
      if ($target) {
        write-host "-> $target" -nonewline -foregroundcolor yellow
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
}
