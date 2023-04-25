<#===========================================================================================================================
Script Name: CloseProcessByName.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
Description:
    Close applications by process name
    If applications hang for closing current work, send command to accept to save
Input:
    AppProcess: name of the process found with get-process or in the task manager
    AppName: application name to bring in front and send keys found in the task manager
    AppKeys: keys to send to close a window that hang the end of the application (example: %Y is Alt+Y for button with "Yes")

Date Created: 25/01/2022
Last Revised: 05/09/2022
===========================================================================================================================#>
param(
    [string]$AppProcess = "",
    [string]$AppName = "",
    [string]$AppKeys = ""
)

# Variables
$Version = "1.4"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"  *>> $LogFile

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

$LASTEXITCODE = 1 #Error by default
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Search process '$AppProcess' known as '$AppName' with Keys '$AppKeys'"

If($AppProcess -ne "") {
    Try {
        $isAppOpen = Get-Process $AppProcess -ea SilentlyContinue

        while ($isAppOpen -ne $null) {
            Get-Process $AppProcess | ForEach-Object { $_.CloseMainWindow() | Out-Null } | stop-process –force
            sleep 5
            If (($isAppOpen = Get-Process $AppProcess -ea SilentlyContinue) -ne $null) {
                If($AppName -ne "") {
                    # If process cannot be closed, try to send keys to close windows locked: like Yes or no for saving work.
                    Write-Host "$AppName is Open.......Closing $AppName with $AppKeys"
                    $wshell = new-object -com wscript.shell
                    $wshell.AppActivate($AppName)
                    $wshell.Sendkeys($AppKeys)
                    $isAppOpen = Get-Process $AppProcess -ea SilentlyContinue
                } else {
                    Write-Host "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! $AppName is Open....... No appplication name given... wait end of process..."
                }
            }
        }
    } Catch {
        # Uninstallation failed
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : $($_.exception.message)"
    }
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! ERROR !!! No application name given"
}
# Restore path
Pop-Location

exit $LASTEXITCODE