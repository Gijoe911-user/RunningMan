# 🏗️ Plan de Refactorisation Architecture & Gamification

**Date :** 30 décembre 2024  
**Objectif :** Passer à une architecture Services modulaire + Système de progression  
**Statut :** 🚧 En cours

---

## 📋 Audit Initial

### Fichiers Actuels (22 visibles)

#### ✅ Fichiers Swift à Conserver
- `ActiveSessionDetailView.swift`
- `ActiveSessionMapContainerView.swift`
- `AllActiveSessionsView.swift`
- `BiometricAuthHelper.swift`
- `CreateSessionView.swift`
- `DesignSystem.swift`
- `ProfileView.swift`
- `RealtimeLocationService.swift` ✨ (Déjà bien structuré)
- `SessionModel.swift`
- `SessionModels+Extensions.swift`
- `SessionsListView.swift`
- `SessionsViewModel.swift`
- `SquadSessionsListView.swift`

#### 🗑️ Fichiers .md à Supprimer du Source
- `CLEANUP_GUIDE.md` → Déplacer vers `/docs`
- `FIREBASE_CLEANUP_GUIDE.md` → Déplacer vers `/docs`
- `INTEGRATION_GUIDE_WIDGETS.md` → Déplacer vers `/docs`
- `MISSION_EXECUTION_PLAN.md` → Déplacer vers `/docs`
- `README.md` → Garder à la racine
- `RESTRUCTURE_BY_FEATURES.md` → Déplacer vers `/docs`
- `FirebaseSchema.swift` → Transformer en documentation `/docs/FIRESTORE_SCHEMA.md`
- `SessionServiceTests.swift` → Garder mais renommer en doc si non exécutable

#### ⚠️ Fichiers Manquants (à rechercher)
- Services Firebase (SessionService, SquadService, etc.)
- HealthKit Manager/Service
- Location Provider
- Route Tracking Service
- Auth Service

---

## 🎯 Objectifs de la Refactorisation

