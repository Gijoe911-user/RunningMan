# RunningMan / SquadRun - Phase 1 MVP

## 📱 Structure de Navigation SwiftUI

### Architecture Générale

```
RunningManApp (Entry Point)
    └── RootView
        ├── AuthenticationView (Non authentifié)
        └── MainTabView (Authentifié)
            ├── SessionsListView (Écran principal avec carte)
            ├── SquadsListView (Gestion des squads)
            └── ProfileView (Profil utilisateur)
```

## 🎨 Design System

**Palette de couleurs Dark Mode Néon:**
- DarkNavy (#1A1F3A) - Fond principal
- CoralAccent (#FF6B6B) - Accent coureurs
- BlueAccent (#4ECDC4) - Accent supporters
- PurpleAccent (#9B59B6) - Communication
- GreenAccent (#2ECC71) - Statut actif
- YellowAccent (#F1C40F) - Objectifs

## 📂 Organisation des Fichiers

### Core
- `RunningManApp.swift` - Point d'entrée avec Firebase
- `AppState.swift` - État global (auth, session active)
- `RootView.swift` - Navigation principale Auth/Main

### Models
- `Models.swift` - User, Squad, RunSession, Message, RunnerLocation

### Features

#### Authentication
- `AuthenticationView.swift` - Inscription/Connexion

#### Sessions (Écran principal)
- `SessionsListView.swift` - Vue avec carte et sessions
- `SessionsViewModel.swift` - Logique métier
- `MapView.swift` - Carte avec annotations coureurs

#### Squads
- `SquadsListView.swift` - Liste des squads
- `SquadsViewModel.swift` - Gestion des squads
- `SquadViews.swift` - Création/Rejoindre squad

#### Profile
- `ProfileView.swift` - Profil utilisateur

## ✅ Fonctionnalités Phase 1 (Implémentées)

### Authentification ✅
- [x] Inscription email/password
- [x] Connexion
- [x] Déconnexion
- [x] Persistance de session

### Squads ✅
- [x] Liste des squads
- [x] Création de squad privée/publique
- [x] Code d'accès unique
- [x] Rejoindre avec code
- [x] Distinction Coureurs/Supporters (modèle)

### Session Live ✅
- [x] Carte interactive avec MapKit
- [x] Affichage des coureurs actifs
- [x] Avatars des membres
- [x] Carte de progression marathon
- [x] Barre de communication (UI)
- [x] Contrôles de carte (zoom, centrage)

### Localisation ✅
- [x] Configuration CoreLocation
- [x] Tracking en temps réel
- [x] Permissions background

## 🚧 À Implémenter - Phase 1

### Backend Firebase
- [ ] Configuration Firestore
- [ ] Collections: users, squads, sessions, messages, locations
- [ ] Cloud Functions pour messages
- [ ] Règles de sécurité Firestore

### Fonctionnalités Essentielles
- [ ] Envoi/réception positions GPS vers Firebase
- [ ] Messages texte transformés en audio (Text-to-Speech)
- [ ] Synchronisation temps réel des positions
- [ ] Gestion des sessions (Start/Stop)
- [ ] Chat basique dans une session

### Optimisations
- [ ] Gestion batterie (réduction fréquence GPS à l'arrêt)
- [ ] Gestion des erreurs réseau
- [ ] États de chargement
- [ ] Cache local des données

## 📋 Prochaines Étapes Immédiates

1. **Configuration Firebase**
   - Créer projet Firebase
   - Ajouter GoogleService-Info.plist
   - Installer Firebase SDK via SPM

2. **Firestore Schema**
   ```
   users/{userId}
   squads/{squadId}
   sessions/{sessionId}
   messages/{messageId}
   locations/{userId}_{sessionId}
   ```

3. **Permissions Info.plist**
   ```xml
   NSLocationAlwaysAndWhenInUseUsageDescription
   NSLocationWhenInUseUsageDescription
   NSMicrophoneUsageDescription (Phase 2)
   NSCameraUsageDescription
   ```

4. **Capabilities Xcode**
   - Background Modes: Location updates
   - Push Notifications

## 🎯 Phase 2 - À Préparer

- [ ] Push-to-Talk (AVFoundation)
- [ ] Live Activities
- [ ] Détection Bluetooth proximité
- [ ] Gestion roles Squad détaillée
- [ ] Notifications supporters → coureurs

## 🎯 Phase 3 - À Préparer

- [ ] Galerie photos géolocalisée
- [ ] Timeline interactive
- [ ] Applaudimètre
- [ ] Effets sonores
- [ ] Optimisation batterie avancée

## 🔧 Configuration Requise

- iOS 17.0+
- Xcode 15+
- Swift 6.0
- SwiftUI
- Firebase SDK

## 📱 Navigation Tabs

1. **Sessions** (🏃) - Écran principal avec carte
2. **Squads** (👥) - Gestion des groupes
3. **Profil** (👤) - Paramètres utilisateur

## 🎨 Composants UI Réutilisables

- `CustomTextField` - Champs de formulaire
- `CommunicationButton` - Boutons micro/photo/messages
- `MapControlButton` - Contrôles carte
- `ActiveSessionCard` - Carte session active
- `MarathonProgressCard` - Progression objectif
- `RunnerAvatar` - Avatar coureur
- `SquadCard` - Carte squad

## 🚀 Pour Démarrer

1. Ouvrir le projet dans Xcode
2. Ajouter Firebase via SPM (Package Dependencies)
3. Créer un Asset Catalog avec les couleurs (voir ColorGuide.swift)
4. Configurer Info.plist avec permissions localisation
5. Builder et tester sur simulateur/device

## 📝 Notes Importantes

- **Données Mock**: Phase 1 utilise des données de test pour valider l'UI
- **Firebase**: À connecter pour la persistance réelle
- **Localisation**: Nécessite device physique pour tests réels
- **Dark Mode**: Forcé dans l'app (.preferredColorScheme(.dark))
