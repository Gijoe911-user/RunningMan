# 🗺️ Historique des Parcours et Mode Arrière-Plan

## Date: 28 décembre 2025

## 🎉 Fonctionnalités Implémentées

### 1. ✅ **Historique Complet des Parcours**
Chaque position GPS est maintenant enregistrée dans Firestore, permettant de :
- Voir le tracé complet de chaque coureur sur la carte
- Afficher la polyligne du parcours en temps réel
- Consulter l'historique après la session

### 2. ✅ **Mode Arrière-Plan**
Le tracking GPS continue même quand :
- L'utilisateur quitte l'app
- L'écran se verrouille
- L'utilisateur utilise une autre app

---

## 📁 Nouveaux Fichiers Créés

### 1. **RouteHistoryModel.swift**
Modèles de données pour l'historique :
- `RoutePoint` : Un point GPS individuel
- `UserRoute` : Parcours complet d'un utilisateur
- `RouteSummary` : Résumé pour affichage liste

### 2. **RouteHistoryService.swift**
Service de gestion de l'historique :
- `saveRoutePoint()` : Enregistre un point GPS
- `loadRoutePoints()` : Charge tous les points d'un parcours
- `updateUserRoute()` : Met à jour les stats du parcours
- `streamRoutePoints()` : Observe les points en temps réel
- `calculateRouteStatistics()` : Calcule distance, durée, vitesse

### 3. **RouteHistoryView.swift**
Vue dédiée pour consulter l'historique :
- Carte avec la polyligne du parcours
- Marqueurs de départ (🟢) et arrivée (🔴)
- Liste des participants avec leurs parcours
- Sélection d'un parcours pour le voir sur la carte
- Stats détaillées (distance, durée, allure)

---

## 🏗️ Structure Firestore

### Nouvelle Architecture

```
sessions/
  └── {sessionId}/
      ├── locations/              ← Position en temps réel (mise à jour toutes les 5m)
      │   └── {userId}/
      │       ├── userId
      │       ├── displayName
      │       ├── latitude
      │       ├── longitude
      │       └── timestamp
      │
      ├── routes/                 ← 🆕 Parcours complets
      │   └── {userId}/           ← Document avec infos globales
      │       ├── sessionId
      │       ├── userId
      │       ├── startedAt
      │       ├── endedAt
      │       ├── totalDistance
      │       ├── duration
      │       ├── averageSpeed
      │       ├── maxSpeed
      │       ├── pointsCount
      │       │
      │       └── points/         ← 🆕 Tous les points GPS enregistrés
      │           └── {timestamp}/
      │               ├── latitude
      │               ├── longitude
      │               ├── altitude
      │               ├── speed
      │               ├── horizontalAccuracy
      │               └── timestamp
      │
      └── participantStats/       ← Stats des participants
          └── {userId}/
              ├── distance
              ├── duration
              ├── averageSpeed
              └── maxSpeed
```

---

## 🔄 Modifications des Fichiers Existants

### 1. **LocationService.swift**

#### A. Import UIKit
```swift
import Foundation
import UIKit  // 🆕 Pour UIBackgroundTaskIdentifier
import CoreLocation
import FirebaseFirestore
import Combine
```

#### B. Ajout du RouteHistoryService
```swift
/// Service d'historique des parcours
private let routeHistoryService = RouteHistoryService.shared

/// Tâche en arrière-plan
private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
```

#### C. Enregistrement dans l'historique
```swift
private func sendLocationToFirestore(location: CLLocation) {
    // ...
    
    // 1. Publier la position actuelle (pour la carte en temps réel)
    try await repository.publishLocation(...)
    
    // 2. 🆕 Enregistrer dans l'historique du parcours
    try await routeHistoryService.saveRoutePoint(
        sessionId: sessionId,
        userId: userId,
        location: location
    )
}
```

