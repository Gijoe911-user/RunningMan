# 🗺️ Dependency Map - RunningMan Components

## Vue d'ensemble des redéclarations identifiées

### ❌ REDÉCLARATION MAJEURE : SessionHistoryDetailView

```
SessionHistoryDetailView (CONFLIT !)
├── ✅ SessionHistoryDetailView.swift (OFFICIELLE - 438 lignes)
│   ├── Imports: SwiftUI, MapKit, Firestore, Combine
│   ├── ViewModel: SessionHistoryViewModel
│   ├── Features: Tabs (overview/participants/map)
│   ├── Composants utilisés:
│   │   ├── SessionStatCard
│   │   ├── SessionSecondaryStatRow
│   │   ├── SessionInfoCard
│   │   ├── SessionNotesCard
│   │   ├── SessionPodiumRow
│   │   ├── SessionParticipantDetailCard
│   │   ├── SessionMapStatItem
│   │   └── SessionEmptyStateView
│   └── Preview avec SessionModel complet
│
└── ❌ SquadSessionsListView.swift (PLACEHOLDER - lignes 434-457)
    ├── Version simplifiée (seulement 24 lignes)
    ├── Pas de ViewModel
    ├── Pas de tabs
    └── TODO: "Ajouter détails complets, carte, tracé GPS"
```

### Solution : **SUPPRIMER** la version dans SquadSessionsListView.swift

---

## Composants UI - État actuel

### ✅ Composants centralisés (SessionUIComponents.swift)
```
SessionUIComponents.swift
├── SessionStatCard                    ✅ Utilisé par SessionHistoryDetailView
├── SessionSecondaryStatRow            ✅ Utilisé par SessionHistoryDetailView
├── SessionStatItem                    ✅ Utilisé par SessionParticipantDetailCard
├── SessionInfoCard                    ✅ Utilisé par SessionHistoryDetailView
├── SessionNotesCard                   ✅ Utilisé par SessionHistoryDetailView
├── SessionPodiumRow                   ✅ Utilisé par SessionHistoryDetailView
├── SessionParticipantDetailCard       ✅ Utilisé par SessionHistoryDetailView
├── SessionMapStatItem                 ✅ Utilisé par SessionHistoryDetailView
├── SessionEmptyStateView              ✅ Utilisé par SessionHistoryDetailView
└── SessionStepHeader                  ✅ Utilisé par Create views
```

### ✅ Composants locaux (SquadSessionsListView.swift)
```
SquadSessionsListView.swift
├── ActiveSessionCard                  ✅ UNIQUE - Spécifique à la liste
├── StatBadgeCompact                   ✅ UNIQUE - Utilisé par ActiveSessionCard
├── HistorySessionCard                 ✅ Référencé mais non défini (TODO)
└── SessionHistoryDetailView           ❌ REDÉCLARATION - À SUPPRIMER
```

---

## Fichiers autonomes

### ✅ StatCard.swift
```
StatCard (générique, 2 styles)
├── Style.compact    → Pour tracking en direct
└── Style.full       → Pour profils et résumés
```

### ✅ LocationPickerView.swift
```
LocationPickerView (unique)
├── Recherche de lieux
├── Sélection sur carte
└── Géolocalisation
```

### ✅ ColorExtensions.swift
```
Color Extensions
├── coralAccent
├── pinkAccent
├── blueAccent
├── greenAccent
├── darkNavy
└── darkNavySecondary
```

---

## Erreurs actuelles expliquées

### 1. "Invalid redeclaration of 'SessionHistoryDetailView'"
**Cause :** 2 définitions de `SessionHistoryDetailView`
- `SessionHistoryDetailView.swift` (la vraie)
- `SquadSessionsListView.swift` ligne 434 (placeholder)

**Solution :** Supprimer celle de SquadSessionsListView.swift

### 2. "Ambiguous use of 'darkNavy', 'coralAccent', etc."
**Cause possible :** Import manquant ou conflit entre :
- `Color.darkNavy` (ColorExtensions.swift)
- Autre définition cachée ?

**Vérification nécessaire :** Chercher d'autres extensions de Color

### 3. "Type 'SessionHistoryViewModel' does not conform to protocol 'ObservableObject'"
**Cause :** Import de Combine manquant ou définition du ViewModel incorrecte

**Statut :** ✅ Déjà corrigé (Combine importé)

### 4. "Ambiguous use of 'init(icon:value:label:color:)'"
**Cause :** Potentiellement un conflit entre :
- `SessionStatCard(icon:value:label:color:)`
- `StatCard(icon:value:label:color:)` (mais signature différente)

**Note :** Normalement OK car les noms sont différents

---

## Plan d'action

### ✅ Étape 1 : Supprimer SessionHistoryDetailView de SquadSessionsListView.swift
```swift
// SUPPRIMER ces lignes (434-457)
struct SessionHistoryDetailView: View { ... }
```

### ✅ Étape 2 : Créer HistorySessionCard (manquant)
```swift
// Dans SquadSessionsListView.swift, ajouter :
struct HistorySessionCard: View {
    let session: SessionModel
    // Affichage résumé pour la liste
}
```

### ⚠️ Étape 3 : Vérifier les imports dans SessionHistoryDetailView.swift
```swift
import SwiftUI          ✅
import MapKit           ✅
import FirebaseFirestore ✅
import Combine          ✅
```

### ⚠️ Étape 4 : Vérifier qu'il n'y a pas d'autre extension Color
Rechercher dans tous les fichiers :
- `extension Color`
- `extension ShapeStyle`
- `static var coralAccent`

---

## Structure cible finale

```
RunningMan/
├── Views/
│   ├── Session/
│   │   ├── SessionHistoryDetailView.swift       ✅ UNIQUE
│   │   ├── ActiveSessionDetailView.swift        ✅ Unique
│   │   └── SquadSessionsListView.swift          ✅ (sans redéclaration)
│   │
│   ├── Create/
│   │   ├── UnifiedCreateSessionView.swift       ✅ (nettoyé)
│   │   └── CreateSessionWithProgramView.swift   ✅ (nettoyé)
│   │
│   └── Shared/
│       ├── LocationPickerView.swift             ✅ UNIQUE
│       └── SessionUIComponents.swift            ✅ Composants centralisés
│
├── Components/
│   ├── StatCard.swift                           ✅ Générique
│   └── DesignSystem.swift                       ✅ Autres composants
│
├── Extensions/
│   └── ColorExtensions.swift                    ✅ Toutes les couleurs
│
└── ViewModels/
    └── SessionHistoryViewModel.swift            ✅ Unique
```

---

## Checklist de validation

- [ ] Une seule déclaration de `SessionHistoryDetailView`
- [ ] `HistorySessionCard` créée dans SquadSessionsListView
- [ ] Pas d'autre extension Color qui redéfinit `.coralAccent`
- [ ] SessionHistoryViewModel conforme à ObservableObject
- [ ] Build réussit sans erreurs
- [ ] Navigation vers SessionHistoryDetailView fonctionne depuis la liste
- [ ] Tabs (overview/participants/map) fonctionnent
- [ ] Carte s'affiche avec le parcours

---

**Prochaine action :** Supprimer le placeholder et créer HistorySessionCard
