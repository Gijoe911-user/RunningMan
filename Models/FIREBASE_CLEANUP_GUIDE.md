# 🧹 Guide de Nettoyage Firestore - Structure SessionModel

## 🎯 Objectif

Nettoyer la base de données Firestore pour correspondre **exactement** à la nouvelle structure `SessionModel` propre et simple.

---

## ✅ Structure Firestore FINALE (après nettoyage)

### Collection : `sessions`

```json
{
  // 🔑 ID automatique (géré par @DocumentID)
  "squadId": "abc123",
  "creatorId": "user456",
  "startedAt": { "seconds": 1735488000, "nanoseconds": 0 },
  "endedAt": { "seconds": 1735491600, "nanoseconds": 0 },  // null si en cours
  "status": "ACTIVE",  // ou "PAUSED" ou "ENDED"
  "participants": ["user456", "user789"],
  
  // Statistiques
  "totalDistanceMeters": 5000.0,
  "durationSeconds": 3600.0,
  "averageSpeed": 2.5,
  "startLocation": {
    "latitude": 48.8566,
    "longitude": 2.3522
  },
  "messageCount": 10,
  
  // Optionnels
  "targetDistanceMeters": 10000.0,
  "title": "Course du matin",
  "notes": "Belle journée",
  "activityType": "TRAINING",  // "TRAINING", "RACE", "INTERVAL", "RECOVERY"
  
  // Nouveaux champs (Refonte Incrément 3)
  "runType": "SOLO",  // "SOLO" ou "GROUP"
  "visibility": "SQUAD",  // "PRIVATE" ou "SQUAD"
  "isJoinable": true,
  "maxParticipants": 10,
  
  "createdAt": { "seconds": 1735488000, "nanoseconds": 0 },
  "updatedAt": { "seconds": 1735491600, "nanoseconds": 0 }
}
```

---

## 🔥 Étapes de Nettoyage

### Option 1 : Nettoyer via Console Firebase (Recommandé pour tests)

#### 1️⃣ **Supprimer TOUTES les anciennes sessions**

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet **RunningMan**
3. Aller dans **Firestore Database**
4. Sélectionner la collection **`sessions`**
5. **Supprimer tous les documents** (bouton "Delete" sur chaque document)

> ⚠️ **ATTENTION** : Cela supprimera toutes vos sessions de test !

#### 2️⃣ **Vérifier les index**

1. Aller dans l'onglet **Indexes** de Firestore
2. Vérifier que ces index existent :

```
Collection: sessions
- squadId (Ascending), status (Ascending), startedAt (Descending)
- status (Ascending), startedAt (Descending)
```

Si manquants, ils seront créés automatiquement lors de la première requête.

---

### Option 2 : Script de Migration (Si vous voulez garder les données)

Si vous avez des données précieuses à conserver, voici un script de migration :

```swift
import FirebaseFirestore

func migrateOldSessions() async throws {
    let db = Firestore.firestore()
    
    // 1. Récupérer toutes les anciennes sessions
    let snapshot = try await db.collection("sessions").getDocuments()
    
    print("🔍 Trouvé \(snapshot.documents.count) sessions à migrer")
    
    for doc in snapshot.documents {
        let data = doc.data()
        
        // 2. Construire les nouvelles données
        var newData: [String: Any] = [:]
        
        // Mapping des champs obligatoires
        newData["squadId"] = data["squadId"] as? String ?? ""
        newData["creatorId"] = data["createdBy"] as? String ?? data["creatorId"] as? String ?? ""
        
        if let startTime = data["startTime"] as? Timestamp {
            newData["startedAt"] = startTime
        } else if let startedAt = data["startedAt"] as? Timestamp {
            newData["startedAt"] = startedAt
        } else {
            newData["startedAt"] = Timestamp(date: Date())
        }
        
        if let endTime = data["endTime"] as? Timestamp {
            newData["endedAt"] = endTime
        } else if let endedAt = data["endedAt"] as? Timestamp {
            newData["endedAt"] = endedAt
        }
        
        // Mapper le status
        if let oldStatus = data["status"] as? String {
            switch oldStatus.lowercased() {
            case "active":
                newData["status"] = "ACTIVE"
            case "paused":
                newData["status"] = "PAUSED"
            case "ended", "finished":
                newData["status"] = "ENDED"
            case "waiting":
                newData["status"] = "ENDED"
            default:
                newData["status"] = "ENDED"
            }
        } else {
            newData["status"] = "ENDED"
        }
        
        // Mapper les participants
        if let activeRunners = data["activeRunners"] as? [String] {
            newData["participants"] = activeRunners
        } else if let participants = data["participants"] as? [String] {
            newData["participants"] = participants
        } else {
            newData["participants"] = []
        }
        
        // Statistiques avec valeurs par défaut
        newData["totalDistanceMeters"] = data["totalDistanceMeters"] as? Double ?? 0
        newData["durationSeconds"] = data["durationSeconds"] as? Double ?? 0
        newData["averageSpeed"] = data["averageSpeed"] as? Double ?? 0
        newData["messageCount"] = data["messageCount"] as? Int ?? 0
        
        if let startLocation = data["startLocation"] as? GeoPoint {
            newData["startLocation"] = startLocation
        }
        
        // Champs optionnels
        newData["targetDistanceMeters"] = data["targetDistanceMeters"] as? Double
        newData["title"] = data["title"] as? String ?? data["name"] as? String
        newData["notes"] = data["notes"] as? String
        newData["activityType"] = data["activityType"] as? String ?? "TRAINING"
        
        // Nouveaux champs
        newData["runType"] = data["runType"] as? String ?? "SOLO"
        newData["visibility"] = data["visibility"] as? String ?? "SQUAD"
        newData["isJoinable"] = data["isJoinable"] as? Bool ?? true
        
        if let createdAt = data["createdAt"] as? Timestamp {
            newData["createdAt"] = createdAt
        } else {
            newData["createdAt"] = Timestamp(date: Date())
        }
        
        newData["updatedAt"] = Timestamp(date: Date())
        
        // 3. Remplacer le document
        try await doc.reference.setData(newData)
        print("✅ Session \(doc.documentID) migrée")
    }
    
    print("🎉 Migration terminée !")
}
```

