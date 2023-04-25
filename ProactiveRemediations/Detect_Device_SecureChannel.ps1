<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Device_SecureChannel.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device secure channel is ok

Created date: 24/08/2022
Last Revised: 22/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "3"

#check if device is part of domain
If ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
    # Check tag file
    If(Test-ComputerSecureChannel) {
        Write-Output "Secure Channel OK"
        Exit 0
    } else {
        Write-Output "Secure Channel to repair!"
        Exit 1
    }
} else {
    Write-Output "Not part of a domain: nothing to do!"
    Exit 0
}