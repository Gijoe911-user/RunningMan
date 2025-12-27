# 🔧 Plan d'Intégration SquadViewModel - 26 Décembre 2025

## 📋 État Actuel de l'Architecture

### ✅ Ce qui est déjà en place

1. **Point d'entrée (RunningManApp.swift)**
   - Firebase configuré ✅
   - AuthViewModel injecté dans l'environnement ✅
   - RootView comme vue principale ✅

2. **Navigation (RootView.swift)**
   - Gère l'authentification
   - Affiche MainTabView si authentifié
   - Vérifie si l'utilisateur a un squad

3. **TabView (MainTabView.swift)**
   - 4 onglets : Dashboard, Squads, Course, Profil
   - Utilise AuthViewModel depuis l'environnement
   - **Problème :** Pas de SquadViewModel injecté

4. **SquadViewModel**
   - Classe `@Observable` prête ✅
   - Méthodes importantes :
     - `loadUserSquads()` - Charge les squads de l'utilisateur
     - `selectedSquad` - Squad actuellement sélectionnée
   - **Problème :** N'est jamais instanciée ni injectée

5. **SessionsListView**
   - Utilise `@Environment(SquadViewModel.self)` ✅
   - Appelle `viewModel.setContext(squadId:)` dans `.task` ✅
   - **Problème :** SquadViewModel pas disponible dans l'environnement

### ❌ Ce qui manque

1. **Instanciation de SquadViewModel** 
   - Pas créé dans RunningManApp
   - Pas injecté dans l'environnement

2. **Chargement initial des squads**
   - `loadUserSquads()` jamais appelé
   - `selectedSquad` toujours nil

3. **Propagation dans l'environnement**
   - SquadViewModel pas disponible pour les vues enfants

---

## 🎯 Plan d'Action

### Phase 1 : Injection de SquadViewModel dans l'environnement

#### Étape 1.1 : Modifier RunningManApp.swift

**Objectif :** Créer et injecter SquadViewModel au même niveau que AuthViewModel

**Modifications :**

```swift
@main
struct RunningManApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authViewModel: AuthViewModel
    @State private var squadViewModel = SquadViewModel() // ✅ NOUVEAU
    
    init() {
        FirebaseApp.configure()
        Logger.log("Firebase configuré dans l'initializer de App", category: .firebase)
        _authViewModel = State(initialValue: AuthViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)
                .environment(squadViewModel) // ✅ NOUVEAU
                .preferredColorScheme(.dark)
        }
    }
}
```

**Impact :**
- SquadViewModel disponible dans toute l'app
- Partagé entre tous les onglets
- Cycle de vie géré par l'app

---

### Phase 2 : Chargement des squads au bon moment

#### Étape 2.1 : Charger les squads après authentification

**Option A : Dans RootView (Recommandé)**

**Avantages :**
- Charge les squads dès qu'on sait que l'utilisateur est authentifié
- Squads disponibles avant d'afficher MainTabView
- Logique centralisée

**Modifications RootView.swift :**

```swift
struct RootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(SquadViewModel.self) private var squadVM // ✅ NOUVEAU
    
    var body: some View {
        Group {
            if authVM.isLoading {
                loadingView
            } else if authVM.isAuthenticated {
                if authVM.hasSquad {
                    MainTabView()
                } else {
                    OnboardingSquadView()
                }
            } else {
                LoginView()
            }
        }
        .task(id: authVM.isAuthenticated) { // ✅ NOUVEAU
            // Charger les squads quand l'utilisateur se connecte
            if authVM.isAuthenticated {
                await squadVM.loadUserSquads()
            }
        }
    }
}
```

**Option B : Dans SquadListView**

**Avantages :**
- Charge uniquement quand l'utilisateur visite l'onglet Squads
- Plus lazy loading

**Modifications SquadListView.swift :**

```swift
struct SquadListView: View {
    @Environment(SquadViewModel.self) private var squadVM // ✅ Ajouter
    @State private var showCreateSquad = false
    @State private var showJoinSquad = false
    
    var body: some View {
        NavigationStack {
            // ... contenu existant
        }
        .task { // ✅ NOUVEAU
            await squadVM.loadUserSquads()
        }
    }
}
```

**Recommandation : Option A (RootView)**
- Plus prévisible
- Données disponibles plus tôt
- SessionsListView peut accéder à selectedSquad dès le départ

---

### Phase 3 : Vérifications et Tests

#### Checklist de vérification

- [ ] SquadViewModel créé dans RunningManApp
- [ ] SquadViewModel injecté avec `.environment(squadViewModel)`
- [ ] `loadUserSquads()` appelé dans `.task` de RootView
- [ ] SessionsListView peut accéder à `squadsVM.selectedSquad`
- [ ] Pas de crash au lancement
- [ ] Les logs montrent le chargement des squads

#### Tests à effectuer

