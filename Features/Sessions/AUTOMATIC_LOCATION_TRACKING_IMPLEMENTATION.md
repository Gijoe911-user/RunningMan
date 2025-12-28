# Publication Automatique des Positions GPS

## Date: 28 décembre 2025

## Vue d'Ensemble

Ce document décrit l'implémentation complète de la publication automatique des positions GPS pendant les sessions actives, permettant le suivi en temps réel de tous les participants d'une session.

---

## Architecture du Système

### 🏗️ Composants Principaux

```
┌─────────────────────────────────────────────────────────────┐
│                    SessionDetailView                         │
│  - Démarre le tracking automatiquement                      │
│  - Observe les positions des autres coureurs                │
│  - Affiche la carte avec tous les runners                   │
└────────────┬────────────────────────────────────────────────┘
             │
             ├──────────────────────────────────┐
             │                                  │
             ▼                                  ▼
┌─────────────────────────┐      ┌────────────────────────────┐
│   LocationService       │      │ RealtimeLocationRepository │
│  - Gère le GPS          │◄─────┤  - Interface Firestore     │
│  - Publie positions     │      │  - Observe positions       │
│  - Calcule stats        │      └────────────────────────────┘
└─────────────────────────┘                   │
             │                                │
             ▼                                ▼
┌───────────────────────────────────────────────────────────┐
│                    Firestore Database                      │
│                                                            │
│  sessions/{sessionId}/                                     │
│    ├── locations/{userId}      ← Positions en temps réel  │
│    │   ├── latitude                                       │
│    │   ├── longitude                                      │
│    │   ├── timestamp                                      │
│    │   └── displayName                                    │
│    │                                                       │
│    └── participantStats/{userId} ← Statistiques           │
│        ├── distance                                        │
│        ├── duration                                        │
│        ├── averageSpeed                                    │
│        └── maxSpeed                                        │
└───────────────────────────────────────────────────────────┘
```

---

## ✅ Modifications Apportées

### 1. **LocationService.swift**

#### Modification : Utilisation de RealtimeLocationRepository

**Avant** :
```swift
// Envoi direct vers Firestore
let locationRef = db.collection("sessions")
    .document(sessionId)
    .collection("locations")
    .document(userId)
try locationRef.setData(from: locationPoint)
```

**Après** :
```swift
// Utilisation du repository
let repository = RealtimeLocationRepository()
try await repository.publishLocation(
    sessionId: sessionId,
    userId: userId,
    coordinate: location.coordinate
)
```

**Avantages** :
- ✅ Centralisation de la logique d'envoi
- ✅ Récupération automatique du `displayName`
- ✅ Gestion cohérente du format des données
- ✅ Réutilisabilité du code

---

### 2. **SessionDetailView.swift**

#### A. Changement de `LocationProvider` à `LocationService`

**Avant** :
```swift
@ObservedObject private var locationProvider = LocationProvider.shared
```

**Après** :
```swift
@ObservedObject private var locationService = LocationService.shared
```

**Raison** : `LocationService` est un service complet qui gère :
- Le tracking GPS
- La publication automatique vers Firestore
- Le calcul des statistiques
- L'observation des autres coureurs

#### B. Démarrage automatique du tracking

**Implémentation** :
```swift
.task {
    await loadSquadName()
    
    // Démarrer le tracking pour cette session
    if let sessionId = session.id,
       let userId = AuthService.shared.currentUserId {
        
        // Demander l'autorisation si nécessaire
        if !locationService.isAuthorized {
            locationService.requestAuthorization()
        }
        
        // Démarrer le tracking
        locationService.startTracking(sessionId: sessionId, userId: userId)
    }
    
    // Observer les positions des coureurs
    if let sessionId = session.id {
        await observeRunnerLocations(sessionId: sessionId)
    }
}
```

**Comportement** :
1. ✅ Demande l'autorisation GPS si nécessaire
2. ✅ Démarre le tracking automatiquement à l'ouverture de la vue
3. ✅ Publie la position toutes les 5 mètres (configuré dans `LocationService`)
4. ✅ Observe les positions des autres coureurs en temps réel
5. ✅ Arrête le tracking à la fermeture de la vue

