# 🚀 Plan d'Action Complet - RunningMan

**Date :** 4 janvier 2026  
**Vision Cible :** Application collaborative de running avec support multi-sessions

---

## 🎯 Vision Métier - Rappel

### Flux Utilisateur Principal

1. **Créer un groupe (Squad)** ✅
   - Invitation de membres
   - Gestion des rôles

2. **Créer un objectif (Session)** ⚠️
   - Entraînement ou course
   - Mode spectateur par défaut (GPS éteint)
   - **Action manuelle** pour démarrer le tracking

3. **Interagir entre membres** ❌
   - Chat de squad
   - Chat de session
   - Messages privés
   - Support / Encouragements

4. **Tracking Live** ⚠️
   - **1 seule session active** en tracking par utilisateur
   - Support illimité (spectateur) dans toutes les sessions de mes squads
   - Partage de position en temps réel

5. **Fin automatique** ⚠️
   - Session termine quand **tous les coureurs inactifs > 2 min**
   - Détection automatique d'abandon

---

## 📊 État Actuel vs Vision Cible

### ✅ Fonctionnalités Complètes

| Fonctionnalité | Détails |
|----------------|---------|
| **Modèle de données** | SessionModel, SquadModel, ParticipantSessionState, ParticipantActivity |
| **Création Squad** | Invitation, rôles, membres |
| **Création Session** | Mode `.scheduled`, heartbeat, états individuels |
| **Cache optimisé** | 2s pour sessions actives |
| **Compilation** | 0 erreur, 0 warning |

### ⚠️ Fonctionnalités Partielles

| Fonctionnalité | État Actuel | Action Requise |
|----------------|-------------|----------------|
| **Mode Spectateur** | GPS éteint à la création ✅ | Vérifier vues de création (Étape 2) |
| **Bouton "Démarrer"** | Pas encore implémenté | Ajouter dans SessionTrackingView (Étape 3) |
| **Timeout inactivité** | 60s au lieu de 120s | Ajuster constante (Étape 4) |
| **Multi-sessions spectateur** | `AllActiveSessionsView` existe ✅ | Tester fonctionnement (Étape 5) |

### ❌ Fonctionnalités Manquantes

| Fonctionnalité | Priorité | Complexité | Étape |
|----------------|----------|------------|-------|
| **Garde-fou tracking unique** | 🔴 HAUTE | Faible | Étape 6 |
| **Chat Squad** | 🟡 MOYENNE | Moyenne | Étape 7 |
| **Chat Session** | 🟡 MOYENNE | Moyenne | Étape 8 |
| **Messages Privés** | 🟢 BASSE | Moyenne | Étape 9 |
| **Support/Encouragements** | 🟡 MOYENNE | Faible | Étape 10 |

---

## 🛠️ Étapes Détaillées

### **Étape 2 : Séparer Création et Tracking** (EN COURS)

**Objectif :** S'assurer que la création de session ne démarre PAS automatiquement le GPS.

#### Fichiers à Vérifier

1. ✅ **CreateSessionView.swift**
   - Statut : Déjà conforme (ligne 402)
   - Commentaire existant : "NE PLUS démarrer le tracking automatiquement"

2. ⏳ **CreateSessionWithProgramView.swift**
   - Action : Rechercher `trackingManager.startTracking()`
   - Action : Rechercher `locationManager.startUpdatingLocation()`
   - Action : Supprimer ces appels si présents

3. ⏳ **UnifiedCreateSessionView.swift**
   - Action : Vérifier si ce fichier existe
   - Action : Même chose que pour CreateSessionWithProgramView

#### Comment Vérifier

```bash
# Dans le terminal
cd /path/to/RunningMan

# Rechercher tous les appels à startTracking
grep -r "startTracking()" --include="*.swift" Features/Sessions/

# Rechercher les vues de création
find . -name "*CreateSession*.swift"
```

#### Tests à Effectuer

1. **Créer une session avec programme**
   - ✅ La session est créée avec status `.scheduled`
   - ✅ Le GPS est éteint
   - ✅ Pas d'appel à `TrackingManager.startTracking()`

2. **Créer une session simple**
   - ✅ Idem

3. **Ouvrir SessionTrackingView**
   - ✅ Carte visible
   - ✅ GPS éteint
   - ✅ Mode spectateur actif

---

### **Étape 3 : Bouton "Démarrer le Tracking"** (PRIORITAIRE)

**Objectif :** Ajouter un bouton explicite pour démarrer le tracking GPS.

#### Fichiers à Modifier

**1. SessionTrackingView.swift**

**Ajouter un bouton conditionnel :**

