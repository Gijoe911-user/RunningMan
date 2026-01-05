# 🔧 Diagnostic et Solutions - Problèmes de Tracking

## 🔴 Problèmes identifiés dans les logs

### 1. **Erreurs de décodage Firestore** (CRITIQUE)

**Symptôme** :
```
⚠️ Session DRA54t3tx8ieCwrwzMCF ignorée (erreur décodage)
   Erreur: The data couldn't be read because it is missing.
```

**Cause** : Structure `SessionModel` incompatible avec les données Firestore.

**Solution** : Vérifier que TOUS les champs requis de `SessionModel` sont présents dans Firestore lors de la création.

#### Action immédiate :

1. **Nettoyer Firestore** : Supprimer toutes les sessions corrompues
2. **Vérifier SessionModel** : S'assurer que tous les champs ont des valeurs par défaut

```swift
// Dans SessionService.shared.createSession()
// Ajouter explicitement TOUS les champs requis :

let sessionData: [String: Any] = [
    "squadId": squadId,
    "creatorId": creatorId,
    "startedAt": Timestamp(date: Date()),
    "status": "SCHEDULED",
    "participants": [creatorId],
    "activityType": "TRAINING",
    
    // 🔥 CHAMPS MANQUANTS PROBABLES :
    "title": "Session du \(formattedDate)", // ⚠️ Peut-être requis
    "targetDistanceMeters": nil as Int?, // ⚠️ Doit être explicite
    "targetDurationSeconds": nil as Int?, // ⚠️ Doit être explicite
    "endedAt": nil as Timestamp?, // ⚠️ Doit être explicite
    "distanceMeters": 0, // ⚠️ Initialiser à 0
    "durationSeconds": 0, // ⚠️ Initialiser à 0
    "totalCalories": 0, // ⚠️ Initialiser à 0
    "averageHeartRate": nil as Double?, // ⚠️ Doit être explicite
    "maxHeartRate": nil as Double?, // ⚠️ Doit être explicite
]
```

---

### 2. **Statut Firestore vs Tracking Local désynchronisé**

**Symptôme** :
```
trackingState: En cours
firestoreStatus: SCHEDULED  ← ❌ Devrait être ACTIVE
```

**Cause** : Le passage de `SCHEDULED` → `ACTIVE` échoue silencieusement.

**Solution** : S'assurer que `SessionService.activateSession()` fonctionne.

#### Vérification :

```swift
// Dans TrackingManager.startTracking()
// Après avoir démarré le tracking local :

do {
    try await SessionService.shared.updateSessionStatus(
        sessionId: session.id!,
        status: .active
    )
    Logger.logSuccess("✅ ✅ Session activée dans Firebase (SCHEDULED → ACTIVE)")
} catch {
    Logger.logError(error, context: "updateSessionStatus", category: .session)
    // ⚠️ Si ça échoue, le tracking local continue mais Firestore reste SCHEDULED
}
```

---

### 3. **Position GPS non publiée dans Firestore**

**Symptôme** :
```
[AUDIT-LIVE-05] ⚠️ Pas de publication Firestore (session: nil, userId: ..., coord: true)
```

**Cause** : `RealtimeLocationService` ne trouve pas la session active car elle est corrompue dans Firestore.

**Solution** : Fix du problème #1 (décodage) résoudra automatiquement celui-ci.

---

### 4. **Bouton "Terminer" absent pour les non-créateurs**

**Symptôme** :
```
canEndSession = false (isCreator: false)
```

**Comportement actuel** : Seul le créateur peut terminer la session.

**Solution (optionnelle)** : Permettre aux participants de quitter leur propre tracking sans terminer la session pour tous.

#### Nouvelle logique à implémenter :

```swift
// Dans SessionDetailView

// Bouton "Quitter" pour les participants
if !isCreator && isTrackingThisSession {
    Button("Quitter mon tracking") {
        quitMyTracking()
    }
}

// Bouton "Terminer pour tous" pour le créateur
if isCreator && canEndSession {
    Button("Terminer la session") {
        endSession()
    }
}

// Fonction pour quitter sans terminer pour tous
private func quitMyTracking() {
    Task {
        // Arrêter le tracking local
        try? await trackingManager.stopTracking()
        
        // Retirer de la liste des participants (optionnel)
        // OU marquer comme "inactif" dans Firestore
    }
}
```

---

### 5. **Sessions corrompues supprimées automatiquement**

**Symptôme** :
```
⚠️ Session corrompue, suppression en arrière-plan
```

**Cause** : Mécanisme de nettoyage qui détecte les sessions invalides.

**Impact** : Les utilisateurs perdent leurs données de tracking !

**Solution** : 
1. Fix du problème #1 pour éviter les corruptions
2. Améliorer la gestion d'erreurs pour NE PAS supprimer les sessions

