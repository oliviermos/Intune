<#===========================================================================================================================
 Script Name: DeleteWifiProfileByName.ps1
     >>> INCLUDE IN INTUNE KICKSTART <<<
Description: Delete a Wifi profile by name
 
 Input:
    Name: Wifi profile name including wildcards
 
 Output:
    Error code return if no application found of no appname given.
    Wifi profile deleted

 Date Created: 14/03/2022
 Last Revised: 05/09/2022
<#===========================================================================================================================#>
param(
    [string]$Name = ""
)

# Variables
$Version = "1.4"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"

if($Name -ne "") {
    # Get all Wifi profiles
    $list=((netsh.exe wlan show profiles) -match '\s{2,}:\s') -replace '.*:\s' , ''

    # Found Wifi profile matching Name
    Foreach($Profile in $list) {
        if($Profile -like $Name) {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Profile '$($Profile)' matching filter '$($Name)' ... delete profile!"
            netsh wlan delete profile name="$($Profile)"
        } else {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Profile '$($Profile)' not matching filter '$($Name)'"
        }        
    }
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! ERROR !!! Missing profile name to delete in parameter !"
}

# Restore path
Pop-Location

exit $LASTEXITCODE
