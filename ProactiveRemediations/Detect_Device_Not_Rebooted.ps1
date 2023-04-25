<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Device_Not_Rebooted.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device has not reboot since a number of days
Beware, it's not working with Fastboot activated

Reference: https://msendpointmgr.com/2020/06/25/endpoint-analytics-proactive-remediations/

Created date: 22/03/2022
Last Revised: 13/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$Version = "18"
$MaxDay = 5
$OS = Get-ComputerInfo
$UptimeDays= $OS.OSUptime.Days

if ($UptimeDays -ge $MaxDay){
    Write-Output "Not compliant: $($UptimeDays) days without reboot, notify user to reboot"
    Exit 1
}else {
    Write-Output "Compliant: $($UptimeDays) days without regboot, all good"
    Exit 0
}