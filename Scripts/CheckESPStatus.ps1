<#===========================================================================================================================
Name: CheckESPStatus.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

.SYNOPSIS
   Return value (nothing in step 1 as no apps could run)
     - 0 : Device Setup in progress ... step 2 normally (i.e Autopilot Erollment Status Page)
     - 1 : Device Setup complete.. if failed also, it's complete... current user logged (i.e Autopilot Erollment Status Page)
     - 2 : User Setup in progress... during first login... desktop not visible
     - 3 : User Setup complete
     - 4 : Autopilot failed! Autopilot process doen't registered correclty the installation (found in DMS devices from 2021)
     - 5 : Not Autopilot... current user logged (INTRA, BYOD managed, MTR, etc.)

.DESCRIPTION

Creation date: 09/05/2022
Modification date: 23/09/2022
===========================================================================================================================#>
# Variables
$Version = "3.3"
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$LogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"
$LogFile = $LogPath + "$($ScriptName)-V$($Version).log"

# ESP return status
$DeviceSetupInProgress = 0
$DeviceSetupComplete = 1
$UserSetupInProgress = 2
$UserSetupComplete = 3
$AutopilotFailed = 4
$NotAutopilot = 5

# Set path to current script folder
Push-Location (Split-Path $MyInvocation.MyCommand.Path)

# Change the ErrorActionPreference to 'Continue'
$ErrorActionPreference = 'Continue'

# Create log file
if(!(Test-Path $LogPath)) { New-Item -ItemType Directory -Force -Path $LogPath }

# Display Script name, version, Hostname, S/N and IPV4
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$IPV4 = & "$($DestRootPath)\Scripts\GetIPV4Address.ps1"
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Script: $($ScriptName) - Version: $($Version) - Hostname: $($Hostname) - Serial Number : $($SerialNumber) - IP: $($IPV4)"  *>> $LogFile

#---------------------------------------------------------------------------------------------------------------------------
# Check ESP Status based on user(s) profile(s) state
# If the ESP Status found with registry is DeviceSetupInProgress and user profile found, return Autopilot failed to avoir auto reboot
#---------------------------------------------------------------------------------------------------------------------------
# Users path
$UsersRootPath = "C:\Users" #Static path... beware to other Windows language: normally supported.

# Get all Users paths except Default(s) and Public 
$UsersPaths = (get-childitem -path $UsersRootPath).FullName
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : All users profile found in $UsersRootPath path :" *>> $LogFile
$UsersPaths *>> $LogFile

$UsersPaths = (get-childitem -path $UsersRootPath | Where-Object { ($_.Name -notlike "default*") } | Where-Object { ($_.Name -notlike "public*") }).FullName
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : All users profile found in $UsersRootPath path (Exclude: Default*, Public*):" *>> $LogFile
$UsersPaths *>> $LogFile

If($UsersPaths.Count -lt 1) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! WARNING !!! Autopilot installation in progress !" *>> $LogFile
    $UserProfileFound = $false
} else {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Active user(s) profile(s) found (Exclude: Default*, Public*) => Running at least in one user session" *>> $LogFile
    $UserProfileFound = $true
}

#---------------------------------------------------------------------------------------------------------------------------
# Check ESP Status based on registry values
#---------------------------------------------------------------------------------------------------------------------------
# Autopilot registry keys
$AutoPilotSettingsKey = 'HKLM:\SOFTWARE\Microsoft\Provisioning\AutopilotSettings'
$DevicePrepName = 'DevicePreparationCategory.Status'
$DeviceSetupName = 'DeviceSetupCategory.Status'
$AccountSetupName = 'AccountSetupCategory.Status'

$AutoPilotDiagnosticsKey = 'HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot'
$TenantIdName = 'CloudAssignedTenantId'

$JoinInfoKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'

$CloudAssignedTenantID = (Get-ItemProperty $AutoPilotDiagnosticsKey -Name $TenantIdName -ErrorAction 'Ignore').$TenantIdName
Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Cloud assigned Tenant Id: $CloudAssignedTenantID" *>> $LogFile

