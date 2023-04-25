<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Device_With_FastBoot_Enabled.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the FastBoot is enable: the remediate script will disable it
Needed to detect real OS start up.

Reference: https://andrewstaylor.com/2021/07/22/disable-windows-fastboot-via-intune-remediations/

Created date: 15/05/2022
Last Revised: 15/05/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$Version = ""
$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Name = "HiberbootEnabled"
$Type = "DWORD"
$Value = 0

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value){
        Write-Output "Compliant"
        Exit 0
    } 
    Write-Warning "Not Compliant"
    Exit 1
} 
Catch {
    Write-Warning "Not Compliant"
    Exit 1
}