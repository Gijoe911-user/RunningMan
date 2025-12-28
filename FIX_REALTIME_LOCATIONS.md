# 🔧 Fix: Positions en temps réel et mises à jour de session

> **Problème :** Les coureurs n'apparaissent pas sur la carte et les stats ne se mettent pas à jour

---

## 🐛 Problèmes identifiés

### 1. Les positions des autres coureurs ne s'affichent pas
**Cause :** Le `RealtimeLocationService` n'est pas correctement initialisé pour observer la session.

### 2. Les stats de session ne se mettent pas à jour
**Cause :** Pas de stream temps réel sur la session elle-même, seulement sur les positions.

### 3. Le contexte squad n'est pas défini
**Cause :** `RealtimeLocationService.setContext(squadId:)` n'est probablement pas appelé.

---

## ✅ Solutions implémentées

### 1. Amélioration de `SessionService`

**Nouvelles méthodes ajoutées :**

```swift
// Observer une session spécifique en temps réel
func observeSession(sessionId: String) -> AsyncStream<SessionModel?>

// Mettre à jour les stats globales de la session
func updateSessionStats(sessionId: String, totalDistance: Double, averageSpeed: Double) async throws

// Mettre à jour la durée
func updateSessionDuration(sessionId: String, duration: TimeInterval) async throws
```

### 2. Amélioration de `ActiveSessionViewModel`

**Propriétés ajoutées :**
```swift
@Published var currentSession: SessionModel?  // Session avec mises à jour temps réel
private var sessionObservationTask: Task<Void, Never>?  // Observer la session
```

**Méthodes ajoutées :**
```swift
// Observer les mises à jour de la session
private func observeSessionUpdates(sessionId: String)

// Démarrer le tracking manuel si besoin
private func startManualLocationTracking(sessionId: String) async
```

---

## 🔍 Comment débugger

### Étape 1 : Vérifier les permissions GPS

Dans `Info.plist`, s'assurer que ces clés existent :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nous avons besoin de votre position pour suivre votre course en temps réel</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Permet de continuer à tracker votre position même en arrière-plan</string>
```

### Étape 2 : Vérifier que le contexte est défini

Dans `SquadDetailView` ou là où la session est créée, s'assurer que :

```swift
// QUAND vous sélectionnez un squad
RealtimeLocationService.shared.setContext(squadId: squad.id)
```

### Étape 3 : Vérifier les logs

Cherchez dans la console Xcode :

```
🎬 Démarrage observation session: [sessionId]
👥 Coureurs reçus: X
📍 Position initiale publiée
✅ Session active déjà détectée
```

**Si vous voyez :**
```
⚠️ Aucune session active détectée
⚠️ Impossible de publier la position: userId ou coordinate manquant
```

→ **Problème** : Le `RealtimeLocationService` n'a pas de session active.

### Étape 4 : Vérifier Firestore

#### Structure attendue :

```
sessions/
  {sessionId}/
    - status: "ACTIVE"
    - squadId: "..."
    - participants: ["userId1", "userId2"]
    - totalDistanceMeters: 1500
    - averageSpeed: 2.5
    
    locations/  ← SOUS-COLLECTION
      {userId1}/
        - latitude: 48.8566
        - longitude: 2.3522
        - timestamp: [Timestamp]
        - displayName: "John"
        - photoURL: "https://..."
      {userId2}/
        - latitude: 48.8600
        - longitude: 2.3500
        ...
```

#### Vérifier dans la console Firebase :

1. Aller sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionner votre projet
3. Aller dans **Firestore Database**
4. Naviguer vers `sessions/{sessionId}/locations`
5. Vérifier que des documents apparaissent avec les positions

**Si vide :**  
→ Les positions ne sont pas publiées. Vérifier `publishLocation` dans `RealtimeLocationRepository`.

---

## 🔧 Code à ajouter dans SquadDetailView

Pour s'assurer que le contexte est défini correctement :

```swift
struct SquadDetailView: View {
    let squad: SquadModel
    
