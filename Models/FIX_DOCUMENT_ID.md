# 🚨 Fix critique : ID de session perdu lors du décodage

## 🎯 Problème identifié

**Symptôme :**
```
✅ Session décodée: no-id - status: SCHEDULED
❌❌ ERREUR CRITIQUE : Session ID est NIL
```

**Cause racine :**
Le décodeur custom `init(from decoder:)` contenait `case id` dans `CodingKeys`, ce qui **empêchait** `@DocumentID` de fonctionner correctement.

---

## 🔧 Solution appliquée

### **Modification dans SessionModel.swift**

**AVANT (❌ Incorrect) :**
```swift
private enum CodingKeys: String, CodingKey {
    case id  // ❌ ERREUR : Interfère avec @DocumentID
    case squadId
    case creatorId
    // ...
}
```

**APRÈS (✅ Correct) :**
```swift
/// ⚠️ IMPORTANT : Ne pas inclure 'id' dans les CodingKeys
/// car @DocumentID est géré automatiquement par Firebase
private enum CodingKeys: String, CodingKey {
    // case id  ← ❌ SUPPRIMÉ : @DocumentID gère ça automatiquement
    case squadId
    case creatorId
    // ...
}
```

**Commentaire ajouté dans le décodeur :**
```swift
/// ⚠️ **IMPORTANT : L'ID n'est PAS décodé ici**
/// Firebase gère automatiquement l'injection de l'ID via @DocumentID.
/// Ne JAMAIS décoder manuellement le champ 'id'.
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    // 🔥 Champs strictement requis (crash si absents)
    squadId = try container.decode(String.self, forKey: .squadId)
    creatorId = try container.decode(String.self, forKey: .creatorId)
    
    // ⚠️ @DocumentID injecte automatiquement l'ID - NE PAS décoder manuellement
    // Firebase appellera le setter de @DocumentID après notre init()
    
    // ... reste du décodage
}
```

---

## 📊 Comment fonctionne @DocumentID

### **Flux de décodage Firestore**

```
1. Firebase reçoit le document avec son ID : "7sddczQR4LA7iiZBgW4H"
   ↓
2. Firebase appelle notre init(from decoder:)
   ↓
3. Notre init() décode squadId, creatorId, status, etc.
   ↓
4. Notre init() retourne une SessionModel
   ↓
5. 🎯 Firebase injecte l'ID via @DocumentID APRÈS le init()
   ↓
6. session.id contient maintenant "7sddczQR4LA7iiZBgW4H"
```

### **Pourquoi `case id` dans CodingKeys cassait tout ?**

Quand on déclare `case id` dans `CodingKeys`, le compilateur Swift génère automatiquement un **décodage manuel** pour `id`, ce qui **écrase** le comportement de `@DocumentID`.

