Set-StrictMode -Version Latest

$script:WETTRoot = $null
$script:WETTLogPath = $null

function Initialize-WETTEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RootPath
    )

    $script:WETTRoot = (Resolve-Path $RootPath).Path
    $logDirectory = Join-Path $script:WETTRoot 'Logs'
    $reportDirectory = Join-Path $script:WETTRoot 'Reports'

    foreach ($directory in @($logDirectory, $reportDirectory)) {
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
    }

    $script:WETTLogPath = Join-Path $logDirectory ("WETT-{0}.log" -f (Get-Date -Format 'yyyyMMdd'))
}

function Write-WETTLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    if (-not $script:WETTLogPath) { return }

    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $script:WETTLogPath -Value $line -Encoding UTF8
}

function Test-WETTAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-WETTHeader {
    [CmdletBinding()]
    param(
        [string]$Subtitle = 'Windows Enterprise Technician Toolkit'
    )

    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '  WETT - Windows Enterprise Technician Toolkit' -ForegroundColor Cyan
    Write-Host "  $Subtitle" -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
}

function Read-WETTContinue {
    [CmdletBinding()]
    param()

    Write-Host ''
    [void](Read-Host 'Press Enter to return to the menu')
}

function Invoke-WETTSafeAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    try {
        Write-WETTLog -Message "Started action: $Name"
        & $Action
        Write-WETTLog -Message "Completed action: $Name"
    }
    catch {
        Write-WETTLog -Message "Action failed: $Name | $($_.Exception.Message)" -Level ERROR
        Write-Host "Action failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-WETTContext {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Version          = '0.1.0'
        RootPath         = $script:WETTRoot
        LogPath          = $script:WETTLogPath
        PowerShell       = $PSVersionTable.PSVersion.ToString()
        RunningAsAdmin   = Test-WETTAdministrator
        ComputerName     = $env:COMPUTERNAME
        CurrentUser      = $env:USERNAME
        SafeMode         = $true
    }
}

function Show-WETTLearningMenu {
    [CmdletBinding()]
    param()

    Show-WETTHeader -Subtitle 'Learning Mode'
    Write-Host '1. System snapshot'
    Write-Host '2. Active TCP connections'
    Write-Host '3. DNS lookup'
    Write-Host '4. Security baseline'
    Write-Host '5. Triage report'
    Write-Host ''
    $topic = Read-Host 'Choose a topic'

    $cards = @{
        '1' = [pscustomobject]@{
            Topic = 'System snapshot'
            Purpose = 'Establish the device identity, operating system, hardware, uptime, and storage baseline.'
            EnterpriseUse = 'Help desk ticket intake, asset inventory, escalation notes, and change validation.'
            KeyCommands = 'Get-CimInstance Win32_OperatingSystem; Get-CimInstance Win32_ComputerSystem'
            Remember = 'Identify the system before changing the system.'
        }
        '2' = [pscustomobject]@{
            Topic = 'Active TCP connections'
            Purpose = 'Show listening and established TCP sessions with their owning processes.'
            EnterpriseUse = 'Investigate unexpected outbound traffic, exposed services, and application connectivity.'
            KeyCommands = 'Get-NetTCPConnection; Get-Process'
            Remember = 'A connection is evidence, not proof of compromise.'
        }
        '3' = [pscustomobject]@{
            Topic = 'DNS lookup'
            Purpose = 'Verify how a hostname resolves and which record types are returned.'
            EnterpriseUse = 'Troubleshoot name resolution, inspect suspicious domains, and validate DNS changes.'
            KeyCommands = 'Resolve-DnsName; nslookup'
            Remember = 'Test DNS separately from general internet connectivity.'
        }
        '4' = [pscustomobject]@{
            Topic = 'Security baseline'
            Purpose = 'Collect Defender, firewall, BitLocker, TPM, Secure Boot, and local administrator status.'
            EnterpriseUse = 'Endpoint posture review and comparison against approved organizational baselines.'
            KeyCommands = 'Get-MpComputerStatus; Get-NetFirewallProfile; Get-BitLockerVolume; Get-Tpm'
            Remember = 'Audit first. Hardening must be tested and approved before enforcement.'
        }
        '5' = [pscustomobject]@{
            Topic = 'Triage report'
            Purpose = 'Preserve a timestamped snapshot of system, network, security, processes, and connections.'
            EnterpriseUse = 'Ticket evidence, incident triage, before-and-after comparisons, and escalation packages.'
            KeyCommands = 'ConvertTo-Json; ConvertTo-Html; Get-FileHash'
            Remember = 'Document time, scope, source, and integrity of collected evidence.'
        }
    }

    if ($cards.ContainsKey($topic)) {
        $cards[$topic] | Format-List
    }
    else {
        Write-Host 'Unknown topic.' -ForegroundColor Yellow
    }
}

Export-ModuleMember -Function @(
    'Initialize-WETTEnvironment',
    'Write-WETTLog',
    'Test-WETTAdministrator',
    'Show-WETTHeader',
    'Read-WETTContinue',
    'Invoke-WETTSafeAction',
    'Get-WETTContext',
    'Show-WETTLearningMenu'
)
