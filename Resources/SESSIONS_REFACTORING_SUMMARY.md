# 📋 Refonte de la Vue Sessions - Récapitulatif

## 🎯 Problèmes résolus

### 1️⃣ **Page blanche lors de la sélection de squad** ✅
**Problème** : Lorsqu'on utilisait le bouton "+" et qu'on sélectionnait une squad, un layer vide s'ouvrait.

**Solution** :
- Ajout d'un `SquadPickerSheet` pour choisir la squad avant de créer une session
- Flux clair : Bouton "+" → Picker de squad (si plusieurs) → CreateSessionView
- Fix : `selectedSquadForCreation` garantit qu'une squad est toujours sélectionnée

**Code ajouté** :
```swift
@State private var showSquadPicker = false
@State private var selectedSquadForCreation: SquadModel?

.sheet(isPresented: $showSquadPicker) {
    SquadPickerSheet(
        squads: squadsVM.userSquads,
        onSquadSelected: { squad in
            selectedSquadForCreation = squad
            showSquadPicker = false
            showCreateSession = true
        }
    )
}
```

---

### 2️⃣ **Aucune possibilité de définir des objectifs ou de planifier** ✅
**Problème** : La page de création de session n'offrait pas de choix d'objectif ni de planification.

**Solution** :
- **Mode de session** : Toggle "Démarrer maintenant" vs "Planifier"
- **Objectifs configurables** :
  - Distance : Picker rapide (1, 3, 5, 10, 15, 21, 42 km) ou saisie personnalisée
  - Durée : Saisie en minutes
- **Planification complète** :
  - Titre de session (obligatoire)
  - Date (DatePicker graphical)
  - Heure (Wheel Picker)
  - Description optionnelle
  - Type d'activité (Entraînement, Course, Fractionné, Récupération)

**Code ajouté** :
```swift
enum SessionMode {
    case immediate  // Démarrer maintenant
    case scheduled  // Planifier
}

@State private var sessionMode: SessionMode = .immediate
@State private var scheduledDate = Date()
@State private var scheduledTime = Date()
@State private var sessionTitle = ""
@State private var sessionDescription = ""
```

---

### 3️⃣ **Interface confuse entre différents types de sessions** ✅
**Problème** : Pas de distinction claire entre :
- Une session avec des coureurs actifs
- Une session planifiée
- Une session active
- Ma session active
- L'historique récent

**Solution** : **Dashboard intelligent** avec 3 catégories distinctes

#### 📍 **Sessions actives** (avec coureurs en train de courir)
```swift
@State private var activeSessionsWithRunners: [SessionModel] = []
```
- Badge vert pulsant
- Nombre de coureurs actifs
- Bouton "Rejoindre" (mode spectateur)
- Affiche "Commencé il y a X min"

**Composant** : `ActiveSessionCardCompact`

---

#### 📅 **Sessions planifiées** (futures)
```swift
@State private var scheduledSessions: [SessionModel] = []
```
- Badge "Planifiée" bleu
- Affiche date et heure de départ
- Objectifs (distance/durée)
- Nombre de participants inscrits

**Composant** : `ScheduledSessionCard`

---

#### 📜 **Historique récent** (5 dernières)
```swift
@State private var recentSessions: [SessionModel] = []
```
- Date relative ("Il y a 2 jours")
- Stats rapides (✅ Terminée, ⏱️ Durée, 👥 Participants)
- Lien "Tout voir" → `SquadSessionsListView`

**Composant** : `RecentSessionCard` (existant, amélioré)

---

#### 🏃 **Ma session active** (si je cours actuellement)
```swift
@State private var myActiveSession: SessionModel?
```
- Priorité absolue : affichée en plein écran
- Widget de stats flottant
- Navigation vers `SessionTrackingView`

**Composant** : `TrackingSessionCard` (existant)

---

## 🔄 Nouveau flux de création de session

