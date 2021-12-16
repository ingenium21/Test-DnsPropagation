param
(
    [string]$Zone = "Contoso.org",
    [string]$ResultsPath = ".\"
)

import-module DnsServer
import-module DnsClient

$results = @()
$Records = Get-DnsServerResourceRecord -ZoneName $Zone


foreach ($rec in $Records) {
    $ip = $Rec.RecordData.IPv4Address.IPAddressToString
    $recObject = [PSCustomObject] [ordered] @{
        Hostname = $rec.Hostname
        Timestamp = $rec.Timestamp
        TTL = $rec.TimeToLive
        IPAddress = $ip
        State = ((Test-Connection $ip -count 1 -ErrorAction SilentlyContinue).Status -ne "TimedOut")
    }

    $results += $recObject
}

$total=$results.count
$alive = $($results | ? {$_.State -eq "true"}).count
$dead = $($results | ? {$_.State-ne "true"}).count

$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 , 5

write-host "   Total Records: " -nonewline -foregroundcolor cyan
$total

write-host "   Alive Records: " -nonewline -foregroundcolor green
$alive

write-host "    Dead Records: " -nonewline -foregroundcolor red
$dead

""

$results | ? {$_.State-ne "true"}