<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Name: SetEconocomProxy.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Script to fix the proxy server to Umbrella (if installed) or legacy proxies (wsg or ironweb on port 8080) when the device is on corporate network

Return code: 0 (see logs for details to see the settings really done)

Creation date: 21/02/2022
Modification date: 20/12/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "4.93"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$LogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"
$LogFile = $LogPath + "$($ScriptName)-V$($Version).log"

# Analyse Profile file
$ProfileName = Resolve-Path "$($DestRootPath)\*.Profile" | Split-Path -leaf
$Profile = $ProfileName.Substring(0, $ProfileName.IndexOf("."))

#===========================================================================================================================
# Functions
#===========================================================================================================================
Function CheckWebSite {
    param(
        [String]$WebSiteName,
        [String]$WebSiteUrl
    )
    $CheckWebUrl = Invoke-WebRequest -uri $WebSiteUrl -ErrorAction SilentlyContinue
    $WebResult = $false
    if([string]::IsNullOrEmpty($CheckWebUrl)) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Failed !!! $($WebSiteName) $($WebSiteUrl) fail to resolved the remote name !"  *>> $LogFile
    } elseif($($CheckWebUrl.StatusCode) -eq 200) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ $($WebSiteName) $($WebSiteUrl) Web access is OK"  *>> $LogFile
        $WebResult = $true
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! $($WebSiteName) $($WebSiteUrl) Web access status code: $($CheckWebUrl.StatusCode)"  *>> $LogFile
    }

    Return $WebResult
}

#===========================================================================================================================

# Create log file
if(!(Test-Path $LogPath)) { New-Item -ItemType Directory -Force -Path $LogPath }

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"  *>> $LogFile

# URL on Internet to check access when proxy is set
$ExtMSURI = "https://login.microsoft.com"

# URL(s) for Choco repo(s)
$ExtChocoURI = "https://community.chocolatey.org/api/v2"

$ExtChocoSource = "chocolatey"
$IntChocoSource01 = "prdchorep01"
$IntChocoURI01 = "http://prdchorep01.intra.corp.grp/chocolatey"

# Chocolatey paths
$ChocolateyPath = "C:\ProgramData\Chocolatey\"
$ChocolateyBinPath = "$($ChocolateyPath)\bin"
$ChocolateyPathFromEnv = "$($env:ChocolateyInstall)"

# WSG is LEGACY
# !!! Will be removed soon and not necessary after Umbrella migration
$ProxyServerWSG = "wsg.intra.corp.grp"
$ProxyPortWSG = "8080"

# Network for Pilot Umbrella
# 10.9.23.0/24: VLAN 23 integration on Plessis
# DEV 10.9.92.0/23: WIFI ECO_PROD/ECO-WIFI Plessis
# DEV 10.9.94.0/23: LAN ECO_PROD Plessis
# DEV 192.168.1.0/24: VLAN Box (Sacha)
If($Profile -eq "DEV") {
    $VLANUmbrellaPilote = "(10.9.23.\d+|10.9.9[2-5].\d+|192.168.1.\d+)"
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Profile $($Profile): network range is $($VLANUmbrellaPilote) and force Umbrella proxy pac (no WSG)"  *>> $LogFile
} elseIf($Profile -eq "DEV_NO_UMBRELLA") {
    $VLANUmbrellaPilote = "10.9.2x.\d+"
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Profile $($Profile): network range is $($VLANUmbrellaPilote) and force Umbrella proxy pac (no WSG)"  *>> $LogFile
} else {
    $VLANUmbrellaPilote = "10.9.23.\d+"
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Profile $($Profile): network range is $($VLANUmbrellaPilote) and force Umbrella proxy pac (no WSG)"  *>> $LogFile
}

# !!! End of part to remove avec Umbrella migration

# Umbrella agent
$UmbrellaTagFile="$($DestRootPath)\Win32Packages\Umbrella_Setup\Umbrella_Setup.ps1-V*-Installed.tag"

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

