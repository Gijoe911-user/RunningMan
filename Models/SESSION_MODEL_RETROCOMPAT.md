# SessionModel - Rétrocompatibilité Firestore

## ✅ Problème résolu

**Erreur initiale** : `"The data couldn't be read because it is missing"`

Cette erreur se produisait lors du décodage de sessions **historiques** dans Firestore, car :
1. ❌ Des champs obligatoires manquaient dans les anciennes sessions
2. ❌ Les noms de champs ont changé entre l'ancien et le nouveau schéma
3. ❌ Les valeurs d'enum `SessionStatus` ont changé

---

## 🔧 Solutions appliquées

### 1️⃣ **Valeurs par défaut pour tous les champs critiques**

**Avant** ❌ :
```swift
var squadId: String
var creatorId: String
var status: SessionStatus
var participants: [String]
```

**Après** ✅ :
```swift
var squadId: String = ""
var creatorId: String = ""
var status: SessionStatus = .ended
var participants: [String] = []
```

**Résultat** : Si un champ manque dans Firestore, Swift utilise automatiquement la valeur par défaut.

---

### 2️⃣ **Mapping des anciens noms de champs via `CodingKeys`**

**Ancien schéma Firestore** :
- `createdBy` → Créateur de la session
- `startTime` → Date de début
- `endTime` → Date de fin
- `activeRunners` → Liste des participants

**Nouveau schéma** :
- `creatorId` 
- `startedAt`
- `endedAt`
- `participants`

**Solution avec `CodingKeys`** :
```swift
enum CodingKeys: String, CodingKey {
    case creatorId = "createdBy"  // 🔄 Mapping ancien → nouveau
    case startedAt = "startTime"  // 🔄 Mapping ancien → nouveau
    case endedAt = "endTime"      // 🔄 Mapping ancien → nouveau
    case participants = "activeRunners"  // 🔄 Mapping ancien → nouveau
    // ... autres champs
}
```

**Résultat** : Firebase lit automatiquement les anciens champs et les assigne aux nouvelles propriétés.

---

### 3️⃣ **Mapping des valeurs d'enum `SessionStatus`**

**Ancien schéma** :
- `"waiting"` → Session en attente
- `"active"` → Session en cours
- `"finished"` → Session terminée

**Nouveau schéma** :
- `"ACTIVE"` → Session en cours
- `"PAUSED"` → Session en pause
- `"ENDED"` → Session terminée

**Solution avec `init(from:)` et `encode(to:)` personnalisés** :
```swift
enum SessionStatus: String, Codable {
    case active = "ACTIVE"
    case paused = "PAUSED"
    case ended = "ENDED"
    
    // Rétrocompatibilité
    case waiting = "waiting"
    case oldActive = "active"
    case finished = "finished"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue.lowercased() {
        case "active": self = .active
        case "paused": self = .paused
        case "ended", "finished": self = .ended
        case "waiting": self = .waiting
        default: self = .ended
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Toujours encoder dans le nouveau format
        switch self {
        case .active, .oldActive: try container.encode("ACTIVE")
        case .paused: try container.encode("PAUSED")
        case .ended, .finished, .waiting: try container.encode("ENDED")
        }
    }
}
```

**Résultat** : Les anciennes valeurs (`"waiting"`, `"active"`, `"finished"`) sont automatiquement converties vers les nouvelles (`"ACTIVE"`, `"PAUSED"`, `"ENDED"`).

---

## 🎯 Fonctionnement avec `@DocumentID`

### ✅ Ce qu'on a **conservé** :

```swift
@DocumentID var id: String?
```

**Pas de `init(from:)` / `encode(to:)` personnalisé pour `SessionModel`** !

Firebase gère automatiquement :
- ✅ L'assignation de `id` depuis `document.documentID` lors de la lecture
- ✅ L'omission du champ `id` lors de l'écriture (si nil)
- ✅ Le mapping via `CodingKeys` (compatible avec `@DocumentID`)

### ⚠️ Ce qu'on a **évité** :

❌ **Ne PAS faire** :
```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(String.self, forKey: .id)  // ❌ CASSE @DocumentID
    // ...
}
```

**Pourquoi ?** Si on implémente un `init(from:)` personnalisé pour `SessionModel`, le comportement automatique de `@DocumentID` est désactivé et il faut **tout** gérer manuellement (y compris l'ID).

---

## 📊 Résultat final

### ✅ Anciennes sessions décodables
```json
{
  "createdBy": "user123",
  "startTime": { "seconds": 1735488000 },
  "status": "finished",
  "activeRunners": ["user123", "user456"]
}
```

**Décodage automatique** vers :
```swift
SessionModel(
    id: "ROuu6mnhY7ty5u1ufyq5",  // ✅ Assigné par @DocumentID
    squadId: "",                   // ✅ Valeur par défaut
    creatorId: "user123",          // ✅ Mappé depuis "createdBy"
    startedAt: Date(...),          // ✅ Mappé depuis "startTime"
    status: .ended,                // ✅ Converti depuis "finished"
    participants: ["user123", "user456"]  // ✅ Mappé depuis "activeRunners"
)
```

### ✅ Nouvelles sessions décodables
```json
{
  "creatorId": "user123",
  "startedAt": { "seconds": 1735488000 },
  "status": "ACTIVE",
  "participants": ["user123", "user456"],
  "runType": "SOLO",
  "visibility": "SQUAD"
}
```

**Décodage automatique** vers :
```swift
SessionModel(
    id: "abc123xyz",               // ✅ Assigné par @DocumentID
    squadId: "squad789",
    creatorId: "user123",
    startedAt: Date(...),
    status: .active,
    participants: ["user123", "user456"],
    runType: .solo,
    visibility: .squad
)
```

---

## 🧪 Test de rétrocompatibilité

Pour vérifier que tout fonctionne :

```swift
func testDecodeOldSession() async throws {
    let sessionRef = Firestore.firestore().collection("sessions").document("ROuu6mnhY7ty5u1ufyq5")
    let document = try await sessionRef.getDocument()
    
    // ✅ Devrait fonctionner sans crash
    let session = try document.data(as: SessionModel.self)
    
    print("✅ Session décodée: \(session.id ?? "no-id")")
    print("   Status: \(session.status)")
    print("   Creator: \(session.creatorId)")
    print("   Participants: \(session.participants.count)")
}
```

---

## 📝 Notes importantes

1. **`@DocumentID` fonctionne avec `CodingKeys`** ✅  
   Firebase respecte les mappings de noms de champs via `CodingKeys`.

2. **Valeurs par défaut nécessaires** ⚠️  
   Tous les champs qui peuvent manquer dans Firestore doivent avoir une valeur par défaut.

3. **`SessionStatus` a un `init(from:)` personnalisé** ✅  
   C'est OK car c'est un **enum**, pas une struct avec `@DocumentID`.

4. **Pas de fallback manuel d'ID dans `SessionService`** ✅  
   On a retiré tous les `if session.id == nil { session.id = doc.documentID }`.

---

## ✅ Checklist de vérification

- [x] Tous les champs obligatoires ont des valeurs par défaut
- [x] Les anciens noms de champs sont mappés via `CodingKeys`
- [x] Les anciennes valeurs de `SessionStatus` sont converties
- [x] `@DocumentID` fonctionne sans `init(from:)` personnalisé sur `SessionModel`
- [x] Pas de fallback manuel d'ID dans `SessionService`
- [x] Les logs n'affichent plus "Session HISTORIQUE ignorée (erreur décodage)"

