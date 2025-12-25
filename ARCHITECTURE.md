# RunningMan - Architecture Phase 1 MVP

## 📱 Structure de l'Application

```
┌─────────────────────────────────────────────────────────────┐
│                     RunningManApp.swift                     │
│                    (Entry Point + Firebase)                 │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   AppState    │
                    │  @Published   │
                    │ - isAuth      │
                    │ - currentUser │
                    │ - activeSession│
                    └───────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                         RootView                            │
└───────────────┬─────────────────────┬───────────────────────┘
                │                     │
     NON AUTH   │                     │   AUTH
                ▼                     ▼
    ┌──────────────────┐    ┌──────────────────┐
    │ Authentication   │    │   MainTabView    │
    │      View        │    │   (3 Tabs)       │
    └──────────────────┘    └──────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
            ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
            │  Sessions    │  │   Squads     │  │   Profile    │
            │   ListView   │  │   ListView   │  │     View     │
            │     🏃       │  │     👥       │  │     👤       │
            └──────────────┘  └──────────────┘  └──────────────┘
                    │
                    ├── MapView (MapKit)
                    ├── SessionsViewModel
                    │   └── LocationManager
                    └── Communication Bar
                        ├── Micro 🎤
                        ├── Photo 📷
                        └── Messages 💬
```

## 🗂️ Organisation des Dossiers

```
RunningMan/
│
├── RunningManApp.swift                 # Entry point
│
├── Core/
│   ├── AppState.swift                  # État global
│   ├── RootView.swift                  # Navigation root
│   └── Navigation/
│       └── MainTabView.swift           # Tabs principale
│
├── Models/
│   └── Models.swift                    # Data models
│       ├── User
│       ├── Squad
│       ├── SquadMember
│       ├── RunSession
│       ├── RunnerLocation
│       └── Message
│
├── Features/
│   ├── Authentication/
│   │   └── AuthenticationView.swift
│   │
│   ├── Sessions/                       # ÉCRAN PRINCIPAL
│   │   ├── SessionsListView.swift     # Vue avec carte
│   │   ├── SessionsViewModel.swift    # Business logic
│   │   └── MapView.swift              # Carte MapKit
│   │
│   ├── Squads/
│   │   ├── SquadsListView.swift       # Liste squads
│   │   ├── SquadsViewModel.swift      # Gestion squads
│   │   └── SquadViews.swift           # Create/Join/Detail
│   │
│   └── Profile/
│       └── ProfileView.swift          # Profil utilisateur
│
├── Resources/
│   ├── ColorGuide.swift               # Palette couleurs
│   ├── InfoPlistGuide.swift           # Permissions
│   └── FirebaseSchema.swift           # Doc Firestore
│
└── README.md                          # Documentation
```

## 🎨 Composants UI Réutilisables

```
UI Components/
│
├── Form Components
│   └── CustomTextField
│       ├── Icon
│       ├── Placeholder
│       └── Secure mode
│
├── Session Components
│   ├── ActiveSessionCard
│   │   ├── Icon + Nom
│   │   ├── Nombre coureurs
│   │   └── Bouton Play/Stop
│   │
│   ├── MarathonProgressCard
│   │   ├── Icône + Titre
│   │   ├── Barre progression
│   │   └── Stats (%, jours)
│   │
│   └── RunnerAvatar
│       ├── Avatar circulaire
│       └── Badge "actif"
│
├── Communication
│   ├── CommunicationBar
│   │   ├── Micro button
│   │   ├── Photo button
│   │   └── Messages button (+ badge)
│   │
│   └── CommunicationButton
│       ├── Icon circulaire coloré
│       ├── Label
│       └── Badge optionnel
│
├── Map Components
│   ├── MapView
│   │   └── RunnerMapAnnotation
│   │       ├── Cercle distance
│   │       └── Triangle pointeur
│   │
│   └── MapControlButton
│       └── Bouton circulaire glassmorphism
│
└── Squad Components
    ├── SquadCard
    │   ├── Icône + Nom
    │   ├── Nombre membres
    │   └── Aperçu avatars
    │
    └── EmptySquadsView
        ├── Icône placeholder
        ├── Message vide
        └── Boutons actions
```

## 🔄 Flux de Données

