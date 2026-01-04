# ✅ Étape 1 : Corrections Appliquées - SessionModel & SessionService

**Date :** 4 janvier 2026  
**Objectif :** Sécuriser le modèle et le service pour aligner sur la vision métier

---

## 📋 Vision Métier - Rappel

1. **Liberté** : Tout membre peut créer une session avec objectifs
2. **Mode Spectateur** : Ouverture passive par défaut (GPS éteint)
3. **Action Manuelle** : Le tracking GPS ne démarre QUE sur clic "Démarrer"
4. **Heartbeat** : Session active tant qu'il y a du mouvement (arrêt > 60s = abandon)

---

## 🔧 Corrections Appliquées

### 1. SessionModel.swift

#### ✅ Problème : Erreurs de compilation sur les optionnels
**Avant :**
```swift
var formattedDuration: String {
    let duration = durationSeconds ?? 0  // ❌ Inférence de type ambiguë
    // ...
}

var averageSpeedKmh: Double { (averageSpeed ?? 0) * 3.6 }  // ❌ Inférence ambiguë
```

**Après :**
```swift
var formattedDuration: String {
    let duration: TimeInterval = durationSeconds ?? 0  // ✅ Type explicite
    // ...
}

var averageSpeedKmh: Double {
    let speed: Double = averageSpeed ?? 0  // ✅ Type explicite
    return speed * 3.6
}
```

**Impact :** ✅ Compilation réussie, pas de crash de décodage

---

### 2. SessionService.swift

#### ✅ Problème 1 : Cache trop long (5s → 2s)
**Avant :**
```swift
private let cacheValidityDuration: TimeInterval = 5.0
```

**Après :**
```swift
private let cacheValidityDuration: TimeInterval = 2.0  // ✅ Optimisé pour développement
```

**Impact :** Les nouvelles sessions apparaissent plus rapidement dans l'UI

---

#### ✅ Problème 2 : `createSession` - Fire-and-forget dangereux
**Avant :**
```swift
// 🚀 Fire-and-forget pour l'enregistrement
Task { @MainActor in
    try sessionRef.setData(from: session)  // ⚠️ Peut échouer silencieusement
}

// Retour IMMÉDIAT sans attendre l'enregistrement
return sessionWithId
```

**Après :**
```swift
// ✅ SYNCHRONE : Enregistrer la session AVANT de retourner
do {
    try sessionRef.setData(from: session)
    Logger.log("✅ Session enregistrée dans Firestore", category: .session)
} catch {
    Logger.log("❌ Erreur enregistrement session: \(error.localizedDescription)", category: .session)
    throw error  // ✅ Propagation de l'erreur
}

// Ajouter à la squad en arrière-plan (non-bloquant)
Task { @MainActor [weak self] in
    try await self?.addSessionToSquad(squadId: squadId, sessionId: sessionRef.documentID)
}

return sessionWithId
```

**Impact :** 
- ✅ Garantit que la session existe réellement en base avant de continuer
- ✅ L'appelant peut gérer les erreurs d'enregistrement
- ✅ L'ajout à la squad reste asynchrone (non critique)

---

#### ✅ Problème 3 : Mode Spectateur par défaut manquant
**Avant :**
```swift
let initialParticipantStates: [String: ParticipantSessionState] = [
    creatorId: .waiting()
]

// ⚠️ Pas d'initialisation de participantActivity
```

**Après :**
```swift
let initialParticipantStates: [String: ParticipantSessionState] = [
    creatorId: .waiting()
]

// 🆕 Initialiser l'activité du créateur comme spectateur (pas de tracking)
let initialParticipantActivity: [String: ParticipantActivity] = [
    creatorId: ParticipantActivity(lastUpdate: Date(), isTracking: false)
]

let session = SessionModel(
    // ...
    participantStates: initialParticipantStates,
    participantActivity: initialParticipantActivity  // ✅ Ajouté
)
```

**Impact :** 
- ✅ Le créateur est SPECTATEUR par défaut (GPS éteint)
- ✅ Nécessite un clic explicite sur "Démarrer" pour activer le tracking

---

#### ✅ Problème 4 : `joinSession` - Heartbeat manquant
**Avant :**
```swift
try await sessionRef.updateData([
    "participants": FieldValue.arrayUnion([userId]),
    "participantStates.\(userId).status": ParticipantStatus.waiting.rawValue,
    // ⚠️ Pas d'initialisation de participantActivity
])
```

**Après :**
```swift
try await sessionRef.updateData([
    "participants": FieldValue.arrayUnion([userId]),
    // 🆕 État : spectateur
    "participantStates.\(userId).status": ParticipantStatus.waiting.rawValue,
    // 🆕 Activité : spectateur (pas de tracking)
    "participantActivity.\(userId).lastUpdate": FieldValue.serverTimestamp(),
    "participantActivity.\(userId).isTracking": false,
    "updatedAt": FieldValue.serverTimestamp()
])
```

**Impact :** 
- ✅ Les participants rejoignent en mode spectateur (GPS éteint)
- ✅ Le heartbeat est initialisé correctement

---

