<#===========================================================================================================================
Script Name: Disable_PowerManagement_On_All_Adaptaters.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
Description: Disactive (Wi-fi) or Disable (Ethernet) Power Management on all adaptaters
Date Created: 25/05/2022
Last Revised: 12/09/2022
===========================================================================================================================#>
# Variables
$Version = "1.2"
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
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"  *>> $LogFile

# Default return code
$ReturnCode = 0

# Check all adapters and disable Power Management
Get-NetAdapterPowerManagement -Name "*" | 
foreach {
    If($_.DeviceSleepOnDisconnect -eq "Inactive" -OR $_.DeviceSleepOnDisconnect -eq "Disabled") {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Power Management already Disabled or Inactive on $($_.Name)" *>> $LogFile
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Disable or Unactive Power Management on $($_.Name)" *>> $LogFile
        Disable-NetAdapterPowerManagement -Name $_.Name *>> $LogFile
    }
}

#  Restore path
Pop-Location

exit $ReturnCode