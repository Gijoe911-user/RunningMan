# 🗺️ Cartographie Architecture RunningMan

**Date:** 2026-01-09  
**Status:** ✅ Code actif | ⚠️ Code obsolète | 🔧 Code à moderniser

---

## 📱 Flux d'Authentification

### ✅ Code Actif

```
AuthenticationView.swift (195 lignes)
├─ Écran login/signup
├─ Email/Password Firebase Auth
└─ Crée le profil utilisateur au signup

↓ [Auth Success]

AppState.isAuthenticated = true
↓
MainTabView.swift
```

### ⚠️ Code Obsolète

- **LoginView.swift** (175 lignes) → Template Firebase exemple, pas utilisé dans l'app

---

## 🏠 Navigation Principale (MainTabView)

### Structure

```swift
TabView {
    Tab 0: DashboardView         // Accueil
    Tab 1: SquadListView          // Mes squads
    Tab 2: AllSessionsViewUnified // Toutes les sessions
    Tab 3: ProfileView            // Profil/Paramètres
}
```

### Détails des Onglets

#### Tab 0 - Dashboard
```
DashboardView
├─ Résumé stats utilisateur
├─ Sessions actives (shortcuts)
└─ Activités récentes
```

#### Tab 1 - Squads
```
SquadListView
├─ Liste des squads de l'utilisateur
└─ [Tap squad] → SquadDetailView
    ├─ Info squad
    ├─ Membres
    ├─ Code d'invitation
    ├─ [Bouton "Voir les sessions"] → SquadSessionsListView
    │   ├─ Segmented Control: Actives | Historique
    │   ├─ [Tap session active] → SessionTrackingView (MODE IMMERSIF)
    │   └─ [Tap session historique] → SessionHistoryDetailView (3D)
    └─ [Bouton "Démarrer une session"] → CreateSessionView
        └─ [Création] → SessionDetailView (avec carte EnhancedSessionMapView)
```

#### Tab 2 - Sessions
```
AllSessionsViewUnified (SessionTrackingViewModel)
├─ Sessions actives de tous mes squads
├─ Historique récent
└─ [Tap session] → SessionDetailView ou SessionTrackingView
```

#### Tab 3 - Profil
```
ProfileView
├─ Infos utilisateur
├─ Stats globales
└─ [Bouton Paramètres] → SettingsView
```

---

## 🗺️ Système de Cartes (3 Types)

### 1. 🎯 EnhancedSessionMapView (Carte avec Contrôles)

**Fichier:** `EnhancedSessionMapView.swift` (581 lignes)  
**Status:** ✅ **ACTIVE - Utilisée dans SessionDetailView**

**Caractéristiques:**
- Affiche position utilisateur + autres coureurs
- Tracé du parcours (votre route + routes des autres)
- Boutons de contrôle en overlay:
  - Recentrer sur soi
  - Toggle 2D/3D
  - Sauvegarder le tracé
  - Toggle afficher tous les coureurs
- Annotations interactives (tap sur coureur)

**Utilisée dans:**
- `SessionDetailView` (vue détail depuis "Voir les sessions")
- `CreateSessionView` (après création de session)

**Code clé:**
```swift
EnhancedSessionMapView(
    userLocation: userLocation,
    runnerLocations: runnerLocations,
    routeCoordinates: userRouteCoordinates,
    runnerRoutes: runnerRoutes,  // Routes des autres participants
    onRecenter: { ... },
    onSaveRoute: { ... },
    onRunnerTapped: { runnerId in ... }
)
```

---

### 2. 🏃 TrackingMapView (Carte Immersive)

**Fichier:** `SessionTrackingView.swift` (674 lignes) - contient TrackingMapView inline  
**Status:** ✅ **ACTIVE - Vue immersive depuis onglet "Sessions Actives"**

**Caractéristiques:**
- **Carte plein écran** (ZStack avec overlay)
- Badge de statut flottant (haut droite)
- Stats flottantes (haut, sous badge)
- Boutons de contrôle en bas (Play/Pause/Stop)
- Mode Spectateur vs Mode Coureur
- Très belle UI immersive