---

## 🎯 Plan d'action prioritaire

### Étape 1 : Nettoyer Firestore (MAINTENANT)

1. Aller dans la console Firebase
2. Ouvrir la collection `sessions`
3. Supprimer toutes les sessions avec `status: SCHEDULED` ou `ACTIVE`
4. Redémarrer l'app

### Étape 2 : Corriger SessionModel/SessionService

**Fichier à vérifier** : `SessionService.swift` → fonction `createSession()`

S'assurer que TOUS les champs sont initialisés :

```swift
// Champs REQUIS (non-optionnels) dans SessionModel :
squadId: String
creatorId: String
startedAt: Date
status: SessionStatus
participants: [String]
activityType: ActivityType

// Champs OPTIONNELS mais doivent être explicites :
title: String? = nil
endedAt: Date? = nil
targetDistanceMeters: Double? = nil
targetDurationSeconds: Int? = nil
distanceMeters: Double = 0
durationSeconds: Int = 0
totalCalories: Double = 0
averageHeartRate: Double? = nil
maxHeartRate: Double? = nil
averageSpeed: Double? = nil
maxSpeed: Double? = nil
elevationGain: Double? = nil
```

### Étape 3 : Vérifier le passage SCHEDULED → ACTIVE

**Fichier** : `TrackingManager.swift`

Dans `startTracking()`, ajouter un log AVANT et APRÈS l'appel à `updateSessionStatus` :

```swift
Logger.log("[DEBUG] Tentative passage SCHEDULED → ACTIVE pour session \(sessionId)")
try await SessionService.shared.updateSessionStatus(sessionId: sessionId, status: .active)
Logger.logSuccess("[DEBUG] ✅ Session passée en ACTIVE")
```

Si le 2e log n'apparaît jamais → il y a une erreur silencieuse.

### Étape 4 : Améliorer l'UX pour les participants

Ajouter un bouton "Quitter" pour les participants qui ne sont pas créateurs.

---

## 🧪 Test après corrections

1. **Supprimer toutes les sessions** corrompues dans Firestore
2. **Créer une nouvelle session** depuis l'app
3. **Vérifier les logs** :
   - ✅ `✅ Session décodée: XXX - status: SCHEDULED`
   - ✅ `✅ Session activée dans Firebase (SCHEDULED → ACTIVE)`
   - ✅ `✅ Position publiée dans Firestore`
4. **Vérifier Firestore** :
   - Le champ `status` doit être `"ACTIVE"`
   - Tous les champs doivent être présents
5. **Tester Pause/Reprise/Stop** :
   - Les boutons doivent être visibles
   - Les actions doivent fonctionner

---

## 📋 Checklist de vérification

- [ ] Toutes les sessions corrompues supprimées de Firestore
- [ ] `SessionModel` a des valeurs par défaut pour tous les champs optionnels
- [ ] `createSession()` initialise TOUS les champs explicitement
- [ ] Le passage `SCHEDULED → ACTIVE` réussit et est logué
- [ ] Les positions GPS sont publiées dans Firestore
- [ ] Les boutons Play/Pause/Stop sont visibles sur la carte
- [ ] Les participants non-créateurs ont un bouton "Quitter"
- [ ] Le créateur a un bouton "Terminer"

---

## 🚨 Si le problème persiste

1. **Activer le mode debug Firestore** :
   - Ajouter `FirebaseConfiguration.shared.setLoggerLevel(.debug)` dans `AppDelegate`
   - Relancer l'app et chercher les erreurs Firestore dans les logs

2. **Comparer la structure Firestore avec SessionModel** :
   - Ouvrir la console Firebase
   - Copier les champs d'une session corrompue
   - Comparer avec la définition de `SessionModel.swift`
   - Identifier les champs manquants ou mal typés

3. **Créer une session de test manuellement** :
   - Dans la console Firebase
   - Avec TOUS les champs requis
   - Voir si elle se charge correctement

---

## 💡 Amélioration future : Migration Firestore

Si le modèle a changé, ajouter une migration :

```swift
// Dans SessionService
func migrateSession(_ sessionId: String) async throws {
    let ref = db.collection("sessions").document(sessionId)
    
    // Ajouter les champs manquants avec des valeurs par défaut
    try await ref.updateData([
        "distanceMeters": 0,
        "durationSeconds": 0,
        "totalCalories": 0,
        "title": "Session migrée",
        // ...
    ])
}
```

---

Voulez-vous que je vous aide à :
1. 🔍 Examiner `SessionService.swift` pour voir comment les sessions sont créées ?
2. 🔍 Vérifier `SessionModel.swift` pour voir les champs requis ?
3. 🛠️ Corriger le code de création de session ?
