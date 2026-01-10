# 🎯 Guide d'Intégration - Onboarding & Notifications

## 📋 Vue d'ensemble

Ce document explique comment intégrer le nouveau système d'onboarding interactif et le centre de notifications vocales dans votre application RunningMan.

---

## 🆕 Nouveaux Fichiers Créés

### 1. **Modèles et Configuration**
- `OnboardingContent.swift` - Contenu paramétrable de l'onboarding
- `VoiceMessageModel.swift` - Modèles pour les messages vocaux/texte

### 2. **Services**
- `TextToSpeechService.swift` - Synthèse vocale (Text-to-Speech)
- `VoiceMessageService.swift` - Gestion des messages vocaux/texte

### 3. **Vues**
- `OnboardingView.swift` - Vue d'onboarding interactive avec audio
- `NotificationCenterView.swift` - Centre de notifications complet
- `HomeWelcomeView.swift` - Page d'accueil avec aide intégrée

---

## 🔧 Étapes d'Intégration

### Étape 1: Ajouter les permissions dans Info.plist

Ajoutez ces clés pour accéder au microphone et aux fonctionnalités audio :

```xml
<key>NSMicrophoneUsageDescription</key>
<string>RunningMan a besoin d'accéder à votre microphone pour enregistrer des messages vocaux à partager avec votre Squad.</string>

<key>NSAudioSessionUsageDescription</key>
<string>RunningMan utilise l'audio pour lire vos messages vocaux et les notifications pendant vos courses.</string>
```

### Étape 2: Créer l'onglet Notifications dans votre TabView

Dans votre fichier principal (ex: `MainTabView.swift` ou `ContentView.swift`), ajoutez :

```swift
TabView {
    // ... vos onglets existants ...
    
    // 🆕 Onglet Notifications
    NotificationCenterView()
        .tabItem {
            Label("Notifications", systemImage: "bell.fill")
        }
        .badge(voiceMessageService.unreadMessages.count)
}
```

### Étape 3: Intégrer l'onboarding dans votre flux d'authentification

Dans votre vue post-authentification :

```swift
import SwiftUI

struct PostAuthenticationView: View {
    @State private var showOnboarding = false
    
    var body: some View {
        HomeWelcomeView()
            .onAppear {
                // Afficher l'onboarding au premier lancement
                let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
                if !hasSeenOnboarding {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOnboarding = true
                    }
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
            }
    }
}
```

### Étape 4: Intégrer la lecture automatique pendant le tracking

Dans `TrackingManager.swift`, ajoutez :

```swift
@MainActor
class TrackingManager: ObservableObject {
    // ... propriétés existantes ...
    
    private let voiceMessageService = VoiceMessageService.shared
    private var messageListenerTask: Task<Void, Never>?
    
    func startTracking(for session: SessionModel) async -> Bool {
        // ... code existant ...
        
        // Démarrer l'écoute des messages
        if let userId = AuthService.shared.currentUserId {
            voiceMessageService.startListeningForMessages(userId: userId)
        }
        
        return true
    }
    
    func stopTracking() async {
        // ... code existant ...
        
        // Arrêter l'écoute des messages
        voiceMessageService.stopListeningForMessages()
    }
}
```

### Étape 5: Ajouter les préférences de notification dans le profil utilisateur

Créez ou modifiez `UserProfileModel.swift` :

```swift
struct UserProfile: Codable {
    // ... champs existants ...
    
    // 🆕 Préférences de messages
    var messagePreferences: MessageReadingPreference = MessageReadingPreference()
}
```

Et créez une section dans votre vue de profil :

```swift
Section("Notifications pendant la course") {
    Toggle("Lire automatiquement les messages", isOn: $profile.messagePreferences.autoReadDuringTracking)
    Toggle("Lire les messages vocaux", isOn: $profile.messagePreferences.autoReadVoiceMessages)
    Toggle("Lire les messages texte", isOn: $profile.messagePreferences.autoReadTextMessages)
    Toggle("Mode bulle (ne pas déranger)", isOn: $profile.messagePreferences.doNotDisturbMode)
}
```

---

## 🎨 Personnalisation

### Modifier le contenu de l'onboarding

Dans `OnboardingContent.swift`, modifiez la configuration :

```swift
static let `default` = OnboardingConfiguration(
    welcomeTitle: "Votre titre personnalisé",
    welcomeSubtitle: "Votre sous-titre",
    steps: [
        OnboardingStep(
            number: 1,
            title: "Votre titre",
            description: "Description courte",
            icon: "person.3.fill",
            color: "coralAccent",
            detailedExplanation: """
            Explication détaillée qui sera lue à voix haute...
            """
        ),
        // ... autres étapes
    ]
)
```

### Personnaliser la voix de synthèse

Dans `TextToSpeechService.swift` :

```swift
func speak(_ text: String, language: String = "fr-FR", rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
    let utterance = AVSpeechUtterance(string: text)
    
    // 🎨 Personnaliser la voix
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = rate  // Ajuster la vitesse (0.0 - 1.0)
    utterance.pitchMultiplier = 1.0  // Ajuster la hauteur
    utterance.volume = 1.0  // Ajuster le volume
    
    synthesizer.speak(utterance)
}
```

