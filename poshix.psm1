param([switch]$NoVersionWarn = $false)

# $cdHistory = Join-Path -Path $Env:USERPROFILE -ChildPath '\.cdHistory'

# if (Get-Module poshix) { return }

Push-Location $psScriptRoot
. .\utils.ps1
. .\ls.ps1
. .\cd.ps1
Pop-Location

if (!$Env:HOME) { $Env:HOME = "$Env:HOMEDRIVE$Env:HOMEPATH" }
if (!$Env:HOME) { $Env:HOME = "$Env:USERPROFILE" }

# Human readable sizes in ls
Update-FormatData -pre $PSScriptRoot/formats/Dir.Format.PS1xml


# Saving Previous alias
$orig_cd = $null
$orig_ls = $null
try {
  $orig_cd = (Get-Alias -Name 'cd' -ErrorAction Stop).Definition
} catch {
  # cd alias doesn't exist, use default
  $orig_cd = 'Set-Location'
}
try {
  $orig_ls = (Get-Alias -Name 'ls' -ErrorAction Stop).Definition
} catch {
  # ls alias doesn't exist, use default
  $orig_ls = 'Get-ChildItem'
}

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  set-item alias:cd -value $orig_cd
  set-item alias:ls -value $orig_ls
}


# Writing new alias
Set-item alias:cd -Value 'Set-FileLocation'
Set-item alias:ls -Value 'Get-FileListing'

Export-ModuleMember `
  -Alias @(
    'ls',
    'cd',
    'gls',
    '..',
    'cdto'
  ) -Function @(
    'Get-FileListing',
    'Set-FileLocation',
    'Get-LocationStack',
    'Set-LocationTo'
  )