#===========================================================================================================================
# Set proxy regarding Umbrella and legacy Econocom Proxies
#===========================================================================================================================

If(Test-Path $UmbrellaTagFile) {
    # Umbrella agent installed: no proxy legacy to use
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Umbrella (from Cisco) is installed: no legacy proxy to use" *>> $LogFile
    & "$($DestRootPath)\Scripts\ModuleUmbrellaProxyPac.ps1" -SET *>> $LogFile

    $LegacyProxySet = $false
    $ProxyNameSet = "Cisco Proxy applied (Cisco Umbrella installed)"

} elseif($IPV4 -match $VLANUmbrellaPilote) {
    # internal server visible: we are on site/vpn without access to WSG, it's an Umbrella pilot network
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Network for Umbrella pilot : $($IPV4) is in $($VLANUmbrellaPilote) !" *>> $LogFile
    & "$($DestRootPath)\Scripts\ModuleUmbrellaProxyPac.ps1" -SET *>> $LogFile

    $LegacyProxySet = $false
    $ProxyNameSet = "Cisco Proxy applied (Cisco Umbrella no yet installed)"

} else {
    # !!! Will be removed after Umbrella migration
    # Reset proxy settings before set again legacy proxy on system accounts (necessary when rool backing from Umbrella)
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Umbrella (from Cisco) not installed: legacy proxy used if on site/vpn !" *>> $LogFile
    & "$($DestRootPath)\Scripts\ModuleUmbrellaProxyPac.ps1" -RESET *>> $LogFile

    if((Test-NetConnection -ComputerName $ProxyServerWSG -Port $ProxyPortWSG).TcpTestSucceeded) {
        # Set WSG proxy 8080    
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Set Econocom proxy $($ProxyServerWSG):$($ProxyPortWSG)"  *>> $LogFile
        & "$($DestRootPath)\Scripts\ModuleUmbrellaProxyPac.ps1" -LEGACY -SYSTEM *>> $LogFile

        $LegacyProxySet = $true
        $ProxyNameSet = "$($ProxyServerWSG)"

    } else {
        # No proxy servers found: check if we are in Umbrella pilot
        $WebChocoInt = CheckWebSite -WebSiteName "Chocolatey internal repo" -WebSiteUrl $($IntChocoURI01)
        If($WebChocoInt) {
            # internal server visible: we are on site/vpn without access to WSG, it's an Umbrella pilot network
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! No WSG found: Umbrella pilot !" *>> $LogFile
            & "$($DestRootPath)\Scripts\ModuleUmbrellaProxyPac.ps1" -SET *>> $LogFile

            $LegacyProxySet = $false
            $ProxyNameSet = "Cisco Proxy applied (Cisco Umbrella no yet installed)"
        } else {
            # No proxy, go back in DIRECT connection (no proxy)
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Proxy not found => Reset proxy to DIRECT already done !" *>> $LogFile
            $LegacyProxySet = $false
            $ProxyNameSet = "AUTODETECT"
        }
    }
    # !!! End of part to remove avec Umbrella migration
}

#===========================================================================================================================
# Check Internet connectivity
#===========================================================================================================================
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Check Internet access:"  *>> $LogFile

# Waiting at least 3mn to check real Internet access (with chocolatey communauty here) with 30s between each check at least
$TotalSecondsFromStart = 0 #seconds... init time
$TimeoutSecondsFromCheck = 30 #seconds... before checking again
$TimeOutSecondsFromStart = 180 #seconds... 3 mn before stop checking end

