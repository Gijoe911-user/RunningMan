# ⚡ Quick Start - Tracking GPS

## 🎯 Objectif
Séparer la **géolocalisation** (automatique) du **tracking GPS** (manuel avec boutons).

---

## ✅ Fichiers Créés

1. **`SessionTrackingControls.swift`** (250 lignes)
   - Boutons : Démarrer/Pause/Reprendre/Terminer
   - Badge de statut animé
   - 4 états : notStarted → active → paused → completed

2. **`SessionTrackingViewModel.swift`** (230 lignes)
   - Enregistrement des points GPS
   - Calculs : distance, allure, durée
   - Sauvegarde Firebase

3. **Guides**
   - `SessionsListView+TrackingIntegration.swift` : Code d'intégration
   - `TRACKING_GPS_GUIDE.md` : Documentation complète
   - `TRACKING_IMPLEMENTATION_SUMMARY.md` : Résumé détaillé
   - `TRACKING_VISUAL_GUIDE.md` : Diagrammes et schémas
   - `DEPENDENCY_MAP.md` : Architecture mise à jour

---

## 🚀 Intégration en 5 Étapes

### 1. Ajouter le ViewModel
```swift
// Dans SessionsListView.swift
@StateObject private var trackingVM: SessionTrackingViewModel?

.task {
    if let session = viewModel.activeSession,
       let sessionId = session.id,
       let userId = AuthService.shared.currentUserId {
        trackingVM = SessionTrackingViewModel(sessionId: sessionId, userId: userId)
    }
}
```

### 2. Badge de Statut (top)
```swift
if let trackingVM = trackingVM {
    VStack {
        TrackingStatusIndicator(
            trackingState: trackingVM.trackingState,
            duration: trackingVM.trackingDuration
        )
        .padding(.top, 60)
        Spacer()
    }
}
```

### 3. Contrôles (bottom)
```swift
if let trackingVM = trackingVM {
    SessionTrackingControls(
        trackingState: $trackingVM.trackingState,
        onStart: { trackingVM.startTracking() },
        onPause: { trackingVM.pauseTracking() },
        onResume: { trackingVM.resumeTracking() },
        onStop: { Task { await trackingVM.stopTracking() } }
    )
    .padding(.horizontal)
}
```

### 4. Tracé GPS sur la Carte
```swift
EnhancedSessionMapView(
    routeCoordinates: trackingVM?.recordedPoints ?? []
    // ... autres paramètres
)
```

### 5. Stats en Temps Réel
```swift
SessionStatsWidget(
    routeDistance: trackingVM?.currentDistance ?? 0
    // ... autres paramètres
)
```

---

## 🔔 Configuration Requise

Dans `RealtimeLocationService.swift`, ajouter :

```swift
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    
    // ... code existant ...
    
    // 🆕 AJOUTER :
    NotificationCenter.default.post(
        name: .locationDidUpdate,
        object: location
    )
}
```

---

## 🎨 Interface Résultante

```
┌─────────────────────────────┐
│ 🔴 Tracking actif • 00:12:34│ ← Badge flottant
│                             │
│   [Carte avec tracé GPS]    │
│                             │
│ ┌─────────┬──────────┐      │
│ │ Pause   │ Terminer │      │ ← Contrôles
│ └─────────┴──────────┘      │
└─────────────────────────────┘
```

---

## 🔄 Machine à États

```
notStarted → [Démarrer] → active → [Pause] → paused
                           ↑                    ↓
                           └───── [Reprendre] ──┘
                           ↓
                        [Terminer] → completed
```

---

## 📊 Données Disponibles

```swift
trackingVM.trackingState        // État actuel
trackingVM.trackingDuration     // Durée (hors pauses)
trackingVM.recordedPoints       // Points GPS [CLLocationCoordinate2D]
trackingVM.currentDistance      // Distance en mètres
trackingVM.currentPace          // Allure en min/km
trackingVM.isTracking           // Bool : est en train d'enregistrer
```

---

## ✅ Checklist

- [ ] Fichiers ajoutés au projet
- [ ] `trackingVM` initialisé dans `SessionsListView`
- [ ] Badge de statut affiché
- [ ] Contrôles affichés
- [ ] Points GPS utilisés dans la carte
- [ ] Stats affichées
- [ ] Notification `.locationDidUpdate` ajoutée
- [ ] Tests effectués (démarrer/pause/terminer)

---

## 📚 Documentation

Consultez :
- `TRACKING_GPS_GUIDE.md` : Guide complet
- `TRACKING_VISUAL_GUIDE.md` : Diagrammes
- `SessionsListView+TrackingIntegration.swift` : Code d'exemple

---

**🎉 Système de Tracking GPS Prêt !**
