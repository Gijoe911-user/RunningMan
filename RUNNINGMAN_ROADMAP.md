# 🏃‍♂️ RunningMan - État du Projet & Prochaines Étapes

**Date de mise à jour :** 23 décembre 2025  
**Version :** En développement actif  
**Plateforme :** iOS (SwiftUI + Firebase)

---

## 📱 Concept de l'Application

**RunningMan** est une application de course collaborative qui permet aux coureurs de se motiver mutuellement via des "squads" (équipes).

### Fonctionnalités Clés
- 🏃 Création et gestion de squads de coureurs
- 👥 Système de rôles : Coureurs et Supporters
- 📊 Suivi des performances et statistiques
- 🔥 Motivation et encouragements entre membres
- 🎯 Objectifs et défis d'équipe

---

## ✅ Ce qui est Déjà Implémenté

### 🔐 Authentification
- ✅ Inscription avec email/mot de passe
- ✅ Connexion
- ✅ Déconnexion
- ✅ Réinitialisation de mot de passe
- ✅ Gestion d'état utilisateur avec `AuthViewModel`
- ✅ Validation des formulaires
- ✅ Indicateurs de force du mot de passe
- ⏳ AutoFill (code prêt, config Xcode à faire)
- ⏳ Face ID (code prêt, config à faire)

**Fichiers :**
- `LoginView.swift` - Interface de connexion/inscription
- `AuthViewModel.swift` - Logique d'authentification
- `AuthService.swift` - Service Firebase Auth

### 👥 Gestion des Squads
- ✅ Service de gestion des squads
- ✅ ViewModel pour les squads
- ⏳ Interface utilisateur à finaliser

**Fichiers :**
- `SquadService.swift` - Service Firestore pour squads
- `SquadViewModel.swift` - Logique des squads

### 🎨 Design System
- ✅ Palette de couleurs Dark Mode néon
- ✅ Extensions de couleurs personnalisées
- ✅ Guide de style

**Fichiers :**
- `ResourcesColorGuide.swift` - Définitions couleurs

