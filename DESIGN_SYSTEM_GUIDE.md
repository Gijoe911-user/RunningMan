# 🎨 Nouveau Design System - RunningMan

## Date: 28 décembre 2025

## 🎯 Inspiré de la Maquette Modern UI

Ce design system reprend les éléments visuels de la maquette pour créer une interface moderne, élégante et cohérente.

---

## 📁 Nouveaux Fichiers Créés

### 1. **DesignSystem.swift** - Composants Réutilisables

#### Composants Principaux

**GlassCard**
- Carte avec effet glassmorphism
- Fond semi-transparent avec `.ultraThinMaterial`
- Bordure subtile blanche
- Ombre douce
```swift
GlassCard {
    Text("Contenu")
}
```

**GlassButton**
- Bouton circulaire avec effet glass
- Tailles personnalisables
- Icônes SF Symbols
```swift
GlassButton(icon: "plus", action: {})
```

**GradientProgressBar**
- Barre de progression avec dégradé
- Dégradé orange → rose par défaut
- Hauteur et coins arrondis personnalisables
```swift
GradientProgressBar(
    progress: 0.67,
    colors: [.orange, .pink]
)
```

**ParticipantBadge**
- Badge circulaire pour avatar
- Dégradé bleu → violet
- Bordure blanche
- Supporte initiales ou images
```swift
ParticipantBadge(
    imageURL: nil,
    initial: "J",
    size: 40
)
```

**ParticipantsStack**
- Pile de badges superposés
- Indicateur "+X" si plus de participants
- Overlap personnalisable
```swift
ParticipantsStack(
    participants: ["Jean", "Marie", "Paul"],
    maxVisible: 4
)
```

**DistanceBadge**
- Badge circulaire pour afficher une distance
- Effet glassmorphism
- Affichage km
```swift
DistanceBadge(distance: 3.5)
```

**SessionCardHeader**
- En-tête de carte de session
- Icône + titre + sous-titre
- Bouton play vert
```swift
SessionCardHeader(
    title: "Run Together",
    subtitle: "4 coureurs actifs",
    icon: "figure.run.circle.fill",
    isActive: true,
    onPlayTap: {}
)
```

**ChallengeCard**
- Carte de défi/objectif
- Barre de progression
- Indicateur de jours restants
```swift
ChallengeCard(
    title: "Préparation Marathon",
    distance: 42.2,
    progress: 0.67,
    daysRemaining: 8
)
```

**ActionButtonBar**
- Barre de boutons d'action (bas de l'écran)
- Micro, Photo, Messages
- Badge pour messages non lus
```swift
ActionButtonBar(
    onMicroTap: {},
    onPhotoTap: {},
    onMessagesTap: {},
    unreadCount: 3
)
```

---

### 2. **ColorExtensions.swift** - Palette de Couleurs

#### Couleurs Principales

```swift
Color.darkNavy       // #1C2433 - Fond principal
Color.coralAccent    // #FF6B6B - Accent principal
Color.pinkAccent     // #ED599F - Accent secondaire
Color.blueAccent     // #47ABEE - Informations
Color.yellowAccent   // #FACC45 - Warnings/Achievements
Color.greenAccent    // #57D194 - Succès/Actions
```

#### Dégradés Prédéfinis

```swift
Color.progressGradient     // Orange → Rose
Color.participantGradient  // Bleu → Violet
Color.actionGradient       // Vert clair → Vert foncé
```

#### Extensions de Vue

```swift
// Ombre glassmorphism
.glassShadow()

// Ombre bouton
.buttonShadow(color: .green)

// Ombre éléments carte
.mapElementShadow()

// Fond glassmorphism complet
.glassBackground(cornerRadius: 20)
```

#### Typographie

```swift
Font.appTitle        // 28pt bold rounded
Font.sectionTitle    // 20pt bold
Font.subtitle        // 16pt semibold
Font.body           // 15pt regular
Font.caption        // 13pt medium
Font.smallLabel     // 11pt medium
Font.stat(size: 32) // Stats (bold rounded)
```

#### Espacement (Spacing)

```swift
Spacing.xs   // 4pt
Spacing.sm   // 8pt
Spacing.md   // 12pt
Spacing.lg   // 16pt
Spacing.xl   // 20pt
Spacing.xxl  // 24pt
Spacing.xxxl // 32pt
```