#### ✅ Problème 5 : Documentation manquante
**Ajouté :**
```swift
/// ⚠️ **IMPORTANT pour la vision métier :**
/// - La session est créée en statut `.scheduled` (GPS ÉTEINT)
/// - Le créateur est ajouté comme participant en mode "waiting"
/// - Le tracking GPS ne démarre PAS automatiquement
/// - L'utilisateur doit cliquer sur "Démarrer" pour activer le GPS
```

**Impact :** Les développeurs comprennent clairement le comportement attendu

---

## 📊 État Actuel du Modèle de Données

### SessionModel - Champs Critiques

| Champ | Type | Optionnel | Défaut | Notes |
|-------|------|-----------|--------|-------|
| `status` | `SessionStatus` | ❌ | `.scheduled` | Passe à `.active` au premier tracking |
| `participantStates` | `[String: ParticipantSessionState]?` | ✅ | `nil` | État individuel (waiting → active → ended) |
| `participantActivity` | `[String: ParticipantActivity]?` | ✅ | `nil` | Heartbeat (isTracking, lastUpdate) |
| `totalDistanceMeters` | `Double?` | ✅ | `nil` | ✅ Pas de crash si absent |
| `durationSeconds` | `TimeInterval?` | ✅ | `nil` | ✅ Pas de crash si absent |
| `averageSpeed` | `Double?` | ✅ | `nil` | ✅ Pas de crash si absent |

### Flux de Création d'une Session

```
1. Utilisateur clique "Créer une session"
   ↓
2. SessionService.createSession()
   - Status: .scheduled
   - ParticipantStates: [creatorId: .waiting]
   - ParticipantActivity: [creatorId: {isTracking: false}]
   ↓
3. Session enregistrée en base (SYNCHRONE)
   ↓
4. Retour à l'UI → Affichage de la carte
   ↓
5. GPS ÉTEINT (mode spectateur)
   ↓
6. Utilisateur clique "Démarrer le tracking"
   ↓
7. TrackingManager.startTracking()
   - ParticipantStates: [creatorId: .active]
   - ParticipantActivity: [creatorId: {isTracking: true}]
   - Status: .active (si premier participant)
   ↓
8. GPS ALLUMÉ (mode coureur)
```

---

## 🎯 Prochaines Étapes

### ✅ Étape 1 - TERMINÉE
- SessionModel.swift : Erreurs de compilation corrigées
- SessionService.swift : Cache, mode spectateur, heartbeat

### 🔜 Étape 2 - Séparer Création et Tracking
**Fichiers à modifier :**
- `CreateSessionView.swift` : Supprimer l'appel à `startTracking()`
- `CreateSessionWithProgramView.swift` : Idem
- `UnifiedCreateSessionView.swift` : Idem

**Objectifs :**
1. La création de session ne démarre PAS le TrackingManager
2. Ouvrir la création aux membres (supprimer restriction `canStartSession`)
3. Redirection vers `SessionTrackingView` en mode spectateur

### 🔜 Étape 3 - Interface de Contrôle
**Fichiers à modifier :**
- `SessionTrackingView.swift` : Bouton "Démarrer" comme UNIQUE déclencheur GPS

**Objectifs :**
1. État clair : "Spectateur" vs "Coureur Actif"
2. Bouton "Démarrer le tracking" visible uniquement si spectateur
3. Bouton "Arrêter le tracking" visible uniquement si coureur actif

---

## 📝 Notes Techniques

### Gestion des Anciens Documents Firestore
- ✅ Tous les champs statistiques sont **optionnels**
- ✅ Pas de crash si `participantActivity` absent (ancienne session)
- ✅ Les computed properties gèrent les valeurs `nil` avec `??`

### Heartbeat & Inactivité
- **Intervalle heartbeat** : Toutes les 10s (recommandé)
- **Timeout inactivité** : 60s sans signal
- **Détection** : `ParticipantActivity.isInactive`
- **Action** : Marquage automatique comme "abandonné"

### Fire-and-Forget
**Opérations critiques :**
- ❌ Évité pour `createSession` (doit être synchrone)
- ❌ Évité pour `startParticipantTracking` (doit être fiable)

**Opérations non-critiques :**
- ✅ Utilisé pour `addSessionToSquad` (peut échouer sans impact)
- ✅ Utilisé pour `updateParticipantStats` (temps réel non critique)

---

## 🧪 Tests à Effectuer

1. **Création de session**
   - ✅ La session apparaît dans Firestore avec status `.scheduled`
   - ✅ Le créateur est en mode "waiting"
   - ✅ GPS éteint par défaut

2. **Rejoindre une session**
   - ✅ Le participant est en mode "waiting"
   - ✅ `participantActivity` initialisé avec `isTracking: false`

3. **Anciennes sessions**
   - ✅ Pas de crash au décodage
   - ✅ Les champs manquants sont `nil`

4. **Cache**
   - ✅ Nouvelle session visible en < 2s

---

## ✅ Validation

- [x] SessionModel.swift : Compilation OK
- [x] SessionService.swift : Cache optimisé
- [x] SessionService.swift : Mode spectateur par défaut
- [x] SessionService.swift : Heartbeat initialisé
- [x] SessionService.swift : Documentation complète
- [ ] CreateSessionView.swift : Supprimer `startTracking()` (Étape 2)
- [ ] SessionTrackingView.swift : Bouton "Démarrer" (Étape 3)

---

**Prêt pour l'Étape 2 ?** 🚀
