<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Device_pwdLastSet.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to remediate if the device pwdLastSet is not too old
We think that this is an incident arount ECO-WIFI issue with the radius (Error code 16)

Created date: 23/08/2022
Last Revised: 22/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "6"

$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\\ProactiveRemediations"
$TagFile = "$($DestPath)\Device-pwdLastSet-Done.tag"

#check if device is part of domain
If ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {

    # PDC to test LDAP connection available: at least one DC is reachable
    $PDC = "prdads16.intra.corp.grp"
    $PDCPort = "389"

    # Test if PDC is reachable and reset computer password
    if((Test-NetConnection -ComputerName $PDC -Port $PDCPort).TcpTestSucceeded) {
        Reset-ComputerMachinePassword
    
        # Create/update tag file
        Set-Content "$($TagFile)" "Reset computer machine password tag file" -Force

        Write-Output "Reset computer password done"
    } else {
        Write-Output "[ERROR] Domain controller not found: reset not done!"
    }
} else {
    Write-Output "Not part of a domain: nothing to do!"
}

Exit 0

