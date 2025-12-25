# 📋 TODO - Phase 1 MVP - Prochaines Étapes

**Dernière mise à jour :** 24 Décembre 2025  
**Voir aussi :** `STATUS.md` pour l'état détaillé du projet

---

## ✅ COMPLÉTÉ - Configuration Initiale

### 1. Configuration Firebase ✅
- [x] Créer projet Firebase "RunningMan"
- [x] Activer Authentication → Email/Password
- [x] Créer base de données Firestore (mode test)
- [x] Créer Storage bucket
- [x] Télécharger `GoogleService-Info.plist`
- [x] Ajouter `GoogleService-Info.plist` dans le projet Xcode
- [x] Ajouter Firebase SDK via Swift Package Manager

### 2. Configuration Xcode ✅
- [x] Créer Asset Catalog "Colors"
- [x] Ajouter permissions dans Info.plist
- [x] Activer Capabilities (Background Modes, etc.)

### 3. Vérification Build ✅
- [x] Build projet réussi
- [x] Tests sur simulateur OK
- [x] Authentification fonctionne
- [x] Création de squads fonctionne

---

## ✅ COMPLÉTÉ - Backend Firebase (Authentification & Squads)

### 4. Services Firestore ✅
- [x] `AuthService.swift` - CRUD Users complet
- [x] `SquadService.swift` - CRUD Squads complet
- [x] Méthodes createUser, signIn, signOut
- [x] Méthodes createSquad, joinSquad, leaveSquad
- [x] Génération code d'invitation unique

### 5. Tests Fonctionnels ✅
- [x] Inscription nouveau compte
- [x] Connexion avec compte existant
- [x] Création d'une squad
- [x] Code d'invitation généré

---

## 🔥 PRIORITÉ HAUTE - À Faire Cette Semaine

### 6. Tester "Rejoindre une Squad" (1h) 🎯
**Status :** Backend OK, nécessite tests utilisateurs

- [ ] Test avec 2 comptes utilisateurs
  - [ ] Utilisateur A crée une squad
  - [ ] Noter le code d'invitation (6 caractères)
  - [ ] Se déconnecter, créer utilisateur B
  - [ ] Utilisateur B rejoint avec le code
  - [ ] Vérifier que B apparaît dans la squad

- [ ] Vérifier cas d'erreur
  - [ ] Code invalide → Message d'erreur approprié
  - [ ] Rejoindre 2x la même squad → Message approprié

**Fichiers concernés :**
- `JoinSquadView.swift` ✅ (déjà implémenté)
- `SquadService.swift` ✅ (méthode joinSquad existe)

**Estimation :** 30 min - 1h de tests manuels

---

### 7. Compléter SquadDetailView (2-3h) 🎯
**Status :** Structure existe, manque contenu

**À implémenter :**
- [ ] **Corriger le NavigationLink** dans SquadsListView
  ```swift
  // Ligne 66 de SquadsListView.swift
  // ❌ Actuel
  NavigationLink(destination: SquadDetailView()) {
  
  // ✅ Corriger en
  NavigationLink(destination: SquadDetailView(squad: squad)) {
  ```

- [ ] **Afficher les infos de la squad**
  - [ ] Nom de la squad
  - [ ] Description
  - [ ] Code d'invitation (avec bouton copier)
  - [ ] Date de création
  - [ ] Nombre de membres

- [ ] **Liste des membres**
  - [ ] Récupérer infos depuis Firestore
  - [ ] Afficher displayName + rôle (Admin/Member)
  - [ ] Différencier visuellement le créateur

- [ ] **Actions**
  - [ ] Bouton "Démarrer une session" (admins seulement)
  - [ ] Bouton "Quitter la squad" (avec confirmation)
  - [ ] Si créateur + autres membres → Message d'erreur

- [ ] **Liste des sessions passées** (optionnel Phase 1)
  - [ ] Afficher 5 dernières sessions
  - [ ] Distance, durée, date

**Fichiers concernés :**
- `SquadDetailView.swift` (à compléter)
- `SquadsListView.swift` (ligne 66 à corriger)
- `SquadService.swift` ✅ (méthode leaveSquad existe)

**Estimation :** 2-3 heures

---

### 8. Créer SessionService.swift (3-4h) 🎯
**Status :** Service n'existe pas encore

**À créer :**
- [ ] Créer fichier `Core/Services/SessionService.swift`
- [ ] Créer modèle `Core/Models/SessionModel.swift`

