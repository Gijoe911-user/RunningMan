# Corrections UX/UI - Suivi des Participants

## Date: 28 décembre 2025

## Problèmes Résolus

### 1. ✅ Affichage "Vous" pour l'utilisateur actuel

**Problème**: Tous les participants affichaient leur nom de coureur, même l'utilisateur actuel

**Solution**: 
- Ajout de la propriété `isCurrentUser` dans `ParticipantRow`
- Affichage de "Vous" pour l'utilisateur actuel avec son nom entre parenthèses
- Icône différente (`person.fill.checkmark`) pour l'utilisateur actuel

```swift
Text(isCurrentUser ? "Vous" : displayName)

if isCurrentUser {
    Text("(\(displayName))")
        .font(.caption2)
        .foregroundColor(.white.opacity(0.5))
}
```

### 2. ✅ Clic sur participant centre la carte

**Problème**: Aucune interaction n'était définie sur les participants

**Solution**:
- Ajout d'un `Button` wrapper dans `ParticipantRow` avec callback `onTap`
- Ajout de la fonction `centerMapOnRunner(userId:)` dans `SessionDetailView`
- La carte se centre avec animation sur la position du coureur sélectionné
- Indication visuelle du participant sélectionné (bordure colorée + icône de localisation)

```swift
Button(action: onTap) {
    // Contenu du participant
}

private func centerMapOnRunner(userId: String) {
    selectedRunnerId = userId
    if let runner = runnerLocations.first(where: { $0.id == userId }) {
        withAnimation {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: runner.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
    }
}
```

### 3. ✅ Affichage du tracking des autres coureurs

**Problème**: Le `MapView` recevait toujours une liste vide `[]`

**Solution**:
- Ajout de `@State private var runnerLocations: [RunnerLocation] = []` dans `SessionDetailView`
- Création de la fonction `observeRunnerLocations(sessionId:)` qui utilise `RealtimeLocationRepository`
- Les positions sont maintenant observées en temps réel via Firestore
- Les annotations des coureurs s'affichent sur la carte

```swift
private func observeRunnerLocations(sessionId: String) async {
    let repository = RealtimeLocationRepository()
    let stream = repository.observeRunnerLocations(sessionId: sessionId)
    
    for await locations in stream {
        runnerLocations = locations
    }
}
```

### 4. ✅ Gestion dynamique de la position de la carte

**Problème**: La carte ne pouvait pas être contrôlée depuis l'extérieur

**Solution**:
- Modification de `MapView` pour accepter `@Binding var mapPosition: MapCameraPosition`
- Ajout de `@State private var mapPosition: MapCameraPosition = .automatic`
- La carte peut maintenant être contrôlée par le parent (centrer sur un coureur)
- Centrage automatique uniquement quand position = `.automatic`

## Modifications des Fichiers

### SessionDetailView.swift
- ✅ Ajout de `runnerLocations`, `selectedRunnerId`, `mapPosition` comme `@State`
- ✅ Passage de `runnerLocations` et `mapPosition` à `MapView`
- ✅ Ajout de `observeRunnerLocations()` dans `.task`
- ✅ Ajout de la fonction `centerMapOnRunner(userId:)`
- ✅ Modification de `ParticipantRow` pour accepter `isSelected` et `onTap`

### MapView.swift
- ✅ Changement de `position` de `@State` à `@Binding`
- ✅ Ajustement de `onChange` pour respecter la position manuelle

### ParticipantRow (dans SessionDetailView.swift)
- ✅ Ajout de `isSelected: Bool` et `onTap: () -> Void`
- ✅ Ajout de `isCurrentUser` computed property
- ✅ Affichage conditionnel "Vous" vs nom du coureur
- ✅ Transformation en `Button` pour gérer le tap
- ✅ Indication visuelle de sélection (bordure + icône)

## Architecture du Tracking en Temps Réel

```
SessionDetailView
    ├── observeRunnerLocations(sessionId)
    │   └── RealtimeLocationRepository
    │       └── Firestore: sessions/{sessionId}/locations/{userId}
    │           ├── userId
    │           ├── latitude
    │           ├── longitude
    │           ├── displayName
    │           └── timestamp
    │
    ├── MapView(runnerLocations, mapPosition)
    │   └── Affiche les annotations pour chaque coureur
    │
    └── ParticipantRow(userId, isSelected, onTap)
        └── Affiche "Vous" ou le nom + permet de centrer la carte

```

## Prochaines Étapes

### Fonctionnalités Manquantes à Implémenter:

1. **Publier la position de l'utilisateur actuel**
   - Appeler `RealtimeLocationRepository.publishLocation()` depuis `LocationProvider` ou un ViewModel
   - Mettre à jour régulièrement la position (toutes les 5-10 secondes pendant la course)

2. **Afficher les stats réelles des coureurs**
   - Calculer la distance parcourue par chaque coureur
   - Calculer le rythme moyen (pace)
   - Récupérer depuis `participantStats` dans Firestore

3. **Détecter si un coureur est "En course"**
   - Vérifier la fraîcheur du timestamp de position (< 30 secondes = En course)
   - Mettre à jour l'indicateur vert/gris dans `ParticipantRow`

4. **Tracer les parcours sur la carte**
   - Stocker l'historique des positions dans Firestore
   - Dessiner les polylignes sur la carte avec `MapPolyline`

5. **Améliorer l'UX de sélection**
   - Ajouter un bouton "Tout voir" pour revenir à la vue globale
   - Afficher une mini-card avec les stats du coureur sélectionné

## Test Manuel

Pour tester ces corrections:

1. **Tester "Vous" vs nom**:
   - Créer une session avec 2+ participants
   - Vérifier que votre participant affiche "Vous (VotreNom)"
   - Vérifier que les autres affichent juste leur nom

2. **Tester le centrage sur clic**:
   - Cliquer sur un participant
   - Vérifier que la carte se centre sur sa position avec animation
   - Vérifier l'indication visuelle de sélection (bordure + icône)

3. **Tester l'affichage des positions**:
   - Avoir 2 coureurs qui publient leur position via `publishLocation()`
   - Vérifier que les 2 annotations apparaissent sur la carte
   - Vérifier que les positions se mettent à jour en temps réel

## Notes Techniques

- ⚠️ **Attention**: Pour que les positions des autres coureurs apparaissent, ils doivent activement publier leur position avec `RealtimeLocationRepository.publishLocation()`
- 📝 La fonction `observeRunnerLocations()` utilise un `AsyncStream` qui écoute indéfiniment
- 🎨 La sélection d'un coureur ne change pas son état dans Firestore, c'est purement local
- 🔄 Le binding `mapPosition` permet un contrôle bidirectionnel de la caméra

