# wsl-tmux plugin for poshix
# Launch a WSL tmux session anchored to the current PowerShell directory.
#
# Usage:
#   wtmux                         # open default WSL distro, session "poshix"
#   wtmux -Distribution Ubuntu    # target a specific WSL distro
#   wtmux -Session work           # use a named tmux session (re-attaches if exists)
#   wtmux -NoSync                 # don't update $PWD on return
#
# When the session exits (all panes closed) or the user detaches (Ctrl-B d),
# poshix attempts to sync the last active pane's working directory back to
# PowerShell.  The sync is best-effort: if the final directory has no Windows
# mount equivalent (e.g. /home/user/...) PowerShell stays where it was.

function Enter-WslTmux {
    <#
    .SYNOPSIS
    Open a WSL tmux session in the current directory and return to PowerShell on exit.
    .DESCRIPTION
    Converts the current Windows path to its WSL mount equivalent, starts (or
    re-attaches to) a named tmux session in that directory, and — when tmux exits
    or the user detaches — syncs the final pane's working directory back to
    PowerShell via wslpath.
    .PARAMETER Distribution
    WSL distribution name to use.  Defaults to the system default.
    .PARAMETER Session
    tmux session name.  Re-attaches if a session with this name already exists.
    Defaults to "poshix".
    .PARAMETER NoSync
    Skip the directory-sync step; PowerShell stays in its original directory.
    .EXAMPLE
    wtmux
    .EXAMPLE
    wtmux -Distribution Ubuntu-22.04 -Session dev
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Distribution,

        [Parameter()]
        [string]$Session = "poshix",

        [Parameter()]
        [switch]$NoSync
    )

    # Resolve wsl.exe
    $wslCmd = Get-Command wsl.exe -CommandType Application -ErrorAction SilentlyContinue
    if (-not $wslCmd) {
        Write-Warning "[poshix] wsl-tmux: wsl.exe is not available in PATH"
        return
    }
    $wsl = $wslCmd.Source

    $distroArgs = @()
    if ($Distribution) { $distroArgs = @('-d', $Distribution) }

    # Verify tmux is present in the target WSL environment
    & $wsl @distroArgs -- bash -c "command -v tmux" *>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[poshix] wsl-tmux: tmux is not installed. In WSL run: sudo apt install tmux"
        return
    }

    # Convert the current Windows path to its /mnt/... WSL path
    $wslPath = (& $wsl @distroArgs -- wslpath -u ($PWD.Path) 2>$null).Trim()
    if (-not $wslPath -or $LASTEXITCODE -ne 0) { $wslPath = '~' }

    # Temp file written by the tmux hooks to capture the final pane directory
    $syncFile = "/tmp/.poshix_tmux_sync_$([System.Diagnostics.Process]::GetCurrentProcess().Id)"

    # Build the bash launcher.  Placeholders avoid PowerShell/bash quoting
    # conflicts when crossing the wsl.exe argument boundary.
    # The script is base64-encoded before passing so no shell escaping is needed.
    $launcher = @'
#!/bin/bash
_SYNC='__SYNC__'
_DIR='__DIR__'
_SESSION='__SESSION__'

if tmux has-session -t "$_SESSION" 2>/dev/null; then
    # Re-attach to existing session — keeps directory sync working
    tmux attach-session -t "$_SESSION"
else
    # pane-exited  : fires when a pane's shell exits; records that pane's CWD.
    # client-detached: fires on Ctrl-B d; records the focused pane's CWD.
    # Both hooks write to the same file, so the last event wins.
    _HOOK="run-shell 'printf \"%s\" \"#{pane_current_path}\" > $_SYNC'"
    tmux new-session -c "$_DIR" -s "$_SESSION" \
        \; set-hook -g pane-exited    "$_HOOK" \
        \; set-hook -g client-detached "$_HOOK"
fi
'@
    $launcher = $launcher.Replace('__SYNC__', $syncFile)
    $launcher = $launcher.Replace('__DIR__', $wslPath)
    $launcher = $launcher.Replace('__SESSION__', $Session)

    # Base64-encode so the script survives the PowerShell → wsl.exe → bash boundary
    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($launcher))

    # Block until tmux exits or the user detaches
    & $wsl @distroArgs -- bash -c "printf '%s' '$b64' | base64 -d | bash"

    # Sync the last active pane's directory back to PowerShell (best-effort)
    if (-not $NoSync) {
        $syncedWslPath = (& $wsl @distroArgs -- bash -c "cat '$syncFile' 2>/dev/null; rm -f '$syncFile' 2>/dev/null").Trim()
        if ($syncedWslPath) {
            $winPath = (& $wsl @distroArgs -- wslpath -w "$syncedWslPath" 2>$null).Trim()
            if ($winPath -and (Test-Path $winPath -ErrorAction SilentlyContinue)) {
                Set-Location $winPath
                Write-Host "  $winPath" -ForegroundColor DarkGray
            }
        }
    }
}

Set-Item -Path "function:global:Enter-WslTmux" -Value ${function:Enter-WslTmux}

Set-Alias -Name wtmux -Value Enter-WslTmux -Scope Global

Write-Verbose "[poshix] wsl-tmux plugin loaded"
