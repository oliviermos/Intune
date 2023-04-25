<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Device_Rename.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device need to be renamed
   Device HAADJ with random: replace random by serial
   Device AADJ with old name: renamed to the new naming convention (LAUTFR to LAFR for example)
   Device Legacy with a chrono: replace chrono by serial

Get model, country and serial to build new name: if current name not equal, renaming required

Created date: 16/12/2022
Last Revised: 16/12/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1"
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\\ProactiveRemediations"
$TagFile = "$($DestPath)\Device-Rename-Done.tag"


# Get informations from device
$Current_Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber
$HardwareType = (Get-WmiObject -Class Win32_ComputerSystem -Property PCSystemType).PCSystemType
    # https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystem
    # Mobile = 2
If($HardwareType -eq 2 ) {
    $Prefix = "L"
} else {
    $Prefix = "D"
}

#check if device is part of domain
If ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
    $SerialSizeMax = 11 # Surface HAADJ with S/N 01234567890123 will be LFR34567890123
} else {
    $Prefix = "$($Prefix)A" # A for AADJ
    $SerialSizeMax = 10 # Surface AADJ with S/N 01234567890123 will be  LAFR4567890123
}

# Get country code from system local (not based on OU in AD or user preferred language
$WinSystemLocal = (GET-WinSystemLocale).Name
$Country = $WinSystemLocal.Substring(3,2) # from fr-FR return FR

# Build new name
$Current_Hostname = "LFR-azioeuazoieu"
$New_Hostname = "$($Prefix)$($Country)$($TrunckedSerialNumber)"

# Check current and new hostname
If($Current_Hostname -eq $New_Hostname) {
    Write-Output "[OK] Current hostname $Current_Hostname is compliant"
        
    # create missing tag file
    #Set-Content "$($TagFile)" "Device renaming not needed for $Current_Hostname" -Force

    Exit 0 # Nothing to do
} else {
    Write-Output "[ERROR] Current hostname $Current_Hostname will be renamed in $New_Hostname"
    Exit 1 # Renaming to do
}

