# Configuration Info.plist pour RunningMan

## ⚠️ ACTION REQUISE

Pour que l'application fonctionne correctement, vous devez ajouter ces clés dans votre fichier `Info.plist`.

### Comment ajouter ces clés dans Xcode :

1. Ouvrez votre projet dans Xcode
2. Sélectionnez le fichier `Info.plist` dans le navigateur de projet
3. Cliquez sur le bouton `+` pour ajouter une nouvelle clé
4. Copiez-collez les clés ci-dessous

---

## 🗺️ Permissions de Localisation (OBLIGATOIRE)

Sans ces clés, l'app crashera au démarrage !

### NSLocationWhenInUseUsageDescription
**Type:** String  
**Valeur:**
```
RunningMan utilise votre position pour afficher votre parcours et vous localiser sur la carte pendant vos courses.
```

### NSLocationAlwaysAndWhenInUseUsageDescription
**Type:** String  
**Valeur:**
```
RunningMan a besoin d'accéder à votre position en arrière-plan pour partager votre position avec votre Squad pendant vos courses.
```

### NSLocationAlwaysUsageDescription
**Type:** String  
**Valeur:**
```
L'accès permanent à la localisation permet de suivre vos courses même quand l'app est en arrière-plan.
```

---

## 📷 Permissions Caméra et Photos

### NSCameraUsageDescription
**Type:** String  
**Valeur:**
```
Prenez des photos pendant vos courses pour les partager avec votre Squad.
```

### NSPhotoLibraryUsageDescription
**Type:** String  
**Valeur:**
```
Accédez à votre photothèque pour partager des photos avec votre Squad.
```

### NSPhotoLibraryAddUsageDescription
**Type:** String  
**Valeur:**
```
Sauvegardez les photos de vos courses dans votre photothèque.
```

---

## 🎤 Permission Microphone (pour Push-to-Talk Phase 2)

### NSMicrophoneUsageDescription
**Type:** String  
**Valeur:**
```
Utilisez le microphone pour communiquer avec votre Squad en mode Talkie-Walkie.
```

---

## 🔄 Background Modes

### UIBackgroundModes
**Type:** Array

Ajoutez ces éléments à l'array :
1. `location` (Item 0)
2. `audio` (Item 1)
3. `fetch` (Item 2)
4. `remote-notification` (Item 3)

---

## 📱 Configuration dans Signing & Capabilities

### 1. Background Modes
Dans Xcode, allez dans votre target → "Signing & Capabilities" → "+" → "Background Modes"

Cochez :
- ☑️ Location updates
- ☑️ Audio, AirPlay, and Picture in Picture
- ☑️ Background fetch
- ☑️ Remote notifications

### 2. Push Notifications
Ajoutez la capability "Push Notifications"

---

## 🎨 Couleurs dans l'Asset Catalog

Les couleurs suivantes sont manquantes et causent des warnings. Créez-les dans votre Asset Catalog :

### Comment créer les couleurs :

1. Dans Xcode, ouvrez le navigateur de projet
2. Cherchez ou créez un fichier `Assets.xcassets` ou `Colors.xcassets`
3. Clic droit → "New Color Set"
4. Nommez la couleur
5. Cliquez sur "Any Appearance" et configurez la couleur

### Couleurs à créer :

#### DarkNavy (Fond principal)
- Nom : `DarkNavy`
- Hex : `#1A1F3A`
- RGB : R:26, G:31, B:58

#### CoralAccent (Accent principal)
- Nom : `CoralAccent`
- Hex : `#FF6B6B`
- RGB : R:255, G:107, B:107

#### PinkAccent (Accent secondaire)
- Nom : `PinkAccent`
- Hex : `#FF85A1`
- RGB : R:255, G:133, B:161

#### BlueAccent (Supporters)
- Nom : `BlueAccent`
- Hex : `#4ECDC4`
- RGB : R:78, G:205, B:196

#### PurpleAccent
- Nom : `PurpleAccent`
- Hex : `#9B59B6`
- RGB : R:155, G:89, B:182

#### GreenAccent (Actif/En ligne)
- Nom : `GreenAccent`
- Hex : `#2ECC71`
- RGB : R:46, G:204, B:113

#### YellowAccent (Avertissements)
- Nom : `YellowAccent`
- Hex : `#F1C40F`
- RGB : R:241, G:196, B:15

---

## ✅ Vérification

Après avoir ajouté toutes ces configurations :

1. Nettoyez le build : Cmd + Shift + K
2. Rebuilder : Cmd + B
3. Lancez l'app dans le simulateur

L'app ne devrait plus crasher au démarrage !

---

## 📝 Note

Le fichier `Color+Extensions.swift` créé contient des valeurs de fallback pour toutes les couleurs, donc **l'app fonctionnera même sans créer les couleurs dans l'Asset Catalog**. Les warnings apparaîtront dans les logs mais ne causeront plus de crash.

Pour une meilleure pratique, créez quand même les couleurs dans l'Asset Catalog pour éviter les warnings.
