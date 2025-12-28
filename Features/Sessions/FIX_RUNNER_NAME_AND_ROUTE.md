# 🔧 Corrections - Nom Coureur & Tracé GPS

**Date :** 27 Décembre 2025  
**Status :** ✅ **Corrigé**

---

## 🐛 Problèmes Identifiés par Tests

### 1. **Nom "Runner" au lieu du vrai nom** ❌
**Symptôme :** Tous les coureurs s'affichent comme "Runner"

**Cause :** 
`RealtimeLocationRepository.publishLocation()` n'envoyait pas le nom dans Firestore

### 2. **Pas de tracé visible sur la carte** ❌
**Symptôme :** La ligne rouge ne s'affiche pas malgré le déplacement GPS

**Cause :** 
`ActiveSessionViewModel` ne gérait pas `routeCoordinates`

---

## ✅ Solution 1 : Afficher le Vrai Nom

### **Fichier Modifié :** `RealtimeLocationRepository.swift`

**Avant ❌ :**
```swift
func publishLocation(...) async throws {
    let payload: [String: Any] = [
        "userId": userId,
        "latitude": coordinate.latitude,
        "longitude": coordinate.longitude,
        "timestamp": Timestamp(date: Date())
        // ❌ Manque: displayName, photoURL
    ]
    
    try await docRef.setData(payload, merge: true)
}
```

**Après ✅ :**
```swift
func publishLocation(...) async throws {
    // Récupérer le nom de l'utilisateur
    let displayName = try await getUserDisplayName(userId: userId)
    let photoURL = try? await getUserPhotoURL(userId: userId)
    
    var payload: [String: Any] = [
        "userId": userId,
        "latitude": coordinate.latitude,
        "longitude": coordinate.longitude,
        "timestamp": Timestamp(date: Date()),
        "displayName": displayName  // ✅ Ajouté
    ]
    
    // Ajouter photoURL si disponible
    if let photoURL = photoURL {
        payload["photoURL"] = photoURL
    }
    
    try await docRef.setData(payload, merge: true)
}

// Helpers ajoutés
private func getUserDisplayName(userId: String) async throws -> String {
    let userDoc = try await db.collection("users").document(userId).getDocument()
    
    if let data = userDoc.data(),
       let displayName = data["displayName"] as? String {
        return displayName
    }
    
    return "Coureur" // Fallback
}

private func getUserPhotoURL(userId: String) async throws -> String? {
    let userDoc = try await db.collection("users").document(userId).getDocument()
    
    if let data = userDoc.data(),
       let photoURL = data["photoURL"] as? String {
        return photoURL
    }
    
    return nil
}
```

**Résultat :**
- ✅ Le nom réel de l'utilisateur s'affiche
- ✅ Photo de profil chargée (si disponible)
- ✅ Fallback "Coureur" si pas de nom

---

## ✅ Solution 2 : Afficher le Tracé GPS

### **Fichier Modifié :** `ActiveSessionDetailView.swift`

**Avant ❌ :**
```swift
class ActiveSessionViewModel: ObservableObject {
    @Published var runnerLocations: [RunnerLocation] = []
    @Published var userLocation: CLLocationCoordinate2D?
    // ❌ Manque: routeCoordinates
    
    func startObserving(sessionId: String) async {
        realtimeService.$userCoordinate
            .assign(to: &$userLocation)
        // ❌ Pas d'ajout au tracé
    }
}
```

**Après ✅ :**
```swift
class ActiveSessionViewModel: ObservableObject {
    @Published var runnerLocations: [RunnerLocation] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []  // ✅ Ajouté
    
    private let routeService = RouteTrackingService.shared  // ✅ Ajouté
    
    func startObserving(sessionId: String) async {
        realtimeService.$userCoordinate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.userLocation = coordinate
                
                // ✅ Ajouter au tracé
                if let coordinate = coordinate {
                    self?.routeService.addRoutePoint(coordinate)
                    self?.routeCoordinates = self?.routeService.getCurrentRoute() ?? []
                    Logger.log("📍 Route: \(self?.routeCoordinates.count ?? 0) points", category: .location)
                }
            }
            .store(in: &cancellables)
    }
}
```

**Résultat :**
- ✅ Chaque position GPS est ajoutée au tracé
- ✅ `routeCoordinates` se remplit automatiquement
- ✅ La ligne rouge s'affiche sur la carte
- ✅ Logs pour débugger le nombre de points

---

