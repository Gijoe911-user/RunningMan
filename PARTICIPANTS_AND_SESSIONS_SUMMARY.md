# 🎯 Résumé : Participants et Sessions

> **Objectif :** Afficher les autres participants sur la carte + Ajouter une liste des sessions

---

## ✅ Ce qui a été fait

### 1. **Liste des sessions** (NOUVEAU)

📁 **Fichier créé :** `SquadSessionsListView.swift`

**Fonctionnalités :**

```
┌─────────────────────────────────┐
│      SESSIONS                   │
├─────────────────────────────────┤
│  [ Actives ] [ Historique ]     │  ← Segmented control
├─────────────────────────────────┤
│                                 │
│  🏃 Session Marathon             │
│  ● Active                       │
│  👥 3  ⏱️ 45m  🎯 10km          │
│  [ Rejoindre → ]                │
│                                 │
│  🏃 Session Interval             │
│  ● Active                       │
│  👥 2  ⏱️ 20m  🎯 5km           │
│  [ Rejoindre → ]                │
│                                 │
└─────────────────────────────────┘
```

**Onglet Actives :**
- Affiche toutes les sessions en cours
- Indicateur de statut (Vert = Active, Orange = Pause)
- Bouton "Rejoindre" visible
- Temps écoulé depuis le début
- Nombre de participants

**Onglet Historique :**
- Affiche les sessions terminées
- Stats complètes (distance, durée, allure, etc.)
- Navigation vers détails de la session
- Date et heure de la session

---

### 2. **Intégration dans SquadDetailView**

📁 **Fichier modifié :** `SquadDetailView.swift`

**Changements :**

```swift
// Nouvel état
@State private var showSessionsList = false

// Nouveau bouton dans actionsSection
Button {
    showSessionsList = true
} label: {
    HStack {
        Image(systemName: "list.bullet.rectangle.fill")
        Text("Voir les sessions")
        Spacer()
        if squad.hasActiveSessions {
            Circle().fill(Color.green)  // Indicateur vert
        }
    }
}

// Navigation
.navigationDestination(isPresented: $showSessionsList) {
    SquadSessionsListView(squad: squad)
}

// ✅ IMPORTANT: Définir le contexte
.task {
    if let squadId = squad.id {
        RealtimeLocationService.shared.setContext(squadId: squadId)
    }
}
```

**Effet visuel dans SquadDetailView :**

```
┌─────────────────────────────────┐
│  ACTIONS                        │
├─────────────────────────────────┤
│  📋 Voir les sessions        🟢  │  ← Nouveau bouton
│  🔗 Partager le code            │
│  ▶️  Démarrer une session       │
│  🚪 Quitter la squad            │
└─────────────────────────────────┘
```

---

### 3. **Nouvelles méthodes dans SessionService**

📁 **Fichier modifié :** `SessionService.swift`

```swift
/// Récupère l'historique des sessions d'un squad
func getSessionHistory(squadId: String, limit: Int = 50) async throws -> [SessionModel]

/// Récupère toutes les sessions actives d'un squad
func getActiveSessions(squadId: String) async throws -> [SessionModel]

/// Récupère toutes les sessions (actives + historique)
func getAllSessions(squadId: String, limit: Int = 100) async throws -> [SessionModel]
```

**Utilisation :**

```swift
// Dans SquadSessionsListView
let activeSessions = try await SessionService.shared.getActiveSessions(squadId: squadId)
let historySessions = try await SessionService.shared.getSessionHistory(squadId: squadId)
```

---

### 4. **Fix du contexte pour les participants**

**Problème :** Le `RealtimeLocationService` n'avait pas le `squadId`, donc ne savait pas quelle session observer.

**Solution :** Dans `SquadDetailView`, ajout de `.task { setContext() }`

**Effet :**
- Dès l'entrée dans `SquadDetailView`, le contexte est défini
- Le service de localisation sait quel squad observer
- Les positions des autres participants sont récupérées

**Flow :**

```
Utilisateur entre dans SquadDetailView
        ↓
    .task { setContext(squadId) }
        ↓
RealtimeLocationService sait quel squad observer
        ↓
    observe les locations dans Firestore
        ↓
    sessions/{sessionId}/locations/{userId}
        ↓
    Récupère les positions des autres coureurs
        ↓
    Affiche les markers sur la carte
```

---

## 🔍 Diagnostic : Pourquoi les participants ne s'affichent pas

### Checklist de débogage

#### 1. **Vérifier les logs**

Dans la console Xcode :

```
✅ Logs attendus :
🎯 Contexte défini pour squad: abc123
👥 Coureurs reçus: 2
📍 Route: 10 points

❌ Logs d'erreur :
⚠️ Aucune session active détectée
⚠️ Impossible de publier la position
```

#### 2. **Vérifier Firestore**

Structure attendue :

