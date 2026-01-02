# Architecture : Session indépendante du tracking individuel

## 🎯 Problème actuel

Quand un participant (notamment le créateur) arrête son tracking avec `stopTracking()`, cela appelle `endSession()` qui **termine la session pour tout le monde**.

### Conséquences :
- ❌ Si le créateur stop, tous les autres sont éjectés
- ❌ Impossible de finir à des moments différents
- ❌ Pas de gestion des abandons
- ❌ Pas de suivi après que certains aient fini

---

## ✅ Architecture proposée

### Nouveaux concepts :

```
Session (Firestore)
├── status: "scheduled" | "active" | "ended"
├── participants: Map<userId, ParticipantSession>
│   ├── userId1: { status: "active", startedAt, endedAt?, ... }
│   ├── userId2: { status: "ended", startedAt, endedAt, ... }
│   └── userId3: { status: "abandoned", ... }
└── stats: { activeCount, endedCount, ... }
```

### États d'un participant :
- `waiting` - En attente de démarrage
- `active` - En course actuellement
- `paused` - En pause
- `ended` - A terminé sa course
- `abandoned` - A abandonné

### États de la session :
- `scheduled` - Pas encore démarrée
- `active` - Au moins 1 participant actif
- `ended` - Tous les participants ont fini/abandonné OU timeout atteint

---

## 🔧 Modifications nécessaires

### 1. **SessionModel.swift** - Ajouter états participants

```swift
struct SessionModel {
    // ... existant ...
    
    /// État de chaque participant dans la session
    /// Key: userId, Value: état du participant
    var participantStates: [String: ParticipantSessionState]?
    
    /// Nombre de participants actuellement actifs
    var activeParticipantsCount: Int {
        participantStates?.values.filter { $0.status == .active }.count ?? 0
    }
    
    /// La session peut être terminée si tous les participants ont fini
    var canBeEnded: Bool {
        guard let states = participantStates, !states.isEmpty else { return true }
        return states.values.allSatisfy { $0.status == .ended || $0.status == .abandoned }
    }
}

/// État d'un participant dans une session
struct ParticipantSessionState: Codable {
    var status: ParticipantStatus
    var startedAt: Date?
    var endedAt: Date?
    var pausedDuration: TimeInterval = 0
    
    enum ParticipantStatus: String, Codable {
        case waiting = "WAITING"
        case active = "ACTIVE"
        case paused = "PAUSED"
        case ended = "ENDED"
        case abandoned = "ABANDONED"
    }
}
```

---

### 2. **TrackingManager.swift** - Distinguer arrêt tracking et fin session

```swift
/// Arrête le tracking pour CET utilisateur uniquement
/// Ne termine PAS la session pour les autres
func stopTrackingForCurrentUser() async throws {
    Logger.log("🛑 Arrêt du tracking utilisateur", category: .location)
    
    guard let session = activeTrackingSession,
          let sessionId = session.id,
          let userId = AuthService.shared.currentUserId else {
        throw TrackingError.invalidSession
    }
    
    trackingState = .stopping
    
    // 1. Arrêter les services locaux
    durationTimer?.invalidate()
    autoSaveTimer?.invalidate()
    locationProvider.stopUpdating()
    healthKitManager.stopHeartRateQuery()
    
    try await healthKitManager.endWorkout()
    
    // 2. Sauvegarder une dernière fois
    await saveCurrentState()
    
    // 3. 🆕 Marquer CE participant comme "ended" (pas toute la session)
    try await sessionService.endParticipantTracking(
        sessionId: sessionId,
        userId: userId,
        finalDistance: currentDistance,
        finalDuration: currentDuration
    )
    
    // 4. 🆕 Vérifier si la session peut être terminée
    // (seulement si tous les participants ont fini)
    try await sessionService.checkAndEndSessionIfComplete(sessionId: sessionId)
    
    // 5. Nettoyer l'état local
    activeTrackingSession = nil
    routeCoordinates = []
    currentDistance = 0
    currentDuration = 0
    trackingState = .inactive
    
    Logger.logSuccess("✅ Tracking arrêté pour cet utilisateur", category: .location)
}

/// 🆕 Abandonner la course (DNF - Did Not Finish)
func abandonTracking() async throws {
    guard let sessionId = activeTrackingSession?.id,
          let userId = AuthService.shared.currentUserId else {
        throw TrackingError.invalidSession
    }
    
    // Arrêter les services
    durationTimer?.invalidate()
    autoSaveTimer?.invalidate()
    locationProvider.stopUpdating()
    healthKitManager.stopHeartRateQuery()
    
    // Marquer comme abandonné
    try await sessionService.abandonParticipantTracking(
        sessionId: sessionId,
        userId: userId
    )
    
    // Nettoyer l'état
    activeTrackingSession = nil
    trackingState = .inactive
    
    Logger.log("⚠️ Course abandonnée", category: .location)
}
```

