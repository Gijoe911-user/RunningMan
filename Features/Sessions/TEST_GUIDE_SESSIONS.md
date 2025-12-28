# 🧪 Guide de Test - Sessions & Terminer Session

**Date :** 27 Décembre 2025

---

## 🎯 Tests Prioritaires

### Test 1️⃣ : Terminer une Session (Flow Complet)

**Prérequis :**
- Appareil avec GPS fonctionnel
- Compte utilisateur connecté
- Membre d'une squad

**Étapes :**
1. ✅ Ouvrir l'onglet "Course"
2. ✅ Taper sur le bouton "+" en haut à droite
3. ✅ Créer une nouvelle session
4. ✅ Vérifier que la carte s'affiche
5. ✅ Vérifier que l'overlay "Session Active" apparaît en bas
6. ✅ Vérifier que les stats s'affichent (durée, coureurs, etc.)
7. ✅ Taper sur le bouton rouge "Terminer la session"
8. ✅ Vérifier l'alerte de confirmation
9. ✅ Taper sur "Terminer"
10. ✅ Vérifier que le bouton affiche un ProgressView
11. ✅ Attendre la fin du traitement
12. ✅ Vérifier que l'overlay disparaît
13. ✅ Vérifier que le NoSessionOverlay s'affiche

**Vérifications Firestore :**
```
1. Ouvrir Firebase Console
2. Aller dans Firestore Database
3. Collection "sessions" → Trouver votre session
4. Vérifier :
   - status: "ENDED"
   - endedAt: [Timestamp]
   - durationSeconds: [nombre]
```

**Résultat attendu :**
- ✅ Session se termine sans erreur
- ✅ UI se met à jour automatiquement
- ✅ Pas de crash
- ✅ GPS s'arrête

---

### Test 2️⃣ : Permissions (Seul le Créateur Peut Terminer)

**Prérequis :**
- 2 devices ou 2 simulateurs
- 2 comptes utilisateurs différents
- Une squad commune

**Étapes :**

**Device A (Créateur) :**
1. ✅ Se connecter avec User A
2. ✅ Créer une session
3. ✅ Noter l'ID de la session (visible dans Firestore)

**Device B (Participant) :**
4. ✅ Se connecter avec User B
5. ✅ Ouvrir la même squad
6. ✅ Aller dans l'onglet "Course"
7. ✅ Vérifier que la session active s'affiche

**Vérifications :**
- ✅ **Device A** : Bouton "Terminer la session" VISIBLE
- ✅ **Device B** : Bouton "Terminer la session" INVISIBLE

**Résultat attendu :**
- ✅ Seul le créateur voit le bouton
- ✅ Les participants ne peuvent pas terminer

---

### Test 3️⃣ : Gestion d'Erreurs

**Test 3A : Sans Session Active**
1. ✅ Aller dans l'onglet "Course"
2. ✅ Vérifier qu'aucune session n'est active
3. ✅ Vérifier que NoSessionOverlay s'affiche
4. ✅ Pas de bouton "Terminer" visible

**Test 3B : Perte de Connexion**
1. ✅ Créer une session
2. ✅ Activer le mode Avion
3. ✅ Taper sur "Terminer la session"
4. ✅ Confirmer
5. ✅ Vérifier qu'une alerte d'erreur s'affiche
6. ✅ Désactiver le mode Avion
7. ✅ Réessayer
8. ✅ Vérifier que ça fonctionne

**Résultat attendu :**
- ✅ Alertes d'erreur claires
- ✅ Pas de crash
- ✅ Possibilité de réessayer

---

### Test 4️⃣ : Historique des Sessions

**Prérequis :**
- Au moins 1 session terminée

**Étapes :**
1. ✅ Aller dans la squad
2. ✅ Taper sur "Historique" (ou naviguer vers SessionHistoryView)
3. ✅ Vérifier que la liste s'affiche
4. ✅ Vérifier les données de la session :
   - Date et heure
   - Type de session
   - Nombre de coureurs
   - Distance
   - Durée
   - Allure moyenne
5. ✅ Taper sur une session
6. ✅ Vérifier la navigation vers SessionDetailView
7. ✅ Tirer vers le bas pour refresh
8. ✅ Vérifier que la liste se met à jour

**État Vide :**
9. ✅ Supprimer toutes les sessions dans Firestore
10. ✅ Refresh la vue
11. ✅ Vérifier l'affichage de l'état vide élégant

**Résultat attendu :**
- ✅ Historique complet et précis
- ✅ Navigation fluide
- ✅ Pull-to-refresh fonctionne
- ✅ État vide s'affiche correctement

---

### Test 5️⃣ : Détails Session Active en Temps Réel

**Prérequis :**
- Session active en cours
- GPS activé

**Étapes :**
1. ✅ Aller dans SessionsListView
2. ✅ Avoir une session active
3. ✅ [Optionnel] Naviguer vers ActiveSessionDetailView
4. ✅ Vérifier la carte avec votre position
5. ✅ Vérifier les stats en direct :
   - Distance
   - Allure moyenne
   - Vitesse moyenne
   - Nombre de coureurs
6. ✅ Marcher/Courir pendant 2-3 minutes
7. ✅ Vérifier que les stats se mettent à jour
8. ✅ Vérifier l'indicateur "En direct"

