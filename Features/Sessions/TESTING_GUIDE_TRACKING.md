# 🧪 Guide de Test - Intégration Tracking

**Date :** 2 janvier 2026  
**Version :** Option A - Contrôles intégrés dans SessionsListView

---

## ✅ Checklist de compilation

Avant de lancer, vérifier que ces fichiers compilent :

- [ ] `SessionActiveOverlay.swift` ← Modifié
- [ ] `SessionTrackingView.swift` ← Modifié précédemment
- [ ] `SessionTrackingControlsView.swift` ← Déjà existant
- [ ] `SessionsListView.swift` ← Inchangé
- [ ] `SessionsViewModel.swift` ← Inchangé
- [ ] `TrackingManager.swift` ← Inchangé

### Erreurs possibles

#### Erreur 1 : "Cannot find TrackingManager in scope"
**Solution :** Vérifier que `TrackingManager.swift` est bien dans le projet

#### Erreur 2 : "Cannot find SessionTrackingControlsView in scope"
**Solution :** Vérifier que `SessionTrackingControlsView.swift` est bien dans le projet

#### Erreur 3 : "Cannot convert value of type 'Binding<TrackingState>'"
**Solution :** Vérifier que vous avez bien `@State private var currentTrackingState: TrackingState = .idle`

---

## 🎯 Scénarios de test

### Test 1 : Démarrage automatique ⭐️ CRITIQUE
**Objectif :** Vérifier que le tracking démarre automatiquement quand la session s'affiche

**Steps :**
1. Lancer l'app
2. Créer une nouvelle session (ou rejoindre une session existante)
3. La session devient active → `SessionsListView` s'affiche
4. Observer l'overlay du bas

**Résultat attendu :**
- ✅ L'overlay `SessionActiveOverlay` apparaît
- ✅ Les contrôles de tracking sont visibles
- ✅ Le bouton principal affiche "Pause" (état actif)
- ✅ Badge "En cours" avec point vert visible en haut

**Logs attendus :**
```
🚀 Demande de démarrage tracking pour session: [sessionId]
✅ Tracking démarré
📍 Point GPS ajouté: (lat, lon)
```

**En cas d'échec :**
- Vérifier que `.onAppear` est bien appelé
- Vérifier que `trackingManager.trackingState == .idle` au départ
- Ajouter des logs dans `.onAppear` pour debug

---

### Test 2 : Pause du tracking
**Objectif :** Mettre en pause le tracking GPS

**Steps :**
1. Session active avec tracking en cours
2. Cliquer sur le bouton "Pause" (orange)
3. Observer le changement d'état

**Résultat attendu :**
- ✅ Bouton principal devient "Reprendre" (vert)
- ✅ Badge passe à "En pause" avec point orange
- ✅ Points GPS ne sont plus ajoutés au tracé
- ✅ Chronomètre arrêté

**Logs attendus :**
```
⏸️  Tracking mis en pause
```

**En cas d'échec :**
- Vérifier que `onPause` est bien appelé
- Vérifier que `trackingManager.pauseTracking()` fonctionne
- Vérifier que `.onChange(of: trackingManager.trackingState)` met à jour l'UI

---

### Test 3 : Reprise du tracking
**Objectif :** Reprendre le tracking après une pause

**Steps :**
1. Session en pause (suite du Test 2)
2. Cliquer sur le bouton "Reprendre" (vert)
3. Observer le changement d'état

**Résultat attendu :**
- ✅ Bouton principal redevient "Pause" (orange)
- ✅ Badge repasse à "En cours" avec point vert
- ✅ Points GPS recommencent à être ajoutés
- ✅ Chronomètre reprend

**Logs attendus :**
```
▶️  Tracking repris
📍 Point GPS ajouté: (lat, lon)
```

**En cas d'échec :**
- Vérifier que `onResume` est bien appelé
- Vérifier que `trackingManager.resumeTracking()` fonctionne

---

### Test 4 : Arrêt complet ⭐️ CRITIQUE
**Objectif :** Terminer la session et arrêter proprement le tracking

**Steps :**
1. Session active (en cours ou en pause)
2. Cliquer sur le bouton "Stop" (rouge)
3. Confirmer dans l'alerte
4. Observer la terminaison

**Résultat attendu :**
- ✅ Alerte de confirmation s'affiche
- ✅ Après confirmation, badge passe à "Arrêt..." avec point rouge
- ✅ L'overlay disparaît après quelques secondes
- ✅ La session n'est plus active
- ✅ Retour à l'état "Aucune session active"

