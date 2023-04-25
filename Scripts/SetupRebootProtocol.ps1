<#===========================================================================================================================
Script Name: SetupRebootProtocol.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
Description:
    Create keys to allow reboot by protocol (used by toast button)

Date Created: 17/06/2022
Last Revised: 05/09/2022
===========================================================================================================================#>
# Variables
$Version = "1.1"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"

#===========================================================================================================================
# Creating registry entries for reboot protocol (used in Toast action)
#===========================================================================================================================
# Create protocol for reboot with Toast notification
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  +++ Create protocol for reboot with Toast notification"

$ErrorActionPreference = 'SilentlyContinue'

New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null 
$RegPath = "HKCR:\rebootnow\"
New-Item -Path "$RegPath" -Force
New-ItemProperty -Path "$RegPath" -Name "(Default)" -Value "URL:Reboot Protocol" -PropertyType "String"
New-ItemProperty -Path "$RegPath" -Name "URL Protocol" -Value "" -PropertyType "String"
New-Item -Path "$RegPath\shell\open\command" -Force
$ScriptPath = "$($DestRootPath)\Scripts\Reboot.bat"
New-ItemProperty -Path "$RegPath\shell\open\command" -Name "(Default)" -Value $ScriptPath -PropertyType "String"

# Create the bat script for reboot protocl
Set-Content "$($DestRootPath)\Scripts\Reboot.bat" "REM Batch done by Worplace Teams`r`nREM Cancel previous shutdown scheduled`r`nshutdown /a`r`nREM Then reboot Windows immediatly`r`nshutdown /r /t 0`r`n"

#===========================================================================================================================
# End of SetupRebootProtocol
#===========================================================================================================================
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Setup Reboot Protocol finished" 

# Script done: details on other actions are in the log file
$ReturnCode = 0

# Restore path
Pop-Location

exit $ReturnCode
