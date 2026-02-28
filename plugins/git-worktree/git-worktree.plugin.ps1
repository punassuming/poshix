# git-worktree plugin for poshix
# Provides git worktree management helpers

function Test-GitWorktreePrerequisites {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "[poshix] git is not available in PATH"
        return $false
    }
    $null = & git rev-parse --git-dir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[poshix] Not inside a git repository"
        return $false
    }
    return $true
}

function Get-GitWorktrees {
    <#
    .SYNOPSIS
    List all git worktrees.
    .DESCRIPTION
    Parses 'git worktree list --porcelain' and returns pipeline-friendly objects
    with Path, Branch, HEAD, and IsMain properties.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-GitWorktreePrerequisites)) { return }

    Write-Verbose "[poshix] Listing git worktrees"
    $raw = & git worktree list --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[poshix] git worktree list failed: $raw"
        return
    }

    $worktrees = [System.Collections.Generic.List[PSCustomObject]]::new()
    $current = $null
    $isFirst = $true

    foreach ($line in $raw) {
        if ($line -match '^worktree (.+)$') {
            if ($null -ne $current) { $worktrees.Add($current) }
            $current = [PSCustomObject]@{
                Path   = $Matches[1]
                Branch = $null
                HEAD   = $null
                IsMain = $isFirst
            }
            $isFirst = $false
        } elseif ($line -match '^HEAD ([0-9a-f]+)$') {
            $current.HEAD = $Matches[1]
        } elseif ($line -match '^branch refs/heads/(.+)$') {
            $current.Branch = $Matches[1]
        } elseif ($line -eq 'detached') {
            $current.Branch = '(detached)'
        }
    }
    if ($null -ne $current) { $worktrees.Add($current) }

    return $worktrees
}

function New-GitWorktree {
    <#
    .SYNOPSIS
    Create a new git worktree and cd into it.
    .PARAMETER Branch
    The branch name for the new worktree. Created with -b if it doesn't exist.
    .PARAMETER Path
    The filesystem path for the new worktree. Defaults to ../<branch-name> relative to the repo root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Branch,

        [Parameter()]
        [string]$Path
    )

    if (-not (Test-GitWorktreePrerequisites)) { return }

    if (-not $Path) {
        $repoRoot = & git rev-parse --show-toplevel 2>&1
        $safeName = $Branch -replace '[/\\]', '-'
        $Path = Join-Path (Split-Path $repoRoot -Parent) $safeName
    }

    Write-Verbose "[poshix] Creating worktree at '$Path' for branch '$Branch'"

    # Determine whether the branch already exists
    $null = & git rev-parse --verify $Branch 2>&1
    if ($LASTEXITCODE -eq 0) {
        $result = & git worktree add $Path $Branch 2>&1
    } else {
        $result = & git worktree add -b $Branch $Path 2>&1
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[poshix] git worktree add failed: $result"
        return
    }

    Write-Host "Created worktree at: $Path" -ForegroundColor Green
    Set-Location $Path
}

function Switch-GitWorktree {
    <#
    .SYNOPSIS
    cd into an existing git worktree by branch name or partial path match.
    .PARAMETER Name
    Branch name or partial path of the target worktree.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Test-GitWorktreePrerequisites)) { return }

    Write-Verbose "[poshix] Switching to worktree matching '$Name'"
    $raw = & git worktree list --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[poshix] git worktree list failed: $raw"
        return
    }

    $worktrees = [System.Collections.Generic.List[PSCustomObject]]::new()
    $current = $null
    foreach ($line in $raw) {
        if ($line -match '^worktree (.+)$') {
            if ($null -ne $current) { $worktrees.Add($current) }
            $current = [PSCustomObject]@{ Path = $Matches[1]; Branch = $null }
        } elseif ($line -match '^branch refs/heads/(.+)$') {
            $current.Branch = $Matches[1]
        }
    }
    if ($null -ne $current) { $worktrees.Add($current) }

    # Exact branch match first
    $match = $worktrees | Where-Object { $_.Branch -eq $Name }

    # Wildcard fallback
    if (-not $match) {
        $match = $worktrees | Where-Object { $_.Branch -like "*$Name*" -or $_.Path -like "*$Name*" }
    }

    if (-not $match) {
        Write-Warning "[poshix] No worktree found matching '$Name'"
        return
    }

    if (@($match).Count -gt 1) {
        Write-Warning "[poshix] Ambiguous match for '$Name'. Matching worktrees:"
        $match | ForEach-Object { Write-Host "  $($_.Branch)  ->  $($_.Path)" }
        return
    }

    $target = @($match)[0]
    Write-Verbose "[poshix] Switching to $($target.Path)"
    Set-Location $target.Path
}

function Remove-GitWorktree {
    <#
    .SYNOPSIS
    Remove a git worktree by branch name or path.
    .PARAMETER Path
    Branch name or filesystem path of the worktree to remove.
    .PARAMETER Force
    Pass --force to git worktree remove.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Force
    )

    if (-not (Test-GitWorktreePrerequisites)) { return }

    # Resolve branch name to path if needed
    $resolvedPath = $Path
    if (-not (Test-Path $Path)) {
        $raw = & git worktree list --porcelain 2>&1
        $found = $false
        $current = $null
        foreach ($line in $raw) {
            if ($line -match '^worktree (.+)$') {
                $current = [PSCustomObject]@{ Path = $Matches[1]; Branch = $null }
            } elseif ($line -match '^branch refs/heads/(.+)$') {
                $current.Branch = $Matches[1]
                if ($current.Branch -eq $Path) {
                    $resolvedPath = $current.Path
                    $found = $true
                    break
                }
            }
        }
        if (-not $found) {
            Write-Warning "[poshix] No worktree found for '$Path'"
            return
        }
    }

    Write-Verbose "[poshix] Removing worktree at '$resolvedPath'"
    if ($PSCmdlet.ShouldProcess($resolvedPath, "git worktree remove")) {
        $gitArgs = @('worktree', 'remove')
        if ($Force) { $gitArgs += '--force' }
        $gitArgs += $resolvedPath

        $result = & git @gitArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "[poshix] git worktree remove failed: $result"
            return
        }
        Write-Host "Removed worktree: $resolvedPath" -ForegroundColor Green
    }
}

# Export functions to global scope
Set-Item -Path "function:global:Get-GitWorktrees" -Value ${function:Get-GitWorktrees}
Set-Item -Path "function:global:New-GitWorktree" -Value ${function:New-GitWorktree}
Set-Item -Path "function:global:Switch-GitWorktree" -Value ${function:Switch-GitWorktree}
Set-Item -Path "function:global:Remove-GitWorktree" -Value ${function:Remove-GitWorktree}

# Export aliases to global scope
Set-Alias -Name gwt -Value Get-GitWorktrees -Scope Global
Set-Alias -Name gwt-add -Value New-GitWorktree -Scope Global
Set-Alias -Name gwt-switch -Value Switch-GitWorktree -Scope Global
Set-Alias -Name gwt-rm -Value Remove-GitWorktree -Scope Global

Write-Verbose "[poshix] git-worktree plugin loaded"
