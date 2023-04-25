<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Certificate_Issues.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if computer device contain the hostname in INTRA
We think that this is an incident arount ECO-WIFI issue with the radius (Error code 16)

Created date: 26/08/2022
Last Revised: 290/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "5"
$Domain = "INTRA"
$Issuer = "INTRA-PRDCASUB01-CA"

# computer hostname
$Hostname = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property "Name").Name

# Get computer certificate personnal
$CertMyList = Get-ChildItem Cert:\LocalMachine\My

$CertFound = 0
$CertDomainFound = 0
$CertToRemoveFound = 0

Foreach($Cert in $CertMyList) {
    $CertFound++

    write-output "-----------------------------------------------------------------------------------------"
    write-output "Subjet: $($cert.subject)"
    write-output "Issuer: $($cert.Issuer)"
    write-output "FriendlyName: $($cert.FriendlyName)"
    write-output "DnsNameList: $($cert.DnsNameList)"
    write-output "NotBefore: $($cert.NotBefore)"

    $CertToRemove = $false
    If($($cert.Issuer) -like "*$($Issuer)*") {
        Write-Output "+++ From INTRA issuer $Issuer"

        $CN = ($Cert.Subject).ToUpper()
        If($CN -like "*$($Domain)*"){
            Write-Output "+++ Domain INTRA found in CN $CN"
            $CertDomainFound++

            # Search hostname in CN
            If($CN.IndexOf($Hostname) -eq -1) {
           
               # not found! Certificate to delele
               Write-Output "--- Hostname $Hostname NOT found in certificate : certificate to removed!"
               $CertToRemoveFound++
               $CertToRemove = $true
            } else {
               Write-Output "+++ Hostname $Hostname found in certificate"
            }
        } else {
            Write-Output "--- Domain INTRA NOT found in CN $CN : certificate to removed!"
            $CertToRemoveFound++
            $CertToRemove = $true
        }
    } else {
        Write-Output "--- Not from INTRA issuer $Issuer"
    }
    If($CertToRemove) {
        Write-Output "!!! Certificate to remove !!!"
        $Thumbprint = $Cert.Thumbprint
        Write-output "Delete certicate $CN (Thumbprint: $Thumbprint)"
        Remove-Item "Cert:\LocalMachine\My\$($Thumbprint)" # optionnal to remove private key -DeleteKey
        Write-Output "!!! Certificate REMOVED !!!"
    } else {
        Write-Output "!!! Certificate to keep !!!"
    }

    write-output "-----------------------------------------------------------------------------------------"
}

# Write statistic
Write-Output "Certificate(s) found: $CertFound | Certificate(s) $Domain found: $CertDomainFound | Certificate(s) removed: $CertToRemoveFound"

Exit 0
