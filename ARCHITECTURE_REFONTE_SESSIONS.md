# 🏗️ Refonte Architecture Sessions (Incrément 3)

## Date: 28 décembre 2025

## 🎯 Vision

**Philosophie** : Chaque coureur s'entraîne de manière autonome tout en restant connecté à sa Squad.

### Changements Majeurs

1. **Une Squad → Plusieurs Sessions Actives**
   - Fini la limite "une session max par squad"
   - Jean court à Paris, Marie à Lyon = 2 sessions actives

2. **Discovery des Runs Actifs**
   - Voir qui court avant de démarrer
   - Choix : Rejoindre OU Démarrer en solo

3. **Notifications Live Run**
   - "Jean a démarré une course !" → Notif aux membres

4. **Join Session**
   - Rejoindre une session existante
   - ParticipantStats individuelles préservées

5. **Observabilité Temps Réel**
   - Membres non-coureurs peuvent voir et encourager

---

## 📊 Nouvelle Structure Firestore

### Avant

```
squads/
  └── {squadId}/
      └── activeSessions: ["session1"]  ← MAX 1 session
```

### Après

```
squads/
  └── {squadId}/
      └── activeSessions: ["session1", "session2", "session3"]  ← N sessions

sessions/
  └── {sessionId}/
      ├── status: "ACTIVE" | "PAUSED" | "ENDED"
      ├── sessionType: "SOLO" | "GROUP"  ← NOUVEAU
      ├── visibility: "PRIVATE" | "SQUAD"  ← NOUVEAU
      ├── participants: ["user1", "user2"]
      ├── creatorId: "user1"
      ├── title: "Morning Run 🏃"  ← NOUVEAU (optionnel)
      │
      ├── participantStats/{userId}/
      │   ├── distance
      │   ├── duration
      │   └── ...
      │
      └── liveFeed/  ← NOUVEAU (encouragements)
          └── {feedId}/
              ├── userId
              ├── type: "CHEER" | "MESSAGE" | "PHOTO"
              ├── content
              └── timestamp
```

---

## 🔧 Modifications Nécessaires

### 1. **SessionModel.swift** - Nouveaux Champs

```swift
struct SessionModel {
    // Existant
    var id: String?
    var squadId: String
    var creatorId: String
    var status: SessionStatus
    var participants: [String]
    
    // 🆕 NOUVEAUX CHAMPS
    var sessionType: SessionType  // SOLO ou GROUP
    var visibility: SessionVisibility  // PRIVATE ou SQUAD
    var title: String?  // "Morning Run 🏃"
    var isJoinable: Bool  // Peut-on rejoindre ?
    var maxParticipants: Int?  // Limite (optionnel)
}

enum SessionType: String, Codable {
    case solo = "SOLO"
    case group = "GROUP"
}

enum SessionVisibility: String, Codable {
    case `private` = "PRIVATE"  // Invisible pour les autres
    case squad = "SQUAD"  // Visible par la squad
}
```

### 2. **SessionService.swift** - Refonte Complète

#### A. Remplacer `getActiveSession()` 

```swift
// ❌ ANCIEN - Une seule session
func getActiveSession(squadId: String) async throws -> SessionModel?

// ✅ NOUVEAU - Toutes les sessions actives
func getActiveSessions(squadId: String) async throws -> [SessionModel]
```

#### B. Modifier `streamActiveSessions()`

```swift
// ❌ ANCIEN - Stream d'UNE session
func observeActiveSession(squadId: String) -> AsyncStream<SessionModel?>

// ✅ NOUVEAU - Stream de TOUTES les sessions
func streamActiveSessions(squadId: String) -> AsyncStream<[SessionModel]> {
    AsyncStream { continuation in
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", in: [
                SessionStatus.active.rawValue,
                SessionStatus.paused.rawValue
            ])
            .order(by: "startedAt", descending: true)
        
        let listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ ERROR streamActiveSessions: \(error)")
                continuation.yield([])
                return
            }
            
            let sessions = snapshot?.documents.compactMap { 
                try? $0.data(as: SessionModel.self) 
            } ?? []
            
            print("📦 \(sessions.count) session(s) active(s) dans squad \(squadId)")
            continuation.yield(sessions)
        }
        
        continuation.onTermination = { _ in
            listener.remove()
        }
    }
}
```

#### C. Nouvelle Méthode : `createSession()` avec type

