# 🎨 UX Redesign - Vue Session Active

**Date :** 29 décembre 2024  
**Objectif :** Maximiser la visibilité de la carte + déplacer les infos sous la carte

---

## 🎯 Vision Cible

### Problèmes Actuels
- ❌ Trop d'overlays masquent la carte
- ❌ Boutons de contrôle peu accessibles
- ❌ Widget stats prend trop de place
- ❌ Participants overlay cache la carte

### Solution
- ✅ Carte plein écran avec overlays minimalistes
- ✅ Barre de progression légère (si objectif)
- ✅ Boutons de contrôle visibles en bas
- ✅ Toutes les infos détaillées sous la carte (scrollable)

---

## 📐 Nouvelle Structure

```
┌────────────────────────────────────────┐
│  Navigation Bar                   [+]  │
├────────────────────────────────────────┤
│                                        │
│                                        │
│         CARTE PLEIN ÉCRAN              │
│      (Tracé GPS + Coureurs)            │
│                                        │
│   ┌──────────────────────────────┐    │
│   │ 🏃 ━━━━●━━━━━━━ 🏁           │    │ ← Barre progression (si objectif)
│   │ 2.5 km / 5.0 km              │    │
│   └──────────────────────────────┘    │
│                                        │
│   [📍 Recentrer]  [💾 Sauvegarder]    │ ← Contrôles visibles
│                                        │
├────────────────────────────────────────┤
│  📊 STATS RAPIDES (sticky)            │
│  ⏱️ 20:45  📍 2.5km  🏃 3 coureurs    │
├────────────────────────────────────────┤
│  (Scrollable)                          │
│                                        │
│  👥 Participants                       │
│  [Avatar1] [Avatar2] [Avatar3]         │ ← Cliquables
│  [Centrer] [Centrer] [Centrer]         │
│                                        │
│  📈 Statistiques Détaillées            │
│  ┌────────┐ ┌────────┐               │
│  │Distance│ │ Allure │               │
│  │ 2.5 km │ │5:30/km│               │
│  └────────┘ └────────┘               │
│  ┌────────┐ ┌────────┐               │
│  │Vitesse │ │  BPM  │               │
│  │ 12km/h │ │  145  │               │
│  └────────┘ └────────┘               │
│                                        │
│  [🛑 Terminer la session]              │
│                                        │
└────────────────────────────────────────┘
```

---

## 📁 Fichiers Créés

### 1. SessionProgressBar.swift ✅

**Responsabilité :** Barre de progression visuelle

**Features :**
- Icône coureur qui avance
- Drapeau d'arrivée
- Couleur dynamique (coral → orange → green → pink)
- Animation fluide
- Texte "X km / Y km"

**Usage :**
```swift
if let targetDistance = session.targetDistanceMeters {
    SessionProgressBar(
        currentDistance: 2500,
        targetDistance: 5000
    )
}
```

---

### 2. SessionDetailsPanel.swift ✅

**Responsabilité :** Panel détaillé sous la carte

**Sections :**
1. **Stats rapides** (sticky) : Temps, Distance, Nb coureurs
2. **Participants** : Avatars cliquables pour centrer la carte
3. **KPI détaillés** : Distance, Allure, Vitesse, BPM
4. **Bouton terminer** : Avec confirmation

**Features :**
- Scrollable
- Handle pour indiquer le swipe
- Callbacks pour actions (centrer, terminer)

**Usage :**
```swift
SessionDetailsPanel(
    session: session,
    viewModel: viewModel,
    currentDistance: 2500,
    onRunnerTap: { runnerId in /* centrer */ },
    onEndSession: { /* terminer */ }
)
```

---

## 🔄 Modifications à Appliquer

### Dans SessionsListView.swift

Remplacer la fonction `activeSessionContent` :

```swift
// ❌ ANCIEN (masque la carte)
private func activeSessionContent(session: SessionModel) -> some View {
    VStack(spacing: 0) {
        Spacer()
        statsWidget(session: session)      // Widget flottant
        Spacer()
        participantsOverlay                 // Overlay participants
        SessionActiveOverlay(...)           // Overlay bas
    }
}

// ✅ NOUVEAU (carte maximale)
private func activeSessionContent(session: SessionModel) -> some View {
    VStack(spacing: 0) {
        // Zone carte plein écran
        ZStack(alignment: .bottom) {
            Color.clear
            
            VStack(spacing: 12) {
                // Barre de progression (si objectif)
                if let targetDistance = session.targetDistanceMeters {
                    SessionProgressBar(
                        currentDistance: currentDistance,
                        targetDistance: targetDistance
                    )
                    .padding(.horizontal)
                    .padding(.top, 60)
                }
                
                Spacer()
                
                // Boutons de contrôle (visibles)
                HStack(spacing: 16) {
                    Button { viewModel.centerOnUserLocation() } label: {
                        Label("Recentrer", systemImage: "location.fill")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    
                    Button { saveCurrentRoute() } label: {
                        Label("Sauvegarder", systemImage: "arrow.down.doc.fill")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .frame(maxHeight: .infinity)
        
        // Panel détaillé sous la carte
        SessionDetailsPanel(
            session: session,
            viewModel: viewModel,
            currentDistance: currentDistance,
            onRunnerTap: { runnerId in
                Logger.log("Centrer sur: \(runnerId)", category: .location)
                // TODO: Centrer la carte
            },
            onEndSession: {
                Task { try? await viewModel.endSession() }
            }
        )
        .frame(maxHeight: 400)
    }
}

// Ajouter computed property
private var currentDistance: Double {
    RouteCalculator.calculateTotalDistance(from: viewModel.routeCoordinates)
}
```

