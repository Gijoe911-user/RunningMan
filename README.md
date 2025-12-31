# 🏃‍♂️ RunningMan

**RunningMan** est une application iOS de course collaborative permettant aux utilisateurs de créer des "squads" pour s'entraîner ensemble, partager leurs performances en temps réel, et atteindre leurs objectifs grâce à un système de gamification et de progression.

**Version actuelle :** v1.1.0 (30 décembre 2024)

---

## 📋 Table des matières

1. [Fonctionnalités](#-fonctionnalités)
2. [Architecture](#-architecture)
3. [Installation](#-installation)
4. [Configuration](#-configuration)
5. [Structure du projet](#-structure-du-projet)
6. [Documentation](#-documentation)
7. [Glossaire](#-glossaire)
8. [Roadmap](#-roadmap)
9. [Contribuer](#-contribuer)

---

## ✨ Fonctionnalités

### ✅ Actuellement disponibles (v1.1.0)

- **Authentification** : Connexion via email/mot de passe (Firebase Auth)
- **Gestion des Squads** : Créer et rejoindre des groupes de coureurs
- **Sessions de course** : Démarrer des sessions solo ou en groupe
- **Tracking GPS** : Suivi du tracé en temps réel sur carte
- **Localisation en temps réel** : Voir la position des autres coureurs
- **Widget de stats** : Distance, temps, BPM, calories en direct
- **🆕 Système de Progression** : Indice de consistance avec barre colorée
- **🆕 Objectifs hebdomadaires** : Distance ou durée, suivi automatique
- **🆕 ProgressionView** : Interface de gamification complète

### 🚧 En développement (Phase 1.2)

- **GPS Adaptatif** : Optimisation batterie selon allure
- **Passage de Relais** : Transfert admin si créateur quitte
- **HealthKit** : Monitoring cardiaque et calories
- **Notifications** : Alertes quand un membre démarre une session

### 🔮 À venir (Phases 2-4)

- **Chat textuel** : Communication dans les sessions
- **Partage de photos** : Capture et partage de moments
- **Audio Triggers** : Messages vocaux contextuels
- **Playlists Adaptatives** : Musique selon allure (Spotify/Apple Music)
- **Intégrations tierces** : Strava, Garmin Connect
- **Voice Chat** : Communication vocale push-to-talk
- **Apple Watch** : App compagnon watchOS
- **Analyse IA** : Coaching personnalisé post-course
- **Préparation Marathon** : Programmes d'entraînement structurés

Voir le fichier [PRD.md](./PRD.md) pour la roadmap complète.

---

## 🏗️ Architecture

RunningMan utilise une architecture **MVVM + Services** avec les principes suivants :

### Principes de conception

1. **Séparation des responsabilités**
   - **Views** : SwiftUI pur, aucune logique métier
   - **ViewModels** : Logique de présentation et orchestration
   - **Services** : Interactions avec Firebase, HealthKit, CoreLocation, etc.
   - **Models** : Structures de données Codable

2. **Isolation des contraintes techniques**
   - ✅ Les ViewModels ne doivent **jamais** importer Firebase
   - ✅ Seuls les Services peuvent interagir avec des SDK tiers
   - ✅ Si on change de backend demain, on ne modifie que les Services

3. **Gestion des états**
   - `@Published` pour les données affichées à l'écran uniquement
   - `Combine` pour les flux de données en temps réel (GPS, Firestore listeners)
   - `async/await` pour les opérations asynchrones (préféré à Dispatch/Combine)

4. **Protocoles et Testabilité**
   - Chaque Service expose un protocole pour permettre le mock dans les tests
   - Exemple : `DataSyncProtocol` permet d'ajouter Strava/Garmin sans toucher aux ViewModels

### Schéma de flux de données

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                         │
│  (SessionsListView, SquadHubView, SessionStatsWidget, etc.) │
└───────────────────────────┬─────────────────────────────────┘
                            │ @ObservedObject / @Environment
┌───────────────────────────▼─────────────────────────────────┐
│                         ViewModels                           │
│     (SessionsViewModel, SquadViewModel, @MainActor)         │
└───────────────────────────┬─────────────────────────────────┘
                            │ Appels async/await
┌───────────────────────────▼─────────────────────────────────┐
│                          Services                            │
│  SessionService, SquadService, RealtimeLocationService,     │
│  HealthKitManager, RouteTrackingService, NotificationService│
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────┴────────┐
                    │                │
┌───────────────────▼──┐   ┌─────────▼──────────────┐
│  Firebase Firestore  │   │  CoreLocation + Apple  │
│  Firebase Auth       │   │  HealthKit, UserNotif. │
└──────────────────────┘   └────────────────────────┘
```

### Gestion d'erreurs

Toutes les erreurs sont définies comme des `enum` conformes à `LocalizedError` :

```swift
enum SessionError: LocalizedError {
    case sessionNotFound
    case notAuthorized
    // ...
    
    var errorDescription: String? {
        // Messages localisés
    }
}
```

---

## 🛠️ Installation

### Prérequis

- **Xcode 16.0+**
- **iOS 17.0+**
- **Swift 6.0+**
- **CocoaPods** ou **Swift Package Manager**
- Compte Firebase (pour le backend)

### Étapes

1. **Cloner le repository**
   ```bash
   git clone https://github.com/votreorg/runningman.git
   cd runningman
   ```

2. **Installer les dépendances**
   
   Avec CocoaPods :
   ```bash
   pod install
   open RunningMan.xcworkspace
   ```
   
   Avec SPM : Les packages sont déjà configurés dans Xcode

3. **Configurer Firebase**
   - Téléchargez `GoogleService-Info.plist` depuis votre console Firebase
   - Ajoutez le fichier à la racine du projet Xcode
   - Assurez-vous qu'il est inclus dans le target `RunningMan`

4. **Configurer les autorisations**
   
   Le fichier `Info.plist` doit contenir les clés suivantes :
   
   ```xml
   <!-- Localisation GPS -->
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>RunningMan a besoin de votre position pour suivre votre course</string>
   
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>RunningMan suit votre position en arrière-plan pendant les sessions</string>
   
   <!-- HealthKit -->
   <key>NSHealthShareUsageDescription</key>
   <string>Accès au rythme cardiaque pour un suivi précis</string>
   
   <key>NSHealthUpdateUsageDescription</key>
   <string>Enregistrement des sessions de course dans l'app Santé</string>
   
   <!-- Face ID (optionnel, pour authentification biométrique) -->
   <key>NSFaceIDUsageDescription</key>
   <string>RunningMan utilise Face ID pour une connexion rapide et sécurisée</string>
   ```
   
   **Ajouter via Xcode :**
   - Ouvrir `Info.plist`
   - Cliquer sur `+` et taper `Privacy - [Type] Usage Description`
   - Ajouter la description appropriée

5. **Build & Run**
   - Sélectionnez votre device ou simulateur
   - `Cmd + R`

---

## ⚙️ Configuration

### Clés API (Optionnel)

Pour activer les intégrations tierces, ajoutez les clés dans `Info.plist` :

```xml
<!-- Strava -->
<key>StravaClientID</key>
<string>VOTRE_CLIENT_ID</string>
<key>StravaClientSecret</key>
<string>VOTRE_CLIENT_SECRET</string>

<!-- Garmin -->
<key>GarminConsumerKey</key>
<string>VOTRE_CONSUMER_KEY</string>
<key>GarminConsumerSecret</key>
<string>VOTRE_CONSUMER_SECRET</string>
```

### Feature Flags

Activez/désactivez des fonctionnalités en cours de développement dans `FeatureFlags.swift` :

```swift
enum FeatureFlags {
    static let voiceChat = false           // Push-to-Talk
    static let stravaIntegration = false   // Sync Strava
    static let heartRateMonitoring = true  // HealthKit
    // ...
}
```

Les fonctionnalités désactivées n'apparaîtront pas dans l'UI.

---

## 📚 Documentation

### Guides Principaux

- **[PRD.md](./PRD.md)** - Product Requirements Document complet
- **[LIVRAISON_PHASE_2.md](./LIVRAISON_PHASE_2.md)** - Résumé de la refactorisation v1.1.0
- **[REFACTORING_SUMMARY.md](./REFACTORING_SUMMARY.md)** - Guide de migration et prochaines étapes
- **[FIRESTORE_MIGRATION_V2.md](./FIRESTORE_MIGRATION_V2.md)** - Scripts de migration base de données

### Guides Techniques

- **[SESSION_VISIBILITY_FIX.md](./SESSION_VISIBILITY_FIX.md)** - Correction bugs de synchronisation sessions
- **[INTEGRATION_GUIDE_WIDGETS.md](./INTEGRATION_GUIDE_WIDGETS.md)** - Intégration des widgets de stats

### Architecture

- **[REFACTORING_PLAN.md](./REFACTORING_PLAN.md)** - Plan détaillé de l'architecture Services

---

## 📁 Structure du projet

```
RunningMan/
├── Features/
│   ├── Session-Running/
│   │   ├── ViewModels/
│   │   │   └── SessionsViewModel.swift
│   │   ├── Views/
│   │   │   ├── SessionsListView.swift
│   │   │   ├── SessionStatsWidget.swift
│   │   │   └── EnhancedSessionMapView.swift
│   │   ├── Services/
│   │   │   ├── SessionService.swift
│   │   │   ├── RouteTrackingService.swift
│   │   │   ├── RealtimeLocationService.swift
│   │   │   └── HealthKitManager.swift
│   │   └── Models/
│   │       ├── SessionModel.swift
│   │       └── ParticipantStats.swift
│   ├── Squad-Hub/
│   │   ├── ViewModels/
│   │   │   └── SquadViewModel.swift
│   │   ├── Views/
│   │   │   ├── SquadHubView.swift
│   │   │   └── CreateSquadView.swift
│   │   ├── Services/
│   │   │   └── SquadService.swift
│   │   └── Models/
│   │       └── SquadModel.swift
│   ├── Integrations/
│   │   ├── Protocols/
│   │   │   └── DataSyncProtocol.swift
│   │   ├── Strava/
│   │   │   └── StravaService.swift (stub)
│   │   └── Garmin/
│   │       └── GarminService.swift (stub)
│   └── Core/
│       ├── Services/
│       │   ├── AuthService.swift
│       │   ├── NotificationService.swift
│       │   └── LocationProvider.swift
│       ├── Utilities/
│       │   ├── Logger.swift
│       │   └── FeatureFlags.swift
│       └── Extensions/
│           └── Color+Theme.swift
├── Resources/
│   ├── GoogleService-Info.plist
│   └── Assets.xcassets/
├── App/
│   ├── RunningManApp.swift
│   └── Info.plist
├── Tests/
│   └── RunningManTests/
├── README.md
├── PRD.md
└── CHANGELOG.md
```

---

## 📖 Glossaire

### Squad
Un **Squad** est un groupe de coureurs qui s'entraînent ensemble. Chaque squad a :
- Un nom et une description
- Un code d'invitation unique
- Une liste de membres avec des rôles (admin, membre, lecteur)

### Session
Une **Session** représente une activité de course. Elle peut être :
- **Active** : En cours, avec tracking GPS et participants en direct
- **Scheduled** : Planifiée pour plus tard
- **Ended** : Terminée, avec stats finales sauvegardées

### Tracé (Route)
Le **tracé** est la liste des coordonnées GPS enregistrées pendant une session. Il est :
- Enregistré en temps réel dans Firebase
- Affiché sur la carte avec une polyline
- Utilisé pour calculer la distance et l'allure

### Participant Stats
Les **stats de participant** incluent :
- Distance parcourue
- Durée totale
- Vitesse moyenne et max
- Rythme cardiaque (si HealthKit activé)
- Calories brûlées

---

## 🗺️ Roadmap

Voir le fichier [PRD.md](./PRD.md) pour la roadmap détaillée avec dates et priorités.

**Résumé des prochaines étapes :**

1. **Phase 1 (Janvier 2025)** : HealthKit complet + Notifications live
2. **Phase 2 (Février 2025)** : Intégration Strava + Chat textuel
3. **Phase 3 (Mars 2025)** : Voice Chat + Apple Watch
4. **Phase 4 (Avril 2025)** : Analyse IA + Programme Marathon

---

## 🤝 Contribuer

### Standards de code

1. **Limite de 200 lignes par fichier**
   - Si dépassé, diviser en extensions ou sous-services

2. **Documentation in-code**
   - Utiliser `///` pour documenter les fonctions publiques
   - Exemple :
     ```swift
     /// Démarre une session de course
     /// - Parameters:
     ///   - squadId: Identifiant de la squad
     ///   - type: Type d'activité
     /// - Returns: La session créée
     func startSession(squadId: String, type: SessionType) async throws -> SessionModel
     ```

3. **Gestion d'erreurs**
   - Utiliser des `enum` avec `LocalizedError`
   - Pas de messages String "magiques"

4. **Extensions pour les protocoles**
   ```swift
   // ✅ Bon
   extension SessionService: SomeDelegate {
       // Implémentation du delegate
   }
   
   // ❌ Mauvais (tout dans la classe principale)
   class SessionService: SomeDelegate {
       // Trop de responsabilités
   }
   ```

5. **Tests**
   - Utiliser Swift Testing (`@Test`, `#expect`)
   - Mocker les services via protocoles

### Git Workflow

**Format des commits :**
```
feat(session): ajout monitoring cardiaque HealthKit
fix(squad): correction crash lors de l'invitation
docs(readme): mise à jour configuration Firebase
refactor(services): isolation Firebase dans SessionService
```

**Branches :**
- `main` : Production
- `develop` : Développement
- `feature/nom-feature` : Nouvelles fonctionnalités
- `fix/nom-bug` : Corrections

---

## 📄 License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](./LICENSE) pour plus d'informations.

---

## 👨‍💻 Équipe

Développé avec ❤️ par l'équipe RunningMan.

**Contact :** runningman@example.com

---

## 🙏 Remerciements

- Firebase pour le backend temps réel
- Apple pour HealthKit et CoreLocation
- La communauté Swift pour les retours et contributions

---

**Bon run ! 🏃‍♂️💨**
