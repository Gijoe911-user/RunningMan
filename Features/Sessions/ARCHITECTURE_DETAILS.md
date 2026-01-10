# 🗺️ Architecture des Nouvelles Fonctionnalités

## 📊 Vue d'Ensemble

```
┌─────────────────────────────────────────────────────────────┐
│                    RUNNINGMAN APP                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ 🏠       │  │ 👥       │  │ 🏃       │  │ 🔔       │   │
│  │ Accueil  │  │ Squads   │  │ Sessions │  │ Messages │   │
│  │          │  │          │  │          │  │  ✨NEW   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Architecture Détaillée

### 1. 🏠 Page d'Accueil (HomeWelcomeView)

```
HomeWelcomeView
├── Nouvel utilisateur (sans squad)
│   ├── Hero Section (icône + titre)
│   ├── Bouton "Comment ça marche ?" → OnboardingView
│   ├── Quick Start Cards
│   │   ├── Créer une Squad
│   │   ├── Planifier une session
│   │   └── Explorer les fonctionnalités
│   └── État vide avec encouragements
│
└── Utilisateur avec squads
    ├── Welcome Header (Bonjour + message)
    ├── Help Card (bouton pour revoir l'onboarding)
    ├── Quick Actions (grille 2x2)
    │   ├── Sessions
    │   ├── Notifications ✨
    │   ├── Squads
    │   └── Profil
    └── Stats récentes (optionnel)
```

---

### 2. 🎓 Onboarding (OnboardingView)

```
OnboardingView
├── Header
│   ├── Bouton fermer (X)
│   ├── Bouton lecture complète 🔊
│   └── Titre + Sous-titre
│
├── TabView (4 étapes)
│   ├── Étape 1: Créer votre Squad
│   │   ├── Icône (person.3.fill)
│   │   ├── Badge "Étape 1"
│   │   ├── Titre
│   │   ├── Description
│   │   ├── Bouton "Lire cette étape" 🔊
│   │   └── Bouton "En savoir plus" ℹ️
│   │
│   ├── Étape 2: Lancer des Sessions
│   │   └── [même structure]
│   │
│   ├── Étape 3: Tracker vos activités
│   │   └── [même structure]
│   │
│   └── Étape 4: Partager avec vos amis
│       └── [même structure]
│
└── Controls (bas)
    ├── Bouton "Précédent" (si > étape 1)
    └── Bouton "Suivant" ou "Commencer"
```

**Fonctionnalités:**
- ✅ Navigation fluide avec TabView
- ✅ Lecture vocale par étape
- ✅ Lecture vocale complète
- ✅ Vue détaillée pour chaque étape
- ✅ Contenu paramétrable
- ✅ Animations et transitions

---

### 3. 🔔 Centre de Notifications (NotificationCenterView)

```
NotificationCenterView
├── Header
│   ├── Titre "Centre de notifications"
│   └── Bouton "+" (créer un message)
│
├── Filter Tabs (horizontal scroll)
│   ├── Tous
│   ├── Non lus (avec badge)
│   ├── Vocaux
│   └── Texte
│
├── Messages List (ScrollView)
│   └── MessageRow (pour chaque message)
│       ├── Avatar de l'expéditeur
│       ├── Nom + timestamp
│       ├── Badge du type (Squad/Session/Direct)
│       ├── Contenu
│       │   ├── Si texte: afficher le texte
│       │   └── Si vocal: player avec waveform
│       └── Badge "Non lu" si applicable
│
└── État vide (si aucun message)
    ├── Icône tray.fill
    ├── "Aucun message"
    └── Encouragement
```

---

### 4. ✉️ Composer un Message (ComposeMessageView)

```
ComposeMessageView
├── Header
│   ├── Titre "Nouveau message"
│   └── Bouton "Annuler"
│
├── Scope Selector
│   ├── ○ Toute ma Squad (person.3.fill)
│   ├── ○ Ma session active (figure.run.circle.fill)
│   └── ○ Un seul participant (person.fill)
│
├── Recipient Selector (conditionnel)
│   ├── Si "Toute ma Squad": Liste des squads
│   ├── Si "Ma session": Auto-sélectionné
│   └── Si "Un seul": Liste des participants
│
├── Message Type Toggle
│   ├── [Texte] [Vocal]
│   └── Toggle bouton style segmented
│
├── Message Input (conditionnel)
│   ├── Si Texte:
│   │   └── TextEditor multi-lignes
│   │
│   └── Si Vocal:
│       ├── État "Prêt": Bouton rond avec micro
│       ├── État "Enregistrement": 
│       │   ├── Cercle rouge pulsant
│       │   ├── Timer (00:00)
│       │   ├── Bouton Annuler
│       │   └── Bouton Terminer
│       └── État "Terminé":
│           ├── Checkmark vert
│           ├── "Message enregistré"
│           └── Bouton "Réenregistrer"
│
└── Bouton "Envoyer"
    └── Désactivé si formulaire invalide
```

---

## 🔄 Flux de Données

### Envoi d'un Message

```
User Action
    ↓
ComposeMessageView
    ↓
VoiceMessageService.sendTextMessage() ou sendVoiceMessage()
    ↓
┌──────────────────────────────────────────┐
│ Si Vocal:                                │
│ 1. Upload audio → Firebase Storage       │
│ 2. Récupérer URL de téléchargement      │
└──────────────────────────────────────────┘
    ↓
Firestore Collection "voiceMessages"
    ↓
Snapshot Listener (destinataires)
    ↓
NotificationCenterView (mise à jour en temps réel)
    ↓
Si tracking actif ET préférences autorisent:
    ↓
VoiceMessageService.autoReadMessageDuringTracking()
    ↓
TextToSpeechService.speak() ou AVAudioPlayer.play()
```

---

### Réception d'un Message

```
Firestore Snapshot
    ↓
VoiceMessageService.processMessagesSnapshot()
    ↓
Filtrage selon recipientType
    ↓
@Published var recentMessages: [VoiceMessage]
@Published var unreadMessages: [VoiceMessage]
    ↓
NotificationCenterView (UI auto-mise à jour)
    ↓
Badge sur TabBar (count des unreadMessages)
```

---

## 🎯 Services et Responsabilités

### TextToSpeechService (TTS)

**Responsabilités:**
- ✅ Convertir texte en parole (AVSpeechSynthesizer)
- ✅ Gérer la file d'attente de lecture
- ✅ Contrôles: play, pause, stop
- ✅ Configuration de la voix (langue, vitesse, pitch)
- ✅ Gestion de la session audio

**Utilisé par:**
- OnboardingView (lire les étapes)
- VoiceMessageService (lire les messages texte)
- HomeWelcomeView (bouton d'aide)

---

### VoiceMessageService

**Responsabilités:**
- ✅ Enregistrement audio (AVAudioRecorder)
- ✅ Lecture audio (AVAudioPlayer)
- ✅ Upload/Download vers Firebase Storage
- ✅ CRUD sur Firestore collection "voiceMessages"
- ✅ Listeners en temps réel
- ✅ Logique de lecture automatique
- ✅ Gestion des préférences utilisateur

**Méthodes principales:**
```swift
// Envoi
func sendTextMessage(text:, recipientType:, recipientId:, ...)
func sendVoiceMessage(audioURL:, duration:, recipientType:, ...)

// Réception
func startListeningForMessages(userId:)
func stopListeningForMessages()

// Enregistrement
func startRecording() async throws -> URL
func stopRecording() -> (url: URL?, duration: TimeInterval)
func cancelRecording()

// Lecture
func playVoiceMessage(_ message:) async throws
func stopPlayback()

// Auto-lecture
func autoReadMessageDuringTracking(_ message:, preferences:)
```

---

## 🔐 Sécurité et Permissions

### Firebase Storage

```javascript
voiceMessages/{messageId}.m4a
↓
Rules: allow read, write if authenticated
```

### Firestore

```javascript
voiceMessages/{messageId}
├── senderId: string (indexé)
├── recipientType: string
├── recipientId: string
├── timestamp: timestamp (indexé)
└── ...

Rules:
- read: if authenticated
- create: if auth.uid == senderId
- update: only isRead/readAt fields
- delete: if auth.uid == senderId
```

### iOS Permissions

```xml
NSMicrophoneUsageDescription
NSAudioSessionUsageDescription
```

---

## 📊 Structure Firestore

```
firestore
├── voiceMessages (collection)
│   ├── {messageId1}
│   │   ├── senderId: "user123"
│   │   ├── senderName: "John Doe"
│   │   ├── recipientType: "all_my_squads"
│   │   ├── recipientId: "squad456"
│   │   ├── messageType: "text"
│   │   ├── textContent: "Salut les gars !"
│   │   ├── audioURL: null
│   │   ├── timestamp: 2026-01-10T10:30:00Z
│   │   ├── isRead: false
│   │   ├── sessionId: "session789"
│   │   └── squadId: "squad456"
│   │
│   └── {messageId2}
│       ├── senderId: "user456"
│       ├── messageType: "voice"
│       ├── audioURL: "gs://bucket/voiceMessages/xyz.m4a"
│       ├── audioDuration: 12.5
│       └── ...
│
├── messageReadStatus (collection)
│   └── {statusId}
│       ├── userId: "user123"
│       ├── messageId: "messageId1"
│       ├── isRead: true
│       ├── readAt: 2026-01-10T10:35:00Z
│       └── autoRead: true
│
└── users (collection)
    └── {userId}
        └── preferences (sub-collection)
            └── messagePreferences
                ├── autoReadDuringTracking: true
                ├── autoReadVoiceMessages: true
                ├── autoReadTextMessages: true
                └── doNotDisturbMode: false
```

---

## 🎨 Thème et Style

### Couleurs Utilisées

```swift
Color.coralAccent      // #FF6B6B - Primaire
Color.pinkAccent       // #FF8FB1 - Secondaire
Color.blueAccent       // #4ECDC4 - Accent
Color.green            // #95E1D3 - Success
Color.darkNavy         // #1A1A2E - Background
```

### Composants Réutilisables

- `QuickStartCard` - Carte d'action rapide
- `QuickActionButton` - Bouton d'action avec icône
- `MessageRow` - Ligne de message dans la liste
- `OnboardingStep` - Modèle d'étape

---

## 📱 Navigation

```
MainTabView
├── Tab 0: HomeWelcomeView
│   ├── → OnboardingView (sheet)
│   └── → Quick Actions
│
├── Tab 1: SquadListView
│
├── Tab 2: SessionsListView
│
├── Tab 3: NotificationCenterView ✨ NEW
│   └── → ComposeMessageView (sheet)
│
└── Tab 4: ProfileView
    └── → NotificationSettingsView (optionnel)
```

---

## 🚀 Performance

### Optimisations

1. **Firestore Listeners**
   - Limités aux dernières 24h
   - Limit(50) messages max
   - Cleanup automatique onDisappear

2. **Audio**
   - Format compressé (MPEG4AAC)
   - Qualité: high (bon compromis)
   - Sample rate: 44.1kHz

3. **TTS**
   - File d'attente pour éviter les conflits
   - Duck autres apps (mode .duckOthers)
   - Annulation automatique si nouvelle lecture

4. **Cache**
   - Messages récents en mémoire
   - Pas de cache audio local (stream direct)

---

## 📈 Métriques Suggérées

```swift
// Analytics à tracker
struct MessageAnalytics {
    let messagesTextSent: Int
    let messagesVoiceSent: Int
    let messagesReceived: Int
    let autoReadCount: Int
    let manualReadCount: Int
    let averageVoiceDuration: TimeInterval
    let doNotDisturbUsage: Int
    let onboardingCompletionRate: Double
}
```

---

## 🔮 Extensions Futures Possibles

1. **Transcription automatique** (Speech Recognition)
   ```swift
   import Speech
   SFSpeechRecognizer().recognitionTask(with: request) { result, error in
       // Auto-transcribe voice messages
   }
   ```

2. **Réactions rapides** aux messages
   ```swift
   struct MessageReaction {
       let emoji: String  // 👍, ❤️, 🔥
       let userId: String
       let timestamp: Date
   }
   ```

3. **Messages programmés**
   ```swift
   struct ScheduledMessage {
       let scheduledFor: Date
       let triggerType: TriggerType  // .time, .distance, .heartRate
   }
   ```

4. **Traduction automatique**
   ```swift
   import NaturalLanguage
   // Détecter langue + traduire
   ```

5. **Voice-to-Voice** (sans passer par texte)
   ```swift
   // Enregistrer → Envoyer → Jouer
   // Sans transcription intermédiaire
   ```

---

## 📝 Notes de Développement

### Conventions

- `🆕` = Nouvelle fonctionnalité
- `✨` = Amélioration
- `🔧` = Correction
- `⚠️` = Attention requise
- `❌` = Obsolète/Déprécié

### Tests

Testez toujours sur **appareil physique** pour :
- Enregistrement microphone
- Lecture audio
- Synthèse vocale (TTS)
- Permissions système

### Debug

Utilisez les catégories de log :
```swift
Logger.log("[VMS] Message", category: .service)  // VoiceMessageService
Logger.log("[TTS] Speech", category: .service)   // TextToSpeech
Logger.log("[ONBOARD] Step 1", category: .ui)    // Onboarding
```

---

## ✅ Checklist Finale

- [ ] Info.plist configuré
- [ ] Firebase Storage configuré
- [ ] Firestore Rules ajoutées
- [ ] MainTabView modifié
- [ ] TrackingManager intégré
- [ ] Tests sur appareil réel
- [ ] Onboarding personnalisé
- [ ] Documentation lue

**Prêt à lancer ! 🚀**
