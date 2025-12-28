# 🔧 Fix: Participants manquants et liste des sessions

> **Date :** 28 Décembre 2025  
> **Problèmes :** Les autres participants n'apparaissent pas + Pas de liste des sessions

---

## ✅ Solutions implémentées

### 1. **Liste des sessions**

**Nouveau fichier créé :** `SquadSessionsListView.swift`

**Fonctionnalités :**
- ✅ Onglet "Actives" : Voir toutes les sessions en cours
- ✅ Onglet "Historique" : Consulter les sessions passées
- ✅ Bouton "Rejoindre" pour les sessions actives
- ✅ Statistiques détaillées pour chaque session
- ✅ Navigation vers `ActiveSessionDetailView` ou `SessionHistoryDetailView`

**Intégration dans `SquadDetailView` :**
- ✅ Bouton "Voir les sessions" ajouté dans la section Actions
- ✅ Indicateur vert si session active
- ✅ Navigation vers `SquadSessionsListView`

**Nouvelles méthodes dans `SessionService` :**

```swift
// Récupérer l'historique
func getSessionHistory(squadId: String, limit: Int = 50) async throws -> [SessionModel]

// Récupérer les sessions actives
func getActiveSessions(squadId: String) async throws -> [SessionModel]

// Récupérer toutes les sessions
func getAllSessions(squadId: String, limit: Int = 100) async throws -> [SessionModel]
```

---

### 2. **Contexte du service de localisation**

**Problème identifié :**  
Le `RealtimeLocationService` n'avait pas le contexte `squadId`, donc il ne savait pas quelle session observer.

**Solution implémentée :**  
Dans `SquadDetailView.swift`, ajout de :

```swift
.task {
    // Définir le contexte du service de localisation en temps réel
    if let squadId = squad.id {
        RealtimeLocationService.shared.setContext(squadId: squadId)
        Logger.log("🎯 Contexte défini pour squad: \(squadId)", category: .location)
    }
}
```

**Effet :**  
Dès que l'utilisateur entre dans `SquadDetailView`, le service de localisation sait quel squad observer et commence à écouter les positions des participants.

---

## 🐛 Diagnostic : Pourquoi les participants n'apparaissent pas

### Vérifications à faire

#### 1. **Vérifier que le contexte est défini**

Dans la console Xcode, cherchez :
```
🎯 Contexte défini pour squad: [squadId]
```

Si absent → Le contexte n'est pas défini, les positions ne peuvent pas être observées.

#### 2. **Vérifier que les positions sont publiées dans Firestore**

Dans Firebase Console → Firestore :
```
sessions/
  {sessionId}/
    locations/  ← SOUS-COLLECTION
      {userId1}/
        - latitude: 48.8566
        - longitude: 2.3522
        - displayName: "John"
        - photoURL: "..."
        - timestamp: [Timestamp]
```

**Si vide :**  
→ Les positions ne sont pas publiées. Vérifier `RealtimeLocationService.publishLocation()`.

#### 3. **Vérifier que le stream d'observation fonctionne**

Dans la console, cherchez :
```
👥 Coureurs reçus: X
```

- Si `X = 0` : Aucun coureur dans la session ou stream non démarré
- Si `X > 0` mais pas de markers : Problème d'affichage sur la carte

#### 4. **Vérifier les permissions GPS**