### 1. Nettoyage & Modularité
- ✅ Supprimer les fichiers .md du dossier source
- ✅ Isoler Firebase/HealthKit dans Services
- ✅ Documentation via DocBlocks (///)
- ✅ Limite de 200 lignes par fichier

### 2. Refonte Data Model
- ✅ **User** : `consistencyRate`, `weeklyGoals[]`, `avatarUrl`, `bio`, rôle par squad
- ✅ **Squad** : `plannedRaces[]` avec activation automatique
- ✅ **Session** : Statut `.archived`, logique "Passage de Relais"

### 3. Gamification
- ✅ `ProgressionService` : Calcul indice de consistance
- ✅ Barre de progression colorée (Vert/Jaune/Rouge)

### 4. Audio & Music (Préparation)
- ✅ `AudioTrigger` struct
- ✅ `MusicManager` boilerplate

### 5. Optimisation Batterie
- ✅ Tracking GPS adaptatif selon allure

---

## 📁 Nouvelle Architecture Cible

```
RunningMan/
├── App/
│   ├── RunningManApp.swift
│   └── AppDelegate.swift
│
├── Core/
│   ├── Models/
│   │   ├── User/
│   │   │   ├── UserModel.swift             ✅ Refonte
│   │   │   ├── UserProgress.swift          🆕 Gamification
│   │   │   └── WeeklyGoal.swift            🆕
│   │   ├── Squad/
│   │   │   ├── SquadModel.swift            ✅ Refonte
│   │   │   ├── PlannedRace.swift           🆕
│   │   │   └── SquadMemberRole.swift       ✅ Refonte
│   │   ├── Session/
│   │   │   ├── SessionModel.swift          ✅ Refonte
│   │   │   ├── ParticipantStats.swift
│   │   │   └── SessionStatus.swift         ✅ Ajout .archived
│   │   └── Audio/
│   │       ├── AudioTrigger.swift          🆕
│   │       └── MusicPlaylist.swift         🆕
│   │
│   ├── Services/
│   │   ├── Firebase/
│   │   │   ├── FirebaseService.swift       🆕 Base class
│   │   │   ├── AuthService.swift
│   │   │   ├── UserService.swift           🆕
│   │   │   ├── SquadService.swift          🆕
│   │   │   ├── SessionService.swift        ✅ Refonte
│   │   │   └── StorageService.swift        🆕 (Photos)
│   │   ├── Health/
│   │   │   ├── HealthKitService.swift      ✅ Refonte
│   │   │   └── WorkoutService.swift        🆕
│   │   ├── Location/
│   │   │   ├── LocationService.swift       ✅ Renommé de LocationProvider
│   │   │   ├── RouteTrackingService.swift
│   │   │   └── RealtimeLocationService.swift ✅ Déjà OK
│   │   ├── Gamification/
│   │   │   ├── ProgressionService.swift    🆕
│   │   │   ├── AchievementService.swift    🆕 (Future)
│   │   │   └── LeaderboardService.swift    🆕 (Future)
│   │   └── Audio/
│   │       ├── AudioTriggerService.swift   🆕
│   │       └── MusicManager.swift          🆕
│   │
│   ├── Repositories/
│   │   ├── UserRepository.swift            🆕
│   │   ├── SquadRepository.swift
│   │   ├── SessionRepository.swift
│   │   └── RealtimeLocationRepository.swift ✅ Existe
│   │
│   └── Utilities/
│       ├── Logger.swift
│       ├── DateFormatter+Extensions.swift
│       └── FeatureFlags.swift
│
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   └── SignupView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   │
│   ├── Squads/
│   │   ├── Views/
│   │   │   ├── SquadListView.swift
│   │   │   ├── CreateSquadView.swift
│   │   │   └── SquadDetailView.swift
│   │   └── ViewModels/
│   │       └── SquadViewModel.swift
│   │
│   ├── Sessions/
│   │   ├── Views/
│   │   │   ├── SessionsListView.swift      ✅ Refonte
│   │   │   ├── CreateSessionView.swift     ✅ Refonte
│   │   │   ├── ActiveSessionDetailView.swift
│   │   │   └── SessionSummaryView.swift    🆕
│   │   ├── ViewModels/
│   │   │   └── SessionsViewModel.swift     ✅ Refonte
│   │   └── Components/
│   │       ├── SessionStatsWidget.swift
│   │       ├── SessionActiveOverlay.swift
│   │       └── SessionParticipantsOverlay.swift
│   │
│   ├── Profile/
│   │   ├── Views/
│   │   │   ├── ProfileView.swift           ✅ Refonte
│   │   │   └── ProgressionView.swift       🆕
│   │   └── ViewModels/
│   │       └── ProfileViewModel.swift      🆕
│   │
│   └── Map/
│       ├── Views/
│       │   └── EnhancedSessionMapView.swift
│       └── Components/
│           └── MapControls.swift
│
├── UI/
│   ├── DesignSystem.swift                  ✅ Existe
│   ├── Components/
│   │   ├── Buttons/
│   │   ├── Cards/
│   │   └── Badges/
│   └── Modifiers/
│       └── CustomModifiers.swift
│
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

---

## 🗺️ Roadmap d'Exécution

### Phase 1️⃣ : Audit & Nettoyage (30 min)
- [x] Lister tous les fichiers existants
- [ ] Identifier les services manquants
- [ ] Créer la structure de dossiers
- [ ] Déplacer les .md hors du source

### Phase 2️⃣ : Refonte Models (1h)
- [ ] **UserModel** : Ajouter gamification fields
- [ ] **SquadModel** : Ajouter `plannedRaces`
- [ ] **SessionModel** : Ajouter `.archived` status
- [ ] Créer `WeeklyGoal.swift`
- [ ] Créer `PlannedRace.swift`
- [ ] Créer `AudioTrigger.swift`

### Phase 3️⃣ : Services Core (2h)
- [ ] **ProgressionService** : Logique de calcul de consistance
- [ ] **UserService** : CRUD utilisateur + stats
- [ ] **SquadService** : Refonte avec plannedRaces
- [ ] **SessionService** : Logique Passage de Relais
- [ ] **AudioTriggerService** : Boilerplate
- [ ] **MusicManager** : Boilerplate

### Phase 4️⃣ : Optimisation Batterie (1h)
- [ ] Adaptive GPS tracking (LocationService)
- [ ] Détecter allure nulle → Réduire fréquence GPS
- [ ] Tests sur device réel

### Phase 5️⃣ : UI Gamification (1h)
- [ ] **ProgressionView** : Barre colorée
- [ ] **ProfileView** : Afficher consistencyRate
- [ ] **WeeklyGoalsCard** : Widget objectifs

### Phase 6️⃣ : Documentation & Tests (30 min)
- [ ] DocBlocks sur toutes les fonctions publiques
- [ ] Tests unitaires ProgressionService
- [ ] Guide de migration pour l'équipe

---

## 📊 Nouveaux Modèles de Données

### 1. UserModel (Refonte)

```swift
/// Modèle utilisateur avec gamification intégrée
///
/// Gère les informations de profil, les objectifs hebdomadaires,
/// et le système de progression/consistance.
///
/// - Important: Le rôle global a été supprimé. Les rôles sont désormais
///   définis au niveau de chaque squad (voir `SquadModel.members`).
struct UserModel: Identifiable, Codable {
    @DocumentID var id: String?
    
    // Profil de base
    var displayName: String
    var email: String
    var avatarUrl: String?              // 🆕
    var bio: String?                    // 🆕
    
    // Gamification
    var consistencyRate: Double         // 🆕 0.0 - 1.0 (0% - 100%)
    var weeklyGoals: [WeeklyGoal]       // 🆕
    var totalDistance: Double           // Cumul lifetime (mètres)
    var totalSessions: Int              // Nombre de sessions complétées
    
    // Metadata
    var createdAt: Date
    var lastSeen: Date
    var squads: [String]                // IDs des squads
    
    // Computed
    var consistencyPercentage: Int {
        Int(consistencyRate * 100)
    }
    
    var consistencyColor: Color {
        switch consistencyRate {
        case 0.75...1.0: return .green
        case 0.5..<0.75: return .yellow
        default: return .red
        }
    }
}
```

### 2. WeeklyGoal (Nouveau)

```swift
/// Objectif hebdomadaire de l'utilisateur
///
/// Utilisé pour calculer l'indice de consistance.
/// Un objectif peut être basé sur la distance ou la durée.
struct WeeklyGoal: Codable, Identifiable {
    var id: String = UUID().uuidString
    
    var weekStartDate: Date             // Lundi de la semaine
    var targetType: GoalType            // Distance ou Durée
    var targetValue: Double             // En mètres ou secondes
    var actualValue: Double             // Valeur réalisée
    var isCompleted: Bool               // true si actualValue >= targetValue
    var sessionsContributed: [String]   // IDs des sessions qui ont contribué
    
    var completionRate: Double {
        guard targetValue > 0 else { return 0 }
        return min(actualValue / targetValue, 1.0)
    }
}

enum GoalType: String, Codable {
    case distance = "DISTANCE"  // En kilomètres
    case duration = "DURATION"  // En minutes
}
```

### 3. PlannedRace (Nouveau)

```swift
/// Course planifiée avec activation automatique
///
/// Les courses planifiées s'activent automatiquement à H-1.
/// Gérées via Cloud Functions Firebase.
struct PlannedRace: Codable, Identifiable {
    var id: String = UUID().uuidString
    
    var name: String                    // Ex: "Marathon de Paris 2025"
    var scheduledDate: Date             // Date et heure de départ
    var location: String                // Lieu de la course
    var distance: Double?               // Distance en mètres (optionnel)
    var squadId: String                 // Squad concernée
    
    var bibNumber: String?              // 🆕 Numéro de dossard
    var officialTrackingUrl: String?    // 🆕 Lien tracking officiel
    
    var isActivated: Bool               // true si session créée (à H-1)
    var activatedSessionId: String?     // ID de la session créée
    
    var createdBy: String               // userId du créateur
    var createdAt: Date
}
```

### 4. SessionStatus (Mise à jour)

```swift
enum SessionStatus: String, Codable {
    case active = "ACTIVE"
    case paused = "PAUSED"
    case ended = "ENDED"
    case archived = "ARCHIVED"      // 🆕 Pour anciennes sessions
}
```

### 5. AudioTrigger (Nouveau)

```swift
/// Trigger audio pour messages vocaux contextuels
///
/// Permet aux supporters d'enregistrer des messages
/// déclenchés selon des conditions GPS ou d'allure.
struct AudioTrigger: Codable, Identifiable {
    var id: String = UUID().uuidString
    
    var audioUrl: String                // Firebase Storage URL
    var fromUserId: String              // Qui a enregistré
    var fromUserName: String            // Nom affiché
    
    var triggerType: TriggerType
    var triggerValue: Double            // KM ou allure (min/km)
    
    var sessionId: String?              // Si spécifique à une session
    var squadId: String?                // Ou global à la squad
    
    var hasBeenTriggered: Bool          // Éviter de rejouer
    var triggeredAt: Date?
    
    var createdAt: Date
}

enum TriggerType: String, Codable {
    case distanceKm = "DISTANCE_KM"     // Ex: Au 30ème km
    case pace = "PACE"                  // Ex: Si allure < 5:00/km
    case heartRate = "HEART_RATE"       // Ex: Si BPM > 180
}
```

### 6. MusicPlaylist (Nouveau)

```swift
/// Playlist musicale adaptative selon l'allure
///
/// Boilerplate pour Phase 4 (Intégration Spotify/Apple Music)
struct MusicPlaylist: Codable, Identifiable {
    var id: String = UUID().uuidString
    
    var name: String                    // Ex: "Playlist Ultime"
    var spotifyUrl: String?
    var appleMusicUrl: String?
    
    var triggerPace: Double?            // Allure cible (min/km)
    var triggerDistance: Double?        // Ex: 2 derniers km
    
    var isActive: Bool
    var createdBy: String
}
```

---

## 🔧 Services Clés

### ProgressionService

```swift
/// Service de gestion de la progression et gamification
///
/// Calcule l'indice de consistance, gère les objectifs hebdomadaires,
/// et fournit les données pour les badges/achievements.
@MainActor
final class ProgressionService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ProgressionService()
    
    // MARK: - Published State
    @Published private(set) var consistencyRate: Double = 0.0
    @Published private(set) var currentWeekGoals: [WeeklyGoal] = []
    
    // MARK: - Dependencies
    private let userService: UserService
    private let sessionService: SessionService
    
    // MARK: - Public API
    
    /// Calcule l'indice de consistance pour un utilisateur
    ///
    /// Formule : `consistencyRate = objectifsRéalisés / objectifsTentés`
    ///
    /// - Parameter userId: ID de l'utilisateur
    /// - Returns: Taux de consistance entre 0.0 et 1.0
    func calculateConsistencyRate(for userId: String) async throws -> Double
    
    /// Met à jour les objectifs hebdomadaires
    ///
    /// Appelé après chaque session terminée pour incrémenter
    /// les valeurs `actualValue` des objectifs en cours.
    ///
    /// - Parameters:
    ///   - userId: ID de l'utilisateur
    ///   - session: Session terminée
    func updateWeeklyGoals(for userId: String, with session: SessionModel) async throws
    
    /// Crée un nouvel objectif hebdomadaire
    ///
    /// - Parameters:
    ///   - userId: ID de l'utilisateur
    ///   - type: Distance ou Durée
    ///   - value: Valeur cible
    func createWeeklyGoal(for userId: String, type: GoalType, value: Double) async throws
    
    /// Récupère la couleur de la barre de progression
    ///
    /// - Vert : > 75%
    /// - Jaune : 50-75%
    /// - Rouge : < 50%
    ///
    /// - Parameter rate: Taux de consistance
    /// - Returns: Couleur SwiftUI
    func getProgressionColor(for rate: Double) -> Color
}
```

### SessionService (Logique Passage de Relais)

```swift
/// Service de gestion des sessions avec logique avancée
///
/// Gère le cycle de vie des sessions, incluant la logique
/// de "Passage de Relais" pour les courses.
@MainActor
final class SessionService: ObservableObject {
    
