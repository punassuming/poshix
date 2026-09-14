# Runtime manager

`runtime-manager` is Poshix's conservative runtime and toolchain layer. It discovers local tools first and changes nothing until you explicitly ask it to install or update something.

```powershell
poshix doctor
poshix doctor --json
poshix doctor --plugins
poshix help
poshix env list
poshix env install Git
poshix update --check
```

Diagnostics cover PowerShell, PSReadLine, Git, GitHub CLI availability, Node.js, Python, .NET, Java, Docker, WSL, kubectl, OpenSSH, and installed Poshix agent tools. Authentication is intentionally not probed so Doctor remains local and non-blocking. Docker and WSL reuse their dedicated Poshix health probes, so a CLI that is present but unable to reach its backend is reported as unhealthy rather than available.

`env install` is Windows-oriented and only invokes a package manager after an explicit command (and confirmation when PowerShell requests one). It uses the ordered `PackageManagers` setting, which defaults to `winget`, then `scoop`. Poshix never installs tools, probes Docker synchronously, or contacts GitHub during startup or while running `doctor`; use `poshix update --check` to check for releases.
