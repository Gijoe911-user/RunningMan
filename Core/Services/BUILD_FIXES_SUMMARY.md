# Corrections des erreurs de build

## ✅ Corrections effectuées dans `SessionsListView.swift`

### 1. **Erreur : `Value of type 'SquadViewModel' has no member 'squads'`**
- **Problème** : Tentative d'accéder à `.squads` au lieu de `.userSquads`
- **Correction** : Remplacé par `squadsVM.userSquads`
- **Ligne** : ~285

### 2. **Erreur : `Type 'SessionStatus' has no member 'completed'`**
- **Problème** : `SessionStatus` n'a que 3 états : `.scheduled`, `.active`, `.paused`
- **Correction** : Supprimé les cas `.completed` et `.cancelled`
- **Lignes** : ~407, ~409, ~422, ~424

### 3. **Erreur : `Value of type 'SessionModel' has no member 'totalDistance'`**
- **Problème** : La propriété s'appelle `distanceMeters` et non `totalDistance`
- **Correction** : Remplacé par `session.distanceMeters`
- **Ligne** : ~368

### 4. **Erreur : `Value of type 'SessionModel' has no member 'duration'`**
- **Problème** : La propriété s'appelle `durationSeconds` et non `duration`
- **Correction** : Remplacé par `session.durationSeconds`
- **Ligne** : ~373

### 5. **Warning : Variable 'squadId' was defined but never used**
- **Problème** : `let squadId = ...` non utilisé
- **Correction** : Simplifié en `if squadsVM.selectedSquad != nil`
- **Ligne** : ~161

### 6. **Warning : 'catch' block is unreachable**
- **Problème** : Le `do-catch` global n'était pas nécessaire
- **Correction** : Déplacé le `try-catch` à l'intérieur de la boucle
- **Ligne** : ~305

## ⚠️ Avertissements à corriger ultérieurement (non bloquants)

### RouteTrackingService.swift (~146)
```swift
// Remplacer:
var routeData = ...
// Par:
let routeData = ...
```

### SessionHistoryViewModel.swift (~59-64)
```swift
// Les constantes stats, route, users sont inférées comme '()'
// Vérifier l'implémentation de ces fonctions async
```

### CreateSessionWithProgramView.swift (~163, ~267)
```swift
// Variable 'race' définie mais jamais utilisée
// Remplacer par _ ou supprimer
```

### HealthKitManager.swift (~480)
```swift
// HKWorkout init déprécié iOS 17
// Utiliser HKWorkoutBuilder à la place
```

### SessionsViewModel.swift (~350)
```swift
// Résultat de requestAuthorization() non utilisé
// Ajouter _ = await ... ou gérer le résultat
```

### SessionRecoveryManager.swift (~41)
```swift
// Variable 'userId' définie mais jamais utilisée
// Simplifier la condition
```

## 🔴 Erreurs Swift 6 (TrackingManager.swift)

### Problème : `NSLock.lock()` unavailable from async contexts

**Lignes** : ~145, ~147, ~446, ~448, ~515, ~518, ~541, ~543

**Solution recommandée** : Utiliser un `actor` au lieu de `NSLock` pour la concurrence Swift 6 :

```swift
// Au lieu de:
class TrackingManager {
    private let lock = NSLock()
    
    func foo() async {
        lock.lock()
        defer { lock.unlock() }
        // ...
    }
}

// Utiliser:
actor TrackingManager {
    // Pas besoin de NSLock, l'isolation de l'actor gère la synchronisation
    
    func foo() async {
        // Le code est automatiquement thread-safe
    }
}
```

**OU** utiliser `os_unfair_lock` avec scoped locking :

```swift
import os

final class TrackingManager {
    private let lock = OSAllocatedUnfairLock<Void>()
    
    func foo() async {
        lock.withLock {
            // Code synchronisé
        }
    }
}
```

### Problème : Main actor-isolated initializer (~469)

```swift
// Ligne ~469
Task { @MainActor in
    let newInstance = MyClass() // ← Erreur si MyClass.init() est @MainActor
}

// Solution:
await MainActor.run {
    let newInstance = MyClass()
}
```

## 📋 Résumé

### ✅ Corrigé (build doit passer)
- [x] SessionsListView.swift - Toutes les erreurs corrigées
- [x] Utilisation de `userSquads` au lieu de `squads`
- [x] SessionStatus - Suppression des cas invalides
- [x] SessionModel - Propriétés correctes

### ⚠️ Warnings (non bloquants)
- [ ] RouteTrackingService - var → let
- [ ] SessionHistoryViewModel - Types inférés '()'
- [ ] CreateSessionWithProgramView - Variables non utilisées
- [ ] HealthKitManager - API dépréciée
- [ ] SessionsViewModel - Résultat non utilisé
- [ ] SessionRecoveryManager - Variable non utilisée

### 🔴 Swift 6 mode (à corriger pour migration future)
- [ ] TrackingManager - NSLock → Actor ou OSAllocatedUnfairLock
- [ ] TrackingManager - Main actor isolation

## 🧪 Test

Après ces corrections, le build devrait passer. Les warnings restants sont non-bloquants et peuvent être corrigés progressivement.

Pour tester :
1. Clean build folder (⌘⇧K)
2. Build (⌘B)
3. Vérifier qu'il n'y a plus d'erreurs rouges
4. Les warnings jaunes peuvent être ignorés temporairement
