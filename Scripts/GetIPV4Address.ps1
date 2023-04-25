<#===========================================================================================================================
Name: GetIPV4Address.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
#----------------------------------------------------------------------------------------------------------------------------
.SYNOPSIS
   Return the IPV4 address found
   If the network is down, wait until network go back until 5 mn (Popup is in study)
.DESCRIPTION

Creation date: 29/04/2022
Modification date: 23/09/2022
===========================================================================================================================#>
# Variables
$Version = "1.5"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$LogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"
$LogFile = $LogPath + "$($ScriptName)-V$($Version).log"

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Create log file
if(!(Test-Path $LogPath)) { New-Item -ItemType Directory -Force -Path $LogPath }

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: Pending..."  *>> $LogFile

# Get IP address
$WaitIP = 10 # secondes
$WaitIPSum = 0
$WaitIPMax = 300 # secondes, 5mn
$IPV4 = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.status -ne "Disconnected"}).IPv4Address.IPAddress

While ($IPV4 -eq $null -AND $WaitIPSum -le $WaitIPMax) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!!  IP not found, retry $($WaitIPSum)s/$($WaitIPMax)s" *>> $LogFile
    $IPV4 = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.status -ne "Disconnected"}).IPv4Address.IPAddress
    Start-Sleep -Seconds $WaitIP
    $WaitIPSum += $WaitIP
}
If($IPV4 -eq $null) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! ERROR !!! IP not found with retry $($WaitIPSum)s/$($WaitIPMax)s !" *>> $LogFile
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> IP: $($IPV4) with retry $($WaitIPSum)s/$($WaitIPMax)s" *>> $LogFile
}

#  Restore path
Pop-Location

Return $IPV4