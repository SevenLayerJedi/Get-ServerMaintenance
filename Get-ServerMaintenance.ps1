
function Load-AllModules{
	$fPath = "C:\toolshed\bluecow\lib\"
	$allPSModules = get-childitem $fPath -recurse | where {$_.extension -eq ".psm1"} | % {$_.FullName}

	foreach($psModule in $allPSModules){
		import-module $psModule
	}
}
#Load-AllModules

$fPath = 'C:\temp'
New-Item -ItemType Directory -Force -Path $fPath | out-null
$now = get-date
[string]$report = $fPath + "\" + [system.environment]::MachineName + "_" + $now.ToString("yyyy-MM-dd---hh-mm-ss") + ".log"


#################################################
## Get local disk information                  ##
#################################################

function Get-ComputerName([STRING]$LogFile){
  $computerName = [system.environment]::MachineName
  Write-host ""
  Write-Host " ############"
  Write-Host " ############ $($computerName)"
  Write-Host " ############"
  Write-host ""
  "-$($computerName)" > $LogFile
}

function Get-DriveSpace([STRING]$LogFile){
  Write-host ""
  Write-Host " ##############################################"
  Write-Host " ## .drivespace                              ##"
  Write-Host " ##############################################"
  Write-host ""
  " - Drive Space" >> $LogFile
  $allDrives = get-wmiobject win32_volume | ? { $_.DriveType -eq 3 }
  foreach ($d in $allDrives){
    if ($d.DriveLetter -gt 0){
      $dLetter = $d.DriveLetter
      $dTotalSpace = [MATH]::ROUND(($d.Capacity / 1GB),2)
      $dFreeSpace = [MATH]::ROUND(($d.FreeSpace / 1GB),2)
      $dUsedSpace  = [MATH]::ROUND(($dTotalSpace - $dFreeSpace), 2)
      Write-host " [$($dLetter)] TOTAL: $($dTotalSpace)`tUSED: $($dUsedSpace)`tFREE: $($dFreeSpace)"
      "  - LETTER: $($dLetter) GB" >> $LogFile
      "   - TOTAL: $($dTotalSpace) GB" >> $LogFile
      "   - USED: $($dUsedSpace) GB" >> $LogFile
      "   - FREE: $($dFreeSpace) GB" >> $LogFile
    }
  }
  Write-Host ""
}

#################################################
## Get average cpu load percentage             ##
#################################################


function Get-CPULoad([STRING]$LogFile){
  $cpuLoad = Get-WmiObject -computer $env:COMPUTERNAME -class win32_processor | Measure-Object -property LoadPercentage -Average | Select-Object -ExpandProperty Average
  Write-host ""
  Write-Host " ##############################################"
  Write-Host " ## .CPU                                     ##"
  Write-Host " ##############################################"
  Write-host ""
  Write-Host " [CPU USED] $($cpuLoad)%"
  Write-Host ""
  " - CPU LOAD" >> $LogFile
  "  - $($cpuLoad)%" >> $LogFile
}


#################################################
## Get average memory percentage               ##
#################################################


Function Get-MemoryLoad([STRING]$LogFile){
  $mFree = [math]::round((Get-WmiObject win32_operatingsystem).freephysicalmemory / 1024 / 1024,2)
  $mTotal = [math]::round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1024 / 1024 / 1024,2)
  $mInUse = $mTotal - $mFree
  $memLoad = ($mInUse / $mTotal)*100
  $memLoad = [math]::round($memLoad,2)
  Write-host ""
  Write-Host " ##############################################"
  Write-Host " ## .memory                                  ##"
  Write-Host " ##############################################"
  Write-host ""
  Write-Host " [MEMORY] TOTAL: $($mTotal)`tUSED: $($mInUse)`tFREE: $($mFree)`tPERCENT_USED: $($memLoad)%"
  Write-Host ""
  " - MEM LOAD" >> $LogFile
  "  - TOTAL: $($mTotal) GB" >> $LogFile
  "  - USED: $($mInUse) GB" >> $LogFile
  "  - FREE: $($mFree) GB" >> $LogFile
  "  - PERCENT_USED: $($memLoad)%" >> $LogFile
}

