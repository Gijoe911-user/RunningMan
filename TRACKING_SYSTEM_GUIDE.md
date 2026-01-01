# 🏃 Système de Tracking GPS Multi-Sessions

## 📋 Vue d'ensemble

Ce système permet de :
- ✅ **Tracker UNE session active** avec GPS, sauvegarde automatique et HealthKit
- ✅ **Supporter plusieurs autres sessions** sans tracking GPS
- ✅ **Sauvegarder automatiquement** toutes les 3 minutes (récupération après crash/batterie)
- ✅ **Contrôler le tracking** avec Play / Pause / Stop
- ✅ **Gérer les cas de perte de batterie** avec sauvegarde incrémentale

---

## 🏗️ Architecture

### Composants principaux

#### 1. **TrackingManager** (Singleton)
**Rôle** : Gère le tracking GPS d'UNE session active à la fois

**Responsabilités** :
- Démarre/pause/reprend/arrête le tracking
- Collecte les points GPS en temps réel
- Calcule distance, durée, vitesse
- Sauvegarde automatique toutes les 3 minutes
- Intégration HealthKit (BPM, calories, workout)

**État** :
```swift
enum TrackingState {
    case idle       // Pas de tracking
    case active     // En cours
    case paused     // En pause
    case stopping   // Arrêt en cours
}
```

**Propriétés publiées** :
```swift
@Published var activeTrackingSession: SessionModel?
@Published var trackingState: TrackingState
@Published var currentDistance: Double
@Published var currentDuration: TimeInterval
@Published var currentSpeed: Double
@Published var routeCoordinates: [CLLocationCoordinate2D]
```

---

#### 2. **SessionTrackingViewModel**
**Rôle** : Orchestre les sessions (tracking + supporter)

**Responsabilités** :
- Sépare la session de tracking des sessions de support
- Charge toutes les sessions actives des squads
- Gère les actions (join, leave, create)
- Formate les données pour l'UI

**Propriétés clés** :
```swift
@Published var myActiveTrackingSession: SessionModel?  // Session trackée
@Published var supporterSessions: [SessionModel]      // Sessions supportées
@Published var allActiveSessions: [SessionModel]      // Toutes les sessions
```

---

#### 3. **RouteTrackingService**
**Rôle** : Gère la sauvegarde des tracés GPS

**Sauvegarde automatique** :
- ⏱️ **Toutes les 3 minutes** (180 secondes)
- 📍 Sauvegarde dans Firestore : `routes/{sessionId}_{userId}`
- 🛡️ Récupération après crash/batterie

**Méthodes principales** :
```swift
func startAutoSave(sessionId: String, userId: String)
func stopAutoSave()
func saveRoute(sessionId: String, userId: String) async throws
func loadRoute(sessionId: String, userId: String) async throws
```

---

## 🎮 Contrôles de Tracking

### SessionTrackingControlsView

**Boutons dynamiques** :

| État     | Bouton Principal | Action          |
|----------|-----------------|-----------------|
| `idle`   | ▶️ Démarrer     | Lance le tracking |
| `active` | ⏸️ Pause        | Met en pause    |
| `paused` | ▶️ Reprendre    | Reprend         |
| `active` | 🛑 Stop         | Termine (avec confirmation) |

**Comportement** :
- ✅ Désactive les boutons pendant les actions
- ✅ Affiche un indicateur de chargement
- ✅ Confirmation avant d'arrêter
- ✅ Empêche les clics multiples

---

## 📱 Vues

### 1. **AllSessionsView**
Vue principale listant toutes les sessions

**Sections** :
```
┌─────────────────────────────────┐
│ Ma session active               │  ← Tracking en cours
│ [TrackingSessionCard]           │
├─────────────────────────────────┤
│ Sessions que je supporte        │  ← Sans tracking
│ [SupporterSessionCard] (1..n)   │
├─────────────────────────────────┤
│ Toutes les sessions actives     │  ← Disponibles
│ [SessionRowCard] (1..n)         │
└─────────────────────────────────┘
```