**Résultat :**
- Le décodeur cherche un champ `"id"` dans le **document Firestore** (qui n'existe pas)
- `@DocumentID` n'a jamais l'occasion d'injecter l'ID
- `session.id` reste `nil`

**Solution :**
- **Supprimer** `case id` des `CodingKeys`
- Laisser `@DocumentID` faire son travail automatiquement

---

## 🧪 Logs attendus après fix

**AVANT (❌) :**
```
📄 Document trouvé: 7sddczQR4LA7iiZBgW4H
✅ Session décodée: no-id - status: SCHEDULED
❌❌ ERREUR CRITIQUE : Session ID est NIL
```

**APRÈS (✅) :**
```
📄 Document trouvé: 7sddczQR4LA7iiZBgW4H
   🔑 Document ID depuis Firestore: 7sddczQR4LA7iiZBgW4H
✅ Session décodée:
   - ID après décodage: 7sddczQR4LA7iiZBgW4H  ← ✅ ID présent !
   - Document ID: 7sddczQR4LA7iiZBgW4H
   - Status: SCHEDULED
```

---

## 🔍 Logs de diagnostic améliorés

**Ajout dans `SessionService.observeActiveSession()` :**

```swift
if let doc = snapshot?.documents.first {
    print("📄 Document trouvé: \(doc.documentID)")
    print("   🔑 Document ID depuis Firestore: \(doc.documentID)")
    
    do {
        let session = try doc.data(as: SessionModel.self)
        print("✅ Session décodée:")
        print("   - ID après décodage: \(session.id ?? "❌ NIL")")
        print("   - Document ID: \(doc.documentID)")
        print("   - Status: \(session.status.rawValue)")
        
        if session.id == nil {
            print("⚠️⚠️ PROBLÈME : L'ID est NIL après décodage !")
            print("   - Firebase a fourni l'ID: \(doc.documentID)")
            print("   - Mais @DocumentID ne l'a pas capturé")
            print("   - Vérifier SessionModel.CodingKeys")
        }
        
        continuation.yield(session)
    } catch {
        print("⚠️ Session ignorée (erreur décodage)")
        print("   Erreur: \(error.localizedDescription)")
        continuation.yield(nil)
    }
}
```

**Permet de diagnostiquer immédiatement si `@DocumentID` ne fonctionne pas.**

---

## 📋 Checklist de validation

Après ce fix, vérifier que :

- [ ] `SessionModel.CodingKeys` ne contient **PAS** `case id`
- [ ] Le décodeur custom ne décode **PAS** manuellement l'ID
- [ ] L'encodeur custom ne encode **PAS** l'ID (déjà correct)
- [ ] Les logs affichent `ID après décodage: ABC123XYZ` (pas "NIL")

---

## 🧪 Test à effectuer

1. **Supprimer l'app** et la réinstaller (pour éviter le cache)
2. **Créer une nouvelle session**
3. **Vérifier les logs** :
   ```
   ✅ Session créée: 7sddczQR4LA7iiZBgW4H
   📄 Document trouvé: 7sddczQR4LA7iiZBgW4H
   ✅ Session décodée:
      - ID après décodage: 7sddczQR4LA7iiZBgW4H  ← ✅ Doit être présent
   ```
4. **Cliquer sur "Démarrer"**
5. **Vérifier les logs** :
   ```
   [AUDIT-TM-01-DEBUG] 📋 Session reçue:
      - id: 7sddczQR4LA7iiZBgW4H  ← ✅ Doit être présent
   ✅ Validation OK - sessionId: 7sddczQR4LA7iiZBgW4H
   [AUDIT-TM-02] 🚀 Appel SessionService.startMyTracking()...
   ✅✅ startMyTracking() réussi
   ```

---

## 🎯 Séquence complète après fix

```
1. Création de session
   ↓
   Firebase : Crée document "7sddczQR4LA7iiZBgW4H"
   ↓
   SessionService.createSession() retourne SessionModel avec id="7sddczQR4LA7iiZBgW4H"
   ↓
   Session visible dans la liste

2. Listener temps réel détecte la session
   ↓
   Firebase envoie snapshot avec document.documentID = "7sddczQR4LA7iiZBgW4H"
   ↓
   SessionModel décodé avec init(from decoder:)
   ↓
   @DocumentID injecte automatiquement l'ID
   ↓
   session.id = "7sddczQR4LA7iiZBgW4H" ✅

3. Utilisateur clique sur "Démarrer"
   ↓
   TrackingManager.startTracking(for: session)
   ↓
   session.id != nil ✅
   ↓
   SessionService.startMyTracking(sessionId: "7sddczQR4LA7iiZBgW4H")
   ↓
   Session passe en ACTIVE
   ↓
   GPS démarre ✅
```

---

## 💡 Leçon apprise

**Règle d'or pour @DocumentID :**

> Quand on utilise `@DocumentID` avec un décodeur custom, **NE JAMAIS** inclure le champ `id` dans les `CodingKeys`. Firebase gère automatiquement l'injection de l'ID après le `init()`.

**Pattern recommandé :**

```swift
struct MyModel: Codable {
    @DocumentID var id: String?
    var name: String
    var value: Int
    
    // ✅ CORRECT : 'id' absent des CodingKeys
    private enum CodingKeys: String, CodingKey {
        case name
        case value
        // case id ← ❌ NE PAS AJOUTER
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Décoder UNIQUEMENT les champs dans CodingKeys
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(Int.self, forKey: .value)
        
        // ⚠️ NE PAS décoder 'id'
        // @DocumentID le fera automatiquement après
    }
}
```

---

## ✅ Résultat attendu

Après ce fix :

1. ✅ **Session décodée avec ID valide**
2. ✅ **Bouton "Démarrer" fonctionne**
3. ✅ **GPS démarre correctement**
4. ✅ **Points GPS publiés dans Firestore**

---

**🎉 Fix appliqué ! Le décodage de l'ID devrait maintenant fonctionner correctement.**
