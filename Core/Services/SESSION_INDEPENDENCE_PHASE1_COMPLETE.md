# Résumé : Session indépendante du tracking - Phase 1 complétée ✅

## 🎯 Objectif

Rendre les sessions **vraiment indépendantes** : chaque participant peut terminer sa course à son rythme sans affecter les autres.

---

## ✅ Phase 1 : Fondations (COMPLÉTÉ)

### Fichiers créés :

#### 1. **ParticipantSessionState.swift** ✨
- Définit l'état individuel de chaque participant
- États supportés : `waiting`, `active`, `paused`, `ended`, `abandoned`
- Méthodes : `start()`, `pause()`, `resume()`, `finish()`, `abandon()`
- Calcul automatique de la durée active (sans pauses)
- UI helpers : icônes, couleurs, emojis

#### 2. **SESSION_INDEPENDENCE_ARCHITECTURE.md** 📚
- Documentation complète de l'architecture
- Guide d'implémentation phase par phase
- Exemples de code pour chaque partie
- Checklist d'implémentation

### Fichiers modifiés :

#### 3. **SessionModel.swift** ✏️
- Ajout de `participantStates: [String: ParticipantSessionState]?`
- Computed properties :
  - `activeParticipantsCount`
  - `finishedParticipantsCount`
  - `abandonedParticipantsCount`
  - `canBeEnded` (true si tous ont fini)
  - `hasActiveParticipants`
  - `participantState(for:)`
  - `isParticipantActive(_:)`

---

## 📋 Prochaines phases (TODO)

### Phase 2 : SessionService
- [ ] Implémenter `startParticipantTracking()`
- [ ] Implémenter `endParticipantTracking()`
- [ ] Implémenter `abandonParticipantTracking()`
- [ ] Implémenter `pauseParticipantTracking()`
- [ ] Implémenter `resumeParticipantTracking()`
- [ ] Implémenter `checkAndEndSessionIfComplete()`
- [ ] Modifier `endSession()` pour vérifier les états

### Phase 3 : TrackingManager
- [ ] Créer `stopTrackingForCurrentUser()` (distinct de `endSession`)
- [ ] Créer `abandonTracking()`
- [ ] Modifier `startTracking()` pour appeler `startParticipantTracking()`
- [ ] Modifier `pauseTracking()` pour appeler `pauseParticipantTracking()`
- [ ] Modifier `resumeTracking()` pour appeler `resumeParticipantTracking()`

### Phase 4 : UI
- [ ] Créer `ParticipantsStatusList` view
- [ ] Créer `ParticipantStatusRow` view
- [ ] Ajouter dans `ActiveSessionView` :
  - Bouton "Terminer ma course"
  - Bouton "Abandonner"
  - Liste des autres participants avec leur statut
- [ ] Ajouter confirmations pour abandon

### Phase 5 : Tests
- [ ] Tester avec 2+ participants qui finissent à des moments différents
- [ ] Tester abandon d'un participant
- [ ] Tester que la session se termine automatiquement quand tous ont fini
- [ ] Tester pause/reprise individuelle
- [ ] Tester compatibilité avec anciennes sessions (sans `participantStates`)

---

## 🎨 Exemple d'utilisation

### Scénario : Course à 3 participants

```swift
// Session créée
let session = SessionModel(
    squadId: "squad123",
    creatorId: "alice",
    participants: ["alice", "bob", "charlie"],
    participantStates: [
        "alice": .waiting(),
        "bob": .waiting(),
        "charlie": .waiting()
    ]
)

// Alice démarre (première)
sessionService.startParticipantTracking(sessionId: sessionId, userId: "alice")
// → session.status = .active
// → participantStates["alice"].status = .active

// Bob démarre 5 min après
sessionService.startParticipantTracking(sessionId: sessionId, userId: "bob")
// → participantStates["bob"].status = .active

// Alice termine après 30 min
trackingManager.stopTrackingForCurrentUser() // Pour Alice
// → participantStates["alice"].status = .ended
// → session reste active (Bob et Charlie courent encore)

// Charlie abandonne après 15 min
trackingManager.abandonTracking() // Pour Charlie
// → participantStates["charlie"].status = .abandoned
// → session reste active (Bob court encore)

// Bob termine après 45 min
trackingManager.stopTrackingForCurrentUser() // Pour Bob
// → participantStates["bob"].status = .ended
// → checkAndEndSessionIfComplete() détecte que tous ont fini
// → session.status = .ended (automatiquement)
```

