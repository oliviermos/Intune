<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Widgets_And_Task_View.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

WIDGETS AND TASK VIEW REMOVAL FROM WINDOWS 11 USING MEM
Forked from: https://cloudbymoe.com/f/widget-and-task-view-removal-from-windows-11

Created date: 07/09/2022
Last Revised: 07/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1"

# Remediate
$tb = Get-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue

If($tb.GetValue("ShowTaskViewButton") -eq $null -Or $tb.GetValue("TaskbarDa") -eq $null){

    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowTaskViewButton -Value 0 -PropertyType DWord -ErrorAction SilentlyContinue

    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarDa -Value 0 -PropertyType DWord -ErrorAction SilentlyContinue

    Write-Host "Registry Added"

} else {

    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\TabbedBrowsing\" -Name "ShowTaskViewButton" -Value 0 -ErrorAction SilentlyContinue

    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\TabbedBrowsing\" -Name "TaskbarDa" -Value 0 -ErrorAction SilentlyContinue

    Write-Host "Registry Modified 1"

}

Exit 0