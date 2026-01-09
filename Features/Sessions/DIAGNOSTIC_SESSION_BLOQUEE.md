# 🔍 DIAGNOSTIC - Session Active Bloquée

## 📋 Symptômes Rapportés

Vous êtes **bloqué** avec les symptômes suivants :

1. ❌ **Impossible de créer une nouvelle session** - L'application dit qu'une session est active
2. ❌ **Session invisible dans l'onglet "Sessions Actives"** - Vous ne la voyez pas
3. ✅ **Session visible dans l'onglet "Sessions"** (historique général)
4. ❌ **Impossible d'interagir** avec la session - Aucun bouton ne fonctionne
5. ❌ **État incohérent** - Le statut ne permet pas de reprendre la main

---

## 🎯 Analyse des Causes Probables

### Cause #1 : **Session avec statut corrompu** ⭐️ TRÈS PROBABLE

**Symptômes correspondants :**
- La session est dans la base avec un statut autre que `.active`, `.paused` ou `.scheduled`
- Ou le statut est `.active` mais les champs `participantStates` ou `participantActivity` sont incohérents
- Le code filtre sur `status IN [scheduled, active, paused]` → session invisible si statut différent

**Scénario possible :**
```swift
// Dans SquadSessionsListView.swift (ligne 114)
let query = self.db.collection("sessions")
    .whereField("squadId", isEqualTo: squadId)
    .whereField("status", in: [
        SessionStatus.scheduled.rawValue,  // ✅
        SessionStatus.active.rawValue,      // ✅
        SessionStatus.paused.rawValue       // ✅
    ])
```

➡️ **Si votre session a un statut `.ended` ou `.stopping` ou un statut corrompu**, elle n'apparaîtra PAS dans "Sessions Actives"

---

### Cause #2 : **TrackingManager pense qu'une session est active** ⭐️ PROBABLE

**Symptômes correspondants :**
- `TrackingManager.shared.activeTrackingSession` contient une référence à une session
- `TrackingManager.shared.trackingState != .idle`
- Le guard `canStartTracking` bloque la création d'une nouvelle session

**Code concerné (CreateSessionWithProgramView.swift ou similaire) :**
```swift
// Vérification avant de créer une session
if trackingManager.isTracking {
    // BLOQUE la création
    showAlreadyTrackingAlert = true
    return
}
```

➡️ **Le TrackingManager en mémoire peut être désynchronisé avec Firestore**

---

### Cause #3 : **Champ `hasActiveSessions` du Squad corrompu** ⭐️ POSSIBLE

**Symptômes correspondants :**
- `SquadModel.hasActiveSessions == true`
- Mais aucune session active réelle n'existe dans Firestore

**Code concerné (SquadDetailView.swift ligne 84) :**
```swift
if squad.hasActiveSessions {
    Label("Session active", systemImage: "circle.fill")
        .font(.caption)
        .foregroundColor(.green)
}
```

➡️ **Le champ `hasActiveSessions` n'a pas été mis à jour lors de la fin de session**

---

### Cause #4 : **Session "zombie" avec `realId == "ID_MANQUANT"`** ⭐️ MOINS PROBABLE

**Symptômes correspondants :**
- La session existe dans Firestore
- Mais son `id` ou `manualId` ne sont pas injectés correctement
- Les boutons "Terminer" ou "Rejoindre" ne fonctionnent pas car ils dépendent de `realId`

**Code concerné (SessionDetailView.swift ligne 413) :**
```swift
private var canEndSession: Bool {
    // ...
    let isTrackingThisSession = trackingManager.activeTrackingSession?.realId == session.realId
    // Si session.realId == "ID_MANQUANT", cette comparaison échoue toujours
}
```

➡️ **Sessions sans ID valide sont inutilisables**

---

## 🛠️ Plan d'Action Recommandé

### Option 1 : **Nettoyage Manuel de la Session (Recommandé pour débloquer immédiatement)** ✅

Vous avez mentionné pouvoir supprimer la session corrompue en base de données. C'est la solution la plus rapide.

#### Étapes :

1. **Ouvrir Firebase Console** → Firestore → Collection `sessions`
2. **Identifier la session problématique** :
   - Filtrer par `squadId == [votre_squad_id]`
   - Chercher une session avec `status != ended`
3. **Supprimer le document entier**
4. **Mettre à jour le squad** (collection `squads`) :
   - Trouver le document de votre squad
   - Mettre `hasActiveSessions = false` (ou supprimer le champ)
5. **Redémarrer l'application** (ou faire un pull-to-refresh)

---

