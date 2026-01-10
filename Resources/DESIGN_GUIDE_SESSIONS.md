# 🎨 Guide de Design - Sessions Refonte

## 📐 Spécifications des composants

### 1️⃣ ActiveSessionCardCompact

**Dimensions** :
- Hauteur : 80pt
- Padding horizontal : 20pt (de l'écran)
- Corner radius : 12pt

**Couleurs** :
- Background : Linear Gradient
  - Départ : `Color.green.opacity(0.1)`
  - Fin : `Color.green.opacity(0.05)`
- Border : `Color.green.opacity(0.3)` - 1pt
- Badge pulsant :
  - Cercle extérieur : `Color.green.opacity(0.2)` - 50x50pt
  - Cercle intérieur : `Color.green` - 30x30pt
- Texte principal : White
- Texte secondaire : White 70% opacity
- Bouton "Rejoindre" : `Color.green` avec texte blanc

**Typographie** :
- Nom squad : Subheadline Bold, White
- Coureurs actifs : Caption Bold (nombre), Caption (texte), Green/White 70%
- Heure relative : Caption2, White 50%
- Bouton : Caption Bold, White

**Animation** :
- Badge pulsant : Scale 1.0 → 1.1 → 1.0 (2s loop)

---

### 2️⃣ ScheduledSessionCard

**Dimensions** :
- Hauteur : Auto (contenu variable)
- Padding horizontal : 20pt
- Padding interne : 12pt
- Corner radius : 12pt
- Spacing vertical : 12pt

**Couleurs** :
- Background : `.ultraThinMaterial`
- Badge "Planifiée" :
  - Background : `Color.blueAccent.opacity(0.2)`
  - Text : `Color.blueAccent`
- Icônes : Accent colors (calendar=blueAccent, clock=blueAccent, person=pinkAccent, location=coralAccent)

**Typographie** :
- Titre : Subheadline Bold, White
- Squad : Caption, White 60%
- Date/Heure : Caption, White 80%
- Description : Caption2, White 60%, 2 lignes max
- Stats : Caption2, White 70%

**Sections** :
1. En-tête : Titre + Squad + Badge
2. Date et heure : 2 Labels horizontaux
3. Description (optionnelle)
4. Footer : Participants + Objectifs

---

### 3️⃣ SquadPickerSheet

**Dimensions** :
- Modal plein écran
- Header icon : 60x60pt
- Carte squad : Hauteur 70pt
- Padding : 20pt

**Couleurs** :
- Background : `Color.darkNavy`
- Cartes :
  - Background : `.ultraThinMaterial`
  - Corner radius : 12pt
- Icône squad :
  - Background : `Color.coralAccent.opacity(0.2)` - 50x50pt
  - Icon : `Color.coralAccent`

**Typographie** :
- Titre principal : Title2 Bold, White
- Sous-titre : Subheadline, White 70%, centré
- Nom squad : Subheadline Bold, White
- Membres : Caption, White 60%

**Interaction** :
- Tap : Scale down 0.95 + haptic feedback
- Navigation : Chevron right, White 50%

---

### 4️⃣ CreateSessionView - Mode Toggle

**Dimensions** :
- Boutons : Hauteur 50pt, width égale
- Spacing : 12pt entre boutons
- Padding vertical : 14pt
- Corner radius : 12pt

**Couleurs** :
- **Sélectionné** :
  - Background : Linear Gradient (coralAccent → pinkAccent)
  - Border : `Color.coralAccent` - 2pt
  - Text : White
  - Icon : White
- **Non sélectionné** :
  - Background : Linear Gradient (White 10% → White 5%)
  - Border : None
  - Text : White 70%
  - Icon : White 70%

**Typographie** :
- Text : Subheadline Bold
- Icon : Title3

**Icônes** :
- Immédiat : `play.circle.fill`
- Planifié : `calendar.badge.clock`

**Animation** :
- Transition : Spring (response: 0.3, damping: 0.7)
- Scale : 1.0 → 0.98 → 1.0 au tap

---

### 5️⃣ Section Headers (Dashboard)

**Dimensions** :
- Hauteur : 30pt
- Padding horizontal : 20pt
- Spacing : 8pt entre icon et texte

**Variantes** :

**Sessions actives** :
- Icon : Cercle vert `Color.green` - 10x10pt
- Text : Title3 Bold, White
- Position : Horizontal stack

**Sessions planifiées** :
- Icon : `calendar` - `Color.blueAccent`
- Text : Title3 Bold, White
- Position : Horizontal stack

**Sessions récentes** :
- Icon : `clock.arrow.circlepath` - `Color.pinkAccent`
- Text : Title3 Bold, White
- Button "Tout voir" : Subheadline, `Color.coralAccent`
- Position : Horizontal stack avec Spacer

---

## 🎯 États visuels

### Dashboard - 4 états possibles

#### État 1 : Je cours actuellement
```
┌─────────────────────────────────────┐
│        🗺️ CARTE PLEIN ÉCRAN         │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 📊 Stats Widget (flottant)    │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🏃 TrackingSessionCard        │ │
│  │    (Plein écran)              │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### État 2 : Sessions disponibles (actives + planifiées + historique)
```
┌─────────────────────────────────────┐
│        🗺️ CARTE (fond)              │
├─────────────────────────────────────┤
│ 📍 Sessions actives                 │
│ ┌─────────────────────────────────┐ │
│ │ ActiveSessionCardCompact        │ │
│ │ ActiveSessionCardCompact        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📅 Sessions planifiées              │
│ ┌─────────────────────────────────┐ │
│ │ ScheduledSessionCard            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 📜 Sessions récentes    Tout voir   │
│ ┌─────────────────────────────────┐ │
│ │ RecentSessionCard               │ │
│ │ RecentSessionCard               │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### État 3 : Uniquement historique
```
┌─────────────────────────────────────┐
│        🗺️ CARTE (fond)              │
├─────────────────────────────────────┤
│                                     │
│        📭 État vide                 │
│   Aucune session active             │
│                                     │
│ 📜 Sessions récentes    Tout voir   │
│ ┌─────────────────────────────────┐ │
│ │ RecentSessionCard               │ │
│ │ RecentSessionCard               │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### État 4 : Vide complet
```
┌─────────────────────────────────────┐
│        🗺️ CARTE (fond)              │
├─────────────────────────────────────┤
│                                     │
│            🏃                       │
│      Aucune session                 │
│                                     │
│  Créez votre première session       │
│     pour commencer à courir         │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ ➕ Créer une session          │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## 🎨 Palette de couleurs par état

### Sessions actives
- **Primaire** : `Color.green` (#00D66A)
- **Background** : Green 10% opacity
- **Border** : Green 30% opacity
- **Badge** : Green pulsant

### Sessions planifiées
- **Primaire** : `Color.blueAccent` (#00A8FF)
- **Background** : `.ultraThinMaterial`
- **Badge** : BlueAccent 20% opacity

### Sessions récentes
- **Primaire** : `Color.pinkAccent` (#FF6B9D)
- **Background** : `.ultraThinMaterial`
- **Icône** : `clock.arrow.circlepath`

### Ma session active
- **Primaire** : Gradient CoralAccent → PinkAccent
- **Background** : Coral 20% opacity
- **Border** : Coral → Pink gradient

---

## 📱 Interactions et animations

### Tap sur ActiveSessionCardCompact
1. **Tap down** : Scale 0.98, haptic light
2. **Tap up** : Scale 1.0
3. **Navigation** : Push to SessionTrackingView

### Tap sur ScheduledSessionCard
1. **Tap down** : Scale 0.98, haptic light
2. **Tap up** : Scale 1.0
3. **Navigation** : Push to SessionTrackingView (mode spectateur)

### Tap sur RecentSessionCard
1. **Tap down** : Scale 0.98, haptic light
2. **Tap up** : Scale 1.0
3. **Navigation** : Push to SessionHistoryDetailView

### Toggle Mode Session (CreateSessionView)
1. **Animation** : Spring (0.3s, damping 0.7)
2. **Transition** : Fade in/out des sections (0.2s)
3. **Haptic** : Selection feedback

### Bouton "+"
1. **Idle** : CoralAccent
2. **Tap down** : Scale 0.95, haptic medium
3. **Tap up** : Scale 1.0
4. **Action** :
   - Si 1 squad → Open CreateSessionView
   - Si > 1 squad → Open SquadPickerSheet

---

## 🔤 Textes et labels

### Français
- "Sessions actives" (pluriel si >1)
- "Sessions planifiées"
- "Sessions récentes"
- "Tout voir"
- "Rejoindre"
- "Planifiée" (badge)
- "En cours" (badge)
- "Terminée"
- "Commencé il y a X min/h"
- "Il y a X jour(s)"
- "X coureur(s) actif(s)"
- "X participant(s)"
- "Créer une session"
- "Aucune session"
- "Créez votre première session pour commencer à courir"

### Icônes SF Symbols
- Sessions actives : Cercle plein vert (custom)
- Sessions planifiées : `calendar`
- Sessions récentes : `clock.arrow.circlepath`
- Coureur actif : `figure.run`
- Badge planifié : `calendar` (dans badge)
- Date : `calendar`
- Heure : `clock`
- Participants : `person.2.fill`
- Distance : `location.fill`
- Durée : `clock.fill`
- Rejoindre : Pas d'icône (texte seul)

---

## 📊 Spacing et layout

### Spacing vertical (Dashboard)
- Entre sections : 20pt
- Dans section header : 16pt sous le titre
- Entre cartes : 12pt
- Padding bottom ScrollView : 40pt

### Spacing horizontal
- Padding écran : 20pt
- Dans cartes : 12pt
- Entre icône et texte : 8pt
- Entre badges et texte : 4pt

### Tailles de police
- Title3 Bold : 20pt (headers)
- Subheadline Bold : 15pt (titres cartes)
- Subheadline : 15pt (texte normal)
- Caption Bold : 12pt (stats importantes)
- Caption : 12pt (texte secondaire)
- Caption2 : 11pt (texte tertiaire)

---

## ✨ Détails subtils

### Ombres
- Cartes : `shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)`
- Boutons : `shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)`

### Borders
- Sessions actives : 1pt, Green 30%
- Sessions planifiées : Aucune
- Mode toggle sélectionné : 2pt, CoralAccent

### Glassmorphism
- Background sections : `.ultraThinMaterial`
- Opacité texte secondaire : 60-70%
- Opacité texte tertiaire : 50%

### Haptic Feedback
- **Light** : Tap sur carte
- **Medium** : Tap sur bouton "+"
- **Selection** : Toggle mode session
- **Success** : Création session réussie
- **Warning** : Validation échouée

---

## 🎬 Animations de transition

### Apparition Dashboard
```swift
.transition(.move(edge: .bottom).combined(with: .opacity))
.animation(.spring(response: 0.4, dampingFraction: 0.8))
```

### Changement de section
```swift
withAnimation(.easeInOut(duration: 0.3)) {
    // Fade out old content
    // Fade in new content
}
```

### Pull to refresh
```swift
.refreshable {
    // Show activity indicator
    // Reload data
    // Haptic success
}
```

---

## 📸 Mockups de référence

### ActiveSessionCardCompact
```
┌─────────────────────────────────────────────┐
│                                             │
│  ⚫  Paris Runners         [Rejoindre]      │
│  ⚪  3 coureurs actifs                      │
│      Commencé il y a 10 min                 │
│                                             │
└─────────────────────────────────────────────┘
 👆 Badge pulsant + gradient vert
```

### ScheduledSessionCard
```
┌─────────────────────────────────────────────┐
│ Course matinale           [Planifiée] 📅    │
│ Marathon Paris 2024                         │
│                                             │
│ 📅 15 jan 2026    🕐 08:00                  │
│                                             │
│ Sortie longue pour prépa marathon          │
│                                             │
│ 👥 5 participants  📍 21 km                 │
└─────────────────────────────────────────────┘
```

### RecentSessionCard
```
┌─────────────────────────────────────────────┐
│                                             │
│  🏁  Marathon Squad                    >    │
│      Il y a 2 jours                         │
│      ✅ Terminée  ⏱️ 45m  👥 4              │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🎯 Responsive Design

### iPhone SE (compact)
- Réduire padding à 16pt
- Réduire taille police de 1-2pt
- Limiter hauteur cartes

### iPhone Pro Max (large)
- Padding standard 20pt
- Possibilité d'afficher 2 colonnes en paysage

### iPad
- Layout 2 colonnes
- Cartes plus larges (max 600pt)
- Sidebar navigation

---

## ✅ Checklist Design

### Composants créés
- [x] ActiveSessionCardCompact
- [x] ScheduledSessionCard
- [x] SquadPickerSheet
- [x] Mode toggle (CreateSessionView)
- [x] Section headers avec icônes

### États couverts
- [x] Je cours actuellement
- [x] Dashboard complet (3 sections)
- [x] Dashboard partiel (historique seul)
- [x] État vide complet

### Interactions définies
- [x] Tap sur cartes
- [x] Toggle mode session
- [x] Bouton "+"
- [x] Pull to refresh
- [x] Navigation

### Animations spécifiées
- [x] Badge pulsant
- [x] Transitions
- [x] Spring animations
- [x] Haptic feedback

---

## 🚀 Prochaines étapes

1. **Implémentation SwiftUI** : Créer les composants
2. **Backend** : API pour sessions planifiées
3. **Tests** : Vérifier tous les états
4. **Notifications** : Rappels sessions planifiées
5. **Analytics** : Tracking engagement utilisateurs

---

Bon code ! 🏃‍♂️✨
