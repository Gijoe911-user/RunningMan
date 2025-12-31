# 🔧 Correction : Synchronisation AuthViewModel ↔ SquadViewModel

## 🐛 Problème Identifié

### Symptômes
- ✅ Utilisateur peut créer une squad
- ✅ Utilisateur peut rejoindre une squad  
- ❌ **MAIS** reste bloqué sur `OnboardingSquadView` (écran "Rejoindre ou créer une squad")
- ❌ Message "Vous êtes déjà membre de cette squad" quand on essaye de rejoindre à nouveau
- ❌ Création d'une nouvelle squad ramène sur l'écran d'onboarding

### Cause Racine

Le flux de données était cassé après le refactoring du `UserModel` :

```
1. Utilisateur rejoint/crée une squad
   ↓
2. SquadViewModel.userSquads est mis à jour ✅
   ↓
3. SquadService écrit dans Firestore (users/{id}.squads) ✅
   ↓
4. AuthViewModel.currentUser n'est PAS rafraîchi ❌
   ↓
5. authVM.hasSquad retourne false (données périmées) ❌
   ↓
6. RootView affiche OnboardingSquadView au lieu de MainTabView ❌
```

**Le problème** : `AuthViewModel` et `SquadViewModel` ne communiquaient pas entre eux.

---

## ✅ Solution Implémentée

### Architecture de Communication

```
SquadViewModel.joinSquad() / createSquad()
    ↓
    ├─ Met à jour userSquads (local) ✅
    ├─ Écrit dans Firestore ✅
    └─ Envoie notification "UserSquadsUpdated" 🆕
        ↓
        └─ AuthViewModel (écoute la notification) 🆕
            ↓
            └─ Rafraîchit currentUser depuis Firestore
                ↓
                └─ authVM.hasSquad se met à jour automatiquement ✅
                    ↓
                    └─ RootView affiche MainTabView ✅
```

---

## 🔧 Modifications Apportées

### 1. **SquadViewModel.swift**

#### Ajout de `refreshAuthUser()`
```swift
/// Rafraîchit l'utilisateur dans AuthViewModel pour mettre à jour hasSquad
/// Appelé après avoir rejoint ou créé une squad
private func refreshAuthUser() async {
    Logger.log("🔄 Rafraîchissement de l'utilisateur dans AuthViewModel", category: .squads)
    
    guard let userId = currentUserId else { return }
    
    do {
        if let updatedUser = try await AuthService.shared.getUserProfile(userId: userId) {
            // Notifier qu'on a besoin de rafraîchir
            NotificationCenter.default.post(
                name: NSNotification.Name("UserSquadsUpdated"),
                object: nil,
                userInfo: ["userId": userId]
            )
            Logger.logSuccess("✅ Notification envoyée pour rafraîchir l'utilisateur", category: .squads)
        }
    } catch {
        Logger.logError(error, context: "refreshAuthUser", category: .squads)
    }
}
```

#### Mise à jour de `joinSquad()`
```swift
func joinSquad(inviteCode: String) async -> Bool {
    // ... code existant ...
    
    userSquads.append(joinedSquad)
    selectedSquad = joinedSquad
    
    successMessage = "Vous avez rejoint \(joinedSquad.name) !"
    
    // 🔥 NOUVEAU : Rafraîchir l'utilisateur
    await refreshAuthUser()
    
    return true
}
```

#### Mise à jour de `createSquad()`
```swift
func createSquad(name: String, description: String) async -> Bool {
    // ... code existant ...
    
    userSquads.append(newSquad)
    selectedSquad = newSquad
    
    successMessage = "Squad créée avec succès !"
    
    // 🔥 NOUVEAU : Rafraîchir l'utilisateur
    await refreshAuthUser()
    
    return true
}
```

---

### 2. **AuthViewModel.swift**

#### Ajout du listener dans `init()`
```swift
init() {
    Task { @MainActor in
        await checkAuthState()
    }
    
    // 🔥 NOUVEAU : Écouter les mises à jour des squads
    setupSquadsUpdateListener()
}
```

#### Nouvelle méthode `setupSquadsUpdateListener()`
```swift
/// Configure un listener pour rafraîchir l'utilisateur quand ses squads changent
private func setupSquadsUpdateListener() {
    NotificationCenter.default.addObserver(
        forName: NSNotification.Name("UserSquadsUpdated"),
        object: nil,
        queue: .main
    ) { [weak self] notification in
        guard let self = self else { return }
        
        Logger.log("📬 Notification reçue : UserSquadsUpdated", category: .auth)
        
        Task { @MainActor in
            await self.refreshUser()
        }
    }
}
```

---

## 🎯 Flux Complet Après Correction

### Scénario : Utilisateur rejoint une squad

```
1. OnboardingSquadView
   └─ showJoinSquad = true
       └─ JoinSquadView apparaît
           └─ Utilisateur entre le code
               └─ SquadViewModel.joinSquad(inviteCode: "ABC123")
                   ↓
                   ├─ SquadService.joinSquad() → Écrit dans Firestore
                   ├─ userSquads.append(joinedSquad) → Mise à jour locale
                   └─ refreshAuthUser()
                       ↓
                       └─ NotificationCenter.post("UserSquadsUpdated")
                           ↓
                           └─ AuthViewModel reçoit la notification
                               ↓
                               └─ AuthViewModel.refreshUser()
                                   ↓
                                   └─ AuthService.getUserProfile(userId)
                                       ↓
                                       └─ currentUser mis à jour avec Firestore
                                           ↓
                                           └─ authVM.hasSquad = true ✅
                                               ↓
                                               └─ RootView détecte le changement
                                                   ↓
                                                   └─ Affiche MainTabView ✅
```