---

### 3. **ParticipantRow**

#### A. Ajout de l'observation des stats en temps réel

**Nouvelle fonction** :
```swift
private func startObservingParticipant() async {
    let db = Firestore.firestore()
    
    // Observer les stats du participant
    let statsRef = db.collection("sessions")
        .document(sessionId)
        .collection("participantStats")
        .document(userId)
    
    statsRef.addSnapshotListener { snapshot, error in
        guard let snapshot = snapshot, snapshot.exists else { return }
        
        if let participantStats = try? snapshot.data(as: ParticipantStats.self) {
            Task { @MainActor in
                self.stats = participantStats
            }
        }
    }
}
```

#### B. Détection automatique si le coureur est actif

**Logique** :
```swift
// Observer les positions pour détecter si actif
locationRef.addSnapshotListener { snapshot, error in
    if let data = snapshot.data(),
       let timestamp = data["timestamp"] as? Timestamp {
        let locationDate = timestamp.dateValue()
        
        // Considérer actif si dernière mise à jour < 30 secondes
        let timeSinceUpdate = Date().timeIntervalSince(locationDate)
        self.isRunning = timeSinceUpdate < 30
    }
}
```

**Indicateur visuel** :
- 🟢 **Vert** : Coureur actif (position < 30s)
- ⚪ **Gris** : Coureur inactif ou en attente

#### C. Affichage des stats réelles

**Avant** : Stats factices (hardcodées)
```swift
Text("3.2 km")  // Placeholder
Text("5'30\"/km")  // Placeholder
```

**Après** : Stats depuis Firestore
```swift
if let stats = stats, stats.distance > 0 {
    Text(String(format: "%.2f km", stats.distance / 1000))
    
    if stats.averageSpeed > 0 {
        let pace = formatPace(speed: stats.averageSpeed)
        Text(pace)
    }
}
```

---

## 🔄 Flux de Données en Temps Réel

### Publication de Position (Toutes les 5 mètres)

```
1. CLLocationManager detecte un changement de position
   ↓
2. LocationService.locationManager(_:didUpdateLocations:)
   ↓
3. Validation de la précision (< 50m)
   ↓
4. LocationService.sendLocationToFirestore(location:)
   ↓
5. RealtimeLocationRepository.publishLocation()
   ↓
6. Firestore: sessions/{sessionId}/locations/{userId}
   ↓
7. Tous les participants reçoivent la mise à jour
```

### Mise à Jour des Statistiques (Toutes les 10 secondes)

```
1. Timer déclenché (10s)
   ↓
2. LocationService.updateStatsInFirestore()
   ↓
3. SessionService.updateParticipantStats()
   ↓
4. Firestore: sessions/{sessionId}/participantStats/{userId}
   ↓
5. ParticipantRow reçoit la mise à jour via Snapshot Listener
   ↓
6. UI se rafraîchit automatiquement
```

---

## 📊 Données Publiées

### Position (sessions/{sessionId}/locations/{userId})

```json
{
  "userId": "abc123",
  "displayName": "Jean Coureur",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "timestamp": "2025-12-28T14:30:00Z",
  "photoURL": "https://..."  // Optionnel
}
```

### Statistiques (sessions/{sessionId}/participantStats/{userId})

```json
{
  "userId": "abc123",
  "distance": 3200.5,  // en mètres
  "duration": 1800,    // en secondes
  "averageSpeed": 1.78,  // en m/s
  "maxSpeed": 3.5,      // en m/s
  "locationPointsCount": 640,
  "joinedAt": "2025-12-28T14:00:00Z"
}
```

---

## 🎯 Fonctionnalités Actives

### ✅ Implémentées

1. **Publication automatique des positions**
   - Toutes les 5 mètres
   - Avec displayName de l'utilisateur
   - Via `RealtimeLocationRepository`

2. **Observation en temps réel**
   - Positions de tous les coureurs sur la carte
   - Mise à jour instantanée

