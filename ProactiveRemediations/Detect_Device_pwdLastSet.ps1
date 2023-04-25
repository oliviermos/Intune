<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Device_pwdLastSet.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device pwdLastSet is not too old
We think that this is an incident arount ECO-WIFI issue with the radius (Error code 16)

Created date: 23/08/2022
Last Revised: 22/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "6"
$MaxDays = 7
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\\ProactiveRemediations"
$TagFile = "$($DestPath)\Device-pwdLastSet-Done.tag"

#check if device is part of domain
If ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {

    # PDC to test LDAP connection available: at least one DC is reachable
    $PDC = "prdads16.intra.corp.grp"
    $PDCPort = "389"

    # Create path to tag files
    if(!(Test-Path $DestPath)) { New-Item -ItemType Directory -Force -Path $DestPath }

    # Test if PDC is reachable and reset computer password
    if((Test-NetConnection -ComputerName $PDC -Port $PDCPort).TcpTestSucceeded) {

        # Check tag file
        If(!(Test-Path "$($TagFile)")) {
            Write-Output "No reset was done: first try"
            Exit 1 # No reset was done
        } else {
            $TagLastWrite = (Get-Item "$($TagFile)").LastWriteTime
            If((Get-Date).AddDays(-$MaxDays) -ge $TagLastWrite) {
                Write-Output "Reset to do"
                Exit 1 # reset again
            } else {
                Write-Output "Reset postponed!"
                Exit 0 # not yet
            }
        }
    } else {
        Write-Output "[ERROR] Domain controller not found: don't check reset status now!"
        Exit 1 # No reset was done
    }
} else {
    Write-Output "Not part of a domain: nothing to do!"
    Exit 0
}