**SessionModel.swift :**
```swift
struct SessionModel: Identifiable, Codable {
    @DocumentID var id: String?
    var squadId: String
    var creatorId: String
    var startedAt: Date
    var endedAt: Date?
    var status: SessionStatus // .active, .paused, .ended
    var participants: [String] // userIds
    var totalDistance: Double // mètres
    var duration: TimeInterval // secondes
}

enum SessionStatus: String, Codable {
    case active = "ACTIVE"
    case paused = "PAUSED"
    case ended = "ENDED"
}
```

**SessionService.swift :**
```swift
class SessionService {
    static let shared = SessionService()
    private let db = Firestore.firestore()
    
    // Créer une session
    func createSession(squadId: String, creatorId: String) async throws -> String {
        // 1. Créer document dans collection "sessions"
        // 2. Ajouter sessionId à squad.activeSessions
        // 3. Retourner sessionId
    }
    
    // Terminer une session
    func endSession(sessionId: String) async throws {
        // 1. Mettre à jour status: .ended, endedAt: Date()
        // 2. Retirer sessionId de squad.activeSessions
        // 3. Calculer statistiques (distance totale, durée)
    }
    
    // Observer session active
    func observeActiveSession(squadId: String) -> AsyncStream<SessionModel?> {
        // Listener Firestore temps réel
    }
    
    // Rejoindre une session
    func joinSession(sessionId: String, userId: String) async throws {
        // Ajouter userId à session.participants
    }
}
```

**Tests à faire :**
- [ ] Créer une session → Vérifier dans Firestore
- [ ] Terminer une session → Status = ended
- [ ] Observer session → Temps réel fonctionne

**Estimation :** 3-4 heures

---

### 9. Créer LocationService.swift (4-5h) 🎯
**Status :** Service n'existe pas, permissions configurées ✅

**À créer :**
- [ ] Créer fichier `Core/Services/LocationService.swift`
- [ ] Implémenter `CLLocationManagerDelegate`

**LocationService.swift :**
```swift
import CoreLocation
import FirebaseFirestore

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    private var activeSessionId: String?
    private var currentUserId: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Mettre à jour tous les 10 mètres
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // Démarrer le tracking
    func startTracking(sessionId: String, userId: String) {
        self.activeSessionId = sessionId
        self.currentUserId = userId
        
        locationManager.requestWhenInUseAuthorization() // Ou Always
        locationManager.startUpdatingLocation()
    }
    
    // Arrêter le tracking
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        self.activeSessionId = nil
        self.currentUserId = nil
    }
    
    // Delegate: Nouvelle position
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              let sessionId = activeSessionId,
              let userId = currentUserId else { return }
        
        currentLocation = location
        
        // Envoyer à Firestore
        Task {
            try await updateLocationInFirestore(
                sessionId: sessionId,
                userId: userId,
                location: location
            )
        }
    }
    
    // Mettre à jour dans Firestore
    private func updateLocationInFirestore(
        sessionId: String,
        userId: String,
        location: CLLocation
    ) async throws {
        let locationData: [String: Any] = [
            "userId": userId,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "altitude": location.altitude,
            "speed": location.speed,
            "timestamp": Timestamp(date: Date())
        ]
        
        // Option 1: Document par utilisateur (recommandé)
        try await db.collection("sessions")
            .document(sessionId)
            .collection("locations")
            .document(userId)
            .setData(locationData)
        
        // Option 2: Sous-collection dans le document session
        // Plus facile à nettoyer après la session
    }
    
    // Observer les positions des autres coureurs
    func observeRunnerLocations(sessionId: String) -> AsyncStream<[RunnerLocation]> {
        // Firestore listener sur la collection locations
        // Retourner un AsyncStream qui émet les nouvelles positions
    }
}

struct RunnerLocation: Codable {
    var userId: String
    var latitude: Double
    var longitude: Double
    var speed: Double
    var timestamp: Date
}
```

**Tests à faire :**
- [ ] Demander permission localisation
- [ ] Démarrer tracking → Console logs positions
- [ ] Vérifier Firestore → Document créé avec lat/long
- [ ] Tester sur device physique en marchant
- [ ] Observer positions d'un autre utilisateur

**⚠️ Important :** Tester sur **device physique uniquement** (simulateur = position fixe)

**Estimation :** 4-5 heures (incluant tests terrain)

---

### 10. Intégrer MapView avec Positions Temps Réel (3h)
**Status :** MapView basique existe, manque sync

