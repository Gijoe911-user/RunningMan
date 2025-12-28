# 🐛 Corrections d'Erreurs de Compilation - Mise à Jour

## Date: 28 décembre 2025

## ✅ Toutes les Erreurs Corrigées

### Erreur 1 : Type 'ShapeStyle' has no member 'coralAccent'

**Fichiers** : 
- `MapView.swift` ligne 38
- `RouteHistoryView.swift` ligne 51

**Solution** :
```diff
- .stroke(.coralAccent, lineWidth: 3)
+ .stroke(Color.coralAccent, lineWidth: 3)
```

---

### Erreur 2 : Value 'selectedRoute' was defined but never used

**Fichier** : `RouteHistoryView.swift` ligne 27

**Solution** :
```diff
- if let selectedRoute = selectedRoute {
+ if selectedRoute != nil {
      mapSection
          .frame(height: 300)
  }
```

**Explication** : On ne fait que tester l'existence, pas besoin de capturer la valeur.

---

### Erreur 3 : Main actor-isolated instance method 'cancel()' cannot be called

**Fichier** : `SquadViewModel.swift` ligne 316

**Solution** :
```diff
- func cancel() {
+ nonisolated func cancel() {
      lock.lock()
      defer { lock.unlock() }
      _task?.cancel()
      _task = nil
  }
```

**Explication** : `nonisolated` permet d'appeler la méthode depuis `Task.detached`. La sécurité thread est garantie par le `NSLock`.

---

## Statut Final

✅ **3/3 erreurs corrigées**
✅ **Le projet compile sans erreurs**
✅ **Compatible Swift 6**