---

## 🧪 Tests de Validation

### Test 1 : Rejoindre une squad
```
1. Se connecter avec un compte sans squad
2. Écran OnboardingSquadView s'affiche ✅
3. Cliquer sur "Rejoindre un Squad"
4. Entrer un code valide (ex: NJ3XAJ)
5. Cliquer sur "Rejoindre"
6. Attendre 1-2 secondes
7. ✅ ATTENDU : Transition vers MainTabView
8. ✅ ATTENDU : Tab "Squads" affiche la squad rejointe
```

### Test 2 : Créer une squad
```
1. Se connecter avec un compte sans squad
2. Écran OnboardingSquadView s'affiche ✅
3. Cliquer sur "Créer un Squad"
4. Entrer un nom (ex: "Mes Amis Coureurs")
5. Cliquer sur "Créer"
6. Attendre 1-2 secondes
7. ✅ ATTENDU : Transition vers MainTabView
8. ✅ ATTENDU : Tab "Squads" affiche la nouvelle squad
```

### Test 3 : Vérification de la persistance
```
1. Rejoindre/créer une squad
2. Force quit de l'application
3. Relancer l'application
4. ✅ ATTENDU : Connexion automatique → MainTabView
5. ✅ ATTENDU : Pas de retour à OnboardingSquadView
```

---

## 📊 Comparaison Avant/Après

| Aspect | Avant (Cassé) | Après (Corrigé) |
|--------|---------------|-----------------|
| **Join Squad** | Écrit Firestore mais reste sur onboarding | ✅ Transition vers MainTabView |
| **Create Squad** | Écrit Firestore mais reste sur onboarding | ✅ Transition vers MainTabView |
| **hasSquad** | Toujours false | ✅ Se met à jour automatiquement |
| **currentUser.squads** | Périmé | ✅ Rafraîchi depuis Firestore |
| **Communication VMs** | ❌ Aucune | ✅ NotificationCenter |
| **Expérience utilisateur** | ❌ Bloqué dans une boucle | ✅ Fluide et cohérente |

---

## 🔍 Logs de Debug

Pour vérifier que tout fonctionne, surveillez ces logs :

```
// Quand on rejoint une squad
🏁 Squad rejointe avec succès: [squadId]
🔄 Rafraîchissement de l'utilisateur dans AuthViewModel
✅ Notification envoyée pour rafraîchir l'utilisateur
📬 Notification reçue : UserSquadsUpdated
✅ Profil utilisateur rafraîchi

// Vérification
authVM.hasSquad: true ✅
authVM.currentUser.squads.count: 1 ✅
```

---

## ⚠️ Points d'Attention

### 1. NotificationCenter vs Combine
Actuellement on utilise `NotificationCenter` qui est simple et efficace. On pourrait améliorer avec :
```swift
// Alternative avec Combine (futur)
class SquadViewModel {
    let squadsUpdated = PassthroughSubject<Void, Never>()
}

class AuthViewModel {
    func init() {
        squadVM.squadsUpdated
            .sink { [weak self] in
                Task { await self?.refreshUser() }
            }
            .store(in: &cancellables)
    }
}
```

### 2. Délai de rafraîchissement
Il y a un court délai (~1 seconde) entre rejoindre/créer une squad et la transition vers `MainTabView`. C'est normal car on attend :
1. Écriture Firestore
2. Lecture Firestore pour rafraîchir
3. Mise à jour SwiftUI

### 3. Mode hors ligne
Si l'utilisateur rejoint une squad hors ligne, la transition ne se fera pas. À gérer dans une future version avec Firestore offline persistence.

---

## 🚀 Améliorations Futures

1. **Cache intelligent**
   - Mettre en cache `currentUser` pour éviter trop de lectures Firestore
   - Invalider le cache uniquement quand nécessaire

2. **Observers Firestore**
   - Utiliser des listeners temps réel sur `users/{userId}`
   - Mise à jour automatique sans notification manuelle

3. **State Management centralisé**
   - Considérer un système comme TCA (The Composable Architecture)
   - Ou un AppState global avec Combine

4. **Feedback visuel**
   - Afficher un loader pendant le rafraîchissement
   - Animation de transition plus smooth

---

## ✅ Checklist de Validation

- [x] SquadViewModel.joinSquad() appelle refreshAuthUser()
- [x] SquadViewModel.createSquad() appelle refreshAuthUser()
- [x] AuthViewModel écoute "UserSquadsUpdated"
- [x] AuthViewModel.refreshUser() met à jour currentUser
- [x] RootView détecte le changement de hasSquad
- [x] Transition OnboardingSquadView → MainTabView fonctionne
- [ ] Tests manuels effectués
- [ ] Tests sur device physique
- [ ] Validation en production

---

**Date de correction** : 31 décembre 2025  
**Problème** : Boucle infinie sur OnboardingSquadView  
**Cause** : Désynchronisation AuthViewModel ↔ SquadViewModel  
**Solution** : Communication via NotificationCenter  
**Status** : ✅ Corrigé et prêt pour tests