---

### 3. **SessionService.swift** - Nouvelles fonctions

```swift
// MARK: - Participant Tracking Management

/// 🆕 Termine le tracking pour UN participant
/// Ne termine PAS la session entière
func endParticipantTracking(
    sessionId: String,
    userId: String,
    finalDistance: Double,
    finalDuration: TimeInterval
) async throws {
    Logger.log("🏁 Fin du tracking pour participant: \(userId)", category: .session)
    
    let sessionRef = db.collection("sessions").document(sessionId)
    
    // Mettre à jour l'état du participant
    try await sessionRef.updateData([
        "participantStates.\(userId).status": ParticipantSessionState.ParticipantStatus.ended.rawValue,
        "participantStates.\(userId).endedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
    ])
    
    // Mettre à jour les stats finales
    try await updateParticipantStats(
        sessionId: sessionId,
        userId: userId,
        distance: finalDistance,
        duration: finalDuration,
        averageSpeed: finalDistance / finalDuration,
        maxSpeed: 0 // À récupérer depuis HealthKit ou GPS
    )
    
    Logger.logSuccess("✅ Participant \(userId) a terminé", category: .session)
}

/// 🆕 Marque un participant comme ayant abandonné
func abandonParticipantTracking(
    sessionId: String,
    userId: String
) async throws {
    Logger.log("⚠️ Abandon pour participant: \(userId)", category: .session)
    
    let sessionRef = db.collection("sessions").document(sessionId)
    
    try await sessionRef.updateData([
        "participantStates.\(userId).status": ParticipantSessionState.ParticipantStatus.abandoned.rawValue,
        "participantStates.\(userId).endedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
    ])
    
    Logger.log("✅ Participant \(userId) marqué comme abandonné", category: .session)
}

/// 🆕 Vérifie si tous les participants ont fini
/// Si oui, termine la session automatiquement
func checkAndEndSessionIfComplete(sessionId: String) async throws {
    Logger.log("🔍 Vérification si session peut être terminée: \(sessionId)", category: .session)
    
    let sessionRef = db.collection("sessions").document(sessionId)
    let document = try await sessionRef.getDocument()
    
    guard let session = try? document.data(as: SessionModel.self) else {
        throw SessionError.invalidSession
    }
    
    // Vérifier si tous ont fini
    if session.canBeEnded {
        Logger.log("✅ Tous les participants ont terminé, fin de session", category: .session)
        try await endSession(sessionId: sessionId)
    } else {
        let activeCount = session.activeParticipantsCount
        Logger.log("ℹ️ Session continue, \(activeCount) participant(s) encore actif(s)", category: .session)
    }
}

/// 🆕 Démarre le tracking pour un participant
func startParticipantTracking(
    sessionId: String,
    userId: String
) async throws {
    Logger.log("🚀 Démarrage tracking pour participant: \(userId)", category: .session)
    
    let sessionRef = db.collection("sessions").document(sessionId)
    
    try await sessionRef.updateData([
        "participantStates.\(userId).status": ParticipantSessionState.ParticipantStatus.active.rawValue,
        "participantStates.\(userId).startedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
    ])
    
    // Si c'est le premier participant à démarrer, mettre la session en "active"
    let document = try await sessionRef.getDocument()
    guard let session = try? document.data(as: SessionModel.self) else { return }
    
    if session.status == .scheduled {
        try await sessionRef.updateData([
            "status": SessionStatus.active.rawValue,
            "startedAt": FieldValue.serverTimestamp()
        ])
        Logger.log("✅ Session activée (premier participant)", category: .session)
    }
    
    Logger.logSuccess("✅ Tracking démarré pour participant", category: .session)
}

/// Met en pause le tracking d'un participant
func pauseParticipantTracking(
    sessionId: String,
    userId: String
) async throws {
    let sessionRef = db.collection("sessions").document(sessionId)
    
    try await sessionRef.updateData([
        "participantStates.\(userId).status": ParticipantSessionState.ParticipantStatus.paused.rawValue,
        "updatedAt": FieldValue.serverTimestamp()
    ])
}

/// Reprend le tracking d'un participant
func resumeParticipantTracking(
    sessionId: String,
    userId: String
) async throws {
    let sessionRef = db.collection("sessions").document(sessionId)
    
    try await sessionRef.updateData([
        "participantStates.\(userId).status": ParticipantSessionState.ParticipantStatus.active.rawValue,
        "updatedAt": FieldValue.serverTimestamp()
    ])
}

// MARK: - End Session (modifié)

/// Termine une session pour TOUS les participants
/// ⚠️ Ne devrait être appelée que si :
/// - Tous les participants ont fini/abandonné
/// - OU timeout atteint (ex: 4h après démarrage)
/// - OU annulation manuelle par l'admin
func endSession(sessionId: String) async throws {
    Logger.log("🛑 Fin de session pour tous: \(sessionId)", category: .session)
    
    let sessionRef = db.collection("sessions").document(sessionId)
    
    // Vérifier que la session existe
    let document = try await sessionRef.getDocument()
    guard document.exists else {
        throw SessionError.sessionNotFound
    }
    
    // Calculer la durée totale
    guard let session = try? document.data(as: SessionModel.self) else {
        throw SessionError.invalidSession
    }
    
    let endTime = Date()
    let duration = endTime.timeIntervalSince(session.startedAt)
    
    // Terminer pour tous
    try await sessionRef.updateData([
        "status": SessionStatus.ended.rawValue,
        "endedAt": FieldValue.serverTimestamp(),
        "durationSeconds": duration,
        "updatedAt": FieldValue.serverTimestamp()
    ])
    
    // Retirer de la squad active
    try? await removeSessionFromSquad(squadId: session.squadId, sessionId: sessionId)
    
    // Invalider le cache
    invalidateCache(squadId: session.squadId)
    
    Logger.logSuccess("✅ Session terminée pour tous", category: .session)
}
```