1. **Test 1 : Lancement de l'app**
   ```
   Console attendue :
   [Firebase] Firebase configuré
   [Authentication] Utilisateur connecté
   [Squads] Squads chargées: 2
   ```

2. **Test 2 : Onglet Sessions**
   - Ouvrir l'onglet Course
   - Vérifier que `selectedSquad` est disponible
   - Console devrait montrer : `[Session] Context set with squadId: XXX`

3. **Test 3 : Changement de squad**
   - Aller dans Squads
   - Sélectionner une squad différente
   - Retourner à Sessions
   - Vérifier que le contexte est mis à jour

---

## 🚨 Points d'Attention

### 1. Ordre de chargement

**Important :** Charger les squads APRÈS que l'utilisateur soit authentifié

```swift
// ✅ BON
.task(id: authVM.isAuthenticated) {
    if authVM.isAuthenticated {
        await squadVM.loadUserSquads()
    }
}

// ❌ MAUVAIS - Peut charger avant auth
.task {
    await squadVM.loadUserSquads() // currentUserId sera nil !
}
```

### 2. selectedSquad peut être nil

**SessionsListView doit gérer le cas où selectedSquad est nil :**

```swift
.task(id: squadsVM.selectedSquad?.id) {
    guard let squadId = squadsVM.selectedSquad?.id else { 
        Logger.log("Aucun squad sélectionné", category: .session)
        return 
    }
    // ... reste du code
}
```

### 3. Rafraîchissement des données

**Considérer le rafraîchissement dans :**
- SquadListView (pull to refresh)
- Quand l'app revient au premier plan
- Après création/rejoindre un squad

---

## 📝 Code Complet à Appliquer

### Fichier 1 : RunningManApp.swift

```swift
@main
struct RunningManApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authViewModel: AuthViewModel
    @State private var squadViewModel = SquadViewModel()
    
    init() {
        FirebaseApp.configure()
        Logger.log("Firebase configuré dans l'initializer de App", category: .firebase)
        _authViewModel = State(initialValue: AuthViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)
                .environment(squadViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
```

### Fichier 2 : RootView.swift

```swift
struct RootView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(SquadViewModel.self) private var squadVM
    
    var body: some View {
        Group {
            if authVM.isLoading {
                loadingView
            } else if authVM.isAuthenticated {
                if authVM.hasSquad {
                    MainTabView()
                } else {
                    OnboardingSquadView()
                }
            } else {
                LoginView()
            }
        }
        .task(id: authVM.isAuthenticated) {
            if authVM.isAuthenticated {
                await squadVM.loadUserSquads()
            }
        }
    }
    
    // ... reste du code (loadingView)
}
```

### Fichier 3 : SquadListView.swift (optionnel)

Ajouter si vous voulez un rafraîchissement manuel :

```swift
struct SquadListView: View {
    @Environment(SquadViewModel.self) private var squadVM
    
    var body: some View {
        NavigationStack {
            // ... contenu existant
        }
        .refreshable {
            await squadVM.loadUserSquads()
        }
    }
}
```

---

## 🎯 Résultat Attendu

Après implémentation :

### ✅ Flux de données complet

```
RunningManApp
    ├─ AuthViewModel (environnement)
    └─ SquadViewModel (environnement)
           │
           ▼
       RootView
    (charge les squads)
           │
           ▼
      MainTabView
           │
    ┌──────┴──────┐
    ▼             ▼
SquadListView  SessionsListView
(affiche)      (utilise selectedSquad)
```

### ✅ Console de logs attendue

```
[Firebase] Firebase configuré dans l'initializer de App
[Firebase] AppDelegate initialisé
[Authentication] Vérification de l'état d'authentification...
[Authentication] Utilisateur connecté: user@example.com
[Squads] Squads chargées: 2
[Squads] Squad sélectionnée: Marathon 2024
[Session] Context set with squadId: ABC123
```

---

## 🔄 Prochaines Étapes (Futures)

1. **Synchronisation temps réel**
   - Écouter les changements de squads dans Firestore
   - Mettre à jour automatiquement la liste

2. **Gestion d'erreurs**
   - Afficher un message si le chargement échoue
   - Permettre de réessayer

3. **Optimisation**
   - Cacher les données localement
   - Éviter les rechargements inutiles

4. **Tests**
   - Tests unitaires pour SquadViewModel
   - Tests d'intégration pour le flux complet

---

## 📊 Temps Estimé

- **Phase 1 :** 5 minutes (ajouter SquadViewModel)
- **Phase 2 :** 10 minutes (charger les squads)
- **Phase 3 :** 10 minutes (tests et vérifications)
- **Total :** ~25 minutes

---

**Status :** 📝 Prêt à implémenter  
**Date :** 26 Décembre 2025  
**Dernière mise à jour :** Maintenant

🎯 **Objectif :** Avoir SquadViewModel disponible dans toute l'app et les squads chargées automatiquement après connexion.
