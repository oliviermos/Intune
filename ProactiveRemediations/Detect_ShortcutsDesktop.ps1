<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Detect_ShortcutsDesktop.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to detect desktop shorcuts issues:
 - Edge & Teams duplicates

Reference: https://workplaceascode.com/2020/11/10/3-incredible-proactive-remediation-scripts/

Created date: 13/05/2022
Last Revised: 13/05/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1"
$OneDrive = @()

# Found Users path
$UserProfile = "$env:USERPROFILE"
$UsersRootPath = (split-path -Path $UserProfile -Parent)

# Found Public name in all languages base on the PUBLIC env value
$PublicProfile = "$env:PUBLIC"
$PublicFolderName = (split-path -Path $PublicProfile -Leaf)

# Get all Users paths except Default(s) and Public 
$UsersPaths = (get-childitem -path $UsersRootPath | Where-Object { ($_.Name -notlike "default*") } | Where-Object { ($_.Name -ne $PublicFolderName) }).FullName

# Found OneDrives folders
foreach ($OneDrive in $UsersPaths) {
    #Find $OneDrive
    $OneDriveLocations = (get-childitem -path $UsersPaths -Filter "OneDrive*" -ErrorAction SilentlyContinue).FullName
}

try {
    foreach ($OneDriveLocation in $OneDriveLocations) {
        $Icons = @()
        $AllEdgeIcons = New-Object PSobject
        $AllTeamsIcons = New-Object PSobject
        $EdgeIcons = (get-childitem -Path $OneDriveLocation  -Filter "Microsoft Edge*.lnk" -Recurse -ErrorAction SilentlyContinue)
        $TeamsIcons = (get-childitem -Path $OneDriveLocation -Filter "Microsoft Teams*.lnk" -Recurse -ErrorAction SilentlyContinue)
 
        $AllEdgeIcons | Add-Member -MemberType NoteProperty -Name "Fullname" -Value $EdgeIcons.fullname
        $AllTeamsIcons | Add-Member -MemberType NoteProperty -Name "Fullname" -Value $TeamsIcons.fullname

        $icons += $EdgeIcons
        $icons += $TeamsIcons
    }
    

    if (($icons.count -gt "0")) {
        #Start remediation
        write-host "Start remediation"
        exit 1
    }
    else {
        #No remediation required    
        write-host "No remediation"
        exit 0
    }   
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}