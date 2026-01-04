# 🎯 Changelog - Implémentation Heartbeat & Mode Spectateur

## 📅 Date : 3 janvier 2026

### ✅ Modifications Appliquées

#### 1. **SessionModel.swift** - Modèle de Données

**Nouveaux champs ajoutés :**
- ✅ `targetDuration: TimeInterval?` - Durée cible pour la session
- ✅ `participantActivity: [String: ParticipantActivity]?` - Système de heartbeat

**Nouvelle structure `ParticipantActivity` :**
```swift
struct ParticipantActivity {
    var lastUpdate: Date              // Dernier signal reçu
    var isTracking: Bool              // Mode coureur vs spectateur
    var lastLocation: GeoPoint?       // Dernière position GPS
    var lastHeartRate: Double?        // Dernier BPM
    
    var isInactive: Bool { ... }      // > 60s sans signal
    var isActivelyTracking: Bool { ... }
}
```

**Nouvelles computed properties :**
- ✅ `activeTrackingParticipantsCount` - Nombre de coureurs actifs
- ✅ `spectatorCount` - Nombre de spectateurs
- ✅ `inactiveParticipantIds` - Liste des participants sans signal > 60s
- ✅ `allTrackingParticipantsInactive` - Détection fin automatique de session

**Décodage personnalisé :**
- ✅ `init(from decoder: Decoder)` - Valeurs par défaut pour rétrocompatibilité
- ✅ Protection contre les crashs sur anciennes sessions Firestore

---

#### 2. **SessionService.swift** - Logique Métier

**Nouvelles méthodes ajoutées :**

##### Heartbeat & Activity Tracking
```swift
// 🆕 Appelé toutes les 10s par TrackingManager
func updateParticipantHeartbeat(
    sessionId: String,
    userId: String,
    location: GeoPoint?,
    heartRate: Double?
) async throws

// 🆕 Pour les spectateurs
func updateSpectatorActivity(
    sessionId: String,
    userId: String
) async throws

// 🆕 Détecte les inactifs > 60s
func checkInactiveParticipants(sessionId: String) async throws
```

##### Règle de Fin de Session
- ✅ `checkAndEndSessionIfComplete()` - Modifié pour utiliser `allTrackingParticipantsInactive`
- ✅ La session se termine UNIQUEMENT si :
  - Tous les participants tracking sont inactifs (> 60s sans signal)
  - OU tous les participants ont terminé/abandonné manuellement

**Logique d'inactivité :**
```
⚠️ IMPORTANT : Un coureur immobile qui envoie GPS/BPM reste actif
✅ Seule l'absence totale de signal pendant > 60s = abandon automatique
```

---

#### 3. **TrackingManager.swift** - Tracking GPS

**Modifications :**
- ✅ `saveRoutePointsToFirebase()` - Appelle maintenant `updateHeartbeat()`
- ✅ Heartbeat envoyé toutes les 10s avec la sauvegarde auto
- ✅ Inclut position GPS + BPM HealthKit dans le heartbeat

**Nouvelle méthode :**
```swift
private func updateHeartbeat(sessionId: String, userId: String) async {
    // Envoie position + BPM toutes les 10s
    try? await sessionService.updateParticipantHeartbeat(
        sessionId: sessionId,
        userId: userId,
        location: currentGeoPoint,
        heartRate: healthKitManager.currentHeartRate
    )
}
```

---

#### 4. **SessionTrackingView.swift** - Interface Utilisateur

**Changements majeurs :**

##### ❌ SUPPRIMÉ : Auto-start du tracking
```swift
// AVANT (supprimé) :
.task {
    if trackingManager.activeTrackingSession == nil {
        _ = await trackingManager.startTracking(for: session)
    }
}

// APRÈS :
.task {
    // 🆕 MODE SPECTATEUR par défaut
    if let sessionId = session.id {
        await loadExistingRoutes(sessionId: sessionId)
    }
}
```

##### ✅ AJOUTÉ : Mode Spectateur
```swift
@State private var isSpectatorMode = true  // Par défaut

// Badge d'état mis à jour
Text(isSpectatorMode ? "👁️ Spectateur" : currentTrackingState.displayName)
```

**Nouvelle méthode :**
```swift
private func loadExistingRoutes(sessionId: String) async {
    // Charge les routes des autres participants
    // Sans démarrer le tracking local
    await trackingManager.loadAllRoutes(sessionId: sessionId)
}
```

**Comportement :**
1. L'utilisateur entre dans la session → **Mode Spectateur** 👁️
2. Il voit la carte + les routes des autres participants
3. Il clique sur "Démarrer" → Bascule en **Mode Coureur** 🏃
4. Le tracking GPS démarre UNIQUEMENT à ce moment

---

### 🎯 Résultat Final

#### Flux Utilisateur Complet

