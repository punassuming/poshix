# Register the completion definition shipped by the installed Herdr version.
# ScriptBlock.Create preserves the generator's leading `using namespace`
# declarations, which cannot be evaluated after other statements in this file.
$herdrCommand = Get-Command herdr -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($herdrCommand) {
    try {
        $completionSource = (& $herdrCommand.Source completion powershell 2>$null) -join [Environment]::NewLine
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($completionSource)) {
            throw "herdr completion powershell exited with code $LASTEXITCODE"
        }
        & ([scriptblock]::Create($completionSource))
        Write-Verbose '[poshix-completions] Herdr native completions registered'
    } catch {
        Write-Verbose "[poshix-completions] Herdr completion registration failed: $($_.Exception.Message)"
    }
}
