Set-StrictMode -Version Latest

function New-WETTFullReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RootPath
    )

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $computerName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { 'UnknownComputer' }
    $reportDirectory = Join-Path (Join-Path $RootPath 'Reports') "$computerName-$timestamp"
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null

    $system = Get-WETTSystemSnapshot
    $network = Get-WETTNetworkSnapshot
    $security = Get-WETTSecurityBaseline
    $processes = Get-Process -ErrorAction SilentlyContinue |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 50 ProcessName, Id, CPU,
            @{Name='WorkingSetMB'; Expression={ [math]::Round($_.WorkingSet64 / 1MB, 2) }},
            @{Name='StartTime'; Expression={
                try { $_.StartTime } catch { 'Access denied or unavailable' }
            }}

    $reportObject = [ordered]@{
        Metadata = [ordered]@{
            ToolkitVersion = '0.1.0'
            CollectedAt     = Get-Date
            ComputerName    = $computerName
            CollectedBy     = "$env:USERDOMAIN\$env:USERNAME"
            PowerShell      = $PSVersionTable.PSVersion.ToString()
            Purpose         = 'Authorized local diagnostics and incident triage'
        }
        System    = $system
        Network   = $network
        Security  = $security
        Processes = @($processes)
    }

    $jsonPath = Join-Path $reportDirectory 'WETT-Triage.json'
    $htmlPath = Join-Path $reportDirectory 'WETT-Triage.html'
    $manifestPath = Join-Path $reportDirectory 'SHA256-Manifest.csv'

    $reportObject | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

    $style = @'
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 32px; color: #1f2937; }
h1 { color: #0f4c81; }
h2 { border-bottom: 2px solid #d1d5db; padding-bottom: 4px; margin-top: 28px; }
table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
th, td { border: 1px solid #d1d5db; padding: 7px; text-align: left; vertical-align: top; }
th { background: #eef2f7; }
.notice { padding: 12px; background: #fff7ed; border-left: 4px solid #f59e0b; }
</style>
'@

    $fragments = @()
    $fragments += '<h1>WETT Full Triage Report</h1>'
    $fragments += '<p class="notice">Read-only collection for authorized systems. Findings require analyst validation.</p>'
    $fragments += ($reportObject.Metadata.GetEnumerator() |
        ForEach-Object { [pscustomobject]@{ Field = $_.Key; Value = $_.Value } } |
        ConvertTo-Html -Fragment -PreContent '<h2>Metadata</h2>')
    $fragments += ($system |
        Select-Object Timestamp, ComputerName, CurrentUser, OSCaption, OSVersion,
            BuildNumber, Architecture, Manufacturer, Model, SerialNumber, CPU,
            LogicalCPUs, MemoryGB, LastBoot, Uptime |
        ConvertTo-Html -Fragment -PreContent '<h2>System</h2>')
    $fragments += ($system.Disks | ConvertTo-Html -Fragment -PreContent '<h2>Storage</h2>')
    $fragments += ($network.Adapters | ConvertTo-Html -Fragment -PreContent '<h2>Network Adapters</h2>')
    $fragments += ($network.IPConfiguration | ConvertTo-Html -Fragment -PreContent '<h2>IP Configuration</h2>')
    $fragments += ($network.DefaultRoutes | ConvertTo-Html -Fragment -PreContent '<h2>Default Routes</h2>')
    $fragments += ($network.Connections | ConvertTo-Html -Fragment -PreContent '<h2>TCP Connections</h2>')
    $fragments += ($security.Defender | ConvertTo-Html -Fragment -PreContent '<h2>Microsoft Defender</h2>')
    $fragments += ($security.FirewallProfiles | ConvertTo-Html -Fragment -PreContent '<h2>Firewall Profiles</h2>')
    $fragments += ($security.BitLockerVolumes | ConvertTo-Html -Fragment -PreContent '<h2>BitLocker</h2>')
    $fragments += ($security.LocalAdministrators | ConvertTo-Html -Fragment -PreContent '<h2>Local Administrators</h2>')
    $fragments += ($processes | ConvertTo-Html -Fragment -PreContent '<h2>Top Processes by Memory</h2>')

    ConvertTo-Html -Title 'WETT Full Triage Report' -Head $style -Body ($fragments -join "`n") |
        Set-Content -Path $htmlPath -Encoding UTF8

    Get-FileHash -Algorithm SHA256 -Path $jsonPath, $htmlPath |
        Select-Object Path, Algorithm, Hash |
        Export-Csv -Path $manifestPath -NoTypeInformation -Encoding UTF8

    [pscustomobject]@{
        ReportDirectory = $reportDirectory
        HtmlPath        = $htmlPath
        JsonPath        = $jsonPath
        ManifestPath    = $manifestPath
    }
}

Export-ModuleMember -Function 'New-WETTFullReport'