**Actions** :
- ➕ Créer une nouvelle session (pour n'importe quelle squad)
- 👁️ Rejoindre comme supporter
- 🏃 Démarrer mon tracking (si aucune session active)

---

### 2. **SessionTrackingView**
Vue de tracking en plein écran

**Composants** :
```
┌─────────────────────────────────┐
│ Carte (tracé GPS en temps réel) │
│ [TrackingMapView]               │
├─────────────────────────────────┤
│ Stats en temps réel             │
│ Distance | Durée | Allure       │
├─────────────────────────────────┤
│ Contrôles                       │
│ [SessionTrackingControlsView]   │
└─────────────────────────────────┘
```

---

### 3. **ActiveSessionDetailView**
Vue pour les sessions en mode supporter (sans tracking)

**Fonctionnalités** :
- 🗺️ Voir la carte avec les coureurs en temps réel
- 📊 Voir les stats de la session
- 👥 Voir la liste des participants

---

## 🔄 Flux de Données

### 1. Démarrage du Tracking

```
Utilisateur appuie sur "Démarrer"
    ↓
SessionTrackingViewModel.startTracking(for: session)
    ↓
TrackingManager.startTracking(for: session)
    ↓
┌─────────────────────────────────────────────────────┐
│ 1. LocationProvider.startUpdating()                 │
│ 2. HealthKitManager.startHeartRateQuery()           │
│ 3. HealthKitManager.startWorkout()                  │
│ 4. RouteTrackingService.startAutoSave() (3 min)    │
│ 5. Démarre le timer de durée                       │
│ 6. Observe les points GPS                          │
└─────────────────────────────────────────────────────┘
    ↓
Mise à jour en temps réel des propriétés @Published
```

---

### 2. Sauvegarde Automatique (toutes les 3 minutes)

```
Timer déclenche toutes les 180 secondes
    ↓
TrackingManager.saveCurrentState()
    ↓
┌─────────────────────────────────────────────────────┐
│ 1. RouteTrackingService.saveRoute()                 │
│    → Firestore: routes/{sessionId}_{userId}         │
│                                                      │
│ 2. SessionService.updateParticipantStats()          │
│    → Firestore: sessions/{id}/participantStats/...  │
│                                                      │
│ 3. SessionService.updateSessionStats()              │
│    → Firestore: sessions/{id}                       │
└─────────────────────────────────────────────────────┘
```

**🛡️ Récupération après crash** :
- Les données sont sauvegardées toutes les 3 minutes
- En cas de crash ou batterie vide, les données des 3 dernières minutes max sont perdues
- Au redémarrage, la session peut être reprise avec les données sauvegardées

---

### 3. Arrêt du Tracking

```
Utilisateur appuie sur "Stop" (avec confirmation)
    ↓
TrackingManager.stopTracking()
    ↓
┌─────────────────────────────────────────────────────┐
│ 1. Arrête tous les timers                           │
│ 2. Arrête LocationProvider                          │
│ 3. Arrête HealthKit                                 │
│ 4. Sauvegarde finale                                │
│ 5. Attente 2 secondes (flush Firestore)            │
│ 6. SessionService.endSession()                      │
│ 7. Nettoie l'état                                   │
└─────────────────────────────────────────────────────┘
```

---

## 🔒 Contraintes Respectées

### ✅ Une seule session de tracking active

**Implémentation** :
```swift
// TrackingManager
var canStartTracking: Bool {
    trackingState == .idle
}

// Vérification avant démarrage
guard canStartTracking else {
    errorMessage = "Un tracking est déjà en cours"
    return false
}
```

**Effet** :
- L'utilisateur ne peut tracker qu'UNE session à la fois
- Les boutons "Démarrer tracking" sont désactivés si déjà actif
- Les autres sessions peuvent être rejointes en mode supporter

---

### ✅ Supporter plusieurs sessions sans tracking

**Implémentation** :
```swift
// SessionTrackingViewModel sépare :
var myActiveTrackingSession: SessionModel?  // 1 seule
var supporterSessions: [SessionModel]       // 0 à n
```

**Comportement** :
- Je peux être dans plusieurs sessions simultanément
- Mais je ne track GPS que pour UNE seule
- Les autres : je vois la carte + les coureurs en temps réel

---

### ✅ Sauvegarde automatique toutes les 3 minutes

**Implémentation** :
```swift
// RouteTrackingService
private let autoSaveInterval: TimeInterval = 180  // 3 minutes

autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 180.0, repeats: true) { ... }
```

**Protection** :
- 🔋 Batterie faible → données sauvegardées régulièrement
- 💥 Crash app → perte maximale de 3 minutes de données
- 🌐 Perte réseau → retry automatique (fire-and-forget)

---

## 🧪 Intégration avec l'App

### 1. Ajouter AllSessionsView dans votre TabView

```swift
TabView {
    // Vos autres vues...
    
    AllSessionsView()
        .tabItem {
            Label("Sessions", systemImage: "figure.run")
        }
}
.environment(squadViewModel)
```

---

### 2. Lancer une session depuis CreateSessionView

Modifier `CreateSessionView` pour utiliser le tracking :

```swift
Button {
    createSessionWithTracking()
} label: {
    Text("Créer et démarrer le tracking")
}

func createSessionWithTracking() {
    Task {
        // 1. Créer la session
        let session = try await SessionService.shared.createSession(...)
        
        // 2. Démarrer le tracking
        let trackingVM = SessionTrackingViewModel()
        await trackingVM.startTracking(for: session)
        
        // 3. Naviguer vers SessionTrackingView
        // (ou fermer et laisser AllSessionsView afficher)
    }
}
```

---

### 3. Ajouter un bouton dans SquadDetailView

```swift
Button {
    // Créer et tracker une session pour cette squad
    showCreateSession = true
} label: {
    Label("Démarrer une session", systemImage: "play.circle.fill")
}
.sheet(isPresented: $showCreateSession) {
    QuickCreateSessionView(squad: squad) { session in
        // Session créée, démarrer le tracking
        let trackingVM = SessionTrackingViewModel()
        await trackingVM.startTracking(for: session)
    }
}
```

---

## 📊 Structure Firestore

### Collections créées/mises à jour

#### 1. **sessions/{sessionId}**
```json
{
  "squadId": "squad_123",
  "creatorId": "user_456",
  "status": "ACTIVE",
  "participants": ["user_456", "user_789"],
  "totalDistanceMeters": 5230.5,
  "durationSeconds": 1834,
  "averageSpeed": 2.85,
  "startedAt": Timestamp,
  "updatedAt": Timestamp
}
```

#### 2. **sessions/{sessionId}/participantStats/{userId}**
```json
{
  "userId": "user_456",
  "distance": 5230.5,
  "duration": 1834,
  "averageSpeed": 2.85,
  "maxSpeed": 4.2,
  "currentHeartRate": 145,
  "averageHeartRate": 138,
  "calories": 320,
  "updatedAt": Timestamp
}
```

#### 3. **routes/{sessionId}_{userId}**
```json
{
  "sessionId": "session_123",
  "userId": "user_456",
  "points": [
    GeoPoint(48.8566, 2.3522),
    GeoPoint(48.8567, 2.3523),
    ...
  ],
  "pointsCount": 523,
  "createdAt": Timestamp
}
```

---

## 🎯 Exemple d'Utilisation

### Scénario : Marathon Training Squad

**Squad "Marathon Paris 2024"** avec 5 membres :
- Alice (créatrice)
- Bob
- Charlie
- Diana
- Eve

---

**Lundi 10h00 - Alice lance une session** :
```swift
1. Alice ouvre AllSessionsView
2. Appuie sur ➕ → Sélectionne "Marathon Paris 2024"
3. QuickCreateSessionView s'ouvre
4. Appuie sur "Créer et démarrer le tracking"
5. SessionTrackingView s'affiche
6. Tracking GPS démarre automatiquement
```

**État** :
- Alice : `myActiveTrackingSession` = Session A (tracking actif)
- Bob, Charlie, Diana, Eve : voient la session A dans "Sessions disponibles"

---

**Lundi 10h05 - Bob et Charlie rejoignent** :
```swift
1. Bob et Charlie voient la session A
2. Appuient sur "⋯" → "Rejoindre comme supporter"
3. ActiveSessionDetailView s'affiche
4. Ils voient Alice courir sur la carte en temps réel
```

**État** :
- Alice : tracking GPS actif
- Bob, Charlie : supporters (pas de tracking)
- Diana, Eve : pas encore rejoints

---

**Lundi 10h10 - Diana veut courir aussi** :
```swift
1. Diana ouvre AllSessionsView
2. Voit la session A
3. Appuie sur "⋯" → "Démarrer mon tracking"
4. Tracking GPS démarre pour Diana
5. Diana et Alice se voient maintenant mutuellement sur la carte
```

**État** :
- Alice : `myActiveTrackingSession` = Session A (tracking actif)
- Diana : `myActiveTrackingSession` = Session A (tracking actif)
- Bob, Charlie : supporters
- Eve : pas rejointe

---

**Lundi 10h15 - Eve lance SA propre session** :
```swift
1. Eve ouvre AllSessionsView
2. Crée une nouvelle session pour "Marathon Paris 2024"
3. Démarre son tracking GPS
4. Court seule (personne n'a rejoint)
```

**État** :
- Alice : tracking Session A
- Diana : tracking Session A
- Bob, Charlie : supporters Session A
- Eve : tracking Session B (différente)

---

**Lundi 10h30 - Alice met en pause** :
```swift
1. Alice appuie sur "⏸️ Pause" dans SessionTrackingView
2. GPS s'arrête (économie batterie)
3. Les sauvegardes automatiques s'arrêtent
4. Les autres continuent de voir sa dernière position
5. Après 5 min de pause, elle appuie sur "▶️ Reprendre"
6. GPS redémarre, sauvegarde reprend
```

---

**Lundi 11h00 - Alice termine** :
```swift
1. Alice appuie sur "🛑 Stop"
2. Confirmation : "Terminer la session ?"
3. Valide
4. Sauvegarde finale
5. Session marquée "ENDED" dans Firestore
6. Bob et Charlie reçoivent la notification de fin
7. AllSessionsView affiche "Session terminée"
```

---

## 🚨 Gestion des Erreurs

### Perte de batterie pendant le tracking

**Scénario** :
```
10h00 : Tracking démarre
10h03 : Sauvegarde automatique #1 (520m parcourus)
10h06 : Sauvegarde automatique #2 (1.2km parcourus)
10h08 : 💀 Batterie vide, téléphone s'éteint
```

**Récupération** :
```
11h00 : Téléphone rallumé
11h05 : App redémarre, utilisateur se reconnecte
```

**Données récupérées** :
- ✅ Distance : 1.2 km (dernière sauvegarde à 10h06)
- ✅ Tracé GPS : 520 points (dernière sauvegarde)
- ❌ Perte : ~2 minutes de données (entre 10h06 et 10h08)

**Action manuelle** :
```swift
1. L'utilisateur voit la session toujours "ACTIVE" dans Firestore
2. Peut :
   - Reprendre le tracking (continuer)
   - Terminer manuellement (sauvegarder ce qui existe)
```

---

### Crash de l'app

**Même principe que la perte de batterie** :
- Données sauvegardées toutes les 3 minutes
- Perte maximale : 3 minutes
- Session reste "ACTIVE" dans Firestore
- Peut être reprise ou terminée manuellement

---

### Perte de réseau

**Comportement** :
```swift
// SessionService utilise fire-and-forget
Task.detached {
    try? await sessionRef.updateData(...)
}
```

**Effet** :
- ✅ L'app ne bloque pas
- ✅ Les données sont bufferisées localement
- ✅ Firestore re-essaie automatiquement
- ⚠️ Pas de garantie immédiate de sauvegarde

**Recommandation** :
- Ajouter une vérification de connectivité
- Afficher un warning si hors ligne
- Sauvegarder localement en JSON en backup

---

## 🎨 Personnalisation

### Changer la fréquence de sauvegarde

**Fichier** : `TrackingManager.swift`

```swift
// Ligne 20
private let autoSaveInterval: TimeInterval = 180  // 3 minutes

// Modifier selon vos besoins :
// 60   = 1 minute (sauvegarde fréquente, plus de requêtes)
// 180  = 3 minutes (recommandé)
// 300  = 5 minutes (moins de requêtes, plus de perte)
```

---

### Ajouter des alertes de batterie faible

**Fichier** : `TrackingManager.swift`

```swift
import UIKit

// Dans startTracking()
// Ajouter :
UIDevice.current.isBatteryMonitoringEnabled = true

// Observer
NotificationCenter.default.addObserver(
    forName: UIDevice.batteryLevelDidChangeNotification,
    object: nil,
    queue: .main
) { [weak self] _ in
    let level = UIDevice.current.batteryLevel
    
    if level < 0.1 {  // 10%
        // Forcer une sauvegarde immédiate
        Task { await self?.saveCurrentState() }
        
        // Avertir l'utilisateur
        self?.showLowBatteryWarning()
    }
}
```

---

### Ajouter un backup local (mode offline)

**Nouveau fichier** : `LocalStorageService.swift`

```swift
import Foundation

class LocalStorageService {
    static let shared = LocalStorageService()
    
    func saveSessionLocally(session: SessionModel, route: [CLLocationCoordinate2D]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(session) {
            let url = getLocalURL(for: session.id ?? "unknown")
            try? data.write(to: url)
        }
        
        // Sauvegarder le tracé
        let coords = route.map { ["lat": $0.latitude, "lon": $0.longitude] }
        if let routeData = try? JSONSerialization.data(withJSONObject: coords) {
            let routeURL = getRouteURL(for: session.id ?? "unknown")
            try? routeData.write(to: routeURL)
        }
    }
    
    private func getLocalURL(for sessionId: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("session_\(sessionId).json")
    }
    
    private func getRouteURL(for sessionId: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("route_\(sessionId).json")
    }
}
```

**Utilisation dans TrackingManager** :
```swift
private func saveCurrentState() async {
    // Sauvegarde Firestore
    ...
    
    // Sauvegarde locale en backup
    if let session = activeTrackingSession {
        LocalStorageService.shared.saveSessionLocally(
            session: session,
            route: routeCoordinates
        )
    }
}
```

---

## ✅ Checklist d'Intégration

### Étape 1 : Vérifier les permissions

- [ ] Info.plist : `NSLocationWhenInUseUsageDescription`
- [ ] Info.plist : `NSLocationAlwaysAndWhenInUseUsageDescription`
- [ ] Info.plist : `NSHealthShareUsageDescription`
- [ ] Info.plist : `NSHealthUpdateUsageDescription`

### Étape 2 : Ajouter les nouveaux fichiers

- [ ] `TrackingManager.swift`
- [ ] `SessionTrackingViewModel.swift`
- [ ] `SessionTrackingControlsView.swift`
- [ ] `SessionTrackingView.swift`
- [ ] `AllSessionsView.swift`

### Étape 3 : Mettre à jour les existants

- [ ] `RouteTrackingService.swift` (sauvegarde 3 min)
- [ ] `SessionService.swift` (si besoin de modifications)

### Étape 4 : Intégrer dans l'app

- [ ] Ajouter `AllSessionsView` dans le `TabView`
- [ ] Tester la création de session
- [ ] Tester le tracking GPS
- [ ] Tester la sauvegarde automatique
- [ ] Tester le mode supporter

### Étape 5 : Tests

- [ ] Créer une session et démarrer tracking
- [ ] Vérifier les sauvegardes dans Firestore (toutes les 3 min)
- [ ] Mettre en pause et reprendre
- [ ] Arrêter et vérifier la sauvegarde finale
- [ ] Tester avec 2 utilisateurs (1 tracking, 1 supporter)
- [ ] Tester la perte de réseau
- [ ] Tester la batterie faible (simulateur)

---

## 🎉 Résultat Final

Vous avez maintenant un système complet de tracking GPS multi-sessions avec :

✅ **Tracking GPS précis** avec sauvegarde automatique  
✅ **Contrôles intuitifs** (Play/Pause/Stop)  
✅ **Gestion de la batterie** (sauvegarde toutes les 3 minutes)  
✅ **Mode supporter** (voir sans tracker)  
✅ **Contrainte UNE session active** respectée  
✅ **Intégration HealthKit** (BPM, calories)  
✅ **Interface utilisateur moderne** avec SwiftUI  

Bon développement ! 🚀
