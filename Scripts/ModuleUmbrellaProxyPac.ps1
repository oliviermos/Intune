<#===========================================================================================================================
Script Name: ModuleUmbrellaProxyPac.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
Description:
    Get proxy settings for Umbrella (Cisco)
    Applied to all users, localsystem, localservice, networkservice

Date Created: 26/10/2022
Last Revised: 28/10/2022
===========================================================================================================================#>
param(
    [switch]$GET = $false,
    [switch]$SET = $false,
    [switch]$RESET = $false,
    [switch]$LEGACY = $false,
    [switch]$SYSTEM = $false,
    [switch]$USER = $false
)

# Variables
$Version = "1.3"
$ScriptName = $MyInvocation.MyCommand.Name

# Functions Get, Set and Reset
Function GetRegistryForSID {
    Param([string]$Name = "<NAME_NOT_GIVEN>", [string]$SID = "<SID_MISSING>")

    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Get registry for $Name (SID $($SID)) :"
    $keyPath = "Registry::HKEY_USERS\$($SID)\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    
    $keyValue = (Get-ItemProperty -Path $keyPath -Name AutoDetect).AutoDetect
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :         Automatically detect settings state : $($KeyValue)"
    
    $keyValue = (Get-ItemProperty -Path $keyPath -Name AutoConfigURL).AutoConfigURL
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :         Autoconfig URL : $($KeyValue)"
    
    $keyValue = (Get-ItemProperty -Path $keyPath -Name ProxyEnable).ProxyEnable
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :         Manual proxy state : $KeyValue"
    
    $keyValue = (Get-ItemProperty -Path $keyPath -Name ProxyServer).ProxyServer
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :         Proxy server value : $KeyValue"

}

Function SetRegistryForSID {
    Param([string]$Name = "<NAME_NOT_GIVEN>", [string]$SID = "<SID_MISSING>")

    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Set registry for $Name (SID $($SID)) :"
    $keyPath = "Registry::HKEY_USERS\$($SID)\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :         Disable automatically detect settings"
    Set-ItemProperty -Path $keyPath -Name AutoDetect -Value 0 -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :         Set Autoconfig URL : $($UmbrellaProxyPac)"
    Set-ItemProperty -Path $keyPath -Name AutoConfigURL -Value $($UmbrellaProxyPac) -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :         Disable Manual proxy"
    Set-ItemProperty -Path $keyPath -Name ProxyEnable -value 0 -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :         Reset Proxy server"
    Set-ItemProperty -Path $keyPath -Name ProxyServer -value "" -force

}

Function ResetRegistryForSID {
    Param([string]$Name = "<NAME_NOT_GIVEN>", [string]$SID = "<SID_MISSING>")

    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :   Reset registry for $Name (SID $($SID)) :"
    $keyPath = "Registry::HKEY_USERS\$($SID)\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Enable automatically detect settings"
    Set-ItemProperty -Path $keyPath -Name AutoDetect -Value 1 -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Clear Autoconfig URL"
    Set-ItemProperty -Path $keyPath -Name AutoConfigURL -Value "" -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Disable Manual proxy"
    Set-ItemProperty -Path $keyPath -Name ProxyEnable -value 0 -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Reset Proxy server"
    Set-ItemProperty -Path $keyPath -Name ProxyServer -value "" -force

}

Function LegacyRegistryForSID {
    Param([string]$Name = "<NAME_NOT_GIVEN>", [string]$SID = "<SID_MISSING>")

    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :   Set LEGACY registry for $Name (SID $($SID)) :"
    $keyPath = "Registry::HKEY_USERS\$($SID)\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Disable automatically detect settings"
    Set-ItemProperty -Path $keyPath -Name AutoDetect -Value 0 -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Clear Autoconfig URL"
    Set-ItemProperty -Path $keyPath -Name AutoConfigURL -Value "" -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Enable Manual proxy"
    Set-ItemProperty -Path $keyPath -Name ProxyEnable -value 1 -force
    
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :      Set Proxy server to $($ProxyServerWSG):$($ProxyPortWSG)"
    Set-ItemProperty -Path $keyPath -Name ProxyServer -value "$($ProxyServerWSG):$($ProxyPortWSG)" -force

}

# Variables

# Change the ErrorActionPreference to 'Continue'
$ErrorActionPreference = 'Continue'

# WSG is LEGACY
# !!! Will be removed soon and not necessary after Umbrella migration
$ProxyServerWSG = "wsg.intra.corp.grp"
$ProxyPortWSG = "8080"

# Cisco Proxy Pac
$UmbrellaProxyPac = "https://proxy.prod.pac.swg.umbrella.com/8021365hadb75c9c8fd5f5e4b462d845/proxy.pac"

# Starting...
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version)"

If($GET) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Get registry status around proxy settings"
} elseif($SET) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Set registry around proxy settings for Cisco Umbrella"
} elseif($RESET) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Reset registry around proxy settings"
} elseif($LEGACY) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Set LEGACY registry around proxy settings"
} else {
    $GET = $true
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! WARNING !!! No action choosen (GET, SET or RESET) : GET set by default !"
}

# Regex pattern for user SIDs
# Domain users: S-1-5-21-*-*-*-*
# Azure users : S-1-12-1-*-*-*-*
# Service acounts : S-1-5-18|19|20
If($USER -and $SYSTEM) {
    $PatternSID = "(S-1-5-21|S-1-12-1|S-1-5-18|S-1-5-19|S-1-5-20)"
} elseif($USER -and !$SYSTEM) {
    $PatternSID = "(S-1-5-21|S-1-12-1)"
} elseif(!$USER -and $SYSTEM) {
    $PatternSID = "(S-1-5-18|S-1-5-19|S-1-5-20)"
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! WARNING !!! No scope choosen (USER and/or SYSTEM) : set to USER and SYSTEM by default !"
    $PatternSID = "(S-1-5-21|S-1-12-1|S-1-5-18|S-1-5-19|S-1-5-20)"
}
 
# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = gp 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID}  | 
    Select  @{name="SID";expression={$_.PSChildName}}, 
            @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
            @{name="Username";expression={$_.ProfileImagePath -replace "^(.*[\\\/])", ""}}
 
# Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
$LoadedHives = gci Registry::HKEY_USERS | ? {$_.PSChildname -match $PatternSID} | Select @{name="SID";expression={$_.PSChildName}}
 
# Get all users that are not currently logged
$UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select @{name="SID";expression={$_.InputObject}}, UserHive, Username

Foreach ($item in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    If($item.SID -in $UnloadedHives.SID) {
        reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
    }
 
    If($GET) {
        GetRegistryForSID -Name $($Item.Username) -SID $($Item.SID)
    } elseif($SET) {
        SETRegistryForSID -Name $($Item.Username) -SID $($Item.SID)
    } elseif($RESET) {
        RESETRegistryForSID -Name $($Item.Username) -SID $($Item.SID)
    } elseif($LEGACY) {
        LegacyRegistryForSID -Name $($Item.Username) -SID $($Item.SID)
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! WARNING !!! No action choosen (GET, SET or RESET) !"
    }
    
    # Unload ntuser.dat        
    If($item.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($Item.SID) | Out-Null
    }
}

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! End ofScript: $($ScriptName) - Version: $($Version)"

Exit 0

