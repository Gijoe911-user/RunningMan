# 🧪 Guide de Test - ActiveSessionDetailView

> **Objectif :** Valider toutes les fonctionnalités de la vue de session active

---

## 📋 Pré-requis

Avant de commencer les tests :

- [ ] Firebase configuré et accessible
- [ ] Permissions GPS accordées
- [ ] Compte utilisateur connecté
- [ ] Au moins une squad créée
- [ ] Appareil avec GPS (réel ou simulé)

---

## ✅ Tests Fonctionnels

### 1️⃣ Affichage Initial

**Objectif :** Vérifier que la vue se charge correctement

**Étapes :**
1. Créer une session depuis SquadDetailView
2. Accéder à ActiveSessionDetailView

**Résultat attendu :**
- ✅ Carte visible avec marker de l'utilisateur
- ✅ Statut "🟢 En direct" affiché
- ✅ Timer démarre à 00:00
- ✅ Distance à 0.00 km
- ✅ Participants : 1 (vous)

---

### 2️⃣ Timer en Temps Réel

**Objectif :** Valider le compteur de durée

**Étapes :**
1. Observer le timer pendant 1 minute
2. Vérifier que les secondes s'incrémentent

**Résultat attendu :**
- ✅ Le timer se met à jour chaque seconde
- ✅ Format MM:SS affiché correctement
- ✅ Pas de décalage visuel des chiffres (grâce à `.monospacedDigit()`)
- ✅ Après 60 secondes, affiche "01:00"

**Capture d'écran :**
```
DURÉE
01:23
```

---

### 3️⃣ Tracé GPS

**Objectif :** Vérifier l'enregistrement et l'affichage du parcours

**Étapes :**
1. Démarrer une session
2. Se déplacer (réellement ou simuler dans Xcode)
3. Observer la carte

**Résultat attendu :**
- ✅ Ligne bleue/rouge visible sur la carte
- ✅ La ligne suit votre déplacement
- ✅ Points GPS ajoutés automatiquement
- ✅ Logs : "📍 Route: 10 points" tous les 10 points

**Debug :**
```swift
// Dans la console
📍 Route: 10 points
📍 Route: 20 points
📍 Route: 30 points
```

---

### 4️⃣ Bouton de Recentrage

**Objectif :** Tester le recentrage sur l'utilisateur

**Étapes :**
1. Déplacer la carte manuellement (pincer/glisser)
2. Taper sur le bouton 🎯 en bas à droite

**Résultat attendu :**
- ✅ La carte se recentre sur votre position avec animation
- ✅ Feedback haptique ressenti
- ✅ Log : "🎯 Recentrage sur l'utilisateur"

---

### 5️⃣ Pause de Session (Créateur seulement)

**Objectif :** Tester la mise en pause

**Étapes :**
1. En tant que créateur, taper sur ⏸️
2. Confirmer la pause
3. Observer les changements

**Résultat attendu :**
- ✅ Alerte de confirmation affichée
- ✅ Statut passe à "🟠 En pause"
- ✅ Bouton ⏸️ remplacé par ▶️
- ✅ Timer continue de tourner (ou se fige selon votre logique)
- ✅ Log : "⏸️ Session mise en pause"

**Capture après pause :**
```
🟠 En pause
▶️ [Reprendre]  🛑 [Terminer]
```

---

### 6️⃣ Reprise de Session

**Objectif :** Tester la reprise après pause

**Étapes :**
1. Session en pause
2. Taper sur ▶️ (Reprendre)
3. Observer le retour à l'état actif

**Résultat attendu :**
- ✅ Statut repasse à "🟢 En direct"
- ✅ Bouton ▶️ redevient ⏸️
- ✅ Timer continue
- ✅ Log : "▶️ Session reprise"

---

### 7️⃣ Fin de Session

**Objectif :** Tester la terminaison de la session

**Étapes :**
1. Taper sur "Terminer"
2. Confirmer la fin
3. Observer les actions

**Résultat attendu :**
- ✅ Alerte de confirmation affichée
- ✅ Après confirmation, retour à l'écran précédent
- ✅ Tracé GPS sauvegardé automatiquement
- ✅ Session dans Firestore a `status: "ENDED"`
- ✅ Log : "✅ Session terminée"
- ✅ Log : "💾 Tracé sauvegardé automatiquement"

**Vérification Firestore :**
```json
{
  "status": "ENDED",
  "endedAt": "2025-12-28T15:30:00Z",
  "durationSeconds": 1800
}
```

---

### 8️⃣ Rafraîchissement des Stats

**Objectif :** Vérifier que les stats se mettent à jour

**Étapes :**
1. Session active avec plusieurs participants
2. Un autre participant se déplace
3. Observer les mises à jour

**Résultat attendu :**
- ✅ Distance totale se met à jour
- ✅ Vitesse moyenne recalculée
- ✅ Nombre de participants actualisé
- ✅ Log : "🔄 Session rafraîchie"

---

### 9️⃣ Gestion d'Erreurs

