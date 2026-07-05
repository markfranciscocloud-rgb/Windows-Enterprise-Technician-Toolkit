BeforeAll {
    $root = Split-Path -Parent $PSScriptRoot
    $modulePath = Join-Path $root 'Modules/WETT.EventLog.psm1'

    Import-Module $modulePath -Force
}

Describe 'WETT Event Log module' {
    It 'contains the Event Log module file' {
        Test-Path $modulePath | Should -BeTrue
    }

    It 'exports the expected commands' {
        $commands = (Get-Command -Module WETT.EventLog).Name

        $commands | Should -Contain 'Get-WETTEventDescription'
        $commands | Should -Contain 'Get-WETTLogonEvent'
        $commands | Should -Contain 'Show-WETTLogonSummary'
    }

    It 'maps supported event IDs to descriptions' {
        Get-WETTEventDescription -EventId 4624 |
            Should -Be 'Successful logon'

        Get-WETTEventDescription -EventId 4625 |
            Should -Be 'Failed logon'

        Get-WETTEventDescription -EventId 4740 |
            Should -Be 'Account lockout'
    }

    It 'rejects unsupported event IDs' {
        {
            Get-WETTEventDescription -EventId 9999
        } | Should -Throw
    }

    It 'validates the requested time window' {
        {
            Get-WETTLogonEvent -Hours 0
        } | Should -Throw
    }

    It 'returns an empty result when no matching events exist' {
        InModuleScope WETT.EventLog {
            Mock Get-WinEvent {
                throw [System.Exception]::new(
                    'No events were found that match the specified selection criteria.'
                )
            }

            $events = @(
                Get-WETTLogonEvent -Hours 24 -MaxEvents 10
            )

            $events.Count | Should -Be 0
            Should -Invoke Get-WinEvent -Times 1
        }
    }

    It 'is connected to the main launcher' {
        $launcherPath = Join-Path $root 'WETT.ps1'
        $launcher = Get-Content $launcherPath -Raw

        $launcher | Should -Match 'WETT\.EventLog\.psm1'
        $launcher | Should -Match 'Windows logon event triage'
        $launcher | Should -Match 'Show-WETTLogonSummary'
    }
}