```swift
// Dans SessionTrackingView.swift
var body: some View {
    ZStack {
        // ... Carte existante
        
        // Overlay : Bouton "Démarrer" si spectateur
        if !isTracking {
            VStack {
                Spacer()
                
                Button {
                    startTracking()
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Démarrer le tracking")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.green, .coralAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
        } else {
            // Bouton "Arrêter" si coureur actif
            VStack {
                Spacer()
                
                Button {
                    stopTracking()
                } label: {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Arrêter le tracking")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
        }
    }
}

// Fonctions d'action
private func startTracking() {
    guard let sessionId = session.id,
          let userId = AuthService.shared.currentUserId else { return }
    
    // Démarrer le TrackingManager
    trackingManager.startTracking()
    
    // Mettre à jour Firestore
    Task {
        try await SessionService.shared.startParticipantTracking(
            sessionId: sessionId,
            userId: userId
        )
    }
    
    isTracking = true
}

private func stopTracking() {
    trackingManager.stopTracking()
    isTracking = false
}
```

#### Tests à Effectuer

1. **Ouvrir une session existante**
   - ✅ Carte visible
   - ✅ Bouton "Démarrer le tracking" affiché
   - ✅ GPS éteint

2. **Cliquer sur "Démarrer"**
   - ✅ GPS démarre
   - ✅ Status passe à `.active`
   - ✅ `ParticipantActivity.isTracking = true`
   - ✅ Bouton devient "Arrêter le tracking"

3. **Cliquer sur "Arrêter"**
   - ✅ GPS s'arrête
   - ✅ Retour en mode spectateur

---

### **Étape 4 : Ajuster le Timeout d'Inactivité** (FACILE)

**Objectif :** Passer de 60s à 120s (2 minutes) comme demandé.

#### Fichiers à Modifier

**1. SessionModel.swift**

```swift
// Ligne ~260 (dans ParticipantActivity)
/// Indique si le participant est considéré comme inactif (> 120s sans signal)
var isInactive: Bool {
    timeSinceLastUpdate > 120  // ✅ Changé de 60 à 120
}
```

**2. Documentation / Commentaires**

Mettre à jour tous les commentaires qui mentionnent "60s" → "120s" ou "2 minutes".

#### Tests à Effectuer

1. **Créer une session et démarrer le tracking**
2. **Fermer l'app (simuler perte de connexion)**
3. **Attendre 2 minutes**
4. **Vérifier que le participant est marqué comme "abandonné"**

---

### **Étape 5 : Tester le Support Multi-Sessions** (TEST)

**Objectif :** Vérifier que le système de spectateur fonctionne correctement.

#### Vue Concernée

**AllActiveSessionsView.swift** (déjà implémenté ✅)

#### Scénarios de Test

**Scénario 1 : Un utilisateur, plusieurs sessions**

1. **Squad A** : Créer une session "Course 10km"
2. **Squad B** : Créer une session "Entraînement fractionné"
3. **Utilisateur** : Membre des deux squads
4. **Test :**
   - ✅ `AllActiveSessionsView` affiche les 2 sessions
   - ✅ Cliquer sur "Course 10km" → Ouvre en spectateur
   - ✅ Démarrer tracking dans "Course 10km"
   - ✅ Retour → Cliquer sur "Entraînement fractionné"
   - ✅ Ouvre en spectateur (GPS ne redémarre pas)

**Scénario 2 : Tracking actif + Support**

1. **Utilisateur A** : Tracking actif dans "Course 10km"
2. **Utilisateur A** : Ouvre `AllActiveSessionsView`
3. **Test :**
   - ✅ "Course 10km" marquée "En cours"
   - ✅ "Entraînement fractionné" marquée "Rejoindre"
   - ✅ Cliquer sur "Entraînement fractionné" → Spectateur uniquement
   - ✅ Pas de bouton "Démarrer tracking" (déjà actif ailleurs)

---

### **Étape 6 : Garde-Fou Tracking Unique** (IMPORTANT)

**Objectif :** Empêcher un utilisateur de tracker dans plusieurs sessions simultanément.

#### Logique Métier

**Règle :** Un utilisateur peut être **spectateur** dans plusieurs sessions, mais **coureur actif** dans **une seule**.

#### Implémentation

**1. Ajouter une vérification dans `startTracking()`**

