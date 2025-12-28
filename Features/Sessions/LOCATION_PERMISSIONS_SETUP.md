# 📍 Configuration des Permissions de Localisation

## 🚨 Problème Actuel

L'app ne voit pas les sessions ni la carte car :
1. ❌ Permissions de localisation pas configurées dans Info.plist
2. ❌ L'app ne peut pas demander la permission
3. ❌ Pas d'option "Position" dans Réglages

---

## ✅ Solution : Configurer Info.plist

### Étape 1 : Ouvrir Info.plist

1. Dans Xcode, ouvrir le **Project Navigator** (Cmd + 1)
2. Trouver le fichier **`Info.plist`** dans le dossier RunningMan
3. Clic droit → **Open As** → **Source Code**

---

### Étape 2 : Ajouter les Clés de Permission

Ajouter ces lignes **avant** `</dict></plist>` :

```xml
<!-- Permissions de Localisation -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>RunningMan a besoin de votre position pour afficher votre emplacement sur la carte pendant les sessions de course.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>RunningMan suit votre position en temps réel pendant les sessions pour que vos amis puissent vous voir sur la carte.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>RunningMan suit votre position même en arrière-plan pour continuer à afficher votre emplacement pendant les sessions de course.</string>

<!-- Autoriser la localisation en arrière-plan -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

---

### Étape 3 : Exemple Complet Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Autres clés existantes... -->
    
    <!-- 📍 Permissions de Localisation -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>RunningMan a besoin de votre position pour afficher votre emplacement sur la carte pendant les sessions de course.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>RunningMan suit votre position en temps réel pendant les sessions pour que vos amis puissent vous voir sur la carte.</string>
    
    <key>NSLocationAlwaysUsageDescription</key>
    <string>RunningMan suit votre position même en arrière-plan pour continuer à afficher votre emplacement pendant les sessions de course.</string>
    
    <!-- Background Location -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
    </array>
    
    <!-- Firebase (si existant) -->
    <!-- ... autres clés ... -->
</dict>
</plist>
```

---

## 🎯 Alternative : Via l'Interface Xcode

### Méthode Visuelle (Plus Simple)

1. **Ouvrir Info.plist** (double-clic, vue tableau)

2. **Ajouter les clés** :
   - Clic sur **+** pour ajouter une ligne
   - Taper `Privacy - Location When In Use Usage Description`
   - Value : `RunningMan a besoin de votre position pour afficher votre emplacement sur la carte pendant les sessions de course.`
   
   - Clic sur **+** pour ajouter une ligne
   - Taper `Privacy - Location Always and When In Use Usage Description`
   - Value : `RunningMan suit votre position en temps réel pendant les sessions pour que vos amis puissent vous voir sur la carte.`
   
   - Clic sur **+** pour ajouter une ligne
   - Taper `Privacy - Location Always Usage Description`
   - Value : `RunningMan suit votre position même en arrière-plan pour continuer à afficher votre emplacement pendant les sessions de course.`

3. **Ajouter Background Modes** :
   - Dans le **Project Navigator**, sélectionner le projet **RunningMan**
   - Sélectionner le **Target** RunningMan
   - Onglet **Signing & Capabilities**
   - Clic **+ Capability**
   - Chercher **Background Modes**
   - Cocher **Location updates**

---

## 📱 Après Configuration

### 1. Clean Build
```
Cmd + Shift + K
```

### 2. Rebuild
```
Cmd + B
```

### 3. Supprimer l'App du Simulateur/Device
- Maintenir appui sur l'icône RunningMan
- Supprimer l'app
- OU dans Simulateur: Device → Erase All Content and Settings

### 4. Réinstaller
```
Cmd + R
```

---

## ✅ Vérification

### Au Premier Lancement

L'app devrait afficher une popup :

```
┌───────────────────────────────────┐
│  "RunningMan" souhaite accéder à  │
│  votre position                   │
│                                   │
│  RunningMan a besoin de votre     │
│  position pour afficher votre     │
│  emplacement sur la carte...      │
│                                   │
│  [Ne pas autoriser]  [Autoriser]  │
└───────────────────────────────────┘
```

### Dans Réglages

Après avoir accepté, l'app devrait apparaître dans :

```
Réglages → Confidentialité et sécurité → Service de localisation → RunningMan

Options disponibles :
○ Jamais
○ Demander la prochaine fois
● Lorsque l'app est utilisée
○ Toujours

☑️ Position précise
```

---

## 🧪 Tests à Effectuer

### Test 1 : Permission Demandée
- [ ] Au lancement, popup de permission apparaît
- [ ] Texte de description visible
- [ ] Boutons Autoriser/Refuser présents

