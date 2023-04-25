<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Teamviewer_HOST.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to remove Teamviewer Host when detected.

Created date: 30/08/2022
Last Revised: 30/08/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "2"
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\Win32Packages\TeamViewer_Host"
$TAGFile = "$($DestPath)\TeamViewerHost_Setup.ps1-V*-Installed.tag"
$TVHName = "teamviewer"
$TVHVersion = "0"
$SearchString = "--- Application found : "

# Check Teamviewer Host installed by Intune
If(!(Test-Path "$($TagFile)")) {
    Write-Output "No teamViewer Host installed by Intune"
} else {
    Write-Output "Uninstall Teamviewer Host"
    & "$($DestPath)\TeamViewerHost_Setup.ps1" -uninstall
}

# Check Teamviewer Host installed by other manners (MSI present)
$DetectTVHMSI = & "$($DestRootPath)\Scripts\Uninstall_MSI_By_NameAndVersion.ps1" -AppName "*$($TVHName)*" -AppVersion "$($TVHVersion)" | Select-String "$($SearchString)"
If([string]::IsNullOrEmpty($DetectTVHMSI)) {
    Write-Output "No Teamviewer MSI found: nothing to do!"
} else {
    Write-Output "Uninstall MSI Teamviewer Host found"
    & "$($DestRootPath)\Scripts\Uninstall_MSI_By_NameAndVersion.ps1" -AppName "*$($TVHName)*" -AppParameters "/q"
}

Exit 0