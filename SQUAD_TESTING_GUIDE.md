# 🧪 Guide de Test : Fonctionnalités Squads

**Date :** 27 Décembre 2025  
**Objectif :** Valider toutes les fonctionnalités liées aux Squads

---

## 📋 Prérequis

- ✅ Firebase configuré et fonctionnel
- ✅ Application lancée avec succès
- ✅ Accès à 2 devices/simulateurs (ou 2 comptes sur le même device)

---

## 🎯 Test 1 : Créer une Squad

### Étapes
1. Lancer l'app
2. Se connecter avec un compte (ou créer un nouveau compte)
   - Email : `testA@runningman.com`
   - Password : `password123`
   - Nom : `Coureur A`
3. Aller dans l'onglet **Squads**
4. Taper sur **"Créer"**
5. Remplir le formulaire :
   - Nom : `Test Marathon 2025`
   - Description : `Préparation pour le marathon de Paris`
6. Taper sur **"Créer la Squad"**

### ✅ Résultat Attendu
- ✅ Message de succès affiché
- ✅ Code d'invitation généré (6 caractères, ex: `ABC123`)
- ✅ Squad apparaît dans la liste des squads
- ✅ Badge "Actif" sur la nouvelle squad
- ✅ Dans Firestore : nouveau document dans `squads/`
- ✅ Dans Firestore : `members` contient l'ID de Coureur A avec rôle `admin`

### 📝 Notes
- **Noter le code d'invitation** pour Test 2
- Code affiché dans le message de succès

---

## 🎯 Test 2 : Rejoindre une Squad

### Étapes
1. **Option A : Nouveau Device/Simulateur**
   - Lancer l'app sur un 2e device
   - Se connecter avec un autre compte :
     - Email : `testB@runningman.com`
     - Password : `password123`
     - Nom : `Coureur B`

2. **Option B : Même Device**
   - Se déconnecter (Profil → Déconnexion)
   - Créer un nouveau compte avec les infos ci-dessus

3. Aller dans l'onglet **Squads**
4. Taper sur **"Rejoindre"**
5. Entrer le **code d'invitation** noté au Test 1
6. Taper sur **"Rejoindre le Squad"**

### ✅ Résultat Attendu
- ✅ Écran de succès "Bienvenue ! 🎉"
- ✅ Message "Vous avez rejoint Test Marathon 2025"
- ✅ Squad apparaît dans la liste de Coureur B
- ✅ Dans Firestore : `members` contient maintenant 2 userIds
  - Coureur A : `admin`
  - Coureur B : `member`

### ❌ Test des Erreurs
1. **Code invalide**
   - Entrer `XXXXXX` → Erreur "Code d'invitation invalide"
2. **Code déjà utilisé**
   - Coureur B essaie de rejoindre 2x → Erreur "Vous êtes déjà membre"

---

## 🎯 Test 3 : Afficher le Détail d'une Squad

### Étapes (Coureur A ou B)
1. Aller dans l'onglet **Squads**
2. Taper sur la card de la squad **Test Marathon 2025**

### ✅ Résultat Attendu
- ✅ Header affiche le nom et la description
- ✅ Nombre de membres : **2 membres**
- ✅ Code d'invitation visible et copiable
- ✅ Bouton **"Partager"** présent
- ✅ Section **Membres** affiche :
  - Coureur A (Admin • Créateur)
  - Coureur B (Membre)
- ✅ **Pour Coureur A** : Bouton "Démarrer une session" visible
- ✅ **Pour Coureur B** : Bouton "Quitter la squad" visible

---

## 🎯 Test 4 : Copier le Code d'Invitation

### Étapes (n'importe quel membre)
1. Ouvrir la vue détail de la squad
2. Taper sur le bouton **"Copier"** à côté du code

### ✅ Résultat Attendu
- ✅ Feedback haptic
- ✅ Bouton change en "✓ Copié" en vert
- ✅ Après 2 secondes, retour à l'état normal
- ✅ Code dans le presse-papier

**Vérification :**
- Aller dans Notes/Messages
- Coller → Le code doit apparaître

---

## 🎯 Test 5 : Partager le Code

### Étapes
1. Ouvrir la vue détail de la squad
2. Taper sur **"Partager"**

