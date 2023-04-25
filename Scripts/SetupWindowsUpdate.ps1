<#===========================================================================================================================
Script Name: SetupWindowsUpdate.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
Description:
    Set Windows Update registry
    Create schedule task to automatically update at each logon without forcing reboot

Date Created: 09/02/2022
Last Revised: 03/11/2022
===========================================================================================================================#>
# Variables
$Version = "1.3"
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
# Tasks scheduled: launch a windows update all @ Login
#===========================================================================================================================
$TaskName = "Windows Update all @ Login"

# Delete task push for updating
if ($(Get-ScheduledTask -TaskName "$($TaskName)" -ErrorAction SilentlyContinue).TaskName -eq "$($TaskName)") {
    Unregister-ScheduledTask -TaskName "$($TaskName)" -Confirm:$False
}

If ($Profile -eq "MTR") {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! MTR do not need Windows update task: already present !"
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Create schedule task to launch automatically Windows Update by script"
    # Actions list
    $Actions = @()
    # Launch Windows update
    $ActionParameters = @{
        Execute  = "powershell.exe"
        Argument = "-executionpolicy bypass -command $($DestRootPath)\Scripts\LaunchWindowsUpdate.ps1"
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
    
    # create list of triggers
    $triggers = @()

    # Every 3 hours
    $StartTime=(Get-Date)
    $trigger = New-ScheduledTaskTrigger -once -at $StartTime -RepetitionInterval (New-TimeSpan -Hours 3)
    $trigger.Enabled = $True
    $triggers += $trigger

    # At logon
    $trigger =  New-ScheduledTaskTrigger -AtLogOn
    $trigger.Enabled = $True 
    $triggers += $trigger

    # Build Task parameters
    $RegSchTaskParameters = @{
        TaskName    = $TaskName
        Description = 'Runs at each logon to run Windows Update'
        TaskPath    = '\Econocom Workplace Tasks\'
        Action      = $Actions
        Principal   = $Principal
        Settings    = $Settings
        Trigger     = $triggers
    }

    # Create the scheduled task
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Create task $TaskName" 
    Register-ScheduledTask @RegSchTaskParameters
}
#===========================================================================================================================
# End of Setup Network for Windows
#===========================================================================================================================
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Setup Windows Update finished" 

# Script done: details on other actions are in the log file
$ReturnCode = 0

# Restore path
Pop-Location

exit $ReturnCode