    // ...
    
    /// Termine une session ou transfère les droits admin
    ///
    /// **Logique de Passage de Relais :**
    /// - Si le créateur quitte mais des runners sont actifs → Transfert admin
    /// - Si tous les runners sont inactifs → Terminer la session
    /// - Si session de type `.race` → Garder active tant qu'un runner bouge
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui quitte
    func leaveOrTransferSession(sessionId: String, userId: String) async throws
    
    /// Détecte les runners actifs (en mouvement)
    ///
    /// Un runner est actif si :
    /// - Dernière position < 5 minutes
    /// - Vitesse > 0.5 m/s (~ 1.8 km/h)
    ///
    /// - Parameter sessionId: ID de la session
    /// - Returns: Liste des userIds actifs
    func getActiveRunners(sessionId: String) async throws -> [String]
    
    /// Archive les sessions anciennes (> 30 jours)
    ///
    /// Appelé par Cloud Function ou batch job.
    func archiveOldSessions() async throws
}
```

---

## ⚡ Optimisation Batterie

### Stratégie GPS Adaptatif

```swift
/// Service de localisation avec optimisation batterie
///
/// Ajuste la fréquence de mise à jour GPS selon l'allure du coureur.
final class LocationService: NSObject, ObservableObject {
    
    // MARK: - Configuration
    