---

## 🎨 Avantages du Nouveau Design

### Carte
✅ **Visible à 100%** : Aucun overlay massif  
✅ **Contrôles accessibles** : Boutons clairs en bas  
✅ **Progression claire** : Barre animée si objectif  

### Infos
✅ **Organisées** : Tout sous la carte, logique  
✅ **Scrollables** : Ne prend pas toute la place  
✅ **Cliquables** : Avatars pour centrer sur un coureur  

### UX
✅ **Non intrusif** : Carte reste utilisable  
✅ **Progressive disclosure** : Stats détaillées accessibles en scrollant  
✅ **Actions claires** : Boutons bien visibles  

---

## 🔮 Future : Vue Historique

### Modifications Prévues

Pour l'historique des sessions terminées :

```swift
struct SessionHistoryDetailView: View {
    let session: SessionModel
    let finalStats: SessionStats
    
    var body: some View {
        VStack(spacing: 0) {
            // Carte avec tracé (zoomable, pas de live)
            Map {
                MapPolyline(coordinates: finalStats.routeCoordinates)
                    .stroke(.coralAccent, lineWidth: 3)
            }
            .frame(height: 300)
            
            // Stats finales (scroll)
            ScrollView {
                VStack(spacing: 20) {
                    // KPI finaux
                    SessionFinalStatsGrid(stats: finalStats)
                    
                    // Graphiques (Phase 2)
                    // SpeedChart, HeartRateChart, etc.
                }
                .padding()
            }
        }
        .navigationTitle("Session du \(session.startedAt.formatted())")
    }
}
```

**Différences avec Session Active :**
- ❌ Pas de participants visibles
- ❌ Pas d'avatars cliquables
- ❌ Pas de live tracking
- ✅ Carte zoomable statique
- ✅ Tracé complet visible
- ✅ Stats finales
- ✅ Graphiques (Phase 2)

---

## ✅ Checklist d'Implémentation

### Immédiat
- [x] SessionProgressBar.swift créé
- [x] SessionDetailsPanel.swift créé
- [ ] Modifier SessionsListView.swift
- [ ] Supprimer anciennes fonctions (statsWidget, participantsOverlay)
- [ ] Build & Test

### Phase 2 (Historique)
- [ ] Créer SessionHistoryDetailView
- [ ] Créer SessionFinalStatsGrid
- [ ] Intégrer dans l'historique des sessions

---

## 🧪 Tests à Faire

### Test 1 : Carte Visible
1. Lancer une session
2. Vérifier que la carte est bien visible
3. Vérifier les boutons Recentrer et Sauvegarder

### Test 2 : Barre de Progression
1. Créer une session avec objectif (5 km)
2. Vérifier la barre apparaît
3. Marcher et voir l'icône coureur avancer

### Test 3 : Panel Détails
1. Scroll vers le bas
2. Voir les participants
3. Cliquer sur un avatar (devrait centrer la carte)
4. Voir les KPI détaillés

### Test 4 : Terminer Session
1. Cliquer sur "Terminer"
2. Confirmer
3. Vérifier retour à l'état vide

---

## 📊 Comparaison Avant/Après

| Aspect | Avant | Après |
|--------|-------|-------|
| **Carte visible** | 40% | 80% |
| **Overlays** | 4 overlays | 1 barre légère |
| **Infos détaillées** | Masquent carte | Sous la carte |
| **Contrôles** | Cachés | Visibles |
| **Progression** | Non | Oui (barre animée) |
| **Participants cliquables** | Non | Oui |
| **UX** | Chargée | Épurée |

---

## 🚀 Prochaines Étapes

1. **Appliquer les modifications** dans SessionsListView.swift (copier le nouveau `activeSessionContent`)
2. **Build & Test** (`Cmd + B` puis `Cmd + R`)
3. **Créer une session de test** avec objectif 5 km
4. **Valider l'UX**
5. **Passer à l'historique** (Phase 2)

---

**Temps estimé : 15 minutes**  
**Difficulté : Moyenne**

**Voulez-vous que j'applique les modifications maintenant ?** 🚀
