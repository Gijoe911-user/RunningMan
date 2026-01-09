# 🛠️ Guide de Nettoyage des Sessions Corrompues

## 🎯 Objectif

Ce guide explique comment détecter et nettoyer les sessions corrompues ou "zombies" qui bloquent l'utilisation de RunningMan.

---

## ⚠️ Quand Utiliser Ce Guide ?

### Symptômes d'une Session Corrompue :

1. ✅ **Impossible de créer une nouvelle session** → Message "Une session est déjà active"
2. ✅ **Session invisible dans l'onglet "Sessions Actives"** → Liste vide mais badge "Session active" sur le squad
3. ✅ **Boutons inactifs** → "Terminer" ou "Rejoindre" ne fonctionnent pas
4. ✅ **Badge rouge persistant** → Le squad affiche "Session active" mais rien ne se passe

---

## 🔧 Solution #1 : Nettoyage Automatique (Recommandé)

### Étapes :

1. **Ouvrir l'onglet Squad** concerné
2. **Taper sur "Voir les sessions"**
3. **Regarder en haut à droite** → Un badge rouge avec un nombre apparaît si sessions corrompues
   ```
   ⚠️ 2  ← Nombre de sessions à nettoyer
   ```
4. **Taper sur le badge rouge**
5. **Confirmer le nettoyage** → "Nettoyer"
6. **Attendre** → Les sessions sont automatiquement supprimées
7. **Pull-to-refresh** → Tirer la liste vers le bas pour recharger
8. **Force-quit l'app** → Fermer complètement et relancer

### Résultat Attendu :

- ✅ Badge rouge disparu
- ✅ Liste "Sessions Actives" vide si aucune session réelle
- ✅ Possibilité de créer une nouvelle session

---

## 🔧 Solution #2 : Nettoyage Manuel (Firebase Console)

Si le nettoyage automatique ne fonctionne pas, vous pouvez nettoyer manuellement depuis Firebase.

### Étapes :

1. **Ouvrir Firebase Console** : https://console.firebase.google.com
2. **Sélectionner votre projet** : RunningMan
3. **Aller dans Firestore Database**
4. **Ouvrir la collection `sessions`**

5. **Identifier la session problématique** :
   - Trier par `squadId` → Trouver votre squad
   - Chercher les sessions avec `status != ended`
   - Noter le **Document ID** (ex: `abc123xyz`)

6. **Supprimer la session** :
   - Cliquer sur le document
   - Menu "..." en haut à droite
   - "Delete document"
   - Confirmer

7. **Mettre à jour le squad** :
   - Retourner dans la collection `squads`
   - Trouver votre squad (par son ID)
   - Cliquer sur le champ `hasActiveSessions`
   - Remplacer par `false` (ou supprimer le champ)
   - Sauvegarder

8. **Redémarrer l'application** :
   - Force-quit l'app
   - Relancer
   - Tester la création d'une nouvelle session

---

## 🔧 Solution #3 : Reset Complet (Dernier Recours)

Si les deux solutions précédentes échouent :

### Option A : Reset du TrackingManager (depuis l'app)

⚠️ Cette option nécessite d'ajouter un bouton temporaire dans l'UI.

```swift
// À ajouter temporairement dans SquadDetailView ou SettingsView
Button("🧹 Reset TrackingManager") {
    Task {
        await TrackingManager.shared.reconcileWithFirestore()
    }
}
```

### Option B : Supprimer TOUTES les sessions du squad

⚠️ Cela supprime aussi les sessions valides !

1. **Firestore Console** → Collection `sessions`
2. **Filtrer** : `squadId == [votre_squad_id]`
3. **Sélectionner tous les documents**
4. **Supprimer en masse**
5. **Mettre à jour** le squad : `hasActiveSessions = false`
6. **Redémarrer l'app**

---

## 🔍 Vérification Post-Nettoyage

Après avoir nettoyé, vérifiez que tout fonctionne :

### Checklist :

- [ ] Je peux créer une nouvelle session
- [ ] La session apparaît dans "Sessions Actives"
- [ ] Le tracking GPS démarre correctement
- [ ] Les boutons "Pause" et "Terminer" fonctionnent
- [ ] Après avoir terminé, la session disparaît de "Sessions Actives"
- [ ] La session apparaît dans "Historique"
- [ ] Le badge "Session active" disparaît du squad

---

## 📊 Logs à Surveiller

Si vous avez accès aux logs Xcode, surveillez ces messages après le nettoyage :