---

## 🔥 Structure Firestore Requise

### Collection: `voiceMessages`

```typescript
voiceMessages/{messageId} {
  senderId: string,
  senderName: string,
  recipientType: "all_my_squads" | "all_my_sessions" | "only_one",
  recipientId: string,  // ID de la squad, session ou user
  messageType: "text" | "voice",
  textContent?: string,
  audioURL?: string,
  audioDuration?: number,
  timestamp: timestamp,
  isRead: boolean,
  readAt?: timestamp,
  sessionId?: string,
  squadId?: string
}
```

### Collection: `messageReadStatus`

```typescript
messageReadStatus/{statusId} {
  userId: string,
  messageId: string,
  isRead: boolean,
  readAt: timestamp,
  autoRead: boolean
}
```

### Sous-collection dans `users`

```typescript
users/{userId}/preferences {
  messagePreferences: {
    autoReadDuringTracking: boolean,
    autoReadVoiceMessages: boolean,
    autoReadTextMessages: boolean,
    doNotDisturbMode: boolean
  }
}
```

---

## 📊 Règles de Sécurité Firestore

Ajoutez ces règles dans votre console Firebase :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Messages vocaux
    match /voiceMessages/{messageId} {
      // Lire: si destinataire ou expéditeur
      allow read: if request.auth != null && (
        resource.data.senderId == request.auth.uid ||
        isMessageRecipient(resource.data)
      );
      
      // Créer: authentifié seulement
      allow create: if request.auth != null && 
        request.resource.data.senderId == request.auth.uid;
      
      // Mettre à jour: seulement pour marquer comme lu
      allow update: if request.auth != null && 
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead', 'readAt']);
    }
    
    // Statuts de lecture
    match /messageReadStatus/{statusId} {
      allow read, write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
    
    function isMessageRecipient(message) {
      // TODO: Implémenter la logique selon recipientType
      return true;
    }
  }
}
```

---

## 🧪 Tests

### Test 1: Onboarding au premier lancement
1. Désinstallez l'app
2. Réinstallez et connectez-vous
3. L'onboarding devrait s'afficher automatiquement
4. Testez le bouton de lecture audio
5. Naviguez entre les étapes

### Test 2: Envoi de message texte
1. Créez une squad avec au moins 2 membres
2. Allez dans l'onglet Notifications
3. Composez un message texte
4. Envoyez à "Toute ma Squad"
5. Vérifiez la réception sur l'autre appareil

### Test 3: Envoi de message vocal
1. Composez un nouveau message
2. Basculez sur "Vocal"
3. Enregistrez un message
4. Envoyez
5. Vérifiez la réception et la lecture

### Test 4: Lecture automatique pendant tracking
1. Lancez une session de tracking
2. Demandez à un ami d'envoyer un message à votre session
3. Le message devrait être lu automatiquement
4. Vérifiez les préférences "Mode bulle"

---

## 🚨 Troubleshooting

### Problème: Pas de son lors de la synthèse vocale

**Solution:**
```swift
// Vérifier les permissions audio
let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
try audioSession.setActive(true)
```

### Problème: Erreur lors de l'upload audio

**Solution:**
```swift
// Vérifier les règles Firebase Storage
// Dans la console Firebase > Storage > Rules
service firebase.storage {
  match /b/{bucket}/o {
    match /voiceMessages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Problème: Messages non reçus en temps réel

**Solution:**
```swift
// Vérifier que le listener est bien démarré
func startListeningForMessages(userId: String) {
    stopListeningForMessages()  // Nettoyer l'ancien listener
    
    messagesListener = db.collection("voiceMessages")
        .whereField("timestamp", isGreaterThan: Date().addingTimeInterval(-86400))
        .addSnapshotListener { snapshot, error in
            // ...
        }
}
```

---

## 📈 Métriques à Suivre

1. **Taux d'adoption de l'onboarding**
   - % d'utilisateurs qui terminent l'onboarding
   - Durée moyenne passée sur l'onboarding

2. **Utilisation des messages**
   - Nombre de messages texte vs vocaux
   - Taux de lecture automatique vs manuelle
   - Temps moyen avant lecture

3. **Préférences utilisateur**
   - % d'utilisateurs en "mode bulle"
   - % avec lecture auto activée

---

## 🔮 Améliorations Futures

1. **Transcription automatique** des messages vocaux avec Speech Recognition
2. **Traduction automatique** pour les squads multilingues
3. **Réactions rapides** (👍, ❤️, 🔥) aux messages
4. **Messages programmés** pour encouragement pendant la course
5. **Statistiques d'engagement** pour les expéditeurs

---

## 📞 Support

Pour toute question ou problème :
- Consultez les logs avec `Logger.log(...)`
- Vérifiez les permissions dans Info.plist
- Testez sur un appareil physique (pas uniquement simulateur)

**Note:** Les fonctionnalités vocales fonctionnent mieux sur appareil réel.
