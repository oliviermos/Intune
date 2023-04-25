#########################################################
############### Author : Benjamin Follet ################
######### Email : Benjamin.follet@econocom.com ##########
###################  Date 10/01/2023 ####################
#########################################################

# Script Purpose : It allows you to create the wifi configurations of the Colisée context. 
   
# Define and fill the DataTable Columns
function Set-DataBase() {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [system.Data.DataTable]$TableUseCases
    )

    BEGIN {
        # Variables
        [int]$Site_Index = 0
        [int]$UseCase_Index = 0
        [int]$SSID_Index = 0
        [int]$Password_Index = 0
        [string]$WorkSheetName = "WiFi-Tablettes"
        $objExcel = New-Object -ComObject Excel.Application  
        $WorkBook = $objExcel.Workbooks.Open($pathExcelFile)  
        $WorkBook.sheets | Select-Object -Property Name  
        $Worksheet = $Workbook.Worksheets.Item($WorkSheetName)
        $totalNoOfRecords = ($WorkSheet.UsedRange.Rows).count  
        $totalColumns = ($WorkSheet.UsedRange.Columns).count 

    }


    PROCESS {
        # Processing with begin and parameters variables.
        for ($index = 1; $index -lt $totalColumns + 1; $index++) {
            if ($WorkSheet.Cells.Item(1, $index).text -eq "User Name") {
                $Site_Index = $index
            }
            elseif ($WorkSheet.Cells.Item(1, $index).text -eq "User Group Name") {
                $UseCase_Index = $index
            }
            elseif ($WorkSheet.Cells.Item(1, $index).text -eq "SSID") {
                $SSID_Index = $index
            }
            elseif ($WorkSheet.Cells.Item(1, $index).text -eq "Password") {
                $Password_Index = $index
            }

            elseif ($Site_Index -ne 0 -and $UseCase_Index -ne 0 -and $SSID_Index -ne 0 -and $Password_Index -ne 0) {
                break
            }

        }
            
        if ($Site_Index -eq 0 -and $UseCase_Index -eq 0 -and $SSID_Index -eq 0 -and $Password_Index -eq 0) {
            Write-host "Verifier le nom des colonnes, l'une d'entre elle n'a pas été trouvée sur le fichier excel"
            exit
        }

        for ($element = 2; $element -lt $totalNoOfRecords + 1; $element++) {
            $row = $TableUseCases.NewRow()
            $row.Site = $WorkSheet.Cells.Item($element, $Site_Index).text
            $row.UseCase = ($WorkSheet.Cells.Item($element, $UseCase_Index).text)
            $row.SSID = ($WorkSheet.Cells.Item($element, $SSID_Index).text)
            $row.Password = ($WorkSheet.Cells.Item($element, $Password_Index).text)
            $TableUseCases.Rows.Add($row) 
        }
    }


    END {
        # Cleaning and closing of non-mandatory processes
        $WorkBook.close($true)
        $objExcel.quit()
        [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($WorkSheet)
        [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($WorkBook)
        [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($objExcel)
    }
}

#Allows you to extract the name of the site from the row "Site"
function Get-Site() {
    [CmdletBinding()]

    Param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string]$SiteName
    )

    BEGIN {
        $SiteNameU = $SiteName.ToUpper()
    }

    PROCESS {
        if ($SiteNameU -match " " ) {
            $TabSiteName = $SiteNameU -split " "
            $SiteNameU = $TabSiteName[0]
            if ($TabSiteName[0] -eq "ATM" -or $TabSiteName[0] -eq "TITAN") {
                return , $SiteNameU[1]
            }

            elseif ($TabSiteName[1] -match "^[0-9]") {
                $SiteNameU += $TabSiteName[1]
                return , $SiteNameU
            }
        }
      
        elseif ($SiteNameU -match "-") {
            $TabSiteName = $SiteNameU -split "-"
            $SiteNameU = $TabSiteName[0]
        }
        
        return , $SiteNameU
    }
}
#Allows to extract the use case for example "PRO" or "ATM" from the row "UseCase".
function Get-UseCase() {
    [CmdletBinding()]

    Param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string]$UseCase
    )

    BEGIN {
        $UseCaseU = $UseCase.ToUpper()

    }

    PROCESS {
        
        if ($UseCaseU -match "TITAN") {
            return , "PRO"    
        }
        return , "ATM"
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
        foreach ($group in $AllGroups) {
            if ($group.displayName -eq $GroupName) {
                return , $group.id
            }
        }
        write-host "Aucun groupe a pour nom le string passé en paramètre. Le requête va échouer pour cette configuration."
    }
}


