<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Name: LaunchWindowsUpdate.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Script to launch Windows Update

Creation date: 24/05/2022
Modification date: 15/12/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1.9"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = $DestRootPath
$LogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"
$LogFile = $LogPath + "$($ScriptName)-V$($Version).log"
$TAG = "Done"

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Create log file
if(!(Test-Path $LogPath)) { New-Item -ItemType Directory -Force -Path $LogPath }

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"  *>> $LogFile

# Display OS Version to follow Windows Update work
$OSVersion = (get-wmiobject -class win32_operatingsystem | Select Version).Version
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! OS version: $($OSVersion)"  *>> $LogFile

# Delete file(s) tag and create installing tag
Remove-item "$($DestPath)\$($ScriptName)-V$($Version)-*.tag" -Force *>> $LogFile
Set-Content "$($DestPath)\$($ScriptName)-V$($Version)-InProgress.tag" "In progress..." *>> $LogFile

# Get ESP Status
$ESPStatus = & "$($DestRootPath)\Scripts\CheckESPStatus.ps1"

# ESP return status
$DeviceSetupInProgress = 0
$DeviceSetupComplete = 1
$UserSetupInProgress = 2
$UserSetupComplete = 3
$AutopilotFailed = 4
$NotAutopilot = 5

If ($ESPStatus -ne $DeviceSetupInProgress) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Start Windows Update in user session... not during ESP!"  *>> $LogFile
    
    # Clean registry
    $ErrorActionPreference = 'SilentlyContinue'
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : --- Clean registry!"  *>> $LogFile
    Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate' -Force -Name WUServer  *>> $LogFile
    Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate' -Force -Name TargetGroup  *>> $LogFile
    Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate' -Force -Name WUStatusServer  *>> $LogFile
    Remove-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate' -Force -Name TargetGroupEnable  *>> $LogFile
    Set-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU' -Value 0 -Force -Name UseWUServer  *>> $LogFile
    Set-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU' -Value 0 -Force -Name NoAutoUpdate  *>> $LogFile
    Set-ItemProperty 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'    -Value 0 -force -Name DisableWindowsUpdateAccess  *>> $LogFile
 
    # Restart service to take modification
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Restart Windows Update service"  *>> $LogFile
    Restart-Service -Name wuauserv  *>> $LogFile

    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord  *>> $LogFile
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord  *>> $LogFile

    # Install Nuget provider
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Install Nuget provider"  *>> $LogFile
    Install-PackageProvider -Name Nuget -Force  *>> $LogFile

    # Install Windows Update PS module
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Install Windows Update PS module" *>> $LogFile
    Install-Module -Name PSWindowsUpdate -Force  *>> $LogFile

    # Import module
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Import Windows Update PS module"  *>> $LogFile
    Import-Module PSWindowsUpdate  *>> $LogFile
 
    # list service manager
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Get Windows Update Service manager"  *>> $LogFile
    Get-WUServiceManager  *>> $LogFile

    # Windows update install all and ignore reboot message (only return code): the proactive will display notification.
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Install all update available and do not reboot..."  *>> $LogFile
    
    Install-WindowsUpdate -MicrosoftUpdate -ForceDownload -AcceptAll -Install -IgnoreReboot -Verbose *>> $LogFile
            
            # Help on options: http://woshub.com/pswindowsupdate-module/
            # Autoreboot: reboot immediatly ... impact user's experience: no alert.
            # IgnoreReboot: no reboot even it should be done...
            # ScheduleReboot 16:00 : reboot at 16:00... fixed hour (could be calculate like in the next 8 hours or at the begining of the NWH)

    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Windows Update done!"  *>> $LogFile

    # Check reboot status
    $NeedReboot = Get-WURebootStatus -silent

    if ($NeedReboot) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Reboot is needed!"  *>> $LogFile
        $ReturnCode = 1641
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Reboot not needed."  *>> $LogFile
        $ReturnCode = 0
    }
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! ESP Running, no Windows Update until user session!"  *>> $LogFile
    $ReturnCode = 0
}

# Add file tag with LastExitCode
Remove-item "$($DestPath)\$($ScriptName)-V$($Version)-InProgress.tag" -Force *>> $LogFile
Set-Content "$($DestPath)\$($ScriptName)-V$($Version)-$($TAG).tag" "Return code: $($ReturnCode) `r`n See log file for details: $($LogFile)" *>> $LogFile

#  Restore path
Pop-Location

Exit $ReturnCode