### ✅ Résultat Attendu
- ✅ Sheet iOS natif `UIActivityViewController`
- ✅ Texte préformaté visible :
  ```
  Rejoins mon squad 'Test Marathon 2025' sur RunningMan ! 🏃
  Code d'invitation : ABC123
  ```
- ✅ Options de partage : Messages, Mail, AirDrop, etc.

---

## 🎯 Test 6 : Quitter une Squad (Membre)

### Étapes (Coureur B uniquement)
1. Ouvrir la vue détail de la squad
2. Taper sur **"Quitter la squad"** (bouton rouge en bas)
3. Confirmer dans l'alerte

### ✅ Résultat Attendu
- ✅ Alerte de confirmation affichée
- ✅ Après confirmation :
  - Squad disparaît de la liste de Coureur B
  - Vue revient automatiquement à la liste
- ✅ Dans Firestore : `members` ne contient plus l'ID de Coureur B
- ✅ **Pour Coureur A** : Rafraîchir la vue détail → Coureur B n'apparaît plus

---

## 🎯 Test 7 : Empêcher le Créateur de Quitter

### Étapes (Coureur A uniquement)
1. Ouvrir la vue détail de la squad
2. **Observer** : Pas de bouton "Quitter la squad"

### ✅ Résultat Attendu
- ✅ Coureur A (créateur) ne voit **pas** le bouton "Quitter"
- ✅ Seul le bouton "Démarrer une session" est visible

### 📝 Cas Spécial
Si Coureur A essaie de quitter via le service directement :
```swift
// Dans SquadService.leaveSquad()
if squad.creatorId == userId && squad.memberCount > 1 {
    throw SquadError.creatorCannotLeave
}
```
→ Erreur "Le créateur ne peut pas quitter tant qu'il y a des membres"

---

## 🎯 Test 8 : Rafraîchir la Liste (Pull to Refresh)

### Étapes
1. Aller dans l'onglet **Squads**
2. Tirer vers le bas (pull to refresh)

### ✅ Résultat Attendu
- ✅ Indicateur de chargement affiché
- ✅ Liste rechargée depuis Firestore
- ✅ Nouvelles squads apparaissent (si ajoutées depuis un autre device)

---

## 🎯 Test 9 : Sélectionner une Squad Active

### Étapes
1. Créer ou rejoindre plusieurs squads
2. Dans la liste, taper sur **"Activer"** d'une squad
3. Observer le changement visuel

### ✅ Résultat Attendu
- ✅ Badge "Actif" apparaît sur la squad sélectionnée
- ✅ Bordure verte autour de la card
- ✅ Icône ✓ en haut à droite de l'avatar
- ✅ Gradient vert/bleu au lieu de corail/rose

---

## 🎯 Test 10 : État Vide (Aucune Squad)

### Étapes
1. Se déconnecter
2. Créer un nouveau compte : `testC@runningman.com`
3. Aller dans l'onglet **Squads**

### ✅ Résultat Attendu
- ✅ Message "Aucun squad"
- ✅ Description "Créez ou rejoignez un squad pour commencer"
- ✅ Icône `person.3.slash` en gris
- ✅ Boutons "Créer" et "Rejoindre" toujours visibles

---

## 🎯 Test 11 : Permissions Créer Session

### Étapes
1. **Coureur A (Admin)** :
   - Ouvrir détail squad
   - Observer bouton **"Démarrer une session"** → ✅ Visible

2. **Coureur B (Membre)** :
   - Ouvrir détail squad
   - Observer bouton **"Démarrer une session"** → ❌ Pas visible

### ✅ Résultat Attendu
- ✅ Seuls les **admins** et **coachs** voient le bouton
- ✅ Les membres normaux ne le voient pas

---

## 🎯 Test 12 : Chargement Asynchrone des Noms

### Étapes
1. Ouvrir la vue détail d'une squad avec plusieurs membres
2. Observer la section **Membres**