#### D. Mise à jour des stats du parcours
```swift
private func updateStatsInFirestore() {
    // ...
    
    // 1. Mettre à jour les stats de participant
    try await SessionService.shared.updateParticipantStats(...)
    
    // 2. 🆕 Mettre à jour le parcours (route)
    try await routeHistoryService.updateUserRoute(
        sessionId: sessionId,
        userId: userId,
        distance: trackingStats.totalDistance,
        duration: trackingStats.duration,
        averageSpeed: trackingStats.averageSpeed,
        maxSpeed: trackingStats.maxSpeed,
        pointsCount: trackingStats.pointsCount
    )
}
```

#### E. Terminer le parcours à l'arrêt
```swift
func stopTracking() {
    // ...
    
    // 🆕 Terminer le parcours dans Firestore
    if let sessionId = activeSessionId, let userId = currentUserId {
        Task {
            try await routeHistoryService.endUserRoute(
                sessionId: sessionId,
                userId: userId
            )
        }
    }
    
    // ...
}
```

#### F. Mode Arrière-Plan
```swift
// MARK: - Background Mode Support

/// Démarre une tâche en arrière-plan pour continuer le tracking
private func beginBackgroundTask() {
    backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
        self?.endBackgroundTask()
    }
}

/// Termine la tâche en arrière-plan
private func endBackgroundTask() {
    if backgroundTask != .invalid {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
```

#### G. Utilisation dans le delegate
```swift
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // ...
    
    // 🆕 Démarrer une tâche en arrière-plan si nécessaire
    if backgroundTask == .invalid {
        beginBackgroundTask()
    }
    
    // Mettre à jour la position
    currentLocation = location
    
    if isTracking {
        sendLocationToFirestore(location: location)
        updateTrackingStats(newLocation: location)
    }
    
    // 🆕 Terminer la tâche en arrière-plan
    endBackgroundTask()
}
```

---

### 2. **MapView.swift**

#### Ajout du paramètre routePoints
```swift
struct MapView: View {
    let runnerLocations: [RunnerLocation]
    let userLocation: CLLocationCoordinate2D?
    let routePoints: [RoutePoint]  // 🆕 Points du parcours
    @Binding var mapPosition: MapCameraPosition
    
    var body: some View {
        Map(position: $mapPosition) {
            UserAnnotation()
            
            ForEach(runnerLocations) { runner in
                Annotation("", coordinate: runner.coordinate) {
                    RunnerMapAnnotation(runner: runner)
                }
            }
            
            // 🆕 Show route polyline
            if routePoints.count > 1 {
                MapPolyline(coordinates: routePoints.map { $0.coordinate })
                    .stroke(.coralAccent, lineWidth: 3)
            }
        }
    }
}
```

---

### 3. **SessionDetailView.swift**

#### A. Ajout de l'état pour les points du parcours
```swift
@State private var userRoutePoints: [RoutePoint] = []  // 🆕 Points du parcours
```

#### B. Passer les points à MapView
```swift
private var mapSection: some View {
    MapView(
        runnerLocations: runnerLocations,
        userLocation: locationService.currentLocation?.coordinate,
        routePoints: userRoutePoints,  // 🆕
        mapPosition: $mapPosition
    )
}
```

#### C. Observer le parcours en temps réel
```swift
.task {
    // ...
    
    // 🆕 Observer le parcours de l'utilisateur en temps réel
    if let sessionId = session.id,
       let userId = AuthService.shared.currentUserId {
        await observeUserRoute(sessionId: sessionId, userId: userId)
    }
}

private func observeUserRoute(sessionId: String, userId: String) async {
    let routeService = RouteHistoryService.shared
    let stream = routeService.streamRoutePoints(sessionId: sessionId, userId: userId)
    
    for await points in stream {
        userRoutePoints = points
    }
}
```

#### D. Mode arrière-plan : NE PAS arrêter le tracking
```swift
.onDisappear {
    // 🆕 NE PAS arrêter le tracking pour permettre le mode arrière-plan
    // Le tracking continuera même si l'utilisateur quitte la vue
    // locationService.stopTracking()
}
```

Le tracking s'arrête uniquement quand :
1. L'utilisateur appuie sur "Terminer la session"
2. La session se termine