```swift
func createSession(
    squadId: String,
    creatorId: String,
    sessionType: SessionType,
    visibility: SessionVisibility,
    title: String? = nil,
    isJoinable: Bool = true,
    startLocation: GeoPoint? = nil
) async throws -> SessionModel {
    
    let session = SessionModel(
        squadId: squadId,
        creatorId: creatorId,
        startedAt: Date(),
        status: .active,
        participants: [creatorId],
        sessionType: sessionType,  // 🆕
        visibility: visibility,  // 🆕
        title: title,  // 🆕
        isJoinable: isJoinable,  // 🆕
        startLocation: startLocation
    )
    
    let sessionRef = db.collection("sessions").document()
    session.id = sessionRef.documentID
    
    try sessionRef.setData(from: session)
    try await addSessionToSquad(squadId: squadId, sessionId: sessionRef.documentID)
    
    // 🆕 Envoyer notification aux membres
    await notifySquadMembers(squadId: squadId, session: session)
    
    return session
}
```

#### D. Nouvelle Méthode : `joinSession()`

```swift
func joinSession(sessionId: String, userId: String) async throws {
    let sessionRef = db.collection("sessions").document(sessionId)
    let doc = try await sessionRef.getDocument()
    
    guard let session = try? doc.data(as: SessionModel.self) else {
        throw SessionError.sessionNotFound
    }
    
    // Vérifier si joinable
    guard session.isJoinable else {
        throw SessionError.notJoinable
    }
    
    // Vérifier limite de participants
    if let maxParticipants = session.maxParticipants,
       session.participants.count >= maxParticipants {
        throw SessionError.sessionFull
    }
    
    // Ajouter le participant
    try await sessionRef.updateData([
        "participants": FieldValue.arrayUnion([userId]),
        "updatedAt": FieldValue.serverTimestamp()
    ])
    
    // Créer les stats initiales
    let statsRef = sessionRef.collection("participantStats").document(userId)
    let stats = ParticipantStats(
        userId: userId,
        distance: 0,
        duration: 0,
        averageSpeed: 0,
        maxSpeed: 0,
        locationPointsCount: 0,
        joinedAt: Date()
    )
    try statsRef.setData(from: stats)
    
    Logger.logSuccess("Utilisateur \(userId) a rejoint la session \(sessionId)", category: .session)
}
```

#### E. Nouvelle Méthode : Notifications

```swift
private func notifySquadMembers(squadId: String, session: SessionModel) async {
    // Récupérer les membres de la squad
    guard let squad = try? await SquadService.shared.getSquad(squadId: squadId) else {
        return
    }
    
    // Récupérer le nom du créateur
    guard let creator = try? await AuthService.shared.getUserProfile(userId: session.creatorId) else {
        return
    }
    
    // Créer la notification
    let notificationData: [String: Any] = [
        "type": "LIVE_RUN_STARTED",
        "sessionId": session.id ?? "",
        "creatorId": session.creatorId,
        "creatorName": creator.displayName,
        "squadId": squadId,
        "squadName": squad.name,
        "timestamp": FieldValue.serverTimestamp()
    ]
    
    // Envoyer aux membres (sauf le créateur)
    for memberId in squad.memberIds where memberId != session.creatorId {
        let notifRef = db.collection("users")
            .document(memberId)
            .collection("notifications")
            .document()
        
        try? await notifRef.setData(notificationData)
    }
    
    Logger.log("📢 Notification envoyée à \(squad.memberIds.count - 1) membre(s)", category: .session)
}
```

---

### 3. **SquadViewModel.swift** - Observ

ation Multiple

#### Ajouter État pour Sessions Actives

```swift
@MainActor
@Observable
class SquadViewModel {
    // Existant
    var userSquads: [SquadModel] = []
    var selectedSquad: SquadModel?
    
    // 🆕 NOUVEAU
    var activeSessionsInSelectedSquad: [SessionModel] = []
    var isObservingSessions = false
    
    private var sessionsObservationTask: Task<Void, Never>?
    
    // ...
}
```

#### Nouvelle Méthode : Observer les Sessions

