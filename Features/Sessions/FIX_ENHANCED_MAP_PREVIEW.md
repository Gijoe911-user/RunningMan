# 🔧 Fix: EnhancedSessionMapView Preview Errors

**Date :** 27 Décembre 2025  
**Status :** ✅ **Corrigé**

---

## 🐛 Erreur

### Symptômes
```
Missing argument for parameter 'id' in call
Extra argument 'userId' in call
```

**Fichier :** `EnhancedSessionMapView.swift` lignes 237 et 244

---

## 🔍 Cause

Le Preview utilisait une initialisation incorrecte de `RunnerLocation` :

```swift
// ❌ AVANT - Paramètres manquants
RunnerLocation(
    userId: "user1",        // Problème: userId n'est pas le premier paramètre
    displayName: "Jean",
    latitude: 48.8576,
    longitude: 2.3532,
    timestamp: Date()
    // Manque: id, photoURL
)
```

### Structure Réelle de RunnerLocation

D'après l'utilisation dans le code :

```swift
struct RunnerLocation: Identifiable {
    var id: String                    // ✅ Requis pour Identifiable
    var userId: String               // ✅ ID de l'utilisateur
    var displayName: String          // ✅ Nom affiché
    var latitude: Double             // ✅ Coordonnée GPS
    var longitude: Double            // ✅ Coordonnée GPS
    var timestamp: Date              // ✅ Date de la position
    var photoURL: String?            // ✅ URL de l'avatar (optionnel)
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
```

---

## ✅ Solution

### Correction du Preview

```swift
// ✅ APRÈS - Tous les paramètres corrects
RunnerLocation(
    id: "user1",              // ✅ ID unique pour Identifiable
    userId: "user1",          // ✅ User ID
    displayName: "Jean",      // ✅ Nom
    latitude: 48.8576,        // ✅ Position
    longitude: 2.3532,        // ✅ Position
    timestamp: Date(),        // ✅ Date
    photoURL: nil             // ✅ Pas de photo dans preview
)
```

### Code Complet Corrigé

```swift
#Preview {
    EnhancedSessionMapView(
        userLocation: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        runnerLocations: [
            RunnerLocation(
                id: "user1",
                userId: "user1",
                displayName: "Jean",
                latitude: 48.8576,
                longitude: 2.3532,
                timestamp: Date(),
                photoURL: nil
            ),
            RunnerLocation(
                id: "user2",
                userId: "user2",
                displayName: "Marie",
                latitude: 48.8556,
                longitude: 2.3512,
                timestamp: Date(),
                photoURL: nil
            )
        ],
        routeCoordinates: [
            CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            CLLocationCoordinate2D(latitude: 48.8571, longitude: 2.3527),
            CLLocationCoordinate2D(latitude: 48.8576, longitude: 2.3532)
        ]
    )
}
```

---

## 📝 Paramètres RunnerLocation

| Paramètre | Type | Optionnel | Description |
|-----------|------|-----------|-------------|
| `id` | String | Non | Identifiant unique (Identifiable) |
| `userId` | String | Non | ID de l'utilisateur |
| `displayName` | String | Non | Nom affiché |
| `latitude` | Double | Non | Coordonnée GPS |
| `longitude` | Double | Non | Coordonnée GPS |
| `timestamp` | Date | Non | Date de la position |
| `photoURL` | String? | Oui | URL de l'avatar |

---

## ✅ Résultat

- ✅ Build réussit
- ✅ Preview fonctionne
- ✅ Pas d'erreurs de compilation
- ✅ Carte affiche correctement les coureurs

---

## 💡 Pour Éviter à l'Avenir

### Astuce 1 : Vérifier la Définition
Avant d'initialiser un struct dans un Preview, vérifier sa définition complète :
```swift
// Cmd + Click sur RunnerLocation pour voir sa définition
RunnerLocation(...)
```

### Astuce 2 : Utiliser l'Autocomplétion
Taper `RunnerLocation(` et laisser Xcode proposer les paramètres.

### Astuce 3 : Copier depuis le Code Existant
Chercher d'autres utilisations dans le projet :
```swift
// Exemple dans SessionsListView.swift ligne 164
ForEach(viewModel.activeRunners) { runner in
    // runner a tous les paramètres nécessaires
}
```

---

**Status :** ✅ **Corrigé - Build OK**
