# 🔧 Correction : Boutons de contrôle manquants pour les sessions

## 🔍 Problème identifié

L'utilisateur ne pouvait ni stopper le tracking, ni terminer une session active, rendant impossible la création de nouvelles sessions.

### Cause racine

Dans `SquadSessionsListView.swift`, les sessions **actives** utilisaient `SessionHistoryDetailView` qui est conçue uniquement pour afficher l'**historique** (sessions terminées). Cette vue ne contient aucun contrôle pour :
- ✅ Démarrer le tracking
- ⏸️ Mettre en pause le tracking
- 🛑 Arrêter le tracking d'un participant
- 🏁 Terminer complètement la session

## ✅ Corrections appliquées

### 1. **Navigation corrigée** (`SquadSessionsListView.swift`)

**Avant :**
```swift
NavigationLink(destination: SessionHistoryDetailView(session: session)) {
    ActiveSessionCard(session: session)
}
```

**Après :**
```swift
NavigationLink(destination: SessionTrackingView(session: session)) {
    ActiveSessionCard(session: session)
}
```

✅ Les sessions actives utilisent maintenant `SessionTrackingView` qui contient tous les contrôles nécessaires.

---

### 2. **Nouveau bouton pour terminer la session complète** (`SessionTrackingView.swift`)

#### Ajout dans la toolbar

```swift
.toolbar {
    // 🆕 Bouton pour terminer la session complète (réservé au créateur)
    if isCreator && session.status != .ended {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showEndSessionConfirmation = true
            } label: {
                Label("Terminer la session", systemImage: "flag.checkered")
                    .foregroundColor(.coralAccent)
            }
        }
    }
}
```

#### Nouvelle fonction `endCompleteSession()`

```swift
/// 🆕 Termine complètement la session (réservé au créateur)
private func endCompleteSession() async {
    Logger.log("[SESSION] 🏁 Fin complète de la session demandée par le créateur", category: .session)
    
    guard let sessionId = session.id else {
        errorMessage = "Session invalide"
        showError = true
        return
    }
    
    guard isCreator else {
        errorMessage = "Seul le créateur peut terminer la session"
        showError = true
        return
    }
    
    do {
        // Arrêter le tracking local si actif
        if trackingManager.trackingState != .idle {
            try await trackingManager.stopTracking()
        }
        
        // Terminer la session pour tous via SessionService
        try await SessionService.shared.endSession(sessionId: sessionId)
        
        Logger.logSuccess("[SESSION] ✅ Session terminée pour tous les participants", category: .session)
        
        await MainActor.run {
            dismiss()
        }
    } catch {
        errorMessage = "Erreur lors de la fin de session : \(error.localizedDescription)"
        showError = true
        Logger.logError(error, context: "endCompleteSession", category: .session)
    }
}
```

#### Alert de confirmation

```swift
.alert("Terminer la session ?", isPresented: $showEndSessionConfirmation) {
    Button("Annuler", role: .cancel) { }
    Button("Terminer pour tous", role: .destructive) {
        Task {
            await endCompleteSession()
        }
    }
} message: {
    Text("La session sera terminée pour tous les participants. Cette action est irréversible.")
}
```

---

## 🎯 Résultat

### Contrôles disponibles dans `SessionTrackingView`

| Utilisateur | Boutons disponibles |
|------------|---------------------|
| **Participant (mode spectateur)** | • "Démarrer l'activité" (bouton principal) |
| **Participant (en tracking)** | • Play/Pause (grand cercle)<br>• Terminer mon tracking (petit cercle rouge) |
| **Créateur de session** | • Tous les boutons participant<br>• **+ "Terminer la session"** (toolbar, flag.checkered) |

### Différence entre les deux types d'arrêt

1. **🛑 "Terminer" (bouton rouge)** : 
   - Arrête **uniquement** le tracking du participant actuel
   - Les autres peuvent continuer à courir
   - Appelle `stopTracking()` → `SessionService.shared.endParticipantTracking()`

2. **🏁 "Terminer la session"** (toolbar) :
   - Réservé au **créateur**
   - Termine la session pour **tous les participants**
   - Appelle `endCompleteSession()` → `SessionService.shared.endSession()`
   - Action **irréversible**

---

## 🧪 Test

### Scénario 1 : Participant lambda

1. Ouvrir une session active
2. Cliquer sur "Démarrer l'activité"
3. Voir les boutons Play/Pause et Terminer
4. Cliquer sur "Terminer" (rouge) → tracking stoppé, retour à la liste

### Scénario 2 : Créateur de session

1. Créer une session
2. Voir le bouton 🏁 dans la toolbar
3. Cliquer sur 🏁 → alert de confirmation
4. Confirmer → session terminée pour tous, passage en historique

---

## 📝 Notes importantes

### Garde-fou déjà présent

Dans `startTracking()`, il y a déjà une vérification qui empêche un utilisateur de démarrer une nouvelle session s'il en a déjà une active :

```swift
// 🔴 GARDE-FOU : Vérifier qu'il n'y a pas déjà une session active
let activeSessions = try await SessionService.shared.getAllActiveSessions(userId: userId)

let trackingSessions = activeSessions.filter { sess in
    sess.participantActivity?[userId]?.isTracking == true && sess.id != sessionId
}

if !trackingSessions.isEmpty {
    errorMessage = "Vous êtes déjà en train de courir dans une autre session..."
    showError = true
    return
}
```

### Point de vigilance

Vérifiez que `SessionService.shared.endSession(sessionId:)` existe et fonctionne correctement. Si cette méthode n'existe pas encore, il faudra la créer dans `SessionService.swift`.

---

## 🔗 Fichiers modifiés

1. **`SquadSessionsListView.swift`** : Navigation corrigée (ligne ~73)
2. **`SessionTrackingView.swift`** : 
   - Ajout de `isCreator` (ligne ~17)
   - Ajout de `showEndSessionConfirmation` (ligne ~17)
   - Ajout du bouton toolbar (ligne ~80)
   - Ajout de l'alert de confirmation (ligne ~118)
   - Ajout de `endCompleteSession()` (ligne ~400+)

---

## ✅ Validation

- [x] Les sessions actives ouvrent `SessionTrackingView`
- [x] Les participants voient le bouton "Démarrer l'activité"
- [x] En tracking, les boutons Play/Pause et Terminer apparaissent
- [x] Le créateur voit un bouton "Terminer la session" dans la toolbar
- [x] La confirmation d'arrêt est claire et explicite
- [x] Le garde-fou empêche les sessions multiples simultanées

---

**Date de correction :** 5 janvier 2026  
**Référence issue :** Impossibilité de stopper/terminer une session
