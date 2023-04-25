<#===========================================================================================================================
Script Name: SetupNetworkForWindows.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
Description:
    Remove old Wifi profiles
    Setup Network for Windows: no IPV6, disable power management, 5GHz prefered, Proxy
    Tasks scheduled: enable history and set automatic task for proxy/ipv6/Power/5GHz
    Tasks scheduled: Add FW rules for Teams @ Login
    Task scheduled: Reset device pwdlastset, repair secure channel

Date Created: 07/02/2022
Last Revised: 02/11/2022
===========================================================================================================================#>
# Variables
$Version = "1.5"
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
# Disable IE first launch to permit to use invoke-webrequest
#===========================================================================================================================
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : --- Disable IE first launch to permit to use invoke-webrequest if not already done..."
$keyPath = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main'
If (!(Test-Path $keyPath)) { New-Item $keyPath -Force }
Set-ItemProperty -Path $keyPath -Name "DisableFirstRunCustomize" -Value 1

#===========================================================================================================================
# Check ESP Running : not necessary to remove old wifi profile during ESP and for MTR profile
#===========================================================================================================================
# ESP return status
$ESPRunning = 0
$ESPComplete = 1
$AutopilotFailed = 2
$NotAutopilot = 3

$ESPStatus = & ".\CheckESPStatus.ps1"

If ($ESPStatus -eq $ESPRunning) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! Warning !!! In ESP, don't need to remove old wifi profiles!"
} else {
    # Check profile file
    # default: autopilot, Intra legacy
    # MTR: nothing to do
    $ProfileName = Resolve-Path "$($DestRootPath)\*.Profile" | Split-Path -leaf
    $Profile = $ProfileName.Substring(0, $ProfileName.IndexOf("."))

    If ($Profile -ne "MTR") {
        # Remove old Wi-fi profile (Dev, Pilot, Prod, etc.)

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  --- Remove Wifi profile 'ECO_MOBILE'" # Removed: see communication from DSI in 20-07-2020
        .\DeleteWifiProfileByName.ps1 -Name "ECO_MOBILE"

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  --- Remove Wifi profile 'Econocom ECO_PROD" # old intune profile version (Q4 2021)
        .\DeleteWifiProfileByName.ps1 -Name "Econocom ECO_PROD"

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  --- Remove Wifi profile 'ECO_PROD (Intune User... all versions" #old pilot for new Wifi: the new name is ECO-WIFI (15/03/2022)
        .\DeleteWifiProfileByName.ps1 -Name "ECO_PROD (Intune User*"

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  --- Remove Wifi profile 'ECO_PILOT all versions" #old pilot for new Wifi: the new name is ECO-WIFI (15/03/2022)
        .\DeleteWifiProfileByName.ps1 -Name "ECO_PILOT*"

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  --- Remove Wifi profile 'ECO-WIFI (Intune Mach PIL V2.X) all versions" #old pilot for new Wifi ECO-WIFI (15/03/2022)
        .\DeleteWifiProfileByName.ps1 -Name "ECO-WIFI (Intune Mach*"

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  --- Remove Wifi profile 'ECO-WIFI (Intune AAD DEV V1.X) all versions" #old pilot for new Wifi ECO-WIFI (15/03/2022)
        .\DeleteWifiProfileByName.ps1 -Name "ECO-WIFI (Intune AAD*"

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  --- Remove Wifi profile 'ECO-WIFI (Intune Hyb PIL V1.x) all versions" #old pilot for new Wifi ECO-WIFI (08/04/2022)
        .\DeleteWifiProfileByName.ps1 -Name "ECO-WIFI (Intune Hyb PIL*"

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  --- Remove Wifi profile 'ECO-WIFI (Intune User PIL V1.X) all versions" #old pilot for new Wifi ECO-WIFI (08/04/2022)
        .\DeleteWifiProfileByName.ps1 -Name "ECO-WIFI (Intune User PIL*"
    } #End of Profile "not MTR"

}

#===========================================================================================================================
# Setup Windows: no IPV6, 5GHz prefered, Proxy
#===========================================================================================================================

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : --- Disable IPV6 on all adaptaters"
.\Disable_IPV6_On_All_Adaptaters.ps1

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : --- Disable PowerManagement On All Adaptaters"
.\Disable_PowerManagement_On_All_Adaptaters.ps1

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Set preferred band to 5GHz if possible"
.\Wireless-SetPreferedBandTo5GHz.ps1

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Set Econocom proxy if necessary"
.\SetEconocomProxy.ps1

#===========================================================================================================================
# Tasks scheduled: enable history and set automatic task for proxy/ipv6/Power/5GHz
#===========================================================================================================================

wevtutil set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true