```swift
// Dans SessionTrackingView.swift
private func startTracking() {
    guard let sessionId = session.id,
          let userId = AuthService.shared.currentUserId else { return }
    
    // 🆕 GARDE-FOU : Vérifier qu'il n'y a pas déjà une session active
    Task {
        // Récupérer toutes les sessions actives de l'utilisateur
        let activeSessions = try await SessionService.shared.getAllActiveSessions(userId: userId)
        
        // Filtrer celles où l'utilisateur est en train de tracker
        let trackingSessions = activeSessions.filter { session in
            session.participantActivity?[userId]?.isTracking == true
        }
        
        if !trackingSessions.isEmpty {
            // L'utilisateur tracke déjà dans une autre session
            errorMessage = "Vous êtes déjà en train de courir dans une autre session. Terminez-la avant d'en commencer une nouvelle."
            showError = true
            return
        }
        
        // OK : Démarrer le tracking
        trackingManager.startTracking()
        
        try await SessionService.shared.startParticipantTracking(
            sessionId: sessionId,
            userId: userId
        )
        
        isTracking = true
    }
}
```

**2. Ajouter des propriétés d'état**

```swift
@State private var errorMessage: String = ""
@State private var showError: Bool = false
```

**3. Ajouter l'alerte**

```swift
.alert("Impossible de démarrer", isPresented: $showError) {
    Button("OK") { showError = false }
} message: {
    Text(errorMessage)
}
```

#### Tests à Effectuer

1. **Utilisateur A** : Démarre tracking dans "Session 1"
2. **Utilisateur A** : Ouvre "Session 2"
3. **Test :**
   - ✅ Bouton "Démarrer le tracking" visible
   - ✅ Cliquer → Alerte "Vous êtes déjà en train de courir..."
   - ✅ Tracking ne démarre pas

---

### **Étape 7 : Chat de Squad** (MOYENNE PRIORITÉ)

**Objectif :** Permettre aux membres d'une squad de communiquer.

#### Modèle de Données

**Créer `MessageModel.swift` :**

```swift
import Foundation
import FirebaseFirestore

struct MessageModel: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var senderPhotoURL: String?
    var content: String
    var type: MessageType
    var timestamp: Date
    var reactions: [String: String]?  // userId: emoji
    
    enum MessageType: String, Codable {
        case text = "TEXT"
        case encouragement = "ENCOURAGEMENT"
        case system = "SYSTEM"
    }
}
```

#### Structure Firestore

```
squads/{squadId}/messages/{messageId}
  - senderId: String
  - senderName: String
  - content: String
  - type: String
  - timestamp: Timestamp
  - reactions: Map<String, String>
```

#### Vue à Créer

**`SquadChatView.swift` :**

```swift
struct SquadChatView: View {
    let squad: SquadModel
    
    @State private var messages: [MessageModel] = []
    @State private var newMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Liste des messages
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Barre de saisie
            HStack {
                TextField("Message...", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.coralAccent)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
        .navigationTitle(squad.name)
        .task {
            await loadMessages()
        }
    }
    
    private func sendMessage() {
        // TODO: Implémenter l'envoi
    }
    
    private func loadMessages() async {
        // TODO: Charger depuis Firestore
    }
}
```

#### Tests à Effectuer

1. **Ouvrir SquadChatView**
   - ✅ Liste des messages affichée
2. **Envoyer un message**
   - ✅ Apparaît immédiatement
   - ✅ Reçu par les autres membres

---

### **Étape 8 : Chat de Session** (MOYENNE PRIORITÉ)

**Objectif :** Permettre aux participants d'une session de communiquer pendant la course.

#### Structure Firestore

```
sessions/{sessionId}/messages/{messageId}
  - senderId: String
  - content: String
  - type: String  // "TEXT", "ENCOURAGEMENT", "SYSTEM"
  - timestamp: Timestamp
```

#### Vue à Intégrer

**Dans `SessionTrackingView.swift` :**

```swift
// Ajouter un bouton de chat
ToolbarItem(placement: .topBarTrailing) {
    Button {
        showChat = true
    } label: {
        Image(systemName: "message.fill")
            .foregroundColor(.white)
    }
}

// Sheet pour le chat
.sheet(isPresented: $showChat) {
    SessionChatView(session: session)
}
```

#### Tests à Effectuer

1. **Pendant une session active**
   - ✅ Bouton chat visible
   - ✅ Cliquer → Sheet s'ouvre
2. **Envoyer un message**
   - ✅ Reçu en temps réel par les autres participants

---

### **Étape 9 : Messages Privés** (BASSE PRIORITÉ)

**Objectif :** Communication directe entre deux utilisateurs.

#### Structure Firestore

```
conversations/{conversationId}/messages/{messageId}
  - senderId: String
  - receiverId: String
  - content: String
  - timestamp: Timestamp
  - isRead: Boolean
```

#### Vue à Créer

**`ConversationListView.swift` :**
- Liste des conversations
- Badge pour messages non lus

**`ConversationView.swift` :**
- Chat 1-to-1

---

