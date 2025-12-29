# 🔧 Fix Cache - Sessions invalides persistantes

## 🎯 Problème résolu

**Symptôme** :
```
📦 Cache hit pour sessions actives: 5wJ3sJuz6k1SXErC5Beo
⚠️ Session HISTORIQUE FPONl57FgjbYoFUGQKEC ignorée (erreur décodage): The data couldn't be read because it is missing.
```

Même après avoir supprimé les sessions dans Firestore, le cache local les retournait encore.

---

## ✅ Solutions appliquées

### 1️⃣ **Réduction de la durée du cache**

**Avant** : 30 secondes  
**Après** : 5 secondes

```swift
// SessionService.swift
private let cacheValidityDuration: TimeInterval = 5.0  // ✅ 5 secondes
```

**Pourquoi ?** En développement, un cache de 5 secondes permet de tester rapidement sans attendre 30 secondes.

---

### 2️⃣ **Invalidation du cache lors du pull-to-refresh**

#### Dans `SquadDetailView.swift` :
```swift
.refreshable {
    if let squadId = squad.id {
        SessionService.shared.invalidateCache(squadId: squadId)
        Logger.log("🔄 Cache invalidé via pull-to-refresh", category: .ui)
    }
}
```

#### Dans `SquadSessionsListView.swift` :
```swift
private func loadSessions() async {
    guard let squadId = squad.id else { return }
    
    // ✅ Invalider le cache avant de recharger
    SessionService.shared.invalidateCache(squadId: squadId)
    Logger.log("🔄 Cache invalidé avant rechargement", category: .ui)
    
    isLoading = true
    // ...
}
```

---

### 3️⃣ **Méthode publique pour forcer le rafraîchissement**

```swift
// SessionService.swift
func forceRefresh(squadId: String) async throws -> [SessionModel] {
    Logger.log("🔄 Rafraîchissement forcé pour squad: \(squadId)", category: .service)
    invalidateCache(squadId: squadId)
    return try await getActiveSessions(squadId: squadId)
}
```

Vous pouvez maintenant appeler cette méthode depuis n'importe où pour forcer un rafraîchissement complet.

---

## 🧹 Comment nettoyer complètement

### Option A : Redémarrer l'app

Le cache est en mémoire (pas persisté). Redémarrer l'app vide complètement le cache.

### Option B : Pull-to-refresh

1. Aller dans `SquadDetailView`
2. Tirer vers le bas pour rafraîchir
3. Le cache sera invalidé et les données seront rechargées depuis Firestore

### Option C : Attendre 5 secondes

Le cache expire automatiquement après 5 secondes maintenant.

---

## 🎯 Procédure complète de nettoyage

### 1️⃣ **Supprimer les anciennes sessions dans Firebase**

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Firestore Database → Collection `sessions`
3. Supprimer tous les documents

### 2️⃣ **Dans l'app : Invalider le cache**

**Option 1** - Force quit + relancer l'app :
```
1. Double-cliquez sur le bouton Home (ou swipe up)
2. Swipe up sur l'app pour la fermer complètement
3. Relancer l'app
```

**Option 2** - Pull-to-refresh :
```
1. Aller dans SquadDetailView ou SquadSessionsListView
2. Tirer vers le bas
3. Le cache sera vidé automatiquement
```

### 3️⃣ **Créer une nouvelle session**

1. Cliquer sur "Démarrer une course"
2. Lancer la session
3. Vérifier dans Firebase Console que la structure est correcte

### 4️⃣ **Vérifier que tout fonctionne**

✅ Session visible sur la carte  
✅ Session visible dans SquadDetailView  
✅ Session visible dans SquadSessionsListView  
✅ Pas d'erreur de décodage dans les logs  

---

## 📊 Logs à surveiller

### ✅ Logs normaux (tout va bien)

```
🔄 Cache invalidé avant rechargement
🔍 Récupération sessions actives pour squad: 5wJ3sJuz6k1SXErC5Beo
✅ 1 sessions actives trouvées
```

### ⚠️ Logs problématiques

```
📦 Cache hit pour sessions actives: 5wJ3sJuz6k1SXErC5Beo
⚠️ Session HISTORIQUE FPONl57FgjbYoFUGQKEC ignorée (erreur décodage)
```

**Solution** : Pull-to-refresh ou attendre 5 secondes.

---

## 🔧 Debugging : Forcer la vidange du cache

Si vous voulez forcer la vidange du cache manuellement pendant le développement :

### Option 1 : Ajouter un bouton de debug

```swift
// Dans SquadDetailView.swift ou SquadSessionsListView.swift
.toolbar {
    #if DEBUG
    ToolbarItem(placement: .topBarLeading) {
        Button("🗑️ Clear Cache") {
            SessionService.shared.invalidateCache()
            print("✅ Cache vidé")
        }
    }
    #endif
}
```

### Option 2 : Appeler depuis la console Xcode

```swift
// Breakpoint dans le code, puis dans la console Xcode :
(lldb) po SessionService.shared.invalidateCache()
```

---

## 🎯 Configuration recommandée

### En développement
```swift
private let cacheValidityDuration: TimeInterval = 5.0  // 5 secondes
```

### En production
```swift
private let cacheValidityDuration: TimeInterval = 30.0  // 30 secondes
```

**Pourquoi ?**
- **Dev** : Besoin de tester rapidement, voir les changements immédiatement
- **Prod** : Réduire les requêtes Firestore, économiser les coûts

---

## ✅ Checklist finale

- [x] Cache réduit à 5 secondes (dev)
- [x] Pull-to-refresh invalide le cache
- [x] `loadSessions()` invalide le cache avant rechargement
- [x] Méthode `forceRefresh()` disponible
- [x] Sessions invalides filtrées silencieusement
- [x] Logs clairs pour le debugging

---

## 🚀 Prochaines étapes

1. **Nettoyer Firestore** (supprimer toutes les anciennes sessions)
2. **Redémarrer l'app** (vider le cache mémoire)
3. **Créer une nouvelle session** (tester la structure)
4. **Vérifier les logs** (pas d'erreur de décodage)
5. **Tester le pull-to-refresh** (cache invalidé)

**Tout devrait fonctionner parfaitement maintenant ! 🎉**
