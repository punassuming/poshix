# wmi plugin for poshix
# WMI/CIM discovery and query helpers for PowerShell

function Normalize-PoshixWmiNamespace {
    param(
        [string]$Namespace = 'root/cimv2'
    )

    if ([string]::IsNullOrWhiteSpace($Namespace)) {
        return 'root/cimv2'
    }

    return ($Namespace -replace '\\', '/').Trim('/')
}

function Get-PoshixCimBaseParams {
    param(
        [string]$Namespace,
        [string]$ComputerName
    )

    $params = @{}
    if ($Namespace) {
        $params.Namespace = (Normalize-PoshixWmiNamespace -Namespace $Namespace)
    }
    if ($ComputerName) {
        $params.ComputerName = $ComputerName
    }

    return $params
}

function Invoke-PoshixCimOperation {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Operation,

        [Parameter(Mandatory)]
        [string]$Description
    )

    try {
        return & $Operation
    } catch {
        Write-Warning "[poshix] $Description failed: $($_.Exception.Message)"
        return $null
    }
}

function Join-PoshixWmiNamespacePath {
    param(
        [Parameter(Mandatory)]
        [string]$Parent,

        [Parameter(Mandatory)]
        [string]$Child
    )

    $normalizedParent = Normalize-PoshixWmiNamespace -Namespace $Parent
    return "$normalizedParent/$Child"
}

function Test-WmiAvailable {
    [CmdletBinding()]
    param()

    if (-not (Get-Command Get-CimInstance -ErrorAction SilentlyContinue)) {
        Write-Warning "[poshix] CIM cmdlets are not available in this session"
        return $false
    }

    return $true
}

function Get-WmiNamespace {
    <#
    .SYNOPSIS
    List WMI namespaces from a root namespace.
    #>
    [CmdletBinding()]
    param(
        [string]$Namespace = 'root',
        [switch]$Recurse,
        [string]$ComputerName
    )

    if (-not (Test-WmiAvailable)) { return }

    $normalizedNamespace = Normalize-PoshixWmiNamespace -Namespace $Namespace
    $baseParams = Get-PoshixCimBaseParams -Namespace $normalizedNamespace -ComputerName $ComputerName

    $children = Invoke-PoshixCimOperation -Description "WMI namespace discovery for '$normalizedNamespace'" -Operation {
        Get-CimInstance @baseParams -ClassName __Namespace
    }
    if (-not $children) {
        return
    }

    foreach ($child in $children | Sort-Object Name) {
        $childPath = Join-PoshixWmiNamespacePath -Parent $normalizedNamespace -Child $child.Name
        [PSCustomObject]@{
            Name = $child.Name
            Namespace = $childPath
            ParentNamespace = $normalizedNamespace
        }

        if ($Recurse) {
            Get-WmiNamespace -Namespace $childPath -Recurse -ComputerName $ComputerName
        }
    }
}

function Get-WmiClass {
    <#
    .SYNOPSIS
    List WMI classes in a namespace.
    #>
    [CmdletBinding()]
    param(
        [string]$Name = '*',
        [string]$Namespace = 'root/cimv2',
        [switch]$Detailed,
        [string]$ComputerName
    )

    if (-not (Test-WmiAvailable)) { return }

    $baseParams = Get-PoshixCimBaseParams -Namespace $Namespace -ComputerName $ComputerName
    $classes = Invoke-PoshixCimOperation -Description "WMI class discovery for '$Name' in '$Namespace'" -Operation {
        Get-CimClass @baseParams -ClassName $Name
    }
    if (-not $classes) {
        return
    }

    if ($Detailed) {
        return $classes
    }

    return $classes |
        Sort-Object CimClassName |
        Select-Object @{
            Name = 'ClassName'
            Expression = { $_.CimClassName }
        }, @{
            Name = 'Namespace'
            Expression = { $_.CimSystemProperties.Namespace }
        }, @{
            Name = 'SuperClass'
            Expression = { $_.CimSuperClassName }
        }, @{
            Name = 'Properties'
            Expression = { @($_.CimClassProperties).Count }
        }, @{
            Name = 'Methods'
            Expression = { @($_.CimClassMethods).Count }
        }
}