Dans `Info.plist` :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nous avons besoin de votre position pour suivre votre course</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Permet de continuer à tracker votre position en arrière-plan</string>
```

---

## 🔍 Débogage du problème des participants

### Étape 1 : Vérifier le flux de publication

Dans `RealtimeLocationService.swift`, ajoutez des logs :

```swift
func publishLocation(coordinate: CLLocationCoordinate2D) async {
    guard let session = activeSession else {
        print("❌ Pas de session active, publication impossible")
        return
    }
    
    print("📍 Publication position pour session: \(session.id ?? "unknown")")
    print("📍 Coordonnées: \(coordinate.latitude), \(coordinate.longitude)")
    
    // ... reste du code
}
```

### Étape 2 : Vérifier le flux d'observation

Dans `RealtimeLocationRepository.swift` :

```swift
func observeRunnerLocations(sessionId: String) -> AsyncStream<[RunnerLocation]> {
    print("👀 Observation démarrée pour session: \(sessionId)")
    
    return AsyncStream { continuation in
        let query = db.collection("sessions")
            .document(sessionId)
            .collection("locations")
        
        let listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Erreur observation: \(error.localizedDescription)")
                continuation.yield([])
                return
            }
            
            let runners = snapshot?.documents.compactMap { /* ... */ } ?? []
            print("👥 Coureurs trouvés: \(runners.count)")
            
            // DEBUG: Afficher les noms
            runners.forEach { runner in
                print("  - \(runner.displayName) @ \(runner.latitude), \(runner.longitude)")
            }
            
            continuation.yield(runners)
        }
        
        continuation.onTermination = { _ in
            listener.remove()
        }
    }
}
```

### Étape 3 : Vérifier EnhancedSessionMapView

Dans `EnhancedSessionMapView.swift`, vérifier que les `runnerLocations` sont bien reçues :

```swift
var body: some View {
    Map(position: $cameraPosition) {
        // User marker
        if let userLocation = userLocation {
            Annotation("Vous", coordinate: userLocation) {
                // ...
            }
        }
        
        // Runners markers
        ForEach(runnerLocations) { runner in
            Annotation(runner.displayName, coordinate: runner.coordinate) {
                // ...
            }
        }
    }
    .onAppear {
        print("🗺️ Map appeared with \(runnerLocations.count) runners")
    }
    .onChange(of: runnerLocations) { old, new in
        print("🗺️ Runners updated: \(old.count) → \(new.count)")
    }
}
```

---

## 📋 Checklist de résolution

### Pour les participants manquants :

- [ ] `SquadDetailView.task` définit le contexte avec `setContext(squadId:)`
- [ ] Session créée avec `status: "ACTIVE"`
- [ ] Positions publiées dans `sessions/{id}/locations/{userId}`
- [ ] Règles Firestore permettent lecture/écriture dans `locations`
- [ ] GPS activé et permissions accordées
- [ ] `RealtimeLocationService.startLocationUpdates()` appelé
- [ ] Stream d'observation démarré dans `ActiveSessionViewModel`
- [ ] Logs montrent "👥 Coureurs reçus: X" avec X > 0
- [ ] `EnhancedSessionMapView` reçoit bien `runnerLocations`

### Pour la liste des sessions :

- [ ] `SquadSessionsListView.swift` ajouté au projet
- [ ] Bouton "Voir les sessions" visible dans `SquadDetailView`
- [ ] Méthodes `getSessionHistory()` et `getActiveSessions()` dans `SessionService`
- [ ] Navigation fonctionne vers `SquadSessionsListView`
- [ ] Onglets "Actives" et "Historique" affichés
- [ ] Sessions chargées depuis Firestore
- [ ] Bouton "Rejoindre" appelle `joinSession()`

---

## 🎯 Solution rapide (Quick Fix)

Si les participants n'apparaissent toujours pas après ces vérifications, essayez ceci dans `ActiveSessionDetailView` :

```swift
.task {
    // Force le contexte immédiatement
    if let squadId = session.squadId {
        RealtimeLocationService.shared.setContext(squadId: squadId)
    }
    
    // Attendre que le GPS se stabilise
    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
    
    // Démarrer l'observation
    await viewModel.startObserving(sessionId: session.id ?? "")
    
    // Publier notre position immédiatement
    if let userId = AuthService.shared.currentUserId,
       let coordinate = RealtimeLocationService.shared.userCoordinate {
        let repository = RealtimeLocationRepository()
        try? await repository.publishLocation(
            sessionId: session.id ?? "",
            userId: userId,
            coordinate: coordinate
        )
        print("📍 Position initiale publiée")
    }
}
```

---

## 🧪 Test manuel complet

### Test avec 2 appareils/simulateurs :

1. **Appareil 1 (Créateur)**
   - Créer une squad
   - Créer une session
   - Aller dans `SquadDetailView`
   - Vérifier log : "🎯 Contexte défini pour squad"
   - Vérifier GPS : position visible sur la carte
   - Publier position toutes les 10 secondes

2. **Appareil 2 (Participant)**
   - Rejoindre la squad avec le code
   - Aller dans `SquadDetailView`
   - Cliquer sur "Voir les sessions"
   - Voir la session active du créateur
   - Cliquer sur "Rejoindre"
   - Vérifier que les 2 markers apparaissent sur la carte

3. **Vérifications dans Firestore**
   - Session a 2 participants : `["userId1", "userId2"]`
   - Sous-collection `locations` a 2 documents
   - Chaque document a `latitude`, `longitude`, `displayName`, `timestamp`

---

## 🔥 Règles Firestore à jour

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Sessions
    match /sessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
      
      // ✅ Locations (positions en temps réel)
      match /locations/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Stats participants
      match /participantStats/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
  }
}
```

---

## ✅ Résumé des fichiers modifiés

1. **`SessionService.swift`**
   - ✅ Ajout de `getSessionHistory()`
   - ✅ Ajout de `getActiveSessions()`
   - ✅ Ajout de `getAllSessions()`

2. **`SquadDetailView.swift`**
   - ✅ Ajout de `@State var showSessionsList`
   - ✅ Ajout du bouton "Voir les sessions"
   - ✅ Ajout de `.task { setContext() }`
   - ✅ Navigation vers `SquadSessionsListView`

3. **`SquadSessionsListView.swift` (NOUVEAU)**
   - ✅ Liste des sessions actives
   - ✅ Liste de l'historique
   - ✅ Segmented control pour switcher
   - ✅ Cartes de session avec stats
   - ✅ Bouton "Rejoindre" pour sessions actives

---

## 📞 Support

Si le problème persiste :

1. Copier tous les logs de la console
2. Vérifier la structure Firestore (screenshot)
3. Vérifier les règles Firestore
4. Tester avec 2 appareils réels (pas simulateur)

---

**Dernière mise à jour :** 28 Décembre 2025

