# 📁 Guide de Restructuration par Features

Ce document explique comment réorganiser le projet RunningMan en modules par fonctionnalité.

**Objectif :** Passer d'une structure "par type de fichier" à une structure "par feature" pour améliorer la maintenabilité.

---

## ❌ Structure actuelle (À éviter)

```
RunningMan/
├── ViewModels/
│   ├── SessionsViewModel.swift
│   ├── SquadViewModel.swift
│   ├── ProfileViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── SessionsListView.swift
│   ├── SquadHubView.swift
│   ├── ProfileView.swift
│   └── SettingsView.swift
├── Services/
│   ├── SessionService.swift
│   ├── SquadService.swift
│   ├── AuthService.swift
│   └── LocationProvider.swift
└── Models/
    ├── SessionModel.swift
    ├── SquadModel.swift
    └── UserModel.swift
```

**Problèmes :**
- ❌ Difficile de savoir quels fichiers font partie d'une même feature
- ❌ Quand on supprime une feature, il faut chercher dans 4 dossiers différents
- ❌ Impossible de voir rapidement ce qui est implémenté vs ce qui est prévu

---

## ✅ Nouvelle structure (Par Features)

```
RunningMan/
├── Features/
│   ├── Session-Running/           # 🏃 Tout ce qui concerne les sessions de course
│   │   ├── ViewModels/
│   │   │   └── SessionsViewModel.swift
│   │   ├── Views/
│   │   │   ├── SessionsListView.swift
│   │   │   ├── SessionStatsWidget.swift
│   │   │   ├── EnhancedSessionMapView.swift
│   │   │   └── CreateSessionView.swift
│   │   ├── Services/
│   │   │   ├── SessionService.swift
│   │   │   ├── RouteTrackingService.swift
│   │   │   └── RealtimeLocationService.swift
│   │   └── Models/
│   │       ├── SessionModel.swift
│   │       ├── ParticipantStats.swift
│   │       └── RunnerLocation.swift
│   │
│   ├── Squad-Hub/                  # 👥 Gestion des squads
│   │   ├── ViewModels/
│   │   │   └── SquadViewModel.swift
│   │   ├── Views/
│   │   │   ├── SquadHubView.swift
│   │   │   ├── CreateSquadView.swift
│   │   │   ├── JoinSquadView.swift
│   │   │   └── SquadDetailView.swift
│   │   ├── Services/
│   │   │   └── SquadService.swift
│   │   └── Models/
│   │       └── SquadModel.swift
│   │
│   ├── Health-Tracking/            # ❤️ HealthKit et stats de santé
│   │   ├── Services/
│   │   │   └── HealthKitManager.swift
│   │   ├── Views/
│   │   │   ├── HeartRateBadge.swift
│   │   │   ├── CaloriesBadge.swift
│   │   │   └── HealthPermissionView.swift
│   │   └── Models/
│   │       └── HealthMetrics.swift
│   │
│   ├── Integrations/               # 🔗 Services tiers (Strava, Garmin, etc.)
│   │   ├── Protocols/
│   │   │   └── DataSyncProtocol.swift
│   │   ├── Strava/
│   │   │   ├── StravaService.swift
│   │   │   ├── StravaAuthView.swift (🆕 À créer)
│   │   │   └── StravaModels.swift (🆕 À créer)
│   │   ├── Garmin/
│   │   │   ├── GarminService.swift
│   │   │   ├── GarminAuthView.swift (🆕 À créer)
│   │   │   └── GarminModels.swift (🆕 À créer)
│   │   └── SyncManager.swift (🆕 À créer - orchestre toutes les syncs)
│   │
│   ├── Communication/              # 💬 Chat, voice, notifications
│   │   ├── Services/
│   │   │   ├── NotificationService.swift
│   │   │   ├── ChatService.swift (🆕 À créer)
│   │   │   └── VoiceChatService.swift (🆕 À créer)
│   │   ├── Views/
│   │   │   ├── ChatView.swift (🆕 À créer)
│   │   │   └── VoiceChatButton.swift (🆕 À créer)
│   │   └── Models/
│   │       └── Message.swift (🆕 À créer)
│   │
│   ├── Profile/                    # 👤 Profil utilisateur
│   │   ├── ViewModels/
│   │   │   └── ProfileViewModel.swift (🆕 À créer)
│   │   ├── Views/
│   │   │   ├── ProfileView.swift (🆕 À créer)
│   │   │   └── EditProfileView.swift (🆕 À créer)
│   │   └── Models/
│   │       └── UserProfile.swift (🆕 À créer)
│   │
│   └── Core/                       # 🛠️ Utilitaires partagés
│       ├── Services/
│       │   ├── AuthService.swift
│       │   └── LocationProvider.swift
│       ├── Utilities/
│       │   ├── Logger.swift
│       │   ├── FeatureFlags.swift
│       │   └── Constants.swift
│       ├── Extensions/
│       │   ├── Color+Theme.swift
│       │   ├── Date+Formatting.swift
│       │   └── Double+Distance.swift
│       └── Protocols/
│           └── Identifiable.swift
│
├── Resources/
│   ├── GoogleService-Info.plist
│   ├── Info.plist
│   └── Assets.xcassets/
│
├── App/
│   ├── RunningManApp.swift
│   └── AppDelegate.swift (si nécessaire)
│
├── Tests/
│   ├── Session-RunningTests/
│   │   └── SessionsViewModelTests.swift
│   ├── Squad-HubTests/
│   │   └── SquadViewModelTests.swift
│   └── IntegrationsTests/
│       ├── StravaServiceTests.swift
│       └── GarminServiceTests.swift
│
├── README.md
├── PRD.md
├── CHANGELOG.md
└── CLEANUP_GUIDE.md
```