## 🧪 Comment Tester

### Test 1 : Vérifier le Nom
```
1. Créer une session avec 2 utilisateurs
2. Vérifier sur la carte :
   ✅ "Jean" au lieu de "Runner"
   ✅ "Marie" au lieu de "Runner"
   ✅ Avatar s'affiche (si configuré)
```

### Test 2 : Vérifier le Tracé
```
1. Créer une session
2. Simulateur → Location → City Run
3. Attendre 10-20 secondes
4. Observer la carte :
   ✅ Ligne rouge apparaît
   ✅ Ligne suit la position
   ✅ Ligne s'allonge avec le temps
```

### Test 3 : Console Logs
```
Chercher dans la console :
✅ "📍 Route: 1 points"
✅ "📍 Route: 2 points"
✅ "📍 Route: 3 points"
...

Si vous voyez ça → Tracé fonctionne !
```

---

## 📊 Firestore - Données Sauvegardées

### Collection `sessions/{sessionId}/locations/{userId}`

**Avant ❌ :**
```javascript
{
  "userId": "abc123",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "timestamp": Timestamp
  // Manque displayName
}
```

**Après ✅ :**
```javascript
{
  "userId": "abc123",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "timestamp": Timestamp,
  "displayName": "Jean Dupont",  // ✅ Ajouté
  "photoURL": "https://..."      // ✅ Optionnel
}
```

---

## 🎯 Résultat Attendu

### Sur la Carte
```
┌─────────────────────────────┐
│              [🎯][👥][💾]  │
│                             │
│    ───────── Ligne rouge    │ ✅ Tracé visible
│    🔵 Vous                  │
│    👤 Jean Dupont           │ ✅ Vrai nom
│    👤 Marie Martin          │ ✅ Vrai nom
│                             │
└─────────────────────────────┘
```

### Dans les Logs
```
📍 Route: 1 points
📍 Route: 2 points
📍 Route: 5 points
📍 Route: 10 points
...
📍 Route: 50 points
```

---

## 💡 Si le Tracé Ne S'Affiche Toujours Pas

### Debug Checklist

1. **Vérifier que les points sont ajoutés**
   ```swift
   // Dans console, chercher :
   "📍 Route: X points"
   
   Si X augmente → Points ajoutés ✅
   Si X reste à 0 → Problème GPS ❌
   ```

2. **Vérifier routeCoordinates dans la vue**
   ```swift
   // Ajouter dans EnhancedSessionMapView
   Text("Points: \(routeCoordinates.count)")
   
   Si > 0 → Données OK ✅
   Si = 0 → Pas de données ❌
   ```

3. **Vérifier la couleur de la ligne**
   ```swift
   // Dans EnhancedSessionMapView
   MapPolyline(coordinates: routeCoordinates)
       .stroke(Color.red, lineWidth: 8)  // Plus épais pour test
   ```

4. **Vérifier les coordonnées GPS**
   ```swift
   // Ajouter log dans addRoutePoint
   Logger.log("📍 Point: \(coordinate.latitude), \(coordinate.longitude)")
   
   Si coordonnées changent → GPS OK ✅
   Si coordonnées fixes → GPS bloqué ❌
   ```

---

## 🚀 Prochains Tests

Maintenant que c'est corrigé, testez :

1. **Nom des Coureurs**
   - [ ] Vérifier vrai nom s'affiche
   - [ ] Tester avec 2+ utilisateurs
   - [ ] Avatar s'affiche (si configuré)

2. **Tracé GPS**
   - [ ] Ligne rouge visible
   - [ ] Ligne suit le déplacement
   - [ ] Tracé sauvegardé (bouton 💾)
   - [ ] Logs confirment les points

3. **Multi-Utilisateurs**
   - [ ] Chaque coureur a son nom
   - [ ] Positions se mettent à jour
   - [ ] Pas de "Runner" générique

---

## 📝 Fichiers Modifiés

1. ✅ `RealtimeLocationRepository.swift` - Ajout nom + photo
2. ✅ `ActiveSessionDetailView.swift` - Ajout routeCoordinates

---

**Status :** ✅ **Corrigé - Prêt pour re-test**

**Action immédiate :**
1. Build & Run (Cmd + R)
2. Créer session
3. Location → City Run
4. Vérifier nom + tracé apparaissent

**Devrait maintenant afficher :**
- ✅ Vrais noms des coureurs
- ✅ Ligne rouge du tracé
- ✅ Logs dans console