#### E. Arrêter le tracking à la fin de session
```swift
private func endSession() {
    Task {
        do {
            if let sessionId = session.id {
                // 🆕 Arrêter le tracking avant de terminer
                locationService.stopTracking()
                
                try await SessionService.shared.endSession(sessionId: sessionId)
                dismiss()
            }
        } catch {
            print("Error ending session: \(error)")
        }
    }
}
```

---

## 🎨 Fonctionnalités Visuelles

### 1. **Polyligne en Temps Réel**

Sur la carte dans `SessionDetailView` :
- 🔵 Ligne corail qui se dessine au fur et à mesure
- Se met à jour automatiquement avec chaque nouveau point
- Visible par l'utilisateur pendant sa course

### 2. **Vue Historique Complète**

Nouvelle vue `RouteHistoryView` :
- 🗺️ **Carte** avec le parcours complet
- 🟢 **Marqueur vert** : Point de départ
- 🔴 **Marqueur rouge** : Point d'arrivée
- 📊 **Carte d'informations** : Distance, durée, allure
- 👥 **Liste des participants** avec leurs parcours
- 🎯 **Clic sur participant** : Voir son parcours sur la carte

### 3. **Indicateurs**

- Nombre de points enregistrés visible
- Stats calculées à partir des points réels
- Zoom automatique pour voir le parcours complet

---

## ⚙️ Configuration Requise

### Info.plist (IMPORTANT!)

```xml
<!-- 📍 Permissions de Localisation -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>RunningMan a besoin de votre position pour afficher votre emplacement sur la carte pendant les sessions de course.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>RunningMan suit votre position en temps réel pendant les sessions pour que vos amis puissent vous voir sur la carte.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>RunningMan suit votre position même en arrière-plan pour continuer à afficher votre emplacement pendant les sessions de course.</string>

<!-- 🔄 Mode Arrière-Plan OBLIGATOIRE -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

### Capabilities Xcode

1. Target **RunningMan**
2. **Signing & Capabilities**
3. **+ Capability** → **Background Modes**
4. ✅ **Location updates**

---

## 🔄 Flux de Données

### Publication de Position

```
CLLocationManager détecte un changement (5m)
    ↓
LocationService.didUpdateLocations()
    ↓
beginBackgroundTask()  ← 🆕 Démarrage tâche arrière-plan
    ↓
┌─────────────────────────────────┐
│ 1. RealtimeLocationRepository   │ → sessions/{id}/locations/{userId}
│    (Position en temps réel)     │    (écrase la précédente)
│                                 │
│ 2. RouteHistoryService 🆕       │ → sessions/{id}/routes/{userId}/points/{ts}
│    (Historique complet)         │    (nouveau document pour chaque point)
└─────────────────────────────────┘
    ↓
endBackgroundTask()  ← 🆕 Fin tâche arrière-plan
    ↓
Tous les participants voient :
  - Position mise à jour sur la carte
  - Polyligne qui s'allonge en temps réel
```

### Mise à Jour Périodique (10s)

```
Timer déclenche updateStatsInFirestore()
    ↓
