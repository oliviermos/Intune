<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Certificate_Issues.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device pwdLastSet is not too old
We think that this is an incident arount ECO-WIFI issue with the radius (Error code 16)

Created date: 26/08/2022
Last Revised: 26/08/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1"
$Domain = "INTRA"

# computer hostname
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name

# Get computer certificate personnal
$CertMyList = Get-ChildItem Cert:\LocalMachine\My

$CertFound = 0
$CertDomainFound = 0
$CertToRemoveFound = 0

Foreach($Cert in $CertMyList) {
    $CertFound++

    $CN = ($Cert.Subject).ToUpper()
    If($CN -like "*$($Domain)*"){
        $CertDomainFound++

        Write-output "Found $($Domain) device: $CN"
        If($CN.IndexOf($Hostname) -gt 0) {
            Write-output "Hostname $Hostname found in $CN"
        } else {
            $CertToRemoveFound++
                        
            Write-output "Hostname $Hostname not found in $CN"
            $Thumbprint = $Cert.Thumbprint
            Write-output "Delete certicate $CN (Thumbprint: $Thumbprint)"
            #Remove-Item "Cert:\LocalMachine\My\$($Thumbprint)" # optionnal to remove private key -DeleteKey
        }
    } else {
        Write-output "not INTRA device: $CN"
    }
}

Write-Output "Certificate(s) found: $CertFound`r`nCertificate(s) $Domain found: $CertDomainFound`r`nCertificate(s) to remove: $CertToRemoveFound"

If($CertToRemoveFound -gt 0) {
    Exit 1
} else {
    Exit 0
}