3. **Calcul automatique des stats**
   - Distance parcourue
   - Vitesse moyenne et maximale
   - Durée de la course

4. **Détection d'activité**
   - Indicateur vert/gris selon timestamp
   - Seuil de 30 secondes

5. **Affichage "Vous" pour l'utilisateur actuel**
   - Avec nom entre parenthèses

6. **Centrage sur participant au clic**
   - Avec animation
   - Indication visuelle de sélection

---

## ⚙️ Configuration Requise

### Info.plist

Pour le tracking GPS, ajoutez ces clés :

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>RunningMan a besoin de votre localisation pour suivre votre course et partager votre position avec votre squad.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>RunningMan peut continuer à suivre votre position en arrière-plan pour des sessions de course continues.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>RunningMan a besoin d'accéder à votre localisation pour suivre vos courses, même en arrière-plan.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

### Capabilities Xcode

1. Ouvrir le projet dans Xcode
2. Sélectionner la target **RunningMan**
3. Aller dans **Signing & Capabilities**
4. Ajouter **Background Modes**
5. Cocher **Location updates**

---

## 🧪 Tests Manuels

### Test 1 : Publication de Position

1. Lancer l'app et créer/rejoindre une session
2. Ouvrir `SessionDetailView`
3. Accepter les permissions de localisation
4. Vérifier dans Firebase Console :
   - `sessions/{sessionId}/locations/{userId}` existe
   - `displayName` est correct
   - `timestamp` se met à jour

**Résultat attendu** : Position mise à jour toutes les 5 mètres

### Test 2 : Observation des Autres Coureurs

1. Avoir 2 appareils/simulateurs
2. Les deux rejoignent la même session
3. Se déplacer avec un appareil
4. Vérifier sur l'autre appareil :
   - Annotation apparaît sur la carte
   - Position se met à jour en temps réel

**Résultat attendu** : Les deux coureurs se voient mutuellement

### Test 3 : Affichage des Stats

1. Rejoindre une session et commencer à courir
2. Vérifier dans `ParticipantRow` :
   - Distance s'affiche et augmente
   - Allure (pace) se calcule correctement
   - Indicateur passe au vert

**Résultat attendu** : Stats réelles affichées

### Test 4 : Détection d'Activité

1. Rejoindre une session
2. Arrêter de bouger pendant 30 secondes
3. Vérifier que l'indicateur passe au gris

**Résultat attendu** : Indicateur vert → gris après 30s

### Test 5 : Centrage sur Participant

1. Avoir plusieurs participants dans une session
2. Cliquer sur un participant dans la liste
3. Vérifier :
   - Carte se centre sur le coureur avec animation
   - Bordure colorée autour de l'avatar
   - Icône de localisation à droite

**Résultat attendu** : Carte centrée avec indications visuelles

---

## 🐛 Problèmes Connus et Solutions

### Problème 1 : Position ne se met pas à jour

**Symptômes** :
- Aucune mise à jour dans Firestore
- Carte ne bouge pas

**Solutions** :
1. Vérifier les permissions GPS
2. Vérifier que `locationService.isTracking == true`
3. Vérifier la précision GPS (doit être < 50m)
4. Désactiver le simulateur "Static Location"

### Problème 2 : Stats ne s'affichent pas

**Symptômes** :
- Distance reste à 0
- Pas d'allure affichée

**Solutions** :
1. Vérifier que le timer de 10s fonctionne
2. Vérifier dans Firebase Console que `participantStats` existe
3. Attendre au moins 10 secondes après le début

### Problème 3 : Coureur toujours "En attente"

**Symptômes** :
- Indicateur reste gris malgré le mouvement
- `isRunning = false`

**Solutions** :
1. Vérifier que les positions sont publiées
2. Vérifier le `timestamp` dans Firestore
3. Désynchronisation d'horloge possible

### Problème 4 : Tracking continue après fermeture

**Symptômes** :
- GPS reste actif
- Batterie se vide

**Solutions** :
1. S'assurer que `.onDisappear` appelle `stopTracking()`
2. Vérifier qu'il n'y a pas de retain cycle
3. Implémenter un bouton "Arrêter" explicite