#### Rayons de Coins (CornerRadius)

```swift
CornerRadius.small   // 8pt
CornerRadius.medium  // 12pt
CornerRadius.large   // 16pt
CornerRadius.xlarge  // 20pt
CornerRadius.button  // 24pt
```

---

### 3. **ModernSessionDetailView.swift** - Exemple d'Intégration

Version modernisée de `SessionDetailView` avec :
- ✅ Nouveau design glassmorphism
- ✅ Barre d'actions en bas
- ✅ Badges de distance sur la carte
- ✅ Contrôles de carte élégants
- ✅ Cartes de stats rapides
- ✅ Liste de participants modernisée

---

## 🎨 Principes du Design

### Glassmorphism

**Caractéristiques :**
- Fond semi-transparent (`.ultraThinMaterial`)
- Bordure blanche subtile (opacity 0.1-0.2)
- Ombre douce portée
- Coins arrondis généreux (16-24pt)

**Quand l'utiliser :**
- Cartes de contenu
- Boutons d'action
- Overlays sur la carte
- Barres de navigation/actions

### Dégradés

**Types de dégradés :**
1. **Progression** : Orange → Rose
   - Barres de progression
   - Indicateurs de challenge

2. **Participant** : Bleu → Violet
   - Avatars
   - Badges de participants

3. **Action** : Vert clair → Vert foncé
   - Boutons d'action principale
   - Succès

### Hiérarchie Visuelle

**1. Éléments Primaires**
- Boutons d'action : Couleurs vives (vert, rouge)
- Informations critiques : Couleur corail

**2. Éléments Secondaires**
- Stats : Blanc avec teinte d'accent
- Texte secondaire : Blanc opacity 0.7

**3. Éléments Tertiaires**
- Labels : Blanc opacity 0.6
- Bordures : Blanc opacity 0.1-0.2

---

## 🔄 Migration depuis l'Ancien Design

### Remplacer les Composants

#### Ancien → Nouveau

**Cartes**
```swift
// ❌ Ancien
VStack {
    // contenu
}
.padding()
.background(Color.white.opacity(0.05))
.cornerRadius(12)

// ✅ Nouveau
GlassCard {
    // contenu
}
```

**Boutons**
```swift
// ❌ Ancien
Button(action: {}) {
    Image(systemName: "plus")
        .frame(width: 60, height: 60)
        .background(Color.blue)
        .clipShape(Circle())
}

// ✅ Nouveau
GlassButton(icon: "plus", action: {})
```

**Barres de Progression**
```swift
// ❌ Ancien
ProgressView(value: 0.67)

// ✅ Nouveau
GradientProgressBar(progress: 0.67)
```

---

## 🎯 Exemples d'Usage

### Écran de Session Active

```swift
struct SessionView: View {
    var body: some View {
        ZStack {
            Color.darkNavy.ignoresSafeArea()
            
            VStack(spacing: Spacing.lg) {
                // Header
                SessionCardHeader(
                    title: "Run Together",
                    subtitle: "4 coureurs actifs",
                    icon: "figure.run.circle.fill",
                    isActive: true,
                    onPlayTap: {}
                )
                
                // Carte principale
                Map()
                    .frame(height: 400)
                    .overlay(alignment: .bottomLeading) {
                        DistanceBadge(distance: 3.5)
                            .padding()
                    }
                
                // Stats
                GlassCard {
                    HStack {
                        StatItem(icon: "timer", value: "23:45", unit: "min", color: .coralAccent)
                        StatItem(icon: "speedometer", value: "5'30\"", unit: "/km", color: .blueAccent)
                    }
                }
                
                Spacer()
                
                // Actions
                ActionButtonBar(
                    onMicroTap: {},
                    onPhotoTap: {},
                    onMessagesTap: {},
                    unreadCount: 2
                )
            }
            .padding()
        }
    }
}
```

### Liste de Squads

```swift
ScrollView {
    VStack(spacing: Spacing.md) {
        ForEach(squads) { squad in
            GlassCard {
                HStack {
                    // Icon
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.coralAccent)
                    
                    // Info
                    VStack(alignment: .leading) {
                        Text(squad.name)
                            .font(.subtitle)
                            .foregroundColor(.white)
                        
                        Text("\(squad.memberCount) membres")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Participants
                    ParticipantsStack(
                        participants: squad.members,
                        maxVisible: 3
                    )
                }
            }
        }
    }
    .padding()
}
```

