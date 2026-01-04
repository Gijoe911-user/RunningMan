# 🗺️ Architecture RunningMan - Carte Complète

> Dernière mise à jour : 03/01/2026  
> Ce document cartographie l'architecture complète de l'application RunningMan

---

## 📱 Navigation Principale (MainTabView)

L'application est structurée autour de **4 onglets principaux** :

```
MainTabView (Onglets principaux)
├── 🏠 Onglet 0: ACCUEIL (DashboardView)
│   ├── Message de bienvenue personnalisé
│   ├── Stats de la semaine (courses, distance, temps)
│   ├── Activité récente
│   └── Aperçu des squads (3 premiers)
│
├── 👥 Onglet 1: SQUADS (SquadListView)
│   ├── Liste de toutes les squads de l'utilisateur
│   ├── Navigation vers → SquadDetailView
│   └── Bouton pour créer/rejoindre une squad
│
├── 🏃 Onglet 2: SESSIONS (AllSessionsViewUnified)
│   ├── Vue unifiée de toutes les sessions
│   ├── Carte avec tracking GPS en temps réel
│   ├── Widget de stats flottant (session active)
│   ├── Overlay participants actifs
│   └── Bouton + pour créer une session
│
└── 👤 Onglet 3: PROFIL (ProfileView)
    ├── Informations utilisateur
    ├── ⚙️ Icône paramètres (en haut à gauche)
    ├── Stats personnelles
    └── (Sous-menus en développement)
```

---

## 🔍 Vues Détaillées & Slices

### 1️⃣ **Accueil (DashboardView)**
```
DashboardView
├── Header avec nom d'utilisateur
├── DashboardStatCard (x3)
│   └── Affiche : Courses, Distance, Temps
├── Section Activité récente (placeholder)
└── DashboardSquadCard (x3 max)
    └── Navigation → SquadDetailView
```

---

### 2️⃣ **Détail d'une Squad (SquadDetailView)**

Accessible depuis : `DashboardView` ou `SquadListView`

```
SquadDetailView
├── 📊 Header de la squad
│   ├── Icône avec gradient
│   ├── Nom & description
│   ├── Nombre de membres
│   └── Indicateur session active
│
├── 🔑 Section Code d'invitation
│   ├── Code affiché en grand (monospace)
│   ├── Bouton copier dans le presse-papiers
│   └── Feedback visuel (✓ Copié)
│
├── 🎯 Actions principales
│   ├── 📋 Voir les sessions → SquadSessionsListView
│   ├── 📤 Partager le code (ShareSheet)
│   ├── ▶️ Démarrer une session (si admin/coach) → CreateSessionView
│   └── 🚪 Quitter la squad (si non-créateur)
│
├── 👥 Section Membres
│   ├── MemberRow (x10 max affichés)
│   │   ├── Avatar coloré selon rôle
│   │   ├── Nom (chargé depuis Firebase)
│   │   ├── Badge rôle (Admin/Coach/Membre)
│   │   └── Badge "Créateur" si applicable
│   └── Texte "+ X autres membres"
│
└── 📈 Section Statistiques (placeholder)
    ├── Nombre de sessions
    └── Distance totale
```

**Fonctionnalités clés :**
- Pull-to-refresh pour invalider le cache
- Context défini pour RealtimeLocationService
- Navigation vers liste des sessions

---

### 3️⃣ **Liste des Sessions d'une Squad (SquadSessionsListView)**

Accessible depuis : `SquadDetailView`

```
SquadSessionsListView
├── 📑 Segmented Control personnalisé
│   ├── ⭐ Tab "Actives"
│   └── 🕐 Tab "Historique"
│
├── 📍 Sessions Actives
│   ├── ActiveSessionCard (liste)
│   │   ├── Titre & type d'activité
│   │   ├── Badge de statut (Active/Pause)
│   │   ├── StatBadgeCompact (x3)
│   │   │   ├── Nombre de coureurs
│   │   │   ├── Temps écoulé
│   │   │   └── Distance objectif
│   │   └── Bouton "Rejoindre"
│   │
│   ├── Navigation → SessionHistoryDetailView (temporaire)
│   └── État vide si aucune session
│
└── 📜 Historique
    ├── HistorySessionCard (liste)
    │   └── Navigation → SessionHistoryDetailView
    └── État vide si aucune session passée
```

