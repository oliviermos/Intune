<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Device_Pending_Reboot.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to remediate a device that need to reboot for updates reasons

Supported languages: FR, ES, IT, DE, NL, EN (default) based on regional format set (Set-Culture of control panel)

Reference: https://msendpointmgr.com/2020/06/25/endpoint-analytics-proactive-remediations/

Created date: 22/03/2022
Last Revised: 12/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$Version = "8"

function Display-ToastNotification() {
    $Load = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $Load = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
    # Load the notification into the required format
    $ToastXML = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
    $ToastXML.LoadXml($Toast.OuterXml)
        
    # Display the toast notification
    try {
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($App).Show($ToastXml)
    }
    catch { 
        Write-Output -Message 'Something went wrong when displaying the toast notification' -Level Warn *>> $LogFile
        Write-Output -Message 'Make sure the script is running as the logged on user' -Level Warn *>> $LogFile
    }
}

# Variables
$Version = ""
$ScriptName = $MyInvocation.MyCommand.Name
$DestRootPath = "$($env:ProgramData)\Econocom\Workplace"
$DestPath = "$($DestRootPath)\ProactiveRemediations"
$LogPath = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\"
$LogFile = $LogPath + $((Get-Date).ToString('yyyy-MM-dd--HH-mm-ss')) + "-$($ScriptName).log"

# Create log folder
if(!(Test-Path $LogPath)) { New-Item -ItemType Directory -Force -Path $LogPath }

# Setting image variables
$LogoImage = "$DestPath\Square Logo_48x48.jpg"
$HeroImage = "$DestPath\Hero Image.jpg"

#Defining the Toast notification settings
#ToastNotification Settings
$Scenario = 'reminder' # <!-- Possible values are: reminder | short | long -->

# Set language
$PreferredLanguage = (Get-Culture | Select-Object "Name").Name
        
# Load Toast Notification text
$AttributionText = "Econocom Workplace"

if ($PreferredLanguage -like "*fr*") {
    $RestartButton = "Redémarrer"
    $HeaderText = "Votre ordinateur doit redémarrer!"
    $TitleText = "Votre appareil a besoin de redémarrer suite à des mises à jour"
    $BodyText1 = "Nous vous recommendons de redémarrer dès que vous êtes disponible pour le faire."
    $BodyText2 = "N'oubliez pas d'enregistrer votre travail avant de redémarrer votre appareil. Merci en avance."
} elseif ($PreferredLanguage -like "*es*") {
    $RestartButton = "Redémarrer"
    $HeaderText = "¡Tu computadora necesita reiniciarse!"
    $TitleText = "Tu dispositivo necesita reiniciarse debido a las actualizaciones"
    $BodyText1 = "Le recomendamos que reinicie tan pronto como esté disponible para hacerlo."
    $BodyText2 = "No olvide guardar su trabajo antes de reiniciar su dispositivo. Gracias de antemano."
} elseif ($PreferredLanguage -like "*it*") {
    $RestartButton = "Redémarrer"
    $HeaderText = "Il tuo computer deve essere riavviato!"
    $TitleText = "Il tuo dispositivo deve essere riavviato a causa di aggiornamenti"
    $BodyText1 = "Ti consigliamo di riavviare non appena sei disponibile."
    $BodyText2 = "Non dimenticare di salvare il tuo lavoro prima di riavviare il dispositivo. Grazie in anticipo."
} elseif ($PreferredLanguage -like "*de*") {
    $RestartButton = "Redémarrer"
    $HeaderText = "Ihr Computer muss neu gestartet werden!"
    $TitleText = "Ihr Gerät muss aufgrund von Updates neu gestartet werden"
    $BodyText1 = "Wir empfehlen, dass Sie neu starten, sobald Sie dazu Zeit haben."
    $BodyText2 = "Vergessen Sie nicht, Ihre Arbeit zu speichern, bevor Sie Ihr Gerät neu starten. Vielen Dank im Voraus."
} elseif ($PreferredLanguage -like "*nl*") {
    $RestartButton = "Redémarrer"
    $HeaderText = "Uw computer moet opnieuw opstarten!"
    $TitleText = "Uw apparaat moet opnieuw worden opgestart vanwege updates"
    $BodyText1 = "We raden u aan opnieuw op te starten zodra u hiervoor beschikbaar bent."
    $BodyText2 = "Vergeet niet uw werk op te slaan voordat u uw apparaat opnieuw opstart. Bij voorbaat dank."
} else {
    # Default language english
    $RestartButton = "Restart"
    $HeaderText = "Your computer needs to restart!"
    $TitleText = "Your device needs to restart due to updates"
    $BodyText1 = "We recommend that you reboot as soon as you are available to do so."
    $BodyText2 = "Don't forget to save your work before restarting your device. Thanks in advance."
}

# Check for required entries in registry for when using Powershell as application for the toast
# Register the AppID in the registry for use with the Action Center, if required
$RegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
$App =  '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

# Creating registry entries if they don't exists
if (-NOT(Test-Path -Path "$RegPath\$App")) {
    New-Item -Path "$RegPath\$App" -Force
    New-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD'
}

# Make sure the app used with the action center is enabled
if ((Get-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne '1') {
    New-ItemProperty -Path "$RegPath\$App" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
}


# Formatting the toast notification XML
[xml]$Toast = @"
<toast scenario="$Scenario">
    <visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$HeroImage"/>
        <image id="1" placement="appLogoOverride" hint-crop="circle" src="$LogoImage"/>
        <text placement="attribution">$AttributionText</text>
        <text>$HeaderText</text>
        <group>
            <subgroup>
                <text hint-style="title" hint-wrap="true" >$TitleText</text>
            </subgroup>
        </group>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText1</text>
            </subgroup>
        </group>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$BodyText2</text>
            </subgroup>
        </group>
    </binding>
    </visual>
    <actions>
        <action activationType="protocol" arguments="rebootnow:" content="$($RestartButton)" />       
        <action activationType="system" arguments="dismiss" content="$DismissButtonContent"/>
    </actions>
</toast>
"@

#Send the notification
Display-ToastNotification

Write-Output $TitleText *>> $LogFile

Exit 0