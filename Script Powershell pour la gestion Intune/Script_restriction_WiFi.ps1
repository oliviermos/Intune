
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
            $data = Invoke-MSGraphRequest -HttpMethod POST -Url $Uri -Content $body
            foreach ($item in $data.values) {
                if ($item[3] -cmatch 'CONF_TB_EHPAD_(PRO|ATM)_[A-Z]{3,4}[0-9]{0,1}_Wi-Fi') {
                    return , $true
                }
            }
            return , $false  
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
        [System.String]$DeviceObjectId,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [System.String]$DeviceName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [System.String]$GroupId
    )
    BEGIN {
        $Uri = "https://graph.microsoft.com/beta/`$batch"
        $Body = "{`"requests`":[{`"id`":`"member_$($GroupId)_$($DeviceObjectId)`",`"method`":`"POST`",`"url`":`"/groups/$($GroupId)/members/`$ref`",`"headers`":{`"Content-Type`":`"application/json`"},`"body`":{`"@odata.id`":`"https://graph.microsoft.com/beta/directoryObjects/$($DeviceObjectId)`"}}]}"
    }

    PROCESS {
        try {
            Invoke-MSGraphRequest -HttpMethod POST -Url $Uri -Content $body
            Write-host "L'appareil " $DeviceName " à été ajouté au groupe GRP_INTUNE_TB_EHPAD_RESTRICTION-WIFI"
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
        return , $res.value
    }
}

#Browse all groups on the Intune tenant. Match the name passed in parameter and return the id.
function Get-GroupID() {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$GroupName
    )
    PROCESS {
        $AllGroups = Get-AADGroup | Get-MSGraphAllPages
        foreach($group in $AllGroups) {
            if ($group.displayName -eq $GroupName) {
                return , $group.id
            }
        }
        write-host "Aucun groupe a pour nom le string passé en paramètre. Le requête va échouer."
    }
}

# Required modules 
# Install-Module -Name Microsoft.Graph -Scope AllUsers
# Install-Module -Name Microsoft.Graph.Intune -Scope AllUsers
# Import-Module -Name Microsoft.Graph
# Import-Module -Name Microsoft.Graph.Intune

# Main 
Connect-MSGraph -ForceInteractive
Update-MSGraphEnvironment -SchemaVersion beta

$GroupIdEhpad = Get-GroupID -GroupName "GRP_INTUNE_TB_EHPAD"
$GroupIdRestriction = Get-GroupID -GroupName "GRP_INTUNE_TB_EHPAD_RESTRICTION-WIFI"
$AllDevicesInGrpEhpad = Get-DevicesFromGroupId -GroupId $GroupIdEhpad
$AllDevicesInGrpRestriction = Get-DevicesFromGroupId -GroupId $GroupIdRestriction
foreach ($deviceGrpEhpad in $AllDevicesInGrpEhpad) {
    Start-Sleep -Seconds 2
    if (Check-WiFiConf -DeviceId $deviceGrpEhpad.deviceId) {
        $nbreElement = $AllDevicesInGrpRestriction.Count
        foreach ($deviceGrpRestriction in $AllDevicesInGrpRestriction) {
            if ($deviceGrpRestriction.deviceID -eq $deviceGrpEhpad.deviceID) {
                break
            }
            elseif ($AllDevicesInGrpRestriction.IndexOf($deviceGrpRestriction) -eq $nbreElement - 1) { 
                 Set-DeviceToGroup -DeviceObjectId $deviceGrpEhpad.id -DeviceName $deviceGrpEhpad.displayName -GroupId $GroupIdRestriction
            }
        }
    }
}
