param
(
    [string]$Zone = "Contoso.org",
    [string]$ResultsPath = ".\"
)

import-module DnsServer
import-module DnsClient

$results = @()
$Records = Get-DnsServerResourceRecord -ZoneName $Zone

function new-Record ($rec) {
    $ip = $Rec.RecordData.IPv4Address.IPAddressToString
    $recObjet = [PSCustomObject] [ordered] @{
        Hostname = $rec.Hostname
        Timestamp = $rec.Timestamp
        TTL = $rec.TimeToLive
        IPAddress = $ip
        $State = ((Test-Connection $recData -count 1 -ErrorAction SilentlyContinue).Status -ne "TimedOut")
    }   
    # return whatever you want, or don't.
    return $recObject
}

foreach ($rec in $Records) {
    $results += new-Record (rec)
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