**Avantages :**
- ✅ Tout est regroupé par fonctionnalité
- ✅ Facile de voir ce qui existe et ce qui manque
- ✅ Suppression d'une feature = supprimer 1 dossier
- ✅ Onboarding plus rapide pour les nouveaux développeurs

---

## 📝 Plan d'action : Migration étape par étape

### Phase 1 : Créer la nouvelle structure (1h)

1. **Créer les dossiers dans Xcode**
   ```
   New Group → Features
   New Group → Features/Session-Running
   New Group → Features/Session-Running/ViewModels
   New Group → Features/Session-Running/Views
   New Group → Features/Session-Running/Services
   New Group → Features/Session-Running/Models
   ```

2. **Répéter pour chaque feature**

### Phase 2 : Déplacer les fichiers existants (2h)

#### Session-Running
```bash
# ViewModels
SessionsViewModel.swift → Features/Session-Running/ViewModels/

# Views
SessionsListView.swift → Features/Session-Running/Views/
SessionStatsWidget.swift → Features/Session-Running/Views/
EnhancedSessionMapView.swift → Features/Session-Running/Views/
CreateSessionView.swift → Features/Session-Running/Views/

# Services
SessionService.swift → Features/Session-Running/Services/
RouteTrackingService.swift → Features/Session-Running/Services/
RealtimeLocationService.swift → Features/Session-Running/Services/

# Models
SessionModel.swift → Features/Session-Running/Models/
ParticipantStats.swift → Features/Session-Running/Models/
RunnerLocation.swift → Features/Session-Running/Models/
```

#### Squad-Hub
```bash
# ViewModels
SquadViewModel.swift → Features/Squad-Hub/ViewModels/

# Views
SquadHubView.swift → Features/Squad-Hub/Views/
CreateSquadView.swift → Features/Squad-Hub/Views/
JoinSquadView.swift → Features/Squad-Hub/Views/

# Services
SquadService.swift → Features/Squad-Hub/Services/

# Models
SquadModel.swift → Features/Squad-Hub/Models/
```

#### Health-Tracking
```bash
# Services
HealthKitManager.swift → Features/Health-Tracking/Services/

# Views
HeartRateBadge.swift → Features/Health-Tracking/Views/
CaloriesBadge.swift → Features/Health-Tracking/Views/
```

#### Integrations
```bash
# Protocols
DataSyncProtocol.swift → Features/Integrations/Protocols/

# Strava
StravaService.swift → Features/Integrations/Strava/

# Garmin
GarminService.swift → Features/Integrations/Garmin/
```

#### Communication
```bash
# Services
NotificationService.swift → Features/Communication/Services/
```

#### Core
```bash
# Services
AuthService.swift → Features/Core/Services/
LocationProvider.swift → Features/Core/Services/

# Utilities
Logger.swift → Features/Core/Utilities/
FeatureFlags.swift → Features/Core/Utilities/

# Extensions
Color+Theme.swift → Features/Core/Extensions/
```

### Phase 3 : Créer les fichiers stubs (1h)

Pour chaque feature future, créer un fichier vide avec un TODO :

#### Communication/ChatService.swift
```swift
//
//  ChatService.swift
//  RunningMan
//
//  Service de chat textuel pour les sessions
//  ⚠️ STUB - À implémenter en Phase 2
//

import Foundation

/// Service de messagerie pour les sessions actives
///
/// - Note: ⚠️ Non implémenté - Prévu Phase 2 (Février 2025)
final class ChatService {
    
    static let shared = ChatService()
    
    private init() {
        Logger.log("ChatService initialisé (STUB)", category: .general)
    }
    
    /// Envoie un message dans le chat de la session
    /// - Parameters:
    ///   - text: Contenu du message
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'expéditeur
    func sendMessage(text: String, sessionId: String, userId: String) async throws {
        Logger.log("⚠️ ChatService.sendMessage() - Non implémenté", category: .general)
        throw ChatError.notImplemented
    }
    
    /// Récupère les messages d'une session
    /// - Parameter sessionId: ID de la session
    /// - Returns: Liste des messages
    func fetchMessages(sessionId: String) async throws -> [Message] {
        Logger.log("⚠️ ChatService.fetchMessages() - Non implémenté", category: .general)
        throw ChatError.notImplemented
    }
}

enum ChatError: LocalizedError {
    case notImplemented
    
    var errorDescription: String? {
        "Fonctionnalité de chat non encore implémentée"
    }
}
```

