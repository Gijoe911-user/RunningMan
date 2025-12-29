# 🧹 Guide de Nettoyage du Projet RunningMan

Ce document liste toutes les actions à effectuer pour nettoyer le projet et le rendre **production-ready**.

**Date :** 28 décembre 2024  
**Objectif :** Éliminer le code mort, standardiser l'architecture, et préparer les futures fonctionnalités

---

## ✅ Ce qui a été fait

### 1. Architecture standardisée
- [x] Création de `FeatureFlags.swift` pour contrôler les fonctionnalités
- [x] Création de `DataSyncProtocol.swift` pour les intégrations tierces
- [x] Création de `NotificationService.swift` centralisé
- [x] Création de `StravaService.swift` (stub)
- [x] Création de `GarminService.swift` (stub)

### 2. Documentation centralisée
- [x] Création d'un `README.md` unique et complet
- [x] Création d'un `PRD.md` avec roadmap détaillée
- [x] Création d'un `CHANGELOG.md` structuré

### 3. Code nettoyé
- [x] `SessionsViewModel.swift` : Documentation in-code ajoutée
- [x] `SessionsViewModel.swift` : Intégration des FeatureFlags
- [x] `SessionsViewModel.swift` : Commentaires améliorés

---

## 🚨 Actions à effectuer MAINTENANT

### Étape 1 : Supprimer les fichiers Markdown obsolètes

**Fichiers à SUPPRIMER :**
```
❌ SESSION_STATS_WIDGET_INTEGRATION_COMPLETE.md
❌ INDEX_FICHIERS.md
❌ INDEX.md
❌ INDEX_AUTOFILL_FILES.md
❌ README_AutoFill_Integration.md
❌ CODE_CHANGES_SUMMARY.md
❌ ARCHITECTURE_REFONTE_SESSIONS.md
❌ FIX_BUILD_ERRORS.md
❌ TEST_GUIDE_SESSIONS.md
❌ InfoPlist_FaceID_Configuration.md
❌ Tous les autres .md SAUF :
   ✅ README.md (le nouveau)
   ✅ PRD.md (le nouveau)
   ✅ CHANGELOG.md (le nouveau)
   ✅ LICENSE (si existant)
```

**Action Xcode :**
1. Dans le navigateur de fichiers, sélectionner tous les `.md` obsolètes
2. Clic droit → Delete → Move to Trash
3. Ne garder QUE `README.md`, `PRD.md`, et `CHANGELOG.md`

---

### Étape 2 : Audit des imports Firebase

**Objectif :** Seuls les **Services** doivent importer Firebase.

**Fichiers à vérifier :**

1. **ViewModels** (NE DOIVENT PAS importer Firebase)
   ```bash
   # Rechercher "import Firebase" dans :
   - SessionsViewModel.swift ✅ (Déjà propre)
   - SquadViewModel.swift ✅ (Déjà propre)
   - [Tous les autres ViewModels]
   ```

2. **Views** (NE DOIVENT PAS importer Firebase)
   ```bash
   # Rechercher "import Firebase" dans :
   - SessionsListView.swift
   - SquadHubView.swift
   - [Toutes les autres Views]
   ```

3. **Services** (DOIVENT importer Firebase)
   ```bash
   # C'est OK pour :
   - SessionService.swift ✅
   - SquadService.swift ✅
   - AuthService.swift ✅
   - RealtimeLocationService.swift ✅
   ```

**Action :**
- Si un ViewModel ou une View importe Firebase :
  1. Supprimer l'import
  2. Extraire la logique Firebase dans un Service
  3. Appeler le Service depuis le ViewModel

**Commande de recherche dans Xcode :**
```
Cmd + Shift + F → Rechercher "import Firebase" → Scope: Workspace
```

---

### Étape 3 : Éliminer les `@Published` inutilisés

**Règle :** Une variable `@Published` ne doit exister QUE si elle est affichée à l'écran.

**ViewModels à auditer :**

#### SessionsViewModel.swift
```swift
// ✅ GARDER (utilisés dans l'UI)
@Published var activeSession: SessionModel?
@Published var runnerLocations: [RunnerLocation] = []
@Published var userLocation: CLLocationCoordinate2D?
@Published var routeCoordinates: [CLLocationCoordinate2D] = []
@Published var currentHeartRate: Double?
@Published var currentCalories: Double?

// ❓ À VÉRIFIER (sont-ils affichés ?)
@Published var unreadMessagesCount: Int = 0          // ❌ Si pas de chat UI → SUPPRIMER
@Published var marathonProgress: MarathonProgress?  // ❌ Si pas d'UI → SUPPRIMER
@Published var averageHeartRate: Double?            // ❓ Affiché quelque part ?
@Published var runnerRoutes: [String: [CLLocationCoordinate2D]] = [:]  // ❓ Utilisé ?
```

#### SquadViewModel.swift
```swift
// Vérifier chaque @Published :
// - Est-elle utilisée dans une View ?
// - Si non → la rendre private et supprimer @Published
```

