<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Teamviewer_HOST.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Detect if TeamViewer Host was installed in the last 7 days: in this case, remove it.
We have a limit of 500 endpoints: this tool needs to be used only for support.
Check normal installation by Intune with tag file and other manners by MSI present.

Only MTR required this tool by default.

Note: The standard remote tool is Teamviewer Quick Support.

Created date: 29/08/2022
Last Revised: 30/08/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "2"
$MaxDays = 7
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
    $TagLastWrite = (Get-Item "$($TagFile)").LastWriteTime
    If((Get-Date).AddDays(-$MaxDays) -ge $TagLastWrite) {
        Write-Output "Teamviewer Host installation is older than $MaxDays days! Uninstall to do"
        Exit 1
    } else {
        Write-Output "Teamviewer was newly installed : waiting $MaxDays days for uninstalling!"
        Exit 0 # not yet
    }
}

# Check Teamviewer Host installed by other manners (MSI present)
$DetectTVHMSI = & "$($DestRootPath)\Scripts\Uninstall_MSI_By_NameAndVersion.ps1" -AppName "*$($TVHName)*" -AppVersion "$($TVHVersion)" | Select-String "$($SearchString)"
If([string]::IsNullOrEmpty($DetectTVHMSI)) {
    Write-Output "No Teamviewer MSI found: nothing to do!"
    Exit 0
} else {
    Write-Output "Teamviewer MSI found: uninstall to do!"
    Exit 1
}
