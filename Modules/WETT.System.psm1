Set-StrictMode -Version Latest

function Get-WETTSystemSnapshot {
    [CmdletBinding()]
    param()

    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $computer = Get-CimInstance -ClassName Win32_ComputerSystem
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $gpu = Get-CimInstance -ClassName Win32_VideoController |
        Select-Object Name, DriverVersion, AdapterRAM

    $uptime = (Get-Date) - $os.LastBootUpTime
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' |
        ForEach-Object {
            [pscustomobject]@{
                Drive       = $_.DeviceID
                FileSystem  = $_.FileSystem
                SizeGB      = [math]::Round($_.Size / 1GB, 2)
                FreeGB      = [math]::Round($_.FreeSpace / 1GB, 2)
                FreePercent = if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { 0 }
            }
        }

    [pscustomobject]@{
        Timestamp       = Get-Date
        ComputerName    = $env:COMPUTERNAME
        CurrentUser     = "$env:USERDOMAIN\$env:USERNAME"
        OSCaption       = $os.Caption
        OSVersion       = $os.Version
        BuildNumber     = $os.BuildNumber
        Architecture    = $os.OSArchitecture
        Manufacturer    = $computer.Manufacturer
        Model           = $computer.Model
        SerialNumber    = $bios.SerialNumber
        BIOSVersion     = ($bios.SMBIOSBIOSVersion -join ', ')
        CPU              = $cpu.Name
        LogicalCPUs      = $computer.NumberOfLogicalProcessors
        MemoryGB         = [math]::Round($computer.TotalPhysicalMemory / 1GB, 2)
        LastBoot         = $os.LastBootUpTime
        Uptime           = '{0}d {1}h {2}m' -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        Disks            = @($disks)
        Graphics         = @($gpu)
    }
}

function Show-WETTSystemSnapshot {
    [CmdletBinding()]
    param()

    Show-WETTHeader -Subtitle 'System Snapshot'
    $snapshot = Get-WETTSystemSnapshot

    $snapshot |
        Select-Object Timestamp, ComputerName, CurrentUser, OSCaption, OSVersion,
            BuildNumber, Architecture, Manufacturer, Model, SerialNumber,
            BIOSVersion, CPU, LogicalCPUs, MemoryGB, LastBoot, Uptime |
        Format-List

    Write-Host 'Storage' -ForegroundColor Cyan
    $snapshot.Disks | Format-Table -AutoSize

    Write-Host 'Graphics' -ForegroundColor Cyan
    $snapshot.Graphics |
        Select-Object Name, DriverVersion,
            @{Name='AdapterRAM_GB'; Expression={ if ($_.AdapterRAM) { [math]::Round($_.AdapterRAM / 1GB, 2) } else { 'Unknown' } }} |
        Format-Table -AutoSize
}

Export-ModuleMember -Function @('Get-WETTSystemSnapshot', 'Show-WETTSystemSnapshot')
