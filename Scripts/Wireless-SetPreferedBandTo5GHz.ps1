<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Wireless-SetPreferredBandTo5Ghz.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Script to change the prefered band for all wireless card found to 5GHz instead of Auto of 2.4Ghz
If the wireless card don't have the settings, it's not changing anything.
If the 5GHz is not available, the wireless card used the 2.4GHz: this setting is only a preferred choice.

Reason:
  - By default, there is not prefered band set and Econocom want to user 5GHz band on all site for better performance

It was used in the GPO Wireless-SetPreferedBandTo5GHz applied on all workstations under PROD with WMI filtering for only hardware with battery (like a laptop).

Creation date: 17/02/2022
Modification date: 12/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1.5"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$LogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"
$LogFile = $LogPath + "$($ScriptName)-V$($Version).log"

# Create log file
if(!(Test-Path $LogPath)) { New-Item -ItemType Directory -Force -Path $LogPath }

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"  *>> $LogFile

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Set path in the hive to HKLM:\SYSTEM\CurrentControlSet\Control\Class and recursively search the RoamingPreferredBandType value and set to 2 (5GHz)

Get-ChildItem HKLM:\SYSTEM\CurrentControlSet\Control\Class -Recurse -ErrorAction silentlyContinue | Get-ItemProperty |
ForEach-Object {
    If($_.RoamingPreferredBandType) {
        $path = $_.pspath
        If($_.RoamingPreferredBandType -ne 2) {
            Set-ItemProperty $path -name "RoamingPreferredBandType" -Value "2" *>> $LogFile

            write-output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Set RoamingPreferredBandType to 5GHz on '$($_.DriverDesc)'in Registry path: $path" *>> $LogFile
        } else {
            write-output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : RoamingPreferredBandType already set to 5GHz on '$($_.DriverDesc)'in Registry path: $path" *>> $LogFile
        }
    }
}

#  Restore path
Pop-Location

exit $LastExitCode
