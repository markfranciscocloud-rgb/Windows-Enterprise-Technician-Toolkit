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
                $eventData[$item.Name] = [string]$item.InnerText
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
function Get-WETTPowerShellEvent {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 720)]
        [int]$Hours = 24,

        [ValidateRange(1, 5000)]
        [int]$MaxEvents = 200,

        [switch]$IncludeContent,

        [ValidateRange(80, 2000)]
        [int]$PreviewLength = 240
    )

    $logNames = @(
        'Microsoft-Windows-PowerShell/Operational'
        'PowerShellCore/Operational'
    )

    $availableLogs = @(
        foreach ($logName in $logNames) {
            try {
                $log = Get-WinEvent `
                    -ListLog $logName `
                    -ErrorAction Stop

                if ($log.IsEnabled) {
                    $logName
                }
            }
            catch {
                Write-Verbose "PowerShell log unavailable: $logName"
            }
        }
    )

    if ($availableLogs.Count -eq 0) {
        throw 'No enabled PowerShell operational logs were found.'
    }

    $rawEvents = @(
        foreach ($logName in $availableLogs) {
            try {
                Get-WinEvent `
                    -FilterHashtable @{
                        LogName   = $logName
                        Id        = 4103, 4104
                        StartTime = (Get-Date).AddHours(-$Hours)
                    } `
                    -MaxEvents $MaxEvents `
                    -ErrorAction Stop
            }
            catch {
                $noEventsFound =
                    $_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*' -or
                    $_.Exception.Message -like 'No events were found*'

                if ($noEventsFound) {
                    Write-Verbose "No events found in $logName."
                    continue
                }

                $accessDenied =
                    $_.Exception.Message -match 'access.*denied|unauthorized'

                if ($accessDenied) {
                    throw "Access denied to PowerShell log: $logName"
                }

                throw "Unable to read ${logName}: $($_.Exception.Message)"
            }
        }
    )

    $rawEvents = @(
        $rawEvents |
            Sort-Object TimeCreated -Descending |
            Select-Object -First $MaxEvents
    )

    foreach ($eventRecord in $rawEvents) {
        [xml]$eventXml = $eventRecord.ToXml()
        $eventData = @{}

        foreach ($item in @($eventXml.Event.EventData.Data)) {
            if ($null -ne $item -and $item.Name) {
                $eventData[$item.Name] = [string]$item.InnerText
            }
        }

        $contentText = $null

        if ($IncludeContent) {
            switch ($eventRecord.Id) {
                4103 {
                    $contentText = $eventData['Payload']
                }

                4104 {
                    $contentText = $eventData['ScriptBlockText']
                }
            }
        }

        $contentPreview = $null

        if (-not [string]::IsNullOrWhiteSpace($contentText)) {
            $singleLineContent = (
                $contentText -replace '\s+', ' '
            ).Trim()

            if ($singleLineContent.Length -gt $PreviewLength) {
                $contentPreview =
                    $singleLineContent.Substring(0, $PreviewLength) + '...'
            }
            else {
                $contentPreview = $singleLineContent
            }
        }

        [pscustomobject]@{
            TimeCreated      = $eventRecord.TimeCreated
            EventId          = $eventRecord.Id
            Description      = switch ($eventRecord.Id) {
                4103 { 'PowerShell module logging' }
                4104 { 'PowerShell script block logging' }
            }
            LogName          = $eventRecord.LogName
            ProviderName     = $eventRecord.ProviderName
            Level            = $eventRecord.LevelDisplayName
            RecordId         = $eventRecord.RecordId
            ProcessId        = $eventRecord.ProcessId
            UserId           = [string]$eventRecord.UserId
            ScriptBlockId    = $eventData['ScriptBlockId']
            Path             = $eventData['Path']
            MessageNumber    = $eventData['MessageNumber']
            MessageTotal     = $eventData['MessageTotal']
            ContentAvailable = (
                $eventData.ContainsKey('Payload') -or
                $eventData.ContainsKey('ScriptBlockText')
            )
            ContentPreview   = $contentPreview
        }
    }
}

function Show-WETTPowerShellSummary {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 720)]
        [int]$Hours = 24,

        [ValidateRange(1, 5000)]
        [int]$MaxEvents = 200,

        [switch]$IncludeContent
    )

    $events = @(
        Get-WETTPowerShellEvent `
            -Hours $Hours `
            -MaxEvents $MaxEvents `
            -IncludeContent:$IncludeContent
    )

    Write-Host ''
    Write-Host "PowerShell Event Summary - Last $Hours Hours" `
        -ForegroundColor Cyan
    Write-Host ('=' * 55) -ForegroundColor Cyan

    if ($events.Count -eq 0) {
        Write-Host 'No matching PowerShell events were found.' `
            -ForegroundColor Yellow
        return
    }

    $events |
        Group-Object LogName, EventId |
        ForEach-Object {
            $firstEvent = $_.Group[0]

            [pscustomobject]@{
                LogName     = $firstEvent.LogName
                EventId     = $firstEvent.EventId
                Description = $firstEvent.Description
                Count       = $_.Count
            }
        } |
        Sort-Object LogName, EventId |
        Format-Table -Wrap -AutoSize

    Write-Host 'Recent PowerShell events' -ForegroundColor Cyan

    $events |
        Select-Object -First 25 `
            TimeCreated,
            EventId,
            ProviderName,
            ProcessId,
            Path,
            ScriptBlockId,
            ContentAvailable |
        Format-Table -Wrap -AutoSize

    if ($IncludeContent) {
        Write-Host ''
        Write-Host 'Content previews' -ForegroundColor Yellow

        $events |
            Where-Object ContentPreview |
            Select-Object -First 10 `
                TimeCreated,
                EventId,
                Path,
                ContentPreview |
            Format-List
    }
}

Export-ModuleMember -Function @(
    'Get-WETTEventDescription',
    'Get-WETTLogonEvent',
    'Show-WETTLogonSummary',
    'Get-WETTPowerShellEvent',
    'Show-WETTPowerShellSummary'
)
