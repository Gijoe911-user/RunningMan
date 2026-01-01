# Fix: Boucle infinie dans SquadListView

## 🐛 Problème

Boucle infinie détectée quand on accède à l'onglet "Squads" dans `MainTabView`, bien que la liste des squads s'affiche correctement.

### Symptômes :
- La console affiche des logs en boucle
- L'app ralentit ou freeze
- La batterie se décharge rapidement
- Les squads sont visibles mais l'interface est instable

---

## 🔍 Causes possibles identifiées

### 1. **Logging dans le `body` de RootView** ✅ CORRIGÉ

**Problème :**
```swift
// ❌ AVANT - Log à chaque render
var body: some View {
    let _ = Logger.log("📍 RootView - ...", category: .ui)
    // ...
}
```

**Solution :**
```swift
// ✅ APRÈS - Log uniquement sur changements
.onChange(of: authVM.isAuthenticated) { oldValue, newValue in
    Logger.log("🔄 isAuthenticated changé: \(oldValue) -> \(newValue)", category: .ui)
}
.onChange(of: squadVM.hasSquads) { oldValue, newValue in
    Logger.log("🔄 hasSquads changé: \(oldValue) -> \(newValue)", category: .ui)
}
```

---

### 2. **Rechargement systématique dans `.task`** ✅ CORRIGÉ

**Problème :**
```swift
// ❌ AVANT - Recharge à chaque fois que la vue apparaît
.task {
    await squadVM.loadUserSquads()
    squadVM.startObservingSquads()
}
```

**Solution :**
```swift
// ✅ APRÈS - Charge seulement si nécessaire
.task {
    if !squadVM.hasAttemptedLoad {
        await squadVM.loadUserSquads()
    }
    // startObservingSquads() temporairement désactivé
}
```

---

### 3. **Stream Firebase en temps réel** ⚠️ DÉSACTIVÉ TEMPORAIREMENT

**Problème potentiel :**
Le stream `squadService.streamUserSquads()` pourrait émettre trop fréquemment, déclenchant des mises à jour en cascade.

**Solution temporaire :**
```swift
// 🔥 TEMPORAIRE : Désactivé pour isoler le problème
// squadVM.startObservingSquads()
```

**TODO :** Investiguer pourquoi le stream Firebase boucle

---

## ✅ Corrections appliquées

### 1. **RootView.swift**

```swift
var body: some View {
    Group {
        // ... logique de navigation
    }
    // ✅ onChange au lieu de logging dans body
    .onChange(of: authVM.isAuthenticated) { old, new in
        Logger.log("🔄 isAuthenticated: \(old) -> \(new)", category: .ui)
    }
    .onChange(of: squadVM.hasAttemptedLoad) { old, new in
        Logger.log("🔄 hasAttemptedLoad: \(old) -> \(new)", category: .ui)
    }
    .onChange(of: squadVM.hasSquads) { old, new in
        Logger.log("🔄 hasSquads: \(old) -> \(new)", category: .ui)
    }
    .onChange(of: authVM.isLoading) { old, new in
        Logger.log("🔄 isLoading: \(old) -> \(new)", category: .ui)
    }
}
```

### 2. **SquadsListView.swift**

```swift
.task {
    // ✅ Charger seulement si pas déjà fait
    if !squadVM.hasAttemptedLoad {
        await squadVM.loadUserSquads()
    }
    
    // 🔥 TEMPORAIRE : Désactivé pour éviter la boucle
    // squadVM.startObservingSquads()
}
.onDisappear {
    // squadVM.stopObservingSquads()
}
```

---

## 🧪 Tests à effectuer

### Test 1 : Vérifier que la boucle est stoppée

1. Lancer l'app
2. Aller dans l'onglet "Squads"
3. Observer la console :
   - ✅ Les squads se chargent une seule fois
   - ✅ Pas de logs répétés en boucle
   - ✅ L'interface reste fluide

### Test 2 : Vérifier le rafraîchissement manuel

