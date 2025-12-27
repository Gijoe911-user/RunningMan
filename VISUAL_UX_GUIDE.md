# 🎨 Guide Visuel UX/UI - RunningMan

## 📱 Flows Utilisateur Améliorés

### 🆕 Flow 1 : Création d'un Squad

```
┌─────────────────────────────────────────────────────────────────┐
│                    CRÉER UN NOUVEAU SQUAD                       │
└─────────────────────────────────────────────────────────────────┘

Étape 1 : Formulaire
┌──────────────────────────┐
│  [Annuler]  Créer Squad  │
│                          │
│      ┌─────────┐         │
│      │ 👥 Icon │         │
│      └─────────┘         │
│                          │
│  Nom du squad            │
│  [Marathon 2024____]     │
│                          │
│  Description             │
│  [Préparation pour...]   │
│                          │
│  ☑️ Squad public          │
│                          │
│  [   CRÉER LE SQUAD   ]  │
└──────────────────────────┘
         │
         │ Appuyer sur "Créer"
         ↓
┌──────────────────────────┐
│  [×]        Succès       │
│                          │
│      ┌─────────┐         │
│      │    ✓    │ 🎉      │
│      └─────────┘         │
│                          │
│   Squad créé ! 🎉        │
│                          │
│  Partagez ce code pour   │
│  inviter vos amis        │
│                          │
│  Code d'invitation       │
│  ┌──────────────────┐   │
│  │  ABC123    [📋]  │   │  ← Copier vers clipboard
│  └──────────────────┘   │
│                          │
│      Copié ! ✓           │  ← Feedback temporaire
│                          │
│  [     TERMINER      ]   │
└──────────────────────────┘
```

**Améliorations :**
- ✅ Code d'invitation mis en avant
- ✅ Copie en un clic avec feedback
- ✅ Haptic feedback
- ✅ Design célébratoire
- ✅ Animation bounce sur checkmark

---

### 🔑 Flow 2 : Rejoindre un Squad

```
┌─────────────────────────────────────────────────────────────────┐
│                    REJOINDRE UN SQUAD                           │
└─────────────────────────────────────────────────────────────────┘

Étape 1 : Saisie du Code
┌──────────────────────────┐
│  [Annuler]               │
│                          │
│      ┌─────────┐         │
│      │  🔑     │         │
│      └─────────┘         │
│                          │
│  Rejoindre un Squad      │
│                          │
│  Entrez le code d'accès  │
│  fourni par le créateur  │
│                          │
│  ┌──────────────────┐   │
│  │  ABC123______    │   │  ← Auto-uppercase, 6 chars max
│  └──────────────────┘   │
│                          │
│  Le code contient        │
│  6 caractères            │
│                          │
│  [  REJOINDRE SQUAD  ]   │  ← Activé si 6 caractères
└──────────────────────────┘
         │
         │ Code valide
         ↓
┌──────────────────────────┐
│  [×]        Succès       │
│                          │
│      ┌─────────┐         │
│      │    ✓    │ 🎉      │
│      └─────────┘         │
│                          │
│    Bienvenue ! 🎉        │
│                          │
│  Vous avez rejoint       │
│                          │
│   Marathon 2024          │  ← Nom du squad
│                          │
│  ┌──────────────────┐   │
│  │ Préparation pour │   │  ← Description
│  │ le marathon de   │   │
│  │ Paris 2024       │   │
│  └──────────────────┘   │
│                          │
│  [     COMMENCER     ]   │
└──────────────────────────┘
```

**Améliorations :**
- ✅ Validation en temps réel (6 chars)
- ✅ Auto-uppercase
- ✅ Écran de bienvenue personnalisé
- ✅ Affichage du nom et description
- ✅ Animation de célébration

---

### 📋 Flow 3 : Liste des Squads

