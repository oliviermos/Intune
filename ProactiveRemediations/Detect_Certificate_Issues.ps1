<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_Certificate_Issues.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect if the device pwdLastSet is not too old
We think that this is an incident arount ECO-WIFI issue with the radius (Error code 16)

Created date: 26/08/2022
Last Revised: 20/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "5"
$Domain = "INTRA"
$Issuer = "INTRA-PRDCASUB01-CA"
$CertLimitDate = "27/03/2022"

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
               $CertDate = "$($Cert.NotBefore)".Split(" ")
               If($Cert.GetEffectiveDateString() -gt $CertLimitDate) {
                   Write-Output "+++ Certificate date $CertDate is greater than $CertLimitDate !"
               } else {
                   Write-Output "--- Certificate date $CertDate is lower than $CertLimitDate !"
                   $CertToRemoveFound++
                   $CertToRemove = $true
               }
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
    } else {
        Write-Output "!!! Certificate to keep !!!"
    }

    write-output "-----------------------------------------------------------------------------------------"
}

# Write statistic
Write-Output "Certificate(s) found: $CertFound | Certificate(s) $Domain found: $CertDomainFound | Certificate(s) to remove: $CertToRemoveFound"

If($CertToRemoveFound -gt 0) {
    Exit 1
} else {
    Exit 0
}