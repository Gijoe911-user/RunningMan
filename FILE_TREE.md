# 📁 Structure Complète du Projet RunningMan

```
RunningMan/
│
├── 📱 RunningManApp.swift                          # Entry point avec Firebase
│
├── 📂 Core/                                        # Composants centraux
│   ├── AppState.swift                              # État global (@MainActor)
│   ├── RootView.swift                              # Navigation root
│   └── Navigation/
│       └── MainTabView.swift                       # Navigation à 3 tabs
│
├── 📂 Models/                                      # Modèles de données
│   └── Models.swift                                # Tous les models
│       ├── struct User
│       ├── struct Squad
│       ├── struct SquadMember
│       ├── struct RunSession
│       ├── struct RunnerLocation
│       └── struct Message
│
├── 📂 Features/                                    # Fonctionnalités par feature
│   │
│   ├── 📂 Authentication/
│   │   └── AuthenticationView.swift                # Connexion/Inscription
│   │       ├── CustomTextField
│   │       └── SignUp/SignIn toggle
│   │
│   ├── 📂 Sessions/                                # Écran principal
│   │   ├── SessionsListView.swift                  # Vue principale avec carte
│   │   │   ├── ActiveSessionCard
│   │   │   ├── MarathonProgressCard
│   │   │   ├── RunnerAvatar
│   │   │   ├── CommunicationBar
│   │   │   │   ├── CommunicationButton (Micro)
│   │   │   │   ├── CommunicationButton (Photo)
│   │   │   │   └── CommunicationButton (Messages)
│   │   │   └── MapControlButton
│   │   │
│   │   ├── SessionsViewModel.swift                 # Business logic + GPS
│   │   │   ├── CLLocationManagerDelegate
│   │   │   ├── Location tracking
│   │   │   └── Mock data
│   │   │
│   │   └── MapView.swift                           # Carte MapKit
│   │       ├── RunnerMapAnnotation
│   │       └── Triangle (shape)
│   │
│   ├── 📂 Squads/
│   │   ├── SquadsListView.swift                    # Liste des squads
│   │   │   ├── SquadCard
│   │   │   └── EmptySquadsView
│   │   │
│   │   ├── SquadsViewModel.swift                   # Gestion squads
│   │   │
│   │   └── SquadViews.swift                        # Vues auxiliaires
│   │       ├── CreateSquadView
│   │       ├── JoinSquadView
│   │       ├── SquadDetailView
│   │       └── CreateSessionView (placeholder)
│   │
│   └── 📂 Profile/
│       └── ProfileView.swift                       # Profil utilisateur
│           ├── StatCard
│           └── ProfileOption
│
├── 📂 Resources/                                   # Ressources & Documentation
│   ├── ColorGuide.swift                            # Palette couleurs + extensions
│   ├── InfoPlistGuide.swift                        # Guide permissions
│   ├── FirebaseSchema.swift                        # Schéma Firestore complet
│   └── ScreenAnnotations.swift                     # Documentation visuelle
│
├── 📂 Documentation/
│   ├── README.md                                   # Vue d'ensemble
│   ├── ARCHITECTURE.md                             # Architecture détaillée
│   ├── TODO.md                                     # Tâches à faire
│   ├── PROJECT_SUMMARY.md                          # Résumé complet
│   └── FILE_TREE.md                                # Ce fichier
│
└── 📂 Assets/                                      # À créer manuellement
    ├── Colors.xcassets/                            # Palette couleurs
    │   ├── DarkNavy.colorset
    │   ├── CoralAccent.colorset
    │   ├── PinkAccent.colorset
    │   ├── BlueAccent.colorset
    │   ├── PurpleAccent.colorset
    │   ├── GreenAccent.colorset
    │   └── YellowAccent.colorset
    │
    └── GoogleService-Info.plist                    # Firebase config
```

---

## 📊 Statistiques du Projet

### Fichiers Créés
```
Total fichiers:      17
Code Swift:          13
Documentation:       5

Lignes de code:      ~2,500
Lignes doc:          ~1,500
```

