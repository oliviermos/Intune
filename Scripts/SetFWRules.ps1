<#
Name: SetFWRules.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
.SYNOPSIS
   Creates firewall rules for given apps in UDP/TCP on Public/Private blocked and Domain Allow.
   Intially created for Teams due to a bug from Microsoft: user voice vote closed... bug not yet solved.
.DESCRIPTION
   Input:
      RuleName : name of the rule
      RulePath: path to the exe file

   Output:
      Create 6 rules
      3 UDP and 3 TCP
      Public/Private: blocked
      Domain: Allow

Creation date: 28/08/2022
Modification date: 05/09/2022
#>
param(
    [string]$RuleName = "",
    [string]$RulePath = ""
)
# Variables
$Version = "1.5"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

if ($RuleName -ne "" -and $RulePath -ne "") {
    if (Test-Path $RulePath) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ $($RulePath) found"
 
        $FWRulesFound = Get-NetFirewallApplicationFilter -Program $RulePath -ErrorAction SilentlyContinue
        if ($FWRulesFound.count -lt 6) {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Add firewall rules $($RuleName)"

            "UDP", "TCP" | ForEach-Object { New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Profile Domain -Program $RulePath -Action Allow -Protocol $_ }
            "UDP", "TCP" | ForEach-Object { New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Profile Private -Program $RulePath -Action Block -Protocol $_ }
            "UDP", "TCP" | ForEach-Object { New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Profile Public -Program $RulePath -Action Block -Protocol $_ }
        } else {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! All 6 firewall rules for $($RulePath) done!"
        }
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! ERROR !!! $($RulePath) not found!"
    }
} else {
    Write-Host "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! ERROR !!! Parameter(s) empty or null"
    $ReturnCode = $false
}

#  Restore path
Pop-Location

exit $ReturnCode