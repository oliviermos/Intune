<#===========================================================================================================================
 Script Name: Uninstall_MSI_By_Name.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

 Description: Uninstall all MSI found by Name installed
 Search Install string in registry and convert the /i in /x to uninstall if necessary
 
 Input:
    AppName: the application name of a mask like "*office*" for all office products
    AppVersion: the version wanted if needed. By default all versions will be found
    AppParameters: additional parameters to add like /silent, /q, DisplayLevel=False
 
 Output:
    Error code return if no application found of no appname given.
    If msi uninstalled failed, error a return too with the message error.

 Date Created: 12/02/2022
 Last Revised: 05/09/2022
<#===========================================================================================================================#>
param(
    [string]$AppName = "",
    [string]$AppVersion = "",
    [string]$AppParameters =""
)

# Variables
$Version = "1.6"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"

$ProcessExitCode = 1 # uninstall not possible or failed

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Search application(s) '$AppName' with version '$AppVersion' and Parameters '$AppParameters'"

If($AppName -ne "") {
    $ErrorActionPreference = 'SilentlyContinue'
    Try {
        $AppsList = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"| Where-Object DisplayName -Like "$AppName" | Select-Object DisplayName, DisplayVersion, Publisher, UninstallString, PSPath
        $TempUString = $Null
        
        If ($AppsList -ne $Null) {
            Foreach($App in $AppsList) {
                Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : --- Application found : '$($App.DisplayName)' Version '$($App.DisplayVersion)'"
                Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :    +++ Uninstall String '$($App.UninstallString)'"
                Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :    +++ Registry path '$($App.PSPath)'"
                If (($($App.DisplayVersion).StartsWith($AppVersion))) {
                    $TempUString = ($($($App.UninstallString)).ToUpper())
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Uninstall String: $TempUString"

    	            If ($TempUString.StartsWith("MSIEXEC.EXE")) {
                        
                        # MSI uninstall
                        
                        $TempUString = $TempUString.Replace("MSIEXEC.EXE /I","/X") #Convert /I (install) in /X (uninstall)
                        $TempUString = $TempUString.Replace("MSIEXEC.EXE /X","/X")
                        $TempUString = "$TempUString $AppParameters"
                        $Process = (Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList "$TempUString" -PassThru -Wait)
                    } elseif($TempUString.Contains("OFFICECLICKTORUN.EXE")) {
                        
                        # OFFICECLICKTORUN.EXE

                        If($TempUString.Substring(0,1) -eq '"') {
                            $TempIndex = $TempUString.LastIndexOf('" ') + 1
                        } else {
                            $TempIndex = $TempUString.IndexOf(" ")
                        }

                        $TempFilePath = $TempUString.Substring(0,$TempIndex)
                        $TempArgumentList = $TempUString.Substring($TempIndex,$TempUString.Length-$TempIndex)
                        $TempArgumentList = "$TempArgumentList $AppParameters"
                        $Process = (Start-Process $TempFilePath -ArgumentList $TempArgumentList -PassThru -Wait)
                    } else {
                        
                        # Other: expected an only exe file without arguments
                        If($TempUString.Substring(0,1) -eq '"') {
                            $TempIndex = $TempUString.LastIndexOf('"') + 1
                        } else {
                            $TempIndex = $TempUString.IndexOf(".EXE") + 4
                        }

                        $TempFilePath = $TempUString.Substring(0,$TempIndex)
                        $TempArgumentList = $TempUString.Substring($TempIndex,$TempUString.Length-$TempIndex)
                        $TempArgumentList = "$TempArgumentList $AppParameters"
                        $Process = (Start-Process $TempFilePath -ArgumentList $TempArgumentList -PassThru -Wait)
                    }

                    # Uninstall process launched: wait end of process
                    $ProcessExitCode = $Process.ExitCode
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Process finished with return code: $ProcessExitCode"
                } else {
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Version not matching"
                }
            }
        } Else {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!!  No application to uninstall"
        }
    } Catch {
        # Uninstallation failed
	    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! FAILED !!! $($_.exception.message)"
    }

} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! ERROR !!! No application name given"
}
# Restore path
Pop-Location

exit $ProcessExitCode