**Couleurs Disponibles :**
- `.darkNavy` - Fond principal (#1A1F3A)
- `.coralAccent` - Accent principal coureurs (#FF6B6B)
- `.blueAccent` - Accent supporters (#4ECDC4)
- `.pinkAccent` - Accent secondaire (#FF85A1)
- `.purpleAccent` - Accent tertiaire (#9B59B6)
- `.greenAccent` - Statut actif (#2ECC71)
- `.yellowAccent` - Avertissements (#F1C40F)

### 🛠️ Infrastructure
- ✅ Firebase configuré (Auth + Firestore)
- ✅ Logger système
- ✅ Local Storage Service
- ✅ Navigation de base

**Fichiers :**
- `RunningManApp.swift` - Point d'entrée
- `Logger.swift` - Système de logs
- `LocalStorageService.swift` - Stockage local
- `APIConfig.swift` - Configuration API

---

## 🚧 À Développer - Priorité Haute

### 1. 🏠 Écran Principal (Dashboard)

**Objectif :** Écran d'accueil après connexion

**Fonctionnalités :**
- Liste des squads de l'utilisateur
- Statistiques rapides (courses cette semaine, km parcourus)
- Notifications/encouragements récents
- Bouton pour créer/rejoindre un squad

**Fichiers à créer :**
- `DashboardView.swift`
- `DashboardViewModel.swift` (optionnel)

**Design :**
```
┌─────────────────────────────────────┐
│  👋 Bonjour, [Nom]                  │
│                                     │
│  📊 Cette semaine                   │
│  ├─ 3 courses                       │
│  ├─ 15.2 km                         │
│  └─ 2 squads actifs                 │
│                                     │
│  🏃 Mes Squads                      │
│  ┌─────────────────────────────┐   │
│  │ Squad Marathon 2024         │   │
│  │ 5 coureurs • 2 supporters   │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Les Runners du Dimanche     │   │
│  │ 3 coureurs • 1 supporter    │   │
│  └─────────────────────────────┘   │
│                                     │
│  [+ Créer un Squad]                 │
│  [🔍 Rejoindre un Squad]            │
└─────────────────────────────────────┘
```

---

### 2. 🏃 Création/Gestion de Squad

**Objectif :** Permettre de créer et gérer un squad

**Fonctionnalités :**
- Formulaire de création (nom, description, image)
- Paramètres (public/privé, objectifs)
- Invitations de membres
- Attribution des rôles (coureur/supporter)
- Paramètres du squad

**Fichiers à créer :**
- `CreateSquadView.swift`
- `SquadDetailView.swift`
- `SquadSettingsView.swift`
- `InviteMembersView.swift`

**Modèles (à vérifier/créer) :**
- `SquadModel.swift`
- `MemberModel.swift`

---

### 3. 📊 Profil Utilisateur

**Objectif :** Profil personnel avec stats

**Fonctionnalités :**
- Photo de profil
- Statistiques personnelles
- Historique des courses
- Liste des squads
- Paramètres du compte

**Fichiers à créer :**
- `ProfileView.swift`
- `ProfileEditView.swift`
- `UserStatsView.swift`

---

### 4. 🎯 Enregistrement d'une Course

**Objectif :** Enregistrer une session de course

**Fonctionnalités :**
- Tracking GPS (CoreLocation)
- Chronomètre
- Distance, vitesse, calories
- Sauvegarde dans Firestore
- Partage avec les squads

**Fichiers à créer :**
- `RunTrackingView.swift`
- `RunTrackingViewModel.swift`
- `LocationService.swift`
- `RunModel.swift`

**Technologies :**
- CoreLocation pour GPS
- HealthKit pour calories (optionnel)
- MapKit pour afficher le parcours

---

### 5. 💬 Système de Motivation/Feed

**Objectif :** Feed social pour le squad

**Fonctionnalités :**
- Voir les courses des membres
- Laisser des encouragements (🔥 💪 👏)
- Commenter
- Notifications push

**Fichiers à créer :**
- `SquadFeedView.swift`
- `RunPostView.swift`
- `CommentView.swift`
- `NotificationService.swift`

---

## 🎨 Priorité Moyenne

### 6. 📈 Statistiques Avancées
- Graphiques de progression
- Comparaisons squad
- Leaderboards
- Badges et achievements

### 7. 🔔 Notifications
- Push notifications
- In-app notifications
- Préférences de notifications

### 8. ⚙️ Paramètres Avancés
- Unités (km/miles)
- Confidentialité
- Connexions externes (Strava, etc.)

---

## 🔮 Priorité Basse / Futures Idées

### 9. 🏆 Défis et Compétitions
- Défis personnalisés
- Compétitions entre squads
- Récompenses virtuelles

### 10. 📱 Widgets
- Widget de stats
- Widget de prochaine course
- Live Activities pendant la course

### 11. ⌚ Apple Watch
- App companion Watch
- Tracking depuis la montre

---

## 🗂️ Architecture Recommandée

```
RunningMan/
├── App/
│   └── RunningManApp.swift
│
├── Core/
│   ├── Services/
│   │   ├── AuthService.swift ✅
│   │   ├── SquadService.swift ✅
│   │   ├── LocationService.swift 🚧
│   │   ├── NotificationService.swift 🚧
│   │   └── LocalStorageService.swift ✅
│   │
│   ├── Models/
│   │   ├── UserModel.swift 🚧
│   │   ├── SquadModel.swift 🚧
│   │   ├── RunModel.swift 🚧
│   │   └── MemberModel.swift 🚧
│   │
│   └── Utilities/
│       ├── Logger.swift ✅
│       └── APIConfig.swift ✅
│
├── Features/
│   ├── Authentication/
│   │   ├── LoginView.swift ✅
│   │   ├── AuthViewModel.swift ✅
│   │   └── FeaturesAuthenticationAuthenticationView.swift ✅
│   │
│   ├── Dashboard/
│   │   ├── DashboardView.swift 🚧
│   │   └── DashboardViewModel.swift 🚧
│   │
│   ├── Squad/
│   │   ├── SquadListView.swift 🚧
│   │   ├── CreateSquadView.swift 🚧
│   │   ├── SquadDetailView.swift 🚧
│   │   ├── SquadViewModel.swift ✅
│   │   └── SquadFeedView.swift 🚧
│   │
│   ├── Run/
│   │   ├── RunTrackingView.swift 🚧
│   │   ├── RunHistoryView.swift 🚧
│   │   └── RunTrackingViewModel.swift 🚧
│   │
│   └── Profile/
│       ├── ProfileView.swift 🚧
│       ├── ProfileEditView.swift 🚧
│       └── UserStatsView.swift 🚧
│
└── Resources/
    ├── ResourcesColorGuide.swift ✅
    └── Assets.xcassets
```

**Légende :**
- ✅ Implémenté
- 🚧 À développer
- ⏳ Partiellement implémenté

---

## 🎯 Plan de Développement Recommandé

### Sprint 1 : Navigation et Base (3-5 jours)
1. Créer `RootView` qui gère la navigation Auth ↔ Dashboard
2. Créer les modèles de base (User, Squad, Run)
3. Mettre en place la navigation principale (TabView)

### Sprint 2 : Dashboard et Squads (5-7 jours)
4. Dashboard avec liste des squads
5. Création de squad
6. Détail d'un squad
7. Invitation de membres

### Sprint 3 : Tracking de Course (7-10 jours)
8. LocationService avec CoreLocation
9. Interface de tracking
10. Sauvegarde des courses
11. Affichage de l'historique

### Sprint 4 : Feed Social (5-7 jours)
12. Feed des activités du squad
13. Système d'encouragements
14. Commentaires

### Sprint 5 : Polish et Optimisations (3-5 jours)
15. Statistiques avancées
16. Paramètres utilisateur
17. Optimisations performances
18. Tests

---

## 🔧 Prochaines Actions Immédiates

### 1. Créer les Modèles de Base

```swift
// UserModel.swift
struct UserModel: Identifiable, Codable {
    var id: String
    var email: String
    var displayName: String
    var photoURL: String?
    var role: UserRole
    var squads: [String] // IDs des squads
    var stats: UserStats?
    var createdAt: Date
}

enum UserRole: String, Codable {
    case runner = "runner"
    case supporter = "supporter"
}

struct UserStats: Codable {
    var totalRuns: Int
    var totalDistance: Double // en km
    var totalDuration: TimeInterval // en secondes
    var averagePace: Double // min/km
}
```

```swift
// SquadModel.swift
struct SquadModel: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var imageURL: String?
    var creatorId: String
    var memberIds: [String]
    var isPublic: Bool
    var goals: SquadGoals?
    var createdAt: Date
}

struct SquadGoals: Codable {
    var weeklyDistance: Double?
    var monthlyDistance: Double?
    var weeklyRuns: Int?
}
```

```swift
// RunModel.swift
struct RunModel: Identifiable, Codable {
    var id: String
    var userId: String
    var squadId: String?
    var distance: Double // km
    var duration: TimeInterval // secondes
    var startDate: Date
    var endDate: Date
    var averagePace: Double // min/km
    var calories: Int?
    var route: [Coordinate]? // Points GPS
    var encouragements: [Encouragement]
}

struct Coordinate: Codable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
}

struct Encouragement: Identifiable, Codable {
    var id: String
    var userId: String
    var emoji: String
    var message: String?
    var timestamp: Date
}
```

### 2. Créer RootView

```swift
// RootView.swift
struct RootView: View {
    @Environment(AuthViewModel.self) private var authVM
    
    var body: some View {
        Group {
            if authVM.isLoading {
                ProgressView()
            } else if authVM.isAuthenticated {
                if authVM.hasSquad {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            } else {
                LoginView()
            }
        }
    }
}
```

### 3. Créer MainTabView

```swift
// MainTabView.swift
struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }
            
            SquadListView()
                .tabItem {
                    Label("Squads", systemImage: "person.3.fill")
                }
            
            RunTrackingView()
                .tabItem {
                    Label("Course", systemImage: "figure.run")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
        }
        .tint(.coralAccent)
    }
}
```

---

## 💡 Conseils de Développement

### Firebase Firestore Structure

```
users/
  {userId}/
    - email
    - displayName
    - photoURL
    - role
    - squads: []
    - stats: {}
    - createdAt

squads/
  {squadId}/
    - name
    - description
    - imageURL
    - creatorId
    - memberIds: []
    - isPublic
    - goals: {}
    - createdAt

runs/
  {runId}/
    - userId
    - squadId
    - distance
    - duration
    - startDate
    - endDate
    - averagePace
    - calories
    - route: []
    - encouragements: []

notifications/
  {notificationId}/
    - userId
    - type
    - message
    - isRead
    - createdAt
```

### Permissions iOS Requises

Dans `Info.plist`, ajouter :

```xml
<!-- Pour le GPS -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>RunningMan a besoin de votre localisation pour enregistrer vos courses</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>RunningMan utilise votre localisation pour suivre vos courses en arrière-plan</string>

<!-- Pour HealthKit (optionnel) -->
<key>NSHealthShareUsageDescription</key>
<string>RunningMan souhaite lire vos données de santé pour calculer les calories brûlées</string>

<key>NSHealthUpdateUsageDescription</key>
<string>RunningMan souhaite sauvegarder vos courses dans l'app Santé</string>

<!-- Pour les notifications -->
<key>NSUserNotificationsUsageDescription</key>
<string>RunningMan vous envoie des notifications pour les encouragements de votre squad</string>
```

---

## 📞 Besoin d'Aide ?

Pour développer une fonctionnalité spécifique, demandez :
- "Créons le DashboardView"
- "Implémentons le tracking GPS"
- "Développons le système de squads"

Je vous guiderai étape par étape avec du code prêt à l'emploi ! 🚀

---

**Dernière mise à jour :** 23 décembre 2025  
**Statut :** Authentification ✅ | Navigation 🚧 | Features 🚧  
**Prochaine étape suggérée :** Créer RootView et MainTabView
