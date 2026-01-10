# 🚀 Quick Start - 5 Minutes

## ✅ Ce qui est déjà fait

1. ✅ **9 nouveaux fichiers créés**
2. ✅ **MainTabView.swift modifié** (onglet Notifications ajouté)
3. ✅ **Services complets** (TTS + VoiceMessage)
4. ✅ **Interface complète** (Onboarding + Notifications)

---

## ⚡ Actions Rapides (20 min)

### 1️⃣ Info.plist (2 min)

Ouvrez `Info.plist` et ajoutez :

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Pour enregistrer des messages vocaux</string>

<key>NSAudioSessionUsageDescription</key>
<string>Pour lire les messages vocaux</string>
```

### 2️⃣ Firebase Storage (5 min)

Console Firebase → Storage → Rules :

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /voiceMessages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Cliquez **"Publier"**

### 3️⃣ Firestore Rules (5 min)

Console Firebase → Firestore → Rules :

Ajoutez à la fin de vos rules :

```javascript
match /voiceMessages/{messageId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && 
    request.resource.data.senderId == request.auth.uid;
  allow update: if request.auth != null;
}

match /messageReadStatus/{statusId} {
  allow read, write: if request.auth != null;
}
```

Cliquez **"Publier"**

### 4️⃣ TrackingManager.swift (5 min)

Ajoutez cette ligne en haut de la classe :

```swift
private let voiceMessageService = VoiceMessageService.shared
```

Dans `startTracking()`, ajoutez avant le `return true` :

```swift
if let userId = AuthService.shared.currentUserId {
    voiceMessageService.startListeningForMessages(userId: userId)
}
```

Dans `stopTracking()`, ajoutez à la fin :

```swift
voiceMessageService.stopListeningForMessages()
```

### 5️⃣ Build & Test (3 min)

1. ⌘B pour compiler
2. Lancez sur un appareil PHYSIQUE (pas simulateur)
3. Testez :
   - Onglet Accueil → Bouton "?" → Onboarding avec audio
   - Onglet Notifications → Créer un message
   - Envoyer un message texte/vocal

---

## 🎯 Résultat

✅ Page d'accueil avec onboarding interactif  
✅ Centre de notifications avec messages vocaux  
✅ Lecture automatique pendant les courses  
✅ 3 modes de partage (Squad/Session/Individuel)  

---

## 📚 Documentation Complète

- `TODO_ACTIVATION.md` - Checklist détaillée
- `INTEGRATION_GUIDE.md` - Guide complet
- `ARCHITECTURE_DETAILS.md` - Architecture technique
- `IMPLEMENTATION_SUMMARY.md` - Résumé des fonctionnalités

---

## ❓ Problèmes ?

### Pas de son ?
→ Testez sur appareil physique (pas simulateur)

### Permission denied ?
→ Vérifiez Info.plist et Firebase Rules

### Compilation error ?
→ Vérifiez que tous les fichiers sont ajoutés au target Xcode

---

**C'est tout ! 🎉**

L'app est prête avec onboarding vocal et notifications.