**Logs attendus :**
```
🔴 stopTrackingAndEndSession() appelé
🛑 Arrêt du TrackingManager...
✅ TrackingManager arrêté
⏳ Attente de 0.5 secondes...
🛑 Terminaison de la session via SessionsViewModel...
🔴 SessionsViewModel.endSession() appelé
🛑 Arrêt de la session [sessionId]...
✅ Tracking GPS arrêté
✅ Auto-save routes arrêté
✅ HealthKit arrêté
✅ Tâches de rafraîchissement annulées
⏳ Attente de 2 secondes pour finaliser les écritures...
✅ Attente terminée
✅ Session terminée dans Firebase
✅✅ Session complètement terminée
✅ Session terminée
```

**En cas d'échec :**
- Si l'overlay ne disparaît pas → Vérifier que `activeSession` devient `nil`
- Si erreur "Already ending" → Problème de double-clic, c'est géré normalement
- Si crash → Vérifier les logs pour identifier où ça bloque

---

### Test 5 : États visuels
**Objectif :** Vérifier que tous les états s'affichent correctement

**Test 5a : État Idle**
- Bouton "Démarrer" visible
- Icône : `play.fill`
- Couleur : Coral (rose/corail)

**Test 5b : État Active**
- Bouton "Pause" visible
- Icône : `pause.fill`
- Couleur : Orange

**Test 5c : État Paused**
- Bouton "Reprendre" visible
- Icône : `play.fill`
- Couleur : Vert

**Test 5d : État Stopping**
- Texte "Arrêt..." visible
- Icône : `hourglass`
- Couleur : Gris
- Boutons désactivés

---

### Test 6 : Participants toujours visibles
**Objectif :** Vérifier qu'on n'a pas perdu la vue des participants

**Steps :**
1. Session active avec plusieurs coureurs
2. Observer l'overlay

**Résultat attendu :**
- ✅ Section "Coureurs actifs" visible
- ✅ Avatars des coureurs affichés (max 5)
- ✅ "+X" affiché si plus de 5 coureurs
- ✅ Stats des coureurs visibles (distance, vitesse, BPM)

---

### Test 7 : Tracé GPS sur la carte
**Objectif :** Vérifier que le tracé est bien affiché sur la carte

**Steps :**
1. Démarrer une session
2. Se déplacer (ou simuler avec Xcode)
3. Observer la carte

**Résultat attendu :**
- ✅ Ligne colorée (dégradé coral → pink) visible
- ✅ Ligne suit le parcours
- ✅ Marqueur utilisateur (cercle coral) visible
- ✅ Carte se centre automatiquement

**En cas d'échec :**
- Vérifier que `trackingManager.routeCoordinates` contient des points
- Vérifier que `SessionsListView` affiche bien le tracé
- Vérifier les permissions de localisation

---

## 🐛 Problèmes connus et solutions

### Problème 1 : Double tracking
**Symptôme :** Deux tracés différents sur la carte

**Cause :** `SessionsViewModel` et `TrackingManager` trackent indépendamment

**Solution actuelle :** Les deux systèmes coexistent
- `SessionsViewModel` : Affichage temps réel
- `TrackingManager` : Contrôle + sauvegarde

**Solution future (optionnelle) :**
```swift
// Dans SessionsViewModel
.onChange(of: trackingManager.routeCoordinates) { _, newRoute in
    self.routeCoordinates = newRoute
}
```

### Problème 2 : Tracking ne démarre pas
**Symptôme :** Bouton "Démarrer" reste visible, rien ne se passe

**Causes possibles :**
1. Permissions de localisation non accordées
2. `TrackingManager` déjà occupé par une autre session
3. Erreur silencieuse dans `startTracking()`

**Debug :**
```swift
// Ajouter dans .onAppear de SessionActiveOverlay
print("🔍 trackingState: \(trackingManager.trackingState)")
print("🔍 activeTrackingSession: \(trackingManager.activeTrackingSession?.id ?? "nil")")
```

### Problème 3 : Overlay ne disparaît pas après Stop
**Symptôme :** Boutons grisés, overlay reste affiché

**Cause :** `activeSession` n'est pas mis à `nil` après `endSession()`

**Solution :**
```swift
// Vérifier dans SessionsViewModel.bindOutputs()
realtimeService.$activeSession
    .receive(on: RunLoop.main)
    .sink { [weak self] session in
        self?.activeSession = session  // Doit devenir nil
    }
```

### Problème 4 : Crash au Stop
**Symptôme :** App crash lors du clic sur Stop