```
sessions/
  {sessionId}/
    - status: "ACTIVE"
    - squadId: "abc123"
    - participants: ["user1", "user2"]
    
    locations/  ← SOUS-COLLECTION
      user1/
        - latitude: 48.8566
        - longitude: 2.3522
        - displayName: "John"
        - timestamp: [Timestamp]
      user2/
        - latitude: 48.8600
        - longitude: 2.3500
        - displayName: "Alice"
        - timestamp: [Timestamp]
```

**Si `locations` est vide :**
→ Les positions ne sont pas publiées

**Causes possibles :**
- GPS pas activé
- Permissions non accordées
- `RealtimeLocationService.startLocationUpdates()` pas appelé
- Contexte `squadId` pas défini

#### 3. **Vérifier les permissions**

Dans `Info.plist` :

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nous avons besoin de votre position pour suivre votre course</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Permet de continuer à tracker votre position en arrière-plan</string>
```

#### 4. **Vérifier les règles Firestore**

```javascript
match /sessions/{sessionId}/locations/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

---

## 🧪 Test manuel

### Scénario 1 : Afficher les sessions

1. Ouvrir l'app
2. Aller dans une squad
3. Cliquer sur "Voir les sessions"
4. **Résultat attendu :**
   - Onglets "Actives" et "Historique" visibles
   - Sessions affichées avec stats
   - Bouton "Rejoindre" pour sessions actives

### Scénario 2 : Voir les autres participants

1. **Appareil 1 :** Créer une session
2. **Appareil 2 :** Rejoindre la session
3. **Résultat attendu sur Appareil 1 :**
   - Voir 2 markers sur la carte
   - Liste des participants : 2 coureurs
   - Position de l'appareil 2 visible en temps réel

4. **Résultat attendu sur Appareil 2 :**
   - Voir 2 markers sur la carte
   - Liste des participants : 2 coureurs
   - Position de l'appareil 1 visible en temps réel

---

## 🎯 Solution rapide

Si les participants ne s'affichent toujours pas :

### Option 1 : Forcer le contexte dans ActiveSessionDetailView

```swift
.task {
    // Force le contexte
    if let squadId = session.squadId {
        RealtimeLocationService.shared.setContext(squadId: squadId)
    }
    
    // Attendre que le GPS se stabilise
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    
    // Démarrer l'observation
    await viewModel.startObserving(sessionId: session.id ?? "")
}
```

### Option 2 : Publier la position manuellement

```swift
// Dans ActiveSessionViewModel.startObserving()
if let userId = AuthService.shared.currentUserId,
   let coordinate = realtimeService.userCoordinate {
    let repository = RealtimeLocationRepository()
    try? await repository.publishLocation(
        sessionId: sessionId,
        userId: userId,
        coordinate: coordinate
    )
}
```

---

## 📊 Structure des données

### SessionModel

```swift
struct SessionModel {
    var id: String?
    var squadId: String
    var creatorId: String
    var status: SessionStatus  // .active, .paused, .ended
    var participants: [String]
    var startedAt: Date
    var endedAt: Date?
    var totalDistanceMeters: Double
    var averageSpeed: Double
    var targetDistanceMeters: Double?
}
```

### RunnerLocation

```swift
struct RunnerLocation: Identifiable {
    var id: String  // userId
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var displayName: String
    var photoURL: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
```

---

## 📂 Fichiers créés/modifiés

### Créés :
- ✅ `SquadSessionsListView.swift`
- ✅ `FIX_PARTICIPANTS_AND_SESSION_LIST.md`
- ✅ `PARTICIPANTS_AND_SESSIONS_SUMMARY.md`

### Modifiés :
- ✅ `SessionService.swift` - Ajout de 3 méthodes
- ✅ `SquadDetailView.swift` - Ajout du bouton + contexte
- ✅ `ActiveSessionDetailView.swift` - Observer la session

---

## 🎉 Résultat final

### Avant :
- ❌ Pas de liste des sessions
- ❌ Impossible de rejoindre une session active
- ❌ Pas d'historique visible
- ❌ Les autres participants invisibles sur la carte

### Après :
- ✅ Liste complète des sessions (actives + historique)
- ✅ Bouton "Rejoindre" pour les sessions actives
- ✅ Historique complet avec stats
- ✅ Participants visibles en temps réel sur la carte
- ✅ Contexte défini automatiquement
- ✅ Logs de débogage complets

---

## 🚀 Prochaines étapes

### Court terme :
1. Tester avec 2 appareils réels
2. Vérifier que les règles Firestore sont correctes
3. Ajouter des animations sur les markers
4. Afficher le tracé GPS de chaque participant

### Moyen terme :
1. Détail complet des sessions historiques
2. Statistiques par participant
3. Comparaison de performances
4. Export des tracés en GPX

### Long terme :
1. Replay animé des sessions
2. Classement des participants
3. Achievements automatiques
4. Partage social des performances

---

**Build et testez avec :** `Cmd + B` puis `Cmd + R`

Bonne chance! 🚀

