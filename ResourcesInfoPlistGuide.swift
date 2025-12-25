//
//  Info.plist Configuration Guide
//  RunningMan
//
//  Permissions et configurations requises
//

/*
Ajoutez ces clés dans votre Info.plist:

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- LOCALISATION -->
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>RunningMan a besoin d'accéder à votre position en arrière-plan pour partager votre position avec votre Squad pendant vos courses.</string>
    
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>RunningMan utilise votre position pour afficher votre parcours et vous localiser sur la carte pendant vos courses.</string>
    
    <key>NSLocationAlwaysUsageDescription</key>
    <string>L'accès permanent à la localisation permet de suivre vos courses même quand l'app est en arrière-plan.</string>
    
    <!-- APPAREIL PHOTO (Phase 1) -->
    <key>NSCameraUsageDescription</key>
    <string>Prenez des photos pendant vos courses pour les partager avec votre Squad.</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Accédez à votre photothèque pour partager des photos avec votre Squad.</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Sauvegardez les photos de vos courses dans votre photothèque.</string>
    
    <!-- MICROPHONE (Phase 2 - Push-to-Talk) -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Utilisez le microphone pour communiquer avec votre Squad en mode Talkie-Walkie.</string>
    
    <!-- BACKGROUND MODES -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
        <string>audio</string>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>
    
    <!-- PERMISSIONS OPTIONNELLES -->
    <key>NSMotionUsageDescription</key>
    <string>RunningMan utilise les données de mouvement pour détecter votre activité de course et optimiser la batterie.</string>
    
    <key>NSHealthShareUsageDescription</key>
    <string>Partagez vos données de course avec HealthKit pour un meilleur suivi.</string>
    
    <key>NSHealthUpdateUsageDescription</key>
    <string>Enregistrez vos courses dans HealthKit.</string>
</dict>
</plist>

DANS XCODE (Signing & Capabilities):

1. Background Modes:
   ☑ Location updates
   ☑ Audio, AirPlay, and Picture in Picture (pour audio TTS)
   ☑ Background fetch
   ☑ Remote notifications

2. Push Notifications:
   ☑ Activer

3. App Groups (optionnel pour widget Phase 3):
   group.com.runningman.shared

*/
