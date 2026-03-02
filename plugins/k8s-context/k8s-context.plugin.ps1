# k8s-context plugin for poshix
# Kubernetes context and namespace management helpers

function Test-KubectlAvailable {
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Warning "[poshix] kubectl is not available in PATH"
        return $false
    }
    return $true
}

function Invoke-KubeContext {
    <#
    .SYNOPSIS
    Show or switch the active kubectl context.
    .DESCRIPTION
    With no arguments, prints the current context name.
    With -Name, switches to the named context.
    With -List, lists all available contexts, marking the current one with *.
    .PARAMETER Name
    The context name to switch to.
    .PARAMETER List
    List all available contexts.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    param(
        [Parameter(ParameterSetName = 'Switch', Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'List')]
        [switch]$List
    )

    if (-not (Test-KubectlAvailable)) { return }

    switch ($PSCmdlet.ParameterSetName) {
        'Current' {
            Write-Verbose "[poshix] Getting current kube context"
            $ctx = & kubectl config current-context 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[poshix] kubectl config current-context failed: $ctx"
                return
            }
            return $ctx
        }
        'Switch' {
            Write-Verbose "[poshix] Switching kube context to '$Name'"
            $result = & kubectl config use-context $Name 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[poshix] kubectl config use-context failed: $result"
                return
            }
            Write-Host "Switched to context: $Name" -ForegroundColor Green
        }
        'List' {
            Write-Verbose "[poshix] Listing kube contexts"
            $current = & kubectl config current-context 2>$null
            $contexts = & kubectl config get-contexts -o name 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[poshix] kubectl config get-contexts failed: $contexts"
                return
            }
            $contexts | ForEach-Object {
                $marker = if ($_ -eq $current) { '*' } else { ' ' }
                [PSCustomObject]@{
                    Current = $marker
                    Name    = $_
                }
            }
        }
    }
}

function Invoke-KubeNamespace {
    <#
    .SYNOPSIS
    Show or set the active namespace for the current kubectl context.
    .DESCRIPTION
    With no arguments, prints the current namespace.
    With -Name, sets the namespace for the current context.
    With -List, lists all namespaces in the current context.
    .PARAMETER Name
    The namespace to set as active.
    .PARAMETER List
    List all namespaces in the current context.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    param(
        [Parameter(ParameterSetName = 'Set', Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'List')]
        [switch]$List
    )

    if (-not (Test-KubectlAvailable)) { return }

    switch ($PSCmdlet.ParameterSetName) {
        'Current' {
            Write-Verbose "[poshix] Getting current kube namespace"
            $ns = & kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[poshix] kubectl config view failed: $ns"
                return
            }
            if ([string]::IsNullOrWhiteSpace($ns)) { $ns = 'default' }
            return $ns
        }
        'Set' {
            Write-Verbose "[poshix] Setting kube namespace to '$Name'"
            $result = & kubectl config set-context --current --namespace=$Name 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[poshix] kubectl config set-context failed: $result"
                return
            }
            Write-Host "Switched to namespace: $Name" -ForegroundColor Green
        }
        'List' {
            Write-Verbose "[poshix] Listing kube namespaces"
            $raw = & kubectl get namespaces -o name 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "[poshix] kubectl get namespaces failed: $raw"
                return
            }
            $raw | ForEach-Object { $_ -replace '^namespace/', '' }
        }
    }
}

function Get-KubeContextInfo {
    <#
    .SYNOPSIS
    Show current Kubernetes context, namespace, and cluster.
    .DESCRIPTION
    Returns an object with Context, Namespace, and Cluster properties and
    displays a formatted summary.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-KubectlAvailable)) { return }

    Write-Verbose "[poshix] Getting kube context info"

    $ctx = & kubectl config current-context 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[poshix] kubectl config current-context failed: $ctx"
        return
    }

    $ns = & kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>&1
    if ([string]::IsNullOrWhiteSpace($ns)) { $ns = 'default' }

    $cluster = & kubectl config view --minify -o jsonpath='{.contexts[0].context.cluster}' 2>&1

    $info = [PSCustomObject]@{
        Context   = $ctx
        Namespace = $ns
        Cluster   = $cluster
    }

    Write-Host "Context:   $ctx"       -ForegroundColor Cyan
    Write-Host "Namespace: $ns"        -ForegroundColor Cyan
    Write-Host "Cluster:   $cluster"   -ForegroundColor Cyan

    return $info
}

function Get-KubePromptInfo {
    <#
    .SYNOPSIS
    Returns a compact string for use in a custom prompt segment.
    .DESCRIPTION
    Returns a string like "⎈ context/namespace", or an empty string if
    kubectl is not available or no context is configured.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { return '' }

    $ctx = & kubectl config current-context 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ctx)) { return '' }

    $ns = & kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>$null
    if ([string]::IsNullOrWhiteSpace($ns)) { $ns = 'default' }

    return "⎈ $ctx/$ns"
}

# Export functions to global scope
Set-Item -Path "function:global:Test-KubectlAvailable" -Value ${function:Test-KubectlAvailable}
Set-Item -Path "function:global:Invoke-KubeContext"    -Value ${function:Invoke-KubeContext}
Set-Item -Path "function:global:Invoke-KubeNamespace"  -Value ${function:Invoke-KubeNamespace}
Set-Item -Path "function:global:Get-KubeContextInfo"   -Value ${function:Get-KubeContextInfo}
Set-Item -Path "function:global:Get-KubePromptInfo"    -Value ${function:Get-KubePromptInfo}

# Export aliases to global scope
Set-Alias -Name kctx  -Value Invoke-KubeContext   -Scope Global
Set-Alias -Name kns   -Value Invoke-KubeNamespace -Scope Global
Set-Alias -Name kinfo -Value Get-KubeContextInfo  -Scope Global

Write-Verbose "[poshix] k8s-context plugin loaded"
