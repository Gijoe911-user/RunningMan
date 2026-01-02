# Phase 2 : SessionService - ✅ COMPLÉTÉ

## 🎯 Objectif

Implémenter toutes les fonctions dans `SessionService` pour gérer les états individuels des participants.

---

## ✅ Fonctions ajoutées

### 1. **startParticipantTracking()** ✨

Démarre le tracking pour un participant spécifique.

```swift
func startParticipantTracking(sessionId: String, userId: String) async throws
```

**Logique :**
- Marque le participant comme `active`
- Enregistre `startedAt` avec timestamp serveur
- Si c'est le premier participant, passe la session de `scheduled` à `active`

**Usage :**
```swift
try await sessionService.startParticipantTracking(
    sessionId: session.id!,
    userId: currentUserId
)
```

---

### 2. **endParticipantTracking()** ✨

Termine le tracking pour UN participant (pas toute la session).

```swift
func endParticipantTracking(
    sessionId: String,
    userId: String,
    finalDistance: Double,
    finalDuration: TimeInterval
) async throws
```

**Logique :**
- Marque le participant comme `ended`
- Enregistre `endedAt`
- Sauvegarde les stats finales
- **NE termine PAS** la session pour les autres

**Usage :**
```swift
try await sessionService.endParticipantTracking(
    sessionId: sessionId,
    userId: userId,
    finalDistance: trackingManager.currentDistance,
    finalDuration: trackingManager.currentDuration
)
```

---

### 3. **abandonParticipantTracking()** ✨

Marque un participant comme ayant abandonné.

```swift
func abandonParticipantTracking(sessionId: String, userId: String) async throws
```

**Logique :**
- Marque le participant comme `abandoned`
- Enregistre `endedAt`
- Conserve les stats partielles

**Usage :**
```swift
try await sessionService.abandonParticipantTracking(
    sessionId: sessionId,
    userId: userId
)
```

---

### 4. **pauseParticipantTracking()** ✨

Met en pause le tracking d'un participant.

```swift
func pauseParticipantTracking(sessionId: String, userId: String) async throws
```

**Logique :**
- Marque le participant comme `paused`
- Enregistre `lastPausedAt` pour calculer la durée de pause

**Usage :**
```swift
try await sessionService.pauseParticipantTracking(
    sessionId: sessionId,
    userId: userId
)
```

---

### 5. **resumeParticipantTracking()** ✨

Reprend le tracking après une pause.

```swift
func resumeParticipantTracking(sessionId: String, userId: String) async throws
```

**Logique :**
- Calcule la durée de pause depuis `lastPausedAt`
- Ajoute au total `pausedDuration`
- Supprime `lastPausedAt`
- Marque le participant comme `active`

**Usage :**
```swift
try await sessionService.resumeParticipantTracking(
    sessionId: sessionId,
    userId: userId
)
```

---

### 6. **checkAndEndSessionIfComplete()** ✨

Vérifie si tous les participants ont fini et termine la session si nécessaire.

```swift
func checkAndEndSessionIfComplete(sessionId: String) async throws
```

**Logique :**
- Récupère la session
- Vérifie `session.canBeEnded` (tous les participants ont fini ou abandonné)
- Si oui, appelle `endSession()`
- Sinon, log le nombre de participants encore actifs

**Usage :**
```swift
// Appelé automatiquement après endParticipantTracking ou abandonParticipantTracking
try await sessionService.checkAndEndSessionIfComplete(sessionId: sessionId)
```

---

## 🔧 Modifications de fonctions existantes

### 1. **createSession()** - Modifié

**Ajout :**
- Initialise `participantStates` avec le créateur en `waiting`
- Status initial = `scheduled` (au lieu de `active`)

**Avant :**
```swift
let session = SessionModel(
    status: .active,
    participants: [creatorId]
)
```

**Après :**
```swift
let initialParticipantStates = [creatorId: .waiting()]
let session = SessionModel(
    status: .scheduled,  // 🆕
    participants: [creatorId],
    participantStates: initialParticipantStates  // 🆕
)
```

---

### 2. **joinSession()** - Modifié

**Ajout :**
- Initialise l'état du nouveau participant comme `waiting`

**Avant :**
```swift
try await sessionRef.updateData([
    "participants": FieldValue.arrayUnion([userId])
])
```

**Après :**
```swift
try await sessionRef.updateData([
    "participants": FieldValue.arrayUnion([userId]),
    "participantStates.\(userId).status": ParticipantStatus.waiting.rawValue  // 🆕
])
```

---

### 3. **endSession()** - Documentation améliorée

**Ajout :**
- Commentaire clair sur quand cette fonction doit être appelée
- Warning explicite qu'elle termine pour TOUS

```swift
/// ⚠️ **Important :** Cette fonction termine la session globalement.
/// Elle devrait être appelée UNIQUEMENT dans ces cas :
/// - Tous les participants ont fini/abandonné (via `checkAndEndSessionIfComplete`)
/// - Timeout atteint (ex: 4h après le démarrage)
/// - Annulation manuelle par un admin de la squad
///
/// Pour terminer le tracking d'UN SEUL participant, utilisez `endParticipantTracking()`.
```

---