### Option 2 : **Script de Nettoyage Automatique** 🔧

Si vous voulez automatiser le nettoyage pour éviter ce problème à l'avenir, je peux créer une fonction de maintenance.

#### Script suggéré :

```swift
// À ajouter dans SessionService.swift
func cleanupCorruptedSessions(squadId: String) async throws {
    Logger.log("🧹 Nettoyage des sessions corrompues pour squad: \(squadId)", category: .service)
    
    // 1. Récupérer TOUTES les sessions (pas seulement actives)
    let allSessions = try await db.collection("sessions")
        .whereField("squadId", isEqualTo: squadId)
        .getDocuments()
    
    for doc in allSessions.documents {
        guard let session = try? doc.data(as: SessionModel.self) else {
            Logger.log("⚠️ Session corrompue détectée: \(doc.documentID)", category: .service)
            // Option 1: Supprimer
            try await doc.reference.delete()
            Logger.log("🗑️ Session \(doc.documentID) supprimée", category: .service)
            continue
        }
        
        // 2. Détecter les sessions "zombies" (actives depuis > 4h)
        let elapsed = Date().timeIntervalSince(session.startedAt)
        if elapsed > 14400 && session.status != .ended {  // 4 heures
            Logger.log("⏱️ Session zombie détectée: \(doc.documentID) (active depuis \(elapsed/3600)h)", category: .service)
            try await doc.reference.updateData([
                "status": SessionStatus.ended.rawValue,
                "endedAt": FieldValue.serverTimestamp()
            ])
            Logger.log("✅ Session zombie terminée: \(doc.documentID)", category: .service)
        }
    }
    
    // 3. Mettre à jour le champ hasActiveSessions du squad
    let activeCount = try await getActiveSessions(squadId: squadId).count
    try await db.collection("squads").document(squadId).updateData([
        "hasActiveSessions": activeCount > 0
    ])
    
    Logger.logSuccess("✅ Nettoyage terminé", category: .service)
}
```

---

### Option 3 : **Améliorer la Robustesse du Code** 🛡️

Pour éviter que ce problème se reproduise, voici les améliorations recommandées :

#### Fix #1 : **Forcer la synchronisation TrackingManager au démarrage**

```swift
// Dans TrackingManager.swift - Ajouter une méthode de réconciliation
func reconcileWithFirestore() async {
    Logger.log("🔄 Réconciliation TrackingManager avec Firestore", category: .session)
    
    guard let userId = AuthService.shared.currentUserId else { return }
    
    // Vérifier si on a une session locale active
    if let localSession = activeTrackingSession {
        // Vérifier son état dans Firestore
        if let firestoreSession = try? await SessionService.shared.getSession(sessionId: localSession.realId) {
            if firestoreSession?.status == .ended {
                Logger.log("⚠️ Session locale active mais terminée dans Firestore → Reset", category: .session)
                await resetTracking()
            }
        } else {
            Logger.log("⚠️ Session locale introuvable dans Firestore → Reset", category: .session)
            await resetTracking()
        }
    } else {
        Logger.log("✅ Aucune session locale active", category: .session)
    }
}

private func resetTracking() async {
    activeTrackingSession = nil
    trackingState = .idle
    locationProvider.stopUpdating()
    durationTimer?.invalidate()
    autoSaveTask?.cancel()
    // ...
}
```

Appeler cette méthode dans `AppDelegate` ou dans la vue racine au démarrage.

---

#### Fix #2 : **Ajouter un timeout automatique sur les sessions**

```swift
// Dans SessionService.swift - Améliorer endSession()
func endSessionWithTimeout(sessionId: String, reason: String) async throws {
    Logger.log("⏱️ Fin de session avec raison: \(reason)", category: .session)
    try await endSession(sessionId: sessionId)
}

// Cloud Function Firebase (optionnel) - À déclencher toutes les heures
// Pseudo-code :
exports.cleanupStaleSessions = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
    const fourHoursAgo = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() - 4 * 60 * 60 * 1000)
    );
    
    const staleSessions = await admin.firestore()
        .collection('sessions')
        .where('status', 'in', ['active', 'paused', 'scheduled'])
        .where('startedAt', '<', fourHoursAgo)
        .get();
    
    staleSessions.forEach(doc => {
        doc.ref.update({
            status: 'ended',
            endedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });
});
```

---

#### Fix #3 : **Détecter et afficher les sessions corrompues dans l'UI**

