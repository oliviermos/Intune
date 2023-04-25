#Variables
$global:arraySites = New-Object -TypeName 'System.Collections.ArrayList'
$global:arrayDeviceBySite = New-Object -TypeName 'System.Collections.ArrayList'
# Required modules :
# Install-Module -Name Microsoft.Graph -Scope CurrentUser

#Import-Module Microsoft.Graph
Select-MgProfile -Name "v1.0"
Import-Module Microsoft.Graph.Identity.DirectoryManagement

$idapplicationclient="98eb3651-30b8-4851-b7b1-d78e8491b728"
$idannuaire="61368fbd-519f-4d22-97da-0b240909e918"
$certificate ="F58F14D4EA2D72703214669BE5E9CE577542FF38"

$global:pathDevice = "$env:USERPROFILE\RebootDevice.log"

# Nettoyage des fichiers de logs
if(Test-Path -Path $pathDevice){
    Clear-Content $global:pathDevice
}

Function Get-DeviceRebootByMinute(){
    if($global:arraySites.Count -lt 5){
        return ,$global:arraySites.Count
    }
    return ,5
}

Function Get-DeviceToReboot($RandomSite){
    $NumberDevice = 0 
    $DeviceRebootByMin = Get-DeviceRebootByMinute
    While ($NumberDevice -lt $DeviceRebootByMin) {
        # Stop the loop if there is no more device
        if($global:arraySites.Count -lt 1){ 
            break
        }

        #Random determination of the device that will be rebooted
        $RandomDevice = $global:arrayDeviceBySite[$RandomSite] | Get-Random
        Write-output "Random Device : " $RandomDevice.AdditionalProperties.displayName >> $global:pathDevice
        #Restart-MgDeviceManagementManagedDeviceNow -ManagedDeviceId $RandomDevice.AdditionalProperties.deviceId    
        
        #remove item
        $global:arrayDeviceBySite[$RandomSite].Remove($RandomDevice)

        
        #Remove empty site
        if($global:arrayDeviceBySite[$RandomSite].Count -eq 0){
            Write-output "Site delete : "  $global:arraySites[$RandomSite] >> $global:pathDevice
            $global:arrayDeviceBySite.RemoveAt($RandomSite)
            $global:arraySites.RemoveAt($RandomSite)
        }

        #Select the next reboot device
        $NextSite = $RandomSite
        if ($RandomSite + 1 -eq $global:arraySites.Count -or $RandomSite + 1 -gt $global:arraySites.Count){
            $RandomSite = 0
        }
        elseif ($global:arraySites.Count -eq 0 -or $global:arraySites.Count -eq 1){
            $RandomSite = 0
        }
        else {
            $RandomSite++
        }
        $NumberDevice++
    }
    return $RandomSite
}


function set-array($arrayDevice){
    foreach($device in $arrayDevice){
        $newArray = New-Object -TypeName 'System.Collections.ArrayList'
        $siteNumber = (($device.AdditionalProperties.displayName-split "_")[1]) -replace '\s',''
        $index = 0
        $existingSiteName = $false

        foreach($site in $global:arraySites){
            if($site -eq $siteNumber){
                $existingSiteName = $true
                break
            }           
            $index++
        }
        if($existingSiteName){
            [void]$arrayDeviceBySite[$index].Add($device)
        }
        else{
            [void]$newArray.Add($device)
            [void]$global:arraySites.Add($siteNumber)
            [void]$global:arrayDeviceBySite.Add($newArray)
        }
    }
}


function Get-Display($pathDevice){
    Write-host "#########################" >> $pathDevice
    for($SiteNumber = 0; $SiteNumber -lt $global:arraySites.count; $SiteNumber++){
        Write-host $global:arraySites[$SiteNumber] >> $pathDevice
        foreach($device in $global:arrayDeviceBySite[$SiteNumber]){
            Write-host "Device " $device >> $pathDevice
        }
        Write-host "" >> $pathDevice
    }
    Write-host "#########################" >> $pathDevice
    Write-host "" >> $pathDevice
}


# Main

Connect-Graph -AppId $idapplicationclient -TenantId $idannuaire -CertificateThumbprint $certificate
$GroupSearch = Get-MgGroup -Filter "displayName eq 'GRP_GSF_COSU'"
$DeviceDetails = Get-MgGroupMember -GroupId $GroupSearch.Id -All
set-array($DeviceDetails)

$clock = [diagnostics.stopwatch]::StartNew()

# Determination of the first random site
$RandomSite = Get-Random -Minimum 0 -Maximum $global:arraySites.Count

Do {     
    $RandomSite = Get-DeviceToReboot $RandomSite
    start-sleep -seconds 0.5
    Write-output "" >> $global:pathDevice
} Until ($global:arrayDeviceBySite.Count -eq 0)

Disconnect-MgGraph