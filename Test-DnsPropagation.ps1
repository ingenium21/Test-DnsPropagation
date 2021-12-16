param
(
    [string]$Zone = "Contoso.org",
    [string]$ResultsPath = ".\"
)

import-module DnsServer
import-module DnsClient

$threads = 1000 # how many simultanious threads. I've tested up to 1000 ok against ~3600 local IPs, ~900 active.

$Records = Get-DnsServerResourceRecord -ZoneName $Zone

clear

""
write-host "       Threads: " -nonewline -foregroundcolor yellow
$threads
"    Build Pool: "
"    Drain Pool: "
" ---------------------"
write-host "   Total Hosts: $($list.count)"
write-host "   Alive Hosts: "
write-host "    Dead Hosts: "

# BLOCK 1: Create and open runspace pool, setup runspaces array with min and max threads
$pool = [RunspaceFactory]::CreateRunspacePool(1, $threads)
$pool.ApartmentState = "MTA"
$pool.Open()
$runspaces = $results = @()

# --------------------------------------------------
    
# BLOCK 2: Create reusable scriptblock. This is the workhorse of the runspace. Think of it as a function.
$scriptblock = {
    Param (
    [string]$rec
    )
    $ip = $Rec.RecordData.IPv4Address.IPAddressToString
    $recObjet = [PSCustomObject] @{Hostname = $rec.Hostname
        RecordType = $rec.RecordType
        Timestamp = $rec.Timestamp
        TTL = $rec.TimeToLive
        IpAddress = $ip
        State = (Test-Connection $recData -count 1 -ErrorAction SilentlyContinue).Status -ne "TimedOut")
    }
        
    # return whatever you want, or don't.
    return $recObject
}

# --------------------------------------------------
# BLOCK 3: Create runspace and add to runspace pool
$counter=0
foreach ($rec in $Records) {
 
    $runspace = [PowerShell]::Create()
    $null = $runspace.AddScript($scriptblock)
    $null = $runspace.AddArgument($rec)

    $runspace.RunspacePool = $pool
 
# BLOCK 4: Add runspace to runspaces collection and "start" it
    # Asynchronously runs the commands of the PowerShell object pipeline
    $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }

	$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 16 , 2
	$counter++
	write-host "$counter " -nonewline
}

# --------------------------------------------------
 
# BLOCK 5: Wait for runspaces to finish

$total=$counter
$counter=0

# BLOCK 6: Clean up
foreach ($runspace in $runspaces ) {
    # EndInvoke method retrieves the results of the asynchronous call
    $results += $runspace.Pipe.EndInvoke($runspace.Status)
    $runspace.Pipe.Dispose()
	
	$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 16 , 3
	$counter++
	write-host "$($total-$counter) " -nonewline

}
    
$pool.Close() 
$pool.Dispose()

# --------------------------------------------------

# Bonus block 7
# Look at $results to see any errors or whatever was returned from the runspaces

# Use this to output to JSON. CSV works too since it's simple data.
$results | ConvertTo-Csv > ($ResultsPath+"records.csv")

$total=$results.count
$alive = $($results | ? {$_.State -eq "true"}).count
$dead = $($results | ? {$_.State -ne "true"}).count

$Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 , 5

write-host "   Total Records: " -nonewline -foregroundcolor cyan
$total

write-host "   Alive Records: " -nonewline -foregroundcolor green
$alive

write-host "    Dead Records: " -nonewline -foregroundcolor red
$dead

""

$results | ? {$_.State -eq "true"} | select ip,DNS,MAC