### Logs de Nettoyage :
```
🧹 Démarrage nettoyage sessions pour squad: [squadId]
📋 X session(s) non terminée(s) trouvée(s)
⚠️ Session corrompue détectée: [sessionId]
🗑️ Session [sessionId] supprimée (corrompue)
✅ Nettoyage terminé: X session(s) nettoyée(s)
```

### Logs de Réconciliation :
```
🔄 === RÉCONCILIATION TrackingManager avec Firestore ===
🔍 Session locale détectée: [sessionId]
⚠️ INCOHÉRENCE: Session terminée dans Firestore mais active localement
🧹 Réinitialisation TrackingManager - Raison: Session terminée dans Firestore
✅ TrackingManager réinitialisé
```

### Logs de Création de Session (après nettoyage) :
```
🆕 Création d'une nouvelle session pour squad: [squadId]
✅ Session créée avec ID: [nouveauId]
🚀 TrackingManager.startTracking appelé
✅✅ Tracking démarré avec succès!
```

---

## ⚡️ Prévention des Futures Corruptions

Pour éviter que le problème se reproduise :

### Bonnes Pratiques :

1. **Toujours terminer proprement une session** :
   - Utiliser le bouton "Terminer" (pas de force-quit)
   - Attendre la confirmation de fin de session

2. **Ne pas laisser une session active > 4h** :
   - Les sessions sont automatiquement terminées après 4h
   - Mais le nettoyage manuel peut être nécessaire

3. **Faire un pull-to-refresh régulièrement** :
   - Dans la liste des sessions
   - Cela invalide le cache et recharge depuis Firestore

4. **Redémarrer l'app après un crash** :
   - Si l'app crash pendant une session
   - Redémarrer proprement avant de créer une nouvelle session

5. **Appeler la réconciliation au démarrage** :
   - L'app appelle automatiquement `reconcileWithFirestore()` au démarrage
   - Cela nettoie les états incohérents

---

## 🆘 Cas Particuliers

### Cas #1 : Session bloquée en "Stopping..."

**Symptôme :** Le tracking est bloqué en état "Arrêt..."

**Solution :**
1. Force-quit l'app
2. Relancer
3. La réconciliation au démarrage devrait nettoyer
4. Si persiste → Nettoyage manuel (Solution #2)

---

### Cas #2 : Plusieurs sessions actives simultanées

**Symptôme :** 2+ sessions actives dans Firestore pour le même squad

**Solution :**
1. Le nettoyage automatique (Solution #1) devrait toutes les détecter
2. Si non → Nettoyage manuel de toutes sauf la plus récente
3. Vérifier les logs pour comprendre comment ça s'est produit

---

### Cas #3 : TrackingManager bloqué après redémarrage

**Symptôme :** Impossible de démarrer un tracking, même après redémarrage

**Solution :**
1. Vérifier les logs : `canStartTracking = false`
2. Appeler manuellement la réconciliation (Solution #3 Option A)
3. Si persiste → Désinstaller/réinstaller l'app (⚠️ perte données locales)

---

## 🐛 Rapporter un Bug

Si le problème persiste après avoir essayé toutes les solutions :

### Informations à Collecter :

1. **Logs Xcode** complets (depuis le démarrage jusqu'à l'erreur)
2. **Capture d'écran** de l'état de la session dans Firebase Console
3. **Étapes de reproduction** détaillées
4. **Version de l'app** et **version iOS**

### Logs Clés à Inclure :

- Tous les logs avec préfixe `[AUDIT-`
- Logs de `TrackingManager.startTracking`
- Logs de `SessionService.createSession`
- Logs de réconciliation

---

## ✅ Checklist de Déblocage Rapide (TL;DR)

Si vous êtes pressé :

1. ✅ **Ouvrir "Voir les sessions"** du squad
2. ✅ **Taper sur le badge rouge** en haut à droite (si visible)
3. ✅ **Confirmer le nettoyage**
4. ✅ **Pull-to-refresh** (tirer vers le bas)
5. ✅ **Force-quit l'app** (fermer complètement)
6. ✅ **Relancer l'app**
7. ✅ **Tester la création d'une nouvelle session**

**Si ça ne marche pas :**
8. ✅ **Firebase Console** → Supprimer manuellement la session
9. ✅ **Firebase Console** → Mettre `hasActiveSessions = false` dans le squad
10. ✅ **Redémarrer l'app**

---

## 🎓 Ressources Complémentaires

- **Diagnostic complet** : `DIAGNOSTIC_SESSION_BLOQUEE.md`
- **Logs de débogage** : Activer "Debug Logs" dans l'app (si disponible)
- **Firebase Console** : https://console.firebase.google.com

---

**Date de création :** 2026-01-09  
**Version du guide :** 1.0  
**Compatibilité :** RunningMan v1.x
