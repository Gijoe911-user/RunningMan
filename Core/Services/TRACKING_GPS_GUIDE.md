# 🎯 Système de Tracking GPS - Guide de Mise en Œuvre

## 📦 Fichiers Créés

### 1. **SessionTrackingControls.swift**
Composants UI pour contrôler le tracking GPS :

- **`TrackingState`** : Énumération des états (notStarted, active, paused, completed)
- **`SessionTrackingControls`** : Boutons de contrôle avec confirmations
- **`TrackingStatusIndicator`** : Badge flottant avec statut et durée

**Caractéristiques :**
- ✅ Design adaptatif selon l'état
- ✅ Animations et feedback haptique
- ✅ Confirmation avant de terminer
- ✅ Gradients de couleur dynamiques

---

### 2. **SessionTrackingViewModel.swift**
ViewModel pour gérer la logique du tracking GPS :

**Propriétés publiques :**
```swift
@Published var trackingState: TrackingState
@Published var trackingDuration: TimeInterval
@Published var recordedPoints: [CLLocationCoordinate2D]
@Published var currentDistance: Double // en mètres
@Published var currentPace: Double // en min/km
@Published var isTracking: Bool
```

**Méthodes :**
- `startTracking()` : Démarre l'enregistrement des points GPS
- `pauseTracking()` : Met en pause (conserve les points)
- `resumeTracking()` : Reprend après une pause
- `stopTracking()` : Termine et sauvegarde dans Firebase
- `reset()` : Réinitialise pour une nouvelle session

**Fonctionnalités :**
- ✅ Enregistrement automatique des points GPS (via notifications)
- ✅ Calcul de distance en temps réel
- ✅ Calcul d'allure (min/km)
- ✅ Gestion des pauses (durée cumulée)
- ✅ Sauvegarde dans Firebase via RouteTrackingService

---

### 3. **SessionsListView+TrackingIntegration.swift**
Guide complet d'intégration dans votre application.

---

## 🔄 Machine à États

```
┌─────────────┐
│ notStarted  │ ← Session créée, tracking pas démarré
└──────┬──────┘
       │ [Bouton "Démarrer"]
       ↓
┌─────────────┐
│   active    │ ← Enregistrement des points GPS
└──────┬──────┘
       │ [Bouton "Pause"]
       ↓
┌─────────────┐
│   paused    │ ← Points conservés, timer en pause
└──────┬──────┘
       │ [Bouton "Reprendre"]
       ↓
   [active]
       │ [Bouton "Terminer"]
       ↓
┌─────────────┐
│  completed  │ ← Sauvegardé dans Firebase
└─────────────┘
```

---

## 🚀 Étapes d'Intégration

### Étape 1 : Ajouter le ViewModel dans SessionsListView

```swift
// Dans SessionsListView.swift
@StateObject private var viewModel = SessionsViewModel() // Existant
@StateObject private var trackingVM: SessionTrackingViewModel? // 🆕 NOUVEAU

// Dans .task ou .onAppear
.task {
    if let session = viewModel.activeSession,
       let sessionId = session.id,
       let userId = AuthService.shared.currentUserId {
        
        // Initialiser le tracking VM
        trackingVM = SessionTrackingViewModel(
            sessionId: sessionId, 
            userId: userId
        )
    }
}
```

---

### Étape 2 : Afficher le Badge de Statut

```swift
// En haut de la carte (dans le ZStack)
if let trackingVM = trackingVM {
    VStack {
        TrackingStatusIndicator(
            trackingState: trackingVM.trackingState,
            duration: trackingVM.trackingDuration
        )
        .padding(.top, 60) // Sous la safe area
        .padding(.horizontal)
        
        Spacer()
    }
}
```

**Résultat :**
- Badge flottant animé
- Affiche "En attente", "Tracking actif", "En pause", etc.
- Durée mise à jour chaque seconde

---

### Étape 3 : Afficher les Contrôles de Tracking

```swift
// Au-dessus de SessionActiveOverlay
if let trackingVM = trackingVM {
    SessionTrackingControls(
        trackingState: $trackingVM.trackingState,
        onStart: {
            trackingVM.startTracking()
        },
        onPause: {
            trackingVM.pauseTracking()
        },
        onResume: {
            trackingVM.resumeTracking()
        },
        onStop: {
            Task {
                await trackingVM.stopTracking()
                
                // 🎯 Actions après la fin :
                // - Mettre à jour le statut de la session dans Firebase
                // - Revenir à l'écran précédent
                // - Afficher un résumé de la session
            }
        }
    )
    .padding(.horizontal)
    .padding(.bottom, 8)
}
```

**Résultat :**
- Boutons adaptés selon l'état
- Confirmation avant de terminer
- Feedback haptique

---

### Étape 4 : Utiliser les Points GPS Enregistrés

```swift
// Dans la carte
EnhancedSessionMapView(
    userLocation: viewModel.userLocation,
    runnerLocations: viewModel.activeRunners,
    routeCoordinates: trackingVM?.recordedPoints ?? [], // ✅ Points du tracking
    runnerRoutes: [:],
    onRecenter: { ... },
    onSaveRoute: { ... }
)
```

**Résultat :**
- Le tracé GPS s'affiche en temps réel
- Seulement quand le tracking est actif

---

### Étape 5 : Afficher les Stats en Temps Réel

