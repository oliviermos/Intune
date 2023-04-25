<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Proactive_Device_pwdLastSet.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Script to force the detect and remediate device pwdlastset

Reason:
  - The proactive remediation could have enough time to remediate pwd


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
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Hostname: $($Hostname) - Version: $($Version) - Serial Number : $($SerialNumber) - IP: $($IPV4)"  *>> $LogFile

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Detec
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Check password needed..." *>> $LogFile
& "$($DestRootPath)\ProactiveRemediations\Detect_Device_pwdLastSet.ps1" *>> $LogFile
$ReturnCode = $LastExitCode

if($ReturnCode -eq "0") {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : No reset password needed" *>> $LogFile
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Reset password needed !" *>> $LogFile

    # Remediate
    $ReturnRemediate = & "$($DestRootPath)\ProactiveRemediations\Remediate_Device_pwdLastSet.ps1"
    $ReturnCode = $LastExitCode
    $ReturnRemediate *>> $LogFile

    IF($ReturnRemediate.indexof("ERROR")) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Failed !!! Cannot reset password !" *>> $LogFile
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Reset password done" *>> $LogFile
    }
}

#  Restore path
Pop-Location

exit $ReturnCode