---

## 🎨 UI Updates

### ActiveSessionView - Afficher qui court encore

```swift
struct ActiveSessionView: View {
    @StateObject private var trackingManager = TrackingManager.shared
    let session: SessionModel
    
    var body: some View {
        VStack {
            // Carte avec tracking local
            MapView(...)
            
            // Stats personnelles
            MyStatsCard(...)
            
            // 🆕 Liste des autres participants
            ParticipantsStatusList(session: session)
            
            // Boutons
            HStack {
                // Abandonner
                Button("Abandonner") {
                    Task {
                        try? await trackingManager.abandonTracking()
                    }
                }
                .buttonStyle(.bordered)
                
                // Terminer (pour moi)
                Button("Terminer ma course") {
                    Task {
                        try? await trackingManager.stopTrackingForCurrentUser()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

/// 🆕 Liste des participants avec leur statut
struct ParticipantsStatusList: View {
    let session: SessionModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Participants")
                .font(.headline)
            
            ForEach(Array(session.participantStates?.keys ?? []), id: \.self) { userId in
                if let state = session.participantStates?[userId] {
                    ParticipantStatusRow(userId: userId, state: state)
                }
            }
        }
    }
}

struct ParticipantStatusRow: View {
    let userId: String
    let state: ParticipantSessionState
    
    var statusIcon: String {
        switch state.status {
        case .active: return "figure.run"
        case .paused: return "pause.circle.fill"
        case .ended: return "checkmark.circle.fill"
        case .abandoned: return "xmark.circle.fill"
        case .waiting: return "clock.fill"
        }
    }
    
    var statusColor: Color {
        switch state.status {
        case .active: return .green
        case .paused: return .orange
        case .ended: return .blue
        case .abandoned: return .red
        case .waiting: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            Text(userId) // TODO: Remplacer par displayName
                .font(.subheadline)
            
            Spacer()
            
            Text(state.status.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
```

