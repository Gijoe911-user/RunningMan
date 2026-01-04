# 🗺️ Guide : Afficher les tracés GPS pour les supporters

## 🎯 Problème identifié

Les logs montrent que :
- ✅ Les points GPS sont bien sauvegardés toutes les 10s dans Firebase
- ✅ La session est active et les stats se mettent à jour
- ❌ Mais le tracé n'apparaît pas sur la carte pour les supporters
- ❌ Log : "Points GPS chargés: 0"

## 🔍 Cause racine

Les tracés GPS sont sauvegardés dans Firebase, mais **ne sont pas chargés** quand un supporter rejoint la session. Il faut appeler `RouteTrackingService.loadRoute()` ou `TrackingManager.loadAllRoutes()`.

## ✅ Solution implémentée

### 1. Nouvelles méthodes dans `TrackingManager`

```swift
// Charger le tracé d'un seul coureur
await TrackingManager.shared.loadRoute(sessionId: sessionId, userId: userId)

// Charger tous les tracés d'une session
await TrackingManager.shared.loadAllRoutes(sessionId: sessionId)
```

### 2. Propriété `@Published` pour les tracés des autres coureurs

```swift
@Published private(set) var otherRunnersRoutes: [String: [CLLocationCoordinate2D]] = [:]
```

## 🛠️ Comment l'utiliser

### Option A : Dans `SessionTrackingView` (pour un coureur actif)

Aucune modification nécessaire ! Le tracé se remplit automatiquement via `TrackingManager.routeCoordinates`.

### Option B : Dans `SquadDetailView` ou `SessionDetailView` (pour les supporters)

Ajouter un `task` pour charger les tracés au démarrage :

```swift
struct SquadDetailView: View {
    let session: SessionModel
    @StateObject private var trackingManager = TrackingManager.shared
    
    var body: some View {
        ZStack {
            // Carte avec tous les tracés
            EnhancedSessionMapView(
                userLocation: nil,  // Supporter = pas de position active
                runnerLocations: runnerLocations,
                routeCoordinates: trackingManager.routeCoordinates,  // Mon tracé (si je cours)
                runnerRoutes: trackingManager.otherRunnersRoutes     // 🆕 Tracés des autres
            )
        }
        .task {
            // 🎯 Charger tous les tracés au démarrage
            if let sessionId = session.id {
                await trackingManager.loadAllRoutes(sessionId: sessionId)
                
                // ✅ Ensuite, observer les mises à jour en temps réel
                startRealtimeUpdates(sessionId: sessionId)
            }
        }
    }
    
    private func startRealtimeUpdates(sessionId: String) {
        // Timer pour rafraîchir les tracés toutes les 10-15 secondes
        Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            Task {
                await trackingManager.loadAllRoutes(sessionId: sessionId)
            }
        }
    }
}
```

### Option C : Dans `ActiveSessionMapContainerView`

Remplacer le TODO existant :

```swift
private func listenToAllRunnerRoutes() {
    Task {
        // ✅ Charger une première fois
        await TrackingManager.shared.loadAllRoutes(sessionId: sessionId)
        
        // ✅ Observer les changements
        otherRunnersRoutes = TrackingManager.shared.otherRunnersRoutes
        routeCoordinates = TrackingManager.shared.routeCoordinates
        
        // ✅ Rafraîchir toutes les 15 secondes
        Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            Task {
                await TrackingManager.shared.loadAllRoutes(sessionId: sessionId)
                await MainActor.run {
                    self.otherRunnersRoutes = TrackingManager.shared.otherRunnersRoutes
                    self.routeCoordinates = TrackingManager.shared.routeCoordinates
                }
            }
        }
    }
}
```

## 📊 Structure Firebase attendue

Les tracés doivent être dans :
```
/routes
  /{sessionId}_{userId}
    - sessionId: String
    - userId: String
    - points: Array<GeoPoint>
    - pointsCount: Number
    - createdAt: Timestamp
```

✅ Cette structure est déjà utilisée par `RouteTrackingService.saveRoute()`.

## 🎨 Résultat attendu

Une fois implémenté :
- ✅ Les supporters verront les tracés GPS se dessiner en temps réel
- ✅ Chaque coureur aura une couleur différente sur la carte
- ✅ Les tracés se mettent à jour toutes les 15 secondes
- ✅ L'affichage est fluide grâce aux `@Published` properties

## 🚀 Prochaines étapes

1. **Identifier où le log "Points GPS chargés: 0" apparaît**
   - Chercher dans `SquadDetailView`, `SessionDetailView`, ou un fichier similaire
   
2. **Ajouter l'appel à `loadAllRoutes()` dans le `.task`**
   ```swift
   .task {
       if let sessionId = session.id {
           await trackingManager.loadAllRoutes(sessionId: sessionId)
       }
   }
   ```

3. **Lier les données à la carte**
   ```swift
   EnhancedSessionMapView(
       routeCoordinates: trackingManager.routeCoordinates,
       runnerRoutes: trackingManager.otherRunnersRoutes
   )
   ```

4. **Tester** 🎉
   - Lancer une session avec 2 appareils
   - Vérifier que les tracés apparaissent sur les deux cartes

## 📝 Notes importantes

- **Performance** : Les tracés sont chargés toutes les 15s (pas en temps réel pur) pour économiser les lectures Firebase
- **Temps réel** : Pour un vrai temps réel, utiliser `.addSnapshotListener()` sur la collection `/routes`
- **Couleurs** : Les couleurs des tracés sont gérées par `EnhancedSessionMapView.runnerColor(for:)`
