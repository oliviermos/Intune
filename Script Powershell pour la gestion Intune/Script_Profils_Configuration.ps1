#Retrieve information according to the resource defined in parameters
function Get-Information{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$resource
    )
    BEGIN{
        [string]$graphApiVersion = "beta"
        [string]$uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/$($resource)?`$expand=assignments"
    }
    PROCESS{
        $AllInformation = Invoke-MSGraphRequest -HttpMethod GET -Url $uri
        return ,$AllInformation
    }
}

#Adding rows to the datatable
function Add-Rows{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.Data.DataTable]$table,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        $AllInformation
    )
    PROCESS{
        $length = $AllInformation.value.Length
        for($i = 0; $i -lt $length; $i++){
            $row = $table.NewRow()
            $row.configuration = $AllInformation.value[$i].displayName 
            if($row.configuration.GetType() -eq [System.DBNull]){
                $row.configuration = $AllInformation.value[$i].name  
            }
            $length2 = $AllInformation.value[$i].assignments.target.Length
            if($length2 -eq 0){
                $table.Rows.Add($row)
                continue
            }
            elseif($null -eq $length2){
                $length2 = 1
            }
            for($j = 0; $j -lt $length2; $j++){
                if($AllInformation.value[$i].assignments.target[$j].'@odata.type'.Contains("microsoft.graph.allDevicesAssignmentTarget")){
                    $row.include = "Tous les appareils"
                    continue
                }
                foreach($group in $AllGroups){
                    if($group.id -eq $AllInformation.value[$i].assignments.target[$j].groupId){
                        if($AllInformation.value[$i].assignments.target[$j].'@odata.type'.Contains("exclusion")){
                            if($row.exclude.GetType() -eq [System.DBNull]){
                                $row.exclude = $group.displayName
                                break
                            }
                            else{
                                $row.exclude = $row.exclude + "`n" + $group.displayName
                                break
                            }
                        }
                        if($row.include.GetType() -eq [System.DBNull]){
                            $row.include = $group.displayName
                        }
                        else{
                            $row.include = $row.include + "`n" + $group.displayName
                        } 
                    }     
                }
            }
            $table.Rows.Add($row)
        }
    }
}

#Display and export the datatable in csv format
function Export-DataTable{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.Data.DataTable]$table,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [System.String]$fileName
    )
    PROCESS{
        $table | Format-Table | Out-String
        $table | Export-Csv $filename -NoTypeInformation
    }
}

#Main
Connect-MSGraph -ForceInteractive
Update-MSGraphEnvironment -SchemaVersion beta
$AllGroups = Get-AADGroup | Get-MSGraphAllPages
$AllConfigurations = Get-Information -resource "deviceConfigurations"
$AllPolicies = Get-Information -resource "configurationPolicies"

$table = New-Object System.Data.DataTable
$col1 = New-Object System.Data.DataColumn(“configuration”)
$col2 = New-Object System.Data.DataColumn(“include”)
$col3 = New-Object System.Data.DataColumn(“exclude”)
$table.columns.Add($col1)
$table.columns.Add($col2)
$table.columns.Add($col3)

Add-Rows -table $table -AllInformation $AllConfigurations
Add-Rows -table $table -AllInformation $AllPolicies
Export-DataTable -table $table -fileName "XXXX.csv"