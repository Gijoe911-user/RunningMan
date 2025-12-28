# 🐛 Guide de débogage - Sessions non affichées

## Problème
Les sessions existent dans Firebase mais ne s'affichent pas dans l'app.

## Logs ajoutés pour déboguer

J'ai ajouté des logs détaillés dans plusieurs endroits du code :

### 1. SessionService.observeActiveSession
```
🔍 observeActiveSession démarré pour squadId: [ID]
📦 Snapshot reçu: X document(s)
📄 Document trouvé: [ID] - data: [...]
✅ Session décodée: [ID] - status: ACTIVE
⚠️ Aucun document trouvé
```

### 2. RealtimeLocationService.setContext
```
🔧 RealtimeLocationService.setContext appelé avec squadId: [ID]
```

### 3. SessionsViewModel
```
🔧 SessionsViewModel.setContext appelé avec squadId: [ID]
📥 SessionsViewModel reçoit session: [ID]
👥 SessionsViewModel reçoit X runners
📍 SessionsViewModel reçoit position: lat, lon
```

## Checklist de diagnostic

### 1. Vérifier que setContext est appelé

Quand vous ouvrez la vue "Course", vous devriez voir dans la console :
```
🔧 SessionsViewModel.setContext appelé avec squadId: [VOTRE_SQUAD_ID]
🔧 RealtimeLocationService.setContext appelé avec squadId: [VOTRE_SQUAD_ID]
🔍 observeActiveSession démarré pour squadId: [VOTRE_SQUAD_ID]
```

**Si vous ne voyez PAS ces logs** → Le problème est que `setContext` n'est pas appelé ou que `selectedSquad` est nil.

### 2. Vérifier la requête Firestore

Vous devriez voir :
```
📦 Snapshot reçu: X document(s)
```

**Si X = 0** → Aucune session n'existe dans Firestore pour ce squad avec status ACTIVE ou PAUSED.

### 3. Vérifier le décodage

Si des documents sont trouvés, vous devriez voir :
```
📄 Document trouvé: [ID] - data: {...}
✅ Session décodée: [ID] - status: ACTIVE
```

**Si vous voyez "⚠️ Échec décodage session"** → Le format des données dans Firestore ne correspond pas au modèle SessionModel.

### 4. Vérifier la réception dans le ViewModel

Finalement, vous devriez voir :
```
📥 SessionsViewModel reçoit session: [ID]
```

**Si vous ne voyez PAS ce log** → Le problème est dans la liaison Combine entre RealtimeLocationService et SessionsViewModel.

## Vérifications dans Firebase

### Structure attendue dans Firestore

```
sessions/
  └── [sessionId]/
      ├── squadId: "votre-squad-id"
      ├── status: "ACTIVE" (ou "PAUSED")
      ├── creatorId: "..."
      ├── startedAt: Timestamp
      ├── participants: ["user1", "user2"]
      ├── sessionType: "TRAINING"
      ├── totalDistanceMeters: 0
      ├── durationSeconds: 0
      ├── averageSpeed: 0
      ├── messageCount: 0
      ├── createdAt: Timestamp
      └── updatedAt: Timestamp
```

### Points à vérifier :

1. ✅ Le champ `squadId` correspond bien à l'ID de votre squad sélectionnée
2. ✅ Le champ `status` est exactement "ACTIVE" ou "PAUSED" (en majuscules)
3. ✅ Tous les champs obligatoires sont présents
4. ✅ Les types de données correspondent (ex: `startedAt` est un Timestamp, pas une String)

## Solutions possibles

### Si squadId ne correspond pas :
- Vérifiez que vous avez sélectionné la bonne squad dans l'app
- Vérifiez l'ID de la squad dans Firebase Console

### Si status n'est pas bon :
```swift
// Dans Firebase Console, modifiez manuellement :
status: "ACTIVE"  // Exactement comme ça, en majuscules
```

### Si des champs manquent :
Utilisez la méthode `createSession` de SessionService qui crée correctement tous les champs.

### Si le décodage échoue :
Comparez la structure de vos documents Firebase avec `SessionModel.swift`.

## Test rapide

1. Supprimez toutes les sessions existantes dans Firebase
2. Créez une nouvelle session via l'app (bouton +)
3. Observez les logs dans la console Xcode
4. La session devrait maintenant apparaître

## Commandes Xcode

Pour voir les logs facilement :
1. Ouvrez la console (⌘⇧C)
2. Filtrez par : `🔍` ou `📥` ou `⚠️` pour voir les logs pertinents
3. Recherchez votre squadId pour suivre le flux complet
