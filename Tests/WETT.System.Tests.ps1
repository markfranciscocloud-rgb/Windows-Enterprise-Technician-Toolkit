
BeforeAll {
    Import-Module (
        Join-Path $PSScriptRoot '..\Modules\WETT.System.psm1'
    ) -Force
}

Describe 'Get-WETTDiskHealth' {

    It 'Warns when free space is below 20%' {
        $disk = [pscustomobject]@{
            Drive = 'T:'
            FreePercent = 9
        }

        $result = Get-WETTDiskHealth -Disks @($disk)

        $result.Status | Should -Be 'WARNING'
    }

    It 'Returns healthy at exactly 20%' {
        $disk = [pscustomobject]@{
            Drive = 'U:'
            FreePercent = 20
        }

        $result = Get-WETTDiskHealth -Disks @($disk)

        $result.Status | Should -Be 'HEALTHY'
    }

    It 'Handles missing free-space information' {
        $disk = [pscustomobject]@{
            Drive = 'V:'
            FreePercent = $null
        }

        $result = Get-WETTDiskHealth -Disks @($disk)

        $result.Status | Should -Be 'UNKNOWN'
    }

    It 'Evaluates multiple disks independently' {
        $disks = @(
            [pscustomobject]@{
                Drive = 'T:'
                FreePercent = 9
            }
            [pscustomobject]@{
                Drive = 'U:'
                FreePercent = 20
            }
            [pscustomobject]@{
                Drive = 'V:'
                FreePercent = $null
            }
        )

        $result = @(Get-WETTDiskHealth -Disks $disks)

        $result.Count | Should -Be 3
        ($result | Where-Object Drive -EQ 'T:').Status |
            Should -Be 'WARNING'
        ($result | Where-Object Drive -EQ 'U:').Status |
            Should -Be 'HEALTHY'
        ($result | Where-Object Drive -EQ 'V:').Status |
            Should -Be 'UNKNOWN'
    }
}