```swift
/// Observe toutes les sessions actives de la squad sélectionnée
func startObservingActiveSessions() {
    guard let squadId = selectedSquad?.id else {
        Logger.log("⚠️ Pas de squad sélectionnée", category: .squads)
        return
    }
    
    // Empêcher plusieurs listeners
    guard sessionsObservationTask == nil else {
        return
    }
    
    isObservingSessions = true
    
    sessionsObservationTask = Task { @MainActor [weak self] in
        guard let self else { return }
        
        let stream = SessionService.shared.streamActiveSessions(squadId: squadId)
        
        for await sessions in stream {
            guard !Task.isCancelled else { break }
            
            self.activeSessionsInSelectedSquad = sessions
            
            Logger.log("📊 \(sessions.count) session(s) active(s) observée(s)", category: .squads)
        }
    }
}

/// Arrête l'observation des sessions
func stopObservingActiveSessions() {
    sessionsObservationTask?.cancel()
    sessionsObservationTask = nil
    isObservingSessions = false
    activeSessionsInSelectedSquad = []
    
    Logger.log("🛑 Observation des sessions arrêtée", category: .squads)
}
```

#### Cleanup

```swift
deinit {
    let sessionsTask = sessionsObservationTask
    Task.detached {
        sessionsTask?.cancel()
    }
}
```

---

### 4. **ActiveSessionsListView.swift** - Discovery UI

```swift
import SwiftUI

struct ActiveSessionsListView: View {
    @ObservedObject var viewModel: SquadViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .foregroundColor(.coralAccent)
                    .font(.title2)
                
                Text("Runs en cours")
                    .font(.sectionTitle)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.activeSessionsInSelectedSquad.count)")
                    .font(.sectionTitle)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Liste des sessions
            if viewModel.activeSessionsInSelectedSquad.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(viewModel.activeSessionsInSelectedSquad) { session in
                            ActiveSessionCard(
                                session: session,
                                onJoin: {
                                    Task {
                                        await joinSession(session)
                                    }
                                },
                                onView: {
                                    // Naviguer vers SessionDetailView
                                }
                            )
                        }
                    }
                }
            }
            
            // Bouton "Démarrer en solo"
            startSoloButton
        }
        .padding()
        .onAppear {
            viewModel.startObservingActiveSessions()
        }
        .onDisappear {
            viewModel.stopObservingActiveSessions()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Aucun run actif")
                .font(.subtitle)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Soyez le premier à démarrer !")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
    }
    
    private var startSoloButton: some View {
        Button {
            Task {
                await startSoloSession()
            }
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                
                Text("Démarrer en solo")
                    .font(.subtitle)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.coralAccent, Color.pinkAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .shadow(color: Color.coralAccent.opacity(0.4), radius: 8, y: 4)
        }
    }
    
    private func joinSession(_ session: SessionModel) async {
        guard let userId = AuthService.shared.currentUserId,
              let sessionId = session.id else {
            return
        }
        
        do {
            try await SessionService.shared.joinSession(
                sessionId: sessionId,
                userId: userId
            )
            
            Logger.logSuccess("Session rejointe !", category: .session)
            
            // Naviguer vers SessionDetailView
        } catch {
            Logger.logError(error, context: "joinSession", category: .session)
        }
    }
    
    private func startSoloSession() async {
        guard let userId = AuthService.shared.currentUserId,
              let squadId = viewModel.selectedSquad?.id else {
            return
        }
        
        do {
            let session = try await SessionService.shared.createSession(
                squadId: squadId,
                creatorId: userId,
                sessionType: .solo,
                visibility: .squad,
                title: nil,
                isJoinable: true
            )
            
            Logger.logSuccess("Session solo créée !", category: .session)
            
            // Naviguer vers SessionDetailView
        } catch {
            Logger.logError(error, context: "startSoloSession", category: .session)
        }
    }
}
```

---

### 5. **ActiveSessionCard.swift** - UI Carte de Session

