# ⚡️ QUICK REFERENCE - Nettoyage Sessions

## 🎯 Commandes Rapides

### Déblocage Immédiat (Sans Code)

```
1. Firebase Console → sessions
2. Trouver session avec status != "ended"
3. Supprimer document
4. squads → Mettre hasActiveSessions = false
5. Force-quit app
```

**Temps : 2 minutes**

---

## 🛠️ Code Snippets

### Nettoyage Automatique (depuis l'app)

```swift
// Dans n'importe quelle vue
Button("🧹 Nettoyer Squad") {
    Task {
        let count = try await SessionService.shared.cleanupCorruptedSessions(
            squadId: squad.id!
        )
        print("✅ \(count) session(s) nettoyée(s)")
    }
}
```

---

### Diagnostic d'une Session

```swift
// Affiche tous les détails dans les logs
Task {
    await SessionService.shared.diagnoseSession(sessionId: "abc123")
}
```

**Logs attendus :**
```
🔍 === DIAGNOSTIC SESSION: abc123 ===
✅ Session décodée avec succès
   - ID: abc123
   - realId: abc123
   - status: active
   - Temps écoulé: 2.5h
   - participants: 3
🔍 === FIN DIAGNOSTIC ===
```

---

### Réconciliation TrackingManager

```swift
// Dans la vue racine (.task {})
let hadZombie = await TrackingManager.shared.reconcileWithFirestore()
if hadZombie {
    print("⚠️ Session zombie nettoyée au démarrage")
}
```

---

### Détecter les Zombies (sans modifier)

```swift
// Retourne les IDs des sessions zombies
let zombieIds = try await SessionService.shared.detectZombieSessions(
    squadId: "squad123"
)
print("⚠️ \(zombieIds.count) zombie(s) détecté(s)")
```

---

## 📊 Logs à Chercher

### Succès de Nettoyage

```bash
# Dans console Xcode, chercher :
🧹 Démarrage nettoyage
✅ Nettoyage terminé: X session(s)
```

### Session Zombie Détectée

```bash
⏱️ Session zombie détectée: [id] (active depuis X.Xh)
🗑️ Session [id] supprimée
```

### Réconciliation OK

```bash
🔄 === RÉCONCILIATION TrackingManager
✅ Aucune session locale active, état cohérent
```

### Erreur Critique

```bash
❌❌ ERREUR CRITIQUE : Session ID est manquant
   - realId: ID_MANQUANT
```

➡️ **Action :** Vérifier que la session est chargée depuis Firestore avec `id` valide

---

## 🔍 Firebase Queries

### Trouver Sessions Actives d'un Squad

```
Collection: sessions
Filtres:
  - squadId == "abc123"
  - status in ["scheduled", "active", "paused"]
```

### Trouver Sessions Zombies (> 4h)

```
Collection: sessions
Filtres:
  - status != "ended"
  - startedAt < (now - 4 hours)
```

---

## 🧪 Tests Rapides

### Test #1 : Créer/Terminer Session

```swift
// 1. Créer
let session = try await SessionService.shared.createSession(
    squadId: "squad123",
    creatorId: "user456"
)
print("✅ Session créée: \(session.id)")

// 2. Terminer
try await SessionService.shared.endSession(sessionId: session.realId)
print("✅ Session terminée")
```

---

### Test #2 : Simuler Zombie

```swift
// Dans Firebase Console :
// 1. Créer session avec startedAt = il y a 5h
// 2. status = "active"

// Dans l'app :
let zombies = try await SessionService.shared.detectZombieSessions(squadId: "squad123")
print("Zombies détectés: \(zombies)")

let cleaned = try await SessionService.shared.cleanupCorruptedSessions(squadId: "squad123")
print("Sessions nettoyées: \(cleaned)")
```

---

## 🎯 Checklist de Déblocage

### Étape 1 : Identifier

- [ ] Ouvrir Firebase Console
- [ ] Chercher sessions avec `status != ended`
- [ ] Noter le `squadId` et `sessionId`

### Étape 2 : Supprimer

- [ ] Supprimer document session
- [ ] Mettre `hasActiveSessions = false` dans squad
- [ ] Vérifier suppression (F5 dans console)

### Étape 3 : Valider

- [ ] Force-quit app
- [ ] Relancer
- [ ] Essayer créer nouvelle session
- [ ] Vérifier tracking démarre

---

## ⚙️ Configuration

### Changer Timeout (4h par défaut)

```swift
// SessionService.swift ligne ~930
let fourHoursAgo = Date().addingTimeInterval(-14400)  // 4h

// Changer à 2 heures :
let twoHoursAgo = Date().addingTimeInterval(-7200)

// Changer à 1 heure :
let oneHourAgo = Date().addingTimeInterval(-3600)
```

---

### Ajouter Nettoyage Périodique

```swift
// Dans AppDelegate ou ContentView
Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
    Task {
        for squad in squads {
            try? await SessionService.shared.cleanupCorruptedSessions(
                squadId: squad.id!
            )
        }
    }
}
```

**Intervalle recommandé :** 1 heure (3600s)

---

## 🆘 Dépannage Express

### Problème : Badge rouge ne s'affiche pas

```swift
// Forcer la détection
Task {
    await detectZombieSessions()
    print("Zombies détectés: \(zombieSessionsCount)")
}
```

---

### Problème : TrackingManager bloqué

```swift
// Forcer la réconciliation
Task {
    let cleaned = await TrackingManager.shared.reconcileWithFirestore()
    print("État nettoyé: \(cleaned)")
    print("État actuel: \(TrackingManager.shared.trackingState)")
}
```

---

### Problème : Session ID manquant