---

## 💡 Avantages clés

### Pour les utilisateurs :
- ✅ **Liberté totale** : Chacun termine quand il veut
- ✅ **Transparence** : Voir qui court encore en temps réel
- ✅ **Statistiques individuelles** : Chacun conserve ses données
- ✅ **Abandon possible** : Pas de pression

### Pour le code :
- ✅ **DRY** : Session = état global, ParticipantSessionState = état individuel
- ✅ **Single Responsibility** : Chaque participant gère son propre tracking
- ✅ **Type Safety** : États typés avec enum
- ✅ **Testable** : Logique claire et isolée

### Pour l'évolution :
- ✅ **Extensible** : Facile d'ajouter de nouveaux états (blessé, disqualifié, etc.)
- ✅ **Compatible** : Fonctionne avec les anciennes sessions
- ✅ **Scalable** : Supporte n'importe quel nombre de participants

---

## 🚀 Comment continuer

### Étape suivante : SessionService

Ouvrez `SessionService.swift` et implémentez les nouvelles fonctions documentées dans `SESSION_INDEPENDENCE_ARCHITECTURE.md` :

```swift
// Dans SessionService.swift

func startParticipantTracking(sessionId: String, userId: String) async throws {
    let sessionRef = db.collection("sessions").document(sessionId)
    
    try await sessionRef.updateData([
        "participantStates.\(userId).status": ParticipantStatus.active.rawValue,
        "participantStates.\(userId).startedAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
    ])
    
    // Si premier participant, activer la session
    let doc = try await sessionRef.getDocument()
    guard let session = try? doc.data(as: SessionModel.self) else { return }
    
    if session.status == .scheduled {
        try await sessionRef.updateData([
            "status": SessionStatus.active.rawValue,
            "startedAt": FieldValue.serverTimestamp()
        ])
    }
}

func endParticipantTracking(
    sessionId: String,
    userId: String,
    finalDistance: Double,
    finalDuration: TimeInterval
) async throws {
    // Marquer comme terminé
    // Sauvegarder stats finales
    // Vérifier si session peut être terminée
}

// ... etc (voir SESSION_INDEPENDENCE_ARCHITECTURE.md)
```

### Tests rapides

Une fois Phase 2 et 3 implémentées :

```swift
// Test manuel dans l'app
1. Créer une session avec 2+ participants
2. Chaque participant démarre son tracking
3. Un participant termine → les autres continuent
4. Dernier participant termine → session se termine auto
```

---

## 📚 Documentation complète

Consultez **SESSION_INDEPENDENCE_ARCHITECTURE.md** pour :
- Architecture détaillée
- Code complet de chaque fonction
- Exemples d'UI
- Diagrammes de flux
- Checklist complète

---

## ✅ État actuel

| Phase | Status | Fichiers |
|-------|--------|----------|
| 1. Modèles | ✅ Complété | `ParticipantSessionState.swift`, `SessionModel.swift` |
| 2. Service | ⏳ À faire | `SessionService.swift` |
| 3. Tracking | ⏳ À faire | `TrackingManager.swift` |
| 4. UI | ⏳ À faire | `ActiveSessionView.swift`, nouveaux components |
| 5. Tests | ⏳ À faire | Tests manuels et unitaires |

---

## 🎉 Résumé

Vous avez maintenant les **fondations solides** pour gérer les sessions de manière indépendante !

**Prochaine étape :** Implémentez les fonctions dans `SessionService` en suivant le guide dans `SESSION_INDEPENDENCE_ARCHITECTURE.md`.

**Besoin d'aide ?** Tous les exemples de code sont fournis dans la documentation. Suivez phase par phase !