**Pour exécuter ce script** :
1. Créez un fichier temporaire `MigrationHelper.swift`
2. Copiez le code ci-dessus
3. Appelez `try await migrateOldSessions()` depuis un bouton de test dans votre app
4. Supprimez le fichier après migration

---

### Option 3 : Commencer à zéro (RECOMMANDÉ pour tests)

**C'est l'option la plus simple et la plus propre :**

1. **Supprimer toutes les sessions** dans Firebase Console
2. **Lancer votre app**
3. **Créer une nouvelle session** depuis l'app
4. **Vérifier dans Firebase** que la structure est correcte

---

## 📊 Vérification après Nettoyage

### 1. Structure Firestore

Vérifiez qu'une session créée depuis l'app ressemble à ça :

```json
{
  "squadId": "abc123",
  "creatorId": "user456",
  "startedAt": { "seconds": ... },
  "status": "ACTIVE",
  "participants": ["user456"],
  "totalDistanceMeters": 0,
  "durationSeconds": 0,
  "averageSpeed": 0,
  "messageCount": 0,
  "activityType": "TRAINING",
  "runType": "SOLO",
  "visibility": "SQUAD",
  "isJoinable": true,
  "createdAt": { "seconds": ... },
  "updatedAt": { "seconds": ... }
}
```

**⚠️ ATTENTION : Le champ `id` ne doit PAS apparaître dans Firestore !**  
L'ID est géré automatiquement par `@DocumentID` et correspond au `documentID` de Firestore.

### 2. Test dans l'App

```swift
// Test de création
func testCreateSession() async throws {
    let session = try await SessionService.shared.createSession(
        squadId: "test-squad",
        creatorId: AuthService.shared.currentUser?.uid ?? ""
    )
    
    print("✅ Session créée avec ID: \(session.id ?? "nil")")
    print("   Status: \(session.status.rawValue)")
    print("   SquadId: \(session.squadId)")
}

// Test de récupération
func testGetActiveSession() async throws {
    let session = try await SessionService.shared.getActiveSession(squadId: "test-squad")
    
    print("✅ Session récupérée: \(session?.id ?? "nil")")
    print("   Status: \(session?.status.rawValue ?? "none")")
}
```

---

## 🎯 Checklist Finale

- [ ] Anciennes sessions supprimées de Firestore
- [ ] Nouvelle session créée depuis l'app sans erreur
- [ ] Session visible dans Firebase Console avec la bonne structure
- [ ] Champ `id` absent de Firestore (uniquement `documentID`)
- [ ] Session récupérable via `getActiveSession()`
- [ ] Session visible sur la carte
- [ ] Session visible dans la vue Squad
- [ ] Listeners temps réel fonctionnent (mise à jour automatique)

---

## 🆘 En cas de problème

### Session non visible dans l'app

1. Vérifier les logs : `Logger.log` dans `SessionService`
2. Vérifier la structure Firestore (nom des champs)
3. Vérifier le `squadId` (doit correspondre)
4. Vérifier le `status` (doit être "ACTIVE" ou "PAUSED")

### Erreur de décodage

```
Session ignorée (erreur décodage): The data couldn't be read...
```

**Cause** : Un champ obligatoire manque dans Firestore.

**Solution** : Supprimer cette session et en créer une nouvelle depuis l'app.

### @DocumentID ne fonctionne pas

**Symptôme** : `session.id` est toujours `nil`.

**Cause** : Vous avez un `init(from:)` / `encode(to:)` personnalisé qui casse `@DocumentID`.

**Solution** : Vérifier que `SessionModel` n'a **PAS** de `CodingKeys`, `init(from:)`, ni `encode(to:)` personnalisé.

---

## 📝 Notes Importantes

1. **@DocumentID** fonctionne automatiquement si vous ne touchez PAS à Codable
2. Les champs optionnels (`Date?`, `String?`, etc.) peuvent être absents dans Firestore
3. Les champs non-optionnels doivent TOUJOURS être présents (ou avoir une valeur par défaut)
4. Le `status` doit être en MAJUSCULES : "ACTIVE", "PAUSED", "ENDED"
5. Les dates sont stockées comme `Timestamp` dans Firestore

---

## ✅ Prêt pour la Production

Une fois le nettoyage terminé et tout testé :

1. **Désactiver** le script de migration (si utilisé)
2. **Tester** la création de plusieurs sessions
3. **Tester** les listeners temps réel
4. **Vérifier** la performance (pas de lag)
5. **Documenter** la structure finale

Bonne chance ! 🚀
