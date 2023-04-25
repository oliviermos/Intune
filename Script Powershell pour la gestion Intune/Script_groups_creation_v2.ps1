#########################################################
############### Author : Benjamin Follet ################
######### Email : Benjamin.follet@econocom.com ##########
###################  Date 05/12/2022 ####################
#########################################################

# Script Purpose : It allows you to create all the sites present in the Colisée context on intune. One Site by group.

# Define and fill the DataTable Columns for sites and regions filters
function Set-DataBaseSites() {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [system.Data.DataTable]$Table,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [string]$Path
    )

    BEGIN{
        [string]$WorkSheetName = "Sites par région"
        [string]$ColumnRegionName = "Region"
        [string]$ColumnSiteName = "Code SITE"
        [string]$ColumnResidenceName = "Residence"
        [int]$ColumnRegionIndex = -1
        [int]$ColumnSiteIndex = -1
        [int]$ColumnResidenceIndex = -1

        $Excel = New-Object -ComObject Excel.Application
        $Excel.Visible = $false
        $Workbook  = $Excel.Workbooks.Open($Path)
        $Worksheet = $Workbook.Worksheets.Item($WorkSheetName)
    }

    PROCESS{
        # get the total used column indices
        $TotalColumns = ($WorkSheet.UsedRange.Columns).count 
        
        # get the first and last used row indices
        $TotalRows = ($WorkSheet.UsedRange.Rows).count 
        # get columns indices by the column name
        for($Column = 1; $Column -lt $TotalColumns + 1; $Column++){
            if($WorkSheet.Cells.Item(1, $column).text -eq $ColumnRegionName){
                $ColumnRegionIndex = $column
            }
            if($WorkSheet.Cells.Item(1, $column).text -eq $ColumnSiteName){
                $ColumnSiteIndex = $column
            }
            if($WorkSheet.Cells.Item(1, $column).text -eq $ColumnResidenceName){
                $ColumnResidenceIndex = $column
            }
            if($ColumnRegionIndex -ne -1 -and $ColumnSiteIndex -ne -1 -and $ColumnResidenceIndex -ne -1){
                break
            }
        }
        # Check all indices value
        if($ColumnRegionIndex -eq -1 -or $ColumnSiteIndex -eq -1 -or $ColumnResidenceIndex -eq -1){
            Write-host "Verifier le nom des colonnes, l'une d'entre elle n'a pas été trouvée sur le fichier excel"
            exit
        }

        # Check all indices value
        for ($Item = 2; $Item -lt $TotalRows + 1; $Item++) {
            $row = $Table.NewRow()
            $row.Region = ($WorkSheet.Cells.Item($Item,$ColumnRegionIndex).Value2)
            $row.CodeSite =  ($WorkSheet.Cells.Item($Item,$ColumnSiteIndex).Value2)
            $row.Residence = ($WorkSheet.Cells.Item($Item,$ColumnResidenceIndex).Value2)
            $Table.Rows.Add($row) 
        }
    }

    END{
        $Excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Worksheet) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        return ,$Table
    }  
}

# Filters Preparation
function GroupSitePreparation(){
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [system.Data.DataTable]$Table
    )
    
    BEGIN{
        [string]$Description = ""
        [string]$Name = ""
        [string]$TokUseCase = ""
        [string]$UseCase = ""
        [string]$Rule = ""
        [boolean]$Continue = $false
    
    }

    PROCESS{
        # Sites filters creation
        for($i=0; $i -lt $Table.Rows.Count; $i++){ 
            $Description = $Table.Rows[$i][2]
            for($y=0; $y -lt 3; $y++){
                if($y -eq 0){
                    $TokUseCase = "TOK_TBPRO"
                    $UseCase = "PRO"
                }
                elseif($y -eq 1){
                    $TokUseCase = "TOK_TBATM"
                    $UseCase = "ATM"
                }
                else {
                    $TokUseCase = "TOK_TBGUEST"
                    $UseCase = "GUEST"
                }
                $Name = "GRP_INTUNE_TB_EHPAD_" + $UseCase + "_" + $Table.Rows[$i][1] 
                $Rule = "(device.displayName -contains \" + '"' + "$($Table.Rows[$i][1])" + "-" + "\" + '"' + ")" + " and " + "(device.enrollmentProfileName -eq \" + '"' + "$($TokUseCase)\" + '"' + ")"
                GroupCreation -Name $Name -Description $Description -Rule $Rule
            } 
        }
    }
}

# TB Group Creation
function GroupCreation(){
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [string]$Description,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
        [string]$Rule        
    )

    BEGIN{
        [string]$GraphApiVersion = "beta"
        [string]$Resource = "groups"
        [string]$Uri = "https://graph.microsoft.com/$GraphApiVersion/$($Resource)"
    }

    PROCESS{
        $body = "{
            `"description`":`"$($Description)`",
            `"displayName`":`"$($Name)`",
            `"mailEnabled`":false,
            `"mailNickname`":`"60028b3a-2`",
            `"securityEnabled`":true,
            `"groupTypes`":[`"DynamicMembership`"],
            `"membershipRule`":`"$($Rule)`",
            `"membershipRuleProcessingState`":`"On
        `"}"

        Write-Host "creation of the group " "$($Name)"
        Write-host $Rule
        Write-host ""    
    }

    END{
        $res = Invoke-MSGraphRequest -HttpMethod POST -Url $Uri -Content $body
    }
}

# Required modules 
# Install-Module -Name Microsoft.Graph -Scope AllUsers
# Install-Module -Name Microsoft.Graph.Intune -Scope AllUsers
# Import-Module -Name Microsoft.Graph
# Import-Module -Name Microsoft.Graph.Intune

# Variables 
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
$FileBrowser.Filter= "Documents (*.docx)|*.docx|SpreadSheet (*.xlsx)|*.xlsx" 
$null = $FileBrowser.ShowDialog()
$PathExcelFile =$FileBrowser.FileName

[system.Data.DataTable]$TableSites = New-Object system.Data.DataTable 'GroupsTable'
$newcol = New-Object system.Data.DataColumn Region,([string]); $TableSites.columns.add($newcol)
$newcol = New-Object system.Data.DataColumn CodeSite,([string]); $TableSites.columns.add($newcol)
$newcol = New-Object system.Data.DataColumn Residence,([string]); $TableSites.columns.add($newcol)

#Main
Connect-MSGraph -ForceInteractive
Update-MSGraphEnvironment -SchemaVersion beta

$TableSites = Set-DataBaseSites -Table $TableSites -Path $PathExcelFile
GroupSitePreparation -Table $TableSites
