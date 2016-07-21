<#
    .Synopsis
        Sets location to the first parent directory that whose name starts with the given target dir.
    .Description
        Searches upwards to the root drive.
        If target dir is not found, a message is emitted to the console
    .Example
        cd c:\user\joeshmoe\Documents
        C:\user\joeshmoe\Documents>
        Set-LocationTo us
        C:\user>
#>
function Set-LocationTo {
    param([string] $targetDir)

    $dirs = (pwd).Path.Split('\')
    if($targetDir -eq '') {
        $targetPath = ''
        for($i = 0; $i -le $dirs.Length -2; $i++) {
            $targetPath += $dirs[$i] + '\'
        }
        Set-Location $targetPath
        return
    }

    for($i = $dirs.Length - 1; $i -ge 0; $i--) {
        if ($dirs[$i].ToLower().StartsWith($targetDir.ToLower())) {
            $targetIndex = $i
            break
        }
    }
    if($targetIndex -eq 0) {
        Write-Host "Unable to resolve $targetDir"
        return
    }

    $targetPath = ''
    for($i = 0; $i -le $targetIndex; $i++) {
       $targetPath += $dirs[$i] + '\'
    }

    Set-Location $targetPath
}

Set-Alias -Name cdto -Value Set-LocationTo
Set-Alias -Name .. -Value Set-LocationTo

function Set-FileLocation {
  param(
    [Parameter(Position=0)]
    [string]$cdPath,
    [Alias('-')]
    [switch]
    $cdBackDir)

  if (-not $cdPath) {
    Push-Location $env:HOMEPATH
  } elseif ($cdBackDir) {
    Pop-Location
  } else {
    Push-Location $cdPath
  }
}

Set-item alias:cd -Value 'Set-FileLocation'
