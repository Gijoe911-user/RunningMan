# 🎯 TODO: Étapes d'Activation des Nouvelles Fonctionnalités

## ✅ Ce qui est DÉJÀ fait

1. ✅ **Tous les fichiers créés** (9 nouveaux fichiers)
2. ✅ **MainTabView.swift modifié** avec le nouvel onglet Notifications
3. ✅ **Services implémentés** (TextToSpeech, VoiceMessage)
4. ✅ **Vues créées** (Onboarding, NotificationCenter, HomeWelcome)
5. ✅ **Documentation complète** (INTEGRATION_GUIDE.md, IMPLEMENTATION_SUMMARY.md)

---

## 🔧 Actions Requises (À faire maintenant)

### 1. ⚠️ Ajouter les permissions dans `Info.plist`

**Fichier:** `Info.plist` (à la racine du projet)

Ajoutez ces lignes :

```xml
<key>NSMicrophoneUsageDescription</key>
<string>RunningMan a besoin d'accéder à votre microphone pour enregistrer des messages vocaux à partager avec votre Squad.</string>

<key>NSAudioSessionUsageDescription</key>
<string>RunningMan utilise l'audio pour lire vos messages vocaux et les notifications pendant vos courses.</string>
```

**Comment faire dans Xcode:**
1. Ouvrez `Info.plist` dans Xcode
2. Clic droit → "Add Row"
3. Collez les clés ci-dessus
4. Entrez les descriptions

---

### 2. 🔥 Configurer Firebase Storage

**Console Firebase** → Storage

#### Créer la structure de dossiers:
```
voiceMessages/
  ├── {messageId1}.m4a
  ├── {messageId2}.m4a
  └── ...
```

#### Règles de sécurité Storage:

Allez dans **Storage > Rules** et collez :

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Messages vocaux
    match /voiceMessages/{messageId} {
      // Permettre lecture et écriture aux utilisateurs authentifiés
      allow read, write: if request.auth != null;
    }
  }
}
```

Puis cliquez sur **"Publier"**

---

### 3. 🔥 Configurer Firestore

**Console Firebase** → Firestore Database → Rules

Ajoutez ces règles (en plus des existantes) :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ... vos règles existantes ...
    
    // 🆕 Messages vocaux
    match /voiceMessages/{messageId} {
      // Lecture: utilisateurs authentifiés
      allow read: if request.auth != null;
      
      // Création: seulement si l'expéditeur est l'utilisateur actuel
      allow create: if request.auth != null && 
        request.resource.data.senderId == request.auth.uid;
      
      // Mise à jour: seulement pour marquer comme lu
      allow update: if request.auth != null && 
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['isRead', 'readAt']);
      
      // Suppression: seulement l'expéditeur
      allow delete: if request.auth != null && 
        resource.data.senderId == request.auth.uid;
    }
    
    // 🆕 Statuts de lecture des messages
    match /messageReadStatus/{statusId} {
      // Lecture/écriture: seulement pour l'utilisateur concerné
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // 🆕 Préférences de notification des utilisateurs
    match /users/{userId}/preferences/messagePreferences {
      // Lecture/écriture: seulement pour l'utilisateur
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

Puis cliquez sur **"Publier"**

---

### 4. 🎨 (Optionnel) Remplacer DashboardView par HomeWelcomeView

Si vous voulez utiliser la nouvelle page d'accueil avec onboarding intégré :

**Fichier:** `MainTabView.swift` (déjà modifié ✅)

La ligne suivante a déjà été changée :
```swift
// AVANT:
DashboardView()

// APRÈS:
HomeWelcomeView()  // ✅ Déjà fait !
```

Si vous préférez garder votre DashboardView actuelle, changez simplement cette ligne.

---

### 5. 🏃 Intégrer la lecture automatique pendant le tracking

**Fichier:** `TrackingManager.swift`

Ajoutez ces lignes :

```swift
@MainActor
class TrackingManager: ObservableObject {
    // ... propriétés existantes ...
    
    // 🆕 Ajouter cette ligne
    private let voiceMessageService = VoiceMessageService.shared
    
    func startTracking(for session: SessionModel) async -> Bool {
        // ... code existant ...
        
        // 🆕 Ajouter ces lignes AVANT le return
        if let userId = AuthService.shared.currentUserId {
            voiceMessageService.startListeningForMessages(userId: userId)
            Logger.log("[TRACKING] 📬 Écoute des messages vocaux activée", category: .service)
        }
        
        return true
    }
    