**Fonctionnalités clés :**
- Chargement avec timeout de 5 secondes
- Cache invalidé au refresh
- État de chargement unique (hasLoaded)
- Pull-to-refresh

---

### 4️⃣ **Détail d'une Session de l'Historique (SessionHistoryDetailView)**

Accessible depuis : `SquadSessionsListView` (historique)

```
SessionHistoryDetailView
├── 📑 Tabs (Segmented Control)
│   ├── 📊 Tab "Vue d'ensemble"
│   ├── 👥 Tab "Participants"
│   └── 🗺️ Tab "Carte"
│
├── TAB 1: Vue d'ensemble
│   ├── SessionStatCard (x3)
│   │   ├── Distance totale
│   │   ├── Durée
│   │   └── Vitesse moyenne
│   │
│   ├── SessionSecondaryStatRow (x2)
│   │   ├── Allure moyenne & Dénivelé
│   │   └── Fréquence cardiaque & Calories
│   │
│   ├── SessionInfoCard
│   │   ├── Date & heure
│   │   ├── Type d'activité
│   │   └── Lieu
│   │
│   └── SessionNotesCard (si notes présentes)
│
├── TAB 2: Participants
│   ├── SessionPodiumRow (Top 3)
│   │   ├── Médailles (🥇 🥈 🥉)
│   │   └── Statistiques du participant
│   │
│   └── SessionParticipantDetailCard (tous)
│       ├── Avatar & nom
│       ├── SessionStatItem (x4)
│       │   ├── Distance
│       │   ├── Temps
│       │   ├── Allure
│       │   └── Vitesse max
│       └── Expansion détails (optionnel)
│
└── TAB 3: Carte
    ├── SessionMapView
    │   ├── Tracé du parcours
    │   ├── Marqueur départ
    │   └── Marqueur arrivée
    │
    └── SessionMapStatItem (x3)
        ├── Distance totale
        ├── Dénivelé positif
        └── Points de passage
```

**Composants utilisés** (depuis `SessionUIComponents.swift`) :
- SessionStatCard
- SessionSecondaryStatRow
- SessionStatItem
- SessionInfoCard
- SessionNotesCard
- SessionPodiumRow
- SessionParticipantDetailCard
- SessionMapStatItem
- SessionEmptyStateView

---

### 5️⃣ **Vue Session Active (SessionsListView)**

Onglet principal "Sessions" (Onglet 2)

```
SessionsListView
├── 🗺️ EnhancedSessionMapView (plein écran)
│   ├── Position utilisateur en temps réel
│   ├── Positions des autres coureurs
│   ├── Tracé GPS du parcours
│   └── Bouton recentrer & sauvegarder tracé
│
├── 📊 SessionStatsWidget (flottant, haut)
│   ├── Distance parcourue
│   ├── Fréquence cardiaque
│   ├── Calories brûlées
│   └── Calculé depuis routeCoordinates
│
├── 👥 SessionParticipantsOverlay (bas de carte)
│   ├── Liste horizontale des coureurs actifs
│   ├── Distance de l'utilisateur à chaque coureur
│   └── Tap → recentrer carte sur coureur
│
├── 📱 SessionActiveOverlay (bas d'écran)
│   ├── Infos session (titre, type, durée)
│   ├── Liste des participants
│   ├── Boutons d'action (pause, terminer)
│   └── Contrôles de la session
│
├── 🆕 Bouton + (toolbar, haut à droite)
│   ├── Visible si squad sélectionnée
│   ├── Désactivé si pas les permissions
│   └── Ouvre → CreateSessionView
│
└── ⚠️ NoSessionOverlay (si aucune session)
    ├── Message "Aucune session active"
    └── Bouton "Créer une session"
```

**Fonctionnalités clés :**
- Tracking GPS temps réel via `SessionsViewModel`
- **Contrôles de tracking GPS** :
  - `SessionTrackingControls` : Boutons pour démarrer/pause/terminer
  - `TrackingStatusIndicator` : Badge flottant avec statut et durée
  - `SessionTrackingViewModel` : Gestion des états et enregistrement
- Calcul de distance via `RouteCalculator`
- Sauvegarde du tracé dans Firebase
- Géolocalisation en continu (indépendante du tracking)

