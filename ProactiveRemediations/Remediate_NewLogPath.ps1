<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_NewLogPath.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Move log files from old path to new path and delete old log path

Created date: 12/09/2022
Last Revised: 12/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "2"
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$OldLogPath = "$($DestRootPath)\_Logs\"
$NewLogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"

# Remediate old log path
if(Test-Path $OldLogPath) {
    # Copy all log files to new path
    Write-Output "!!! Warning !!! Copy all files from $OldLogPath to $NewLogPath"
    Copy-Item -Path $OldLogPath\* -Destination $NewLogPath -Recurse -force

    # Delete log folder
    Write-Output "!!! Warning !!! Delete folder $OldLogPath"
    remove-item -path $OldLogPath -Recurse -Force
} else {
    Write-Output "Old path $OldLogPath doesn't exist : no log files to move !"
}

exit 0