# Tab completions for k8s-context plugin

$_kubeContextCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $contexts = & kubectl config get-contexts -o name 2>$null
    if ($LASTEXITCODE -ne 0) { return }

    $contexts | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName 'Invoke-KubeContext' -ParameterName Name -ScriptBlock $_kubeContextCompleter
Register-ArgumentCompleter -CommandName 'kctx'               -ParameterName Name -ScriptBlock $_kubeContextCompleter

$_kubeNamespaceCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $raw = & kubectl get namespaces -o name 2>$null
    if ($LASTEXITCODE -ne 0) { return }

    $namespaces = $raw | ForEach-Object { $_ -replace '^namespace/', '' }

    $namespaces | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName 'Invoke-KubeNamespace' -ParameterName Name -ScriptBlock $_kubeNamespaceCompleter
Register-ArgumentCompleter -CommandName 'kns'                   -ParameterName Name -ScriptBlock $_kubeNamespaceCompleter