**Machine à états du Tracking :**
```
notStarted → [Démarrer] → active → [Pause] → paused
                            ↑                    ↓
                            └────── [Reprendre] ─┘
                            ↓
                         [Terminer] → completed
```

---

### 6️⃣ **Créer / Démarrer une Session (CreateSessionView)**

Accessible depuis :
- `SessionsListView` (bouton +)
- `SquadDetailView` (bouton "Démarrer une session")
- `NoSessionOverlay`

```
CreateSessionView / UnifiedCreateSessionView
├── 📝 Étape 1 : Informations générales
│   ├── Titre de la session
│   ├── Type d'activité (Course, Marche, Vélo, etc.)
│   ├── Description (optionnel)
│   └── Notes (optionnel)
│
├── 📍 Étape 2 : Localisation
│   ├── LocationPickerView
│   │   ├── Recherche de lieux
│   │   ├── Sélection sur carte
│   │   └── Géolocalisation automatique
│   └── Point de rendez-vous
│
├── 🎯 Étape 3 : Objectifs
│   ├── Distance cible (optionnel)
│   ├── Durée cible (optionnel)
│   ├── Allure cible (optionnel)
│   └── Niveau de difficulté
│
├── 🏃 Étape 4 : Participants
│   ├── Sélection des membres de la squad
│   ├── Nombre max de participants
│   └── Invitation automatique
│
└── 📅 Étape 5 : Planification
    ├── Date & heure de début
    ├── Session immédiate ou planifiée
    └── Bouton "Créer la session"
```

**Composants utilisés :**
- SessionStepHeader (navigation entre étapes)
- LocationPickerView (recherche + carte)

**Variantes :**
- `UnifiedCreateSessionView` : Version complète avec toutes les étapes
- `CreateSessionWithProgramView` : Avec programme d'entraînement prédéfini
- `CreateSessionView` : Version simplifiée pour démarrage rapide

---

### 7️⃣ **Système de Tracking GPS** 🆕

Le tracking GPS est **indépendant** de la création de session et de la géolocalisation.

```
SessionTrackingControls (Boutons de contrôle)
├── État: Not Started
│   └── Bouton "Démarrer" (vert) → Lance l'enregistrement
│
├── État: Active
│   ├── Bouton "Pause" (orange) → Met en pause
│   └── Bouton "Terminer" (rouge) → Termine la session
│
├── État: Paused
│   ├── Bouton "Reprendre" (jaune) → Reprend l'enregistrement
│   └── Bouton "Terminer" (rouge) → Termine la session
│
└── État: Completed
    └── Aucune action possible (grisé)

TrackingStatusIndicator (Badge flottant)
├── Icône animée (selon état)
├── Statut textuel
└── Durée écoulée (HH:MM:SS)

SessionTrackingViewModel
├── trackingState: TrackingState
├── trackingDuration: TimeInterval
├── recordedPoints: [CLLocationCoordinate2D]
├── currentDistance: Double (en mètres)
├── currentPace: Double (en min/km)
└── Méthodes:
    ├── startTracking()
    ├── pauseTracking()
    ├── resumeTracking()
    ├── stopTracking() → Sauvegarde dans Firebase
    └── reset()
```

**Différences clés :**

| Fonctionnalité | Géolocalisation | Tracking GPS |
|----------------|----------------|--------------|
| **Déclenchement** | Automatique à l'ouverture | Manuel (bouton Démarrer) |
| **Affichage** | Position en temps réel sur carte | Position + tracé enregistré |
| **Enregistrement** | Aucun | Points GPS sauvegardés |
| **Contrôle** | Aucun | Démarrer/Pause/Terminer |
| **Durée** | Continue | Mesurée (avec pauses) |
| **Sauvegarde** | Non | Oui (Firebase) |

---

## 🧩 Composants Réutilisables

### Composants Centralisés (`SessionUIComponents.swift`)
```
SessionUIComponents.swift
├── SessionStatCard                    → Cartes de stats principales
├── SessionSecondaryStatRow            → Stats secondaires (2 par ligne)
├── SessionStatItem                    → Item de stat individuel
├── SessionInfoCard                    → Carte d'informations générales
├── SessionNotesCard                   → Affichage des notes
├── SessionPodiumRow                   → Podium top 3
├── SessionParticipantDetailCard       → Détails d'un participant
├── SessionMapStatItem                 → Stats sur la carte
├── SessionEmptyStateView              → État vide générique
└── SessionStepHeader                  → Header d'étapes (création)
```