function Get-WmiData {
    <#
    .SYNOPSIS
    Query a WMI class via CIM.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ClassName,

        [string]$Namespace = 'root/cimv2',
        [string]$Filter,
        [string[]]$Property,
        [int]$First,
        [string]$ComputerName
    )

    if (-not (Test-WmiAvailable)) { return }

    $params = Get-PoshixCimBaseParams -Namespace $Namespace -ComputerName $ComputerName
    $params.ClassName = $ClassName
    if ($Filter) {
        $params.Filter = $Filter
    }

    $instances = Invoke-PoshixCimOperation -Description "WMI query for '$ClassName' in '$Namespace'" -Operation {
        Get-CimInstance @params
    }
    if (-not $instances) {
        return
    }

    $results = $instances
    if ($Property -and $Property.Count -gt 0) {
        $results = $results | Select-Object -Property $Property
    }
    if ($First -gt 0) {
        $results = $results | Select-Object -First $First
    }

    return $results
}

function Get-WmiSystemInfo {
    <#
    .SYNOPSIS
    Return a compact system inventory snapshot from WMI.
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName
    )

    if (-not (Test-WmiAvailable)) { return }

    $computerSystem = Get-WmiData -ClassName Win32_ComputerSystem -First 1 -ComputerName $ComputerName
    $operatingSystem = Get-WmiData -ClassName Win32_OperatingSystem -First 1 -ComputerName $ComputerName
    $bios = Get-WmiData -ClassName Win32_BIOS -First 1 -ComputerName $ComputerName
    $processor = Get-WmiData -ClassName Win32_Processor -First 1 -ComputerName $ComputerName

    if (-not $computerSystem -or -not $operatingSystem) {
        return
    }

    return [PSCustomObject]@{
        ComputerName = if ($ComputerName) { $ComputerName } else { $operatingSystem.CSName }
        Manufacturer = $computerSystem.Manufacturer
        Model = $computerSystem.Model
        UserName = $computerSystem.UserName
        Domain = $computerSystem.Domain
        OS = $operatingSystem.Caption
        Version = $operatingSystem.Version
        BuildNumber = $operatingSystem.BuildNumber
        InstallDate = $operatingSystem.InstallDate
        LastBootUpTime = $operatingSystem.LastBootUpTime
        BIOSVersion = if ($bios.SMBIOSBIOSVersion) { $bios.SMBIOSBIOSVersion } else { ($bios.BIOSVersion -join ', ') }
        SerialNumber = $bios.SerialNumber
        Processor = $processor.Name
        LogicalProcessors = $computerSystem.NumberOfLogicalProcessors
        TotalMemoryGB = if ($computerSystem.TotalPhysicalMemory) {
            [math]::Round([double]$computerSystem.TotalPhysicalMemory / 1GB, 2)
        } else {
            $null
        }
    }
}

function Get-WmiProcessInfo {
    <#
    .SYNOPSIS
    List processes from WMI.
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        [int]$First,
        [string]$ComputerName
    )

    $processes = Get-WmiData -ClassName Win32_Process -ComputerName $ComputerName
    if (-not $processes) {
        return
    }

    if ($Name) {
        $processes = $processes | Where-Object { $_.Name -like "*$Name*" }
    }

    $processes = $processes |
        Sort-Object Name, ProcessId |
        Select-Object Name, ProcessId, ParentProcessId, ThreadCount, WorkingSetSize, CommandLine

    if ($First -gt 0) {
        $processes = $processes | Select-Object -First $First
    }

    return $processes
}

function Get-WmiServiceInfo {
    <#
    .SYNOPSIS
    List services from WMI.
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        [ValidateSet('Running', 'Stopped', 'Paused')]
        [string]$State,
        [int]$First,
        [string]$ComputerName
    )

    $services = Get-WmiData -ClassName Win32_Service -ComputerName $ComputerName
    if (-not $services) {
        return
    }

    if ($Name) {
        $services = $services | Where-Object { $_.Name -like "*$Name*" -or $_.DisplayName -like "*$Name*" }
    }
    if ($State) {
        $services = $services | Where-Object { $_.State -eq $State }
    }

    $services = $services |
        Sort-Object State, Name |
        Select-Object Name, DisplayName, State, StartMode, StartName

    if ($First -gt 0) {
        $services = $services | Select-Object -First $First
    }

    return $services
}

function Get-WmiDiskInfo {
    <#
    .SYNOPSIS
    List logical disks from WMI.
    #>
    [CmdletBinding()]
    param(
        [switch]$All,
        [string]$ComputerName
    )

    $disks = Get-WmiData -ClassName Win32_LogicalDisk -ComputerName $ComputerName
    if (-not $disks) {
        return
    }

    if (-not $All) {
        $disks = $disks | Where-Object { $_.DriveType -eq 3 }
    }

    return $disks |
        Sort-Object DeviceID |
        Select-Object DeviceID, VolumeName, DriveType, FileSystem, Size, FreeSpace
}

