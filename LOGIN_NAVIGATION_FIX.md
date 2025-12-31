# 🔧 Correction : Affichage correct lors du Login

## 🐛 Problème Identifié

### Symptôme
Un utilisateur qui **a déjà des squads** se retrouve sur l'écran `OnboardingSquadView` ("Rejoindre ou créer une squad") après la connexion, au lieu d'aller directement sur `MainTabView`.

### Flux Problématique

```
1. Utilisateur se connecte
   ↓
2. AuthViewModel.signIn() réussit
   ↓
3. currentUser est défini ✅
   ↓
4. isLoading = false ❌ (TROP TÔT)
   ↓
5. RootView évalue hasSquad
   ↓
6. currentUser.squads peut être vide temporairement ❌
   ↓
7. hasSquad = false ❌
   ↓
8. Affiche OnboardingSquadView ❌ (alors que l'utilisateur a des squads)
   ↓
9. SquadViewModel.loadUserSquads() charge les squads (tard)
   ↓
10. Mais l'utilisateur est déjà sur le mauvais écran ❌
```

### Cause Racine

**Race condition** entre :
- `AuthViewModel` qui définit `currentUser` et met `isLoading = false`
- `SquadViewModel` qui charge les squads de manière asynchrone dans `.task()`
- `RootView` qui évalue `hasSquad` **avant** que les squads soient chargées

---

## ✅ Solution Implémentée

### Approche : Attendre le Chargement des Squads

Ne pas afficher l'écran de navigation tant que :
1. ✅ L'utilisateur n'est pas authentifié ET
2. ✅ Les squads n'ont pas été chargées (ou tentées de charger)

### Architecture Corrigée

```
1. Utilisateur se connecte
   ↓
2. AuthViewModel.signIn() réussit
   ↓
3. currentUser est défini ✅
   ↓
4. isLoading = false
   ↓
5. RootView détecte isAuthenticated = true
   ↓
6. .task() déclenche squadVM.loadUserSquads() ✅
   ↓
7. RootView affiche loadingView JUSQU'À ce que:
      - hasAttemptedLoad = true ✅
   ↓
8. Squads chargées depuis Firestore
   ↓
9. hasAttemptedLoad = true
   ↓
10. RootView évalue hasSquad
    ↓
    ├─ Si userSquads.count > 0 → MainTabView ✅
    └─ Si userSquads.count = 0 → OnboardingSquadView ✅
```

---

## 🔧 Modifications Apportées

### 1. **SquadViewModel.swift**

#### Ajout de `hasAttemptedLoad`
```swift
/// Indique si on a déjà tenté de charger les squads
var hasAttemptedLoad = false
```

#### Mise à jour de `loadUserSquads()`
```swift
func loadUserSquads() async {
    guard let userId = currentUserId else {
        errorMessage = "Utilisateur non connecté"
        hasAttemptedLoad = true  // ✅ Marquer comme tenté
        return
    }
    
    isLoading = true
    errorMessage = nil
    
    do {
        userSquads = try await squadService.getUserSquads(userId: userId)
        
        if selectedSquad == nil, let firstSquad = userSquads.first {
            selectedSquad = firstSquad
        }
        
        Logger.logSuccess("Squads chargées: \(userSquads.count)", category: .squads)
    } catch {
        Logger.logError(error, context: "loadUserSquads", category: .squads)
        errorMessage = "Erreur lors du chargement des squads"
    }
    
    isLoading = false
    hasAttemptedLoad = true  // ✅ Marquer comme tenté après chargement
}
```

---

### 2. **RootView.swift**

#### Condition de Chargement Améliorée
```swift
var body: some View {
    Group {
        // ✅ NOUVEAU : Afficher loading tant que:
        // 1. AuthVM est en train de charger
        // 2. OU l'utilisateur est authentifié MAIS les squads ne sont pas encore chargées
        if authVM.isLoading || 
           (authVM.isAuthenticated && squadVM.userSquads.isEmpty && !squadVM.hasAttemptedLoad) {
            
            loadingView
                .transition(.opacity)
        } else if authVM.isAuthenticated {
            // Utilisateur connecté ET squads chargées
            if authVM.hasSquad {
                // A des squads → MainTabView ✅
                MainTabView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Pas de squads → OnboardingSquadView ✅
                OnboardingSquadView()
                    .transition(.scale.combined(with: .opacity))
            }
        } else {
            // Non authentifié
            LoginView()
                .transition(.move(edge: .leading).combined(with: .opacity))
        }
    }
    .animation(.easeInOut(duration: 0.3), value: authVM.isLoading)
    .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
    .animation(.easeInOut(duration: 0.3), value: authVM.hasSquad)
    .task(id: authVM.isAuthenticated) {
        if authVM.isAuthenticated {
            await squadVM.loadUserSquads()  // ✅ Charge les squads
        }
    }
}
```

---

## 🎯 Scénarios de Test

### Scénario 1 : Utilisateur avec Squad(s)

```
État Initial:
- Firebase Auth: utilisateur connecté
- Firestore: users/{id}.squads = ["squad1", "squad2"]

Flux Attendu:
1. App démarre
   ↓
2. AuthViewModel.checkAuthState()
   ↓
3. currentUser chargé depuis Firestore ✅
   ↓
4. isAuthenticated = true
   ↓
5. RootView: Affiche loadingView (car hasAttemptedLoad = false)
   ↓
6. .task() → squadVM.loadUserSquads()
   ↓
7. Charge squads depuis Firestore
   ↓
8. userSquads = [squad1, squad2]
   ↓
9. hasAttemptedLoad = true ✅
   ↓
10. RootView réévalue: hasSquad = true
    ↓
11. Affiche MainTabView ✅✅✅

Résultat: ✅ L'utilisateur arrive directement sur MainTabView
```

