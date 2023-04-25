<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Proactive_Device_SecureChannel.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Script to force the detect and remediate device repair secure channel

Reason:
  - The proactive remediation could have enough time to remediate secure chanel


Creation date: 29/08/2022
Modification date: 12/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1.3"
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

# Detec
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Check password needed..." *>> $LogFile
& "$($DestRootPath)\ProactiveRemediations\Detect_Device_SecureChannel.ps1" *>> $LogFile
$ReturnCode = $LastExitCode

if($ReturnCode -eq "0") {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Secure Channel is ok" *>> $LogFile
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Need to repair secure channel !" *>> $LogFile

    # Remediate
    $ReturnRemediate = & "$($DestRootPath)\ProactiveRemediations\Detect_Device_SecureChannel.ps1"
    $ReturnCode = $LastExitCode
    $ReturnRemediate *>> $LogFile
    
    IF($ReturnRemediate.indexof("ERROR")) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Failed !!! Cannot repair secure channel !" *>> $LogFile
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Repair secure channel done" *>> $LogFile
    }
}

#  Restore path
Pop-Location

exit $ReturnCode