function Invoke-PoshixWmiProxy {
    [CmdletBinding()]
    param(
        [string]$ComputerName,

        [Parameter(Position = 0)]
        [string]$Subcommand,

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($Subcommand)) {
        return Get-WmiSystemInfo -ComputerName $ComputerName
    }

    switch ($Subcommand.ToLowerInvariant()) {
        'info' {
            return Get-WmiSystemInfo -ComputerName $ComputerName
        }
        'namespaces' {
            $namespace = if ($Arguments.Count -gt 0) { $Arguments[0] } else { 'root' }
            $recurse = $Arguments -contains '--recurse'
            return Get-WmiNamespace -Namespace $namespace -Recurse:$recurse -ComputerName $ComputerName
        }
        'classes' {
            $name = if ($Arguments.Count -gt 0) { $Arguments[0] } else { '*' }
            $namespace = if ($Arguments.Count -gt 1 -and $Arguments[1] -notlike '--*') { $Arguments[1] } else { 'root/cimv2' }
            $detailed = $Arguments -contains '--detailed'
            return Get-WmiClass -Name $name -Namespace $namespace -Detailed:$detailed -ComputerName $ComputerName
        }
        'query' {
            if ($Arguments.Count -eq 0) {
                Write-Warning "[poshix] Usage: wmi query <ClassName> [Namespace]"
                return
            }
            $className = $Arguments[0]
            $namespace = if ($Arguments.Count -gt 1) { $Arguments[1] } else { 'root/cimv2' }
            return Get-WmiData -ClassName $className -Namespace $namespace -ComputerName $ComputerName
        }
        'processes' {
            $name = if ($Arguments.Count -gt 0) { $Arguments[0] } else { $null }
            return Get-WmiProcessInfo -Name $name -ComputerName $ComputerName
        }
        'services' {
            $name = if ($Arguments.Count -gt 0) { $Arguments[0] } else { $null }
            return Get-WmiServiceInfo -Name $name -ComputerName $ComputerName
        }
        'disks' {
            $all = $Arguments -contains '--all'
            return Get-WmiDiskInfo -All:$all -ComputerName $ComputerName
        }
        default {
            Write-Warning "[poshix] Unknown wmi subcommand '$Subcommand'. Use info, namespaces, classes, query, processes, services, or disks."
        }
    }
}

Set-Item -Path "function:global:Normalize-PoshixWmiNamespace" -Value ${function:Normalize-PoshixWmiNamespace}
Set-Item -Path "function:global:Get-PoshixCimBaseParams" -Value ${function:Get-PoshixCimBaseParams}
Set-Item -Path "function:global:Invoke-PoshixCimOperation" -Value ${function:Invoke-PoshixCimOperation}
Set-Item -Path "function:global:Join-PoshixWmiNamespacePath" -Value ${function:Join-PoshixWmiNamespacePath}
Set-Item -Path "function:global:Test-WmiAvailable" -Value ${function:Test-WmiAvailable}
Set-Item -Path "function:global:Get-WmiNamespace" -Value ${function:Get-WmiNamespace}
Set-Item -Path "function:global:Get-WmiClass" -Value ${function:Get-WmiClass}
Set-Item -Path "function:global:Get-WmiData" -Value ${function:Get-WmiData}
Set-Item -Path "function:global:Get-WmiSystemInfo" -Value ${function:Get-WmiSystemInfo}
Set-Item -Path "function:global:Get-WmiProcessInfo" -Value ${function:Get-WmiProcessInfo}
Set-Item -Path "function:global:Get-WmiServiceInfo" -Value ${function:Get-WmiServiceInfo}
Set-Item -Path "function:global:Get-WmiDiskInfo" -Value ${function:Get-WmiDiskInfo}
Set-Item -Path "function:global:wmi" -Value ${function:Invoke-PoshixWmiProxy}

Set-Alias -Name wmiq -Value Get-WmiData -Scope Global
Set-Alias -Name wmiinfo -Value Get-WmiSystemInfo -Scope Global
Set-Alias -Name wmicls -Value Get-WmiClass -Scope Global
Set-Alias -Name wmins -Value Get-WmiNamespace -Scope Global
Set-Alias -Name wmisvc -Value Get-WmiServiceInfo -Scope Global
Set-Alias -Name wmiproc -Value Get-WmiProcessInfo -Scope Global

Write-Verbose "[poshix] wmi plugin loaded"
