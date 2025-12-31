# 🗄️ Guide de Migration Firestore - Refactorisation v2.0

**Date :** 30 décembre 2024  
**Version :** 2.0  
**Impact :** Modifications de schéma pour gamification et courses planifiées

---

## 📋 Vue d'Ensemble

Cette migration ajoute les fonctionnalités de gamification et de gestion de courses planifiées.

**Collections impactées :**
- ✅ `users` - Ajout de champs gamification
- ✅ `squads` - Ajout de courses planifiées
- ✅ `sessions` - Ajout statut `.archived`

---

## 🔄 Migration 1 : Collection `users`

### Champs Ajoutés

```typescript
{
  // ... champs existants (displayName, email, etc.)
  
  // 🆕 Gamification
  "consistencyRate": 0.0,          // Double (0.0 - 1.0)
  "weeklyGoals": [],               // Array<WeeklyGoal>
  "avatarUrl": null,               // String | null
  "bio": null,                     // String | null
  "totalDistance": 0.0,            // Double (en mètres)
  "totalSessions": 0,              // Number
}
```

### Structure `WeeklyGoal`

```typescript
{
  "id": "uuid",                    // String
  "weekStartDate": Timestamp,      // Timestamp (lundi 00:00:00)
  "targetType": "DISTANCE",        // "DISTANCE" | "DURATION"
  "targetValue": 20000.0,          // Double (mètres ou secondes)
  "actualValue": 5000.0,           // Double
  "isCompleted": false,            // Boolean
  "sessionsContributed": ["sessionId1"], // Array<String>
  "createdAt": Timestamp           // Timestamp
}
```

### Script de Migration (Firebase Admin SDK)

```javascript
// migration-users-v2.js
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

async function migrateUsers() {
  const usersSnapshot = await db.collection('users').get();
  
  const batch = db.batch();
  let count = 0;
  
  usersSnapshot.forEach((doc) => {
    const userRef = db.collection('users').doc(doc.id);
    
    // Ajouter les nouveaux champs avec valeurs par défaut
    batch.update(userRef, {
      consistencyRate: 0.0,
      weeklyGoals: [],
      avatarUrl: null,
      bio: null,
      totalDistance: 0.0,
      totalSessions: 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    count++;
    
    // Commit batch tous les 500 documents
    if (count % 500 === 0) {
      console.log(`✅ ${count} utilisateurs migrés...`);
    }
  });
  
  await batch.commit();
  console.log(`✅✅ Migration terminée : ${count} utilisateurs`);
}

migrateUsers().catch(console.error);
```

---

## 🔄 Migration 2 : Collection `squads`

### Champs Ajoutés

```typescript
{
  // ... champs existants (name, members, etc.)
  
  // 🆕 Courses planifiées
  "plannedRaces": []               // Array<PlannedRace>
}
```

### Structure `PlannedRace`

```typescript
{
  "id": "uuid",                    // String
  "name": "Marathon de Paris 2025", // String
  "scheduledDate": Timestamp,      // Timestamp
  "location": "Champs-Élysées",   // String
  "distance": 42195.0,             // Double | null
  "squadId": "squadId",            // String
  
  // Métadonnées compétition
  "bibNumber": "12345",            // String | null
  "officialTrackingUrl": "https://...", // String | null
  
  // État d'activation
  "isActivated": false,            // Boolean
  "activatedSessionId": null,      // String | null
  "activatedAt": null,             // Timestamp | null
  
  // Metadata
  "createdBy": "userId",           // String
  "createdAt": Timestamp,          // Timestamp
  "updatedAt": Timestamp           // Timestamp
}
```

### Script de Migration

```javascript
// migration-squads-v2.js
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

async function migrateSquads() {
  const squadsSnapshot = await db.collection('squads').get();
  
  const batch = db.batch();
  let count = 0;
  
  squadsSnapshot.forEach((doc) => {
    const squadRef = db.collection('squads').doc(doc.id);
    
    // Ajouter le nouveau champ
    batch.update(squadRef, {
      plannedRaces: [],
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    count++;
  });
  
  await batch.commit();
  console.log(`✅✅ Migration terminée : ${count} squads`);
}

migrateSquads().catch(console.error);
```

---

## 🔄 Migration 3 : Collection `sessions`

### Mise à Jour `SessionStatus`

**Anciennes valeurs :**
- `ACTIVE`
- `PAUSED`
- `ENDED`

**Nouvelle valeur ajoutée :**
- `ARCHIVED` 🆕

### Script de Migration (Optionnel)

```javascript
// migration-sessions-archived.js
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

async function archiveOldSessions() {
  // Archiver les sessions de plus de 30 jours
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  
  const oldSessionsSnapshot = await db.collection('sessions')
    .where('status', '==', 'ENDED')
    .where('endedAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .get();
  
  const batch = db.batch();
  let count = 0;
  
  oldSessionsSnapshot.forEach((doc) => {
    const sessionRef = db.collection('sessions').doc(doc.id);
    
    batch.update(sessionRef, {
      status: 'ARCHIVED',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    count++;
  });
  
  await batch.commit();
  console.log(`✅✅ ${count} sessions archivées`);
}

archiveOldSessions().catch(console.error);
```