**À faire :**
- [ ] Importer `LocationService` dans `SessionsViewModel`
- [ ] Observer `LocationService.observeRunnerLocations()`
- [ ] Mettre à jour les annotations sur la carte
- [ ] Ajouter annotations personnalisées pour chaque coureur
- [ ] Centrer la carte sur l'utilisateur actuel

**Fichiers concernés :**
- `FeaturesSessionsSessionsListView.swift`
- `SessionsViewModel.swift` (si existe, sinon à créer)

**Estimation :** 3 heures


---

## 🟡 PRIORITÉ MOYENNE - Semaine Prochaine

### 11. Messages Basiques (3-4h)
**À créer :**
- [ ] `Core/Models/MessageModel.swift`
- [ ] `Core/Services/MessageService.swift`
- [ ] `Features/Messages/Views/MessagesView.swift`

**MessageModel :**
```swift
struct MessageModel: Identifiable, Codable {
    @DocumentID var id: String?
    var sessionId: String
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Date
    var type: MessageType // .text, .voice (Phase 2)
}

enum MessageType: String, Codable {
    case text = "TEXT"
    case voice = "VOICE"
}
```

**MessageService :**
- [ ] Envoyer message texte
- [ ] Observer messages (Firestore listener)
- [ ] Compter messages non lus

**MessagesView :**
- [ ] Liste des messages (ScrollView)
- [ ] TextField pour nouveau message
- [ ] Badge notification sur CommunicationBar

**Tests :**
- [ ] Envoyer message → Apparaît dans Firestore
- [ ] Recevoir message temps réel d'un autre utilisateur
- [ ] Badge mise à jour avec nombre non lus

**Estimation :** 3-4 heures

---

### 12. Text-to-Speech Basique (2h)
**À créer :**
- [ ] `Core/Services/TextToSpeechService.swift`

**Utilisation d'AVFoundation :**
```swift
import AVFoundation

class TextToSpeechService {
    static let shared = TextToSpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = 0.5 // Vitesse
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // Configurer pour mix avec musique utilisateur
    func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, options: [.mixWithOthers])
        try audioSession.setActive(true)
    }
}
```

**Intégration avec Messages :**
- [ ] Quand nouveau message arrive → TTS lit le message
- [ ] Option pour activer/désactiver dans préférences

**Tests :**
- [ ] Recevoir message → TTS lit à voix haute
- [ ] Fonctionne avec musique en arrière-plan
- [ ] Peut désactiver dans settings

**Estimation :** 2 heures

---


## 🟢 PRIORITÉ BASSE - Fonctionnalités Secondaires

### 13. Photos (2-3h)
- [ ] Créer `Core/Services/PhotoService.swift`
- [ ] Implémenter PhotoPicker (PhotosUI)
- [ ] Upload vers Firebase Storage
- [ ] Compression avant upload
- [ ] Afficher dans galerie session

**Estimation :** 2-3 heures

---

### 14. Profile Management (1-2h)
- [ ] Édition nom d'affichage
- [ ] Upload photo de profil
- [ ] Afficher statistiques réelles (pas mock)

**Estimation :** 1-2 heures

---

## 🧪 TESTS & QUALITÉ

### 15. Tests Unitaires (optionnel Phase 1)
- [ ] Tests AuthService
- [ ] Tests SquadService
- [ ] Tests SessionService
- [ ] Tests LocationService

### 16. Tests sur Device Physique (obligatoire)
- [ ] Test GPS en conditions réelles (marche/course)
- [ ] Test consommation batterie sur 30 min
- [ ] Test arrière-plan (GPS continue si app en background)
- [ ] Test réseau instable (mode avion on/off)

---

## 📊 Estimation Totale Restante

| Tâche | Priorité | Temps Estimé |
|-------|----------|--------------|
| Tester rejoindre squad | 🔴 Haute | 1h |
| Compléter SquadDetailView | 🔴 Haute | 2-3h |
| SessionService | 🔴 Haute | 3-4h |
| LocationService | 🔴 Haute | 4-5h |
| MapView temps réel | 🔴 Haute | 3h |
| Messages basiques | 🟡 Moyenne | 3-4h |
| Text-to-Speech | 🟡 Moyenne | 2h |
| Photos | 🟢 Basse | 2-3h |
| Tests device | 🔴 Haute | 2-3h |
| **TOTAL** | | **~25-30h** |

**Sprint 1 (Cette semaine) :** Tâches 6-10 = 13-16h  
**Sprint 2 (Semaine prochaine) :** Tâches 11-12 + Tests = 7-9h  
**Sprint 3 (Optionnel) :** Tâches 13-14 = 3-5h

---