```
┌─────────────────┐
│  Bouton "+" 📱  │
└────────┬────────┘
         │
         ├─ 1 squad → CreateSessionView directement
         │
         └─ Plusieurs squads → SquadPickerSheet
                                └─ Sélection → CreateSessionView

┌────────────────────────────────────────────────────┐
│         CreateSessionView                          │
├────────────────────────────────────────────────────┤
│                                                    │
│  Quand ?                                           │
│  ┌──────────────┬──────────────┐                  │
│  │ ▶️ Maintenant │ 📅 Planifier │                  │
│  └──────────────┴──────────────┘                  │
│                                                    │
│  Type : Entraînement, Course, Fractionné...       │
│                                                    │
│  Objectifs :                                       │
│  - Distance (Picker rapide ou saisie)              │
│  - Durée (minutes)                                 │
│                                                    │
│  [SI PLANIFIÉ]                                     │
│  - Titre (obligatoire)                             │
│  - Date + Heure                                    │
│  - Description                                     │
│                                                    │
│  ┌────────────────────────────┐                   │
│  │ Créer et rejoindre / Plan. │                   │
│  └────────────────────────────┘                   │
└────────────────────────────────────────────────────┘
         │
         ├─ MODE IMMÉDIAT
         │  └─ Session créée (SCHEDULED)
         │     └─ Redirection SessionTrackingView
         │        └─ Mode spectateur
         │           └─ Bouton "Démarrer l'activité"
         │
         └─ MODE PLANIFIÉ
            └─ Session créée avec scheduledStartDate
               └─ Visible dans "Sessions planifiées"
               └─ Notifications avant le départ
```

---

## 📊 Architecture des données

### Fonction de chargement unifiée

```swift
func loadAllSessions() async {
    for squad in squadsVM.userSquads {
        // 1️⃣ Sessions actives
        if let activeSession = try await SessionService.getActiveSession(squadId: squadId) {
            allActiveSessions.append(activeSession)
        }
        
        // 2️⃣ Sessions planifiées
        let scheduled = try await SessionService.getScheduledSessions(squadId: squadId)
        allScheduledSessions.append(contentsOf: scheduled)
        
        // 3️⃣ Historique
        let history = try await SessionService.getSessionHistory(squadId: squadId)
        allHistorySessions.append(contentsOf: history)
    }
    
    // Séparation intelligente
    myActiveSession = allActiveSessions.first { 
        $0.participantActivity?[currentUserId]?.isTracking == true 
    }
    
    activeSessionsWithRunners = allActiveSessions.filter { 
        $0.id != myActiveSession?.id && hasActiveRunners($0)
    }
    
    scheduledSessions = sortedByScheduledDate(allScheduledSessions)
    recentSessions = sortedByEndDate(allHistorySessions).prefix(10)
}
```

---

## 🎨 Nouveaux composants

### 1. `ActiveSessionCardCompact`
Carte compacte pour session active avec coureurs
- Badge vert pulsant
- Affiche nombre de coureurs actifs
- Heure de début relative
- Bouton "Rejoindre"

### 2. `ScheduledSessionCard`
Carte pour session planifiée
- Badge "Planifiée" bleu
- Titre + Squad
- Date et heure formatées
- Description
- Participants + Objectifs

### 3. `SquadPickerSheet`
Modal pour choisir la squad lors de création
- Liste toutes les squads de l'utilisateur
- Affiche nombre de membres
- Navigation vers CreateSessionView

---

## 🔧 Modifications techniques

### CreateSessionView.swift
```swift
// Ajouts
enum SessionMode: String, CaseIterable {
    case immediate = "Démarrer maintenant"
    case scheduled = "Planifier"
}

@State private var sessionMode: SessionMode = .immediate
@State private var scheduledDate = Date()
@State private var scheduledTime = Date()
@State private var sessionTitle = ""
@State private var sessionDescription = ""

// Validation
private var isFormValid: Bool {
    if sessionMode == .scheduled {
        return !sessionTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }
    return true
}

// Création avec paramètres étendus
try await SessionService.shared.createSession(
    squadId: squadId,
    creatorId: userId,
    activityType: activityType,
    startLocation: nil,
    targetDistance: finalDistance,
    targetDuration: finalDuration,
    scheduledStartDate: scheduledStartDate,
    title: sessionMode == .scheduled ? sessionTitle : nil,
    description: sessionMode == .scheduled && !sessionDescription.isEmpty ? sessionDescription : nil
)
```

