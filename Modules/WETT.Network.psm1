Set-StrictMode -Version Latest

function Get-WETTActiveConnections {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 1000)]
        [int]$Limit = 100
    )

    $processMap = @{}
    Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
        $processMap[$_.Id] = $_.ProcessName
    }

    Get-NetTCPConnection -ErrorAction Stop |
        Sort-Object State, RemoteAddress, RemotePort |
        Select-Object -First $Limit LocalAddress, LocalPort, RemoteAddress, RemotePort,
            State, OwningProcess,
            @{Name='ProcessName'; Expression={ $processMap[[int]$_.OwningProcess] }}
}

function Get-WETTNetworkSnapshot {
    [CmdletBinding()]
    param()

    $adapters = Get-NetAdapter -ErrorAction Stop |
        Select-Object Name, InterfaceDescription, Status, LinkSpeed, MacAddress, ifIndex

    $ipConfiguration = Get-NetIPConfiguration -ErrorAction Stop |
        ForEach-Object {
            $ipv4 = if ($_.IPv4Address) { $_.IPv4Address.IPAddress -join ', ' } else { '' }
            $ipv6 = if ($_.IPv6Address) { $_.IPv6Address.IPAddress -join ', ' } else { '' }
            $gateway = if ($_.IPv4DefaultGateway) { $_.IPv4DefaultGateway.NextHop -join ', ' } else { '' }
            $dns = if ($_.DNSServer) { $_.DNSServer.ServerAddresses -join ', ' } else { '' }

            [pscustomobject]@{
                InterfaceAlias = $_.InterfaceAlias
                InterfaceIndex = $_.InterfaceIndex
                IPv4Address    = $ipv4
                IPv6Address    = $ipv6
                IPv4Gateway    = $gateway
                DNSServers     = $dns
            }
        }

    $defaultRoutes = Get-NetRoute -ErrorAction SilentlyContinue |
        Where-Object { $_.DestinationPrefix -in @('0.0.0.0/0', '::/0') } |
        Sort-Object RouteMetric |
        Select-Object DestinationPrefix, NextHop, InterfaceAlias, RouteMetric

    [pscustomobject]@{
        Timestamp       = Get-Date
        Adapters        = @($adapters)
        IPConfiguration = @($ipConfiguration)
        DefaultRoutes   = @($defaultRoutes)
        Connections     = @(Get-WETTActiveConnections -Limit 100)
    }
}

function Show-WETTNetworkSnapshot {
    [CmdletBinding()]
    param()

    Show-WETTHeader -Subtitle 'Network Snapshot'
    $snapshot = Get-WETTNetworkSnapshot

    Write-Host 'Adapters' -ForegroundColor Cyan
    $snapshot.Adapters | Format-Table -AutoSize

    Write-Host 'IP Configuration' -ForegroundColor Cyan
    $snapshot.IPConfiguration | Format-Table -Wrap -AutoSize

    Write-Host 'Default Routes' -ForegroundColor Cyan
    $snapshot.DefaultRoutes | Format-Table -AutoSize
}

function Test-WETTConnectivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Target
    )

    Show-WETTHeader -Subtitle "Connectivity Test: $Target"
    Test-NetConnection -ComputerName $Target -InformationLevel Detailed
}

function Resolve-WETTDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z0-9.-]+$')]
        [string]$Domain
    )

    Show-WETTHeader -Subtitle "DNS Lookup: $Domain"
    if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
        Resolve-DnsName -Name $Domain -ErrorAction Stop |
            Select-Object Name, Type, IPAddress, NameHost, QueryType, TTL |
            Format-Table -AutoSize
    }
    else {
        & nslookup.exe $Domain
    }
}

function Show-WETTActiveConnections {
    [CmdletBinding()]
    param()

    Show-WETTHeader -Subtitle 'Active TCP Connections'
    Get-WETTActiveConnections -Limit 200 | Format-Table -AutoSize
    Write-Host ''
    Write-Host 'Interpretation: investigate unknown processes or destinations, but do not treat one connection as proof of compromise.' -ForegroundColor Yellow
}

Export-ModuleMember -Function @(
    'Get-WETTActiveConnections',
    'Get-WETTNetworkSnapshot',
    'Show-WETTNetworkSnapshot',
    'Test-WETTConnectivity',
    'Resolve-WETTDomain',
    'Show-WETTActiveConnections'
)
