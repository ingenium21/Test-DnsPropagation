param
(
    [string]$Zone = "Contoso.com"
)

import-module DnsServer
import-module DnsClient


function test-Record ($Rec) {
    $recData = $Rec.Data

    $Test = Test-Connection $recData -Ping -Count 1 -TimeoutSeconds 1

    if ($Test.Status -ne "TimedOut"){
        return $true
    }
}


function main {
    $Records = Get-DnsServerResourceRecord -ZoneName $Zone
    $Successful = @()
    $Failed = @()

    $script = {
        if ($rec.RecordType -eq "A"){
            if (test-Record($Rec)){
                $Successful += $Rec
            }
            else {
                $Failed += $Rec
            }
        }
    }
    foreach ($Rec in $Records) {
        Start-ThreadJob -ScriptBlock $script -InputObject $Rec 
        $RunningJobs = (Get-Job | ? {($_.State -eq "Running") -or ($_.State -eq "NotStarted")}).count
        While($runningJobs -ne 0){
            $runningJobs = (Get-Job | ? {($_.State -eq "Running") -or ($_.State -eq "NotStarted")}).count
        }

        Get-Job | Remove-Job
    }

}

#Entry point
main
