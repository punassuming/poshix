# Tab completions for session-layouts plugin

$_layoutNameCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $layoutsDir = Join-Path $HOME '.poshix' 'layouts'
    if (-not (Test-Path $layoutsDir)) { return }

    Get-ChildItem -Path $layoutsDir -Filter '*.json' -ErrorAction SilentlyContinue |
        ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) } |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Register-ArgumentCompleter -CommandName 'Restore-SessionLayout' -ParameterName Name   -ScriptBlock $_layoutNameCompleter
Register-ArgumentCompleter -CommandName 'layout-restore'        -ParameterName Name   -ScriptBlock $_layoutNameCompleter
Register-ArgumentCompleter -CommandName 'Remove-SessionLayout'  -ParameterName Name   -ScriptBlock $_layoutNameCompleter
Register-ArgumentCompleter -CommandName 'layout-rm'             -ParameterName Name   -ScriptBlock $_layoutNameCompleter
Register-ArgumentCompleter -CommandName 'Add-LayoutBookmark'    -ParameterName Layout -ScriptBlock $_layoutNameCompleter
Register-ArgumentCompleter -CommandName 'bookmark'              -ParameterName Layout -ScriptBlock $_layoutNameCompleter
Register-ArgumentCompleter -CommandName 'Invoke-LayoutBookmark' -ParameterName Layout -ScriptBlock $_layoutNameCompleter
Register-ArgumentCompleter -CommandName 'bm'                    -ParameterName Layout -ScriptBlock $_layoutNameCompleter