    func stopTracking() async {
        // ... code existant ...
        
        // 🆕 Ajouter ces lignes AVANT la fin
        voiceMessageService.stopListeningForMessages()
        Logger.log("[TRACKING] 📭 Écoute des messages vocaux désactivée", category: .service)
    }
}
```

---

### 6. 👤 (Optionnel) Ajouter les préférences de notification dans le profil

**Fichier:** `ProfileView.swift` ou créer une nouvelle vue `NotificationSettingsView.swift`

Ajoutez une section :

```swift
Section("Notifications pendant la course") {
    Toggle("Lire automatiquement les messages", 
           isOn: $userProfile.messagePreferences.autoReadDuringTracking)
    
    Toggle("Lire les messages vocaux", 
           isOn: $userProfile.messagePreferences.autoReadVoiceMessages)
    
    Toggle("Lire les messages texte", 
           isOn: $userProfile.messagePreferences.autoReadTextMessages)
    
    Toggle("Mode bulle (ne pas déranger)", 
           isOn: $userProfile.messagePreferences.doNotDisturbMode)
        .foregroundColor(.coralAccent)
}
.listRowBackground(Color.darkNavy.opacity(0.3))
```

Et dans votre `UserModel` :

```swift
struct UserModel: Codable {
    // ... champs existants ...
    
    // 🆕 Ajouter cette ligne
    var messagePreferences: MessageReadingPreference = MessageReadingPreference()
}
```

---

## 🧪 Tests à Effectuer

### Test 1: Onboarding
- [ ] Désinstaller l'app
- [ ] Réinstaller et se connecter
- [ ] L'onboarding s'affiche automatiquement
- [ ] Les boutons de lecture audio fonctionnent
- [ ] Navigation entre les étapes fluide

### Test 2: Onglet Notifications
- [ ] L'onglet "Notifications" apparaît dans la TabBar
- [ ] L'icône de cloche est visible
- [ ] Le badge affiche le nombre de messages non lus

### Test 3: Envoyer un message texte
- [ ] Créer/rejoindre une squad
- [ ] Aller dans Notifications → Bouton "+"
- [ ] Sélectionner "Toute ma Squad"
- [ ] Taper un message texte
- [ ] Envoyer
- [ ] Vérifier la réception (autre appareil ou même appareil)

### Test 4: Envoyer un message vocal
- [ ] Notifications → Bouton "+"
- [ ] Basculer sur "Vocal"
- [ ] Appuyer et parler
- [ ] Voir le timer en temps réel
- [ ] Valider l'enregistrement
- [ ] Envoyer
- [ ] Vérifier la lecture

### Test 5: Lecture automatique pendant tracking
- [ ] Lancer une session de tracking
- [ ] Demander à un ami d'envoyer un message à votre session
- [ ] Le message est lu automatiquement
- [ ] Vérifier que le "mode bulle" désactive la lecture

### Test 6: Bouton d'aide dans l'accueil
- [ ] Aller dans l'onglet "Accueil"
- [ ] Cliquer sur le bouton "?" en haut à droite
- [ ] L'onboarding s'affiche
- [ ] Lecture vocale fonctionne

---

## 📋 Checklist Complète

### Configuration
- [ ] Permissions ajoutées dans Info.plist
- [ ] Firebase Storage configuré
- [ ] Firestore Rules mises à jour
- [ ] Fichiers ajoutés au projet Xcode

### Code
- [ ] MainTabView.swift modifié ✅ (déjà fait)
- [ ] TrackingManager.swift modifié (point 5)
- [ ] UserModel.swift modifié (point 6, optionnel)
- [ ] ProfileView.swift modifié (point 6, optionnel)

### Tests
- [ ] Onboarding testé
- [ ] Message texte testé
- [ ] Message vocal testé
- [ ] Lecture automatique testée
- [ ] Filtres testés
- [ ] Mode bulle testé

---

## 🚨 Problèmes Potentiels et Solutions

### Erreur: "Missing microphone permission"
**Solution:** Vérifiez que `NSMicrophoneUsageDescription` est dans Info.plist

### Erreur: "Firebase Storage permission denied"
**Solution:** Vérifiez les règles Storage dans la console Firebase

### Erreur: "Firestore permission denied"
**Solution:** Vérifiez les règles Firestore dans la console Firebase

### Pas de son lors de la lecture vocale
**Solution:** Testez sur un appareil physique (pas simulateur)

### Messages non reçus en temps réel
**Solution:** Vérifiez que `startListeningForMessages()` est appelé

---

## 📞 Aide Supplémentaire

Consultez :
- `INTEGRATION_GUIDE.md` - Guide détaillé
- `IMPLEMENTATION_SUMMARY.md` - Résumé complet
- `BUGFIX_SUMMARY.md` - Corrections précédentes

---

## ✨ Après Activation

Une fois tout configuré, votre app aura :

✅ Page d'accueil avec onboarding interactif
✅ Onglet Notifications avec messages vocaux
✅ Lecture automatique pendant les courses
✅ Mode "bulle" pour ne pas être dérangé
✅ 3 modes de partage (Squad/Session/Individuel)
✅ Interface moderne et fluide

**Temps estimé d'activation:** 20-30 minutes

Bonne chance ! 🚀