## 🆕 Modifications dans SessionModel

### 1. **SessionStatus** - Ajout de `.scheduled`

```swift
enum SessionStatus: String, Codable {
    case scheduled = "SCHEDULED"  // 🆕 Nouveau
    case active = "ACTIVE"
    case paused = "PAUSED"
    case ended = "ENDED"
}
```

### 2. **Computed property** - `isScheduled`

```swift
var isScheduled: Bool { status == .scheduled }
```

---

## 📊 Cycle de vie d'une session maintenant

### Avant (Phase 1) :
```
Created → Active → Ended (pour tous)
```

### Après (Phase 2) :
```
Created (scheduled)
  ↓
First participant starts → Active
  ↓
Participants can:
  - End individually (ended)
  - Abandon (abandoned)
  - Pause/Resume (paused ↔ active)
  ↓
All finished/abandoned → checkAndEndSessionIfComplete() → Ended
```

---

## 🧪 Tests à effectuer

### Test 1 : Création et démarrage
```swift
// 1. Créer une session
let session = try await sessionService.createSession(
    squadId: squadId,
    creatorId: userId
)
// ✅ Vérifier : session.status == .scheduled
// ✅ Vérifier : participantStates[userId].status == .waiting

// 2. Démarrer le tracking
try await sessionService.startParticipantTracking(
    sessionId: session.id!,
    userId: userId
)
// ✅ Vérifier : session.status == .active
// ✅ Vérifier : participantStates[userId].status == .active
```

### Test 2 : Fin individuelle avec plusieurs participants
```swift
// Session avec Alice et Bob
// Alice termine après 30 min
try await sessionService.endParticipantTracking(
    sessionId: sessionId,
    userId: "alice",
    finalDistance: 5000,
    finalDuration: 1800
)
try await sessionService.checkAndEndSessionIfComplete(sessionId: sessionId)
// ✅ Vérifier : participantStates["alice"].status == .ended
// ✅ Vérifier : session.status == .active (Bob court encore)

// Bob termine après 45 min
try await sessionService.endParticipantTracking(
    sessionId: sessionId,
    userId: "bob",
    finalDistance: 7000,
    finalDuration: 2700
)
try await sessionService.checkAndEndSessionIfComplete(sessionId: sessionId)
// ✅ Vérifier : participantStates["bob"].status == .ended
// ✅ Vérifier : session.status == .ended (tous ont fini)
```

### Test 3 : Abandon
```swift
try await sessionService.abandonParticipantTracking(
    sessionId: sessionId,
    userId: userId
)
// ✅ Vérifier : participantStates[userId].status == .abandoned
// ✅ Vérifier : endedAt != nil
```

### Test 4 : Pause/Reprise
```swift
// Pause
try await sessionService.pauseParticipantTracking(
    sessionId: sessionId,
    userId: userId
)
// ✅ Vérifier : participantStates[userId].status == .paused
// ✅ Vérifier : lastPausedAt != nil

// Attendre 30 secondes...

// Reprise
try await sessionService.resumeParticipantTracking(
    sessionId: sessionId,
    userId: userId
)
// ✅ Vérifier : participantStates[userId].status == .active
// ✅ Vérifier : pausedDuration ≈ 30 secondes
// ✅ Vérifier : lastPausedAt == nil
```

---

## 📋 Checklist Phase 2

- [x] Créer `startParticipantTracking()`
- [x] Créer `endParticipantTracking()`
- [x] Créer `abandonParticipantTracking()`
- [x] Créer `pauseParticipantTracking()`
- [x] Créer `resumeParticipantTracking()`
- [x] Créer `checkAndEndSessionIfComplete()`
- [x] Modifier `createSession()` pour initialiser participantStates
- [x] Modifier `joinSession()` pour initialiser nouvel état
- [x] Améliorer doc de `endSession()`
- [x] Ajouter `SessionStatus.scheduled`
- [x] Ajouter computed property `isScheduled`
- [ ] Tester création → démarrage → fin
- [ ] Tester avec plusieurs participants
- [ ] Tester abandon
- [ ] Tester pause/reprise

---

## 🚀 Prochaine étape : Phase 3

**Objectif :** Modifier `TrackingManager` pour utiliser ces nouvelles fonctions.

**Fichier :** `TrackingManager.swift`

**Tâches :**
1. Renommer `stopTracking()` → `stopTrackingForCurrentUser()`
2. Modifier `startTracking()` pour appeler `startParticipantTracking()`
3. Créer `abandonTracking()`
4. Modifier `pauseTracking()` pour appeler `pauseParticipantTracking()`
5. Modifier `resumeTracking()` pour appeler `resumeParticipantTracking()`

Voir `SESSION_INDEPENDENCE_ARCHITECTURE.md` pour le code détaillé.

---

## ✅ Résumé

**Phase 2 complétée !** 🎉

Tous les outils dans `SessionService` sont maintenant prêts pour gérer les sessions de manière indépendante.

**Fichiers modifiés :**
- `SessionService.swift` - 6 nouvelles fonctions + 3 modifications
- `SessionModel.swift` - Ajout `.scheduled` + `isScheduled`

**Prêt pour Phase 3 ?** Dites "ok poursuivons" ! 🚀