```
1. Ouverture SessionTrackingView
   └─> isSpectatorMode = true
   └─> Charge routes existantes
   └─> Badge : "👁️ Spectateur"
   └─> Bouton : "▶️ Démarrer"

2. Clic sur "Démarrer"
   └─> trackingManager.startTracking()
   └─> isSpectatorMode = false
   └─> Badge : "🟢 En cours"
   └─> Heartbeat envoyé toutes les 10s

3. Pendant la course
   └─> GPS + BPM envoyés toutes les 10s
   └─> participantActivity.lastUpdate mis à jour
   └─> Reste actif même si immobile

4. Fin manuelle (bouton Stop)
   └─> trackingManager.stopTracking()
   └─> sessionService.endParticipantTracking()
   └─> participantStates[userId].status = .ended

5. Fin automatique (inactivité)
   └─> checkInactiveParticipants() détecte > 60s
   └─> participantStates[userId].status = .abandoned
   └─> Si dernier actif → endSession()
```

---

### 📊 Système de Heartbeat

#### Détection d'Inactivité

| Condition | État | Action |
|-----------|------|--------|
| GPS/BPM reçu < 60s | ✅ Actif | Rien |
| GPS/BPM reçu > 60s | ⚠️ Inactif | Marqué "abandonné" |
| Immobile mais signal OK | ✅ Actif | Rien (normal) |
| App fermée > 60s | ❌ Abandon | Auto-terminé |

#### Fin de Session

La session passe en `.ended` si :
- ✅ Tous les participants tracking ont terminé manuellement
- ✅ OU tous les participants tracking sont inactifs > 60s
- ✅ Les spectateurs n'affectent PAS la fin de session

---

### 🔧 Tests Recommandés

1. **Test Spectateur :**
   - [ ] Ouvrir une session sans cliquer "Démarrer"
   - [ ] Vérifier que le GPS n'est pas activé
   - [ ] Vérifier que les routes des autres sont visibles

2. **Test Heartbeat :**
   - [ ] Démarrer une course
   - [ ] Vérifier Firebase : `participantActivity.lastUpdate` mis à jour toutes les 10s
   - [ ] Rester immobile 30s → Toujours actif
   - [ ] Fermer l'app 60s → Marqué "abandonné"

3. **Test Fin Auto :**
   - [ ] 2 coureurs en session
   - [ ] Coureur 1 termine manuellement
   - [ ] Coureur 2 ferme l'app 60s
   - [ ] Session passe en `.ended` automatiquement

4. **Test Rétrocompatibilité :**
   - [ ] Charger une ancienne session Firestore
   - [ ] Vérifier qu'aucun crash n'arrive
   - [ ] Valeurs par défaut appliquées correctement

---

### 🚀 Prochaines Étapes

#### Phase 2 - Permissions Créateur Squad
- [ ] Vérifier que seul le `ownerId` de la Squad peut créer une session RACE
- [ ] Bloquer sessions TRAINING parallèles quand une RACE est active
- [ ] Implémenter migration automatique vers session RACE

#### Phase 3 - Cloud Functions (Optionnel)
- [ ] Cloud Function : `checkInactiveParticipants()` toutes les 30s
- [ ] Cloud Function : `checkAndEndSessionIfComplete()` après chaque update
- [ ] Réduire la charge sur l'app cliente

---

### ⚠️ Points d'Attention

1. **HealthKit Manager :**
   - Vérifier que `currentHeartRate` est bien publié
   - S'assurer que les permissions sont demandées

2. **Firestore Security Rules :**
   - Permettre lecture de `participantActivity` par tous les participants
   - Permettre écriture uniquement pour son propre userId

3. **Performance :**
   - Heartbeat toutes les 10s = acceptable
   - Logger désactivé pour heartbeat (pollution logs)
   - Batch writes si > 10 participants

---

### 📝 Notes Développeur

**Architecture :**
- `ParticipantSessionState` = État persistant (ended, paused, etc.)
- `ParticipantActivity` = État temps réel (heartbeat, dernière position)
- Séparation claire entre les deux pour éviter conflits

**Nil Coalescing :**
- Toutes les anciennes sessions fonctionnent sans crash
- Valeurs par défaut appliquées au décodage
- Migration progressive sans breaking changes

**Mode Spectateur :**
- Pas de tracking GPS actif
- Pas de sauvegarde en base
- Juste visualisation temps réel

---

## ✅ Checklist de Validation

- [x] SessionModel.swift modifié
- [x] ParticipantActivity créé
- [x] SessionService.swift mis à jour
- [x] TrackingManager.swift mis à jour
- [x] SessionTrackingView.swift mis à jour
- [x] Décodage personnalisé ajouté
- [x] Heartbeat intégré
- [x] Mode spectateur implémenté
- [x] Auto-start supprimé
- [ ] Tests unitaires à ajouter
- [ ] Tests d'intégration à faire
- [ ] Validation métier à obtenir

---

**Auteur :** AI Assistant  
**Date :** 3 janvier 2026  
**Version :** 1.0  