**Objectif :** Tester l'affichage des erreurs

**Étapes :**
1. Désactiver le réseau (mode avion)
2. Tenter de mettre en pause
3. Observer l'alerte d'erreur

**Résultat attendu :**
- ✅ Alerte "Erreur" affichée
- ✅ Message : "Impossible de mettre en pause"
- ✅ Bouton "OK" pour fermer
- ✅ Log : "❌ Error: ..."

**Capture d'erreur :**
```
⚠️ Erreur
Impossible de mettre en pause

[OK]
```

---

### 🔟 Participants en Temps Réel

**Objectif :** Voir les autres coureurs sur la carte

**Étapes :**
1. Avoir 2+ participants dans la session
2. Observer la carte et la liste

**Résultat attendu :**
- ✅ Markers des autres coureurs visibles
- ✅ Noms affichés sur les markers
- ✅ Liste des participants en bas
- ✅ Avatar + nom + statut "🟢 actif"
- ✅ Position mise à jour en temps réel

---

## 🎨 Tests UI/UX

### Animations

**À vérifier :**
- ✅ Transition fluide lors du recentrage
- ✅ Changement de couleur du statut smooth
- ✅ Barre de progression animée

### Responsive

**À vérifier :**
- ✅ Sur iPhone SE (petit écran)
- ✅ Sur iPhone 15 Pro Max (grand écran)
- ✅ En mode paysage
- ✅ Avec Dynamic Type (grande police)

### Dark Mode

**À vérifier :**
- ✅ Lisibilité en mode sombre
- ✅ Contraste suffisant
- ✅ Couleurs cohérentes

---

## 🐛 Tests Edge Cases

### 1. Session sans objectif de distance

**Test :**
- Créer une session sans `targetDistanceMeters`

**Résultat attendu :**
- ✅ Pas de barre de progression affichée
- ✅ Pas d'erreur de crash

### 2. Session avec 0 participants

**Test :**
- Simuler une session vide (tous sont partis)

**Résultat attendu :**
- ✅ Affiche "Coureurs: 0"
- ✅ Pas de crash

### 3. GPS désactivé

**Test :**
- Désactiver les permissions GPS

**Résultat attendu :**
- ✅ Alerte de permission GPS
- ✅ Carte affichée mais pas de marker utilisateur
- ✅ Pas de crash

### 4. Session déjà terminée

**Test :**
- Accéder à une session avec `status: "ENDED"`

**Résultat attendu :**
- ✅ Statut "🔴 Terminée" affiché
- ✅ Boutons de contrôle masqués
- ✅ Tracé GPS affiché (historique)

### 5. Longue session (>1h)

**Test :**
- Session de plus de 60 minutes

**Résultat attendu :**
- ✅ Timer passe en format HH:MM:SS
- ✅ Affiche "01:23:45" correctement
- ✅ Pas de problème de mémoire avec le tracé

---

## 🔥 Tests de Performance

### Mémoire

**Vérifier dans Xcode Instruments :**
- ✅ Pas de fuites mémoire
- ✅ Tracé GPS ne consomme pas trop de RAM
- ✅ `cancellables` bien nettoyés dans `deinit`

### Batterie

**Observer :**
- ✅ GPS ne draine pas excessivement la batterie
- ✅ Mises à jour de position raisonnables (pas trop fréquentes)

### Réseau

**Vérifier :**
- ✅ Pas trop de requêtes Firestore
- ✅ Stream temps réel optimisé
- ✅ Lectures Firestore raisonnables

---

## 📊 Métriques de Succès

### Objectifs :

- ✅ 0 crash lors des tests
- ✅ Temps de chargement < 2 secondes
- ✅ FPS stable à 60 sur iPhone récent
- ✅ Consommation batterie < 20% par heure
- ✅ 100% des fonctionnalités opérationnelles

---

## 🎯 Checklist Finale

Avant de déployer en production :

- [ ] Tous les tests fonctionnels passés
- [ ] Tests UI/UX validés
- [ ] Tests edge cases couverts
- [ ] Performance acceptable
- [ ] Code review effectuée
- [ ] Logs de debug retirés ou mis en mode production
- [ ] Documentation à jour

---

## 🚨 Cas de Bugs Connus

### Bug potentiel 1 : Timer continue après dismiss

**Symptôme :** Timer continue de tourner en arrière-plan

**Solution :**
```swift
.onDisappear {
    durationTimer.upstream.connect().cancel() // ⚠️ À vérifier
    viewModel.stopObserving()
}
```

### Bug potentiel 2 : Tracé GPS trop volumineux

**Symptôme :** Crash ou lenteur après 1000+ points

**Solution :**
- Limiter à 1000 points max
- Ou simplifier le tracé avec un algorithme de décimation

---

## 📝 Notes de Test

**Testeur :** _______________  
**Date :** _______________  
**Appareil :** _______________  
**Version iOS :** _______________

### Bugs trouvés :
- 
- 
- 

### Suggestions d'amélioration :
- 
- 
- 

---

**Fin du guide de test** ✅
