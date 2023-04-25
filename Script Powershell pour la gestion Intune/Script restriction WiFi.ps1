#########################################################
############### Author : Benjamin Follet ################
######### Email : Benjamin.follet@econocom.com ##########
###################  Date 25/01/2023 ####################
#########################################################

# Script Purpose : It allows you to add devices with a wifi configuration assigned to the wifi restriction group.

# Return all devices that have a Wi-Fi configuration assigned
function Check-WiFiConf {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$DeviceId
    )
    BEGIN {
        $Uri = "https://graph.microsoft.com/beta/deviceManagement/reports/getConfigurationPoliciesReportForDevice"
        $Body = "{
            `"select`":[`"IntuneDeviceId`",`"PolicyBaseTypeName`",`"PolicyId`",`"PolicyStatus`",`"UPN`",`"UserId`",`"PspdpuLastModifiedTimeUtc`",`"PolicyName`",`"UnifiedPolicyType`"],
            `"filter`":`"((PolicyBaseTypeName eq 'Microsoft.Management.Services.Api.DeviceConfiguration') or (PolicyBaseTypeName eq 'DeviceManagementConfigurationPolicy') or (PolicyBaseTypeName eq 'DeviceConfigurationAdmxPolicy') or (PolicyBaseTypeName eq 'Microsoft.Management.Services.Api.DeviceManagementIntent')) and (IntuneDeviceId eq '$($DeviceId)')`",
            `"skip`":0,
            `"top`":50,
            `"orderBy`":[`"PolicyName`"]
        }"
    }

    PROCESS {
        try {
            #Write-host "WiFiConf"
            $data = Invoke-MSGraphRequest -HttpMethod POST -Url $Uri -Content $body
            foreach($item in $data.values){
                if($item[3] -cmatch 'CONF_TB_EHPAD_(PRO|ATM)_[A-Z]{3,4}[0-9]{0,1}_Wi-Fi'){
                    return ,$true
                }
            }
            return ,$false  
        }
        Catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}

# Add the device in Restriction Group Wifi 
function Set-DeviceToGroup {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$DeviceId,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [System.String]$Device
    )
    BEGIN {
        $Uri = "https://graph.microsoft.com/beta/`$batch"
        $GroupId = "abdf7f25-6e16-465c-98b5-3320dbb4ec8f"
        $Body = "{`"requests`":[{`"id`":`"member_$($GroupId)_$($DeviceId)`",`"method`":`"POST`",`"url`":`"/groups/$($GroupId)/members/`$ref`",`"headers`":{`"Content-Type`":`"application/json`"},`"body`":{`"@odata.id`":`"https://graph.microsoft.com/beta/directoryObjects/$($DeviceId)`"}}]}"
    }

    PROCESS {
        try {
            Invoke-MSGraphRequest -HttpMethod POST -Url $Uri -Content $body
            Write-host "L'appareil " $Device " à été ajouté au groupe GRP_INTUNE_TB_EHPAD_RES_WI-FI"
        }
        catch {
           Write-Host $_.Exception.Message -ForegroundColor Red
        }
 
    }
}

# Get all devices members of given group based on its Azure group id
function Get-DevicesFromGroupId {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$GroupId
    )

    BEGIN {
        $Resource = "groups/$GroupId/transitiveMembers?`$select=id,displayName,deviceId&`$top=999"
        $graphApiVersion = "beta"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    }

    PROCESS {
        try {
            $res = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
        }
        catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }

    END {
        return ,$res.value
    }
}

# Get the ObjectId of the device which is use to add the device in Wi-Fi restriction group
function Get-DeviceObjectId {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$DeviceId,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [System.Object[]]$DevicesInGrp
    )

    PROCESS {
        try{
            foreach($AzureADDevice in $DevicesInGrp) {
                if($AzureADDevice.deviceId -eq $DeviceId){
                    return ,$AzureADDevice.id
                }
            }
            return ,$false
        }
        catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
}


# Connect and change schema 
Connect-MSGraph -ForceInteractive
Update-MSGraphEnvironment -SchemaVersion beta

$GroupName = "GRP_INTUNE_TB_EHPAD"
$GroupSearch = Get-AADGroup -filter "displayName eq '$GroupName'"

if ($GroupSearch.Length -eq 0){
    write-host "Error: Group '$GroupName' Not Found" -ForegroundColor Red
    exit(1)
} 

$GroupId = $GroupSearch[0].id
$AllDevices = Get-IntuneManagedDevice | Get-MSGraphAllPages
$AllDeviceInGrp = Get-DevicesFromGroupId -GroupId $GroupId

foreach($device in $AllDevices){
    if(Check-WiFiConf -DeviceId $device.id) {
        $DeviceIdGrp = Get-DeviceObjectId -DeviceId $device.id -DevicesInGrp $AllDeviceInGrp
        if($DeviceIdGrp -ne $false){
            Set-DeviceToGroup -DeviceId $DeviceIdGrp -Device $device.deviceName 
        }
    }
}

  
