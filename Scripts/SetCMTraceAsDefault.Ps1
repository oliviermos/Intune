<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Name: SetCMTraceAsDefault.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Script to associate .log and .lo_ files to CMtrace and make it the default app to open them

Creation date: 11/04/2022
Modification date: 05/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1.3"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"

# Create Resgistry Keys 
New-Item -Path 'HKLM:\Software\Classes\.lo_' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\.log' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\.log.File' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\.Log.File\shell' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\Log.File\shell\Open' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Classes\Log.File\shell\Open\Command' -type Directory -Force -ErrorAction SilentlyContinue
New-Item -Path 'HKLM:\Software\Microsoft\Trace32' -type Directory -Force -ErrorAction SilentlyContinue

# Create the properties to make CMtrace the default log viewer
New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\.lo_' -Name '(default)' -Value "Log.File" -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\.log' -Name '(default)' -Value "Log.File" -PropertyType String -Force -ea SilentlyContinue;
New-ItemProperty -LiteralPath 'HKLM:\Software\Classes\Log.File\shell\open\command' -Name '(default)' -Value '"C:\ProgramData\Econocom\Workplace\Tools\CMTrace.exe" "%1"' -PropertyType String -Force -ea SilentlyContinue;

# Create an ActiveSetup that will remove the initial question in CMtrace if it should be the default reader
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace" -type Directory -Force -ErrorAction SilentlyContinue
new-itemproperty "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace" -Name "Version" -Value 1 -PropertyType String -Force -ErrorAction SilentlyContinue
new-itemproperty "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\CMtrace" -Name "StubPath" -Value "'reg.exe add HKCU\Software\Microsoft\Trace32' /v 'Register File Types' /d 0 /f" -PropertyType ExpandString -Force -ErrorAction SilentlyContinue