---

## 🗂️ Nouvelle Collection : `audio_triggers` (Phase 2)

**⚠️ Création future (Phase 2)**

```typescript
// Collection: audio_triggers
{
  "id": "uuid",                    // Document ID
  "audioUrl": "gs://...",          // Firebase Storage URL
  "durationSeconds": 15.5,         // Double
  
  "fromUserId": "userId",          // String
  "fromUserName": "John Doe",      // String
  "fromUserAvatarUrl": "https://...", // String | null
  
  "triggerType": "DISTANCE_KM",    // "DISTANCE_KM" | "PACE" | "HEART_RATE"
  "triggerValue": 30.0,            // Double
  "comparison": "GREATER_THAN_OR_EQUAL", // Enum
  
  "sessionId": "sessionId",        // String | null
  "squadId": "squadId",            // String | null
  
  "hasBeenTriggered": false,       // Boolean
  "triggeredAt": null,             // Timestamp | null
  "playCount": 0,                  // Number
  
  "createdAt": Timestamp,          // Timestamp
  "expiresAt": null                // Timestamp | null
}
```

### Indexes Requis

```
Collection: audio_triggers
- sessionId (ASC), hasBeenTriggered (ASC), triggerType (ASC)
- squadId (ASC), hasBeenTriggered (ASC), createdAt (DESC)
```

---

## 🗂️ Nouvelle Collection : `music_playlists` (Phase 4)

**⚠️ Création future (Phase 4)**

```typescript
// Collection: music_playlists
{
  "id": "uuid",                    // Document ID
  "name": "Playlist Ultime",       // String
  "description": "Pour les 2 derniers km", // String | null
  
  "spotifyUri": "spotify:playlist:...", // String | null
  "spotifyUrl": "https://...",     // String | null
  "appleMusicId": "1234567",       // String | null
  "appleMusicUrl": "https://...",  // String | null
  
  "triggerPace": 5.0,              // Double | null (min/km)
  "triggerDistance": 40000.0,      // Double | null (mètres)
  "triggerHeartRate": 160.0,       // Double | null (BPM)
  "triggerTimeElapsed": 600.0,     // Double | null (secondes)
  
  "priority": 0,                   // Number
  "isActive": true,                // Boolean
  "isDefault": false,              // Boolean
  
  "createdBy": "userId",           // String
  "createdAt": Timestamp,          // Timestamp
  "updatedAt": Timestamp           // Timestamp
}
```

### Indexes Requis

```
Collection: music_playlists
- createdBy (ASC), isActive (ASC), priority (DESC)
```

---

## 📊 Schéma Firestore Complet (v2.0)

```
Firestore Root
├── users/
│   ├── {userId}/
│   │   ├── displayName: String
│   │   ├── email: String
│   │   ├── consistencyRate: Double       🆕
│   │   ├── weeklyGoals: Array            🆕
│   │   ├── avatarUrl: String?            🆕
│   │   ├── bio: String?                  🆕
│   │   ├── totalDistance: Double         🆕
│   │   ├── totalSessions: Number         🆕
│   │   ├── squads: Array<String>
│   │   ├── createdAt: Timestamp
│   │   └── lastSeen: Timestamp
│
├── squads/
│   ├── {squadId}/
│   │   ├── name: String
│   │   ├── members: Map<userId, role>
│   │   ├── plannedRaces: Array           🆕
│   │   ├── inviteCode: String
│   │   ├── createdBy: String
│   │   └── createdAt: Timestamp
│
├── sessions/
│   ├── {sessionId}/
│   │   ├── squadId: String
│   │   ├── status: String                (+ "ARCHIVED" 🆕)
│   │   ├── creatorId: String
│   │   ├── participants: Array
│   │   ├── participantStats: Map
│   │   ├── startedAt: Timestamp
│   │   ├── endedAt: Timestamp?
│   │   └── ...
│
├── locations/
│   ├── {userId}_{sessionId}/
│   │   ├── sessionId: String
│   │   ├── userId: String
│   │   ├── latitude: Number
│   │   ├── longitude: Number
│   │   ├── timestamp: Timestamp
│   │   └── ...
│
├── routes/
│   ├── {sessionId}/
│   │   └── users/
│   │       └── {userId}/
│   │           ├── points: Array
│   │           └── ...
│
├── audio_triggers/                       🆕 Phase 2
│   └── {triggerId}/
│       ├── audioUrl: String
│       ├── triggerType: String
│       └── ...
│
└── music_playlists/                      🆕 Phase 4
    └── {playlistId}/
        ├── name: String
        ├── spotifyUri: String?
        └── ...
```

---

## 🔐 Security Rules (Mises à Jour)

### `users` Collection

```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
  
  // 🆕 Valider les nouveaux champs
  allow update: if request.auth.uid == userId
    && request.resource.data.consistencyRate >= 0.0
    && request.resource.data.consistencyRate <= 1.0
    && request.resource.data.totalDistance >= 0.0
    && request.resource.data.totalSessions >= 0;
}
```