### ✅ Résultat Attendu
- ✅ Initialement : "Chargement..."
- ✅ Après ~1s : Noms réels affichés (ex: "Coureur A", "Coureur B")
- ✅ Si erreur : "Utilisateur #abc123" (6 premiers caractères de l'ID)

---

## 🎯 Test 13 : Affichage des Rôles

### Étapes
1. Ouvrir la vue détail de la squad
2. Observer la section **Membres**

### ✅ Résultat Attendu

**Pour Coureur A :**
- ✅ Icône : étoile orange
- ✅ Label : "Admin • Créateur"
- ✅ Couleur : corail

**Pour Coureur B :**
- ✅ Icône : personne bleue
- ✅ Label : "Membre"
- ✅ Couleur : bleu

---

## 📊 Récapitulatif des Tests

| # | Test | Statut | Notes |
|---|------|--------|-------|
| 1 | Créer une squad | ⏳ À tester | |
| 2 | Rejoindre une squad | ⏳ À tester | |
| 3 | Afficher détail | ⏳ À tester | |
| 4 | Copier code | ⏳ À tester | |
| 5 | Partager code | ⏳ À tester | |
| 6 | Quitter (membre) | ⏳ À tester | |
| 7 | Empêcher quitter (créateur) | ⏳ À tester | |
| 8 | Pull to refresh | ⏳ À tester | |
| 9 | Sélectionner squad | ⏳ À tester | |
| 10 | État vide | ⏳ À tester | |
| 11 | Permissions session | ⏳ À tester | |
| 12 | Chargement noms | ⏳ À tester | |
| 13 | Affichage rôles | ⏳ À tester | |

---

## 🐛 Bugs Connus à Vérifier

### 1. Refresh Automatique après Join
**Problème potentiel :** Après avoir rejoint une squad, la liste ne se rafraîchit pas automatiquement chez Coureur A

**Vérification :**
1. Coureur B rejoint la squad
2. Coureur A reste sur la vue détail
3. Est-ce que Coureur B apparaît automatiquement ?

**Si non :** Besoin d'ajouter un Firestore listener temps réel

---

### 2. Suppression de Squad Vide
**Problème potentiel :** Si Coureur A (créateur) est seul et quitte, que se passe-t-il ?

**Vérification :**
1. Coureur A crée une squad
2. Ne pas inviter personne
3. Essayer de quitter

**Résultat attendu :**
- ✅ Squad supprimée de Firestore
- ✅ Code dans `SquadService.leaveSquad()` :
  ```swift
  if squad.members.isEmpty {
      try await deleteSquad(squadId: squadId)
  }
  ```

---

### 3. Plusieurs Squads Actives
**Problème potentiel :** Peut-on activer plusieurs squads en même temps ?

**Vérification :**
1. Créer/rejoindre 2 squads
2. Activer la première
3. Activer la seconde
4. Vérifier si la première est désactivée

**Résultat attendu :**
- ✅ Une seule squad active à la fois
- ✅ `SquadViewModel.selectedSquad` contient une seule référence

---

## 🎓 Conseils de Test

### Outils de Debug
```swift
// Dans SquadViewModel ou SquadService
print("🔍 [DEBUG] Current squads: \(userSquads.map { $0.name })")
print("🔍 [DEBUG] Selected squad: \(selectedSquad?.name ?? "none")")
```

### Firebase Console
1. Ouvrir [console.firebase.google.com](https://console.firebase.google.com)
2. Aller dans **Firestore Database**
3. Observer les collections en temps réel pendant les tests :
   - `users/` → Vérifier `squadIds`
   - `squads/` → Vérifier `members`, `inviteCode`

### Simulateur Multiple (Mac uniquement)
```bash
# Lancer 2 simulateurs en même temps
xcrun simctl boot "iPhone 15"
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator
```

---

## ✅ Validation Finale

Après avoir complété tous les tests ci-dessus, vous devriez pouvoir :

- ✅ Créer des squads
- ✅ Générer des codes uniques
- ✅ Rejoindre avec un code
- ✅ Afficher les membres avec leurs rôles
- ✅ Quitter une squad
- ✅ Partager l'invitation
- ✅ Gérer les permissions
- ✅ Synchroniser avec Firestore

---

## 🚀 Prochaine Étape

Une fois tous ces tests passés, vous pourrez passer à :
- **Sessions de Course** (créer, démarrer, terminer)
- **Tracking GPS** (positions temps réel)
- **Messages** (communication entre coureurs)

---

**Bonne chance pour les tests ! 🎉**

Si vous rencontrez un bug, notez-le dans ce fichier avec la section "🐛 Bug Découvert" et les étapes de reproduction.