#################################################
## Get application logs                        ##
#################################################


function Get-ApplicationEventLogs([STRING]$LogFile){
  " - Application Logs" >> $LogFile
  $EventAgeDays = 7     #we will take events for the latest 7 days
  $CompArr = @("localhost")   # replace it with your server names
  $LogNames = @("Application")  # Checking app and system logs
  $EventTypes = @("1","2","3")  # Loading only Critical, Errors, and Warnings
  $ExportFolder = "C:\temp\"

  $objArray = @()   #consolidated error log
  $now = get-date
  $startdate = $now.adddays(-$EventAgeDays)
  #$ExportFile = $ExportFolder + "eachEvent" + $now.ToString("yyyy-MM-dd---hh-mm-ss") + ".csv"  # we cannot use standard delimiteds like ":"

  foreach($comp in $CompArr)
  {
    foreach($log in $LogNames)
    {
      Write-Host Processing $comp\$log
      $eachEvent = get-winevent -ComputerName $comp -FilterHashtable @{logname="$log";level=$eventtypes;starttime=$startdate}
      $objArray += $eachEvent  #consolidating
    }
  }
  #sorted = $objArray | Sort-Object TimeGenerated    #sort by time
  $sorted = $objArray | select -First 10 | Sort-Object Id
  Write-host ""
  Write-Host " ##############################################"
  Write-Host " ## .application_logs                        ##"
  Write-Host " ##############################################"
  Write-host ""
  $sorted | Select LevelDisplayName, TimeCreated, ProviderName, ID, MachineName, Message
  $sorted | Select LevelDisplayName, TimeCreated, ProviderName, ID, MachineName, Message >> $LogFile
}

#################################################
## Get system logs                             ##
#################################################


function Get-SystemEventLogs([STRING]$LogFile){
  " - System Logs" >> $LogFile
  $EventAgeDays = 7     #we will take events for the latest 7 days
  $CompArr = @("localhost")   # replace it with your server names
  $LogNames = @("System")  # Checking app and system logs
  $EventTypes = @("1","2","3")  # Loading only Critical, Errors, and Warnings
  $ExportFolder = "C:\temp\"

  $objArray = @()   #consolidated error log
  $now = get-date
  $startdate = $now.adddays(-$EventAgeDays)
  #$ExportFile = $ExportFolder + "eachEvent" + $now.ToString("yyyy-MM-dd---hh-mm-ss") + ".csv"  # we cannot use standard delimiteds like ":"

  foreach($comp in $CompArr)
  {
    foreach($log in $LogNames)
    {
      Write-Host Processing $comp\$log
      $eachEvent = get-winevent -ComputerName $comp -FilterHashtable @{logname="$log";level=$eventtypes;starttime=$startdate}
      $objArray += $eachEvent  #consolidating
    }
  }
  #sorted = $objArray | Sort-Object TimeGenerated    #sort by time
  $sorted = $objArray | select -First 10 | Sort-Object Id
  Write-host ""
  Write-Host " ##############################################"
  Write-Host " ## .system_logs                             ##"
  Write-Host " ##############################################"
  Write-host ""
  $sorted | Select LevelDisplayName, TimeCreated, ProviderName, ID, MachineName, Message
  $sorted | Select LevelDisplayName, TimeCreated, ProviderName, ID, MachineName, Message >> $LogFile
}



#################################################
## Main                                        ##
#################################################


function Get-ServerMaintenance{
Get-ComputerName -LogFile $report
Get-DriveSpace -LogFile $report
Get-CPULoad -LogFile $report
Get-MemoryLoad -LogFile $report
Get-ApplicationEventLogs -LogFile $report
Get-SystemEventLogs -LogFile $report
Invoke-Expression $report
}

Get-ServerMaintenance


