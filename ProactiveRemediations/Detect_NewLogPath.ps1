<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_NewLogPath.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the old log path is present: if yes, ask to move log files to new log path and delete old path

Created date: 12/09/2022
Last Revised: 12/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "2"
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$OldLogPath = "$($DestRootPath)\_Logs\"
$NewLogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"

# Check old path existing
If(!(Test-Path "$($OldLogPath)")) {
    Write-Output "Nothing to do: old log path $OldLogPath not found!"
    Exit 0 # Nothing to do
} else {
    Write-Output "!!! Warning !!! Move log files from old log path $OldLogPath to new log path $NewLogPath"
    Exit 1 # move log files
}
