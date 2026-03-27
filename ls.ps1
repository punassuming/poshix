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

  # Get color configuration once for efficiency
  $config = Get-PoshixConfig
  $colors = $config.Colors
  $fileTypes = $config.FileTypes
  $fileNames = if ($config.FileNames) { $config.FileNames } else { @{} }

  # Build lookup tables for O(1) type and exact-name resolution
  $extToColor = @{}
  foreach ($type in $fileTypes.Keys) {
    $colorKey = "${type}File"
    if (-not $colors.ContainsKey($colorKey)) {
      continue
    }

    foreach ($ext in $fileTypes[$type]) {
      if ([string]::IsNullOrWhiteSpace($ext)) {
        continue
      }

      $normalizedExt = $ext.ToString().ToLowerInvariant()
      if (-not $normalizedExt.StartsWith('.')) {
        $normalizedExt = ".${normalizedExt}"
      }

      $extToColor[$normalizedExt] = $colors[$colorKey]
    }
  }

  $nameToColor = @{}
  foreach ($type in $fileNames.Keys) {
    $colorKey = "${type}File"
    if (-not $colors.ContainsKey($colorKey)) {
      continue
    }

    foreach ($name in $fileNames[$type]) {
      if ([string]::IsNullOrWhiteSpace($name)) {
        continue
      }

      $nameToColor[$name.ToString().ToLowerInvariant()] = $colors[$colorKey]
    }
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
      
      $display = Get-PoshixLsDisplayInfo -Item $e -Colors $colors -ExtToColor $extToColor -NameToColor $nameToColor -NoColor:$NoColor
      $color = $display.Color
      $suffix = $display.Suffix
      
      # Print with determined color
      Write-PoshixStyledText -Text $Name -Style $color -NoNewline
      Write-PoshixStyledText -Text $suffix -Style 'White' -NoNewline
      
      # Print symlink target if applicable
      if ($target) {
        Write-PoshixStyledText -Text "-> $target" -Style 'Yellow' -NoNewline
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

function Test-PoshixAnsiStyle {
  param(
    [AllowNull()]
    [string]$Style
  )

  if ([string]::IsNullOrEmpty($Style)) {
    return $false
  }

  return $Style.Contains([string][char]27)
}

function Write-PoshixStyledText {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text,
    [AllowNull()]
    [string]$Style,
    [switch]$NoNewline
  )

  if (Test-PoshixAnsiStyle -Style $Style) {
    $reset = "$([char]27)[0m"
    Write-Host "${Style}${Text}${reset}" -NoNewline:$NoNewline
    return
  }

  if ([string]::IsNullOrWhiteSpace($Style)) {
    Write-Host $Text -NoNewline:$NoNewline
    return
  }

  Write-Host $Text -ForegroundColor $Style -NoNewline:$NoNewline
}

function Test-PoshixExecutableFile {
  param(
    [Parameter(Mandatory = $true)]
    [System.IO.FileSystemInfo]$Item
  )

  if ($Item -is [System.IO.DirectoryInfo]) {
    return $false
  }

  if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
    return $Item.Extension.ToLowerInvariant() -in @('.bat', '.cmd', '.com')
  }

  try {
    return (($Item.UnixFileMode -band [System.IO.UnixFileMode]::UserExecute) -ne 0) -or
      (($Item.UnixFileMode -band [System.IO.UnixFileMode]::GroupExecute) -ne 0) -or
      (($Item.UnixFileMode -band [System.IO.UnixFileMode]::OtherExecute) -ne 0)
  } catch {
    return $Item.Mode -match 'x'
  }
}

function Get-PoshixLsDisplayInfo {
  param(
    [Parameter(Mandatory = $true)]
    [System.IO.FileSystemInfo]$Item,
    [Parameter(Mandatory = $true)]
    [hashtable]$Colors,
    [Parameter(Mandatory = $true)]
    [hashtable]$ExtToColor,
    [Parameter(Mandatory = $true)]
    [hashtable]$NameToColor,
    [switch]$NoColor
  )

  $name = $Item.Name
  $lowerName = $name.ToLowerInvariant()
  $color = 'White'
  $suffix = '   '

  if ($NoColor) {
    return @{
      Color = 'White'
      Suffix = $suffix
    }
  }

  if (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -and ($Item -is [System.IO.DirectoryInfo])) {
    return @{
      Color = $Colors.Symlink
      Suffix = '@  '
    }
  }

  if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    return @{
      Color = $Colors.FileSymlink
      Suffix = '@  '
    }
  }

  if (($name -match "^\..*$") -and ($Item -is [System.IO.DirectoryInfo])) {
    return @{
      Color = $Colors.HiddenDirectory
      Suffix = '/  '
    }
  }

  if ($Item -is [System.IO.DirectoryInfo]) {
    return @{
      Color = if ($NameToColor.ContainsKey($lowerName)) { $NameToColor[$lowerName] } else { $Colors.Directory }
      Suffix = '/  '
    }
  }

  if ($NameToColor.ContainsKey($lowerName)) {
    return @{
      Color = $NameToColor[$lowerName]
      Suffix = $suffix
    }
  }

  if ($name -match "^\..*$") {
    return @{
      Color = $Colors.HiddenFile
      Suffix = $suffix
    }
  }

  $ext = $Item.Extension.ToLowerInvariant()
  if ($ExtToColor.ContainsKey($ext)) {
    $color = $ExtToColor[$ext]
  } elseif (Test-PoshixExecutableFile -Item $Item) {
    $color = $Colors.ExecutableFile
  } elseif ($ext) {
    $color = $Colors.File
  } else {
    $color = $Colors.FileNoExtension
  }

  return @{
    Color = $color
    Suffix = $suffix
  }
}
