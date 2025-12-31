# 📊 Guide d'Utilisation : StatCard

## Vue d'ensemble

`StatCard` est un composant SwiftUI réutilisable pour afficher des statistiques dans toute l'application. Il supporte deux styles distincts selon le contexte d'utilisation.

---

## 🎨 Deux Styles Disponibles

### 1. **Style Compact** (pour le tracking)
- Design minimaliste
- Fond secondaire système
- Icône bleue
- Idéal pour les statistiques en temps réel pendant une course

### 2. **Style Full** (pour le profil)
- Design plus grand et coloré
- Icône avec couleur personnalisée
- Fond ultra thin material
- Parfait pour les statistiques globales de l'utilisateur

---

## 📝 Utilisation

### Style Compact (Tracking)

**Utilisation typique** : Affichage des statistiques pendant une session de course active

```swift
import SwiftUI

struct TrackingView: View {
    var body: some View {
        HStack(spacing: 20) {
            // Distance parcourue
            StatCard(
                title: "Distance",
                value: "12.5",
                unit: "km",
                icon: "figure.run"
            )
            
            // Durée
            StatCard(
                title: "Durée",
                value: "1:23:45",
                unit: "",
                icon: "timer"
            )
            
            // Allure actuelle
            StatCard(
                title: "Allure",
                value: "5:30",
                unit: "/km",
                icon: "speedometer"
            )
        }
        .padding()
    }
}
```

**Signature de l'initializer** :
```swift
init(
    title: String,      // Titre de la stat (ex: "Distance")
    value: String,      // Valeur affichée (ex: "12.5")
    unit: String = "",  // Unité optionnelle (ex: "km")
    icon: String        // Icône SF Symbol (ex: "figure.run")
)
```

---

### Style Full (Profil)

**Utilisation typique** : Affichage des statistiques globales dans le profil utilisateur

```swift
import SwiftUI

struct ProfileStatsView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Nombre de courses
                StatCard(
                    icon: "figure.run",
                    value: "24",
                    label: "Courses",
                    color: .coralAccent
                )
                
                // Distance totale
                StatCard(
                    icon: "map",
                    value: "125",
                    unit: "km",
                    label: "Distance",
                    color: .blueAccent
                )
                
                // Temps total
                StatCard(
                    icon: "timer",
                    value: "18h",
                    label: "Durée",
                    color: .purpleAccent
                )
            }
            
            HStack(spacing: 12) {
                // Nombre de squads
                StatCard(
                    icon: "person.3.fill",
                    value: "3",
                    label: "Squads",
                    color: .greenAccent
                )
                
                // Calories
                StatCard(
                    icon: "flame.fill",
                    value: "2.1k",
                    label: "Calories",
                    color: .yellowAccent
                )
                
                // Rythme moyen
                StatCard(
                    icon: "speedometer",
                    value: "5:30",
                    label: "Rythme moy.",
                    color: .pinkAccent
                )
            }
        }
    }
}
```

**Signature de l'initializer** :
```swift
init(
    icon: String,        // Icône SF Symbol (ex: "figure.run")
    value: String,       // Valeur principale (ex: "24")
    unit: String = "",   // Unité optionnelle (ex: "km")
    label: String,       // Label descriptif (ex: "Courses")
    color: Color         // Couleur de l'icône (ex: .orange)
)
```

---

## 🎯 Exemples Complets

### Exemple 1 : Tracking en temps réel

```swift
struct ActiveSessionView: View {
    @ObservedObject var locationService = OptimizedLocationService.shared
    
    var body: some View {
        VStack {
            // Carte
            MapView()
            
            // Statistiques compactes
            HStack(spacing: 20) {
                StatCard(
                    title: "Distance",
                    value: String(format: "%.2f", locationService.trackingStats.distanceInKm),
                    unit: "km",
                    icon: "figure.run"
                )
                
                StatCard(
                    title: "Durée",
                    value: locationService.trackingStats.formattedDuration,
                    unit: "",
                    icon: "timer"
                )
                
                StatCard(
                    title: "Allure",
                    value: locationService.trackingStats.currentPace,
                    unit: "/km",
                    icon: "speedometer"
                )
            }
            .padding()
        }
    }
}
```

### Exemple 2 : Profil utilisateur

```swift
struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    
    var statsData: UserStats {
        authVM.currentUser?.statistics ?? UserStatistics()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistiques")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "figure.run",
                    value: "\(statsData.totalRaces)",
                    label: "Courses",
                    color: .coralAccent
                )
                
                StatCard(
                    icon: "map",
                    value: String(format: "%.0f", statsData.totalDistanceMeters / 1000),
                    unit: "km",
                    label: "Distance",
                    color: .blueAccent
                )
                
                StatCard(
                    icon: "timer",
                    value: formatDuration(statsData.totalTimeSeconds),
                    label: "Durée",
                    color: .purpleAccent
                )
            }
        }
    }
    
    func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        return "\(hours)h"
    }
}
```

