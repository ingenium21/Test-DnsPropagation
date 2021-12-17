# Test-DnsPropagation
 tool to true up your DNS A records shows you in the console how many are alive, dead, and total. 
 Spits it all out in a results.csv
 must have DnsServer module installed.
 i only ran this in a DC with the DNS Server feature, so i haven't tested this in a workstation.
 There are two files, one runs sequentially the other runs multithreaded.

# How To Run MultiThreaded
from a powershell console type 
```
.\test-DnsPropagationMulti.ps1 -Zone myDomainZone.org -ResultsPath .\Path\to\dump\file\
```

# How To Run Sequentially
from a powershell console type 
```
.\test-DnsPropagation.ps1 -Zone myDomainZone.org -ResultsPath .\Path\to\dump\file\
```