---

## 🚀 Améliorations Futures

### 1. **Mode Économie d'Énergie**
- Réduire la fréquence de mise à jour (ex: 20m au lieu de 5m)
- Désactiver le tracking si vitesse = 0 pendant 5 minutes

### 2. **Historique du Parcours**
- Stocker toutes les positions (pas juste la dernière)
- Tracer la polyligne sur la carte
- Collection : `sessions/{sessionId}/routes/{userId}/points`

### 3. **Notifications de Proximité**
- Alerter quand un coureur s'approche
- "Jean est à 500m de vous !"

### 4. **Mode Hors Ligne**
- Stocker les positions localement
- Synchroniser quand connexion rétablie

### 5. **Statistiques Avancées**
- Élévation (dénivelé)
- Zones de fréquence cardiaque (avec HealthKit)
- Segments (sprints détectés automatiquement)

### 6. **Tracking Intelligent**
- Démarrage automatique quand vitesse > seuil
- Arrêt automatique si immobile 10 minutes
- Pause automatique aux feux rouges

---

## 📖 Utilisation du Système

### Pour les Développeurs

#### Démarrer le tracking manuellement

```swift
let locationService = LocationService.shared

// Demander autorisation
if !locationService.isAuthorized {
    locationService.requestAuthorization()
}

// Démarrer
locationService.startTracking(
    sessionId: "session123",
    userId: "user456"
)

// Arrêter
locationService.stopTracking()
```

#### Observer les positions

```swift
let repository = RealtimeLocationRepository()
let stream = repository.observeRunnerLocations(sessionId: "session123")

for await locations in stream {
    print("Positions des \(locations.count) coureurs")
    for location in locations {
        print("\(location.displayName): \(location.latitude), \(location.longitude)")
    }
}
```

#### Publier une position manuellement

```swift
let repository = RealtimeLocationRepository()
let coordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)

try await repository.publishLocation(
    sessionId: "session123",
    userId: "user456",
    coordinate: coordinate
)
```

---

## 🔐 Sécurité et Confidentialité

### Règles Firestore

Les positions doivent être protégées :

```javascript
match /sessions/{sessionId}/locations/{userId} {
  // Lecture : Tous les participants de la session
  allow read: if isParticipant(sessionId);
  
  // Écriture : Seulement sa propre position
  allow write: if request.auth.uid == userId && isParticipant(sessionId);
}

match /sessions/{sessionId}/participantStats/{userId} {
  // Lecture : Tous les participants
  allow read: if isParticipant(sessionId);
  
  // Écriture : Seulement ses propres stats
  allow write: if request.auth.uid == userId && isParticipant(sessionId);
}

function isParticipant(sessionId) {
  return request.auth.uid in get(/databases/$(database)/documents/sessions/$(sessionId)).data.participants;
}
```

### Données Sensibles

- ✅ Les positions ne sont visibles que par les participants de la session
- ✅ Les positions sont supprimées automatiquement quand la session se termine
- ✅ Pas de stockage d'historique sans consentement
- ❌ Ne jamais partager les positions en dehors des sessions actives

---

## 📝 Conclusion

Le système de tracking automatique est maintenant **entièrement fonctionnel** :

✅ Publication automatique des positions GPS  
✅ Observation en temps réel des autres coureurs  
✅ Calcul et affichage des statistiques  
✅ Détection d'activité (vert/gris)  
✅ Affichage "Vous" pour l'utilisateur actuel  
✅ Centrage sur participant au clic  

**L'expérience utilisateur est complète** : dès qu'un utilisateur ouvre `SessionDetailView`, son tracking démarre automatiquement et il voit tous les autres coureurs en temps réel sur la carte.

---

## 📞 Support

Pour toute question ou problème :
1. Consultez les logs avec `Logger.log()` (catégorie `.location`)
2. Vérifiez Firebase Console : `sessions/{sessionId}/locations`
3. Testez avec 2 appareils/simulateurs en parallèle

---

**Dernière mise à jour** : 28 décembre 2025  
**Version** : 1.0  
**Auteur** : AI Assistant

