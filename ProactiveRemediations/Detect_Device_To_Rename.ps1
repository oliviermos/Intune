<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Device_To_Rename.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device hostname need to be renamed: if S/N is missing partially, renaming is required
    Hostname should containt at least the last 11 numbers for long S/N

Created date: 16/09/2022
Last Revised: 16/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1"

# Get Hostname and S/N
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$FullSerialNumber = (Get-CimInstance -ClassName Win32_bios | Select-Object -Property "SerialNumber").SerialNumber

$FullSerialNumber = "1232123"

# If S/N is greater than 11 letters, trunc it
If($SerialNumber.Length -gt 11) {
    $TrunckedSerialNumber = $FullSerialNumber.Substring($FullSerialNumber.Length - 11,11)
} else {
    $TrunckedSerialNumber = $FullSerialNumber
}

$Hostname = "LAUTFR1232123"

# Check S/N in Hostname
If($Hostname.IndexOf($TrunckedSerialNumber) -eq -1) {
    Write-Output "[ERROR] Hostname $Hostname doesn't contain the last 11 numbers of S/N $FullSerialNumber ! Renaming required"
    Exit 1 # Renaming to do
} else {
    Write-Output "[OK] Hostname $Hostname contain S/N $FullSerialNumber"
    Exit 0 # Nothing to do
}
