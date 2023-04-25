<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Device_SecureChannel.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to remediate if the device secure channel

Created date: 24/08/2022
Last Revised: 22/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "3"

#check if device is part of domain
If ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {

    # PDC to test LDAP connection available: at least one DC is reachable
    $PDC = "prdads16.intra.corp.grp"
    $PDCPort = "389"

    # Test if PDC is reachable and reset computer password
    if((Test-NetConnection -ComputerName $PDC -Port $PDCPort).TcpTestSucceeded) {
        Test-ComputerSecureChannel -Repair -Verbose
    
        Write-Output "Secure channel repair"
    } else {
        Write-Output "[ERROR] Domain controller not found: cannot repair!"
    }
} else {
    Write-Output "Not part of a domain: nothing to do!"
}

Exit 0
