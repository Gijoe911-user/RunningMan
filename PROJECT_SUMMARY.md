# 🏃 RunningMan / SquadRun - Résumé du Projet

## 📋 Fichiers Créés

### Core Application
✅ `RunningManApp.swift` - Point d'entrée avec Firebase
✅ `Core/AppState.swift` - État global de l'application
✅ `Core/RootView.swift` - Navigation root (Auth vs Main)
✅ `Core/Navigation/MainTabView.swift` - Navigation principale à 3 tabs

### Models
✅ `Models/Models.swift` - Tous les modèles de données:
- User
- Squad & SquadMember
- RunSession
- RunnerLocation
- Message

### Features

#### Authentication
✅ `Features/Authentication/AuthenticationView.swift`
- Inscription/Connexion
- Design Dark Mode néon
- Validation des champs

#### Sessions (Écran Principal)
✅ `Features/Sessions/SessionsListView.swift`
- Vue principale avec carte
- Session active card
- Marathon progress card
- Avatars des coureurs
- Communication bar (Micro, Photo, Messages)

✅ `Features/Sessions/SessionsViewModel.swift`
- Gestion de la logique métier
- Tracking GPS
- Données mock pour tests

✅ `Features/Sessions/MapView.swift`
- Carte MapKit interactive
- Annotations des coureurs avec distance

#### Squads
✅ `Features/Squads/SquadsListView.swift`
- Liste des squads
- Empty state
- Navigation

✅ `Features/Squads/SquadsViewModel.swift`
- Gestion des squads
- Données mock

✅ `Features/Squads/SquadViews.swift`
- CreateSquadView (création avec code)
- JoinSquadView (rejoindre avec code)
- SquadDetailView (placeholder)

#### Profile
✅ `Features/Profile/ProfileView.swift`
- Profil utilisateur
- Statistiques
- Options et paramètres
- Déconnexion

### Resources & Documentation
✅ `Resources/ColorGuide.swift` - Palette de couleurs complète
✅ `Resources/InfoPlistGuide.swift` - Guide des permissions
✅ `Resources/FirebaseSchema.swift` - Schéma Firestore complet
✅ `Resources/ScreenAnnotations.swift` - Documentation visuelle des écrans

### Documentation
✅ `README.md` - Documentation générale du projet
✅ `ARCHITECTURE.md` - Architecture détaillée avec diagrammes
✅ `TODO.md` - Liste complète des tâches à faire

---

## 🎨 Design System

### Couleurs (Dark Mode Néon)
```swift
DarkNavy:     #1A1F3A  // Fond principal
CoralAccent:  #FF6B6B  // Coureurs / CTA
PinkAccent:   #FF85A1  // Messages
BlueAccent:   #4ECDC4  // Supporters
PurpleAccent: #9B59B6  // Micro
GreenAccent:  #2ECC71  // Actif
YellowAccent: #F1C40F  // Objectifs
```

### Composants UI Réutilisables
- `CustomTextField` - Champs de formulaire avec icône
- `CommunicationButton` - Boutons circulaires colorés (Micro/Photo/Messages)
- `MapControlButton` - Contrôles carte (zoom, centrage)
- `ActiveSessionCard` - Card session en cours
- `MarathonProgressCard` - Card progression marathon
- `RunnerAvatar` - Avatar coureur avec badge actif
- `SquadCard` - Card squad avec aperçu membres
- `StatCard` - Card statistiques profil
- `ProfileOption` - Option de menu profil

---

## 🗺️ Navigation

```
RootView
├── AuthenticationView (Non connecté)
└── MainTabView (Connecté)
    ├── Tab 1: SessionsListView 🏃 (Écran principal avec carte)
    ├── Tab 2: SquadsListView 👥 (Gestion des squads)
    └── Tab 3: ProfileView 👤 (Profil utilisateur)
```

---

## ✅ Fonctionnalités Implémentées (Phase 1)

### Authentification
- [x] Inscription email/password
- [x] Connexion
- [x] Déconnexion
- [x] Persistance de session

### Squads
- [x] Création squad privée/publique
- [x] Code d'accès unique (6 caractères)
- [x] Rejoindre avec code
- [x] Liste des squads
- [x] Rôles Runner/Supporter (dans le modèle)

### Sessions Live
- [x] Carte MapKit interactive
- [x] Affichage coureurs actifs
- [x] Session active card
- [x] Progression marathon
- [x] Avatars des membres
- [x] Communication bar (UI)
- [x] Contrôles carte (zoom, centrage)

