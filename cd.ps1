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
        Push-Location $targetPath
        return
    }

    for($i = $dirs.Length - 1; $i -ge 0; $i--) {
        if ($dirs[$i].ToLower().Startswith($targetDir.ToLower())) {
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

    Push-Location $targetPath
}

function Set-FileLocation {
  [CmdletBinding()]
  param ([string] $cdPath)

  if (-not $cdPath) {
    Push-Location $env:USERPROFILE
  } elseif ($cdPath -eq "-") {
    $currentDirectory = $(Get-Location)
    $popDirectory = $(Get-Location)
    $val = 0
    while (($currentDirectory.Path -eq $popDirectory.Path) -and ($val -ne 10)) {
      # keep on popping until we change a directory
      $val++
      Pop-Location
      $popDirectory = $(Get-Location)
    }
  } else {
    Try {
      Push-Location $cdPath -Erroraction Stop
    } Catch [System.Management.Automation.ItemNotFoundException] { #when item doesn't exist
      $globPath = $cdPath + "*" -replace '([^\./\\]+)/|\\','$1*/'
      $cdPossibilities = $(gci "$globPath") | Where-Object {$_.PSisContainer -eq $true}
      if ($cdPossibilities.length -eq 0) {
        Write-Host "No fuzzy matches found" -foregroundcolor Blue
      } elseif ($cdPossibilities.length -eq 1) {
        Push-Location $cdPossibilities.FullName
      } else {
        Write-Host "Multiple fuzzy matches found: [$($cdPossibilities.length)]" -foregroundcolor Blue
        foreach ($f in $cdPossibilities) {
          Write-Verbose $f.FullName
        }
      }
    } Catch {
      Write-Host $_.Exception.Message -ForegroundColor Red
    }
  }
  # z support
  Try {
    Save-CdCommandHistory
  } catch {}
}

Set-Alias -Name cdto -Value Set-LocationTo
Set-Alias -Name .. -Value Set-LocationTo