---

## 📱 Responsive Design

### Adaptations par Taille

**iPhone SE / Petits Écrans**
- Réduire `badgeSize` des participants (35pt au lieu de 40pt)
- Réduire `DistanceBadge` (70pt au lieu de 80pt)
- Stack vertical pour les stats si nécessaire

**iPhone Pro Max / Grands Écrans**
- Augmenter les espacements (`.xl` au lieu de `.lg`)
- Plus de participants visibles dans `ParticipantsStack`

**iPad**
- Layout en colonnes
- Cartes plus larges avec max width
- Navigation split view

---

## ♿ Accessibilité

### Contraste

Toutes les couleurs respectent WCAG AA :
- ✅ Texte blanc sur darkNavy : 15:1
- ✅ Accents sur darkNavy : > 4.5:1

### Dynamic Type

Utiliser les styles de police prédéfinis qui supportent Dynamic Type :
```swift
.font(.body)        // Supporte Dynamic Type
.font(.caption)     // Supporte Dynamic Type
```

### VoiceOver

Tous les composants sont accessibles :
- Boutons avec labels
- Images avec `accessibilityLabel`
- Cartes avec `accessibilityElement(children: .contain)`

---

## 🎬 Animations

### Transitions Recommandées

**Apparition de Cartes**
```swift
GlassCard { }
    .transition(.opacity.combined(with: .scale(scale: 0.95)))
    .animation(.spring(response: 0.3), value: isShowing)
```

**Boutons**
```swift
GlassButton(icon: "plus", action: {})
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .animation(.spring(response: 0.2), value: isPressed)
```

**Progress Bar**
```swift
GradientProgressBar(progress: progress)
    .animation(.easeInOut(duration: 0.5), value: progress)
```

---

## 📦 Checklist d'Intégration

### Phase 1 : Setup
- [x] Créer `DesignSystem.swift`
- [x] Créer `ColorExtensions.swift`
- [x] Ajouter couleurs dans Assets.xcassets
- [x] Créer exemple `ModernSessionDetailView`

### Phase 2 : Migration Progressive
- [ ] Remplacer `SessionDetailView` par version moderne
- [ ] Moderniser `SessionsListView`
- [ ] Moderniser `SquadsListView`
- [ ] Moderniser `ProfileView`

### Phase 3 : Nouveautés
- [ ] Ajouter `ChallengeCard` fonctionnel
- [ ] Implémenter messages vocaux (micro)
- [ ] Implémenter partage de photos
- [ ] Ajouter notifications badge

### Phase 4 : Polish
- [ ] Animations de transitions
- [ ] Haptic feedback
- [ ] Dark mode (déjà optimisé)
- [ ] Tests accessibilité

---

## 🚀 Prochaines Étapes

1. **Tester les composants**
   - Ouvrir les Previews dans Xcode
   - Vérifier sur différents devices

2. **Intégrer progressivement**
   - Commencer par `SessionDetailView`
   - Puis `SessionsListView`
   - Enfin les autres écrans

3. **Affiner les couleurs**
   - Ajuster si besoin dans Assets.xcassets
   - Tester le contraste

4. **Documenter l'usage**
   - Créer des exemples pour chaque composant
   - Ajouter dans un Storybook SwiftUI

---

## 📸 Aperçu des Composants

Tous les composants ont des Previews intégrés :

```swift
#Preview("Glass Card") { }
#Preview("Session Cards") { }
#Preview("Modern Session Detail") { }
```

**Pour les voir :**
1. Ouvrir `DesignSystem.swift` dans Xcode
2. Activer Canvas (Cmd + Option + Enter)
3. Sélectionner un Preview

---

## 💡 Conseils de Conception

1. **Cohérence** : Toujours utiliser les composants du design system
2. **Espacement** : Utiliser `Spacing.*` plutôt que des valeurs hardcodées
3. **Couleurs** : Utiliser les couleurs prédéfinies
4. **Typographie** : Utiliser `Font.*` pour la cohérence
5. **Glassmorphism** : Ne pas abuser, réserver aux éléments importants

---

**Dernière mise à jour** : 28 décembre 2025  
**Version** : 1.0  
**Design inspiré de** : Maquette Modern Running App