```
┌──────────────────────────────────────────────────────────────┐
│  Mes Squads                                  [Rafraîchir ↻]  │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────┬──────────────────────────┐
│  [+ Créer]               │  [🔍 Rejoindre]          │
└──────────────────────────┴──────────────────────────┘

Vos squads

┌────────────────────────────────────────────────────────┐
│  ┌────┐                                           ✓    │  ← Badge "Actif"
│  │ 👥 │  Marathon 2024                        ┌─────┐ │
│  └────┘  Préparation marathon de Paris        │🟢   │ │  ← Bordure verte
│  ──────────────────────────────────────────────┴─────┘ │
│  🏃 5  👍 2                          [✓ Actif]        │
└────────────────────────────────────────────────────────┘
         │
         │ Appuyer sur carte
         ↓
     SquadDetailView

┌────────────────────────────────────────────────────────┐
│  ┌────┐                                                 │
│  │ 👥 │  Les Runners du Dimanche                       │
│  └────┘  Course tranquille                             │
│  ─────────────────────────────────────────────────────  │
│  🏃 3  👍 1                          [○ Activer]       │  ← Pas actif
└────────────────────────────────────────────────────────┘
         │
         │ Appuyer sur "Activer"
         ↓
┌────────────────────────────────────────────────────────┐
│  ┌────┐                                           ✓    │  ← Devient actif
│  │ 👥 │  Les Runners du Dimanche              ┌─────┐ │
│  └────┘  Course tranquille                    │🟢   │ │  ← Bordure verte
│  ──────────────────────────────────────────────┴─────┘ │
│  🏃 3  👍 1                          [✓ Actif]        │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│  ┌────┐                                                 │
│  │ 👥 │  Marathon 2024                                 │  ← Plus actif
│  └────┘  Préparation marathon                          │
│  ─────────────────────────────────────────────────────  │
│  🏃 5  👍 2                          [○ Activer]       │
└────────────────────────────────────────────────────────┘

─────────────────────────────────────────────────────────

État Vide (aucun squad)
┌────────────────────────────────────────────────────────┐
│                                                         │
│                    👥/                                  │
│                                                         │
│                 Aucun squad                             │
│                                                         │
│     Créez ou rejoignez un squad                        │
│           pour commencer                                │
│                                                         │
└────────────────────────────────────────────────────────┘
```

**Améliorations :**
- ✅ Indicateur visuel du squad actif (badge + bordure)
- ✅ Bouton "Activer" pour changer
- ✅ Données réelles depuis Firestore
- ✅ Pull-to-refresh
- ✅ État vide élégant
- ✅ Indicateur de chargement

---

### 🏠 Flow 4 : Dashboard

```
┌──────────────────────────────────────────────────────────┐
│  Accueil                                                 │
└──────────────────────────────────────────────────────────┘

Bonjour, Jocelyn! 👋
Prêt pour votre prochaine course ?

Cette semaine
┌────────────┬────────────┬────────────┐
│  🏃        │  🗺️        │  ⏰         │
│  5         │  24 km     │  3h 12m    │
│  Courses   │  Distance  │  Temps     │
└────────────┴────────────┴────────────┘

Activité récente
┌────────────────────────────────────────┐
│  Aucune activité récente               │
└────────────────────────────────────────┘

Mes Squads                   Voir tout →
┌──────┐ ┌──────┐ ┌──────┐
│ 👥   │ │ 👥   │ │ 👥   │  ← Scroll horizontal
│      │ │      │ │      │
│Mara  │ │Runner│ │Sprint│
│thon  │ │du    │ │      │
│      │ │      │ │      │
│5 mbr │ │3 mbr │ │4 mbr │
└──────┘ └──────┘ └──────┘
```

**Améliorations :**
- ✅ Section squads dynamique
- ✅ Scroll horizontal
- ✅ Navigation rapide
- ✅ Bouton "Voir tout"
- ✅ Cartes compactes

---

## 🎨 Composants Visuels

### SquadCard (Liste complète)

```
┌────────────────────────────────────────────────┐
│  ┌────┐                                   ✓    │  ← Badge si actif
│  │ 👥 │  Nom du Squad              ┌────────┐ │
│  │    │  Description du squad      │ Border │ │  ← Bordure si actif
│  └────┘  sur 2 lignes max          │ verte  │ │
│           ...                       └────────┘ │
│  ────────────────────────────────────────────  │
│  🏃 5 coureurs  👍 2 supporters                │
│                              [✓ Actif]   →     │  ← Bouton + chevron
└────────────────────────────────────────────────┘
```

**États :**
- Normal : Gradient coral/pink, pas de bordure
- Actif : Gradient green/blue, bordure verte, badge checkmark
- Hover : Effet de surbrillance

---

### DashboardSquadCard (Compact)

```
┌──────────────┐
│  ┌────────┐  │
│  │   👥   │  │  ← Icône gradient
│  └────────┘  │
│              │
│  Marathon    │  ← Nom (1 ligne)
│  2024        │
│              │
│  🏃 5 membres │  ← Compteur
└──────────────┘
  140 x 120pt
```

**Usage :**
- Dashboard (scroll horizontal)
- Quick access
- Navigation vers détails

---

### Success Screen Pattern

```
┌──────────────────────────┐
│  [×]        Titre        │
│                          │
│      ┌─────────┐         │
│      │ ✓ Icône │ ←bounce │
│      └─────────┘         │
│                          │
│   Message Principal      │
│                          │
│  Message secondaire      │
│                          │
│   ┌──────────────────┐  │
│   │                  │  │  ← Zone info
│   │  Contenu central │  │
│   │                  │  │
│   └──────────────────┘  │
│                          │
│  [   ACTION BUTTON   ]   │
└──────────────────────────┘
```

**Utilisé pour :**
- Squad créé (affiche code)
- Squad rejoint (affiche bienvenue)

---

## 🎭 Animations

### Transitions RootView

```
Loading  ───opacity fade───→  Login/Onboarding/Main

Login    ───slide left──────→  Onboarding

Onboarding ─scale + opacity─→  MainTabView

MainTabView ─slide right───→  Dashboard
```

