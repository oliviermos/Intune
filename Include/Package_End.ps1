<#===========================================================================================================================
Include script: Package_End.ps1
Description: To include at the end of the Win32 package script
    Variable to used:
        ReturnCode: contains error code to return
        TAG: containts Installed or Uninstalled when OK (depending of Unsinstall option)
Date Created: 08/06/2022
Last Revised: 18/10/2022
===========================================================================================================================#>

# Add file tag base on ReturnCode and TAG
Remove-item "$($DestPath)\$($ScriptName)-*.tag" -Force *>> $LogFile
If($ReturnCode -in $ReturnCodeOK) {
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : >>> End of script: $($ScriptName) with Return Code '$ReturnCode'"  *>> $LogFile
    Set-Content "$($DestPath)\$($ScriptName)-V$($Version)-$($TAG).tag" "Return code: '$($ReturnCode)' `r`n See log file for details: $($LogFile)" *>> $LogFile
} else {
    If($Profile -ne "DEV") {
        If(!([string]::IsNullOrEmpty($PackageName))) {
            # Error during choco installation: clean the trace for next retry
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! FAILED !!! Clean up choco installation for next retry !" *>> $LogFile

            # List of path to delete
            $ChocoPathToDelete = @(
                "$($env:ProgramData)\choco-cache\$($PackageName)",
                "$($env:ProgramData)\chocolatey\.chocolatey\$($PackageName).*",
                "$($env:ProgramData)\chocolatey\lib\$($PackageName)",
                "$($env:ProgramData)\chocolatey\lib-bad\$($PackageName)",
                "$($env:ProgramData)\chocolatey\lib-bkp\$($PackageName)"            
            )

            # remove Package cache folder folder trace
            ForEach($PathToDelete in $ChocoPathToDelete) {
                If(Test-Path $PathToDelete) {
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! WARNING !!! Delete $PathToDelete !" *>> $LogFile
                    remove-item -path $PathToDelete -Recurse -Force *>> $LogFile
                } else {
                    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! Nothing to delete !!! Path $PathToDelete no found !" *>> $LogFile
                }
            }

            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! WARNING !!! Clean up choco finished for next retry !" *>> $LogFile
        } else {
            # Error during other installation to manage..
            Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! FAILED !!! No clean up for WIN32 installation (only for Choco) !" *>> $LogFile
        }
    } else {
        # DEV profile: no clean up needed
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) :  !!! WARNING !!! DEV profile: no clean up needed !" *>> $LogFile
    }

    # Empty returncode is failed!
    If([string]::IsNullOrEmpty($ReturnCode)) {
        $ReturnCode = -1
    }

    # End of script with NOK installation
    Set-Content "$($DestPath)\$($ScriptName)-V$($Version)-$($TAG)-FAILED.tag" "!!! FAILED !!! Return code: '$($ReturnCode)' `r`n See log file for details: $($LogFile)" *>> $LogFile
    Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! FAILED !!!  End of script: $($ScriptName) with Return Code '$ReturnCode' ! "  *>> $LogFile
    
    # Failed return code(s)
    If($ReturnCode -in $ReturnCodeFailed ) {
    
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! FAILED !!!  Return Code for Intune 'Failed' (ReturnCode) ! "  *>> $LogFile
    
    # Retry return code(s)
    } elseif($ReturnCode -in $ReturnCodeRetry) {
    
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! WARNING !!!  Return Code for Intune 'Retry' ($ReturnCode) ! "  *>> $LogFile
    
    } else {
    
        Write-Output "$((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) : !!! FAILED !!!  Return Code not managed for Intune set it to 'Retry' (1618) ! "  *>> $LogFile
        $ReturnCode = 1618
    
    }
}

# Restore path
Pop-Location