1. Dans l'onglet Squads, faire un pull-to-refresh
2. Vérifier que les squads se rechargent correctement
3. Pas de boucle déclenchée

### Test 3 : Vérifier la navigation

1. Cliquer sur une squad dans la liste
2. Vérifier que `SquadDetailView` s'affiche
3. Revenir à la liste
4. Pas de rechargement inutile

---

## 🔧 Diagnostic avancé si le problème persiste

Si la boucle continue, vérifier :

### 1. **Logs dans la console**

Chercher des patterns répétitifs :
```
🔄 hasSquads changé: true -> true  ← ANORMAL
🔄 hasSquads changé: true -> true
🔄 hasSquads changé: true -> true
```

### 2. **Instruments (Time Profiler)**

Utiliser Xcode Instruments pour identifier :
- Les fonctions appelées en boucle
- Les mises à jour SwiftUI excessives

### 3. **Breakpoints conditionnels**

Placer des breakpoints dans :
- `SquadViewModel.loadUserSquads()`
- `SquadViewModel.startObservingSquads()`
- `SquadCard.body`

Et compter le nombre d'appels.

### 4. **Vérifier SquadService.streamUserSquads()**

Le stream Firebase pourrait émettre en boucle :
```swift
// Dans SquadService
func streamUserSquads(userId: String) -> AsyncStream<[SquadModel]> {
    // Ajouter des logs ici pour voir la fréquence
    Logger.log("📡 Stream emit pour userId: \(userId)", category: .squads)
    // ...
}
```

---

## 🎯 Solution permanente (TODO)

### Option 1 : Débouncing du stream

Limiter la fréquence des mises à jour du stream :
```swift
func startObservingSquads() {
    // ...
    for await squads in stream {
        // Attendre 500ms avant de mettre à jour
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Vérifier si les données ont vraiment changé
        guard squads != self.userSquads else { continue }
        
        self.userSquads = squads
    }
}
```

### Option 2 : Cache intelligent

Ne mettre à jour que si les données changent :
```swift
func startObservingSquads() {
    // ...
    for await squads in stream {
        // Comparer avec l'état actuel
        if squads != self.userSquads {
            self.userSquads = squads
            Logger.log("✅ Squads mises à jour", category: .squads)
        }
    }
}
```

### Option 3 : Snapshot listener avec diffing

Utiliser le listener Firebase avec `includeMetadataChanges: false` :
```swift
// Dans SquadService
db.collection("users").document(userId)
    .addSnapshotListener(includeMetadataChanges: false) { snapshot, error in
        // Ne déclenche que sur changements réels
    }
```

---

## 📋 Checklist

- [x] Supprimer logging dans `body` de RootView
- [x] Ajouter condition dans `.task` de SquadListView
- [x] Désactiver temporairement `startObservingSquads()`
- [ ] Tester l'app pour confirmer que la boucle est stoppée
- [ ] Investiguer `SquadService.streamUserSquads()`
- [ ] Implémenter débouncing ou diffing
- [ ] Réactiver le real-time updates
- [ ] Tests de performance

---

## 📊 État actuel

| Composant | Status | Notes |
|-----------|--------|-------|
| RootView | ✅ Corrigé | onChange au lieu de logging dans body |
| SquadsListView | ✅ Corrigé | Chargement conditionnel |
| Real-time updates | ⚠️ Désactivé | À investiguer et réactiver |
| Build | ✅ OK | Compile sans erreur |

---

## 🚀 Prochaines étapes

1. **Tester l'app** pour confirmer que la boucle est stoppée
2. **Partager les logs** si le problème persiste
3. **Investiguer le stream Firebase** pour comprendre pourquoi il boucle
4. **Implémenter une solution permanente** (débouncing ou diffing)
5. **Réactiver le real-time updates** une fois corrigé

---

## 💡 Notes

- Le **pull-to-refresh** fonctionne toujours via `.refreshable`
- Les squads sont **chargés au premier affichage**
- Le **real-time** sera réactivé une fois le problème du stream résolu
- Les **performances** devraient être améliorées sans le stream actif