### **Étape 10 : Support/Encouragements** (MOYENNE PRIORITÉ)

**Objectif :** Permettre d'envoyer des encouragements rapides.

#### Implémentation

**Boutons d'encouragement prédéfinis :**

```swift
// Dans SessionTrackingView.swift ou SessionChatView.swift
HStack {
    ForEach(Encouragement.allCases, id: \.self) { encouragement in
        Button {
            sendEncouragement(encouragement)
        } label: {
            Text(encouragement.emoji)
                .font(.title)
        }
    }
}

enum Encouragement: String, CaseIterable {
    case fire = "🔥"
    case muscle = "💪"
    case clap = "👏"
    case rocket = "🚀"
    case heart = "❤️"
    
    var message: String {
        switch self {
        case .fire: return "En feu !"
        case .muscle: return "Force !"
        case .clap: return "Bravo !"
        case .rocket: return "Fonce !"
        case .heart: return "Courage !"
        }
    }
}
```

#### Affichage

**Toast notification en overlay sur la carte :**

```swift
if let encouragement = lastEncouragement {
    VStack {
        HStack {
            Text(encouragement.emoji)
                .font(.largeTitle)
            VStack(alignment: .leading) {
                Text(encouragement.senderName)
                    .font(.caption.bold())
                Text(encouragement.message)
                    .font(.caption)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
        Spacer()
    }
    .padding()
    .transition(.move(edge: .top).combined(with: .opacity))
    .animation(.spring(), value: lastEncouragement)
}
```

---

## 📋 Checklist Complète

### Phase 1 : Stabilisation (EN COURS)

- [x] ✅ Compilation sans erreur
- [x] ✅ Modèle de données complet
- [x] ✅ Mode spectateur par défaut
- [x] ✅ Heartbeat système fonctionnel
- [ ] ⏳ **Étape 2 : Vérifier vues de création**
- [ ] ⏳ **Étape 3 : Bouton "Démarrer le tracking"**
- [ ] ⏳ **Étape 4 : Ajuster timeout (120s)**

### Phase 2 : Tracking & Multi-Sessions

- [ ] ⏳ **Étape 5 : Tester support multi-sessions**
- [ ] ⏳ **Étape 6 : Garde-fou tracking unique**

### Phase 3 : Communication

- [ ] ⏳ **Étape 7 : Chat de squad**
- [ ] ⏳ **Étape 8 : Chat de session**
- [ ] ⏳ **Étape 9 : Messages privés**
- [ ] ⏳ **Étape 10 : Support/Encouragements**

### Phase 4 : Améliorations UI/UX

- [ ] ⏳ Notifications push
- [ ] ⏳ Historique de performance
- [ ] ⏳ Classements / Achievements
- [ ] ⏳ Partage social

---

## 🎯 Ordre de Priorité Recommandé

| Ordre | Étape | Priorité | Impact | Effort |
|-------|-------|----------|--------|--------|
| 1 | **Étape 2** | 🔴 Critique | 🔥 Haute | ⏱️ Faible |
| 2 | **Étape 3** | 🔴 Critique | 🔥 Haute | ⏱️ Moyen |
| 3 | **Étape 4** | 🟡 Moyenne | 🔥 Moyenne | ⏱️ Faible |
| 4 | **Étape 6** | 🔴 Critique | 🔥 Haute | ⏱️ Moyen |
| 5 | **Étape 10** | 🟡 Moyenne | 🔥 Haute | ⏱️ Faible |
| 6 | **Étape 7** | 🟡 Moyenne | 🔥 Moyenne | ⏱️ Moyen |
| 7 | **Étape 8** | 🟡 Moyenne | 🔥 Moyenne | ⏱️ Moyen |
| 8 | **Étape 5** | 🟢 Basse | 🔥 Basse | ⏱️ Faible |
| 9 | **Étape 9** | 🟢 Basse | 🔥 Basse | ⏱️ Moyen |

---

## 🚀 Prochaine Action Immédiate

### Commencez par l'Étape 2 !

**Action :**
1. Ouvrir le terminal
2. Chercher tous les fichiers de création de session :
   ```bash
   find . -name "*CreateSession*.swift" -not -path "*/.*"
   ```

3. Pour chaque fichier, chercher les appels à `startTracking` :
   ```bash
   grep -n "startTracking" Features/Sessions/CreateSessionView.swift
   grep -n "startTracking" Features/Sessions/CreateSessionWithProgramView.swift
   ```

4. Supprimer ces appels si présents

5. Tester : Créer une session → GPS doit être éteint ✅

---

**Dites-moi quand vous êtes prêt pour passer à l'Étape 2 ou si vous voulez que je vous aide sur une étape spécifique !** 🚀