### `audio_triggers` Collection (Phase 2)

```javascript
match /audio_triggers/{triggerId} {
  // Lecture : Tous les membres de la squad (ou session)
  allow read: if request.auth != null
    && (isSquadMember(request.auth.uid, resource.data.squadId)
        || isSessionParticipant(request.auth.uid, resource.data.sessionId));
  
  // Écriture : Créateur uniquement
  allow create: if request.auth != null
    && request.auth.uid == request.resource.data.fromUserId;
  
  // Mise à jour : Créateur ou système (pour hasBeenTriggered)
  allow update: if request.auth.uid == resource.data.fromUserId
    || (request.auth != null 
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['hasBeenTriggered', 'triggeredAt', 'playCount']));
}
```

---

## 🧪 Tests de Validation

### Test 1 : Migration Users

```bash
# Lancer le script de migration
node migration-users-v2.js

# Vérifier un utilisateur
firebase firestore:get users/{userId}
```

**Résultat attendu :**
```json
{
  "displayName": "John Doe",
  "consistencyRate": 0.0,
  "weeklyGoals": [],
  "avatarUrl": null,
  "bio": null,
  "totalDistance": 0.0,
  "totalSessions": 0
}
```

### Test 2 : Migration Squads

```bash
node migration-squads-v2.js
firebase firestore:get squads/{squadId}
```

**Résultat attendu :**
```json
{
  "name": "Marathon Paris 2024",
  "plannedRaces": []
}
```

### Test 3 : Archivage Sessions

```bash
node migration-sessions-archived.js
```

**Vérifier :**
```bash
firebase firestore:query sessions --where status==ARCHIVED
```

---

## 📝 Checklist de Migration

### Avant la Migration

- [ ] **Backup Firestore** (via Firebase Console → Backups)
- [ ] Vérifier que Firebase Admin SDK est installé (`npm install firebase-admin`)
- [ ] Télécharger la clé de service (`serviceAccountKey.json`)
- [ ] Tester les scripts sur un projet Firebase de test

### Pendant la Migration

- [ ] Exécuter `migration-users-v2.js`
- [ ] Vérifier les logs de réussite
- [ ] Exécuter `migration-squads-v2.js`
- [ ] Exécuter `migration-sessions-archived.js` (optionnel)

### Après la Migration

- [ ] Vérifier 5 documents aléatoires dans chaque collection
- [ ] Tester l'app avec les nouveaux champs
- [ ] Déployer la nouvelle version de l'app
- [ ] Surveiller les logs Firebase pour erreurs

---

## 🚨 Rollback (En cas de Problème)

### Option 1 : Restauration depuis Backup

```bash
# Via Firebase Console
1. Aller dans Firestore → Backups
2. Sélectionner le backup pré-migration
3. Cliquer "Restore"
```

### Option 2 : Suppression Manuelle des Champs

```javascript
// rollback-users.js
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

async function rollbackUsers() {
  const usersSnapshot = await db.collection('users').get();
  
  const batch = db.batch();
  
  usersSnapshot.forEach((doc) => {
    const userRef = db.collection('users').doc(doc.id);
    
    // Supprimer les nouveaux champs
    batch.update(userRef, {
      consistencyRate: admin.firestore.FieldValue.delete(),
      weeklyGoals: admin.firestore.FieldValue.delete(),
      avatarUrl: admin.firestore.FieldValue.delete(),
      bio: admin.firestore.FieldValue.delete(),
      totalDistance: admin.firestore.FieldValue.delete(),
      totalSessions: admin.firestore.FieldValue.delete()
    });
  });
  
  await batch.commit();
  console.log('✅ Rollback terminé');
}

rollbackUsers().catch(console.error);
```

---

## 📅 Planning de Migration

### Phase 1 : Préparation (30 min)
- [x] Créer backup Firestore
- [x] Téster scripts sur projet test
- [x] Valider schémas de données

### Phase 2 : Migration Users (15 min)
- [ ] Exécuter `migration-users-v2.js`
- [ ] Validation manuelle

### Phase 3 : Migration Squads (10 min)
- [ ] Exécuter `migration-squads-v2.js`
- [ ] Validation manuelle

### Phase 4 : Migration Sessions (10 min)
- [ ] Exécuter `migration-sessions-archived.js`
- [ ] Validation manuelle

### Phase 5 : Déploiement App (20 min)
- [ ] Déployer nouvelle version
- [ ] Tests E2E
- [ ] Monitoring production

**Temps total estimé :** ~1h30

---

## 🎯 Impact Utilisateurs

### Downtime Prévu
- ⚠️ **5-10 minutes** pendant la migration (lecture seule)

### Notifications Utilisateurs
```
📢 Maintenance planifiée
Nous effectuons une mise à jour de la base de données 
pour introduire le système de progression.

Durée estimée : 10 minutes
Date : [DATE ET HEURE]

Merci de votre compréhension ! 🏃‍♂️
```

---

**Dernière mise à jour :** 30 décembre 2024  
**Version du schéma :** 2.0  
**Statut :** ✅ Prêt pour migration
