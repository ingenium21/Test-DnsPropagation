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
        $recObject
    )
        
        $recObject.State = Test-Connection $recObject.IPAddress -Count 1 -TimeToLive 10 -Quiet

    return $recObject
}

$threads = @() #empty array that holds different objects that Threads spin up

$records = Get-DnsServerResourceRecord -ZoneName $Zone

foreach ($rec in $records) {
    if ($rec.RecordType -eq "A") {
        $ip = $rec.RecordData.IPv4Address.IPAddressToString
        $recObject = [PSCustomObject] [ordered] @{
            Hostname = $rec.Hostname
            Timestamp = $rec.Timestamp
            TTL = $rec.TimeToLive
            IPAddress = $ip
            State = $false
        }
        $runspaceObject = [PSCustomObject]@{
            Runspace = [PowerShell]::Create()
            Invoker = $null
        }
        $runspaceObject.Runspace.RunSpacePool = $runspacePool
        $runspaceObject.Runspace.AddScript($codeContainer) | Out-Null
        $runspaceObject.Runspace.AddArgument($recObject) | Out-Null
        $runspaceObject.Invoker = $runspaceObject.Runspace.BeginInvoke()
        $threads += $runspaceObject
    }
}

Write-Host "Runspaces running ..."
while ($threads.Invoker.IsCompleted -contains $false){}

$threadResults = @()
Foreach ($t in $threads) {
    $threadResults += $t.Runspace.EndInvoke($t.Invoker)
    $t.Runspace.Dispose()
}

$threadResults | ConvertTo-Csv > ($ResultsPath+"results.csv")

Clear-Host
""
Write-Host "All runspaces completed"
""

$total=$threadResults.count
$alive = $($threadResults | ? {$_.State -eq $true}).count
$dead = $($threadResults | ? {$_.State -ne $true}).count

$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 , 5

write-host "   Total Records: " -nonewline -foregroundcolor cyan
$total

write-host "   Alive Records: " -nonewline -foregroundcolor green
$alive

write-host "   Dead Records: " -nonewline -foregroundcolor red
$dead


$runspacePool.Close()
$runspacePool.Dispose()