### Test 2 : Dans Réglages
- [ ] App visible dans Réglages → Position
- [ ] Options de permission disponibles
- [ ] "Position précise" cochable

### Test 3 : Carte Fonctionne
- [ ] Naviguer vers Sessions
- [ ] Carte s'affiche
- [ ] Point bleu (position user) visible
- [ ] Carte centrée sur user

### Test 4 : Localisation Temps Réel
- [ ] Bouger dans le simulateur (Features → Location → Custom Location)
- [ ] Carte suit le mouvement
- [ ] Coordonnées se mettent à jour

---

## 🎮 Simuler le Mouvement (Simulateur)

### Option 1 : Emplacements Prédéfinis
```
Simulateur → Features → Location → Custom Location
- Apple Park
- City Bicycle Ride
- City Run
- Freeway Drive
```

### Option 2 : Position Personnalisée
```
Simulateur → Features → Location → Custom Location
Latitude: 48.8566
Longitude: 2.3522
(Paris)
```

### Option 3 : GPX File (Parcours Simulé)
1. Créer un fichier `route.gpx` avec un parcours
2. Features → Location → GPX File → Choisir le fichier

---

## 🐛 Troubleshooting

### Problème 1 : Pas de Popup de Permission

**Cause :** Info.plist pas configuré

**Solution :**
1. Vérifier que les clés sont bien dans Info.plist
2. Clean Build (Cmd + Shift + K)
3. Supprimer l'app
4. Réinstaller

---

### Problème 2 : "RunningMan" pas dans Réglages

**Cause :** L'app n'a jamais demandé la permission

**Solution :**
```swift
// Dans SessionsListView.onAppear
viewModel.startLocationUpdates()  // ← Doit appeler requestAuthorization()
```

Vérifier que `LocationProvider.startUpdating()` appelle bien :
```swift
if authorizationStatus == .notDetermined {
    requestWhenInUseAuthorization()
}
```

---

### Problème 3 : Permission Refusée

**Réinitialiser les permissions :**

**Simulateur :**
```
Device → Erase All Content and Settings
```

**Device Physique :**
```
Réglages → Général → Réinitialiser → Réinitialiser la localisation et confidentialité
```

---

### Problème 4 : Point Bleu pas Visible

**Vérifier :**
1. Permission accordée ✅
2. `showsUserLocation: true` dans Map ✅
3. Simulateur a une position définie
4. `LocationProvider.startUpdating()` appelé ✅

---

## 📋 Checklist Complète

### Configuration
- [ ] Info.plist configuré avec les 3 clés
- [ ] Background Modes → Location updates activé
- [ ] Build clean effectué
- [ ] App réinstallée

### Runtime
- [ ] Popup de permission apparaît
- [ ] Permission "Lorsque l'app est utilisée" accordée
- [ ] App visible dans Réglages → Position
- [ ] Position précise activée

### Fonctionnel
- [ ] Carte s'affiche
- [ ] Point bleu visible
- [ ] Carte centrée sur user
- [ ] Coordonnées mises à jour

---

## 🎯 Résumé des Actions

### Actions Immédiates

1. **Configurer Info.plist**
   ```xml
   NSLocationWhenInUseUsageDescription
   NSLocationAlwaysAndWhenInUseUsageDescription
   UIBackgroundModes → location
   ```

2. **Activer Background Modes**
   ```
   Target → Signing & Capabilities → + Capability → Background Modes
   ✓ Location updates
   ```

3. **Clean & Rebuild**
   ```
   Cmd + Shift + K
   Cmd + B
   ```

4. **Supprimer & Réinstaller**
   ```
   Supprimer l'app du simulateur
   Cmd + R
   ```

5. **Accepter la Permission**
   ```
   Autoriser l'accès à la position
   ```

---

## 📱 Résultat Attendu

### Au Lancement
```
[Popup] "RunningMan" souhaite accéder à votre position
→ Autoriser
```

### Dans Sessions
```
┌────────────────────────┐
│  Sessions          [+] │
├────────────────────────┤
│                        │
│     🗺️ CARTE          │
│                        │
│       📍 (vous)        │
│                        │
│     ┌───┐              │
│     │👤 │ Runner 1     │
│     └───┘              │
│                        │
└────────────────────────┘
```

---

**Après ces étapes, l'app devrait demander la permission et afficher la carte avec votre position ! ** 📍🗺️

Si ça ne fonctionne toujours pas, faites-moi signe avec les détails (logs console, comportement observé, etc.)
