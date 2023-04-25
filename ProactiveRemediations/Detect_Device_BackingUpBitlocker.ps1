<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Device_BackingUpBitlocker.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device has Backing Up Bitlocker key to Azure AD

Created date: 27/09/2022
Last Revised: 27/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$Version = "1"
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\\ProactiveRemediations"
$TagFile = "$($DestPath)\Device-BackingUpBitlocker-Done.tag"

# Create path to tag files
if(!(Test-Path $DestPath)) { New-Item -ItemType Directory -Force -Path $DestPath }

# Check tag file
If(!(Test-Path "$($TagFile)")) {
    Write-Output "Backing up Bitlocker key to AAD!"
    Exit 1 # First time, backup
} else {
    Write-Output "Bitlocker key already backuped to AAD!"
    Exit 0 # already done
}
