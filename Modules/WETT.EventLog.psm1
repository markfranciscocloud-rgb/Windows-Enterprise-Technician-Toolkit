Set-StrictMode -Version Latest

function ConvertFrom-WETTEventXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Diagnostics.Eventing.Reader.EventRecord]$EventRecord
    )

    process {
        [xml]$eventXml = $EventRecord.ToXml()
        $eventData = @{}

        foreach ($item in $eventXml.Event.EventData.Data) {
            if ($item.Name) {
                $eventData[$item.Name] = [string]$item.'#text'
            }
        }

        [pscustomobject]@{
            TimeCreated = $EventRecord.TimeCreated
            EventId     = $EventRecord.Id
            Computer    = $EventRecord.MachineName
            AccountName = $eventData['TargetUserName']
            Domain      = $eventData['TargetDomainName']
            SourceIP    = $eventData['IpAddress']
            Workstation = $eventData['WorkstationName']
            LogonType   = $eventData['LogonType']
            Status      = $eventData['Status']
            SubStatus   = $eventData['SubStatus']
        }
    }
}

function Get-WETTEventDescription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(4624, 4625, 4740)]
        [int]$EventId
    )

    switch ($EventId) {
        4624 { 'Successful logon' }
        4625 { 'Failed logon' }
        4740 { 'Account lockout' }
    }
}

function Get-WETTLogonEvent {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 720)]
        [int]$Hours = 24,

        [ValidateRange(1, 5000)]
        [int]$MaxEvents = 200
    )

    $filter = @{
        LogName   = 'Security'
        Id        = 4624, 4625, 4740
        StartTime = (Get-Date).AddHours(-$Hours)
    }

    try {
        $rawEvents = @(
            Get-WinEvent `
                -FilterHashtable $filter `
                -MaxEvents $MaxEvents `
                -ErrorAction Stop
        )
    }
    catch {
        $noEventsFound =
            $_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*' -or
            $_.Exception.Message -like 'No events were found*'

        if ($noEventsFound) {
            Write-Verbose "No matching Security events were found in the last $Hours hours."
            return
        }

        $accessDenied =
            $_.Exception.Message -match 'access.*denied|unauthorized'

        if ($accessDenied) {
            throw 'Access denied to the Security event log. Run PowerShell as Administrator.'
        }

        throw "Unable to read Security events: $($_.Exception.Message)"
    }

    $rawEvents | ConvertFrom-WETTEventXml
}

function Show-WETTLogonSummary {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 720)]
        [int]$Hours = 24,

        [ValidateRange(1, 5000)]
        [int]$MaxEvents = 200
    )

    $events = @(
        Get-WETTLogonEvent `
            -Hours $Hours `
            -MaxEvents $MaxEvents
    )

    Write-Host ''
    Write-Host "Windows Logon Summary - Last $Hours Hours" -ForegroundColor Cyan
    Write-Host ('=' * 55) -ForegroundColor Cyan

    if ($events.Count -eq 0) {
        Write-Host 'No matching events were found.' -ForegroundColor Yellow
        return
    }

    $events |
        Group-Object EventId |
        ForEach-Object {
            [pscustomobject]@{
                EventId     = [int]$_.Name
                Description = Get-WETTEventDescription -EventId ([int]$_.Name)
                Count       = $_.Count
            }
        } |
        Sort-Object EventId |
        Format-Table -AutoSize

    Write-Host 'Recent events' -ForegroundColor Cyan

    $events |
        Sort-Object TimeCreated -Descending |
        Select-Object -First 25 `
            TimeCreated,
            EventId,
            AccountName,
            Domain,
            SourceIP,
            Workstation,
            LogonType |
        Format-Table -Wrap -AutoSize
}

Export-ModuleMember -Function @(
    'Get-WETTEventDescription',
    'Get-WETTLogonEvent',
    'Show-WETTLogonSummary'
)