$StartDate = Get-Date
Do {
    $CheckDate = Get-Date
    $WebChocoExt = CheckWebSite -WebSiteName "Chocolatey external repo" -WebSiteUrl $($ExtChocoURI)
    If(-not $WebChocoExt) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  Waiting at least $($TimeoutSecondsFromCheck)s before checking again" *>> $LogFile
        Do {
            $EndDate = Get-Date
            $TotalSecondsCheckDate = [math]::Round((New-TimeSpan -Start $CheckDate -End $EndDate).TotalSeconds)
        } until ($TotalSecondsCheckDate -ge $TimeoutSecondsFromCheck)

        $TotalSecondsFromStart = [math]::Round((New-TimeSpan -Start $StartDate -End $EndDate).TotalSeconds)
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  Retry to reach Chocolatey external repo $($ExtChocoURI) : Timeout in $($TimeOutSecondsFromStart - $TotalSecondsFromStart)s ..." *>> $LogFile
    }
} until ($WebChocoExt -or $TotalSecondsFromStart -ge $TimeOutSecondsFromStart)

If($WebChocoExt) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! Warning !!! Chocolatey external repo $($ExtChocoURI) is successfully reached after $($TotalSecondsFromStart)s !" *>> $LogFile
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! Failed !!! Cannot reach Chocolatey external repo $($ExtChocoURI) in $($TotalSecondsFromStart)s !" *>> $LogFile
}

# Check Microsoft web site always allow on site (not blocked)
$WebMS = CheckWebSite -WebSiteName "Microsoft login access" -WebSiteUrl $($ExtMSURI)

# Check Internal Chocolatey repo to choose the repository for choco install
$WebChocoInt = CheckWebSite -WebSiteName "Chocolatey internal repo" -WebSiteUrl $($IntChocoURI01)

# !!! Will be removed after Umbrella migration
#===========================================================================================================================
# For legacy proxy, go to direct if Internet check failed
#===========================================================================================================================
If($LegacyProxySet) {
    IF($WebMS) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Proxy found and Internet access successeded => Econocom proxy is $ProxyNameSet !"  *>> $LogFile
    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Proxy not found or Internet access failed => Reset proxy settings for USER & SYSTEM!"  *>> $LogFile
        & "$($DestRootPath)\Scripts\ModuleUmbrellaProxyPac.ps1" -RESET *>> $LogFile

        $LegacyProxySet = $false
        $ProxyNameSet = "AUTODETECT"
    }
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! No legacy proxy set !"  *>> $LogFile
}
# !!! End of part to remove avec Umbrella migration

#===========================================================================================================================
# Check Choco installed before assigning repository
#===========================================================================================================================

If((Test-Path $ChocolateyBinPath)) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  +++ Found $ChocolateyBinPath" *>> $LogFile
    
    If(-not [string]::IsNullOrEmpty($ChocolateyPathFromEnv)) {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  +++ Found $ChocolateyPathFromEnv" *>> $LogFile
        
        # Set internal Choco repo if found
        If($WebChocoInt) {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Internal Choco repo $IntServerChoco01 => enable internal choco repo only !"  *>> $LogFile
            choco source disable -n="$($ExtChocoSource)" *>> $LogFile
            choco source enable -n="$($IntChocoSource01)" *>> $LogFile
        } else {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Internal Choco repo $IntServerChoco01 not found => enable external choco repo $ExtServerChoco only !"  *>> $LogFile
            choco source enable -n="$($ExtChocoSource)" *>> $LogFile
            choco source disable -n="$($IntChocoSource01)" *>> $LogFile
        }
        # Display Choco sources result
        Choco sources *>> $LogFile

    } else {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Chocolatey path exist but not found in environnement variables : don't setup source !" *>> $LogFile
    }

} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Chocolatey not found: don't setup source !" *>> $LogFile
}

#===========================================================================================================================
# End of script
#===========================================================================================================================

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Connection set to $ProxyNameSet !"  *>> $LogFile
& "$($DestRootPath)\Scripts\ModuleUmbrellaProxyPac.ps1" -GET *>> $LogFile

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! End of Script: $($ScriptName) - Version: $($Version)"  *>> $LogFile

#  Restore path
Pop-Location

exit 0
