<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Device_Rename.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to remediate the device need to be renamed
   Device HAADJ with random: replace random by serial
   Device AADJ with old name: renamed to the new naming convention (LAUTFR to LAFR for example)
   Device Legacy with a chrono: replace chrono by serial

Created date: 16/12/2022
Last Revised: 16/12/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1"

$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\\ProactiveRemediations"
$TagFile = "$($DestPath)\Device-Rename-Done.tag"

$Current_Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name
$SerialNumber = (Get-CimInstance -ClassName win32_bios | Select-Object -Property "SerialNumber").SerialNumber


#check if device is part of domain
If ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {

    # PDC to test LDAP connection available: at least one DC is reachable
    $PDC = "prdads16.intra.corp.grp"
    $PDCPort = "389"

    # Test if PDC is reachable and reset computer password
    if((Test-NetConnection -ComputerName $PDC -Port $PDCPort).TcpTestSucceeded) {

    
        # Create/update tag file
        Set-Content "$($TagFile)" "Device was renamed from $Current_Hostname to $New_Hostname based on serial $SerialNumber" -Force

        Write-Output "Reset computer password done"
    } else {
        Write-Output "[ERROR] Domain controller not found: renaming not done!"
    }
} else {
    
}

Exit 0