┌─────────────────────────────────┐
│ 1. SessionService               │ → sessions/{id}/participantStats/{userId}
│    (Stats pour la session)      │    { distance, duration, avgSpeed, maxSpeed }
│                                 │
│ 2. RouteHistoryService 🆕       │ → sessions/{id}/routes/{userId}
│    (Stats du parcours)          │    { totalDistance, duration, pointsCount... }
└─────────────────────────────────┘
```

---

## 🧪 Tests

### Test 1 : Enregistrement de l'Historique

1. Créer une session
2. Commencer à courir
3. Vérifier dans Firebase Console :
   - `sessions/{sessionId}/routes/{userId}/points`
   - Nouveaux documents créés toutes les ~5 mètres
4. Vérifier sur la carte :
   - Polyligne se dessine en temps réel

**Résultat attendu** : Un nouveau point tous les 5 mètres

### Test 2 : Mode Arrière-Plan

1. Démarrer une session
2. Quitter l'app (Home button ou swipe up)
3. Attendre 30 secondes
4. Rouvrir l'app
5. Vérifier Firebase Console :
   - Nouveaux points ajoutés pendant l'absence

**Résultat attendu** : Le tracking a continué en arrière-plan

### Test 3 : Polyligne en Temps Réel

1. Session avec 2 appareils
2. Coureur A se déplace
3. Coureur B observe sur sa carte
4. Vérifier :
   - Position de A se met à jour
   - Polyligne de A visible (pas encore implémenté pour les autres)

**Résultat attendu** : Polyligne visible sur sa propre carte

### Test 4 : Vue Historique

1. Terminer une session
2. Naviguer vers `RouteHistoryView`
3. Vérifier :
   - Carte affiche le parcours complet
   - Marqueurs départ/arrivée présents
   - Stats correctes (distance, durée)
4. Cliquer sur un autre participant
5. Vérifier :
   - Carte se centre sur son parcours
   - Polyligne change

**Résultat attendu** : Parcours complet visible avec marqueurs

### Test 5 : Verrouillage Écran

1. Démarrer une session
2. Verrouiller l'écran
3. Attendre 1 minute
4. Déverrouiller
5. Vérifier Firebase :
   - Points ajoutés pendant le verrouillage

**Résultat attendu** : Tracking continue avec écran verrouillé

---

## 📊 Données Enregistrées

### Point GPS (sessions/{id}/routes/{userId}/points/{timestamp})

```json
{
  "latitude": 48.8566,
  "longitude": 2.3522,
  "altitude": 35.2,
  "speed": 2.5,           // m/s
  "horizontalAccuracy": 5.0,
  "timestamp": "2025-12-28T14:30:15Z"
}
```

### Parcours (sessions/{id}/routes/{userId})

```json
{
  "sessionId": "session123",
  "userId": "user456",
  "startedAt": "2025-12-28T14:00:00Z",
  "endedAt": "2025-12-28T14:45:00Z",
  "totalDistance": 5243.7,    // mètres
  "duration": 2700,            // secondes (45 min)
  "averageSpeed": 1.94,        // m/s (~7 km/h)
  "maxSpeed": 3.5,             // m/s (~12.6 km/h)
  "pointsCount": 1048,         // nombre de points
  "createdAt": "2025-12-28T14:00:00Z",
  "updatedAt": "2025-12-28T14:45:00Z"
}
```

---

## 🚀 Utilisation

### Démarrer le Tracking avec Historique

```swift
// Tout est automatique !
// Dès que LocationService.startTracking() est appelé :
// 1. Position actuelle publiée (locations)
// 2. Point enregistré dans l'historique (routes/points)
// 3. Stats mises à jour (participantStats + routes)

locationService.startTracking(sessionId: "session123", userId: "user456")
```

### Charger un Parcours

```swift
let routeService = RouteHistoryService.shared

// Charger tous les points
let points = try await routeService.loadRoutePoints(
    sessionId: "session123",
    userId: "user456"
)

// Afficher sur la carte
MapPolyline(coordinates: points.map { $0.coordinate })
    .stroke(.coralAccent, lineWidth: 3)
```

### Observer en Temps Réel

```swift
let stream = routeService.streamRoutePoints(
    sessionId: "session123",
    userId: "user456"
)