#### Répéter pour :
- `VoiceChatService.swift`
- `SyncManager.swift`
- `ProfileViewModel.swift`
- Etc.

### Phase 4 : Mettre à jour les imports (30 min)

Après avoir déplacé les fichiers, certains imports peuvent être cassés. Xcode devrait les détecter automatiquement.

**Build le projet :**
```
Cmd + B
```

**Si des erreurs d'import apparaissent :**
- C'est généralement dû à des dépendances circulaires
- Solution : Utiliser des protocoles pour découpler

---

## 🎯 Avantages de cette structure

### 1. **Clarté du scope**
Chaque feature a son propre dossier. On sait immédiatement ce qui existe et ce qui manque.

### 2. **Facilité de suppression**
Si on décide de supprimer une fonctionnalité (ex: Garmin), on supprime juste le dossier `Integrations/Garmin/`.

### 3. **Onboarding rapide**
Un nouveau développeur peut voir en un coup d'œil :
- Les features déjà implémentées
- Les features en cours (stubs)
- Les features planifiées (dossiers vides)

### 4. **Séparation des préoccupations**
Chaque feature est isolée. On peut travailler sur `Squad-Hub` sans toucher à `Session-Running`.

### 5. **Tests plus clairs**
La structure de `Tests/` reflète la structure de `Features/`.

---

## 📊 Comparaison avant/après

| Critère | Avant (Par type) | Après (Par feature) |
|---------|------------------|---------------------|
| Nombre de dossiers racine | 4 (ViewModels, Views, Services, Models) | 7 features + Core |
| Localisation d'une feature | 4 endroits différents | 1 seul dossier |
| Ajout d'une feature | Toucher 4 dossiers | Créer 1 dossier |
| Suppression d'une feature | Chercher dans 4 dossiers | Supprimer 1 dossier |
| Clarté pour un nouveau dev | ⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🚨 Pièges à éviter

### 1. Dépendances circulaires
**Problème :**
```
Session-Running → Squad-Hub → Session-Running
```

**Solution :**
- Extraire les types partagés dans `Core/Models/`
- Utiliser des protocoles pour découpler

### 2. Duplication de code
**Problème :**
Chaque feature réimplémente sa propre logique de formatage de dates.

**Solution :**
Mettre les utilitaires partagés dans `Core/Utilities/` ou `Core/Extensions/`.

### 3. Trop de features
**Problème :**
50 dossiers de features = difficile à naviguer

**Solution :**
Regrouper les features similaires :
```
Communication/
  ├── Chat/
  ├── Voice/
  └── Notifications/
```

---

## ✅ Checklist de migration

### Préparation
- [ ] Créer une branche Git : `git checkout -b feature/restructure-by-features`
- [ ] Faire un backup du projet
- [ ] Lire ce guide en entier avant de commencer

### Création de la structure
- [ ] Créer le dossier `Features/`
- [ ] Créer `Session-Running/` avec sous-dossiers
- [ ] Créer `Squad-Hub/` avec sous-dossiers
- [ ] Créer `Health-Tracking/` avec sous-dossiers
- [ ] Créer `Integrations/` avec sous-dossiers
- [ ] Créer `Communication/` avec sous-dossiers
- [ ] Créer `Profile/` avec sous-dossiers
- [ ] Créer `Core/` avec sous-dossiers

### Migration des fichiers
- [ ] Déplacer les fichiers Session-Running
- [ ] Déplacer les fichiers Squad-Hub
- [ ] Déplacer les fichiers Health-Tracking
- [ ] Déplacer les fichiers Integrations
- [ ] Déplacer les fichiers Communication
- [ ] Déplacer les fichiers Core

### Création des stubs
- [ ] ChatService.swift
- [ ] VoiceChatService.swift
- [ ] SyncManager.swift
- [ ] ProfileViewModel.swift
- [ ] ProfileView.swift

### Validation
- [ ] Build réussi (`Cmd + B`)
- [ ] Tests passent
- [ ] L'app se lance sans crash
- [ ] Toutes les features fonctionnent

### Finalisation
- [ ] Supprimer les anciens dossiers vides (ViewModels, Views, Services, Models)
- [ ] Commiter : `git commit -m "refactor: restructure project by features"`
- [ ] Push : `git push origin feature/restructure-by-features`
- [ ] Créer une Pull Request

---

## 🎓 Ressources supplémentaires

- [Feature-Driven Development](https://en.wikipedia.org/wiki/Feature-driven_development)
- [SwiftUI App Architecture](https://developer.apple.com/documentation/swiftui/app-architecture)
- [Organizing Your Code](https://developer.apple.com/documentation/xcode/organizing-your-code)

---

**Bonne restructuration ! 📁✨**

Si vous rencontrez des problèmes, consultez le `README.md` ou créez une Issue.