```
                        ┌──────────────┐
                        │   Firebase   │
                        │   Backend    │
                        └──────────────┘
                               ▲│
                               │▼
                        ┌──────────────┐
                        │  AppState    │◄─── Listen Auth
                        └──────────────┘
                               │
                               │ EnvironmentObject
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │Sessions  │   │ Squads   │   │ Profile  │
        │ViewModel │   │ViewModel │   │   View   │
        └──────────┘   └──────────┘   └──────────┘
                │              │
                │              │
                ▼              ▼
        ┌──────────┐   ┌──────────┐
        │ Sessions │   │  Squads  │
        │   View   │   │   View   │
        └──────────┘   └──────────┘
```

## 🎯 Flow Utilisateur Principal

```
1. LANCEMENT APP
   └─► RootView check Auth
       ├─► Non connecté → AuthenticationView
       │   ├─► S'inscrire
       │   └─► Se connecter
       │           │
       │           ▼
       └─► Connecté → MainTabView
                         │
                         └─► Tab Sessions (par défaut)

2. CRÉER/REJOINDRE SQUAD
   └─► Tab Squads
       ├─► Créer Squad
       │   ├─► Nom
       │   ├─► Type (Privé/Public)
       │   └─► Code généré
       │
       └─► Rejoindre Squad
           └─► Entrer code

3. DÉMARRER SESSION
   └─► Tab Sessions
       ├─► Voir carte
       ├─► Voir coureurs actifs
       ├─► Bouton Play
       │   └─► Démarre tracking GPS
       │
       └─► Communication
           ├─► Micro (Phase 2)
           ├─► Photo
           └─► Messages

4. PENDANT LA COURSE
   └─► Vue Live
       ├─► Carte temps réel
       │   ├─► Position utilisateur
       │   └─► Positions coéquipiers
       │
       ├─► Progression marathon
       │   ├─► % complété
       │   └─► Jours restants
       │
       └─► Messages/Audio
           └─► Text-to-Speech

5. FIN DE SESSION
   └─► Bouton Stop
       └─► Sauvegarde données
           └─► Capsule temporelle (Phase 3)
```

## 🔐 Permissions iOS Requises

```
┌────────────────────────────────────────┐
│         PHASE 1 - MVP                  │
├────────────────────────────────────────┤
│ ✅ Location Always                     │
│ ✅ Location When In Use                │
│ ✅ Camera                              │
│ ✅ Photo Library                       │
├────────────────────────────────────────┤
│         PHASE 2                        │
├────────────────────────────────────────┤
│ ⏳ Microphone                          │
│ ⏳ Push Notifications                  │
├────────────────────────────────────────┤
│         PHASE 3                        │
├────────────────────────────────────────┤
│ ⏳ Motion & Fitness                    │
│ ⏳ HealthKit                           │
└────────────────────────────────────────┘
```

## 🎨 Design System - Couleurs

```
┌─────────────────────────────────────────┐
│  DarkNavy      #1A1F3A   ████████████   │ Fond principal
│  CoralAccent   #FF6B6B   ████████████   │ Coureurs / CTA
│  PinkAccent    #FF85A1   ████████████   │ Messages
│  BlueAccent    #4ECDC4   ████████████   │ Supporters
│  PurpleAccent  #9B59B6   ████████████   │ Micro
│  GreenAccent   #2ECC71   ████████████   │ Actif / Play
│  YellowAccent  #F1C40F   ████████████   │ Objectifs
└─────────────────────────────────────────┘
```

## 🚀 État d'Implémentation Phase 1

```
✅ COMPLÉTÉ
├── ✅ Structure navigation SwiftUI
├── ✅ Authentification (Firebase Auth)
├── ✅ Interface Sessions avec carte
├── ✅ Gestion Squads (Create/Join)
├── ✅ Interface Communication Bar
├── ✅ Tracking GPS (CoreLocation)
└── ✅ Design System complet

🚧 EN COURS / À FAIRE
├── 🚧 Connexion Firestore
├── 🚧 Sync temps réel positions
├── 🚧 Messages text-to-speech
├── 🚧 Upload photos
├── 🚧 Gestion sessions actives
└── 🚧 Optimisation batterie
```

## 📊 Performance Targets Phase 1

```
Batterie     : < 15% par heure
Latence GPS  : < 5 secondes
Latence Msg  : < 2 secondes
Crash Rate   : < 0.1%
Memory       : < 150MB
Network      : < 50KB/min GPS
```