## 🎯 Ordre de Développement Recommandé

### Cette Semaine (Sprint 1)
```
1. Tester rejoindre squad (1h)           ← Quick win
2. Corriger SquadDetailView (2-3h)       ← Finir Squads
3. Créer SessionModel (30min)            ← Prérequis
4. Créer SessionService (3-4h)           ← Core feature
5. Créer LocationService (4-5h)          ← Core feature
6. Intégrer MapView temps réel (3h)      ← Finaliser Sessions
```

**Total :** ~14-17 heures  
**Répartition :** 2-3 jours de dev intensif ou 1 semaine à temps partiel

**À la fin du Sprint 1 :**
- ✅ Squads complètes (créer, rejoindre, voir détail, quitter)
- ✅ Sessions fonctionnelles (créer, terminer)
- ✅ GPS tracking en temps réel
- ✅ Carte affiche tous les coureurs
- ✅ **MVP utilisable pour courir ensemble !**

---

### Semaine Prochaine (Sprint 2)
```
7. Messages basiques (3-4h)              ← Communication
8. Text-to-Speech (2h)                   ← Vocal
9. Tests device physique (2-3h)          ← Validation
10. Bug fixes & polish (2h)              ← Finitions
```

**Total :** ~9-11 heures

**À la fin du Sprint 2 :**
- ✅ Communication entre coureurs
- ✅ Messages lus à voix haute
- ✅ Testé en conditions réelles
- ✅ **MVP production ready !**

---

### Plus Tard (Sprint 3 - Optionnel)
```
11. Photos (2-3h)
12. Profile management (1-2h)
13. Refactoring organisation (2-3h)
14. Tests unitaires (4-5h)
```

---

## 🚀 Commencer Maintenant

### Tâche #6 : Tester "Rejoindre une Squad" (30 min)

**Procédure de test :**

1. **Créer utilisateur A**
   ```
   - Ouvrir app
   - S'inscrire: testA@mail.com / password123 / User A
   - Créer une squad "Test Squad"
   - Noter le code d'invitation (6 caractères)
   - Se déconnecter
   ```

2. **Créer utilisateur B**
   ```
   - S'inscrire: testB@mail.com / password123 / User B
   - Aller dans Squads
   - Taper sur "Rejoindre avec un code"
   - Entrer le code noté à l'étape 1
   - Vérifier succès
   ```

3. **Vérifier dans Firebase Console**
   ```
   - Aller sur console.firebase.google.com
   - Firestore Database → Collection "squads"
   - Ouvrir le document de la squad
   - Vérifier que members contient 2 userIds
   ```

4. **Tester erreurs**
   ```
   - Entrer code invalide "ABCDEF" → Erreur "Code invalide"
   - Rejoindre 2x la même squad → Erreur "Déjà membre"
   ```

**Si ça marche :** ✅ Passer à la tâche #7  
**Si ça ne marche pas :** Débugger dans `JoinSquadView.swift` et `SquadService.swift`

---

### Tâche #7 : Corriger SquadDetailView (Quick Fix - 5 min)

**Fichier :** `FeaturesSquadsSquadsListView.swift`

**Ligne 66 :**
```swift
// ❌ AVANT
NavigationLink(destination: SquadDetailView()) {
    SquadCard(squad: squad)
}

// ✅ APRÈS
NavigationLink(destination: SquadDetailView(squad: squad)) {
    SquadCard(squad: squad)
}
```

**Puis dans `SquadDetailView.swift` :**
```swift
struct SquadDetailView: View {
    let squad: SquadModel  // Ajouter cette ligne
    
    var body: some View {
        // Utiliser squad.name, squad.description, etc.
    }
}
```

**Test :** Taper sur une squad → Doit afficher le nom de la squad

---

## 📝 Notes de Développement

### Conseils
- ✅ Commiter après chaque tâche complétée
- ✅ Tester sur device physique pour GPS
- ✅ Logger dans console pour débugger
- ✅ Consulter `STATUS.md` pour voir l'état global

### Git Commits Recommandés
```bash
git commit -m "test: validate join squad flow with 2 users"
git commit -m "fix: pass squad model to SquadDetailView"
git commit -m "feat: implement SessionService with CRUD operations"
git commit -m "feat: add LocationService with GPS tracking"
git commit -m "feat: integrate real-time positions on MapView"
```

---

**Dernière mise à jour :** 24 Décembre 2025  
**Prochaine action :** Tâche #6 - Tester rejoindre une squad (30 min)

🎯 **Bon courage pour le développement !**