**Causes possibles :**
1. Double appel à `stopTracking()`
2. Objet déjà libéré
3. Erreur Firebase non gérée

**Solution :**
- La protection `guard !isEnding` est déjà en place
- Vérifier les logs pour identifier la ligne exacte
- Entourer de `do-catch` supplémentaires si nécessaire

---

## 📊 Métriques de succès

### ✅ Test réussi si :
- [ ] Compilation sans erreur
- [ ] Démarrage automatique fonctionne
- [ ] Pause/Reprise fonctionnent
- [ ] Stop termine proprement la session
- [ ] Tous les états visuels s'affichent correctement
- [ ] Participants restent visibles
- [ ] Tracé GPS s'affiche sur la carte
- [ ] Aucun crash
- [ ] Logs cohérents

### ⚠️ Améliorations possibles (non critiques) :
- Synchroniser les tracés entre les deux systèmes
- Animations de transition entre états
- Feedback haptique sur les boutons
- Toast de confirmation
- Meilleure gestion des erreurs utilisateur

---

## 🎬 Scénario complet de bout en bout

**Durée estimée :** 5 minutes

1. **Lancer l'app** → Écran d'accueil
2. **Sélectionner une squad** → Voir la liste des sessions
3. **Créer une nouvelle session** → Sheet de création
4. **Remplir le formulaire** → Titre, type, distance
5. **Confirmer** → Session créée, retour à la carte
6. **Observer** → Overlay apparaît automatiquement
7. **Vérifier** → Badge "En cours", bouton "Pause" visible
8. **Attendre 30s** → Points GPS ajoutés, tracé visible
9. **Cliquer "Pause"** → Badge passe à "En pause"
10. **Attendre 10s** → Pas de nouveaux points
11. **Cliquer "Reprendre"** → Badge repasse à "En cours"
12. **Attendre 20s** → Nouveaux points ajoutés
13. **Cliquer "Stop"** → Alerte de confirmation
14. **Confirmer** → Badge "Arrêt...", puis overlay disparaît
15. **Vérifier** → État "Aucune session active"

**Résultat attendu :** Tout fonctionne sans crash, états cohérents, logs propres

---

## 🔍 Logs à surveiller

### ✅ Logs normaux
```
🎯 TrackingManager initialisé
🚀 Demande de démarrage tracking pour session: abc123
✅ Tracking démarré
📍 Point GPS ajouté: (48.123, 2.456)
⏸️  Tracking mis en pause
▶️  Tracking repris
🔴 stopTrackingAndEndSession() appelé
✅✅ Session complètement terminée
```

### ⚠️ Logs suspects
```
⚠️ Impossible de démarrer : tracking déjà actif
❌ Session ID manquant
❌ User ID manquant
⚠️ Déjà en cours de terminaison, ignoré
```

### 🚨 Logs d'erreur
```
❌ Erreur: [description]
💥 Crash: [stack trace]
🔥 Firebase error: [code]
```

---

## 📞 En cas de problème

### Si le test échoue :
1. Lire attentivement les logs
2. Identifier quelle étape échoue
3. Consulter la section "Problèmes connus"
4. Ajouter des logs supplémentaires pour debug
5. Vérifier les fichiers modifiés

### Fichiers à vérifier :
- `SessionActiveOverlay.swift` ← Modifications principales
- `SessionTrackingControlsView.swift` ← Composant utilisé
- `TrackingManager.swift` ← Logique de tracking
- `SessionsViewModel.swift` ← Gestion de session

### Logs de debug à ajouter :
```swift
// Dans SessionActiveOverlay.onAppear
print("🔍 Session: \(session.id ?? "nil")")
print("🔍 TrackingState: \(trackingManager.trackingState)")
print("🔍 ActiveSession: \(trackingManager.activeTrackingSession?.id ?? "nil")")

// Dans stopTrackingAndEndSession
print("🔍 Step 1: Stopping tracking...")
print("🔍 Step 2: Waiting...")
print("🔍 Step 3: Ending session...")
```

---

## ✨ Checklist finale

- [ ] Compilation OK
- [ ] Démarrage auto OK
- [ ] Bouton Pause fonctionne
- [ ] Bouton Reprendre fonctionne
- [ ] Bouton Stop fonctionne
- [ ] États visuels OK
- [ ] Participants visibles
- [ ] Tracé GPS visible
- [ ] Pas de crash
- [ ] Logs cohérents

**Si tous les tests passent → 🎉 Option A implémentée avec succès !**
