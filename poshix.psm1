param([switch]$NoVersionWarn = $false)

# if (Get-Module poshix) { return }

Push-Location $psScriptRoot
. .\fileutils.ps1
. .\ls.ps1
. .\cd.ps1
Pop-Location

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

# Human readable sizes in ls
Update-FormatData -pre $PSScriptRoot/formats/Dir.Format.PS1xml

Export-ModuleMember `
  -Alias @(
    'ls',
    'cd',
    '..',
    'cdto'
  ) -Function @(
    'Get-FileListing',
    'Set-FileLocation',
    'Set-LocationTo'
  )
