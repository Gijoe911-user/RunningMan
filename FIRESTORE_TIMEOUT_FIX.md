# 🚨 PROBLÈME : updateData() bloque indéfiniment

## 🔍 Diagnostic

Votre app **bloque** à cette ligne :

```
🔵 Appel updateData...
(puis plus rien pendant plusieurs minutes)
```

Cela signifie que **Firestore ne répond pas**.

---

## 🛠️ Solutions implémentées

### ✅ **Timeout de 10 secondes**

Un timeout a été ajouté pour éviter que l'app reste bloquée :

```swift
try await withTimeout(seconds: 10) {
    try await sessionRef.updateData([...])
}
```

**Maintenant, après 10 secondes max, vous verrez :**
```
⏱️ TIMEOUT: updateData a pris plus de 10 secondes
⚠️ Firestore ne répond pas, réessayez ou vérifiez la connexion
```

---

## 🔧 Causes possibles

### 1️⃣ **Règles Firestore trop restrictives**

Vérifiez vos règles de sécurité Firestore :

#### **Firebase Console → Firestore Database → Règles**

**Règles recommandées pour le développement :**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Sessions: Lecture pour tous, écriture pour les participants
    match /sessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       (request.auth.uid in resource.data.participants ||
                        request.auth.uid == resource.data.creatorId);
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.creatorId;
    }
    
    // Squads: Lecture et écriture pour les membres
    match /squads/{squadId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      request.auth.uid in resource.data.members;
    }
    
    // Règle permissive pour le développement (à retirer en production)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**⚠️ Règle temporaire super permissive (uniquement pour tester) :**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // ⚠️ DANGER : Tout le monde peut tout faire !
    }
  }
}
```

☝️ **Utilisez cette règle UNIQUEMENT pour tester si le problème vient des permissions.**  
**Ne la laissez JAMAIS en production !**

---

### 2️⃣ **Problème de connexion réseau**

#### **Vérifier la connexion Firestore**

Ajoutez ce code temporairement dans `AppDelegate` ou au démarrage :

```swift
import FirebaseFirestore

// Activer les logs détaillés de Firestore
FirebaseConfiguration.shared.setLoggerLevel(.debug)

// Tester la connexion
let db = Firestore.firestore()
Task {
    do {
        let testDoc = try await db.collection("_test").document("ping").getDocument()
        print("✅ Firestore connecté !")
    } catch {
        print("❌ Firestore déconnecté : \(error)")
    }
}
```

---

### 3️⃣ **Offline Persistence activée**

Si vous avez activé la persistance offline, Firestore peut mettre du temps à synchroniser.

**Vérifiez si vous avez ce code quelque part :**

```swift
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
db.settings = settings
```

**Essayez de le désactiver temporairement :**

```swift
let settings = FirestoreSettings()
settings.isPersistenceEnabled = false
db.settings = settings
```

---

### 4️⃣ **Simulateur vs Appareil physique**

Si vous êtes sur **Simulateur** :
- Le réseau peut être instable
- Firebase peut ne pas se connecter correctement

**Essayez sur un appareil physique.**

---

## 🧪 Tests à faire

### **Test 1 : Vérifier les règles Firestore**

1. Allez sur https://console.firebase.google.com
2. Votre projet → **Firestore Database**
3. Onglet **Règles**
4. Remplacez temporairement par :
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
5. Cliquez sur **"Publier"**
6. Relancez l'app et testez le bouton "Terminer"

**Si ça fonctionne** → Le problème venait des règles  
**Si ça ne fonctionne pas** → Passez au test 2

---

### **Test 2 : Vérifier la connexion réseau**

Dans la console Xcode, cherchez :

```
[FirebaseFirestore] Could not reach Cloud Firestore backend
```

**Si vous voyez ce message** → Problème de connexion réseau

**Solutions :**
- Vérifiez que vous êtes connecté à Internet
- Désactivez VPN/proxy si vous en avez un
- Redémarrez le simulateur/appareil
- Essayez sur un appareil physique

---

### **Test 3 : Utiliser l'outil de nettoyage**

Au lieu d'utiliser le bouton "Terminer", utilisez l'outil de nettoyage :

1. **Paramètres** → **🔧 Développement** → **Nettoyage & Debug**
2. Cliquez sur **"Terminer TOUTES les sessions actives"**

Cet outil utilise `SessionCleanupUtility` qui a une logique différente.

---

## 🆘 Solution alternative : Terminer manuellement

Si rien ne fonctionne, terminez la session manuellement depuis Firebase Console :

1. https://console.firebase.google.com
2. Votre projet → **Firestore Database**
3. Collection **`sessions`**
4. Document **`GWi8MJbcp9yqS6wwmNOc`**
5. Éditez le champ **`status`** → Changez `"ACTIVE"` en `"ENDED"`
6. Ajoutez un champ **`endedAt`** → Type : timestamp → Valeur : maintenant
7. Sauvegardez

---

## 📝 Logs attendus après le fix

Après avoir ajouté le timeout, vous verrez :

**Si ça fonctionne :**
```
🔵 Appel updateData...
🔵 updateData terminé
✅ Firestore mis à jour
🔵 Préparation removeSessionFromSquad...
🔵 Appel removeSessionFromSquad...
🔵 removeSessionFromSquad terminé
✅ Session retirée de la squad
✅ Session GWi8MJbcp9yqS6wwmNOc terminée avec succès
```

**Si ça timeout :**
```
🔵 Appel updateData...
⏱️ TIMEOUT: updateData a pris plus de 10 secondes
⚠️ Firestore ne répond pas, réessayez ou vérifiez la connexion
❌ ERROR: invalidSession
```

---

## 🎯 Actions immédiates

1. **Recompilez** l'app (le timeout est maintenant actif)
2. **Vérifiez les règles Firestore** (mettez-les en mode permissif pour tester)
3. **Testez** le bouton "Terminer" → Vous verrez un timeout après 10s
4. **Regardez les logs** → Cherchez les erreurs Firestore
5. **Utilisez l'outil de nettoyage** si le bouton ne fonctionne pas

---

**Bon courage ! 🚀**