### Structure par Type
```
Views (SwiftUI):     8 fichiers
ViewModels:          2 fichiers
Models:              1 fichier
Core/App:            3 fichiers
Resources:           4 fichiers
Documentation:       5 fichiers
```

### Composants UI Réutilisables
```
CustomTextField          ✅
CommunicationButton      ✅
MapControlButton         ✅
ActiveSessionCard        ✅
MarathonProgressCard     ✅
RunnerAvatar             ✅
SquadCard                ✅
StatCard                 ✅
ProfileOption            ✅
EmptySquadsView          ✅
RunnerMapAnnotation      ✅
Triangle (Shape)         ✅
```

---

## 🎯 Organisation par Fonctionnalité

### 1. Authentification (1 écran)
```
Features/Authentication/
└── AuthenticationView.swift
    ├── Sign Up
    ├── Sign In
    └── Toggle entre les deux
```

### 2. Sessions - Écran Principal (1 écran + carte)
```
Features/Sessions/
├── SessionsListView.swift          # Vue principale
│   ├── MapView                     # Carte plein écran
│   ├── ActiveSessionCard           # Session en cours
│   ├── MarathonProgressCard        # Progression objectif
│   ├── RunnerAvatars               # Scroll horizontal
│   └── CommunicationBar            # Micro, Photo, Messages
│
├── SessionsViewModel.swift         # Logic + GPS
└── MapView.swift                   # Carte MapKit
```

### 3. Squads (3 écrans)
```
Features/Squads/
├── SquadsListView.swift            # Liste principale
├── CreateSquadView.swift           # Modal création
└── JoinSquadView.swift             # Modal rejoindre
```

### 4. Profile (1 écran)
```
Features/Profile/
└── ProfileView.swift               # Profil + paramètres
```

---

## 🗺️ Navigation Flow

```
                    [Launch]
                       |
                  RootView
                    |   |
        NON AUTH    |   |    AUTH
                    |   |
         ┌──────────┘   └──────────┐
         |                         |
    AuthView                  MainTabView
         |                         |
    [Sign Up]              ┌──────┼──────┐
    [Sign In]              |      |      |
         |                 |      |      |
         └─────────────────┘      |      |
                           |      |      |
                      Sessions Squads Profile
                       (Main)
```

---

## 🎨 Design System - Composants

### Forms
```
CustomTextField
├── Icon (SF Symbol)
├── Placeholder
├── Text input
└── Secure mode (optional)
```

### Cards
```
ActiveSessionCard
├── Icon
├── Title + subtitle
└── Action button

MarathonProgressCard
├── Header (icon + title + distance)
├── Progress bar (gradient)
└── Stats (% + days)

SquadCard
├── Icon (public/private)
├── Name + member count
├── Avatar stack
└── Chevron
```

### Buttons
```
CommunicationButton
├── Circular icon (56x56)
├── Label
└── Badge (optional)

MapControlButton
├── Circular icon (44x44)
└── Glassmorphism effect
```

### Avatars
```
RunnerAvatar
├── Circle (60x60)
├── Initial letter or photo
└── Active badge (green)
```

---

## 🔧 Services à Créer (Phase 1)

```
Services/
├── FirestoreService.swift          # CRUD Firestore
│   ├── func createUser()
│   ├── func createSquad()
│   ├── func joinSquad()
│   └── func observeMessages()
│
├── LocationService.swift           # GPS tracking
│   ├── func startTracking()
│   ├── func updateLocation()
│   └── func observeRunnerLocations()
│
├── TextToSpeechService.swift       # TTS
│   ├── func speak()
│   ├── func stopSpeaking()
│   └── func configureAudioSession()
│
├── MessageService.swift            # Messages
│   ├── func sendMessage()
│   └── func observeMessages()
│
└── PhotoService.swift              # Photos
    ├── func uploadPhoto()
    └── func downloadPhoto()
```

---

## 📱 Écrans par Tab

