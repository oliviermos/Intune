<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_ShortcutsDesktop.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to remediate desktop shorcuts issues:
 - remove Edge & Teams duplicates

Reference: https://workplaceascode.com/2020/11/10/3-incredible-proactive-remediation-scripts/

Created date: 13/05/2022
Last Revised: 13/05/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
# Variables
$Version = "1"
$OneDrive = @()
$Cleandedicons = "unkown"

# Set language
$PreferredLanguage = (Get-Culture | Select-Object "Name").Name

# Found Users path
$UserProfile = "$env:USERPROFILE"
$UsersRootPath = (split-path -Path $UserProfile -Parent)

# Found Public name in all languages base on the PUBLIC env value
$PublicProfile = "$env:PUBLIC"
$PublicFolderName = (split-path -Path $PublicProfile -Leaf)

# Get all Users paths except Default(s) and Public 
$UsersPaths = (get-childitem -path $UsersRootPath | Where-Object { ($_.Name -notlike "default*") } | Where-Object { ($_.Name -ne $PublicFolderName) }).FullName

# Found OneDrives folders
$OneDrive = @()
foreach ($OneDrive in $UsersPaths) {
    #Find $OneDrive
    $OneDriveLocations = (get-childitem -path $UsersPaths -Filter "OneDrive*" -ErrorAction SilentlyContinue).FullName
}

# Analyse all OneDrives folder to search Shortcuts
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

        if (($icons.Count -gt "0")) {
            #Below necessary for Intune as of 10/2019 will only remediate Exit Code 1
            
            foreach ($Item in $Icons) {
                write-host The item ($item).fullname is removed -ForegroundColor Red
                remove-item $Item.FullName -Force 
                $Cleandedicons = "Yes"
            }
        }
    }

    if ($Cleandedicons -eq "Yes") {

        # Set messages regarding language
        if ($PreferredLanguage -like "*fr*") {
            $BalloonTipTitle = "Gardez votre bureau propre"
            $BalloonTipText = "Nous avons supprimé les icônes en double de Microsoft Teams ou Edge"
        } elseif ($PreferredLanguage -like "*es*") {
            $BalloonTipTitle = "Mantenga su escritorio limpia"
            $BalloonTipText = "Eliminamos los iconos duplicados de Microsoft Teams o Edge"
        } elseif ($PreferredLanguage -like "*it*") {
            $BalloonTipTitle = "Mantieni pulito il tuo desktop"
            $BalloonTipText = "Abbiamo rimosso le icone duplicate di Microsoft Teams o Edge"
        } elseif ($PreferredLanguage -like "*de*") {
            $BalloonTipTitle = "Halten Sie Ihren Desktop sauber"
            $BalloonTipText = "Wir haben die doppelten Symbole von Microsoft Teams oder Edge entfernt"
        } elseif ($PreferredLanguage -like "*nl*") {
            $BalloonTipTitle = "Houd je bureaublad schoon"
            $BalloonTipText = "We hebben de dubbele pictogrammen van Microsoft Teams of Edge verwijderd"
        } else {
            # Default language english
            $BalloonTipTitle = "Keep your desktop clean"
            $BalloonTipText = "We removed the duplicated icons of Microsoft Teams or Edge"
        }

        # Create&Display the Ballon Tip
        Add-Type -AssemblyName System.Windows.Forms
        $global:balmsg = New-Object System.Windows.Forms.NotifyIcon
        $path = (Get-Process -id $pid).Path
        $balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
        $balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
        $balmsg.BalloonTipTitle = $BalloonTipTitle
        $balmsg.BalloonTipText = $BalloonTipText
        $balmsg.Visible = $true
        $balmsg.ShowBalloonTip(40000)
    }      
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}