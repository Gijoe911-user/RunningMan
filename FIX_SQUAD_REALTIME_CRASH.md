# Correction du crash lié aux listeners temps réel

## Problème identifié

L'erreur système `syscall -> jae -> cerror_nocancel` indique un problème de gestion des ressources système, probablement lié aux listeners Firestore et à la gestion concurrente des tâches asynchrones.

### Causes principales :

1. **TaskHolder avec `@unchecked Sendable` et NSLock** : Complexité inutile qui peut causer des deadlocks
2. **Task.detached dans deinit** : Peut créer des race conditions lors de la destruction du ViewModel
3. **Pas de gestion d'erreur dans la boucle async** : Si le stream échoue, la tâche continue indéfiniment
4. **Listener Firestore non nettoyé proprement** : Peut accumuler des listeners actifs en mémoire

## Solutions appliquées

### 1. Simplification de la gestion des tâches

**Avant :**
```swift
private let taskHolder = TaskHolder()

deinit {
    Task.detached { [taskHolder] in
        taskHolder.cancel()
    }
}
```

**Après :**
```swift
private var observationTask: Task<Void, Never>?

deinit {
    observationTask?.cancel()
}
```

### 2. Amélioration de startObservingSquads()

**Changements :**
- Ajout de `[weak self]` pour éviter les retain cycles
- Ajout d'un bloc `do-catch` pour gérer les erreurs du stream
- Vérification que la squad sélectionnée existe toujours
- Gestion propre de l'annulation avec `Task.isCancelled`

```swift
observationTask = Task { @MainActor [weak self] in
    guard let self else { return }
    
    let stream = squadService.streamUserSquads(userId: userId)
    
    do {
        for await squads in stream {
            guard !Task.isCancelled else {
                Logger.log("Observation des squads annulée", category: .squads)
                break
            }
            
            // Mise à jour des squads...
            
            // Vérification que selectedSquad existe toujours
            if self.selectedSquad != nil && !squads.contains(where: { $0.id == self.selectedSquad?.id }) {
                self.selectedSquad = squads.first
            }
        }
    } catch {
        Logger.logError(error, context: "startObservingSquads loop", category: .squads)
    }
}
```

### 3. Suppression de TaskHolder

La classe `TaskHolder` avec ses locks manuels était source de problèmes :
- Risque de deadlock avec NSLock
- `@unchecked Sendable` masquait des problèmes de concurrence
- Complexité inutile pour un simple stockage de Task

## Actions supplémentaires recommandées

### 1. Vérifier l'appel à startObservingSquads()

Assurez-vous que cette fonction est appelée une seule fois :

```swift
// Dans la vue principale ou ContentView
.task {
    await viewModel.loadUserSquads()
    viewModel.startObservingSquads()
}
.onDisappear {
    viewModel.stopObservingSquads()
}
```

### 2. Ajouter une protection contre les appels multiples

```swift
func startObservingSquads() {
    guard let userId = currentUserId else { return }
    
    // NOUVEAU : Empêcher de créer plusieurs listeners
    guard observationTask == nil else {
        Logger.log("Listener déjà actif", category: .squads)
        return
    }
    
    observationTask = Task { @MainActor [weak self] in
        // ...
    }
}
```

### 3. Vérifier les autres ViewModels

Si vous avez d'autres ViewModels avec des patterns similaires (SessionViewModel, etc.), appliquez les mêmes corrections :

- Supprimer les TaskHolder
- Utiliser `private var task: Task<Void, Never>?`
- Ajouter `[weak self]` dans les closures de Task
- Gérer les erreurs dans les boucles `for await`
- Simplifier les `deinit`

### 4. Monitoring des listeners Firestore

Ajoutez du logging pour suivre le cycle de vie des listeners :

```swift
// Dans SquadService.streamUserSquads
AsyncStream { continuation in
    Logger.log("🎧 Création listener squads pour \(userId)", category: .squads)
    
    let reg = observeUserSquads(userId: userId) { result in
        // ...
    }
    
    continuation.onTermination = { _ in
        Logger.log("🛑 Destruction listener squads pour \(userId)", category: .squads)
        reg.remove()
    }
}
```

## Tests à effectuer

1. **Test de création/destruction rapide** : Ouvrir et fermer rapidement la vue des squads
2. **Test de déconnexion** : Se déconnecter pendant qu'une session est active
3. **Test de changement de squad** : Sélectionner différentes squads rapidement
4. **Monitoring mémoire** : Vérifier dans Xcode Instruments qu'il n'y a pas de fuite mémoire

## Indicateurs de succès

✅ Plus de crash système avec `syscall -> cerror_nocancel`
✅ Pas de fuite mémoire visible dans Instruments
✅ Les listeners se nettoient correctement dans la console
✅ Les mises à jour temps réel fonctionnent toujours
✅ Performance stable même après usage prolongé

## Prochaines étapes

1. Appliquer les mêmes corrections à `SessionViewModel` si applicable
2. Vérifier `LocationService` pour des problèmes similaires
3. Ajouter des tests unitaires pour la gestion du cycle de vie des ViewModels
4. Documenter les bonnes pratiques pour les listeners temps réel dans le projet