### Tab 1: Sessions 🏃
```
SessionsListView (Écran Principal)
├── Carte MapKit (plein écran)
│   ├── Annotations coureurs
│   └── Position utilisateur
│
├── Overlays (sur la carte)
│   ├── ActiveSessionCard
│   ├── MarathonProgressCard
│   └── RunnerAvatars (scroll)
│
├── Controls
│   ├── Center button (gauche)
│   └── Zoom +/- (droite)
│
└── CommunicationBar (bas)
    ├── Micro 🎤
    ├── Photo 📷
    └── Messages 💬 (badge)
```

### Tab 2: Squads 👥
```
SquadsListView
├── Header + Menu
├── Liste SquadCards
└── Empty state (si aucune)

Modals:
├── CreateSquadView
└── JoinSquadView
```

### Tab 3: Profile 👤
```
ProfileView
├── Avatar + Info
├── Stats (Courses, Distance, Squads)
├── Options menu
└── Déconnexion
```

---

## 🎨 Palette Couleurs

```
┌─────────────────────────────────────┐
│ DarkNavy    #1A1F3A  ██████████████ │ Fond
│ CoralAccent #FF6B6B  ██████████████ │ CTA/Coureurs
│ PinkAccent  #FF85A1  ██████████████ │ Messages
│ BlueAccent  #4ECDC4  ██████████████ │ Supporters
│ Purple      #9B59B6  ██████████████ │ Micro
│ Green       #2ECC71  ██████████████ │ Actif
│ Yellow      #F1C40F  ██████████████ │ Objectifs
└─────────────────────────────────────┘
```

---

## ⚙️ Configuration Requise

### Xcode
```
- Xcode 15+
- Swift 6.0
- iOS 17.0+ deployment target
```

### Firebase
```
- Project créé
- Authentication activée
- Firestore Database créée
- Storage bucket créé
- GoogleService-Info.plist ajouté
```

### Permissions Info.plist
```
- NSLocationAlwaysAndWhenInUseUsageDescription
- NSLocationWhenInUseUsageDescription
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription
- NSMicrophoneUsageDescription (Phase 2)
```

### Capabilities
```
- Background Modes: Location updates
- Push Notifications
```

### Swift Packages
```
- Firebase Auth
- Firebase Firestore
- Firebase FirestoreSwift
- Firebase Storage
```

---

## 📈 Progression Phase 1

### ✅ Complété
```
[████████████████████] 100%  Structure & Architecture
[████████████████████] 100%  UI/UX Design
[████████████████████] 100%  Navigation
[████████████████████] 100%  Models
[████████████████████] 100%  GPS Setup
[████████████████████] 100%  Documentation
```

### 🚧 En Cours
```
[░░░░░░░░░░░░░░░░░░░░]   0%  Firebase Setup
[░░░░░░░░░░░░░░░░░░░░]   0%  Backend Services
[░░░░░░░░░░░░░░░░░░░░]   0%  Realtime Sync
[░░░░░░░░░░░░░░░░░░░░]   0%  Text-to-Speech
[░░░░░░░░░░░░░░░░░░░░]   0%  Tests
```

---

## 🎯 Prochaines Étapes

### Immédiat (Aujourd'hui)
```
1. ✅ Configuration Firebase
2. ✅ Ajout GoogleService-Info.plist
3. ✅ Ajout Swift Packages
4. ✅ Création Asset Catalog Colors
5. ✅ Configuration Info.plist
```

### Court Terme (Cette Semaine)
```
1. ✅ FirestoreService implementation
2. ✅ LocationService implementation
3. ✅ Sync temps réel positions
4. ✅ Messages basiques
5. ✅ Text-to-Speech basique
```

### Moyen Terme (Semaine Prochaine)
```
1. ✅ Upload photos
2. ✅ UI Polish + animations
3. ✅ Error handling complet
4. ✅ Tests unitaires
5. ✅ Optimisation batterie
```

---

## 💾 Taille Estimée

```
Code Source:        ~300 KB
Assets/Images:      ~5 MB
Documentation:      ~100 KB
Dependencies:       ~50 MB (Firebase SDK)
Total Build:        ~60-70 MB
```

---

**Dernière mise à jour**: 23 Décembre 2025
**Version**: Phase 1 MVP Structure Complète
**Status**: Prêt pour intégration Firebase 🚀