**Action :**
1. Ouvrir chaque ViewModel
2. Pour chaque `@Published`, faire un `Cmd + Clic` sur le nom
3. Regarder si elle est référencée dans une **View**
4. Si NON → Supprimer `@Published` et rendre la variable `private`

---

### Étape 4 : Rechercher et supprimer les fonctions orphelines

**Méthode :**
1. Sélectionner un nom de fonction (ex: `calculateDistance`)
2. `Cmd + Shift + F` → "Find Selected Symbol in Workspace"
3. Si **1 seule occurrence** (la définition) → fonction jamais appelée → **SUPPRIMER**

**Zones à auditer :**
- [ ] Tous les ViewModels
- [ ] Tous les Services
- [ ] Toutes les Extensions

**Exemples de fonctions potentiellement orphelines :**
```swift
// Si jamais appelée depuis l'extérieur → supprimer ou rendre private
func refreshSquad(squadId: String) async { ... }
func getInviteCode(for squad: SquadModel) -> String { ... }
```

---

### Étape 5 : Remplacer les `print()` par `Logger`

**Rechercher tous les `print(` dans le projet :**

```bash
Cmd + Shift + F → Rechercher "print(" → Scope: Workspace
```

**Remplacer par :**
```swift
// ❌ Avant
print("🔨 createSession appelé")

// ✅ Après
Logger.log("createSession appelé", category: .session)
```

**Catégories disponibles :**
- `.session` : Sessions de course
- `.squads` : Gestion des squads
- `.location` : GPS et tracking
- `.health` : HealthKit
- `.audio` : Micro et voice chat
- `.general` : Divers

**Note :** Les `print()` de debug temporaires (ex: avec `🗺️ DEBUG`) peuvent rester en attendant, mais ajouter un `#if DEBUG` :
```swift
#if DEBUG
print("🗺️ DEBUG - routeCoordinates: \(viewModel.routeCoordinates.count) points")
#endif
```

---

### Étape 6 : Supprimer le code commenté

**Règle :** **ZÉRO ligne de code en commentaire**. On utilise Git pour l'historique.

**Rechercher :**
```bash
Cmd + Shift + F → Rechercher "// TODO:" → Scope: Workspace
```

**Actions :**
1. Si le TODO est dans un stub (ex: StravaService) → **GARDER** avec référence à la Phase
2. Si le TODO est dans du code actif :
   - Soit l'implémenter maintenant
   - Soit créer une Issue GitHub/Jira
   - Soit supprimer si obsolète

**Exemples à garder :**
```swift
// TODO: Phase 2 - Implémenter l'upload vers Firebase Storage
// TODO: Phase 3 - Ajouter le support Apple Watch
```

**Exemples à supprimer ou implémenter :**
```swift
// TODO: Vérifier si ça marche  ❌ VAGUE → Supprimer
// TODO: Optimiser cette boucle  ❌ VAGUE → Implémenter ou supprimer
```

---

### Étape 7 : Vérification des Strong Reference Cycles

**Objectif :** S'assurer qu'il n'y a pas de fuites mémoire avec Combine.

**Pattern à vérifier :**
```swift
// ✅ BON (avec [weak self])
realtimeService.$activeSession
    .sink { [weak self] session in
        self?.activeSession = session
    }
    .store(in: &cancellables)

// ❌ MAUVAIS (sans [weak self])
realtimeService.$activeSession
    .sink { session in
        self.activeSession = session  // ⚠️ Strong reference cycle !
    }
    .store(in: &cancellables)
```

**Fichiers à auditer :**
- [ ] SessionsViewModel.swift → `bindOutputs()`
- [ ] SquadViewModel.swift → `startObservingSquads()`
- [ ] Tous les autres ViewModels avec Combine

---

### Étape 8 : Configurer les FeatureFlags dans l'UI

**Objectif :** Masquer les boutons des fonctionnalités non implémentées.

**Exemple pour SessionsListView.swift :**

```swift
// ❌ Avant (bouton toujours visible)
Button("Prendre une photo") {
    viewModel.takePhoto()
}

// ✅ Après (bouton masqué si feature désactivée)
if FeatureFlags.photoSharing {
    Button("Prendre une photo") {
        viewModel.takePhoto()
    }
}
```

**Zones à modifier :**
- [ ] SessionsListView : Boutons micro, photo, messages
- [ ] SquadHubView : Intégrations Strava/Garmin
- [ ] Paramètres : Affichage des features disponibles

---

### Étape 9 : Standardiser les Services (Repository Pattern)

**Objectif :** Tous les Services doivent suivre le même template.

**Template à appliquer :**
```swift
// 1. Dépendances minimales
import Foundation
import Combine 

// 2. Protocole pour permettre le Mock (Tests)
protocol SessionServiceProtocol {
    func startRun() async throws
}

// 3. Implémentation avec contraintes techniques séparées
final class SessionService: SessionServiceProtocol {
    static let shared = SessionService()
    
    // Contrainte technique : Firebase
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private init() {}
    
    func startRun() async throws {
        // Logique isolée
    }
}
```

**Services à refactorer selon ce template :**
- [ ] SessionService.swift
- [ ] SquadService.swift
- [ ] RouteTrackingService.swift
- [ ] RealtimeLocationService.swift