# Set the configuration on Intune tenant WITHOUT the group and filter.
function Set-WiFi-Without() {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$displayName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [System.String]$SSID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
        [System.String]$password
    )

    BEGIN {
        [string]$graphApiVersion = "beta"
        [string]$Resource = "deviceManagement/deviceConfigurations"
        [string]$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    }

    PROCESS {
        write-host "displayName " $displayName
        write-host "SSID " $SSID

        $body = "{
            `"id`":`"00000000-0000-0000-0000-000000000000`",
            `"displayName`":`"$($displayName)`",
            `"roleScopeTagIds`":[`"0`"],
            `"@odata.type`":`"#microsoft.graph.androidDeviceOwnerWiFiConfiguration`",
            `"connectAutomatically`":true,
            `"connectWhenNetworkNameIsHidden`":true,
            `"proxyManualAddress`":null,
            `"proxyManualPort`":null,
            `"proxyExclusionList`":null,
            `"proxyAutomaticConfigurationUrl`":null,
            `"eapType`":null,
            `"authenticationMethod`":null,
            `"outerIdentityPrivacyTemporaryValue`":null,
            `"innerAuthenticationProtocolForEapTtls`":null,
            `"innerAuthenticationProtocolForPeap`":`"none`",
            `"trustedServerCertificateNames`":[],
            `"proxySettings`":`"none`",
            `"networkName`":`"$($SSID)`",
            `"ssid`":`"$($SSID)`",
            `"wiFiSecurityType`":`"wpaPersonal`",
            `"preSharedKey`":`"$($password)
        `"}"

        Invoke-MSGraphRequest -HttpMethod POST -Url $uri -Content $body  
    }
}

#Send a request to the intune tenant and get the configuration id.
function Get-ConfigurationID() {    
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$displayName
    )

    PROCESS {
        $ConfigurationID = Get-IntuneDeviceConfigurationPolicy -Select id , displayName | Where-Object { $_.displayName -eq $displayName }
        if ($ConfigurationID.id -is [string]) {
            return , $ConfigurationID.id
        }
        elseif ($ConfigurationID -eq $null) {
            Write-host "Configuration non trouvée"
            return "non configurable"
        }
        write-host "Une configuration possède le même nom sur le tenant. Des problèmes peuvent survenir pour l'assignation du groupe et du filtre associé."
        return , $ConfigurationID.id.GetValue(0)
    }
}


# Set the group in the WiFi configuration.
function Set-WiFiGroup() {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$groupID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [System.String]$configurationID
    )

    
    BEGIN {
        [string]$graphApiVersion = ""
        [string]$Resource = ""
        [string]$uri = ""
    }

    PROCESS {
        $body = "{
            `"assignments`":[{
                `"target`":{
                    `"@odata.type`":`"#microsoft.graph.groupAssignmentTarget`",
                    `"groupId`":`"$($groupID)`"
                }
            }]
        }"
    

        $graphApiVersion = "beta"
        $Resource = "deviceManagement/deviceConfigurations/" + $configurationID + "/assign"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        Invoke-MSGraphRequest -HttpMethod POST -Url $uri -Content $body  
       
    }
}


#Function that goes through each row and starts all functions to set the WiFi configuration on Intune tenant.
function Set-WiFi() {
    [CmdletBinding()]

    Param ()

    BEGIN {
        [string]$SiteName = ""
        [string]$UseCase = ""
        [string]$displayName = ""
        [string]$GroupName = ""
        [string]$GroupID = ""
        [string]$ConfigurationID = ""       
    }

    PROCESS {
        foreach ($row in $TableUseCases) {
            $SiteName = Get-Site -SiteName $row.Site 
            $UseCase = Get-UseCase -UseCase $row.UseCase
            $displayName = "CONF_TB_EHPAD_" + $UseCase + "_" + $SiteName + "_" + "Wi-Fi"
            Set-WiFi-Without -displayName $displayName -SSID $row.SSID -password $row.Password

            $GroupName = "GRP_INTUNE_TB_EHPAD_" + $UseCase + "_" + $SiteName
            $GroupID = Get-GroupID -GroupName $GroupName 
            $ConfigurationID = Get-ConfigurationID -displayName $displayName
            if ($ConfigurationID -ne "non configurable"){
                Set-WiFiGroup  -groupID $GroupID -configurationID $ConfigurationID
            }
        }
    }
}


# Required modules 
# Install-Module -Name Microsoft.Graph -Scope AllUsers
# Install-Module -Name Microsoft.Graph.Intune -Scope AllUsers
# Import-Module -Name Microsoft.Graph
# Import-Module -Name Microsoft.Graph.Intune

# Variables 
$pathDevice = "$env:USERPROFILE\Downloads\RenameDevice.log"
$pathErrorDevice = "$env:USERPROFILE\Downloads\RenameDeviceError.log"
$pathExcelFile = "$env:USERPROFILE\Downloads\WiFi-Tablettes.xlsx"

[system.Data.DataTable]$TableUseCases = New-Object system.Data.DataTable 'DataBase'
$newcol = New-Object system.Data.DataColumn Site, ([string]); $TableUseCases.columns.add($newcol)
$newcol = New-Object system.Data.DataColumn UseCase, ([string]); $TableUseCases.columns.add($newcol)
$newcol = New-Object system.Data.DataColumn SSID, ([string]); $TableUseCases.columns.add($newcol)
$newcol = New-Object system.Data.DataColumn Password, ([string]); $TableUseCases.columns.add($newcol)

#Main
# Connect and change schema 
Connect-MSGraph -ForceInteractive
Update-MSGraphEnvironment -SchemaVersion beta

#Cleaning of log files
if (Test-Path -Path $pathDevice) {
    Clear-Content $pathDevice
}
else {
    New-Item -Path $pathDevice
}

if (Test-Path -Path $pathErrorDevice) {
    Clear-Content $pathErrorDevice
}
else {
    New-Item -Path $pathErrorDevice
}

Set-DataBase -TableUseCases $TableUseCases
$AllGroups = Get-AADGroup | Get-MSGraphAllPages
Set-WiFi
