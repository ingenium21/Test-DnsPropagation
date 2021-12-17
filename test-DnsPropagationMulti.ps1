param
(
    [string]$Zone = "contoso.com",
    [string]$ResultsPath = ".\"
)

import-module DnsServer
import-module DnsClient

#Runspace Pool creation
$runspacePool = [RunspaceFactory]::CreateRunspacePool(1,5)
$runspacePool.ApartmentState = "MTA" #apartment state tells threads if they should run synchronously.
$runspacePool.Open()

$codeContainer = {
    param(
        $rec
    )

    $ip = $rec.RecordData.IPv4Address.IPAddressToString
        $recObject = [PSCustomObject] [ordered] @{
            Hostname = $rec.Hostname
            Timestamp = $rec.Timestamp
            TTL = $rec.TimeToLive
            IPAddress = $ip
            State = ((Test-Connection $ip -count 1 -ErrorAction SilentlyContinue).Status -ne "TimedOut")
        }

    return $recObject
}

$threads = @() #empty array that holds different objects that Threads spin up

$records = Get-DnsServerResourceRecord -ZoneName $Zone

foreach ($rec in $records) {

    $runspaceObject = [PSCustomObject]@{
        Runspace = [PowerShell]::Create()
        Invoker = $null
    }
    $runspaceObject.Runspace.RunSpacePool = $runspacePool
    $runspaceObject.Runspace.AddScript($codeContainer) | Out-Null
    $runspaceObject.Runspace.AddArgument($rec) | Out-Null
    $runspaceObject.Invoker = $runspaceObject.Runspace.BeginInvoke()
    $threads += $runspaceObject
}

Write-Host "Runspaces running ..."
Write-Host "All runspaces completed"

$threadResults = @()
Foreach ($t in $threads) {
    $threadResults += $t.Runspace.EndInvoke($t.Invoker)
    $t.Runspace.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()
