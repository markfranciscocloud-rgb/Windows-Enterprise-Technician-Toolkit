Set-StrictMode -Version Latest

function Get-WETTSecurityBaseline {
    [CmdletBinding()]
    param()

    $defender = try {
        Get-MpComputerStatus -ErrorAction Stop |
            Select-Object AntivirusEnabled, AntispywareEnabled, RealTimeProtectionEnabled,
                BehaviorMonitorEnabled, IoavProtectionEnabled, NISEnabled,
                AntivirusSignatureLastUpdated, QuickScanEndTime, FullScanEndTime
    }
    catch {
        [pscustomobject]@{ Status = "Unavailable: $($_.Exception.Message)" }
    }

    $firewall = try {
        Get-NetFirewallProfile -ErrorAction Stop |
            Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction,
                AllowInboundRules, NotifyOnListen
    }
    catch {
        @([pscustomobject]@{ Status = "Unavailable: $($_.Exception.Message)" })
    }

    $bitLocker = try {
        Get-BitLockerVolume -ErrorAction Stop |
            Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionMethod,
                EncryptionPercentage, LockStatus
    }
    catch {
        @([pscustomobject]@{ Status = "Unavailable: $($_.Exception.Message)" })
    }

    $secureBoot = try {
        [pscustomobject]@{ Enabled = [bool](Confirm-SecureBootUEFI -ErrorAction Stop) }
    }
    catch {
        [pscustomobject]@{ Enabled = 'Unavailable or unsupported' }
    }

    $tpm = try {
        Get-Tpm -ErrorAction Stop |
            Select-Object TpmPresent, TpmReady, TpmEnabled, TpmActivated,
                ManufacturerIdTxt, ManufacturerVersion
    }
    catch {
        [pscustomobject]@{ Status = "Unavailable: $($_.Exception.Message)" }
    }

    $localAdministrators = try {
        Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop |
            Select-Object Name, ObjectClass, PrincipalSource
    }
    catch {
        @([pscustomobject]@{ Status = "Unavailable: $($_.Exception.Message)" })
    }

    [pscustomobject]@{
        Timestamp           = Get-Date
        Defender            = $defender
        FirewallProfiles    = @($firewall)
        BitLockerVolumes    = @($bitLocker)
        SecureBoot          = $secureBoot
        TPM                 = $tpm
        LocalAdministrators = @($localAdministrators)
    }
}

function Show-WETTSecurityBaseline {
    [CmdletBinding()]
    param()

    Show-WETTHeader -Subtitle 'Security Baseline Snapshot'
    $baseline = Get-WETTSecurityBaseline

    Write-Host 'Microsoft Defender' -ForegroundColor Cyan
    $baseline.Defender | Format-List

    Write-Host 'Windows Firewall Profiles' -ForegroundColor Cyan
    $baseline.FirewallProfiles | Format-Table -AutoSize

    Write-Host 'BitLocker' -ForegroundColor Cyan
    $baseline.BitLockerVolumes | Format-Table -AutoSize

    Write-Host 'Secure Boot' -ForegroundColor Cyan
    $baseline.SecureBoot | Format-List

    Write-Host 'TPM' -ForegroundColor Cyan
    $baseline.TPM | Format-List

    Write-Host 'Local Administrators' -ForegroundColor Cyan
    $baseline.LocalAdministrators | Format-Table -AutoSize

    Write-Host ''
    Write-Host 'This is an audit snapshot, not an automatic compliance verdict.' -ForegroundColor Yellow
}

Export-ModuleMember -Function @('Get-WETTSecurityBaseline', 'Show-WETTSecurityBaseline')
