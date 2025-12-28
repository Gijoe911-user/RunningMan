# 🔧 Fix : Erreur squadVM.squads

> **Erreur :** `Value of type 'SquadViewModel' has no member 'squads'`

---

## 🐛 Problème

Dans `AllSessionsView.swift`, le code utilise `squadVM.squads`, mais la propriété correcte est `squadVM.userSquads`.

---

## ✅ Solution

### Lignes à corriger dans `AllSessionsView.swift`

**Ligne ~291 :**
```swift
// AVANT
private var squadsWithActiveSessions: [SquadModel] {
    squadVM.squads.filter { $0.hasActiveSessions }  // ❌
}

// APRÈS
private var squadsWithActiveSessions: [SquadModel] {
    squadVM.userSquads.filter { $0.hasActiveSessions }  // ✅
}
```

**Ligne ~301 :**
```swift
// AVANT
let userSquads = squadVM.squads  // ❌

// APRÈS
let userSquads = squadVM.userSquads  // ✅
```

---

## 📝 Code complet corrigé

```swift
// MARK: - Computed Properties

private var squadsWithActiveSessions: [SquadModel] {
    squadVM.userSquads.filter { $0.hasActiveSessions }
}

// MARK: - Load Data

private func loadAllSessions() async {
    isLoading = true
    errorMessage = nil
    
    // Charger les sessions de TOUS les squads de l'utilisateur
    let userSquads = squadVM.userSquads
    
    guard !userSquads.isEmpty else {
        isLoading = false
        return
    }
    
    var allActiveSessions: [SessionModel] = []
    var allHistorySessions: [SessionModel] = []
    
    await withTaskGroup(of: (active: [SessionModel]?, history: [SessionModel]?).self) { group in
        for squad in userSquads {
            guard let squadId = squad.id else { continue }
            
            group.addTask {
                let active = try? await SessionService.shared.getActiveSessions(squadId: squadId)
                let history = try? await SessionService.shared.getSessionHistory(squadId: squadId, limit: 10)
                return (active, history)
            }
        }
        
        for await result in group {
            if let active = result.active {
                allActiveSessions.append(contentsOf: active)
            }
            if let history = result.history {
                allHistorySessions.append(contentsOf: history)
            }
        }
    }
    
    // Trier par date (plus récent en premier)
    activeSessions = allActiveSessions.sorted { $0.startedAt > $1.startedAt }
    recentHistory = allHistorySessions.sorted { ($0.endedAt ?? Date()) > ($1.endedAt ?? Date()) }
    
    Logger.logSuccess("✅ Chargé: \(activeSessions.count) actives, \(recentHistory.count) historique", category: .service)
    isLoading = false
}
```

---

## 🔍 Explication

### SquadViewModel a ces propriétés :

```swift
@Observable
class SquadViewModel {
    var userSquads: [SquadModel] = []  // ✅ Correcte
    var selectedSquad: SquadModel?
    // ...
}
```

**Pas de propriété `squads`**, seulement `userSquads`.

---

## 🧪 Test après correction

1. Ouvrir `AllSessionsView.swift`
2. Remplacer les 2 occurrences de `squadVM.squads` par `squadVM.userSquads`
3. Build : `Cmd + B`
4. **Résultat attendu :** Compilation réussie ✅

---

## 📋 Checklist

- [ ] Ouvrir `AllSessionsView.swift` dans Xcode
- [ ] Ligne ~291 : `squadVM.squads` → `squadVM.userSquads`
- [ ] Ligne ~301 : `squadVM.squads` → `squadVM.userSquads`
- [ ] Build : `Cmd + B`
- [ ] Vérifier qu'il n'y a plus d'erreurs

---

**Date :** 28 Décembre 2025

