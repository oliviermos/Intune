<#===========================================================================================================================
Script Name: DetectLowSpace.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Description: Detect low harddrive space on C directory

Forked from: https://deviceadvice.io/2021/11/15/use-proactive-remediations-to-detect-users-running-out-of-hard-drive-space/

The alert is 10 GB (not 10% like the original as it's not efficient between a 128GB and 512GB SSD drive...)

Date Created: 16/03/2022
Last Revised: 31/08/2022
===========================================================================================================================#>
$Version = "3"
$DriveLetter = "C"
$GigaFactor = 1024*1024*1024
$AlertSizeGb = 10 # 10 GB remaining

try {
    $WindowsDrive = Get-Volume -DriveLetter "$DriveLetter"
    $DriveRemaining = $WindowsDrive.SizeRemaining/$GigaFactor
    $DriveSize = $WindowsDrive.Size/$GigaFactor
    
    $PercentageRemaining = ($DriveRemaining/$DriveSize)*100

    Write-Host "$([math]::Round($PercentageRemaining,0)) % remaining on $($DriveLetter): | Remaining size : $([math]::Round($DriveRemaining,2)) Gb | Drive $($DriveLetter): total size: $([math]::Round($DriveSize,2)) Gb"
    if ($DriveRemaining -lt $AlertSizeGb){
        exit 1
    }
    else {
        exit 0
    }
}
catch {
    $errMsg = $_.Exception.Message
    return $errMsg
    exit 1
} 