---

## 📋 Checklist d'implémentation

### Phase 1 : Modèles
- [ ] Créer `ParticipantSessionState` dans SessionModel.swift
- [ ] Ajouter `participantStates` à `SessionModel`
- [ ] Ajouter computed properties `activeParticipantsCount`, `canBeEnded`

### Phase 2 : Service
- [ ] Implémenter `startParticipantTracking()` dans SessionService
- [ ] Implémenter `endParticipantTracking()` dans SessionService
- [ ] Implémenter `abandonParticipantTracking()` dans SessionService
- [ ] Implémenter `pauseParticipantTracking()` dans SessionService
- [ ] Implémenter `resumeParticipantTracking()` dans SessionService
- [ ] Implémenter `checkAndEndSessionIfComplete()` dans SessionService
- [ ] Modifier `endSession()` pour vérifier les permissions

### Phase 3 : Tracking
- [ ] Renommer `stopTracking()` en `stopTrackingForCurrentUser()` dans TrackingManager
- [ ] Modifier `startTracking()` pour appeler `startParticipantTracking()`
- [ ] Modifier `pauseTracking()` pour appeler `pauseParticipantTracking()`
- [ ] Modifier `resumeTracking()` pour appeler `resumeParticipantTracking()`
- [ ] Implémenter `abandonTracking()` dans TrackingManager

### Phase 4 : UI
- [ ] Créer `ParticipantsStatusList` view
- [ ] Créer `ParticipantStatusRow` view
- [ ] Ajouter bouton "Abandonner" dans ActiveSessionView
- [ ] Changer "Terminer" en "Terminer ma course"
- [ ] Ajouter confirmation avant abandon

### Phase 5 : Tests
- [ ] Tester arrêt tracking avec 2+ participants
- [ ] Tester abandon
- [ ] Tester fin automatique quand tous ont fini
- [ ] Tester pause/reprise individuelle
- [ ] Tester timeout de session (4h)

---

## 🚀 Avantages de cette architecture

### Pour les utilisateurs :
- ✅ Chacun peut finir à son rythme
- ✅ Possibilité d'abandonner sans affecter les autres
- ✅ Voir qui court encore en temps réel
- ✅ Statistiques individuelles conservées

### Pour le code :
- ✅ Séparation claire : tracking local vs session globale
- ✅ Session vraiment indépendante du créateur
- ✅ Pas de "single point of failure"
- ✅ Facilite les fonctionnalités futures (spectateurs, commentaires, etc.)

### Pour la scalabilité :
- ✅ Supporte des courses longues (marathons)
- ✅ Supporte des abandons
- ✅ Supporte l'arrivée décalée
- ✅ Facile d'ajouter des états (disqualifié, blessé, etc.)

---

## 💡 Améliorations futures

1. **Timeout automatique** : Terminer la session après X heures
2. **Rôles** : Seuls les admins peuvent forcer la fin de session
3. **Spectateurs** : Observer sans participer
4. **Notifications** : "X a terminé sa course !"
5. **Podium** : Classement final avec temps de chacun
6. **Replay** : Revoir le parcours de chaque participant

---

## 🎯 Résumé

**Avant :**
```
stopTracking() → endSession() → Session terminée pour TOUS
```

**Après :**
```
stopTrackingForCurrentUser() → endParticipantTracking() → 
checkAndEndSessionIfComplete() → endSession() SI tous ont fini
```

**Résultat :** Session indépendante, chacun termine quand il veut ! 🎉
