# Checklist : Vérification des ViewModels pour problèmes similaires

## ViewModels à vérifier

### ✅ SquadViewModel
- [x] TaskHolder supprimé
- [x] Task stockée directement comme propriété
- [x] deinit simplifié
- [x] Gestion d'erreur dans la boucle async
- [x] Protection contre les appels multiples
- [x] `[weak self]` ajouté dans les closures

### ⚠️ SessionViewModel (À vérifier)

Recherchez les patterns suivants :

1. **Listeners Firestore**
   ```swift
   // Mauvais pattern
   private let taskHolder = TaskHolder()
   
   // Bon pattern
   private var observationTask: Task<Void, Never>?
   ```

2. **Boucles async**
   ```swift
   // Ajouter gestion d'erreur
   do {
       for await data in stream {
           guard !Task.isCancelled else { break }
           // traitement
       }
   } catch {
       Logger.logError(error, context: "...", category: ...)
   }
   ```

3. **deinit**
   ```swift
   // Simple et efficace
   deinit {
       observationTask?.cancel()
   }
   ```

### ⚠️ LocationService (À vérifier)

Le LocationService utilise des delegates et CLLocationManager qui peuvent aussi causer des problèmes :

1. **Vérifier le nettoyage**
   ```swift
   func stopUpdatingLocation() {
       locationManager.stopUpdatingLocation()
       locationManager.delegate = nil // IMPORTANT
   }
   ```

2. **Vérifier le cycle de vie**
   ```swift
   deinit {
       stopUpdatingLocation()
   }
   ```

### ⚠️ Autres services avec listeners

- AuthService
- NotificationService
- Tous les services utilisant Combine, AsyncStream ou delegates

## Pattern de correction standard

### 1. Déclaration de la propriété

```swift
// Dans la classe @MainActor @Observable
private var observationTask: Task<Void, Never>?
// OU pour plusieurs tâches
private var locationTask: Task<Void, Never>?
private var squadTask: Task<Void, Never>?
```

### 2. Fonction start avec protection

```swift
func startObserving() {
    guard observationTask == nil else {
        Logger.log("Listener déjà actif", category: ....)
        return
    }
    
    observationTask = Task { @MainActor [weak self] in
        guard let self else { return }
        
        let stream = service.streamData()
        
        do {
            for await data in stream {
                guard !Task.isCancelled else {
                    Logger.log("Observation annulée", category: ....)
                    break
                }
                
                // Traitement des données
                self.updateData(data)
            }
        } catch {
            Logger.logError(error, context: "startObserving", category: ....)
        }
        
        Logger.log("Stream terminé", category: ....)
    }
}
```

### 3. Fonction stop

```swift
func stopObserving() {
    observationTask?.cancel()
    observationTask = nil
    Logger.log("Observation arrêtée", category: ....)
}
```

### 4. deinit simplifié

```swift
deinit {
    observationTask?.cancel()
    // Nettoyer d'autres ressources si nécessaire
}
```

## Problèmes à éviter

### ❌ Ne JAMAIS faire

1. **Task.detached dans deinit**
   ```swift
   // ❌ MAUVAIS
   deinit {
       Task.detached {
           self.cleanup()
       }
   }
   ```

2. **@unchecked Sendable sans raison valable**
   ```swift
   // ❌ MAUVAIS - cache des problèmes
   class Wrapper: @unchecked Sendable {
       var data: SomeType
   }
   ```

3. **NSLock manuel pour des Tasks**
   ```swift
   // ❌ MAUVAIS - risque de deadlock
   private let lock = NSLock()
   lock.lock()
   defer { lock.unlock() }
   ```

4. **Boucle async sans gestion d'erreur**
   ```swift
   // ❌ MAUVAIS
   for await data in stream {
       // Si stream échoue, la tâche reste bloquée
   }
   ```

### ✅ À faire

1. **Stocker les Tasks directement**
   ```swift
   // ✅ BON
   private var task: Task<Void, Never>?
   ```

2. **Toujours utiliser weak self**
   ```swift
   // ✅ BON
   Task { @MainActor [weak self] in
       guard let self else { return }
       // ...
   }
   ```

3. **Gérer les erreurs**
   ```swift
   // ✅ BON
   do {
       for await data in stream {
           // traitement
       }
   } catch {
       Logger.logError(error, ...)
   }
   ```

4. **Vérifier l'annulation**
   ```swift
   // ✅ BON
   guard !Task.isCancelled else { break }
   ```

## Tests après correction

Pour chaque ViewModel corrigé, effectuer ces tests :

1. **Test de création/destruction rapide**
   - Ouvrir et fermer la vue 10 fois rapidement
   - Vérifier qu'il n'y a pas de crash
   - Vérifier dans la console que les listeners se nettoient

2. **Test de changement d'état**
   - Changer rapidement entre différents états
   - Vérifier qu'il n'y a pas de comportement étrange

3. **Test de déconnexion**
   - Se déconnecter pendant qu'une opération est en cours
   - Vérifier que l'app ne crash pas

4. **Instruments - Leaks**
   - Lancer l'app avec Instruments (Leaks)
   - Utiliser l'app normalement pendant 5 minutes
   - Vérifier qu'il n'y a pas de fuites mémoire

5. **Console Xcode**
   - Vérifier que les logs montrent :
     - ✅ "Listener créé"
     - ✅ "Listener arrêté"
     - ✅ "Stream terminé"
   - Pas de warnings ou d'erreurs répétées

## Commandes Xcode utiles

### Voir tous les listeners actifs

Dans la console de débogage :
```
(lldb) po Firestore.firestore().listenerCount
```

### Breakpoint symbolique

Mettre un breakpoint sur :
- `NSLock.lock`
- `Task.cancel`
- Pour détecter les problèmes de concurrence

### Memory Graph Debugger

1. Lancer l'app
2. Product → Debug → Memory Graph
3. Chercher les cycles de rétention
4. Vérifier que les ViewModels sont bien détruits

## Prochaines actions

1. [ ] Auditer SessionViewModel
2. [ ] Auditer LocationService
3. [ ] Auditer AuthService
4. [ ] Créer des tests unitaires pour les cycles de vie
5. [ ] Documenter les bonnes pratiques dans le README
6. [ ] Former l'équipe sur ces patterns

## Ressources

- [Swift Concurrency: Task Management](https://developer.apple.com/documentation/swift/task)
- [Actor isolation in Swift](https://developer.apple.com/documentation/swift/actor)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