**Utilisée dans:**
- `SquadSessionsListView` → Tap sur session active → **SessionTrackingView**

**Code clé:**
```swift
// Dans SessionTrackingView
ZStack {
    // Carte plein écran
    TrackingMapView(
        userLocation: trackingManager.routeCoordinates.last,
        routeCoordinates: trackingManager.routeCoordinates
    )
    
    // Badge statut (overlay)
    stateIndicator.padding(.top, 60).padding(.trailing, 20)
    
    // Stats flottantes
    statsOverlay.padding(.top, 110)
    
    // Boutons contrôle (bas)
    trackingControlButtons
}
```

---

### 3. 🌍 Map3DView (Vue 3D Historique)

**Fichier:** `SessionHistoryDetailView.swift` (593 lignes) - contient Map3DView inline  
**Status:** ✅ **ACTIVE - Visualisation 3D dans l'historique**

**Caractéristiques:**
- **Rendu 3D du parcours avec élévation**
- Rotation automatique ou manuelle
- Affiche le tracé avec relief terrain
- Stats de la session terminée

**Utilisée dans:**
- `SquadSessionsListView` → Tap sur session historique → **SessionHistoryDetailView**

**Code clé:**
```swift
// Vue 3D avec MapKit elevation
Map3D(
    route: session.routeCoordinates,
    style: .realistic // ou .satellite
)
.rotation3DEffect(...)
```

---

## 🎛️ Flux de Tracking GPS

### Démarrage Tracking

**Cas 1: Depuis "Démarrer une session" (SquadDetailView)**
```
SquadDetailView
└─ [Bouton "Démarrer une session"]
    └─ CreateSessionView
        ├─ Crée session avec status = .scheduled
        └─ [Navigation] → SessionDetailView
            ├─ Affiche EnhancedSessionMapView (avec contrôles)
            ├─ Mode SPECTATEUR par défaut
            └─ [Bouton "Démarrer l'activité"] → startTracking()
                ├─ TrackingManager.startTracking(for: session)
                ├─ Session passe à .active
                └─ GPS activé
```

**Cas 2: Depuis "Sessions Actives" (SquadSessionsListView)**
```
SquadSessionsListView (onglet Actives)
└─ [Tap sur session]
    └─ SessionTrackingView (MODE IMMERSIF)
        ├─ Carte plein écran TrackingMapView
        ├─ Charge tracé existant (mode spectateur)
        └─ [Bouton "Démarrer mon activité"] → startTracking()
            ├─ TrackingManager.startTracking(for: session)
            └─ GPS activé pour cet utilisateur
```

---

## 🔄 Services & Managers

### Services Actifs

| Service | Fichier | Rôle | Status |
|---------|---------|------|--------|
| **SessionService** | SessionService.swift (1400+ lignes) | CRUD sessions, queries Firestore | ✅ ACTIF |
| **TrackingManager** | TrackingManager.swift (817 lignes) | Tracking GPS, état local | ✅ ACTIF |
| **RouteTrackingService** | RouteTrackingService.swift (304 lignes) | Sauvegarde points GPS dans Firestore | ✅ ACTIF |
| **RealtimeLocationService** | RealtimeLocationService.swift (154 lignes) | Sync positions temps réel | ✅ ACTIF |
| **RouteHistoryService** | RouteHistoryService.swift | Chargement historique routes | ✅ ACTIF |
| **AuthService** | AuthService.swift (259 lignes) | Auth Firebase, profil utilisateur | ✅ ACTIF |
| **SquadService** | SquadService.swift | CRUD squads | ✅ ACTIF |
| **HealthKitManager** | HealthKitManager.swift | Récup BPM, calories | ✅ ACTIF |

### ViewModels Actifs

