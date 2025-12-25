# 🚀 Guide de Démarrage Rapide - RunningMan

## ⚡ Quick Start (15 minutes)

### ✅ Étape 1: Configuration Firebase (5 min)

1. **Créer le projet Firebase**
   - Aller sur https://console.firebase.google.com
   - Cliquer "Ajouter un projet"
   - Nom: `RunningMan` ou `SquadRun`
   - Désactiver Google Analytics (optionnel pour Phase 1)

2. **Configurer Authentication**
   - Dans le menu → Authentication → Get Started
   - Activer "Email/Password"
   - Cliquer "Enregistrer"

3. **Créer Firestore Database**
   - Dans le menu → Firestore Database → Create Database
   - Choisir "Start in test mode" (pour Phase 1)
   - Région: europe-west1 (ou la plus proche)
   - Cliquer "Activer"

4. **Créer Storage**
   - Dans le menu → Storage → Get Started
   - Start in test mode
   - Cliquer "Terminer"

5. **Télécharger config iOS**
   - Dans Project Overview → Ajouter une app → iOS
   - Bundle ID: `com.runningman.app` (ou votre bundle)
   - Nom app: RunningMan
   - Télécharger `GoogleService-Info.plist`
   - **NE PAS** fermer cette page (garder les instructions)

---

### ✅ Étape 2: Configuration Xcode (5 min)

1. **Ajouter GoogleService-Info.plist**
   ```
   - Glisser-déposer GoogleService-Info.plist dans Xcode
   - Cocher "Copy items if needed"
   - Target: RunningMan
   ```

2. **Ajouter Firebase SDK via Swift Package Manager**
   ```
   File → Add Package Dependencies...
   
   URL: https://github.com/firebase/firebase-ios-sdk
   Version: Up to Next Major Version (10.0.0 <)
   
   Packages à cocher:
   ☑ FirebaseAuth
   ☑ FirebaseFirestore
   ☑ FirebaseFirestoreSwift
   ☑ FirebaseStorage
   
   Add Package → Attendre le téléchargement (1-2 min)
   ```

3. **Créer Asset Catalog pour les couleurs**
   ```
   File → New → File → Asset Catalog
   Nom: Colors
   
   Pour chaque couleur (clic droit dans Colors.xcassets → New Color Set):
   
   DarkNavy:
     - Any Appearance: Hex #1A1F3A
   
   CoralAccent:
     - Any Appearance: Hex #FF6B6B
   
   PinkAccent:
     - Any Appearance: Hex #FF85A1
   
   BlueAccent:
     - Any Appearance: Hex #4ECDC4
   
   PurpleAccent:
     - Any Appearance: Hex #9B59B6
   
   GreenAccent:
     - Any Appearance: Hex #2ECC71
   
   YellowAccent:
     - Any Appearance: Hex #F1C40F
   ```

4. **Configurer Info.plist**
   ```
   Ouvrir Info.plist
   Clic droit → Add Row
   
   Ajouter ces clés:
   
   Key: Privacy - Location Always and When In Use Usage Description
   Value: RunningMan a besoin d'accéder à votre position pour partager votre localisation avec votre Squad.
   
   Key: Privacy - Location When In Use Usage Description  
   Value: RunningMan utilise votre position pour afficher votre parcours sur la carte.
   
   Key: Privacy - Camera Usage Description
   Value: Prenez des photos pendant vos courses pour les partager.
   
   Key: Privacy - Photo Library Usage Description
   Value: Accédez à vos photos pour les partager avec votre Squad.
   ```

5. **Activer Capabilities**
   ```
   Target RunningMan → Signing & Capabilities
   
   Cliquer + Capability:
   
   1. Background Modes
      ☑ Location updates
      ☑ Audio, AirPlay, and Picture in Picture
   
   2. Push Notifications (ajouter mais pas obligatoire Phase 1)
   ```

---

### ✅ Étape 3: Build & Test (5 min)

1. **Build le projet**
   ```
   Cmd + B
   
   Si erreurs:
   - Vérifier que GoogleService-Info.plist est bien ajouté
   - Vérifier que les packages Firebase sont installés
   - Clean Build Folder (Cmd + Shift + K) puis rebuild
   ```

2. **Lancer sur simulateur**
   ```
   Choisir un simulateur: iPhone 15 Pro (ou plus récent)
   Cmd + R
   
   L'app devrait lancer et afficher l'écran de connexion
   ```

3. **Tester l'inscription**
   ```
   - Cliquer "Pas de compte ? S'inscrire"
   - Entrer:
     * Nom: Test User
     * Email: test@example.com
     * Password: test123
   - Cliquer "Créer un compte"
   
   Si succès → Navigation vers MainTabView
   ```

4. **Tester la navigation**
   ```
   - Tab Sessions: Carte s'affiche ✅
   - Tab Squads: Liste vide avec boutons ✅
   - Tab Profile: Profil affiché ✅
   ```

---

## 🎯 Vous avez maintenant l'app fonctionnelle !

### Ce qui fonctionne:
✅ Authentification Firebase
✅ Navigation entre écrans
✅ Interface UI complète
✅ Carte MapKit
✅ Tracking GPS (simulateur = position fixe)