---

### Étape 10 : Ajouter la documentation in-code

**Objectif :** Toutes les fonctions publiques doivent avoir un DocBlock.

**Format standard :**
```swift
/// Démarre une session de course
///
/// Cette méthode crée une nouvelle session dans Firebase et démarre le tracking GPS.
///
/// - Parameters:
///   - squadId: Identifiant de la squad
///   - type: Type d'activité (Solo, Duo, Squad)
/// - Returns: La session créée avec son ID
/// - Throws: `SessionError.notAuthorized` si l'utilisateur n'a pas les droits
///
/// - Note: Envoie une notification automatique à la Squad via `NotificationService`
/// - SeeAlso: `SessionModel`, `SessionError`
func startSession(squadId: String, type: SessionType) async throws -> SessionModel
```

**Fichiers à documenter :**
- [x] SessionsViewModel.swift ✅ (Déjà fait)
- [ ] SquadViewModel.swift
- [ ] SessionService.swift
- [ ] SquadService.swift
- [ ] Tous les autres Services

---

### Étape 11 : Vérifier la limite de 200 lignes

**Règle :** Aucun fichier ne doit dépasser 200 lignes.

**Commande pour lister les fichiers longs :**
```bash
find . -name "*.swift" -exec wc -l {} + | sort -rn | head -20
```

**Si un fichier dépasse 200 lignes :**

1. **Option 1 : Extensions**
   ```swift
   // Fichier principal : SessionService.swift (150 lignes)
   
   // Extension : SessionService+Analytics.swift
   extension SessionService {
       // Logique d'analytics
   }
   
   // Extension : SessionService+CLLocationManagerDelegate.swift
   extension SessionService: CLLocationManagerDelegate {
       // Implémentation du delegate
   }
   ```

2. **Option 2 : Diviser en sous-services**
   ```
   SessionService.swift → 250 lignes
   
   ↓ Diviser en :
   
   SessionService.swift (100 lignes) - Logique principale
   SessionRouteService.swift (80 lignes) - Gestion des tracés
   SessionStatsService.swift (70 lignes) - Calcul des stats
   ```

**Fichiers à vérifier :**
- [ ] SessionsListView.swift (630 lignes) ⚠️ **À DIVISER**
- [ ] SessionService.swift (420 lignes) ⚠️ **À DIVISER**
- [ ] SquadService.swift (460 lignes) ⚠️ **À DIVISER**
- [ ] SquadViewModel.swift (332 lignes) ⚠️ **À DIVISER**

---

## 📋 Checklist finale

### Documentation
- [x] README.md unique créé
- [x] PRD.md avec roadmap créé
- [x] CHANGELOG.md structuré créé
- [ ] Supprimer tous les .md obsolètes

### Architecture
- [x] FeatureFlags.swift créé
- [x] DataSyncProtocol.swift créé
- [x] NotificationService.swift créé
- [x] StravaService.swift (stub) créé
- [x] GarminService.swift (stub) créé

### Code Quality
- [ ] Aucun import Firebase dans les ViewModels
- [ ] Aucun import Firebase dans les Views
- [ ] Aucun @Published inutilisé
- [ ] Aucune fonction orpheline
- [ ] Tous les print() remplacés par Logger
- [ ] Aucun code commenté (sauf TODOs avec Phase)
- [ ] Tous les [weak self] présents dans Combine

### UI
- [ ] FeatureFlags intégrés dans l'UI
- [ ] Boutons désactivés masqués

### Standards
- [ ] Tous les Services suivent le template
- [ ] Documentation in-code sur fonctions publiques
- [ ] Aucun fichier > 200 lignes

### Tests
- [ ] Tests unitaires pour SessionsViewModel
- [ ] Tests unitaires pour SquadViewModel
- [ ] Tests unitaires pour SessionService

---

## 🚀 Prochaines étapes (après nettoyage)

1. **Phase 1 (Janvier)** : Implémenter HealthKit complet
2. **Intégrer NotificationService** : Connecter aux événements de la squad
3. **Tests** : Écrire les tests unitaires avec Swift Testing
4. **CI/CD** : Configurer GitHub Actions pour les builds

---

## 💡 Conseils

### Pour gagner du temps
1. Utiliser les raccourcis Xcode :
   - `Cmd + Shift + F` : Recherche globale
   - `Cmd + Option + Click` : Voir la définition
   - `Cmd + Shift + O` : Ouvrir rapidement un fichier

2. Faire le nettoyage par étapes :
   - Jour 1 : Supprimer les .md + Audit Firebase
   - Jour 2 : @Published + Fonctions orphelines
   - Jour 3 : Logger + Code commenté
   - Jour 4 : Documentation + Tests

### Pour ne pas casser l'app
1. **Tester après chaque modification**
2. **Commiter souvent** avec des messages clairs
3. **Créer une branche** `feature/cleanup` avant de commencer

---

**Bon nettoyage ! 🧹✨**

Si vous avez des questions ou rencontrez des problèmes, consultez le README.md ou créez une Issue.
