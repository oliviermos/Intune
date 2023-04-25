#########################################################
############### Author : Benjamin Follet ################
######### Email : Benjamin.follet@econocom.com ##########
###################  Date 10/01/2023 ####################
#########################################################

# Script Purpose : It allows you to rename all Colisée devices with the inventaire file according to the naming policy defined.   

# Define and fill the DataTable Columns
function Set-DataBase() {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [system.Data.DataTable]$Table,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [string]$Path
    )

    BEGIN {

        # Variables
        [int]$Name_Index = 0
        [int]$Serial_Number_Index = 0
        [string]$WorkSheetName = "Flotte TB Intégrée à Intune"

        $Excel = New-Object -ComObject Excel.Application
        $Excel.Visible = $false
        $Workbook  = $Excel.Workbooks.Open($Path)
        $Worksheet = $Workbook.Worksheets.Item($WorkSheetName)
        $totalNoOfRecords = ($WorkSheet.UsedRange.Rows).count  
        $totalColumns = ($WorkSheet.UsedRange.Columns).count 
    }


    PROCESS {
        # Processing with begin and parameters variables.
        for ($index = 1; $index -lt $totalColumns + 1; $index++) {
            if ($WorkSheet.Cells.Item(1, $index).text -eq "Nom Intune") {
                $Name_Index = $index
            }
            elseif ($WorkSheet.Cells.Item(1, $index).text -eq "S/N") {
                $Serial_Number_Index = $index
            }

            elseif ($Name_Index -ne 0 -and $Serial_Number_Index -ne 0 ) {
                break
            }
        }
            
        if ($Name_Index -eq 0 -or $Serial_Number_Index -eq 0) {
            Write-host "Verifier le nom des colonnes, l'une d'entre elle n'a pas été trouvée sur le fichier excel"
            exit
        }

        for ($element = 2; $element -lt $totalNoOfRecords + 1; $element++) {
            
            $row = $Table.NewRow()
            $row.Name = ($WorkSheet.Cells.Item($element, $Name_Index).text)
            $row.Serial_Number = ($WorkSheet.Cells.Item($element, $Serial_Number_Index).text)
            $Table.Rows.Add($row) 
        }
    }

    
    END {
        $WorkBook.close($false)
        $Excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Worksheet) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        return ,$Table
    }
} 


# Set the device name on Intune tenant
function Set-DeviceName() {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [System.String]$deviceID,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [System.String]$newDeviceName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
        [System.String]$serialNumber
    )

    PROCESS {

        $body = "{
            `"deviceName`":`"$($newDeviceName)`"
         }"

        $body1 = "{
            `"managedDeviceName`":`"$($newDeviceName)`"
        }"

        $graphApiVersion = "beta"
        $Resource = "deviceManagement/managedDevices('$deviceID')/setDeviceName"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        for ($i = 0; $i -lt 2; $i++) {
            if ($i -eq 1) {
                $Resource = "deviceManagement/managedDevices('$deviceID')"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                $body = $body1
                
                Invoke-MSGraphRequest -HttpMethod PATCH -Url $uri -Content $body1  
            }
            else {
                Invoke-MSGraphRequest -HttpMethod POST -Url $uri -Content $body
            }
        } 
    }
    END {
        "La requête a bien été envoyé pour l'appareil qui a pour numéro de série: " + $SerialNumber | Out-File -FilePath $pathDevice -Append
    }   
} 

# Set the device name on Intune tenant
function Get-DeviceName() {
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [system.Data.DataTable]$Table,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [Object]$DeviceIntune
    )

    PROCESS {
        foreach($device in $Table){
            if($DeviceIntune.serialNumber -eq $device.Serial_Number){
                Set-DeviceName -deviceID $DeviceIntune.Id -newDeviceName $device.Name -serialNumber $device.Serial_Number
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
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{InitialDirectory = [Environment]::GetFolderPath('Desktop')}
$FileBrowser.Filter= "Documents (*.docx)|*.docx|SpreadSheet (*.xlsx)|*.xlsx" 
$null = $FileBrowser.ShowDialog()
$pathExcelFile =$FileBrowser.FileName 

[system.Data.DataTable]$Table = New-Object system.Data.DataTable 'DataBase'
$newcol = New-Object system.Data.DataColumn Name, ([string]); $Table.columns.add($newcol)
$newcol = New-Object system.Data.DataColumn Serial_Number, ([string]); $Table.columns.add($newcol)

# Main
#Cleaning of log files
if (Test-Path -Path $pathDevice) {
    Clear-Content $pathDevice
}
else {
    New-Item -Path $pathDevice
}

# Connect and change schema 
Connect-MSGraph -ForceInteractive
Update-MSGraphEnvironment -SchemaVersion beta

$AllDevices = Get-IntuneManagedDevice | Get-MSGraphAllPages
$Table = Set-DataBase -Table $Table -Path $pathExcelFile
foreach($device in $allDevices){
    if($device.deviceName -notmatch '^[A-Z]{3,4}[0-9]{0,1}-(TBPRO|TBGUEST|TBATM)\w{3}\Z'){
        Get-DeviceName -Table $Table -DeviceIntune $device
    }
}