    /// Fréquence de mise à jour selon l'état du coureur
    enum UpdateFrequency {
        case stopped        // Allure nulle → 30 secondes
        case slow           // < 6 min/km → 10 secondes
        case normal         // 4-6 min/km → 5 secondes
        case fast           // > 4 min/km → 3 secondes
    }
    
    /// Ajuste la fréquence GPS selon l'allure actuelle
    ///
    /// **Économie batterie :**
    /// - Si allure = 0 pendant 2 minutes → Mode `stopped`
    /// - Si course lente → Réduit fréquence
    /// - Si sprint → Maximise précision
    ///
    /// - Parameter speed: Vitesse en m/s
    private func adjustUpdateFrequency(for speed: Double)
}
```

---

## 📝 Checklist de Validation

### Code Quality
- [ ] Tous les fichiers < 200 lignes
- [ ] DocBlocks (///) sur toutes les fonctions publiques
- [ ] Pas de code mort
- [ ] Aucun fichier .md dans le source

### Architecture
- [ ] Services isolés (Firebase, HealthKit, Location)
- [ ] Repositories pour l'accès données
- [ ] ViewModels < 250 lignes
- [ ] Combine pour rafraîchissement UI

### Data Models
- [ ] UserModel avec gamification ✅
- [ ] SquadModel avec plannedRaces ✅
- [ ] SessionModel avec .archived ✅
- [ ] WeeklyGoal ✅
- [ ] PlannedRace ✅
- [ ] AudioTrigger ✅

### Services
- [ ] ProgressionService fonctionnel
- [ ] SessionService avec Passage de Relais
- [ ] LocationService avec GPS adaptatif
- [ ] AudioTriggerService (boilerplate)
- [ ] MusicManager (boilerplate)

### UI
- [ ] ProgressionView avec barre colorée
- [ ] ProfileView avec consistencyRate
- [ ] Tous les widgets < 150 lignes

### Tests
- [ ] Tests unitaires ProgressionService
- [ ] Tests SessionService (Relais)
- [ ] Tests LocationService (GPS adaptatif)

---

## 🚀 Prochaines Étapes

1. **Maintenant** : Créer la structure de dossiers
2. **Phase 2** : Refonte des Models
3. **Phase 3** : Implémentation des Services
4. **Phase 4** : Migration du code existant
5. **Phase 5** : Tests et validation

---

**Début d'exécution :** 30 décembre 2024, 14:00  
**Temps estimé :** 5-6 heures (avec breaks)