**Multi-utilisateurs :**
9. ✅ Avoir un autre participant actif
10. ✅ Vérifier que sa position apparaît sur la carte
11. ✅ Vérifier ses stats dans la liste des participants

**Résultat attendu :**
- ✅ Carte fonctionne
- ✅ Stats se mettent à jour en temps réel
- ✅ Positions des autres visibles
- ✅ Pas de lag

---

### Test 6️⃣ : Flow Complet Multi-Utilisateurs

**Prérequis :**
- 2 devices avec GPS
- 2 utilisateurs dans la même squad

**Étapes :**

**User A (Créateur) :**
1. ✅ Créer une session
2. ✅ Démarrer le GPS (automatique)
3. ✅ Commencer à marcher/courir

**User B (Participant) :**
4. ✅ Voir la session active dans l'onglet Course
5. ✅ [Optionnel] Rejoindre la session via bouton
6. ✅ Démarrer le GPS
7. ✅ Commencer à marcher/courir

**Vérifications :**
- ✅ User A voit la position de User B
- ✅ User B voit la position de User A
- ✅ Les stats se mettent à jour pour les deux
- ✅ Le nombre de coureurs affiche "2"

**Fin de Session :**
8. ✅ User A termine la session
9. ✅ User B voit la session disparaître en temps réel
10. ✅ Les deux voient NoSessionOverlay
11. ✅ La session apparaît dans l'historique pour les deux

**Résultat attendu :**
- ✅ Synchronisation temps réel fonctionne
- ✅ Pas de delay important (<2 secondes)
- ✅ Pas de crash
- ✅ GPS précis

---

## 📊 Checklist Globale

### Fonctionnalités Core
- [ ] ✅ Créer une session
- [ ] ✅ Terminer une session
- [ ] ✅ Confirmation avant terminaison
- [ ] ✅ Permissions (créateur uniquement)
- [ ] ✅ Loading state pendant terminaison
- [ ] ✅ Gestion d'erreurs
- [ ] ✅ Arrêt automatique du GPS

### Visibilité
- [ ] ✅ Session active visible dans SessionsListView
- [ ] ✅ Historique accessible
- [ ] ✅ Détails session avec stats
- [ ] ✅ États vides élégants

### Temps Réel
- [ ] ✅ Positions des coureurs
- [ ] ✅ Stats en direct
- [ ] ✅ Synchronisation multi-utilisateurs
- [ ] ✅ Listeners Firestore

### UI/UX
- [ ] ✅ Animations fluides
- [ ] ✅ Alertes de confirmation
- [ ] ✅ Messages d'erreur clairs
- [ ] ✅ Indicateurs de chargement
- [ ] ✅ Dark mode

---

## 🐛 Bugs à Surveiller

### Problèmes Potentiels

1. **Session ne se termine pas**
   - Vérifier les permissions Firestore
   - Vérifier que l'userId est correct
   - Vérifier que le sessionId n'est pas nil

2. **GPS ne s'arrête pas**
   - Vérifier `LocationService.stopTracking()`
   - Vérifier les logs console
   - Vérifier background modes

3. **UI ne se met pas à jour**
   - Vérifier que les listeners Firestore sont actifs
   - Vérifier `@Published` properties
   - Vérifier `@MainActor`

4. **Crash lors de la terminaison**
   - Vérifier force unwraps (!)
   - Vérifier les optionals
   - Activer Exception Breakpoint

---

## 📝 Logs à Vérifier

### Console Logs Attendus

**Lors de la création :**
```
🔨 createSession appelé pour squadId: [ID]
💾 Enregistrement session dans Firestore: [SESSION_ID]
✅ Session enregistrée - ID: [SESSION_ID], Status: ACTIVE
```

**Lors de la terminaison :**
```
🛑 Fin de la session [SESSION_ID]...
✅ Session terminée avec succès
```

**Erreurs possibles :**
```
❌ Impossible de terminer la session: pas de session active
❌ Utilisateur non connecté
❌ Seul le créateur peut terminer la session
```

---

## ✅ Validation Finale

Une fois tous les tests passés :

1. [ ] Créer une session → OK
2. [ ] Terminer la session → OK
3. [ ] Permissions respectées → OK
4. [ ] Historique fonctionne → OK
5. [ ] Multi-utilisateurs OK → OK
6. [ ] Gestion d'erreurs OK → OK
7. [ ] GPS s'arrête → OK
8. [ ] Pas de crash → OK
9. [ ] UI fluide → OK
10. [ ] Firestore cohérent → OK

**Si tous les tests passent : ✅ READY FOR PRODUCTION**

---

## 🚀 Commandes Firebase Utiles

### Tester manuellement dans Console

**Créer une session de test :**
```javascript
// Collection: sessions
{
  squadId: "YOUR_SQUAD_ID",
  creatorId: "YOUR_USER_ID",
  startedAt: Timestamp.now(),
  status: "ACTIVE",
  participants: ["YOUR_USER_ID"],
  totalDistanceMeters: 0,
  durationSeconds: 0,
  averageSpeed: 0
}
```

**Terminer manuellement :**
```javascript
// Mettre à jour le document
{
  status: "ENDED",
  endedAt: Timestamp.now(),
  durationSeconds: 1800 // 30 min
}
```

---

**Bon courage pour les tests ! 🎯**
