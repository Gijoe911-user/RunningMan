# Guide d'intégration - Amélioration de la carte de session

## Résumé des modifications

✅ **Problème 1 résolu** : Superposition des boutons carte avec le bouton "+"
- Augmenté le padding top de 100 à 140 pixels pour les contrôles de carte

✅ **Problème 2 résolu** : Visualisation des tracés de tous les coureurs
- Ajout du paramètre `runnerRoutes` qui stocke les tracés par ID de coureur
- Affichage automatique de tous les tracés avec des couleurs différentes pour chaque coureur
- Votre tracé reste en dégradé coral/pink, les autres ont des couleurs uniques (bleu, vert, violet, etc.)

✅ **Problème 3 résolu** : Clic sur le nom d'un coureur pour le suivre
- Création du composant `SessionParticipantsOverlay` 
- Fonction `centerOnRunner(runnerId:)` ajoutée à `EnhancedSessionMapView`
- Animation fluide lors du centrage sur un coureur

## Modifications apportées

### 1. EnhancedSessionMapView.swift

**Nouveaux paramètres** :
```swift
let runnerRoutes: [String: [CLLocationCoordinate2D]] // Tracés par runner ID
var onRunnerTapped: ((String) -> Void)? // Callback lors du clic sur un coureur
```

**Nouvelle méthode publique** :
```swift
func centerOnRunner(runnerId: String)
```

**Changements dans la carte** :
- Les tracés de tous les coureurs sont maintenant affichés avec des couleurs différentes
- Padding augmenté à 140px pour éviter le bouton "+"

### 2. SessionParticipantsOverlay.swift (NOUVEAU)

Composant d'overlay affichant :
- La liste horizontale des participants
- Un bouton pour replier/déplier la liste
- Photo ou avatar de chaque coureur
- État "En course"
- Clic sur un coureur pour centrer la carte sur lui

## Comment utiliser ces modifications

### Exemple d'intégration dans votre vue de session active

```swift
import SwiftUI
import MapKit

struct ActiveSessionView: View {
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var runnerRoutes: [String: [CLLocationCoordinate2D]] = [:]
    @State private var runnerLocations: [RunnerLocation] = []
    @State private var userLocation: CLLocationCoordinate2D?
    
    // Référence à la carte pour la contrôler
    @State private var mapView: EnhancedSessionMapView?
    
    var body: some View {
        ZStack {
            // Carte
            EnhancedSessionMapView(
                userLocation: userLocation,
                runnerLocations: runnerLocations,
                routeCoordinates: routeCoordinates,
                runnerRoutes: runnerRoutes, // NOUVEAU
                onRecenter: {
                    print("Recentré sur l'utilisateur")
                },
                onSaveRoute: {
                    saveRoute()
                },
                onRunnerTapped: { runnerId in // NOUVEAU
                    // Centrer la carte sur ce coureur
                    centerOnRunner(runnerId: runnerId)
                }
            )
            
            // Overlay des participants (en bas)
            VStack {
                Spacer()
                
                SessionParticipantsOverlay(
                    participants: runnerLocations,
                    userLocation: userLocation,
                    onRunnerTap: { runnerId in
                        centerOnRunner(runnerId: runnerId)
                    }
                )
                .padding(.bottom, 100) // Au-dessus de la tab bar
            }
        }
        .onAppear {
            startLocationUpdates()
            listenToRunnerLocations()
        }
    }
    
    // MARK: - Actions
    
    private func centerOnRunner(runnerId: String) {
        // Trouver le coureur
        guard let runner = runnerLocations.first(where: { $0.id == runnerId }) else { return }
        
        // Note: Vous devrez créer une référence à la carte pour appeler cette méthode
        // Ou utiliser un Binding<MapCameraPosition> partagé
        print("Centrage sur \(runner.displayName)")
    }
    
    private func saveRoute() {
        // Logique de sauvegarde
    }
    
    private func startLocationUpdates() {
        // Mise à jour de votre position
        // userLocation = ...
        // routeCoordinates.append(userLocation)
    }
    
    private func listenToRunnerLocations() {
        // Écoute Firestore pour les positions des autres coureurs
        // runnerLocations = ...
        // runnerRoutes[runnerId] = coordinates
    }
}
```