### Ce qui ne fonctionne pas encore:
❌ Sync temps réel positions (pas de backend)
❌ Messages (pas de Firestore connecté)
❌ Photos (pas de Storage connecté)
❌ Création/Rejoindre Squad (pas de backend)

---

## 🔥 Étapes Suivantes (Optionnel Jour 1)

### Option A: Tester sur Device Physique (10 min)

1. **Connecter iPhone/iPad**
   - Brancher via USB
   - Autoriser l'ordinateur sur l'appareil

2. **Configurer Signing**
   ```
   Target → Signing & Capabilities
   Team: Votre équipe/compte Apple
   Bundle Identifier: com.runningman.app (ou unique)
   ```

3. **Build & Run sur device**
   ```
   Sélectionner votre appareil
   Cmd + R
   
   Sur l'appareil:
   Settings → General → VPN & Device Management
   → Approuver le développeur
   ```

4. **Tester GPS réel**
   - Lancer l'app
   - Accepter permissions localisation (Always)
   - Aller sur Tab Sessions
   - Sortir marcher → Votre position devrait bouger sur la carte

---

### Option B: Implémenter Services Firebase (30-60 min)

Voir le fichier `TODO.md` section "Backend Firebase" pour:
1. Créer `FirestoreService.swift`
2. Implémenter CRUD Users
3. Implémenter CRUD Squads
4. Connecter aux ViewModels

---

## 🐛 Troubleshooting

### Erreur: "No such module 'Firebase'"
```
Solution:
1. File → Packages → Reset Package Caches
2. File → Packages → Update to Latest Package Versions
3. Clean Build Folder (Cmd + Shift + K)
4. Build (Cmd + B)
```

### Erreur: "GoogleService-Info.plist not found"
```
Solution:
1. Vérifier que le fichier est dans le projet Xcode
2. Target Membership: Cocher RunningMan
3. Copy Bundle Resources: Vérifier présence
```

### Erreur de signing
```
Solution:
1. Target → Signing & Capabilities
2. Automatically manage signing: ☑
3. Team: Sélectionner votre équipe
4. Bundle Identifier: Changer pour un unique
```

### Carte ne s'affiche pas
```
Solution simulateur:
1. Features → Location → Custom Location
2. Entrer: Latitude 48.8566, Longitude 2.3522 (Paris)

Solution device:
1. Settings → Privacy → Location Services: ON
2. RunningMan → Always
```

### Couleurs ne s'affichent pas
```
Solution:
1. Vérifier que Colors.xcassets existe
2. Vérifier que les couleurs sont bien créées
3. Ou utiliser les fallbacks dans ColorGuide.swift
```

---

## 📚 Ressources

### Documentation Créée
- `README.md` - Vue d'ensemble
- `ARCHITECTURE.md` - Architecture détaillée
- `TODO.md` - Tâches à faire
- `PROJECT_SUMMARY.md` - Résumé complet
- `FILE_TREE.md` - Arborescence fichiers

### Code Guide
- `ColorGuide.swift` - Palette couleurs
- `FirebaseSchema.swift` - Schéma Firestore
- `InfoPlistGuide.swift` - Permissions
- `ScreenAnnotations.swift` - Doc visuelle

### Firebase
- Console: https://console.firebase.google.com
- Documentation: https://firebase.google.com/docs/ios/setup
- Auth Guide: https://firebase.google.com/docs/auth/ios/start

### Apple
- SwiftUI: https://developer.apple.com/swiftui/
- MapKit: https://developer.apple.com/maps/
- CoreLocation: https://developer.apple.com/documentation/corelocation

---

## ✅ Checklist Finale

Avant de passer à l'implémentation des services:

- [ ] Firebase projet créé
- [ ] Authentication activée
- [ ] Firestore créé (test mode)
- [ ] Storage créé (test mode)
- [ ] GoogleService-Info.plist ajouté dans Xcode
- [ ] Firebase SDK installé (SPM)
- [ ] Asset Catalog Colors créé avec 7 couleurs
- [ ] Info.plist configuré (4 permissions)
- [ ] Capabilities activées (Background Modes)
- [ ] Build réussi (Cmd + B = ✅)
- [ ] Run sur simulateur réussi (Cmd + R = ✅)
- [ ] Test inscription/connexion ✅
- [ ] Test navigation tabs ✅

---

## 🎉 Félicitations !

Vous avez maintenant une application RunningMan fonctionnelle avec:

✅ **Structure complète** - Navigation, écrans, composants
✅ **Design System** - Couleurs, typographie, styles
✅ **Authentication** - Firebase Auth connecté
✅ **UI/UX Polish** - Animations, glassmorphism
✅ **Architecture MVVM** - ViewModels, Services séparés
✅ **Documentation** - Complète et détaillée

### Prochaine étape recommandée:

👉 **Implémenter FirestoreService** pour connecter le backend
    (Voir `TODO.md` section 4)

Bonne chance ! 🚀

---

**Temps total**: ~15-20 minutes
**Difficulté**: Facile 🟢
**Prérequis**: Xcode 15+, Compte Firebase (gratuit)