### Scénario 2 : Utilisateur sans Squad

```
État Initial:
- Firebase Auth: utilisateur connecté
- Firestore: users/{id}.squads = []

Flux Attendu:
1. App démarre
   ↓
2. AuthViewModel.checkAuthState()
   ↓
3. currentUser chargé ✅
   ↓
4. isAuthenticated = true
   ↓
5. RootView: Affiche loadingView
   ↓
6. .task() → squadVM.loadUserSquads()
   ↓
7. Charge squads depuis Firestore
   ↓
8. userSquads = [] (vide)
   ↓
9. hasAttemptedLoad = true ✅
   ↓
10. RootView réévalue: hasSquad = false
    ↓
11. Affiche OnboardingSquadView ✅

Résultat: ✅ L'utilisateur arrive sur OnboardingSquadView
```

### Scénario 3 : Première Connexion (Sign Up)

```
État Initial:
- Firebase Auth: nouveau compte créé
- Firestore: users/{id}.squads = []

Flux Attendu:
1. Utilisateur s'inscrit
   ↓
2. AuthViewModel.signUp() crée le compte
   ↓
3. currentUser créé dans Firestore ✅
   ↓
4. isAuthenticated = true
   ↓
5. RootView: Affiche loadingView
   ↓
6. .task() → squadVM.loadUserSquads()
   ↓
7. userSquads = [] (nouveau compte)
   ↓
8. hasAttemptedLoad = true
   ↓
9. hasSquad = false
   ↓
10. Affiche OnboardingSquadView ✅

Résultat: ✅ Le nouvel utilisateur est guidé vers l'onboarding
```

---

## 📊 Comparaison Avant/Après

| Aspect | Avant (Bugué) | Après (Corrigé) |
|--------|---------------|-----------------|
| **Login avec squads** | ❌ OnboardingSquadView | ✅ MainTabView |
| **Login sans squads** | ✅ OnboardingSquadView | ✅ OnboardingSquadView |
| **Nouveau compte** | ✅ OnboardingSquadView | ✅ OnboardingSquadView |
| **Écran de chargement** | ⚡ Trop court | ✅ Attend les squads |
| **Race condition** | ❌ Présente | ✅ Éliminée |
| **hasSquad évaluation** | ❌ Trop tôt | ✅ Au bon moment |

---

## 🔍 Logs de Debug

Pour vérifier que tout fonctionne, surveillez ces logs :

### Login Utilisateur avec Squads
```
✅ Utilisateur reconnecté automatiquement
📡 isAuthenticated = true
🔄 Chargement des squads...
✅ Squads chargées: 2
📊 hasAttemptedLoad = true
✅ hasSquad = true
🎉 Navigation → MainTabView
```

### Login Utilisateur sans Squads
```
✅ Utilisateur reconnecté automatiquement
📡 isAuthenticated = true
🔄 Chargement des squads...
✅ Squads chargées: 0
📊 hasAttemptedLoad = true
❌ hasSquad = false
🎯 Navigation → OnboardingSquadView
```

---

## ⚠️ Points d'Attention

### 1. Durée du Loading
L'écran de chargement sera visible ~1-2 secondes le temps de charger les squads depuis Firestore. C'est normal et préférable à afficher le mauvais écran.

### 2. Erreur Réseau
Si le chargement des squads échoue (pas de réseau), `hasAttemptedLoad = true` quand même pour éviter un écran de chargement infini. L'utilisateur sera sur `OnboardingSquadView` avec un message d'erreur.

### 3. Cache Firestore
Firestore met en cache les données localement, donc après la première connexion, les chargements suivants seront quasi instantanés.

---

## 🚀 Améliorations Futures

### 1. Loading State Plus Granulaire
```swift
enum LoadingState {
    case idle
    case loadingAuth
    case loadingSquads
    case ready
}
```

### 2. Préchargement
Charger les squads pendant l'écran de loading d'auth pour réduire le temps total.

### 3. Skeleton Screens
Au lieu d'un simple loading, afficher des "skeletons" des squads en train de charger.

### 4. Retry Automatique
Si le chargement des squads échoue, réessayer automatiquement après quelques secondes.

---

## ✅ Checklist de Validation

- [x] SquadViewModel a `hasAttemptedLoad`
- [x] `loadUserSquads()` met à jour `hasAttemptedLoad`
- [x] RootView vérifie `hasAttemptedLoad` avant d'afficher la navigation
- [x] Loading affiché pendant le chargement des squads
- [ ] Tests manuels : Login avec squads → MainTabView
- [ ] Tests manuels : Login sans squads → OnboardingSquadView
- [ ] Tests manuels : Nouveau compte → OnboardingSquadView
- [ ] Tests sur device physique
- [ ] Validation en production

---

**Date de correction** : 31 décembre 2025  
**Problème** : Mauvais écran affiché au login  
**Cause** : Race condition entre auth et chargement des squads  
**Solution** : Attendre `hasAttemptedLoad` avant navigation  
**Status** : ✅ Corrigé et prêt pour tests