### Composants Spécifiques (`SquadSessionsListView.swift`)
```
SquadSessionsListView.swift
├── ActiveSessionCard                  → Card pour session active
├── StatBadgeCompact                   → Badge de stat compact
└── HistorySessionCard                 → Card pour session historique
```

### Composants Standalone
```
StatCard.swift
├── Style.compact                      → Tracking en direct
└── Style.full                         → Profils et résumés

LocationPickerView.swift               → Sélection de lieu avec carte

ColorExtensions.swift
├── .coralAccent                       → Couleur principale
├── .pinkAccent
├── .blueAccent
├── .greenAccent
├── .purpleAccent
├── .darkNavy                          → Fond principal
└── .darkNavySecondary
```

---

## 🔄 Flux de Navigation

### Créer une Session
```
MainTabView (Onglet Profil/Squad/Session)
  └─→ SquadDetailView
      └─→ [Bouton "Démarrer une session"]
          └─→ CreateSessionView
              └─→ [Callback] → Retour à MainTabView (Onglet 2: Sessions)
```

### Voir les Sessions d'une Squad
```
MainTabView (Onglet Accueil/Squads)
  └─→ SquadDetailView
      └─→ [Bouton "Voir les sessions"]
          └─→ SquadSessionsListView
              ├─→ Tab Actives
              │   └─→ ActiveSessionCard → SessionHistoryDetailView
              │
              └─→ Tab Historique
                  └─→ HistorySessionCard → SessionHistoryDetailView
                      ├─→ Tab Vue d'ensemble
                      ├─→ Tab Participants
                      └─→ Tab Carte
```

### Rejoindre une Session Active
```
MainTabView (Onglet 2: Sessions)
  └─→ SessionsListView
      ├─→ [Si session active] → SessionActiveOverlay + Carte
      └─→ [Si aucune session] → NoSessionOverlay
          └─→ [Bouton "Créer"] → CreateSessionView
```

---

## 🚧 Fonctionnalités en Développement

### ✅ Complètes
- [x] Navigation principale (4 onglets)
- [x] Détail des squads
- [x] Création de sessions
- [x] Liste des sessions (actives/historique)
- [x] Détail de session historique (3 tabs)
- [x] Géolocalisation temps réel
- [x] Carte avec parcours GPS

### ⚙️ En cours
- [x] **Tracking GPS pour lancer le suivi** ✅ NOUVEAU
  - `SessionTrackingControls` : Boutons Démarrer/Pause/Reprendre/Terminer
  - `TrackingStatusIndicator` : Indicateur visuel du statut (badge flottant)
  - `SessionTrackingViewModel` : Gestion des états et enregistrement des points
  - États : `notStarted` → `active` → `paused` → `completed`
- [ ] ActiveSessionDetailView dédié (utilise SessionHistoryDetailView temporairement)
- [ ] Stats temps réel complètes (fréquence cardiaque, calories)
- [ ] Tracés GPS individuels des coureurs

### 📋 Prévues (non prioritaires)
- [ ] Sous-menus du profil (Paramètres, Statistiques personnelles, etc.)
- [ ] Notifications push
- [ ] Chat de squad
- [ ] Programmes d'entraînement personnalisés
- [ ] Analyse avancée des performances

---

## 🎨 Design System

### Couleurs
```swift
Color.coralAccent          // #FF6B6B - Primaire
Color.pinkAccent           // #FF8FAB - Secondaire
Color.blueAccent           // #4ECDC4 - Info
Color.greenAccent          // #95E1D3 - Succès
Color.purpleAccent         // #A89FED - Highlight
Color.darkNavy             // #1A1F35 - Fond principal
Color.darkNavySecondary    // #252B43 - Fond secondaire
```

### Composants de Base
- **Cards** : `.ultraThinMaterial` avec `RoundedRectangle(cornerRadius: 12-16)`
- **Boutons** : Gradient avec `.coralAccent` → `.pinkAccent`
- **Badges** : Capsule avec background semi-transparent
- **Icons** : SF Symbols avec tailles variées

