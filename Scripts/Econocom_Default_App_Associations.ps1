<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Econocom_Default_App_Associations.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Description:
Too replace the GPO SET_C_Econocom_Default_App_Associations previously create to fix "Chrome" as defaut".

Script to set default apps based on an export file done by:
   dism /online /Export-DefaultAppAssociations:"C:\EconocomDefaultAppAssociations.xml"

The default application associations file is near this script and push by Intune Kickstart package

Return code:
After applying, the exitcode is the lasterrorcode of DISM: 0 is not error.

Creation date: 17/02/2022
Modification date: 14/10/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1.41"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\Scripts"

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"

# Apply the Econocom default application associations
dism /online /Import-DefaultAppAssociations:"$($DestPath)\EconocomDefaultAppAssociations.xml"

# Restore path
Pop-Location

exit $LASTEXITCODE