#---------------------------------------------------------------------------------------------------------------------------
# Check if device is/was autopilot installed
if (-not [string]::IsNullOrEmpty($CloudAssignedTenantID)) {

    # Get AAD Tenant ID (null during ESP for HAADJ
    $AzureADTenantId = ""
    foreach ($Guid in (Get-ChildItem -Path $JoinInfoKey -ErrorAction 'Ignore')) {
        $AzureADTenantId = (Get-ItemProperty -Path "$JoinInfoKey\$($Guid.PSChildName)" -Name 'TenantId' -ErrorAction 'Ignore').'TenantId'
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Azure AD Tenant Id: $AzureADTenantId" *>> $LogFile
    }

    # Check Azure AD tenand ID and Cloud assignemt Tenant ID: equal MANDATORY except for on-prem Hybrid (INTRA legacy)
    if ($AzureADTenantId -eq "") {
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Warning !!! Azure AD Tenant Id not found: on-prem Hybrid not register?" *>> $LogFile
    } else {
        # Check equal?
        if ($CloudAssignedTenantID -eq $AzureADTenantId) {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : +++ Cloud assignement Tenant ID are equal to Azure AD Tenant Id" *>> $LogFile
        } else {
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! ERROR !!! Tenant Id assigned not equal to Azure joined tenant ID !" *>> $LogFile
        }
    }

    #---------------------------------------------------------------------------------------------------------------------------
    # Check ESP states
    #---------------------------------------------------------------------------------------------------------------------------
    # Step 1: Device Prep

    $DevicePrepDetails = (Get-ItemProperty -Path $AutoPilotSettingsKey -Name $DevicePrepName -ErrorAction 'Ignore').$DevicePrepName

    if (-not [string]::IsNullOrEmpty($DevicePrepDetails)) {
        $DevicePrepDetails = $DevicePrepDetails | ConvertFrom-Json
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> DevicePrepDetails:" *>> $LogFile
        $DevicePrepDetails *>> $LogFile

        $DevicePrepState = $DevicePrepDetails.categoryState
        $DevicePrepSucceded = $DevicePrepDetails.categorySucceeded
        $DevicePrepStatusMessage = $DevicePrepDetails.categoryStatusMessage

        if([string]::IsNullOrEmpty($DevicePrepStatusMessage)) {
            $DevicePrepStatusMessage = $DevicePrepDetails.categoryStatusText # other registry name
            if([string]::IsNullOrEmpty($DevicePrepStatusMessage)) {
                $DevicePrepStatusMessage = "No value found (ERROR)"
            }
        }

        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Device prepratation status message: $DevicePrepStatusMessage" *>> $LogFile
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Device preparation state: $DevicePrepState" *>> $LogFile
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Device preparation state: $DevicePrepSucceeded" *>> $LogFile

        # !!! This script cannot be run in this step: it's Step 2 or during user session... nothing else to to

        #---------------------------------------------------------------------------------------------------------------------------
        # Step 2: Device Setup
        
        $DeviceSetupDetails = (Get-ItemProperty -Path $AutoPilotSettingsKey -Name $DeviceSetupName -ErrorAction 'Ignore').$DeviceSetupName
        
        if (-not [string]::IsNullOrEmpty($DeviceSetupDetails)) {
            $DeviceSetupDetails = $DeviceSetupDetails | ConvertFrom-Json
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> DeviceSetupDetail:" *>> $LogFile
            $DeviceSetupDetails *>> $LogFile

            $DeviceSetupState = $DeviceSetupDetails.categoryState
            $DeviceSetupSucceeded = $DeviceSetupDetails.categorySucceeded

            $DeviceSetupStatusMessage = $DeviceSetupDetails.categoryStatusMessage

            if([string]::IsNullOrEmpty($DeviceSetupStatusMessage)) {
                $DeviceSetupStatusMessage = $DevicePrepDetails.categoryStatusText # other registry name
                if([string]::IsNullOrEmpty($DeviceSetupStatusMessage)) {
                    $DeviceSetupStatusMessage = "No value found (ERROR)"
                }
            }
            
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Device setup status message: $DeviceSetupStatusMessage" *>> $LogFile
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Device setup state: $DeviceSetupState" *>> $LogFile
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Device setup succeeded: $DeviceSetupSucceeded" *>> $LogFile

            # Check device setup status
            if (($DeviceSetupState -eq 'succeeded') -or ($DeviceSetupState -like '*failed*') -or ($DeviceSetupSucceeded -eq 'True')) {
                $ESPStatus = $DeviceSetupComplete

                #---------------------------------------------------------------------------------------------------------------------------
                # Step 3: User Setup
                
                $AccountSetupDetails = (Get-ItemProperty -Path $AutoPilotSettingsKey -Name $AccountSetupName -ErrorAction 'Ignore').$AccountSetupName
                
                if (-not [string]::IsNullOrEmpty($AccountSetupDetails)) {
                    $AccountSetupDetails = $AccountSetupDetails | ConvertFrom-Json
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> AccountSetupDetails:" *>> $LogFile
                    $AccountSetupDetails *>> $LogFile

                    $AccountSetupState = $AccountSetupDetails.categoryState
                    $AccountSetupSucceeded = $AccountSetupDetails.categorySucceeded
                    $AccountSetupStatusMessage = $AccountSetupDetails.categoryStatusMessage

                    if([string]::IsNullOrEmpty($AccountSetupStatusMessage)) {
                        $AccountSetupStatusMessage = $DevicePrepDetails.categoryStatusText # other registry name
                        if([string]::IsNullOrEmpty($AccountSetupStatusMessage)) {
                            $AccountSetupStatusMessage = "No value found (ERROR)"
                        }
                    }

                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Account setup status message: $AccountSetupStatusMessage" *>> $LogFile
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Account setup state: $AccountSetupState" *>> $LogFile
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> Account setup succeeded: $AccountSetupSucceeded" *>> $LogFile

                    #---------------------------------------------------------------------------------------------------------------------------
                    # After Account Setup started, the ESP Status is "Complete" and we can consider during user session
                    if (($AccountSetupState -eq 'succeeded') -or ($AccountSetupState -like 'notStarted') -or ($AccountSetupState -like '*failed*') -or ($AccountSetupSucceeded -eq 'True')) {
                        $ESPStatus = $UserSetupComplete
                    } else {
                        $ESPStatus = $UserSetupInProgress
                    }
                } else {
                    #---------------------------------------------------------------------------------------------------------------------------
                    # Step 3: User Setup not found! Bad Autopilot installation?
                    #---------------------------------------------------------------------------------------------------------------------------
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Failed !!! Account setup state not found !" *>> $LogFile

                    $ESPStatus = $UserSetupInProgress # go back in device setup? Waiting starting user setup?
                }
            } else {
                # Check if user profile exist
                If($UserProfileFound) {
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Failed !!! Device setup in progress but user profile found => Autopilot installation is failed !" *>> $LogFile
                    $ESPStatus = $AutopilotFailed
                } else {
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! WARNING !!! Device setup always in progress as account setup not yet started !" *>> $LogFile
                    $ESPStatus = $DeviceSetupInProgress
                }
            }
            
        } else {
            #---------------------------------------------------------------------------------------------------------------------------
            # Step 2: Device Setup not found! Bad Autopilot installation?
            #---------------------------------------------------------------------------------------------------------------------------
            $ESPStatus = $AutopilotFailed
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Failed !!! Device setup state not found !" *>> $LogFile
        }

    } else {
        #---------------------------------------------------------------------------------------------------------------------------
        # Step 1: Device Prep no found! Bad Autopilot installation?
        #---------------------------------------------------------------------------------------------------------------------------
        $ESPStatus = $AutopilotFailed
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! Failed !!! Device preparation state not found !" *>> $LogFile
    }

} else {
    #---------------------------------------------------------------------------------------------------------------------------
    # Autopilot informations not found: it's not an autopilot device!
    #---------------------------------------------------------------------------------------------------------------------------
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! ERROR !!! Not Autopilot device as cloud assigned Tenant Id empty >>> Not running in ESP!" *>> $LogFile
    $ESPStatus = $NotAutopilot
}

Switch ($ESPStatus) {
    $DeviceSetupInProgress { $ESPStatusText = "DeviceSetupInProgress" }
    $DeviceSetupComplete { $ESPStatusText = "DeviceSetupComplete" }
    $UserSetupInProgress { $ESPStatusText = "UserSetupInProgress" }
    $UserSetupComplete { $ESPStatusText = "UserSetupComplete" }
    $AutopilotFailed { $ESPStatusText = "AutopilotFailed" }
    $NotAutopilot { $ESPStatusText = "NotAutopilot" }
}

Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : Return code : $ESPStatusText ($ESPStatus)" *>> $LogFile

# Restore path
Pop-Location

Return $ESPStatus