```swift
// Dans SquadSessionsListView.swift
@State private var corruptedSessionsCount = 0

private func detectCorruptedSessions() async {
    guard let squadId = squad.id else { return }
    
    let allSessions = try? await db.collection("sessions")
        .whereField("squadId", isEqualTo: squadId)
        .whereField("status", "!=", SessionStatus.ended.rawValue)
        .getDocuments()
    
    let count = allSessions?.documents.count ?? 0
    let displayedCount = activeSessions.count
    
    corruptedSessionsCount = count - displayedCount
    
    if corruptedSessionsCount > 0 {
        Logger.log("⚠️ \(corruptedSessionsCount) session(s) corrompue(s) détectée(s)", category: .ui)
    }
}

// UI
if corruptedSessionsCount > 0 {
    Button("🧹 Nettoyer les sessions corrompues (\(corruptedSessionsCount))") {
        Task {
            try? await SessionService.shared.cleanupCorruptedSessions(squadId: squad.id!)
            await loadSessions()
        }
    }
    .buttonStyle(.bordered)
}
```

---

## 🎯 Recommandation Immédiate

### Pour débloquer maintenant :

1. ✅ **Supprimez manuellement la session dans Firebase Console**
2. ✅ **Mettez `hasActiveSessions = false` dans le document squad**
3. ✅ **Force-quit l'application** (pour réinitialiser TrackingManager)
4. ✅ **Relancez et testez**

### Pour éviter le problème à l'avenir :

1. 🔧 **Ajoutez la fonction `cleanupCorruptedSessions()`** dans SessionService
2. 🔧 **Ajoutez `reconcileWithFirestore()`** dans TrackingManager
3. 🔧 **Appelez `reconcileWithFirestore()` au démarrage de l'app**
4. 🔧 **Ajoutez un timeout de 4h sur les sessions** (Cloud Function ou local)

---

## 📊 Logs à Surveiller

Après avoir nettoyé la session corrompue, créez une nouvelle session et surveillez ces logs :

```
[AUDIT-TM-01] 🚀 TrackingManager.startTracking appelé
[AUDIT-TM-01-DEBUG] 📋 Session reçue:
   - id: [DOIT ÊTRE NON-NIL]
   - manualId: [DOIT ÊTRE NON-NIL]
   - realId: [DOIT ÊTRE NON-"ID_MANQUANT"]
   
[AUDIT-SDV-START-06] ✅ Session rechargée - id: [...], manualId: [...], realId: [...]
[AUDIT-SDV-START-09] 🏃 Démarrage TrackingManager...
[AUDIT-SDV-START-10] ✅✅ Tracking démarré avec succès!
```

Si vous voyez `ID_MANQUANT` ou des IDs `NIL`, c'est un problème de chargement depuis Firestore.

---

## ✅ Checklist de Validation Post-Fix

Après avoir nettoyé et redémarré :

- [ ] Je peux créer une nouvelle session
- [ ] La session apparaît dans "Sessions Actives"
- [ ] Le bouton "Terminer" fonctionne (pour le créateur)
- [ ] Le tracking GPS démarre correctement
- [ ] Après avoir terminé, la session disparaît de "Sessions Actives"
- [ ] La session apparaît dans "Historique"
- [ ] Le champ `hasActiveSessions` du squad est correct

---

## 🔗 Fichiers Concernés

| Fichier | Ligne | Description |
|---------|-------|-------------|
| `SessionService.swift` | 261-300 | Filtrage sessions actives |
| `SquadSessionsListView.swift` | 114-125 | Query Firestore pour sessions actives |
| `TrackingManager.swift` | 140-180 | Démarrage du tracking |
| `SessionDetailView.swift` | 413-430 | Validation `canEndSession` |
| `CreateSessionWithProgramView.swift` | N/A | Vérification avant création |

---

## 💡 Questions de Diagnostic

Si le problème persiste après le nettoyage, vérifiez :

1. **Dans Firebase Console :**
   - Y a-t-il encore des sessions avec `status != ended` pour ce squad ?
   - Le champ `hasActiveSessions` du squad est-il correct ?

2. **Dans les logs Xcode :**
   - Voyez-vous `[AUDIT-SSL-01] 🔄 SquadSessionsListView.loadSessions - Cache invalidé` ?
   - Voyez-vous `✅ Sessions chargées: X actives, Y historique` ?

3. **Dans l'UI :**
   - Faites un **pull-to-refresh** dans la liste des sessions
   - Vérifiez si le badge "Session active" apparaît sur le card du squad

---

**Voulez-vous que je crée les fonctions de nettoyage automatique ?**  
Ou préférez-vous d'abord tester le nettoyage manuel et revenir si le problème persiste ?