**Durée :** 0.3s easeInOut

---

### Button States

```
Normal    →  Pressed      →  Success
[Button]  →  [Button]     →  [Button]
             (scale 0.95)      (✓ + vibration)
```

---

### Pull to Refresh

```
┌──────────────────┐
│       ↓          │  ← Tirer vers le bas
│   Rafraîchir     │
└──────────────────┘
        │
        ↓
┌──────────────────┐
│       ○          │  ← Spinner
│   Chargement...  │
└──────────────────┘
        │
        ↓
┌──────────────────┐
│   Squads (5)     │  ← Contenu mis à jour
└──────────────────┘
```

---

## 🎨 Design Tokens

### Couleurs

```swift
Primary Actions
├─ coralAccent (#FF6B6B)   // Boutons principaux, coureurs
└─ pinkAccent (#FF85A1)    // Gradients accent

Secondary Actions
├─ blueAccent (#4ECDC4)    // Supporters
└─ purpleAccent (#9B59B6)  // Accents secondaires

Status
├─ greenAccent (#2ECC71)   // Succès, actif
└─ yellowAccent (#F1C40F)  // Avertissements

Background
└─ darkNavy (#1A1F3A)      // Fond principal
```

### Gradients

```swift
Primary
LinearGradient([.coralAccent, .pinkAccent])

Success
LinearGradient([.greenAccent, .blueAccent])

Secondary
LinearGradient([.blueAccent, .purpleAccent])
```

### Typography

```swift
.title              // 28pt, Bold
.title2             // 22pt, Bold
.headline           // 17pt, Semibold
.subheadline        // 15pt, Regular
.body               // 17pt, Regular
.caption            // 12pt, Regular
```

### Spacing Scale

```swift
4pt   // Très petit (rarement utilisé)
8pt   // Petit (inside cards)
12pt  // Normal small
16pt  // Normal
20pt  // Comfortable
24pt  // Large
30pt  // Section spacing
40pt  // Major sections
```

### Corner Radius

```swift
10pt  // Input fields
12pt  // Standard cards
16pt  // Large cards
20pt  // Modal sheets
```

---

## 📱 Responsive Behavior

### SquadCard
- Largeur : max width (fill)
- Hauteur : auto (fit content)
- Min height : 120pt

### DashboardSquadCard
- Largeur : 140pt (fixe)
- Hauteur : 120pt (fixe)
- Scroll horizontal si > 3 cards

### Success Screens
- Full screen modal
- Safe area respected
- Scroll si contenu long

---

## 🎯 Interaction States

### Buttons

```
Enabled
[Button Text]
↓ Press
[Button Text] (scale 0.95)
↓ Release
Action + Haptic
```

### Toggle

```
Off              On
○ Label    →    ● Label
(gray)          (coralAccent)
```

### TextField

```
Empty           Focused         Filled
[____]     →    [|___]     →    [Text]
(white 0.1)     (white 0.15)    (white 0.1)
                border accent
```

---

## ✅ Checklist Visuelle

### Écrans Principaux
- [x] RootView avec transitions
- [x] Dashboard avec squads
- [x] SquadListView avec données réelles
- [x] CreateSquadView avec success
- [x] JoinSquadView avec success
- [ ] SquadDetailView (à faire)
- [ ] SessionsListView avec carte (à faire)
- [ ] ProfileView (à faire)

### Composants
- [x] SquadCard avec sélection
- [x] DashboardSquadCard compact
- [x] Success screens (2 types)
- [x] Empty states
- [x] Loading states

### Animations
- [x] Transitions RootView
- [x] Button press feedback
- [x] Success bounce
- [x] Pull-to-refresh
- [ ] Card flip (future)
- [ ] Slide gestures (future)

### Feedback
- [x] Haptic sur copie
- [x] Haptic sur succès
- [x] Visual feedback (couleur)
- [x] Text feedback (messages)
- [ ] Sound effects (future)

---

## 🎨 Prochaines Améliorations Visuelles

### Court Terme
1. **SquadDetailView**
   - Liste des membres avec avatars
   - Statistiques du squad
   - Graphiques de progression

2. **SessionsListView**
   - Carte interactive
   - Marqueurs runners
   - Trajets en temps réel

3. **ProfileView**
   - Avatar personnalisable
   - Graphiques stats
   - Historique courses

### Moyen Terme
1. **Animations Avancées**
   - Shared element transitions
   - Card flip animations
   - Parallax effects

2. **Interactions**
   - Swipe to delete
   - Long press actions
   - Drag to reorder

3. **Themes**
   - Light mode
   - Custom colors
   - Accessibility modes

---

**Créé le :** 26 Décembre 2025  
**Status :** ✅ Guide complet  
**Usage :** Référence pour développement et design

🎨 **Utilisez ce guide pour maintenir la cohérence visuelle et l'expérience utilisateur !**
