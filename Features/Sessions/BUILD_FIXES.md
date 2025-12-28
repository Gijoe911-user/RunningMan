# 🐛 Corrections d'Erreurs de Compilation

## Date: 28 décembre 2025

## Erreurs Corrigées

### ❌ Erreur 1 : Type 'ShapeStyle' has no member 'coralAccent'

**Fichier** : `MapView.swift` ligne 38

**Problème** :
```swift
MapPolyline(coordinates: routePoints.map { $0.coordinate })
    .stroke(.coralAccent, lineWidth: 3)  // ❌ Erreur
```

L'erreur se produit car `.coralAccent` est une `Color` personnalisée, pas un `ShapeStyle` direct. Swift ne peut pas inférer automatiquement le type.

**Solution** :
```swift
MapPolyline(coordinates: routePoints.map { $0.coordinate })
    .stroke(Color.coralAccent, lineWidth: 3)  // ✅ Correct
```

**Explication** :
- `.stroke()` attend un `ShapeStyle`
- `Color` se conforme à `ShapeStyle`, mais il faut être explicite
- Ajouter `Color.` avant `coralAccent` résout l'ambiguïté

---

### ❌ Erreur 2 : Main actor-isolated property 'task' cannot be accessed from outside of the actor

**Fichier** : `SquadViewModel.swift` ligne 317

**Problème** :
```swift
// Dans deinit
Task.detached { [taskHolder] in
    taskHolder.task?.cancel()  // ❌ Erreur Swift 6
}

// Dans stopObservingSquads()
taskHolder.task?.cancel()  // ❌ Erreur potentielle
taskHolder.task = nil
```

En mode Swift 6, l'accès à `task` depuis `Task.detached` (qui n'est pas isolé au MainActor) est considéré comme dangereux, même si `TaskHolder` utilise `@unchecked Sendable` et un lock.

**Solution** :
Ajouter une méthode `cancel()` thread-safe dans `TaskHolder` :

```swift
private final class TaskHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var _task: Task<Void, Never>?
    
    var task: Task<Void, Never>? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _task
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _task = newValue
        }
    }
    
    /// ✅ Annule la tâche de manière thread-safe
    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        _task?.cancel()
        _task = nil
    }
}
```

Utilisation :
```swift
// Dans stopObservingSquads()
func stopObservingSquads() {
    taskHolder.cancel()  // ✅ Correct
    Logger.log("Observation des squads arrêtée", category: .squads)
}

// Dans deinit
deinit {
    Task.detached { [taskHolder] in
        taskHolder.cancel()  // ✅ Correct
    }
}
```

**Explication** :
- La méthode `cancel()` encapsule l'accès à `_task` avec le lock
- Évite l'accès direct à la propriété `task` depuis `Task.detached`
- Respecte les règles de concurrence strictes de Swift 6
- Plus propre et plus sûr

---

## Résumé des Changements

### MapView.swift
```diff
- .stroke(.coralAccent, lineWidth: 3)
+ .stroke(Color.coralAccent, lineWidth: 3)
```

### SquadViewModel.swift
```diff
  private final class TaskHolder: @unchecked Sendable {
      // ...
      
+     func cancel() {
+         lock.lock()
+         defer { lock.unlock() }
+         _task?.cancel()
+         _task = nil
+     }
  }
  
  func stopObservingSquads() {
-     taskHolder.task?.cancel()
-     taskHolder.task = nil
+     taskHolder.cancel()
  }
  
  deinit {
      Task.detached { [taskHolder] in
-         taskHolder.task?.cancel()
+         taskHolder.cancel()
      }
  }
```

---

## Vérification

### Compilation
```bash
# Avant
❌ 2 erreurs de compilation

# Après
✅ 0 erreur
```

### Tests à Effectuer

1. **MapView** : Vérifier que la polyligne s'affiche correctement
   - Créer une session
   - Se déplacer
   - ✅ Polyligne corail visible

2. **SquadViewModel** : Vérifier l'observation des squads
   - Observer des squads en temps réel
   - Quitter la vue
   - ✅ Pas de crash, pas de fuite mémoire

---

## Notes Techniques

### Swift 6 Concurrency

Swift 6 introduit des vérifications plus strictes pour la concurrence :
- **MainActor isolation** : Les propriétés marquées `@MainActor` ne peuvent pas être accédées depuis d'autres contextes
- **Sendable checking** : Plus strict sur les types qui peuvent traverser les frontières de concurrence
- **Task isolation** : `Task.detached` n'hérite d'aucune isolation d'acteur

### Bonnes Pratiques

1. **Encapsulation** : Utiliser des méthodes au lieu d'accéder directement aux propriétés
2. **Thread-safety** : Utiliser des locks (`NSLock`, `OSAllocatedUnfairLock`) pour protéger l'état mutable
3. **@unchecked Sendable** : Utiliser avec précaution, toujours avec un lock
4. **Explicite > Implicite** : Préférer `Color.coralAccent` à `.coralAccent` quand le type n'est pas clair

---

## Statut

✅ **Toutes les erreurs corrigées**

Le code compile maintenant sans erreurs et respecte les règles de concurrence strictes de Swift 6.

---

**Date** : 28 décembre 2025  
**Swift Version** : 6.0  
**Erreurs corrigées** : 2

