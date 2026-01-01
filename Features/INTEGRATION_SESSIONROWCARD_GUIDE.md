# Guide d'Intégration du SessionRowCard - Résumé

## 🎯 Objectif
Intégrer proprement le composant `SessionRowCard` dans votre vue principale pour gérer 3 états différents :
1. **Ma propre session** (déjà en cours de tracking)
2. **Session à rejoindre** (en tant que Runner pour courir)
3. **Session à observer** (en tant que Supporter pour encourager)

## ✅ Fichiers Modifiés

### 1. SessionRowCard.swift (Corrigé)
**Problème résolu :** Erreur `Value of type 'SessionModel' has no member 'isRace'`

**Solution :** Remplacé `session.isRace` par `session.activityType == .race`

```swift
// Avant (❌ Erreur)
if session.isRace {
    Text("COURSE")
        // ...
}

// Après (✅ Correct)
if session.activityType == .race {
    Text("COURSE")
        .foregroundColor(.white)  // Ajout pour meilleure lisibilité
        // ...
}
```

### 2. AllSessionsViewUnified.swift (Nouveau fichier créé)
**Rôle :** Vue principale unifiée qui regroupe toutes les fonctionnalités

**Sections incluses :**
1. **Ma session active** : Session GPS en cours avec stats temps réel
2. **Sessions que je supporte** : Sessions suivies en mode spectateur
3. **Sessions disponibles** : Toutes les sessions actives avec le `SessionRowCard`
4. **Historique récent** : Sessions terminées récemment

**Utilisation du SessionRowCard :**
```swift
ForEach(viewModel.allActiveSessions) { session in
    SessionRowCard(
        session: session,
        isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
        onJoin: {
            Task {
                if let sessionId = session.id {
                    _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
                    await loadSessions()
                }
            }
        },
        onStartTracking: {
            Task {
                _ = await viewModel.startTracking(for: session)
                await loadSessions()
            }
        }
    )
}
```

### 3. MainTabView.swift (Mise à jour)
**Changement :** Onglet "Sessions" utilise maintenant `AllSessionsViewUnified`

```swift
// Avant
AllSessionsView()

// Après
AllSessionsViewUnified()
```

## 🏗️ Architecture

```
MainTabView
└── AllSessionsViewUnified
    ├── SessionTrackingViewModel (État centralisé)
    ├── TrackingSessionCard (Ma session active)
    ├── SupporterSessionCard (Sessions supportées)
    ├── SessionRowCard (Sessions disponibles) ← NOUVEAU
    └── HistorySessionCard (Historique)
```

## 📊 Flux de Données

```
SessionTrackingViewModel
├── myActiveTrackingSession: SessionModel?
├── supporterSessions: [SessionModel]
├── allActiveSessions: [SessionModel]  ← Utilisé par SessionRowCard
└── recentHistory: [SessionModel]

Actions disponibles :
├── startTracking(for:) → Lance le GPS pour une session
├── joinSessionAsSupporter(sessionId:) → Suit une session sans GPS
└── loadAllActiveSessions(squadIds:) → Charge toutes les données
```

## 🎨 Composants UI

### SessionRowCard
Affiche une session avec 3 états possibles :

1. **C'est ma session** (`isMyTracking = true`)
   - Badge "LIVE" vert
   - Fond et bordure coral
   - Pas de bouton d'action

2. **Session disponible** (`isMyTracking = false`)
   - Bouton "..." pour choisir l'action
   - Menu avec 2 options :
     - "Démarrer mon tracking (Runner)"
     - "Suivre la session (Supporter)"

### TrackingSessionCard
Affiche la session active avec :
- Distance parcourue en temps réel
- Durée écoulée
- État (Actif, En pause, etc.)
- Navigation vers les détails

### SupporterSessionCard
Affiche les sessions suivies en mode spectateur :
- Icône "eyes" bleue
- Nombre de coureurs
- Stats de la session

### HistorySessionCard
Affiche l'historique des sessions :
- Icône grisée
- Date de fin
- Stats finales

## 🔄 Intégration dans le ViewModel

Le `SessionTrackingViewModel` centralise toute la logique :

```swift
@MainActor
class SessionTrackingViewModel: ObservableObject {
    @Published var myActiveTrackingSession: SessionModel?
    @Published var supporterSessions: [SessionModel] = []
    @Published var allActiveSessions: [SessionModel] = []  // Pour SessionRowCard
    @Published var recentHistory: [SessionModel] = []
    
    func loadAllActiveSessions(squadIds: [String]) async {
        // Charge en parallèle :
        // 1. Sessions LIVE (allActiveSessions)
        // 2. Historique récent (recentHistory)
    }
    
    func startTracking(for session: SessionModel) async -> Bool {
        // Active le GPS et le suivi de session
    }
    
    func joinSessionAsSupporter(sessionId: String) async -> Bool {
        // S'abonne aux notifications sans activer le GPS
    }
}
```

## ✨ Fonctionnalités Clés