```swift
SessionStatsWidget(
    session: session,
    currentHeartRate: viewModel.currentHeartRate,
    currentCalories: viewModel.currentCalories,
    routeDistance: trackingVM?.currentDistance ?? 0 // ✅ Distance calculée
)
```

**Autres stats disponibles :**
- `trackingVM.currentPace` : Allure en min/km
- `trackingVM.trackingDuration` : Durée (hors pauses)
- `trackingVM.recordedPoints.count` : Nombre de points GPS

---

## 🔔 Configuration du Service de Localisation

Pour que le `SessionTrackingViewModel` reçoive les mises à jour, il faut publier les notifications dans `RealtimeLocationService` :

```swift
// Dans RealtimeLocationService.swift
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    
    // ... code existant ...
    
    // 🆕 AJOUTER cette ligne
    NotificationCenter.default.post(
        name: .locationDidUpdate,
        object: location
    )
}
```

---

## 🎨 Personnalisation des Couleurs

Les boutons changent de couleur selon l'état :

| État | Couleur | Icône |
|------|---------|-------|
| `notStarted` | Vert → Bleu | `play.circle.fill` |
| `active` | Coral → Rose | `pause.circle.fill` |
| `paused` | Jaune → Orange | `play.circle.fill` |
| `completed` | Gris | `checkmark.circle.fill` |

Le bouton "Terminer" est toujours rouge (`Color.red.opacity(0.8)`).

---

## 📊 Calculs Automatiques

Le ViewModel calcule automatiquement :

### Distance
```swift
// À chaque nouveau point GPS
let segmentDistance = lastPoint.distance(from: currentPoint)
currentDistance += segmentDistance
```

### Allure (min/km)
```swift
let distanceKm = currentDistance / 1000
let durationMinutes = trackingDuration / 60
currentPace = distanceKm > 0 ? durationMinutes / distanceKm : 0
```

### Durée (hors pauses)
```swift
let elapsed = Date().timeIntervalSince(startTime)
trackingDuration = elapsed - pausedDuration
```

---

## 💾 Sauvegarde dans Firebase

Lors de l'appel à `stopTracking()` :

```swift
try await routeTrackingService.saveRoute(
    sessionId: sessionId,
    userId: userId
)
```

**Ce qui est sauvegardé :**
- Tous les points GPS enregistrés (`recordedPoints`)
- Distance totale
- Durée (hors pauses)
- Timestamp de début/fin

---

## ⚠️ Points d'Attention

### 1. **Géolocalisation ≠ Tracking**
- **Géolocalisation** : Position en temps réel (toujours active)
- **Tracking** : Enregistrement du parcours (activé manuellement)

### 2. **Gestion des Pauses**
- Les points GPS ne sont **pas enregistrés** pendant les pauses
- La durée exclut les périodes de pause
- Le timer s'arrête automatiquement

### 3. **Permissions**
- S'assurer que l'utilisateur a donné l'autorisation de localisation
- Utiliser `CLLocationManager.requestWhenInUseAuthorization()`

### 4. **Performance**
- Les points GPS sont enregistrés à chaque mise à jour (≈ 1 seconde)
- Pour de longues sessions, considérer un échantillonnage (ex: tous les 5 mètres)

### 5. **Indicateurs Visuels**
- Le badge de statut pulse quand le tracking est actif
- Feedback haptique à chaque action (démarrer, pause, terminer)

---

## 🧪 Tests

### Preview des Composants

Les fichiers incluent des previews SwiftUI :

```swift
#Preview("Tracking Controls") { ... }
#Preview("Status Indicators") { ... }
```

### Cas de Test

1. ✅ Démarrer le tracking → Points enregistrés
2. ✅ Mettre en pause → Points non enregistrés, durée figée
3. ✅ Reprendre → Points enregistrés à nouveau
4. ✅ Terminer → Sauvegarde dans Firebase
5. ✅ Multiples pauses → Durée correcte (hors pauses)

---

## 📋 Checklist d'Intégration

- [ ] `SessionTrackingControls.swift` ajouté au projet
- [ ] `SessionTrackingViewModel.swift` ajouté au projet
- [ ] `trackingVM` initialisé dans `SessionsListView`
- [ ] `TrackingStatusIndicator` affiché en haut de la carte
- [ ] `SessionTrackingControls` affiché au-dessus de l'overlay
- [ ] `recordedPoints` utilisés dans `EnhancedSessionMapView`
- [ ] `currentDistance` affiché dans `SessionStatsWidget`
- [ ] Notifications `.locationDidUpdate` publiées dans `RealtimeLocationService`
- [ ] Tests manuels effectués (démarrer/pause/terminer)
- [ ] Sauvegarde Firebase vérifiée

---

## 🎯 Résultat Final

Votre application aura maintenant :

✅ **Session créée** → Géolocalisation active (carte en temps réel)  
✅ **Bouton "Démarrer"** → Tracking GPS lance l'enregistrement  
✅ **Badge flottant** → Statut et durée visibles en permanence  
✅ **Bouton "Pause"** → Met en pause le tracking (conserve les points)  
✅ **Bouton "Reprendre"** → Continue l'enregistrement  
✅ **Bouton "Terminer"** → Sauvegarde le parcours et termine la session  
✅ **Tracé en temps réel** → Visible sur la carte pendant le tracking  
✅ **Stats calculées** → Distance, allure, durée (hors pauses)  

---

**🎉 Système de Tracking GPS Prêt à l'Emploi !**