```swift
struct ActiveSessionCard: View {
    let session: SessionModel
    let onJoin: () -> Void
    let onView: () -> Void
    
    @State private var creatorName: String = "..."
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                HStack {
                    // Type badge
                    HStack(spacing: 4) {
                        Image(systemName: session.sessionType == .solo ? "person.fill" : "person.2.fill")
                            .font(.caption)
                        
                        Text(session.sessionType == .solo ? "Solo" : "Groupe")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.coralAccent.opacity(0.3))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Durée
                    Text(formatDuration(session.startedAt))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Creator
                HStack(spacing: Spacing.sm) {
                    ParticipantBadge(
                        imageURL: nil,
                        initial: creatorName.prefix(1).uppercased(),
                        size: 36
                    )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(creatorName)
                            .font(.subtitle)
                            .foregroundColor(.white)
                        
                        if let title = session.title {
                            Text(title)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                }
                
                // Participants
                if session.participants.count > 1 {
                    HStack {
                        ParticipantsStack(
                            participants: session.participants,
                            maxVisible: 4,
                            badgeSize: 32
                        )
                        
                        Spacer()
                        
                        Text("\(session.participants.count) coureur(s)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Actions
                HStack(spacing: Spacing.sm) {
                    // Bouton Voir
                    Button(action: onView) {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("Voir")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                    }
                    
                    // Bouton Rejoindre (si joinable)
                    if session.isJoinable {
                        Button(action: onJoin) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Rejoindre")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.greenAccent)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                        }
                    }
                }
            }
        }
        .task {
            await loadCreatorName()
        }
    }
    
    private func loadCreatorName() async {
        do {
            if let user = try await AuthService.shared.getUserProfile(userId: session.creatorId) {
                creatorName = user.displayName
            }
        } catch {
            creatorName = "Coureur"
        }
    }
    
    private func formatDuration(_ startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)min"
        }
    }
}
```

---

## 📊 Résumé des Changements

### Modèles
- ✅ `SessionModel` : Ajout `sessionType`, `visibility`, `title`, `isJoinable`
- ✅ `SessionType` enum : `SOLO` | `GROUP`
- ✅ `SessionVisibility` enum : `PRIVATE` | `SQUAD`

### Services
- ✅ `SessionService.streamActiveSessions()` → Retourne `[SessionModel]`
- ✅ `SessionService.createSession()` → Paramètres étendus
- ✅ `SessionService.joinSession()` → Nouvelle méthode
- ✅ `SessionService.notifySquadMembers()` → Notifications

### ViewModels
- ✅ `SquadViewModel.activeSessionsInSelectedSquad` → État
- ✅ `SquadViewModel.startObservingActiveSessions()` → Observer
- ✅ `SquadViewModel.stopObservingActiveSessions()` → Cleanup

### Vues
- ✅ `ActiveSessionsListView` → Discovery UI
- ✅ `ActiveSessionCard` → Carte de session
- ✅ Boutons "Rejoindre" et "Démarrer solo"

---

## 🚀 Actions Immédiates

### Phase 1 : Backend (Priorité Haute)
1. [ ] Modifier `SessionModel` avec nouveaux champs
2. [ ] Refondre `SessionService.streamActiveSessions()`
3. [ ] Implémenter `SessionService.joinSession()`
4. [ ] Implémenter `SessionService.notifySquadMembers()`

### Phase 2 : ViewModel
5. [ ] Ajouter `activeSessionsInSelectedSquad` à `SquadViewModel`
6. [ ] Implémenter `startObservingActiveSessions()`
7. [ ] Gérer le cleanup

### Phase 3 : UI
8. [ ] Créer `ActiveSessionsListView`
9. [ ] Créer `ActiveSessionCard`
10. [ ] Intégrer dans le flow de navigation

### Phase 4 : Notifications
11. [ ] Implémenter système de notifications
12. [ ] Badge "Live Run" dans la UI
13. [ ] Navigation depuis notification

---

## 🎯 User Flow Complet

```
1. Utilisateur ouvre Squad
   ↓
2. Voir liste des runs actifs (Discovery)
   ├─→ Si runs actifs : Afficher cartes avec "Rejoindre" ou "Voir"
   └─→ Si aucun run : État vide + "Démarrer en solo"
   ↓
3. Utilisateur choisit :
   ├─→ A. Rejoindre run existant
   │   ├─ Appeler joinSession()
   │   └─ Naviguer vers SessionDetailView
   │
   └─→ B. Démarrer en solo
       ├─ Appeler createSession(sessionType: .solo)
       ├─ Notifier les membres de la squad
       └─ Naviguer vers SessionDetailView
   ↓
4. Pendant la course :
   ├─ Stats individuelles enregistrées (ParticipantStats)
   ├─ Positions GPS publiées
   └─ Membres peuvent voir et encourager
```

---

**Date** : 28 décembre 2025  
**Version** : Incrément 3  
**Philosophie** : Autonomie + Connexion Squad