### 1. Menu Contextuel (SessionRowCard)
Lorsqu'on clique sur le bouton "..." :
```swift
.confirmationDialog("Options de session", isPresented: $showActions) {
    Button("Démarrer mon tracking (Runner)") {
        onStartTracking()
    }
    
    Button("Suivre la session (Supporter)") {
        onJoin()
    }
    
    Button("Annuler", role: .cancel) { }
}
```

### 2. Badge de Type de Session
Affiche visuellement le type d'activité :
```swift
if session.activityType == .race {
    Text("COURSE")
        .font(.system(size: 8, weight: .black))
        .foregroundColor(.white)
        .background(Color.red)
        .clipShape(RoundedRectangle(cornerRadius: 4))
}
```

### 3. Indicateur LIVE
Pour la session active de l'utilisateur :
```swift
HStack(spacing: 4) {
    Circle()
        .fill(Color.green)
        .frame(width: 8, height: 8)
    Text("LIVE")
        .font(.caption2.bold())
        .foregroundColor(.green)
}
```

## 🧪 Test de l'Intégration

### Scénario 1 : Créer et démarrer une session
1. Onglet "Sessions"
2. Bouton "+" en haut à droite
3. Choisir une squad
4. "Créer et démarrer le tracking"
5. → Session apparaît en haut avec "LIVE"

### Scénario 2 : Rejoindre une session existante
1. Voir une session dans "Sessions disponibles"
2. Cliquer sur "..."
3. Choisir "Démarrer mon tracking" ou "Suivre la session"
4. → Session déplacée dans la section appropriée

### Scénario 3 : Voir l'historique
1. Scroller vers le bas
2. Section "Historique récent"
3. Cliquer sur une session
4. → Détails de la session terminée

## 📱 Hiérarchie Visuelle

```
┌─────────────────────────────────────┐
│  Sessions                       [+] │
├─────────────────────────────────────┤
│                                     │
│  Ma session active                  │
│  ┌───────────────────────────────┐  │
│  │ 🏃 Session en cours      ●LIVE│  │
│  │ 5.2 km          45:23         │  │
│  │ [Voir les détails →]          │  │
│  └───────────────────────────────┘  │
│                                     │
│  Sessions que je supporte           │
│  ┌───────────────────────────────┐  │
│  │ 👀 Entraînement               │  │
│  │ 3 coureurs • 2.1 km           │  │
│  └───────────────────────────────┘  │
│                                     │
│  Sessions actives dans mes squads   │
│  ┌───────────────────────────────┐  │
│  │ 🏃 Course          [...]      │  │ ← SessionRowCard
│  │ 2 coureurs • 1.5 km           │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ 🏃 Ma session      ●LIVE      │  │ ← Ma session
│  │ 1 coureur • 0.2 km            │  │
│  └───────────────────────────────┘  │
│                                     │
│  Historique récent                  │
│  ┌───────────────────────────────┐  │
│  │ 🏃 Entraînement               │  │
│  │ 31 déc. 14:30 • 10.2 km       │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

## 🔧 Fichiers à Vérifier

Assurez-vous que ces fichiers/types existent dans votre projet :

- [x] `SessionModel.swift` → Avec `ActivityType` enum
- [x] `SessionTrackingViewModel.swift` → Avec toutes les propriétés
- [x] `TrackingManager.swift` → Pour le GPS
- [x] `SessionService.swift` → Pour Firebase
- [ ] `SessionTrackingView.swift` → Pour les détails de tracking
- [ ] `ActiveSessionDetailView.swift` → Pour les détails de session
- [ ] `SessionDetailView.swift` → Pour l'historique

Si les vues de détail n'existent pas encore, vous pouvez les remplacer temporairement par :
```swift
Text("Détails de session (à implémenter)")
```

## 🚀 Prochaines Étapes

1. **Tester l'intégration** : Lancer l'app et vérifier l'onglet Sessions
2. **Implémenter les vues de détail** : SessionTrackingView, etc.
3. **Ajouter les animations** : Transitions lors des changements d'état
4. **Améliorer les erreurs** : Afficher les messages d'erreur du ViewModel
5. **Ajouter les notifications** : Push quand quelqu'un rejoint une session

## 💡 Notes Importantes

- **Performance** : Le chargement des sessions se fait en parallèle avec `TaskGroup`
- **Réactivité** : Le pull-to-refresh permet de mettre à jour les données
- **État** : Le ViewModel utilise `@Published` pour la réactivité SwiftUI
- **Navigation** : NavigationStack permet le push/pop des détails
- **Permissions** : Vérifier que l'utilisateur a autorisé la localisation

## 🐛 Débogage

Si vous rencontrez des problèmes :

1. **Sessions non affichées** : Vérifier que `squadVM.userSquads` contient des squads
2. **Tracking ne démarre pas** : Vérifier les permissions de localisation
3. **Crash au lancement** : Vérifier que tous les services sont initialisés
4. **UI ne se met pas à jour** : Vérifier que le ViewModel est `@StateObject`

## 📚 Ressources

- Documentation SwiftUI : Navigation et State Management
- Firebase Firestore : Real-time listeners
- Core Location : Background tracking
- HealthKit : Fitness data integration

---

**Auteur :** Assistant IA  
**Date :** 31 décembre 2025  
**Version :** 1.0
