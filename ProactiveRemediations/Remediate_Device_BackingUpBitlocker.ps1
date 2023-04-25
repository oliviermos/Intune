<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Device_BackingUpBitlocker.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to backing up bitlocker key to Azure AD

If done, create a tag file to stop to backup.

This script is here to remediate the legacy INTRA devices with MDOP/MBAM

Created date: 27/09/2022
Last Revised: 27/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$Version = "1"
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\\ProactiveRemediations"
$TagFile = "$($DestPath)\Device-BackingUpBitlocker-Done.tag"

# Create path to tag files
if(!(Test-Path $DestPath)) { New-Item -ItemType Directory -Force -Path $DestPath }

# Backing up bitlocker key for system drive only
$BitLocker = Get-BitLockerVolume -MountPoint $env:SystemDrive
$RecoveryProtector = $BitLocker.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
    
foreach ($Key in $RecoveryProtector.KeyProtectorID) {
    try {
        Write-Output "Backing up bitlocker key $Key to Azure AD..."
        BackupToAAD-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $Key
        Write-Output "Done !"

        # Create/update tag file
        Set-Content "$($TagFile)" "Backing up bitlocker key $Key to Azure AD done" -Force
    }
    catch {
        Write-Output "Could not back up to Azure AD. Error: $_ !"
    }
}

Exit 0