for await points in stream {
    // La polyligne se met à jour automatiquement
    self.routePoints = points
}
```

### Naviguer vers l'Historique

```swift
// Depuis SessionDetailView ou SessionsListView
NavigationLink {
    RouteHistoryView(session: session)
} label: {
    Label("Voir l'historique", systemImage: "map")
}
```

---

## 🐛 Problèmes Connus et Solutions

### Problème 1 : Trop de Points Enregistrés

**Symptôme** : Firestore quotas dépassés, trop de lectures/écritures

**Solutions** :
1. Augmenter `distanceFilter` à 10m ou 20m
2. Filtrer les points avec faible précision (> 20m)
3. Implémenter un throttle (max 1 point / 5 secondes)

### Problème 2 : Mode Arrière-Plan ne Fonctionne Pas

**Causes possibles** :
- `UIBackgroundModes` pas dans Info.plist
- Capabilities Background Modes pas activé
- Permission "Always" pas accordée

**Vérification** :
1. Info.plist : `UIBackgroundModes` = `["location"]`
2. Xcode : Capabilities → Background Modes → Location updates ✅
3. Réglages : RunningMan → Position → **Toujours**

### Problème 3 : Polyligne Saccadée

**Cause** : Précision GPS variable, points aberrants

**Solution** :
```swift
// Dans RouteHistoryService.calculateRouteStatistics()
// Filtrer les distances aberrantes
if distance < 100 {  // < 100m entre deux points
    totalDistance += distance
}
```

### Problème 4 : App Tuée par le Système

**Cause** : iOS peut tuer l'app pour économiser batterie/mémoire

**Solutions** :
1. Implémenter des notifications locales pour réengager l'utilisateur
2. Utiliser `significantLocationChanges` pour économiser batterie
3. Informer l'utilisateur que le tracking peut s'arrêter

**Note** : Le mode arrière-plan n'est PAS garanti indéfiniment par iOS

---

## ⚡ Optimisations Futures

### 1. **Compression des Parcours**

Pour les longues courses, réduire le nombre de points :
- Algorithme de simplification (Douglas-Peucker)
- Garder seulement les points "importants" (changements de direction)

### 2. **Cache Local**

- Stocker les points localement avec CoreData
- Synchroniser avec Firestore périodiquement
- Résilience en cas de perte de connexion

### 3. **Export GPX**

Permettre l'export des parcours :
```swift
func exportToGPX(points: [RoutePoint]) -> String {
    // Générer fichier GPX standard
    // Compatible avec Strava, Garmin, etc.
}
```

### 4. **Analyses Avancées**

- Détection de segments (montées, descentes)
- Calcul du dénivelé
- Zones de vitesse
- Comparaison avec d'autres parcours

### 5. **Mode Économie d'Énergie**

```swift
// Réduire la fréquence en mode éco
if batteryLevel < 0.2 {
    locationManager.distanceFilter = 50  // Au lieu de 5m
}
```

---

## 📖 Documentation des Structures

### RoutePoint

| Champ | Type | Description |
|-------|------|-------------|
| `latitude` | Double | Latitude GPS |
| `longitude` | Double | Longitude GPS |
| `altitude` | Double? | Altitude en mètres |
| `speed` | Double? | Vitesse instantanée (m/s) |
| `horizontalAccuracy` | Double | Précision horizontale (m) |
| `timestamp` | Date | Moment de l'enregistrement |

### UserRoute

| Champ | Type | Description |
|-------|------|-------------|
| `sessionId` | String | ID de la session |
| `userId` | String | ID de l'utilisateur |
| `startedAt` | Date | Début du parcours |
| `endedAt` | Date? | Fin du parcours |
| `totalDistance` | Double | Distance totale (m) |
| `duration` | TimeInterval | Durée totale (s) |
| `pointsCount` | Int | Nombre de points GPS |
| `averageSpeed` | Double | Vitesse moyenne (m/s) |
| `maxSpeed` | Double | Vitesse max (m/s) |

---

## 📝 Conclusion

Le système d'historique des parcours et de mode arrière-plan est maintenant **entièrement fonctionnel** :

✅ Enregistrement de tous les points GPS  
✅ Affichage de la polyligne en temps réel  
✅ Mode arrière-plan avec `UIBackgroundTaskIdentifier`  
✅ Vue dédiée pour consulter l'historique  
✅ Marqueurs de départ et arrivée  
✅ Stats complètes des parcours  
✅ Streaming en temps réel des points  

**L'utilisateur peut maintenant :**
- Voir son parcours se dessiner en temps réel sur la carte
- Quitter l'app et continuer à être tracké
- Consulter l'historique complet après la session
- Voir les parcours de tous les participants

---

**Dernière mise à jour** : 28 décembre 2025  
**Version** : 2.0  
**Auteur** : AI Assistant