```swift
// Vérifier la session
if session.realId == "ID_MANQUANT" {
    print("❌ Session sans ID - Recharger depuis Firestore")
    
    // Recharger
    if let reloaded = try await SessionService.shared.getSession(
        sessionId: session.manualId ?? ""
    ) {
        print("✅ Session rechargée: \(reloaded.realId)")
    }
}
```

---

## 📱 UI Badge Rouge

### SquadSessionsListView

Le badge apparaît automatiquement si zombies détectés :

```swift
.toolbar {
    if zombieSessionsCount > 0 {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showCleanupConfirmation = true } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("\(zombieSessionsCount)")
                }
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .clipShape(Capsule())
            }
        }
    }
}
```

---

## 🔗 Documentation Complète

| Fichier | Description | Audience |
|---------|-------------|----------|
| `ACTIONS_IMMEDIATES.md` | Déblocage rapide | Tous |
| `GUIDE_NETTOYAGE_SESSIONS.md` | Guide détaillé | Utilisateurs |
| `DIAGNOSTIC_SESSION_BLOQUEE.md` | Analyse technique | Développeurs |
| `RESUME_EXECUTIF.md` | Résumé technique | Lead Dev |
| `CHANGELOG_SESSION_FIX.md` | Historique | Tous |
| `QUICK_REFERENCE.md` | Ce fichier | Développeurs |

---

## 🎓 Exemples Complets

### Exemple 1 : Nettoyage Complet d'un Squad

```swift
import SwiftUI

struct AdminCleanupView: View {
    let squad: SquadModel
    @State private var cleaning = false
    @State private var result: String?
    
    var body: some View {
        VStack {
            Button("🧹 Nettoyer Squad") {
                Task {
                    cleaning = true
                    do {
                        let count = try await SessionService.shared
                            .cleanupCorruptedSessions(squadId: squad.id!)
                        result = "✅ \(count) session(s) nettoyée(s)"
                    } catch {
                        result = "❌ Erreur: \(error)"
                    }
                    cleaning = false
                }
            }
            .disabled(cleaning)
            
            if let result = result {
                Text(result)
            }
        }
    }
}
```

---

### Exemple 2 : Diagnostic Panel

```swift
struct DiagnosticView: View {
    @State private var sessionId = ""
    @State private var diagnosing = false
    
    var body: some View {
        VStack {
            TextField("Session ID", text: $sessionId)
                .textFieldStyle(.roundedBorder)
            
            Button("🔍 Diagnostiquer") {
                Task {
                    diagnosing = true
                    await SessionService.shared.diagnoseSession(sessionId: sessionId)
                    diagnosing = false
                }
            }
            .disabled(diagnosing || sessionId.isEmpty)
            
            Text("Voir les logs dans la console")
                .font(.caption)
        }
        .padding()
    }
}
```

---

### Exemple 3 : Réconciliation Auto au Démarrage

```swift
// Dans App.swift ou ContentView.swift
@main
struct RunningManApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Réconciliation au démarrage
                    let cleaned = await TrackingManager.shared.reconcileWithFirestore()
                    if cleaned {
                        Logger.log("⚠️ Session zombie nettoyée au démarrage", category: .app)
                    }
                }
        }
    }
}
```

---

## 🔐 Sécurité & Validation

### Avant de Supprimer une Session

```swift
// Vérifier les participants actifs
if let session = try await SessionService.shared.getSession(sessionId: id) {
    let activeCount = session.participantStates?.values.filter {
        $0.status == .active
    }.count ?? 0
    
    if activeCount > 0 {
        print("⚠️ ATTENTION : \(activeCount) participant(s) actif(s)")
        print("Confirmer la suppression ?")
    } else {
        print("✅ OK pour supprimer (aucun participant actif)")
    }
}
```

---

### Logs de Sécurité

Toutes les opérations de nettoyage sont loggées :

```
🧹 Démarrage nettoyage sessions pour squad: abc123
📋 3 session(s) non terminée(s) trouvée(s)
⏱️ Session zombie détectée: xyz789 (active depuis 5.2h)
✅ Session zombie terminée: xyz789
⚠️ Session corrompue détectée: bad123
🗑️ Session bad123 supprimée (corrompue)
✅ Nettoyage terminé: 2 session(s) nettoyée(s)
```

---

## ⚡️ Commandes Terminal (Firebase CLI)

### Lister Sessions Actives

```bash
firebase firestore:query sessions \
  --where 'status=="active"' \
  --limit 10
```

### Supprimer Session (ATTENTION)

```bash
firebase firestore:delete sessions/[SESSION_ID]
```

---

## 📞 Support

### Logs à Envoyer

Si vous avez besoin d'aide, collectez :

1. **Logs complets** depuis le démarrage
2. **Screenshot** de la session dans Firebase Console
3. **Résultat de `diagnoseSession()`**
4. **Version de l'app** et **iOS**

### Commande de Collecte

```swift
// Générer un rapport de diagnostic
Task {
    print("=== RAPPORT DIAGNOSTIC ===")
    
    // 1. État TrackingManager
    print("TrackingManager:")
    print("  - trackingState: \(TrackingManager.shared.trackingState)")
    print("  - activeSession: \(TrackingManager.shared.activeTrackingSession?.realId ?? "NIL")")
    
    // 2. Sessions actives
    let sessions = try await SessionService.shared.getActiveSessions(squadId: squadId)
    print("Sessions actives: \(sessions.count)")
    
    // 3. Zombies
    let zombies = try await SessionService.shared.detectZombieSessions(squadId: squadId)
    print("Zombies détectés: \(zombies.count)")
    print("  IDs: \(zombies)")
    
    print("=== FIN RAPPORT ===")
}
```

---

**Version :** 1.0  
**Date :** 2026-01-09  
**Compatibilité :** RunningMan v1.x
