<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Device_With_FastBoot_Enabled.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to remediate by disabling the fastbootdetect

Reference: https://andrewstaylor.com/2021/07/22/disable-windows-fastboot-via-intune-remediations/

Created date: 15/05/2022
Last Revised: 15/05/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$Version = ""

New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;