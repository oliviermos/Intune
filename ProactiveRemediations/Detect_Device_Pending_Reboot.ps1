<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Device_Pending_Reboot.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device need to reboot after an update

Reference: https://adamtheautomator.com/pending-reboot-registry/

Created date: 15/04/2022
Last Revised: 12/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$Version = "8"

function Test-RegistryKey {
    [OutputType('bool')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Key
    )
    
    if (Get-Item -Path $Key -ErrorAction Ignore) {
        $true
    }
}

function Test-RegistryValue {
    [OutputType('bool')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    
    if (Get-ItemProperty -Path $Key -Name $Value -ErrorAction Ignore) {
        $true
    }
}

function Test-RegistryValueNotNull {
    [OutputType('bool')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    
    if (($regVal = Get-ItemProperty -Path $Key -Name $Value -ErrorAction Ignore) -and $regVal.($Value)) {
        $true
    }
}

# Added "test-path" to each test that did not leverage a custom function from above since
# an exception is thrown when Get-ItemProperty or Get-ChildItem are passed a nonexistant key path
$tests = @(
    { Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' }
    { Test-RegistryKey -Key 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress' }
    { Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' }
    { Test-RegistryKey -Key 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending' }
    { Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting' }
    # too often without any urgency to reboot=> Disabled { Test-RegistryValueNotNull -Key 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Value 'PendingFileRenameOperations' }
    { Test-RegistryValueNotNull -Key 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Value 'PendingFileRenameOperations2' }
    { 
        # Added test to check first if key exists, using "ErrorAction ignore" will incorrectly return $true
        'HKLM:\SOFTWARE\Microsoft\Updates' | Where-Object { test-path $_ -PathType Container } | ForEach-Object {            
            (Get-ItemProperty -Path $_ -Name 'UpdateExeVolatile' | Select-Object -ExpandProperty UpdateExeVolatile) -ne 0 
        }
    }
    { Test-RegistryValue -Key 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Value 'DVDRebootSignal' }
    { Test-RegistryKey -Key 'HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttemps' }
    { Test-RegistryValue -Key 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon' -Value 'JoinDomain' }
    { Test-RegistryValue -Key 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon' -Value 'AvoidSpnSet' }
    {
        # Added test to check first if keys exists, if not each group will return $Null
        # May need to evaluate what it means if one or both of these keys do not exist
        ( 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' | Where-Object { test-path $_ } | %{ (Get-ItemProperty -Path $_ ).ComputerName } ) -ne 
        ( 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' | Where-Object { Test-Path $_ } | %{ (Get-ItemProperty -Path $_ ).ComputerName } )
    }
    {
        # Added test to check first if key exists
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending' | Where-Object { 
            (Test-Path $_) -and (Get-ChildItem -Path $_) } | ForEach-Object { $true }
    }
)

$ReturnCode = $false

# Check all test done and display the true results
#$OutPutText = ""
foreach ($test in $tests) {
    #Write-Output "Running tests: [$($test.ToString())]"
    if (& $test) {
        #$OutputText += "Test true: [$($test.ToString())]" 
        Write-Output "Test true: [$($test.ToString())]"
        $ReturnCode = $ReturnCode -or $true
    }
}

#Write-Output $OutputText

# Return true if one or more test was true.
Exit $ReturnCode