### Structure de données pour runnerRoutes

```swift
// Exemple de structure pour stocker les tracés
var runnerRoutes: [String: [CLLocationCoordinate2D]] = [
    "userId1": [
        CLLocationCoordinate2D(latitude: 48.8576, longitude: 2.3532),
        CLLocationCoordinate2D(latitude: 48.8581, longitude: 2.3537),
        // ... plus de points
    ],
    "userId2": [
        CLLocationCoordinate2D(latitude: 48.8556, longitude: 2.3512),
        CLLocationCoordinate2D(latitude: 48.8551, longitude: 2.3507),
        // ... plus de points
    ]
]
```

### Écoute des tracés dans Firestore

```swift
func listenToAllRunnerRoutes(sessionId: String) {
    // Pour chaque participant, écouter son tracé
    let db = Firestore.firestore()
    
    db.collection("sessions")
        .document(sessionId)
        .collection("runnerRoutes")
        .addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            
            var newRoutes: [String: [CLLocationCoordinate2D]] = [:]
            
            for doc in documents {
                let runnerId = doc.documentID
                let data = doc.data()
                
                // Extraire les coordonnées
                if let coordinates = data["coordinates"] as? [[String: Double]] {
                    let coords = coordinates.compactMap { point -> CLLocationCoordinate2D? in
                        guard let lat = point["latitude"],
                              let lon = point["longitude"] else { return nil }
                        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                    newRoutes[runnerId] = coords
                }
            }
            
            runnerRoutes = newRoutes
        }
}
```

## Personnalisation

### Changer les couleurs des tracés

Dans `EnhancedSessionMapView.swift`, modifiez la fonction `runnerColor(for:)` :

```swift
private func runnerColor(for runnerId: String) -> Color {
    let colors: [Color] = [
        .blue, .green, .purple, .orange, .yellow, .cyan, .mint, .indigo
    ]
    
    // Utilisez votre propre logique de couleurs
    let hash = abs(runnerId.hashValue)
    let index = hash % colors.count
    
    return colors[index]
}
```

### Ajuster le padding des boutons

Dans `EnhancedSessionMapView.swift`, ligne ~220 :

```swift
.padding(.top, 140) // Augmentez ou diminuez selon vos besoins
```

### Personnaliser l'overlay des participants

Dans `SessionParticipantsOverlay.swift`, vous pouvez :
- Modifier la taille des cartes : `frame(width: 160)` → `frame(width: 200)`
- Changer la hauteur maximale : `frame(maxHeight: 140)` → `frame(maxHeight: 180)`
- Ajouter plus d'informations (distance parcourue, vitesse, etc.)

## Tests

### Test 1 : Vérifier l'affichage des tracés
1. Lancez une session avec au moins 2 participants
2. Vérifiez que vous voyez plusieurs tracés de couleurs différentes
3. Votre tracé doit être en dégradé coral/pink

### Test 2 : Clic sur un participant
1. Ouvrez l'overlay des participants (en bas)
2. Cliquez sur le nom d'un coureur
3. La carte doit se centrer sur sa position avec une animation fluide

### Test 3 : Vérifier le positionnement des boutons
1. Ouvrez la carte de session
2. Vérifiez que les boutons de contrôle (location, zoom, etc.) ne se superposent pas avec le bouton "+" en haut à droite

## Notes importantes

⚠️ **MapCameraPosition** : Pour permettre le contrôle externe de la carte (clic sur un participant), vous devrez peut-être exposer la position de la caméra via un Binding.

⚠️ **Performance** : Si vous avez beaucoup de points dans les tracés, envisagez de :
- Limiter le nombre de points affichés (derniers 100 points par exemple)
- Utiliser une simplification de trajectoire (algorithme Douglas-Peucker)

⚠️ **Données temps réel** : Assurez-vous que votre structure Firestore stocke les tracés de manière optimisée pour éviter les lectures excessives.

## Prochaines étapes suggérées

1. Ajouter des statistiques par coureur (distance, vitesse moyenne)
2. Permettre de filtrer quels tracés afficher
3. Ajouter une légende des couleurs
4. Implémenter un mode "suivre automatiquement" qui centre la carte sur le coureur actif