### Localisation
- [x] Configuration CoreLocation
- [x] Tracking GPS en temps réel
- [x] Permissions background
- [x] Annotations carte avec distance

### Profile
- [x] Affichage profil
- [x] Statistiques (mock)
- [x] Options menu
- [x] Déconnexion

---

## 🚧 À Implémenter

### Backend Firebase (Priorité Haute)
- [ ] Configuration Firebase
- [ ] Firestore collections (users, squads, sessions, locations, messages)
- [ ] Security rules
- [ ] Firebase Storage pour photos

### Features Core (Priorité Haute)
- [ ] Sync temps réel positions GPS
- [ ] Messages texte → Audio (Text-to-Speech)
- [ ] Upload photos
- [ ] Gestion sessions actives (Start/Stop)
- [ ] Chat basique

### UI/UX Polish (Priorité Moyenne)
- [ ] Animations et transitions
- [ ] Loading states
- [ ] Error handling
- [ ] Empty states
- [ ] Skeleton screens

### Optimisations (Priorité Moyenne)
- [ ] Gestion batterie (réduire fréquence GPS)
- [ ] Cache local
- [ ] Offline support
- [ ] Compression images

### Tests (Priorité Basse)
- [ ] Tests unitaires
- [ ] Tests UI
- [ ] Tests sur device physique

---

## 🚀 Démarrage Rapide

### 1. Configuration Firebase (30 min)
```
1. Créer projet sur console.firebase.google.com
2. Activer Authentication (Email/Password)
3. Créer Firestore Database (mode test)
4. Créer Storage bucket
5. Télécharger GoogleService-Info.plist
6. Ajouter dans Xcode
```

### 2. Swift Packages (5 min)
```
Ajouter via SPM: https://github.com/firebase/firebase-ios-sdk
Packages:
- FirebaseAuth
- FirebaseFirestore
- FirebaseFirestoreSwift (obsolete maintenant inclus dans ackage principale)
- FirebaseStorage
```

### 3. Asset Catalog (10 min)
```
Créer "Colors.xcassets" avec les couleurs:
- DarkNavy, CoralAccent, PinkAccent, BlueAccent
- PurpleAccent, GreenAccent, YellowAccent
```

### 4. Info.plist (5 min)
```xml
Ajouter permissions:
- NSLocationAlwaysAndWhenInUseUsageDescription
- NSLocationWhenInUseUsageDescription
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription
```

### 5. Capabilities (2 min)
```
Dans Xcode → Signing & Capabilities:
- Background Modes → Location updates
- Push Notifications
```

### 6. Build & Run (2 min)
```
cmd + B pour build
cmd + R pour run sur simulateur
```

---

## 📱 Écrans Principaux

### 1. AuthenticationView
- Logo + titre app
- Formulaire inscription/connexion
- Toggle Sign Up / Sign In
- Design néon sur fond dark

### 2. SessionsListView (Écran Principal)
- **Carte MapKit** en plein écran avec:
  - Annotations des coureurs (cercles avec distance)
  - Position utilisateur en rouge
- **Overlay cards** sur la carte:
  - ActiveSessionCard (session en cours)
  - MarathonProgressCard (progression objectif)
  - Avatars des coureurs actifs (scroll horizontal)
- **Communication bar** en bas:
  - Micro (violet)
  - Photo (bleu)
  - Messages (rose) avec badge
- **Map controls**:
  - Bouton centrage (gauche)
  - Boutons zoom +/- (droite)

### 3. SquadsListView
- Liste des squads avec SquadCard
- Menu création/rejoindre
- Empty state avec boutons actions
- Navigation vers détails squad

### 4. ProfileView
- Avatar + nom
- Statistiques (Courses, Distance, Squads)
- Menu options
- Bouton déconnexion

### 5. Modals
- CreateSquadView: Formulaire création squad
- JoinSquadView: Entrer code accès

---

## 📊 Schéma Firestore

### Collections
```
users/{userId}
  - displayName, email, photoURL
  - squads: [squadId]

squads/{squadId}
  - name, accessCode, isPublic
  - members: [{ userId, role, displayName }]

sessions/{sessionId}
  - squadId, name, status
  - activeRunners: [userId]
  - startTime, endTime

locations/{userId}_{sessionId}
  - latitude, longitude, timestamp
  - displayName, photoURL
  
messages/{messageId}
  - sessionId, senderId, content
  - type, timestamp
```

### Security Rules
- Users: Read all, Write own
- Squads: Read all, Write if member
- Sessions: Read all, Write if signed in
- Locations: Read all, Write if signed in
- Messages: Read all, Write if signed in