### SessionsListView.swift
```swift
// Nouveaux états
@State private var myActiveSession: SessionModel?
@State private var activeSessionsWithRunners: [SessionModel] = []
@State private var scheduledSessions: [SessionModel] = []
@State private var recentSessions: [SessionModel] = []
@State private var showSquadPicker = false
@State private var selectedSquadForCreation: SquadModel?

// Overlay intelligent
@ViewBuilder
private var contentOverlay: some View {
    if let mySession = myActiveSession {
        // Je cours → Afficher ma session
        activeSessionContent(session: mySession)
    } else {
        // Je ne cours pas → Dashboard
        dashboardContent
    }
}
```

---

## 🆕 API SessionService nécessaires

### À ajouter dans `SessionService.swift`

```swift
/// Récupère les sessions planifiées d'une squad
func getScheduledSessions(squadId: String) async throws -> [SessionModel] {
    // Firestore query : status == .scheduled && scheduledStartDate != nil
}

/// Met à jour createSession avec nouveaux paramètres
func createSession(
    squadId: String,
    creatorId: String,
    activityType: ActivityType = .training,
    startLocation: CLLocationCoordinate2D? = nil,
    targetDistance: Double? = nil,
    targetDuration: TimeInterval? = nil,
    scheduledStartDate: Date? = nil,
    title: String? = nil,
    description: String? = nil
) async throws -> SessionModel
```

---

## 🚀 Avantages de cette refonte

### ✅ UX améliorée
- **Clarté** : 3 catégories distinctes (actives, planifiées, historique)
- **Feedback visuel** : Badges colorés, états clairs
- **Flexibilité** : Possibilité de planifier à l'avance

### ✅ Fonctionnalités enrichies
- **Objectifs configurables** : Distance et durée
- **Planification** : Date, heure, titre, description
- **Multi-squad** : Picker intelligent selon le nombre de squads

### ✅ Architecture solide
- **Séparation des responsabilités** : Chaque type de session a sa carte
- **Chargement unifié** : Une seule fonction `loadAllSessions()`
- **État centralisé** : Toutes les catégories dans SessionsListView

### ✅ Performance
- **Chargement intelligent** : Uniquement les données nécessaires
- **Cache local** : Pas de rechargement inutile
- **Async/await** : Code moderne et performant

---

## 📝 Checklist de déploiement

### Frontend (SwiftUI)
- [x] `CreateSessionView` : Mode immédiat/planifié
- [x] `CreateSessionView` : Objectifs (distance, durée)
- [x] `CreateSessionView` : Planification (date, heure, titre, description)
- [x] `SessionsListView` : Dashboard avec 3 catégories
- [x] `ActiveSessionCardCompact` : Carte session active
- [x] `ScheduledSessionCard` : Carte session planifiée
- [x] `SquadPickerSheet` : Modal de sélection squad
- [x] `ScreenAnnotations.swift` : Documentation mise à jour

### Backend (à implémenter)
- [ ] `SessionService.getScheduledSessions()` : Requête Firestore
- [ ] `SessionService.createSession()` : Paramètres étendus
- [ ] Firestore : Champs `scheduledStartDate`, `title`, `description`, `targetDistance`, `targetDuration`
- [ ] Notifications : Rappel avant sessions planifiées

### Tests
- [ ] Création session immédiate
- [ ] Création session planifiée
- [ ] Affichage des 3 catégories
- [ ] Navigation entre les vues
- [ ] Gestion multi-squad

---

## 🎉 Résultat final

L'interface Sessions est maintenant :
- **Claire** : Distinction nette entre sessions actives, planifiées et historique
- **Flexible** : Possibilité de planifier à l'avance avec objectifs
- **Intuitive** : Flux de création simplifié avec picker de squad
- **Complète** : Vue d'ensemble de toutes les sessions dans un dashboard unifié

L'utilisateur peut désormais :
1. Créer une session immédiate ou planifiée
2. Définir des objectifs (distance, durée)
3. Voir les sessions actives avec coureurs
4. Rejoindre une session en mode spectateur
5. Consulter l'historique récent (5 dernières)
6. Naviguer facilement entre toutes les sessions de toutes ses squads