    var body: some View {
        // ... votre UI
    }
    .task {
        // ✅ IMPORTANT: Définir le contexte dès l'entrée dans la vue
        RealtimeLocationService.shared.setContext(squadId: squad.id ?? "")
    }
    .onDisappear {
        // Optionnel: Nettoyer le contexte en sortant
        // RealtimeLocationService.shared.clearContext()
    }
}
```

---

## 🧪 Test manuel

### Test 1 : Vérifier la publication de position

```swift
// Dans ActiveSessionViewModel.startObserving()
print("🧪 Test: sessionId = \(sessionId)")
print("🧪 Test: userId = \(AuthService.shared.currentUserId ?? "nil")")
print("🧪 Test: coordinate = \(realtimeService.userCoordinate?.latitude ?? 0)")
print("🧪 Test: activeSession = \(realtimeService.activeSession?.id ?? "nil")")
```

### Test 2 : Simuler une position

Dans Xcode :
1. **Debug** → **Simulate Location** → **Custom Location**
2. Entrer : Latitude `48.8566`, Longitude `2.3522`
3. Observer les logs

### Test 3 : Tester avec 2 appareils/simulateurs

1. Lancer l'app sur 2 simulateurs ou appareils
2. Créer une session sur le premier
3. Rejoindre la session sur le second
4. Observer que les 2 markers apparaissent sur la carte

---

## 📋 Checklist de débogage

- [ ] Permissions GPS accordées
- [ ] `RealtimeLocationService.setContext()` appelé
- [ ] Session créée avec `status: "ACTIVE"`
- [ ] Session a un `squadId` valide
- [ ] Utilisateur est dans `participants`
- [ ] GPS activé sur l'appareil
- [ ] Positions visibles dans Firestore sous `sessions/{id}/locations`
- [ ] Logs montrent "👥 Coureurs reçus: X" avec X > 0
- [ ] Règles Firestore permettent l'écriture dans `locations`

---

## 🔥 Règles Firestore à vérifier

Assurez-vous que vos règles Firestore permettent l'accès aux positions :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Sessions
    match /sessions/{sessionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      
      // ✅ IMPORTANT: Locations sous-collection
      match /locations/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Stats participants
      match /participantStats/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
  }
}
```

---

## 🎯 Solution rapide (Quick Fix)

Si rien ne fonctionne, ajoutez ce code dans `ActiveSessionDetailView.body` :

```swift
.task {
    // Force le contexte immédiatement
    if let squadId = session.squadId {
        RealtimeLocationService.shared.setContext(squadId: squadId)
    }
    
    // Attendre un peu que le GPS se stabilise
    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
    
    // Démarrer l'observation
    await viewModel.startObserving(sessionId: session.id ?? "")
}
```

---

## 🐛 Erreurs courantes

### Erreur 1 : "No documents found"
```
⚠️ Aucun document trouvé
```
**Solution :** La session n'existe pas ou le squadId est incorrect.

### Erreur 2 : "Permission denied"
```
❌ ERROR observeRunnerLocations: Permission denied
```
**Solution :** Règles Firestore trop restrictives, voir section "Règles Firestore" ci-dessus.

### Erreur 3 : "Coordinate is nil"
```
⚠️ Impossible de publier la position: userId ou coordinate manquant
```
**Solution :** GPS pas encore initialisé. Attendre quelques secondes ou appeler `requestOneShotLocation()`.

---

## ✅ Validation

Une fois les corrections appliquées, vous devriez voir dans les logs :

```
🎬 Démarrage observation session: abc123xyz
✅ Session active déjà détectée: abc123xyz
👥 Coureurs reçus: 2
📍 Route: 10 points
📍 Route: 20 points
🔄 Session mise à jour: distance=1500m
```

Et sur la carte :
- ✅ Votre position (marker bleu pulsant)
- ✅ Les autres coureurs (markers avec leur nom)
- ✅ Tracé GPS de votre parcours
- ✅ Stats qui se mettent à jour en temps réel

---

## 📞 Support

Si le problème persiste après avoir suivi ce guide :

1. Copier les logs de la console
2. Vérifier la structure Firestore
3. Vérifier les règles Firestore
4. Tester avec la simulation de localisation

---

**Dernière mise à jour :** 28 Décembre 2025