| ViewModel | Fichier | Rôle | Status |
|-----------|---------|------|--------|
| **SessionTrackingViewModel** | SessionTrackingViewModel.swift (156 lignes) | Gestion sessions actives multi-squads | ✅ ACTIF |
| **AuthViewModel** | AuthViewModel.swift (435 lignes) | État auth, login/logout | ✅ ACTIF |
| **SquadViewModel** | SquadViewModel.swift | Liste squads utilisateur | ✅ ACTIF |
| **AppState** | AppState.swift | État global app (tab sélectionné, auth) | ✅ ACTIF |

---

## 📊 Statuts de Session

### Enum SessionStatus

```swift
enum SessionStatus: String {
    case scheduled  // Créée, GPS éteint, en attente
    case active     // GPS actif, au moins 1 participant tracke
    case paused     // Pause globale (optionnel, peu utilisé)
    case ended      // Terminée
}
```

### Transitions

```
scheduled → active   // Premier participant démarre son GPS
active → ended       // Dernier participant termine OU créateur termine OU timeout 4h
```

### Statuts Participants (ParticipantStatus)

```swift
enum ParticipantStatus: String {
    case waiting    // Spectateur, GPS éteint
    case active     // Coureur, GPS actif
    case paused     // Coureur en pause (optionnel)
    case ended      // A terminé sa course
    case abandoned  // A abandonné
}
```

---

## 🗂️ Structure Firestore

### Collection `sessions`

```
sessions/{sessionId}
├─ squadId: String
├─ creatorId: String
├─ status: String (scheduled, active, ended)
├─ startedAt: Timestamp
├─ participants: [String] (userIds)
├─ participantStates: { userId: ParticipantSessionState }
├─ participantActivity: { userId: ParticipantActivity }
└─ participantStats/ (subcollection)
    └─ {userId}
        ├─ distance: Double
        ├─ duration: Double
        ├─ averageSpeed: Double
        ├─ currentHeartRate: Double?
        └─ calories: Double?
```

### Collection `routeHistory`

```
routeHistory/{sessionId}/participants/{userId}/points/{pointId}
├─ latitude: Double
├─ longitude: Double
├─ timestamp: Timestamp
├─ altitude: Double?
└─ speed: Double?
```

---

## 🎨 Différences Cartes Résumées

| Caractéristique | EnhancedSessionMapView | TrackingMapView | Map3DView |
|----------------|------------------------|-----------------|-----------|
| **Usage** | Vue détail session | Vue immersive tracking | Historique 3D |
| **Fullscreen** | ❌ (frame: 420) | ✅ Plein écran | ✅ Plein écran |
| **Contrôles visibles** | ✅ Boutons overlay | ✅ Boutons bas | ❌ Rotation auto |
| **Mode 3D** | ✅ Toggle 2D/3D | ❌ 2D only | ✅ 3D only |
| **Autres coureurs** | ✅ Annotations | ❌ Soi uniquement | ❌ Route seule |
| **Stats overlay** | ❌ | ✅ | ✅ |
| **Élévation terrain** | ❌ | ❌ | ✅ |

---

## 🔧 Code à Moderniser

### Fichiers Obsolètes Identifiés

1. **LoginView.swift** (175 lignes)
   - Template Firebase exemple
   - **Action:** Supprimer, AuthenticationView le remplace

2. **TEMPLATE_SessionTrackingView.swift** (267 lignes)
   - Template exemple
   - **Action:** Supprimer si non utilisé

3. **ExampleUsageView.swift** (494 lignes)
   - Fichier d'exemple
   - **Action:** Supprimer après validation

### Fonctions Non Utilisées dans SessionService

**À vérifier (nécessite logs runtime) :**
- `getActiveRaceSession()` - Semble spécifique type Race, pas sûr si utilisé
- `getUserActiveSession()` - Possiblement remplacé par `getAllActiveSessions()`
- `pauseSession()` / `resumeSession()` - Pause globale session, peu utilisé
- `updateSpectatorActivity()` - Heartbeat spectateur, à valider
- `checkInactiveParticipants()` - Détection timeout, probablement pas appelé côté client

