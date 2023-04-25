<#===========================================================================================================================
Include script: Package_Start.ps1
Description: To include at the begining of the Win32 package script
Date Created: 08/06/2022
Last Revised: 02/11/2022
===========================================================================================================================#>
# Errors code used for creating tag file (can be overriden if necessary)
$ReturnCodeOK = @(0,"Success",1707,"Success",3010,"Soft reboot",1641,"Hard reboot")
$ReturnCodeRetry = @(1618,"Retry")
$ReturnCodeFailed = @(-1,"Failed")

# Error codes for the package: should be override if necessary
$PackageCodeOK = @(0,"Success",1603,"Apps present",17002,"Apps present",17006,"Apps present")
$ReturnCodeFailed = @(-1,"Failed")

# Variables
$LogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"
$LogFile = $LogPath + "$($ScriptName)-V$($Version).log"

# Set path to current script folder
Push-Location $SourcePath

# Create log file
if(!(Test-Path $LogPath)) { New-Item -ItemType Directory -Force -Path $LogPath }

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"  *>> $LogFile
If($Uninstall) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! WARNING !!! Uninstall will be processed !"  *>> $LogFile
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Install will be processed..."  *>> $LogFile
}
# Copy package
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Copy package..." *>> $LogFile
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Source Path:$($SourcePath)"  *>> $LogFile
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Destination Path:$($DestPath)" *>> $LogFile
If(!(Test-Path $DestPath)) { New-Item -ItemType Directory -Force -Path $DestPath  *>> $LogFile }
If($SourcePath -ne $DestPath) { Copy-Item -Path $SourcePath\* -Destination $DestPath -Recurse -force *>> $LogFile }

# Delete file(s) tag and create installing tag
Remove-item "$($DestPath)\$($ScriptName)-*.tag" -Force *>> $LogFile
Set-Content "$($DestPath)\$($ScriptName)-V$($Version)-InProgress.tag" "In progress..." *>> $LogFile

# Get ESP Status
$ESPStatus = & "$($DestRootPath)\Scripts\CheckESPStatus.ps1"

# ESP return status
$DeviceSetupInProgress = 0
$DeviceSetupComplete = 1
$UserSetupInProgress = 2
$UserSetupComplete = 3
$AutopilotFailed = 4
$NotAutopilot = 5

Switch ($ESPStatus) {
    $DeviceSetupInProgress { $ESPStatusText = "DeviceSetupInProgress" }
    $DeviceSetupComplete { $ESPStatusText = "DeviceSetupComplete" }
    $UserSetupInProgress { $ESPStatusText = "UserSetupInProgress" }
    $UserSetupComplete { $ESPStatusText = "UserSetupComplete" }
    $AutopilotFailed { $ESPStatusText = "AutopilotFailed" }
    $NotAutopilot { $ESPStatusText = "NotAutopilot" }
}

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : ESP status: $ESPStatusText ($ESPStatus)" *>> $LogFile

# Analyse Profile file
$ProfileName = Resolve-Path "$($DestRootPath)\*.Profile" | Split-Path -leaf
$Profile = $ProfileName.Substring(0, $ProfileName.IndexOf("."))

# Check choco package installed and get version
If(-not [string]::IsNullOrEmpty($PackageName)) {
    $ChocoResult = "$(choco find "$PackageName" -localonly | Select-String "$PackageName")"
    
    If(-not [string]::IsNullOrEmpty($ChocoResult)) {
        $ChocoVersion = $ChocoResult.split(" ")[1]
        $SplitChocoVersion = $ChocoVersion.Split(".")
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! Warning !!! Choco $PackageName package found with version $ChocoVersion !" *>> $LogFile
        $ChocoFound = $true
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! Warning !!! Choco $PackageName package not found: possible conflict during installation that could be viewed as success !" *>> $LogFile
        $ChocoFound = $false
    }
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! Warning !!! Not a Choco install: installation conflict could be viewed as success !" *>> $LogFile
}
