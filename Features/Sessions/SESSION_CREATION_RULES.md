# 🏃 Règles de création de sessions - RunningMan

## 📋 Règles finales implémentées

### ✅ **Qui peut créer des sessions ?**
→ **Tous les membres d'une squad** (pas seulement le propriétaire)

### ✅ **Combien de sessions actives par coureur ?**
→ **Une seule session active par coureur par squad**

### ✅ **Restriction pour les Courses**
→ **Une seule Course active par squad** (tous coureurs confondus)

---

## 🔒 Règles de sécurité

### 1. **Un coureur = Une session active par squad**

```
Coureur A dans Squad "Marathon Paris":
  ✅ Peut créer une session
  ❌ Ne peut pas créer une 2ème session tant que la 1ère est active
  ✅ Peut rejoindre les sessions des autres coureurs
```

**Vérification** : Avant de créer, on vérifie :
```swift
let existingSession = try await SessionService.shared.getUserActiveSession(
    squadId: squadId,
    userId: userId
)

if existingSession != nil {
    // Afficher alerte : "Vous avez déjà une session active"
}
```

---

### 2. **Une Course active par squad**

```
Squad "Marathon Paris":
  ✅ Coureur A crée une Course → OK
  ❌ Coureur B tente de créer une Course → Proposition de rejoindre
  ✅ Coureur B rejoint la Course de A
  ✅ Coureur C peut créer un Entraînement en parallèle
```

**Vérification** : Seulement pour les sessions de type "Course" :
```swift
if isRace {
    let existingRace = try await SessionService.shared.getActiveRaceSession(squadId: squadId)
    
    if existingRace != nil {
        // Afficher dialogue : "Rejoindre la course ?"
    }
}
```

---

## 🎯 Vue globale : AllActiveSessionsView

### Caractéristiques

1. **Affiche toutes les sessions actives** de toutes les squads de l'utilisateur
2. **Informations affichées** :
   - Nom du créateur + avatar
   - Nom de la squad
   - Titre de la session
   - Lieu de RDV (ville)
   - Stats : Distance, Durée, Nb participants
   - Badge "En cours" si l'utilisateur participe déjà
3. **Bouton de création** : Menu avec choix de la squad
4. **Désactivation** : Le bouton est grisé si le coureur a déjà une session active dans cette squad

---

## 📱 Flux utilisateur

### Scénario 1 : **Créer ma première session**

```
1. Ouvrir "Sessions actives"
2. Cliquer sur "+" → Choisir "Marathon Paris"
3. Remplir les infos (titre, type, lieu, programme)
4. Créer ✅
5. Ma session apparaît dans la liste
```

---

### Scénario 2 : **Tenter de créer une 2ème session**

```
1. Ouvrir "Sessions actives"
2. Cliquer sur "+" → Choisir "Marathon Paris"
3. ⚠️ Alerte : "Session déjà active"
   → "Vous avez déjà une session active dans cette squad"
   [OK] [Voir ma session]
4. La vue se ferme
```

---

### Scénario 3 : **Rejoindre une session existante**

```
1. Ouvrir "Sessions actives"
2. Voir la session de Coureur B
3. Cliquer sur la card
4. Voir les détails de la session
5. Rejoindre la session
```

---

### Scénario 4 : **Tenter de créer une Course (une déjà active)**

```
1. Ouvrir "Créer une session"
2. Cocher "Session de type Course"
3. Cliquer "Suivant"
4. 🏁 Dialogue : "Course en cours"
   → "Voulez-vous rejoindre la course ?"
   [Annuler] [Rejoindre]
5. Si "Rejoindre" → Rejoint la course existante
6. Si "Annuler" → Retour étape 1, peut créer un entraînement
```

---

## 🗂️ Structure des données

### SessionModel (étendu)

```swift
struct SessionModel {
    var id: String?
    var squadId: String              // ✅ Squad de la session
    var creatorId: String            // ✅ Créateur de la session
    var title: String?               // ✅ Titre personnalisé
    var activityType: ActivityType   // ✅ Type (training, race...)
    
    // Localisation
    var meetingLocationName: String?        // ✅ Ex: "Lyon 3ème"
    var meetingLocationCoordinate: GeoPoint? // ✅ Coordonnées GPS
    
    // Programme
    var trainingProgramId: String?   // ✅ ID du programme associé
    
    // Stats
    var totalDistanceMeters: Double
    var durationSeconds: TimeInterval
    var participants: [String]       // ✅ UserIds
    var status: SessionStatus        // ✅ active / paused / ended
}
```

---

## 🔍 Requêtes Firestore

### 1. **Récupérer les sessions actives d'une squad**

```swift
db.collection("sessions")
    .whereField("squadId", isEqualTo: squadId)
    .whereField("status", isEqualTo: "ACTIVE")
    .getDocuments()
```

### 2. **Récupérer la session active d'un coureur**

```swift
db.collection("sessions")
    .whereField("squadId", isEqualTo: squadId)
    .whereField("creatorId", isEqualTo: userId)
    .whereField("status", isEqualTo: "ACTIVE")
    .limit(to: 1)
    .getDocuments()
```

### 3. **Récupérer la Course active d'une squad**