### Fichiers de Maintenance Nouveaux (Ajoutés récemment)

```
SessionService.swift (nouvelles fonctions)
├─ cleanupCorruptedSessions()       // ✅ Badge rouge dans SquadSessionsListView
├─ detectZombieSessions()           // ✅ Utilisé pour afficher badge
├─ diagnoseSession()                // 🔧 Debug tool
└─ startMyTracking() / stopMyTracking()  // ✅ CRITIQUES, utilisées par TrackingManager
```

---

## 🧩 Dépendances Critiques

### TrackingManager ← Services

```
TrackingManager
├─ SessionService.startMyTracking()        // Démarre tracking Firestore
├─ RouteTrackingService.saveRoutePoint()   // Sauvegarde points GPS
├─ RealtimeLocationService                  // Sync positions live
├─ HealthKitManager                         // BPM, calories
└─ LocationProvider                         // CoreLocation
```

### Vues ← ViewModels

```
SessionTrackingView
└─ SessionTrackingViewModel
    ├─ TrackingManager (state)
    └─ SessionService (queries)

SquadSessionsListView
└─ SessionService
    ├─ getActiveSessions()
    ├─ detectZombieSessions()
    └─ cleanupCorruptedSessions()

SessionDetailView
└─ SessionService
    ├─ getSession()
    ├─ endSession()
    └─ updateSessionFields()
```

---

## ✅ Actions Recommandées

### Immédiat

1. ✅ **Supprimer LoginView.swift** (obsolète)
2. ✅ **Supprimer TEMPLATE_SessionTrackingView.swift** (template)
3. ✅ **Supprimer ExampleUsageView.swift** (exemple)

### Validation Runtime Nécessaire

Pour identifier le code mort, ajoutez ces logs temporaires :

```swift
// Dans SessionService.swift

func pauseSession(sessionId: String) async throws {
    Logger.log("[USAGE-AUDIT] pauseSession appelé", category: .audit) // 🔍 LOG
    // ...
}

func getActiveRaceSession(squadId: String) async throws -> SessionModel? {
    Logger.log("[USAGE-AUDIT] getActiveRaceSession appelé", category: .audit) // 🔍 LOG
    // ...
}
```

Naviguer dans l'app pendant 1 session complète, puis chercher `[USAGE-AUDIT]` dans les logs.

### Documentation à Créer

1. **FLOW_DIAGRAMS.md** - Diagrammes de flux utilisateur
2. **API_REFERENCE.md** - Doc des services publics
3. **STATE_MANAGEMENT.md** - Explication AppState, ViewModels

---

## 📈 Métriques Codebase

| Catégorie | Fichiers | Lignes Estimées | Status |
|-----------|----------|-----------------|--------|
| **Vues** | ~30 | ~8000 | ✅ Actif |
| **Services** | 10 | ~3000 | ✅ Actif |
| **ViewModels** | 5 | ~1200 | ✅ Actif |
| **Models** | 8 | ~1500 | ✅ Actif |
| **Obsolète** | 3 | ~900 | ⚠️ À supprimer |

**Total Code Actif:** ~13,700 lignes  
**Total Obsolète:** ~900 lignes (6.5%)

---

## 🎯 Conclusion

### Points Forts

- ✅ Architecture claire avec séparation Services/ViewModels/Vues
- ✅ 3 types de cartes adaptées aux cas d'usage
- ✅ Système de tracking robuste avec TrackingManager
- ✅ Maintenance automatique (nettoyage zombies)

### Points d'Amélioration

- 🔧 Supprimer templates obsolètes
- 🔧 Valider utilisation de toutes les fonctions service
- 🔧 Documenter les flows complexes (démarrage tracking, etc.)
- 🔧 Ajouter tests unitaires pour fonctions critiques

---

**Prochaine étape:** Naviguer dans l'app avec logs `[USAGE-AUDIT]` pour identifier le code mort restant.
