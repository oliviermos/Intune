<#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name: Remediate_Device_Not_Rebooted.ps1
    >>> INCLUDE IN INTUNE KICKSTART <<<

Script to remediate a device that not not reboot since a number of days specifiy in the remediate script
It's only a notification to ask to reboot at least each 7 days
The toast is display regarding the detection script (on 5 days the 12/04/2021)

Supported languages: FR, ES, IT, DE, NL, EN (default) based on regional format set (Set-Culture of control panel)

Reference: https://msendpointmgr.com/2020/06/25/endpoint-analytics-proactive-remediations/

Created date: 22/03/2022
Last Revised: 13/09/2022
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------#>
$Version = "18"

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
$Version = "17"
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
$Uptime= get-computerinfo | Select-Object OSUptime 

#Defining the Toast notification settings
#ToastNotification Settings
$Scenario = 'reminder' # <!-- Possible values are: reminder | short | long -->

# Set language
$PreferredLanguage = (Get-Culture | Select-Object "Name").Name
        
# Load Toast Notification text
$AttributionText = "Econocom Workplace"

if ($PreferredLanguage -like "*fr*") {
    $RestartButton = "Redémarrer"
    $HeaderText = "Le redémarrage de l'ordinateur est nécessaire!"
    $TitleText = "Votre appareil n'a pas effectué de redémarrage au cours des $($Uptime.OsUptime.Days) derniers jours"
    $BodyText1 = "Pour des raisons de performances et de stabilité, nous suggérons un redémarrage au moins une fois par semaine."
    $BodyText2 = "Veuillez enregistrer votre travail et redémarrer votre appareil aujourd'hui. Merci en avance."
} elseif ($PreferredLanguage -like "*es*") {
    $RestartButton = "Reiniciar"
    $HeaderText = "¡Se necesita reiniciar la computadora!"
    $TitleText = "Su dispositivo no se ha reiniciado en los últimos $($Uptime.OsUptime.Days) días"
    $BodyText1 = "Por razones de rendimiento y estabilidad, sugerimos reiniciar al menos una vez a la semana."
    $BodyText2 = "Guarde su trabajo y reinicie su dispositivo hoy. Gracias de antemano."
} elseif ($PreferredLanguage -like "*it*") {
    $RestartButton = "Ricomincia"
    $HeaderText = "È necessario il riavvio del computer!"
    $TitleText = "Il tuo dispositivo non ha eseguito un riavvio negli ultimi $($Uptime.OsUptime.Days)."
    $BodyText1 = "Per motivi di prestazioni e stabilità suggeriamo un riavvio almeno una volta alla settimana."
    $BodyText2 = "Si prega di salvare il lavoro e riavviare il dispositivo oggi. Grazie in anticipo."
} elseif ($PreferredLanguage -like "*de*") {
    $RestartButton = "Neu starten"
    $HeaderText = "Computer-Neustart ist erforderlich!"
    $TitleText = "Ihr Gerät hat in den letzten $($Uptime.OsUptime.Days) Tagen keinen Neustart durchgeführt"
    $BodyText1 = "Aus Performance- und Stabilitätsgründen empfehlen wir mindestens einmal pro Woche einen Neustart."
    $BodyText2 = "Bitte speichern Sie Ihre Arbeit und starten Sie Ihr Gerät noch heute neu. Vielen Dank im Voraus."
} elseif ($PreferredLanguage -like "*nl*") {
    $RestartButton = "Herstarten"
    $HeaderText = "Computer opnieuw opstarten is nodig!"
    $TitleText = "Uw apparaat heeft de afgelopen $($Uptime.OsUptime.Days) dagen geen herstart uitgevoerd"
    $BodyText1 = "Om prestatie- en stabiliteitsredenen raden we aan om ten minste eenmaal per week opnieuw op te starten."
    $BodyText2 = "Sla uw werk op en start uw apparaat vandaag opnieuw op. Dank u bij voorbaat."
} else {
    # Default language english
    $RestartButton = "Restart"
    $HeaderText = "Computer Restart is needed!"
    $TitleText = "Your device has not performed a reboot the last $($Uptime.OsUptime.Days) days"
    $BodyText1 = "For performance and stability reasons we suggest a reboot at least once a week."
    $BodyText2 = "Please save your work and restart your device today. Thank you in advance."
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