```swift
db.collection("sessions")
    .whereField("squadId", isEqualTo: squadId)
    .whereField("activityType", isEqualTo: "RACE")
    .whereField("status", isEqualTo: "ACTIVE")
    .limit(to: 1)
    .getDocuments()
```

---

## 💬 Messages d'encouragement partagés

### Principe

**Tous les messages** des supporteurs (ceux qui ne courent pas) sont **partagés entre toutes les sessions actives** d'une squad.

### Structure Firestore proposée

```
squads/{squadId}/
  └── sharedMessages/{messageId}
      ├── senderId: string
      ├── message: string
      ├── timestamp: timestamp
      ├── type: "encouragement" | "cheer"
      └── targetSessionIds: [sessionId1, sessionId2, ...]
```

### Logique

1. **Supporter** envoie un message
2. Message enregistré dans `sharedMessages`
3. Tous les **coureurs** de toutes les sessions actives voient le message
4. Les coureurs peuvent répondre (leurs messages sont visibles par tous)

### Implémentation (à venir)

```swift
// Dans ActiveSessionDetailView
class SharedMessagingService {
    func sendSharedMessage(
        squadId: String,
        senderId: String,
        message: String
    ) async throws {
        // Récupérer toutes les sessions actives
        let activeSessions = try await SessionService.shared.getActiveSessions(squadId: squadId)
        let sessionIds = activeSessions.compactMap { $0.id }
        
        // Enregistrer le message partagé
        let messageData: [String: Any] = [
            "senderId": senderId,
            "message": message,
            "timestamp": FieldValue.serverTimestamp(),
            "type": "encouragement",
            "targetSessionIds": sessionIds
        ]
        
        try await db.collection("squads")
            .document(squadId)
            .collection("sharedMessages")
            .addDocument(data: messageData)
    }
}
```

---

## 📊 Interface utilisateur

### 1. **AllActiveSessionsView**

**Header avec stats globales** :
```
┌─────────────────────────────────────┐
│  👥 12 Coureurs  🏃 5 Sessions  🔥 25.3 km  │
└─────────────────────────────────────┘
```

**Cards de sessions** :
```
┌─────────────────────────────────────┐
│  [Avatar] Jean Dupont               │
│           👥 Marathon Paris 2024    │
│                                     │
│  Course du dimanche matin          │
│                                     │
│  📍 Lyon 3ème                       │
│                                     │
│  📏 5.2 km  ⏱️ 25 min  👥 3        │
│                          [Rejoindre]│
└─────────────────────────────────────┘
```

### 2. **Menu de création** (Toolbar +)

```
[+]
 ├─ Créer dans Marathon Paris ✅
 ├─ Créer dans Squad du Dimanche ❌ (déjà une session)
 ├─ Créer dans Les Coureurs 2025 ✅
 └─ ───────────────
    └─ Actualiser
```

---

## ✅ Checklist d'implémentation

### Fait ✅
- [x] `AllActiveSessionsView` créée
- [x] `AllActiveSessionsViewModel` avec chargement des squads et sessions
- [x] `SessionService.getUserActiveSession()` ajoutée
- [x] Vérification avant création (une session par coureur)
- [x] Alerte "Session déjà active"
- [x] Affichage des infos : Squad, Créateur, Lieu, Stats
- [x] Menu de création par squad
- [x] Désactivation si session déjà active

### À faire 🚧
- [ ] Service `UserService` avec `getUser(userId:)` pour charger les créateurs
- [ ] Navigation vers la session active depuis l'alerte
- [ ] Service `SharedMessagingService` pour les messages d'encouragement
- [ ] Vue de messagerie partagée dans `ActiveSessionDetailView`
- [ ] Notifications push quand un message est envoyé
- [ ] Badge "Nouveau message" sur les sessions

---

## 🎯 Exemple d'usage

### Situation : Squad "Marathon Paris 2024"

```
Coureurs :
- Alice (admin)
- Bob
- Charlie
- David

Sessions actives :
1. Alice : Course 10km (🏁 RACE)
2. Bob   : Entraînement fractionné
3. Charlie : Récupération 30 min

Supporteurs :
- Emma (ne court pas, envoie des encouragements)
```

**Actions possibles** :

- ✅ **David** peut rejoindre la Course d'Alice
- ✅ **David** peut rejoindre l'entraînement de Bob
- ✅ **David** peut créer sa propre session
- ❌ **Alice** ne peut pas créer une 2ème session
- ❌ **Bob** ne peut pas créer une Course (celle d'Alice est active)
- ✅ **Emma** peut envoyer des messages visibles par Alice, Bob ET Charlie

---

## 📝 Résumé

| Règle | Description |
|-------|-------------|
| **Création** | Tous les membres peuvent créer |
| **Limite par coureur** | 1 session active par squad |
| **Limite par squad (Course)** | 1 seule Course active |
| **Affichage global** | Toutes les sessions de toutes les squads |
| **Informations** | Squad, Créateur, Lieu, Stats |
| **Messagerie** | Messages partagés entre toutes les sessions |

---

**Date** : 30 décembre 2025  
**Version** : 2.0 - Gestion multi-sessions
