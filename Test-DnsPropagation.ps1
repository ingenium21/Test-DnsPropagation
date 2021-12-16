param
(
    [string]$Zone = "Contoso.org",
    [string]$ResultsPath = ".\"
)

import-module DnsServer
import-module DnsClient


function main {
    $Records = Get-DnsServerResourceRecord -ZoneName $Zone
    $global:Successful = New-Object System.Collections.ArrayList
    $global:Failed = New-Object System.Collections.ArrayList

    $script = {
        param ($rec)
        $recData = $Rec.RecordData.IPv4Address.IPAddressToString
        $recObject = New-Object -TypeName PSObject -Property ([Ordered] @{
            'Hostname' = $rec.Hostname
            'RecordType' = $rec.RecordType
            'Timestamp' = $rec.Timestamp
            'TTL' = $rec.TimeToLive
            'IpAddress' = $recData
        })

            if ((Test-Connection $recData -count 1 -ErrorAction SilentlyContinue).Status -ne "TimedOut"){
                write-host -ForegroundColor Green $recObject
                $global:Successful.Add($recObject)
            }
            else {
                write-host -ForegroundColor Red $recOBject
                $global:Failed.Add($recObjec)
            }
    }

    foreach ($Rec in $Records) {
        if ($Rec.RecordType -eq "A"){
            #& $script -rec $Rec
            Start-Job -ScriptBlock $script -InputObject $Rec
            }
        }

    $RunningJobs = (Get-Job | ? {($_.State -eq "Running") -or ($_.State -eq "NotStarted")}).count
    While($runningJobs -ne 0){
        $runningJobs = (Get-Job | ? {($_.State -eq "Running") -or ($_.State -eq "NotStarted")}).count
    }

    $global:Successful | Export-Csv -Path ($ResultsPath + "Successful.csv")
    $global:Successful | Export-Csv -Path ($ResultsPath + "Failed.csv")
}
#Entry point
main
