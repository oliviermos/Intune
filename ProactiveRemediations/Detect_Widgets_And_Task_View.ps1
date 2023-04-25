<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Widgets_And_Task_View.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

WIDGETS AND TASK VIEW REMOVAL FROM WINDOWS 11 USING MEM
Forked from: https://cloudbymoe.com/f/widget-and-task-view-removal-from-windows-11

Created date: 07/09/2022
Last Revised: 07/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1"

# Detection
$tb = Get-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction Stop

If($tb.GetValue("ShowTaskViewButton") -eq $null -or $tb.GetValue("TaskbarDa") -eq $null)  {

  Write-Host "Reg is identified"

    Exit 1

}

else{

    Write-Host "Key does not exist"

    Exit 0

}