---

## 🔍 Différences entre les Styles

| Aspect | Style Compact | Style Full |
|--------|--------------|------------|
| **Taille police valeur** | 20pt | 24pt |
| **Affichage icône** | Petit (caption) | Grand (title2) |
| **Couleur icône** | Bleue fixe | Personnalisable |
| **Padding vertical** | 8pt | 16pt |
| **Fond** | `secondarySystemBackground` | `ultraThinMaterial` |
| **Couleur texte** | Adaptative | Blanc |
| **Usage** | Tracking actif | Profil / Résumés |

---

## 🎨 Couleurs Disponibles (RunningMan)

Pour le style Full, utilisez les couleurs de l'application :

```swift
// Couleurs disponibles
.coralAccent   // Orange/Coral
.blueAccent    // Bleu
.purpleAccent  // Violet
.greenAccent   // Vert
.yellowAccent  // Jaune
.pinkAccent    // Rose

// Exemple d'utilisation
StatCard(
    icon: "flame.fill",
    value: "2.1k",
    label: "Calories",
    color: .yellowAccent  // ✅ Couleur de l'app
)
```

---

## ⚠️ Bonnes Pratiques

### ✅ DO (À faire)

```swift
// ✅ Utiliser le bon style selon le contexte
// Tracking → Compact
StatCard(title: "Distance", value: "12.5", unit: "km", icon: "figure.run")

// Profil → Full
StatCard(icon: "figure.run", value: "24", label: "Courses", color: .orange)

// ✅ Grouper dans un HStack
HStack(spacing: 12) {
    StatCard(...)
    StatCard(...)
    StatCard(...)
}

// ✅ Formater les valeurs proprement
let distanceKm = String(format: "%.2f", distance / 1000)
StatCard(title: "Distance", value: distanceKm, unit: "km", icon: "map")
```

### ❌ DON'T (À éviter)

```swift
// ❌ Ne pas mélanger les styles dans la même vue
HStack {
    StatCard(title: "Distance", value: "12.5", unit: "km", icon: "map")
    StatCard(icon: "timer", value: "1h", label: "Durée", color: .blue)
}

// ❌ Ne pas utiliser de couleurs système pour le style Full
StatCard(icon: "flame.fill", value: "2.1k", label: "Calories", color: .red)
// Utilisez plutôt .coralAccent, .blueAccent, etc.

// ❌ Ne pas oublier l'unité si nécessaire
StatCard(title: "Distance", value: "12.5", icon: "map")
// Devrait être : StatCard(title: "Distance", value: "12.5", unit: "km", icon: "map")
```

---

## 📦 Migration depuis l'Ancienne Version

Si vous aviez une ancienne version de `StatCard` dans vos fichiers :

### Ancien code (ProfileView)
```swift
StatCard(
    icon: "figure.run",
    value: "24",
    label: "Courses",
    color: .orange
)
```

### Nouveau code (identique !)
```swift
StatCard(
    icon: "figure.run",
    value: "24",
    label: "Courses",
    color: .orange
)
```
✅ Aucun changement nécessaire pour le style Full

### Ancien code (TrackingControlView)
```swift
StatCard(
    title: "Distance",
    value: "12.5",
    unit: "km",
    icon: "figure.run"
)
```

### Nouveau code (identique !)
```swift
StatCard(
    title: "Distance",
    value: "12.5",
    unit: "km",
    icon: "figure.run"
)
```
✅ Aucun changement nécessaire pour le style Compact

---

## 🔧 Personnalisation Avancée

Si vous avez besoin d'un style personnalisé, vous pouvez toujours accéder aux composants internes :

```swift
// Exemple : StatCard avec fond personnalisé
StatCard(title: "Distance", value: "12.5", unit: "km", icon: "map")
    .background(Color.blue.opacity(0.2))
    .clipShape(RoundedRectangle(cornerRadius: 16))
```

---

## 📱 Responsive Design

Les `StatCard` sont conçues pour être responsive :

```swift
// Sur petits écrans : 2 colonnes
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
    StatCard(...)
    StatCard(...)
    StatCard(...)
    StatCard(...)
}

// Sur grands écrans : 3 colonnes
LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
    StatCard(...)
    StatCard(...)
    StatCard(...)
}
```

---

## 📚 Ressources

- **Fichier source** : `StatCard.swift`
- **Utilisations** : 
  - `TrackingControlView.swift` (style compact)
  - `ProfileView.swift` (style full)
- **Icônes SF Symbols** : https://developer.apple.com/sf-symbols/

---

**Date de création** : 31 décembre 2025  
**Version** : 1.0  
**Composant** : StatCard réutilisable