---

## 🎯 Prochaines Étapes Immédiates

### Sprint 1 (Semaine 1) - Backend Core
1. ✅ Configuration Firebase
2. ✅ Créer FirestoreService.swift
3. ✅ Implémenter CRUD Users
4. ✅ Implémenter CRUD Squads
5. ✅ Implémenter CRUD Sessions
6. ✅ Tester création/lecture données

### Sprint 2 (Semaine 2) - Features Core
1. ✅ Implémenter LocationService (envoi positions)
2. ✅ Sync temps réel positions sur carte
3. ✅ Implémenter MessageService
4. ✅ Text-to-Speech basic (AVFoundation)
5. ✅ Upload photos basique
6. ✅ Start/Stop session

### Sprint 3 (Semaine 3) - Polish & Tests
1. ✅ UI/UX polish (animations, loading states)
2. ✅ Error handling complet
3. ✅ Tests unitaires
4. ✅ Tests sur device physique
5. ✅ Optimisation batterie
6. ✅ Documentation finale

---

## 🔧 Technologies Utilisées

- **Framework**: SwiftUI
- **Language**: Swift 6.0
- **iOS Version**: iOS 17.0+
- **Backend**: Firebase
  - Authentication
  - Firestore
  - Storage
  - Cloud Functions (Phase 2)
- **Localisation**: CoreLocation + MapKit
- **Audio**: AVFoundation (TTS)
- **Architecture**: MVVM

---

## 📝 Fichiers de Documentation

1. **README.md** - Vue d'ensemble du projet
2. **ARCHITECTURE.md** - Architecture détaillée avec diagrammes ASCII
3. **TODO.md** - Liste complète des tâches par priorité
4. **ColorGuide.swift** - Palette de couleurs et extensions
5. **InfoPlistGuide.swift** - Guide des permissions requises
6. **FirebaseSchema.swift** - Schéma Firestore complet + Rules
7. **ScreenAnnotations.swift** - Documentation visuelle des écrans

---

## 🎉 État du Projet

### ✅ Phase 1 MVP - Structure Complète
- Architecture SwiftUI ✅
- Navigation complète ✅
- Tous les écrans UI ✅
- Models de données ✅
- Design system ✅
- Tracking GPS ✅
- Carte MapKit ✅
- Documentation complète ✅

### 🚧 Phase 1 MVP - À Finaliser
- Connexion Firebase
- Sync temps réel
- Text-to-Speech
- Upload photos
- Tests

### ⏳ Phase 2 - À Planifier
- Push-to-Talk
- Live Activities
- Bluetooth proximity
- Notifications supporters

### ⏳ Phase 3 - À Planifier
- Galerie photos géolocalisée
- Timeline interactive
- Applaudimètre
- Effets sonores

---

## 💡 Notes Importantes

### Pour Tester sur Simulateur
- GPS: Utiliser Debug → Location → Custom Location
- Données mock disponibles dans ViewModels
- Firebase optionnel pour UI testing

### Pour Tester sur Device
- GPS réel requis pour tracking
- Firebase requis pour sync
- Permissions à accepter

### Optimisations Batterie
- Réduire fréquence GPS quand vitesse = 0
- Utiliser `.reducedAccuracy` quand possible
- Stop updates quand session terminée

### Performance Targets
- Batterie: < 15% par heure
- Latence GPS: < 5 secondes
- Latence Messages: < 2 secondes
- Memory: < 150MB

---

## 🎨 Inspiration Design

Design basé sur la maquette fournie avec:
- **Dark Mode** forcé (#1A1F3A)
- **Effets néon** sur accents (Corail, Rose, Bleu)
- **Glassmorphism** pour overlays et cards
- **Animations fluides** pour transitions
- **Grandes zones touch** pour utilisation en course
- **Contraste élevé** pour lisibilité extérieure

---

## 🤝 Contribution

Pour ajouter une fonctionnalité:
1. Créer une branche `feature/nom-feature`
2. Implémenter avec tests
3. Suivre l'architecture MVVM existante
4. Documenter les changements
5. Créer une PR

---

## 📞 Support

Pour toute question sur l'architecture ou l'implémentation:
- Consulter `ARCHITECTURE.md` pour la structure
- Consulter `TODO.md` pour les tâches
- Consulter `FirebaseSchema.swift` pour le backend
- Consulter `ScreenAnnotations.swift` pour les écrans

---

**Version**: Phase 1 MVP
**Date**: 23 Décembre 2025
**Status**: Structure complète ✅ | Backend à connecter 🚧
