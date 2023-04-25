<#
.SYNOPSIS
This script retrieve all installed apps uninstall keys
.DESCRIPTION
This script checks for all installed apps uninstall keys
.NOTES
#>

clear

$productNames = @("*")
$UninstallKeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
                    )
$results = foreach ($key in (Get-ChildItem $UninstallKeys) ) {

    foreach ($product in $productNames) {
        if ($key.GetValue("DisplayName") -like "$product") {
            [pscustomobject]@{
                KeyName = $key.Name.split('\')[-1];
                DisplayName = $key.GetValue("DisplayName");
                UninstallString = $key.GetValue("UninstallString");
                Publisher = $key.GetValue("Publisher");
            }
        }
    }
}

$results | fl *