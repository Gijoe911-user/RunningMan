# 🧭 Problèmes de Navigation et Solutions

> **Date :** 28 Décembre 2025  
> **Problème :** Navigation confuse, vues incorrectes affichées

---

## 🐛 Problèmes identifiés

### 1. **Confusion entre SessionsListView et SquadSessionsListView**

**Problème actuel :**

```
SessionsListView (Onglet "Sessions")
    ↓
  Affiche UNIQUEMENT la carte avec session active
  Pas d'accès à la liste des sessions
  Pas d'historique visible
```

**Ce que l'utilisateur attend :**

```
Onglet "Sessions"
    ↓
  Liste des sessions actives de TOUS les squads
  Historique récent
  Possibilité de rejoindre ou voir détails
```

---

### 2. **Deux vues avec des noms similaires**

**Fichiers actuels :**

1. **`SessionsListView.swift`** (dans l'onglet principal)
   - Affiche une CARTE avec la session active
   - Pas de liste réelle
   - Nom trompeur!

2. **`SquadSessionsListView.swift`** (dans SquadDetailView)
   - Affiche la vraie liste des sessions d'un squad
   - Onglets "Actives" / "Historique"
   - Navigation vers détails

**Confusion :** Les noms suggèrent l'inverse de ce qu'ils font!

---

## 📊 Structure actuelle de navigation

```
MainTabView
├── Tab 0: Dashboard
├── Tab 1: Squads
│   └── SquadListView
│       └── NavigationLink → SquadDetailView
│           ├── Bouton "Voir les sessions"
│           └── NavigationLink → SquadSessionsListView ✅ (BONNE LISTE)
│               ├── Onglet "Actives"
│               └── Onglet "Historique"
├── Tab 2: Sessions ❌ (CARTE, PAS DE LISTE)
│   └── SessionsListView
│       └── Affiche carte + session active seulement
└── Tab 3: Profil
```

---

## ✅ Solutions proposées

### Option 1 : Renommer les vues (Recommandé)

**Renommages :**

1. `SessionsListView.swift` → **`ActiveSessionMapView.swift`**
   - Nom reflète mieux son rôle : afficher la carte
   - Plus clair pour les développeurs

2. `SquadSessionsListView.swift` → **`SessionsListView.swift`**
   - C'est la vraie liste de sessions
   - Devrait être dans l'onglet principal

**Nouvelle structure :**

```
MainTabView
├── Tab 2: Sessions
│   └── SessionsListView (ex-SquadSessionsListView)
│       ├── Segmented: [Toutes | Mon Squad]
│       ├── Onglet "Actives"
│       └── Onglet "Historique"
│       └── NavigationLink → ActiveSessionMapView (carte)
```

---

### Option 2 : Changer le contenu de l'onglet Sessions

**Modification :**

Au lieu d'afficher la carte dans `SessionsListView`, afficher la liste complète avec onglets.

**Code pour MainTabView.swift :**

```swift
// Onglet 2 : Sessions
SquadSessionsListView(squad: squadsVM.selectedSquad ?? defaultSquad)
    .tabItem {
        Label("Sessions", systemImage: "list.bullet.rectangle")
    }
    .tag(2)
```

**Problème :** Nécessite un squad sélectionné. Comment gérer si aucun squad?

---

### Option 3 : Vue hybride (Meilleur compromis)

**Créer une nouvelle vue `AllSessionsView`** qui combine :

1. **Section "Mes squads"** : Liste des squads avec sessions actives
2. **Section "Sessions actives"** : Toutes les sessions en cours
3. **Section "Historique récent"** : Dernières sessions terminées
4. **Bouton flottant** : Voir la carte

**Structure :**

```swift
AllSessionsView
├── Header: "Mes Sessions"
├── Section: "Squads avec sessions actives"
│   ├── Squad A (🟢 1 session active)
│   └── Squad B (🟢 2 sessions actives)
├── Section: "Sessions actives"
│   ├── Session 1 [Rejoindre]
│   ├── Session 2 [Rejoindre]
│   └── Session 3 [Voir]
├── Section: "Historique récent"
│   ├── Session passée 1
│   └── Session passée 2
└── Floating Button: [Carte 🗺️]
```

---

## 🎯 Implémentation recommandée (Option 3)

### Étape 1 : Créer `AllSessionsView.swift`

```swift
import SwiftUI

struct AllSessionsView: View {
    @Environment(SquadViewModel.self) private var squadVM
    
    @State private var activeSessions: [SessionModel] = []
    @State private var recentHistory: [SessionModel] = []
    @State private var isLoading = true
    @State private var showMap = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Squads avec sessions actives
                        if !squadsWithActiveSessions.isEmpty {
                            squadsSection
                        }
                        
                        // Sessions actives (toutes)
                        if !activeSessions.isEmpty {
                            activeSessionsSection
                        }
                        
                        // Historique récent
                        if !recentHistory.isEmpty {
                            historySection
                        }
                        
                        // Empty state
                        if activeSessions.isEmpty && recentHistory.isEmpty {
                            emptyState
                        }
                    }
                    .padding()
                }
                
                // Bouton flottant pour voir la carte
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showMap = true
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Carte")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.coralAccent)
                            .clipShape(Capsule())
                            .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Sessions")
            .navigationDestination(isPresented: $showMap) {
                ActiveSessionMapView()  // La vue carte actuelle
            }
            .task {
                await loadAllSessions()
            }
            .refreshable {
                await loadAllSessions()
            }
        }
    }
    
    // MARK: - Sections
    
    private var squadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mes Squads")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            ForEach(squadsWithActiveSessions) { squad in
                NavigationLink(destination: SquadSessionsListView(squad: squad)) {
                    SquadActiveSessionCard(squad: squad)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sessions actives")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(activeSessions.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            
            ForEach(activeSessions) { session in
                NavigationLink(destination: ActiveSessionDetailView(session: session)) {
                    ActiveSessionCard(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique récent")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            ForEach(recentHistory.prefix(5)) { session in
                NavigationLink(destination: SessionHistoryDetailView(session: session)) {
                    HistorySessionCard(session: session)
                }
                .buttonStyle(.plain)
            }
            
            if recentHistory.count > 5 {
                NavigationLink("Voir tout l'historique") {
                    // Vue d'historique complet
                }
                .font(.subheadline)
                .foregroundColor(.coralAccent)
                .padding()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 80))
                .foregroundColor(.coralAccent.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Aucune session")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Créez ou rejoignez une session pour commencer")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Computed Properties
    
    private var squadsWithActiveSessions: [SquadModel] {
        squadVM.squads.filter { $0.hasActiveSessions }
    }
    
    // MARK: - Load Data
    
    private func loadAllSessions() async {
        isLoading = true
        
        // TODO: Charger toutes les sessions de tous les squads de l'utilisateur
        // Pour l'instant, charger depuis le squad sélectionné
        guard let selectedSquad = squadVM.selectedSquad,
              let squadId = selectedSquad.id else {
            isLoading = false
            return
        }
        
        do {
            activeSessions = try await SessionService.shared.getActiveSessions(squadId: squadId)
            recentHistory = try await SessionService.shared.getSessionHistory(squadId: squadId)
            isLoading = false
        } catch {
            Logger.logError(error, context: "loadAllSessions", category: .service)
            isLoading = false
        }
    }
}

// MARK: - Squad Active Session Card

struct SquadActiveSessionCard: View {
    let squad: SquadModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Squad icon
            Circle()
                .fill(LinearGradient(
                    colors: [.coralAccent, .pinkAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.white)
                }
            
            // Squad info
            VStack(alignment: .leading, spacing: 4) {
                Text(squad.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    // TODO: Afficher le nombre réel de sessions actives
                    Text("Session active")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

---

### Étape 2 : Modifier MainTabView.swift

```swift
// Onglet 2 : Sessions
AllSessionsView()
    .tabItem {
        Label("Sessions", systemImage: "list.bullet.rectangle.fill")
    }
    .tag(2)
```

---

### Étape 3 : Renommer SessionsListView

**Ancien nom :** `SessionsListView.swift`  
**Nouveau nom :** `ActiveSessionMapView.swift`

**Changements :**

```swift
// Avant
struct SessionsListView: View { ... }

// Après
struct ActiveSessionMapView: View { ... }
```

---

## 📋 Checklist de migration

- [ ] Créer `AllSessionsView.swift`
- [ ] Renommer `SessionsListView` → `ActiveSessionMapView`
- [ ] Modifier `MainTabView.swift` pour utiliser `AllSessionsView`
- [ ] Tester la navigation : Tab Sessions → Liste → Détails
- [ ] Tester la navigation : Liste → Carte (bouton flottant)
- [ ] Tester : Squad Detail → Voir sessions → même liste
- [ ] Vérifier que tous les liens de navigation fonctionnent

---

## 🎨 Flow de navigation après corrections

```
MainTabView
├── Tab 0: Dashboard
│   └── Widgets, statistiques
│
├── Tab 1: Squads
│   └── SquadListView
│       └── NavigationLink → SquadDetailView
│           ├── Bouton "Voir les sessions"
│           └── NavigationLink → SquadSessionsListView
│               ├── Onglet "Actives"
│               └── Onglet "Historique"
│
├── Tab 2: Sessions ✅ (NOUVELLE VUE)
│   └── AllSessionsView
│       ├── Section: Squads avec sessions actives
│       ├── Section: Sessions actives (toutes)
│       ├── Section: Historique récent
│       └── Bouton flottant → ActiveSessionMapView (carte)
│
└── Tab 3: Profil
```

---

## 🔍 Différences claires

### Avant (Confus)

| Nom du fichier | Ce qu'il fait réellement |
|----------------|--------------------------|
| `SessionsListView` | Affiche une CARTE (pas une liste!) |
| `SquadSessionsListView` | Affiche la vraie LISTE |

### Après (Clair)

| Nom du fichier | Ce qu'il fait |
|----------------|---------------|
| `AllSessionsView` | Vue d'ensemble : toutes sessions + historique |
| `SquadSessionsListView` | Sessions d'un squad spécifique |
| `ActiveSessionMapView` | Carte avec session active en temps réel |
| `ActiveSessionDetailView` | Détails d'une session active |
| `SessionHistoryDetailView` | Détails d'une session passée |

---

## ✅ Avantages de la solution

1. **Clarté :** Noms de fichiers reflètent leur contenu
2. **Découverte :** Utilisateur voit toutes ses sessions d'un coup d'œil
3. **Navigation intuitive :** Carte accessible via bouton flottant
4. **Flexibilité :** Peut voir sessions par squad OU globalement
5. **Performance :** Chargement progressif possible

---

## 🧪 Tests de validation

### Test 1 : Onglet Sessions
1. Ouvrir l'app
2. Aller dans l'onglet "Sessions"
3. **Résultat attendu :** Liste des squads, sessions actives, historique

### Test 2 : Navigation vers carte
1. Dans l'onglet Sessions
2. Cliquer sur bouton flottant "Carte"
3. **Résultat attendu :** Carte avec session active

### Test 3 : Navigation depuis Squad
1. Onglet Squads → Sélectionner un squad
2. Cliquer sur "Voir les sessions"
3. **Résultat attendu :** Liste des sessions de CE squad

### Test 4 : Rejoindre une session
1. Onglet Sessions → Session active
2. Cliquer sur "Rejoindre"
3. **Résultat attendu :** Navigation vers carte avec session active

---

## 📝 Notes d'implémentation

### Chargement des sessions multi-squads

```swift
// Dans AllSessionsView
private func loadAllSessions() async {
    // Charger les sessions de TOUS les squads de l'utilisateur
    let userSquads = squadVM.squads
    
    var allActiveSessions: [SessionModel] = []
    var allHistorySessions: [SessionModel] = []
    
    for squad in userSquads {
        guard let squadId = squad.id else { continue }
        
        if let active = try? await SessionService.shared.getActiveSessions(squadId: squadId) {
            allActiveSessions.append(contentsOf: active)
        }
        
        if let history = try? await SessionService.shared.getSessionHistory(squadId: squadId) {
            allHistorySessions.append(contentsOf: history)
        }
    }
    
    // Trier par date
    activeSessions = allActiveSessions.sorted { $0.startedAt > $1.startedAt }
    recentHistory = allHistorySessions.sorted { ($0.endedAt ?? Date()) > ($1.endedAt ?? Date()) }
}
```

---

## 🚀 Prochaines étapes

1. **Créer `AllSessionsView.swift`** avec le code ci-dessus
2. **Renommer `SessionsListView`** → `ActiveSessionMapView`
3. **Modifier `MainTabView`** pour utiliser la nouvelle vue
4. **Tester** la navigation complète
5. **Documenter** les changements pour l'équipe

---

**Questions à se poser :**

- Voulez-vous implémenter Option 3 (recommandée) ?
- Souhaitez-vous que je crée le fichier `AllSessionsView.swift` complet ?
- Y a-t-il d'autres vues de navigation confuses ?

---

**Date de mise à jour :** 28 Décembre 2025

