//
//  FirebaseSchema.swift
//  RunningMan
//
//  Documentation du schéma Firestore pour Phase 1
//

/*
 
═══════════════════════════════════════════════════════════════════
FIRESTORE DATABASE STRUCTURE - PHASE 1 MVP
═══════════════════════════════════════════════════════════════════

📦 COLLECTION: users
════════════════════════════════════════════════════════════════════
Document ID: {userId} (Firebase Auth UID)
{
    "displayName": String,
    "email": String,
    "photoURL": String?,
    "squads": [String], // Array of Squad IDs
    "createdAt": Timestamp,
    "lastSeen": Timestamp
}

Index requis: None


📦 COLLECTION: squads
════════════════════════════════════════════════════════════════════
Document ID: {squadId} (auto-generated)
{
    "name": String,
    "accessCode": String, // Code unique 6 caractères
    "isPublic": Boolean,
    "createdAt": Timestamp,
    "createdBy": String, // userId
    "members": [
        {
            "userId": String,
            "displayName": String,
            "role": String, // "runner" | "supporter"
            "photoURL": String?,
            "joinedAt": Timestamp
        }
    ]
}

Index requis:
- accessCode (ASC)
- isPublic (ASC), createdAt (DESC)


📦 COLLECTION: sessions
════════════════════════════════════════════════════════════════════
Document ID: {sessionId} (auto-generated)
{
    "squadId": String,
    "name": String,
    "status": String, // "waiting" | "active" | "finished"
    "startTime": Timestamp?,
    "endTime": Timestamp?,
    "activeRunners": [String], // Array of userIds
    "createdBy": String, // userId
    "createdAt": Timestamp
}

Index requis:
- squadId (ASC), status (ASC), startTime (DESC)
- status (ASC), startTime (DESC)


📦 COLLECTION: locations
════════════════════════════════════════════════════════════════════
Document ID: {userId}_{sessionId}
{
    "userId": String,
    "sessionId": String,
    "displayName": String,
    "photoURL": String?,
    "latitude": Number,
    "longitude": Number,
    "altitude": Number?,
    "speed": Number?, // m/s
    "heading": Number?, // degrés
    "accuracy": Number?, // mètres
    "timestamp": Timestamp,
    "updatedAt": Timestamp // Pour TTL
}

Index requis:
- sessionId (ASC), timestamp (DESC)
- userId (ASC), sessionId (ASC), timestamp (DESC)

TTL (Time To Live): 
- Supprimer automatiquement après 24h
- Field: updatedAt


📦 COLLECTION: messages
════════════════════════════════════════════════════════════════════
Document ID: {messageId} (auto-generated)
{
    "sessionId": String,
    "senderId": String,
    "senderName": String,
    "content": String,
    "type": String, // "text" | "audio" | "photo"
    "audioURL": String?, // Cloud Storage URL (Phase 2)
    "photoURL": String?, // Cloud Storage URL
    "timestamp": Timestamp,
    "readBy": [String] // Array of userIds
}

Index requis:
- sessionId (ASC), timestamp (ASC)


═══════════════════════════════════════════════════════════════════
FIRESTORE SECURITY RULES - PHASE 1
═══════════════════════════════════════════════════════════════════

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isSquadMember(squadId) {
      return request.auth.uid in get(/databases/$(database)/documents/squads/$(squadId)).data.members.map(m => m.userId);
    }
    
    // Users Collection
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // Squads Collection
    match /squads/{squadId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSquadMember(squadId);
      allow delete: if resource.data.createdBy == request.auth.uid;
    }
    
    // Sessions Collection
    match /sessions/{sessionId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn();
      allow delete: if resource.data.createdBy == request.auth.uid;
    }
    
    // Locations Collection
    match /locations/{locationId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn();
      allow delete: if isOwner(locationId.split('_')[0]);
    }
    
    // Messages Collection
    match /messages/{messageId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if request.auth.uid == resource.data.senderId;
      allow delete: if request.auth.uid == resource.data.senderId;
    }
  }
}


═══════════════════════════════════════════════════════════════════
FIREBASE STORAGE STRUCTURE - PHASE 1
═══════════════════════════════════════════════════════════════════

/users/{userId}/
    - profile_photo.jpg

/sessions/{sessionId}/
    - photos/{userId}_{timestamp}.jpg
    - audio/{messageId}.m4a (Phase 2)

/squads/{squadId}/
    - squad_photo.jpg


═══════════════════════════════════════════════════════════════════
CLOUD FUNCTIONS - PHASE 1 (Optionnelles)
═══════════════════════════════════════════════════════════════════

1. onMessageCreated (Phase 1)
   - Trigger: onCreate messages/{messageId}
   - Action: Envoyer notification push aux membres de la session

2. onLocationUpdate (Optimisation Phase 1)
   - Trigger: onUpdate locations/{locationId}
   - Action: Calculer distance parcourue, mettre à jour stats

3. cleanupOldLocations (Batch)
   - Trigger: Scheduled (toutes les heures)
   - Action: Supprimer locations > 24h

4. textToSpeech (Phase 1)
   - Trigger: HTTP callable
   - Action: Convertir texte en audio, uploader dans Storage
   - Input: { text: String, sessionId: String }
   - Output: { audioURL: String }


═══════════════════════════════════════════════════════════════════
REALTIME DATABASE (Alternative pour locations - Performance)
═══════════════════════════════════════════════════════════════════

Si trop de writes avec Firestore, utiliser Realtime Database pour locations:

/sessions/{sessionId}/
    /runners/
        /{userId}/
            - latitude: Number
            - longitude: Number
            - timestamp: Number
            - displayName: String

Rules:
{
  "rules": {
    "sessions": {
      "$sessionId": {
        "runners": {
          ".read": "auth != null",
          "$userId": {
            ".write": "auth.uid == $userId"
          }
        }
      }
    }
  }
}


═══════════════════════════════════════════════════════════════════
FIREBASE CONFIGURATION STEPS
═══════════════════════════════════════════════════════════════════

1. Console Firebase:
   - Créer projet "RunningMan"
   - Activer Authentication (Email/Password)
   - Créer base Firestore (mode test au début)
   - Créer Storage bucket

2. iOS App:
   - Télécharger GoogleService-Info.plist
   - Ajouter dans Xcode (Copy items if needed)
   - Ajouter Firebase SDK via SPM:
     * FirebaseAuth
     * FirebaseFirestore
     * FirebaseStorage
     * FirebaseFirestoreSwift

3. Indexes Firestore:
   - Créer automatiquement via console lors des premières queries
   - Ou via firebase deploy --only firestore:indexes

4. Extensions (Optionnel):
   - Text-to-Speech extension
   - Image Resizing extension


═══════════════════════════════════════════════════════════════════
ESTIMATION COÛTS FIREBASE (100 utilisateurs actifs/mois)
═══════════════════════════════════════════════════════════════════

Firestore:
- Reads: ~500K/mois → ~$0.18
- Writes: ~200K/mois → ~$0.36
- Storage: ~1GB → $0.18

Storage:
- Photos: ~5GB → $0.13
- Bandwidth: ~20GB → $2.40

Cloud Functions:
- Invocations: ~50K → Gratuit
- CPU: ~10h → ~$0.40

Realtime Database (si utilisé pour locations):
- Storage: 1GB → Gratuit
- Bandwidth: 10GB → Gratuit

Total estimé: ~$3-5/mois (Scale Spark gratuit au début)

*/

import Foundation

// Ce fichier sert uniquement de documentation
// Ne pas compiler dans le projet