# Delete old task if existing
$OldTaskName = "ChangeSystemProxyWhenNetworkChanged"
if ($(Get-ScheduledTask -TaskName "$($OldTaskName)" -ErrorAction SilentlyContinue).TaskName -eq "$($OldTaskName)") {
    Unregister-ScheduledTask -TaskName "$($OldTaskName)" -Confirm:$False
}

# Create Scheduled task to automatically change proxy for system when network connect/disconnect (pulse included)
$TaskName = "RemediateNetworkAdaptater"

# Delete task to update if existing
if ($(Get-ScheduledTask -TaskName "$($TaskName)" -ErrorAction SilentlyContinue).TaskName -eq "$($TaskName)") {
    Unregister-ScheduledTask -TaskName "$($TaskName)" -Confirm:$False
}

# Actions list
$Actions = @()

# Disable IPV6 if necessary
$ActionParameters = @{
    Execute  = "powershell.exe"
    Argument = "-executionpolicy bypass -command $($DestRootPath)\Scripts\Disable_IPV6_On_All_Adaptaters.ps1"
}
$Actions += New-ScheduledTaskAction @ActionParameters
    
# Disable PowerManagement if necessary
$ActionParameters = @{
    Execute  = "powershell.exe"
    Argument = "-executionpolicy bypass -command $($DestRootPath)\Scripts\Disable_PowerManagement_On_All_Adaptaters.ps1"
}
$Actions += New-ScheduledTaskAction @ActionParameters
    
# Set Preferred band 5GHz if possible
$ActionParameters = @{
    Execute  = "powershell.exe"
    Argument = "-executionpolicy bypass -command $($DestRootPath)\Scripts\Wireless-SetPreferedBandTo5GHz.ps1"
}
$Actions += New-ScheduledTaskAction @ActionParameters
    
# Set Econocom proxy if found
$ActionParameters = @{
    Execute  = "powershell.exe"
    Argument = "-executionpolicy bypass -command $($DestRootPath)\Scripts\SetEconocomProxy.ps1"
}
$Actions += New-ScheduledTaskAction @ActionParameters

# Proactive device pwdlastset
$ActionParameters = @{
    Execute  = "powershell.exe"
    Argument = "-executionpolicy bypass -command $($DestRootPath)\Scripts\Proactive_Device_pwdLastSet.ps1"
}
$Actions += New-ScheduledTaskAction @ActionParameters

# Proactive device SecureChannel
$ActionParameters = @{
    Execute  = "powershell.exe"
    Argument = "-executionpolicy bypass -command $($DestRootPath)\Scripts\Proactive_Device_SecureChannel.ps1"
}
$Actions += New-ScheduledTaskAction @ActionParameters

# Task account service
$Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest

# Settings
$Params = @{
    "ExecutionTimeLimit"         = (New-TimeSpan -Minutes 30)
    "AllowStartIfOnBatteries"    = $True
    "DontStopIfGoingOnBatteries" = $True
    "RestartCount"               = 2
    "RestartInterval"            = (New-TimeSpan -Minutes 5)
}
$Settings = New-ScheduledTaskSettingsSet @Params
    
# create list of triggers, and add logon trigger
$triggers = @()
    
# OS Startup (to prevent a proxy set after setup on site and finalyze outside (send to end-user@home for example)
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.Enabled = $True 
$triggers += $trigger

# At logon (to prevent when machine was in sleep mode before login)
$trigger =  New-ScheduledTaskTrigger -AtLogOn
$trigger.Enabled = $True 
$triggers += $trigger

# Network connected
$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger

$trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$trigger.Subscription = 
@"
<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name="Microsoft-Windows-NetworkProfile"] and EventID=10000]]</Select></Query></QueryList>
"@
$trigger.Enabled = $True 
$triggers += $trigger
    
# Network Disconnected
$trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$trigger.Subscription = 
@"
<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name="Microsoft-Windows-NetworkProfile"] and EventID=10001]]</Select></Query></QueryList>
"@
$trigger.Enabled = $True 
$triggers += $trigger

# Build Task parameters
$RegSchTaskParameters = @{
    TaskName    = $TaskName
    Description = 'Remediatiate network adapater when starting or when network connection change'
    TaskPath    = '\Econocom Workplace Tasks\'
    Action      = $Actions
    Principal   = $Principal
    Settings    = $Settings
    Trigger     = $Triggers
}

# Create the scheduled task
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Create task $TaskName" 
Register-ScheduledTask @RegSchTaskParameters

#===========================================================================================================================
# End of Setup Network for Windows
#===========================================================================================================================
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Setup Network for Windows finished" 

# Script done: details on other actions are in the log file
$ReturnCode = 0

# Restore path
Pop-Location

exit $ReturnCode