---

## 📦 Services & ViewModels

```
Services
├── AuthService                        → Authentification Firebase
├── SquadService                       → Gestion des squads
├── SessionService                     → CRUD sessions (avec cache)
├── RealtimeLocationService            → Localisation temps réel
├── RouteTrackingService               → Enregistrement tracés GPS
└── RouteCalculator                    → Calculs distance/dénivelé

ViewModels
├── AppState                           → État global (selectedTab, etc.)
├── AuthViewModel                      → Gestion utilisateur
├── SquadViewModel                     → Liste squads utilisateur
├── SessionsViewModel                  → Session active + tracking
└── SessionHistoryViewModel            → Détails session historique
```

---

## 🐛 Points de Vigilance

### Cache & Performance
- **SessionService** : Cache avec invalidation manuelle
- Pull-to-refresh invalide le cache (`invalidateCache(squadId:)`)
- Timeout de 5 secondes sur chargement des sessions

### Navigation
- Utiliser `@Environment(\.dismiss)` au lieu de `presentationMode`
- Callback après création de session pour redirection fluide
- `hasLoaded` pour éviter les rechargements multiples

### Permissions
- Seuls Admin/Coach/Créateur peuvent démarrer une session (configurable)
- Vérifier `squad.canCreateSession(userId:)` avant d'afficher les boutons

---

## 📄 Fichiers Clés

```
MainTabView.swift                      → Navigation principale (77 lignes)
DashboardView.swift                    → Accueil (225 lignes)
SquadDetailView.swift                  → Détail squad (555 lignes)
SquadSessionsListView.swift            → Liste sessions (393 lignes)
SessionsListView.swift                 → Session active (230 lignes)
SessionHistoryDetailView.swift         → Détail historique (à vérifier)
CreateSessionView.swift                → Création session (461 lignes)
UnifiedCreateSessionView.swift         → Création complète (943 lignes)
SessionUIComponents.swift              → Composants UI centralisés
SessionTrackingControls.swift          → 🆕 Contrôles tracking GPS
SessionTrackingViewModel.swift         → 🆕 ViewModel tracking GPS
```

---

## 🔍 Audit des Composants (03/01/2026)

### Objectif
Identifier et supprimer les composants obsolètes via des identifiants de logs.

### Identifiants Ajoutés
- ✅ **TrackingManager.swift** : 4 identifiants (AUDIT-TM-01 à AUDIT-TM-04)
- ✅ **SessionsListView.swift** : 4 identifiants (AUDIT-SLV-01 à AUDIT-SLV-04)
- ✅ **SessionCardComponents.swift** : 2 identifiants (AUDIT-TSC-01, AUDIT-HSC-01)
- ✅ **RouteTrackingService.swift** : 5 identifiants (AUDIT-RTS-01 à AUDIT-RTS-05)
- ✅ **RealtimeLocationService.swift** : 3 identifiants (AUDIT-RLS-01 à AUDIT-RLS-03)
- ✅ **SquadDetailView.swift** : 2 identifiants (AUDIT-SDV-01, AUDIT-SDV-02)
- ✅ **SquadSessionsListView.swift** : 1 identifiant (AUDIT-SSL-01)

### Fichiers à Supprimer (Doublons identifiés)
```bash
# Code Swift (doublons)
SessionTrackingViewModel.swift         # Doublon de TrackingManager.swift
SessionTrackingControls.swift          # Fonctionnalité déjà dans TrackingManager

# Guides/Documentation redondante
SessionsListView+TrackingIntegration.swift
TRACKING_GPS_GUIDE.md
TRACKING_IMPLEMENTATION_SUMMARY.md
TRACKING_VISUAL_GUIDE.md
QUICK_START_TRACKING.md
```

### Comment Effectuer l'Audit
1. Lancer l'app en mode Debug
2. Parcourir TOUS les scénarios (voir `AUDIT_IDENTIFIERS.md`)
3. Filtrer les logs par `[AUDIT-`
4. Noter quels identifiants apparaissent
5. Les composants jamais appelés = obsolètes
6. Supprimer les fichiers inutilisés

**📄 Documentation complète :** `AUDIT_IDENTIFIERS.md`

---

**✅ Architecture à jour et documentée**  
**🚀 Prêt pour la suite du développement**
