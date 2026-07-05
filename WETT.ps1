#requires -Version 5.1
<#+
.SYNOPSIS
    Windows Enterprise Technician Toolkit (WETT) console launcher.
.DESCRIPTION
    A safe-by-default Windows diagnostics and cybersecurity learning toolkit.
    Version 0.1.0 focuses on read-only system, network, and security collection.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
    Write-Error 'WETT currently supports Windows only.'
    exit 1
}

$moduleRoot = Join-Path $PSScriptRoot 'Modules'
$moduleFiles = @(
    'WETT.Core.psm1',
    'WETT.System.psm1',
    'WETT.Network.psm1',
    'WETT.Security.psm1',
    'WETT.EventLog.psm1',
    'WETT.Reporting.psm1'
)

try {
    foreach ($moduleFile in $moduleFiles) {
        Import-Module (Join-Path $moduleRoot $moduleFile) -Force -ErrorAction Stop
    }

    Initialize-WETTEnvironment -RootPath $PSScriptRoot
    Write-WETTLog -Message "Toolkit started by $env:USERNAME on $env:COMPUTERNAME."
}
catch {
    Write-Error "WETT failed to initialize: $($_.Exception.Message)"
    exit 1
}

function Show-MainMenu {
    Show-WETTHeader -Subtitle 'Safe Diagnostics and Security Learning'
    Write-Host '  1. System snapshot'
    Write-Host '  2. Network snapshot'
    Write-Host '  3. Connectivity test'
    Write-Host '  4. DNS lookup'
    Write-Host '  5. Active TCP connections'
    Write-Host '  6. Security baseline snapshot'
    Write-Host '  7. Generate full triage report'
    Write-Host '  8. Learning mode'
    Write-Host '  9. Show toolkit status'
    Write-Host ' 10. Windows logon event triage'
    Write-Host ' 11. PowerShell event triage'
    Write-Host '  0. Exit'
    Write-Host ''
}

$running = $true
while ($running) {
    Show-MainMenu
    $choice = Read-Host 'Choose an option'

    switch ($choice) {
        '1' {
            Invoke-WETTSafeAction -Name 'System snapshot' -Action {
                Show-WETTSystemSnapshot
            }
            Read-WETTContinue
        }
        '2' {
            Invoke-WETTSafeAction -Name 'Network snapshot' -Action {
                Show-WETTNetworkSnapshot
            }
            Read-WETTContinue
        }
        '3' {
            $target = Read-Host 'Target hostname or IP [1.1.1.1]'
            if ([string]::IsNullOrWhiteSpace($target)) { $target = '1.1.1.1' }
            Invoke-WETTSafeAction -Name "Connectivity test: $target" -Action {
                Test-WETTConnectivity -Target $target
            }
            Read-WETTContinue
        }
        '4' {
            $domain = Read-Host 'Domain to resolve [www.microsoft.com]'
            if ([string]::IsNullOrWhiteSpace($domain)) { $domain = 'www.microsoft.com' }
            Invoke-WETTSafeAction -Name "DNS lookup: $domain" -Action {
                Resolve-WETTDomain -Domain $domain
            }
            Read-WETTContinue
        }
        '5' {
            Invoke-WETTSafeAction -Name 'Active TCP connections' -Action {
                Show-WETTActiveConnection
            }
            Read-WETTContinue
        }
        '6' {
            Invoke-WETTSafeAction -Name 'Security baseline snapshot' -Action {
                Show-WETTSecurityBaseline
            }
            Read-WETTContinue
        }
        '7' {
            Invoke-WETTSafeAction -Name 'Full triage report' -Action {
                $report = Export-WETTFullReport -RootPath $PSScriptRoot
                Write-Host ''
                Write-Host "Report created: $($report.ReportDirectory)" -ForegroundColor Green
                Write-Host "HTML: $($report.HtmlPath)"
                Write-Host "JSON: $($report.JsonPath)"
            }
            Read-WETTContinue
        }
        '8' {
            Show-WETTLearningMenu
            Read-WETTContinue
        }
        '9' {
            $context = Get-WETTContext
            Show-WETTHeader -Subtitle 'Toolkit Status'
            $context | Format-List
            Read-WETTContinue
        }
        '10' {
    Invoke-WETTSafeAction -Name 'Windows logon event triage' -Action {
        Show-WETTLogonSummary -Hours 24 -MaxEvents 500
    }
    Read-WETTContinue
}
'11' {
    Invoke-WETTSafeAction -Name 'PowerShell event triage' -Action {
        Show-WETTPowerShellSummary -Hours 24 -MaxEvents 500
    }
    Read-WETTContinue
}
        '0' {
            Write-WETTLog -Message 'Toolkit closed normally.'
            $running = $false
        }
        default {
            Write-Host 'Invalid choice. Enter 0-11.' -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}

