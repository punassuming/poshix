param([switch]$NoVersionWarn = $false)

# if (Get-Module poshix) { return }

Push-Location $psScriptRoot
. .\poshix-ls.ps1
. .\poshix-cd.ps1
Pop-Location

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

Export-ModuleMember `
  -Alias @(
    'ls',
    '..',
    'cdto'
  ) -Function @(
    'Poshix-Ls',
    'Set-LocationTo'
  )
