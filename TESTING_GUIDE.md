# 🧪 Guide de Test : AutoFill & Face ID

Ce guide vous accompagne pour tester toutes les fonctionnalités d'AutoFill et de Face ID dans RunningMan.

---

## 📱 Prérequis

### Sur Simulateur
- ✅ iOS 12+ 
- ✅ Face ID activé : Features → Face ID → Enrolled
- ✅ Connexion internet (Firebase)

### Sur Appareil Réel
- ✅ iOS 12+
- ✅ Face ID ou Touch ID configuré
- ✅ iCloud Keychain activé (Réglages → [Votre nom] → iCloud → Mots de passe et trousseau)

---

## 🧪 Scénarios de Test

### Test 1 : Sauvegarde d'un mot de passe (Inscription)

**Objectif :** Vérifier que iOS propose de sauvegarder le mot de passe lors de l'inscription.

**Étapes :**
1. Lancez l'app
2. Basculez sur l'onglet **"Inscription"**
3. Remplissez :
   - Nom d'affichage : `Test User`
   - Email : `test1@example.com`
   - Mot de passe : `Test1234!`
4. Appuyez sur **"S'inscrire"**
5. **Attendez la connexion à Firebase**

**Résultat attendu :**
```
┌──────────────────────────────────────────┐
│  🔑 Enregistrer le mot de passe ?       │
│                                          │
│  Pour test1@example.com                 │
│  dans RunningMan                         │
│                                          │
│  [Jamais pour ce site]   [Enregistrer] │
└──────────────────────────────────────────┘
```

**Actions :**
- ✅ Appuyez sur **"Enregistrer"**

**Notes :**
- La bannière peut apparaître en haut de l'écran
- Si elle n'apparaît pas, essayez 2-3 fois
- Sur simulateur, parfois capricieux

---

### Test 2 : Sauvegarde d'un mot de passe (Connexion)

**Objectif :** Vérifier la sauvegarde lors d'une connexion avec un compte existant.

**Étapes :**
1. Lancez l'app
2. Restez sur l'onglet **"Connexion"**
3. Remplissez :
   - Email : `existing@example.com`
   - Mot de passe : `YourPassword123`
4. Appuyez sur **"Se connecter"**

**Résultat attendu :**
- Bannière "Enregistrer le mot de passe ?" après connexion réussie

**Actions :**
- ✅ Appuyez sur **"Enregistrer"**

---

### Test 3 : AutoFill - Récupération simple

**Objectif :** Vérifier que iOS suggère automatiquement les identifiants.

**Prérequis :**
- ✅ Avoir réussi le Test 1 ou Test 2

**Étapes :**
1. Déconnectez-vous de l'app (si nécessaire)
2. Revenez à l'écran de connexion
3. **Touchez le champ Email** (important : touchez, pas juste regarder)
4. Observez la barre au-dessus du clavier

**Résultat attendu :**
```
┌─────────────────────────────────────────────┐
│  🔑  test1@example.com               ▼    │  ← Touchez ici
└─────────────────────────────────────────────┘
│  Q  W  E  R  T  Y  U  I  O  P            │
│   A  S  D  F  G  H  J  K  L              │
└─────────────────────────────────────────────┘
```

**Actions :**
1. ✅ Appuyez sur la suggestion `🔑 test1@example.com`
2. ✅ Vérifiez que les deux champs sont remplis automatiquement
3. ✅ Appuyez sur "Se connecter"

**Notes :**
- Si vous ne voyez pas la suggestion, touchez aussi le champ Mot de passe
- La suggestion peut prendre 1-2 secondes à apparaître

---

### Test 4 : AutoFill - Plusieurs comptes

**Objectif :** Tester avec plusieurs comptes sauvegardés.

**Étapes :**
1. Créez 2-3 comptes différents (suivez Test 1 pour chaque)
2. Déconnectez-vous
3. À l'écran de connexion, touchez le champ Email
4. Appuyez sur la flèche **▼** dans la barre de suggestion

**Résultat attendu :**
```
┌─────────────────────────────────────┐
│  Mots de passe                      │
├─────────────────────────────────────┤
│  🔑  test1@example.com             │
│  🔑  test2@example.com             │
│  🔑  user@runningman.com           │
├─────────────────────────────────────┤
│  ⚙️  Gérer les mots de passe       │
└─────────────────────────────────────┘
```

**Actions :**
1. ✅ Sélectionnez différents comptes
2. ✅ Vérifiez que les champs changent correctement
3. ✅ Connectez-vous avec chacun

---

### Test 5 : Vérification dans Réglages

**Objectif :** Confirmer que les mots de passe sont bien sauvegardés dans iCloud Keychain.

**Étapes :**
1. Ouvrez **Réglages** (app Réglages iOS)
2. Allez dans **Mots de passe**
3. Authentifiez-vous avec Face ID / Touch ID
4. Dans la barre de recherche, tapez "localhost" ou "runningman"

**Résultat attendu :**
```
┌────────────────────────────────────┐
│  Mots de passe                     │
│                                    │
│  🔍 localhost                      │
│                                    │
│  localhost                         │
│  test1@example.com                │
│  test2@example.com                │
└────────────────────────────────────┘
```

**Actions :**
1. ✅ Touchez un identifiant
2. ✅ Vérifiez les informations :
   - Site web : localhost (ou votre domaine)
   - Nom d'utilisateur : votre email
   - Mot de passe : (masqué par défaut)
3. ✅ Touchez "Mot de passe" pour le révéler

---

### Test 6 : Face ID - Configuration

**Objectif :** Vérifier que Face ID est disponible et configuré.

**Sur Simulateur :**
1. Menu : **Features** → **Face ID**
2. Vérifiez que **"Enrolled"** est coché
3. Si non coché, cliquez dessus

**Sur Appareil Réel :**
1. Réglages → Face ID et code
2. Vérifiez qu'au moins une option est activée
3. Si besoin, configurez Face ID

**Résultat attendu :**
- ✅ Face ID opérationnel

---

### Test 7 : Face ID - Authentification Réussie

**Prérequis :**
- ✅ Face ID configuré (Test 6)
- ✅ Identifiants sauvegardés (Test 1)
- ✅ Bouton "Connexion rapide" implémenté dans LoginView

**Étapes :**
1. Lancez l'app
2. À l'écran de connexion, cherchez le bouton **"Connexion rapide"** ou **"Face ID"**
3. Appuyez sur le bouton
4. **Sur simulateur :** Immédiatement après, menu Features → Face ID → **Matching Face**
5. **Sur appareil réel :** Regardez l'écran normalement

**Résultat attendu :**

Sur simulateur :
```
┌────────────────────────────────────────┐
│                                        │
│         Face ID                        │
│                                        │
│  RunningMan utilise Face ID pour une   │
│  connexion rapide et sécurisée         │
│                                        │
│         [Annuler]                      │
└────────────────────────────────────────┘
```

Après matching :
- ✅ L'app se connecte automatiquement
- ✅ Vous accédez à l'écran principal

---

### Test 8 : Face ID - Authentification Échouée

**Objectif :** Tester la gestion d'erreur quand Face ID échoue.

**Étapes :**
1. Suivez Test 7 jusqu'à l'étape 3
2. **Sur simulateur :** Menu Features → Face ID → **Non-matching Face**
3. **Sur appareil réel :** Détournez le regard ou couvrez la caméra

**Résultat attendu :**
```
┌────────────────────────────────────────┐
│         Erreur                         │
│                                        │
│  L'authentification a échoué           │
│                                        │
│         [OK]                           │
└────────────────────────────────────────┘
```

**Actions :**
- ✅ Appuyez sur OK
- ✅ Vérifiez que vous restez sur l'écran de connexion
- ✅ Vous pouvez vous connecter manuellement

---

### Test 9 : Face ID - Annulation

**Objectif :** Tester quand l'utilisateur annule Face ID.

**Étapes :**
1. Appuyez sur le bouton "Connexion rapide"
2. Quand Face ID apparaît, appuyez sur **"Annuler"**

**Résultat attendu :**
- ✅ Retour à l'écran de connexion
- ✅ Aucune erreur affichée (ou message neutre)
- ✅ Possibilité de réessayer

---

### Test 10 : Keychain - Pré-remplissage Email

**Objectif :** Vérifier que l'email est pré-rempli au lancement.

**Prérequis :**
- ✅ Code de pré-remplissage implémenté dans LoginView

**Étapes :**
1. Connectez-vous une fois avec `signInAndSave`
2. Déconnectez-vous
3. **Fermez complètement l'app** (swipe up)
4. Relancez l'app

**Résultat attendu :**
- ✅ Champ Email pré-rempli avec votre dernière adresse
- ✅ Champ Mot de passe VIDE (important pour la sécurité)

---

### Test 11 : Déconnexion avec suppression Keychain

**Objectif :** Vérifier que les identifiants peuvent être supprimés du Keychain.

**Étapes :**
1. Connectez-vous
2. Allez dans Paramètres (si implémenté) ou modifiez temporairement :
   ```swift
   Button("Déconnexion et oublier") {
       authVM.signOutAndDelete(deleteFromKeychain: true)
   }
   ```
3. Appuyez sur le bouton

**Résultat attendu :**
- ✅ Déconnexion réussie
- ✅ Retour à l'écran de connexion
- ✅ Champ Email VIDE (non pré-rempli)
- ✅ Pas de suggestion AutoFill au toucher des champs

**Vérification supplémentaire :**
1. Ouvrez Réglages → Mots de passe
2. ✅ L'identifiant n'apparaît plus dans la liste

---

## 🐛 Tests de Robustesse

### Test 12 : Sans connexion Internet

**Étapes :**
1. Activez le mode Avion
2. Essayez de vous connecter avec Face ID

**Résultat attendu :**
- ✅ Face ID s'active
- ✅ Après authentification, erreur réseau affichée
- ✅ Message clair : "Vérifiez votre connexion"

---

### Test 13 : Face ID non configuré

**Étapes :**
1. Sur simulateur : Features → Face ID → décochez "Enrolled"
2. Relancez l'app

**Résultat attendu :**
- ✅ Le bouton "Connexion rapide" N'APPARAÎT PAS
- ✅ Seulement le formulaire classique

**Code responsable :**
```swift
if BiometricAuthHelper.shared.isBiometricAvailable() {
    // Afficher le bouton
}
```

---

### Test 14 : Mots de passe différents

**Objectif :** Tester quand l'utilisateur change son mot de passe.

**Étapes :**
1. Connectez-vous avec `test@example.com` / `OldPassword123`
2. iOS sauvegarde ce mot de passe
3. Sur le backend/Firebase, changez le mot de passe en `NewPassword456`
4. Essayez de vous connecter avec AutoFill (qui suggère l'ancien mot de passe)

**Résultat attendu :**
- ✅ Erreur : "Mot de passe incorrect"
- ✅ L'utilisateur peut saisir le nouveau
- ✅ Après connexion réussie, iOS propose : "Mettre à jour le mot de passe ?"
- ✅ Si accepté, l'ancien est remplacé

---

### Test 15 : Multiple devices (iCloud Sync)

**Objectif :** Vérifier la synchronisation iCloud Keychain entre appareils.

**Prérequis :**
- 2 appareils connectés au même compte iCloud
- iCloud Keychain activé sur les deux

**Étapes :**
1. **Appareil 1 :** Connectez-vous et sauvegardez le mot de passe
2. **Attendez 1-2 minutes** (synchronisation iCloud)
3. **Appareil 2 :** Lancez l'app
4. Touchez le champ de connexion

**Résultat attendu :**
- ✅ Le mot de passe est suggéré automatiquement sur Appareil 2
- ✅ Connexion possible sans re-saisir

**Note :** La synchronisation peut prendre quelques minutes.

---

## 📊 Checklist Complète

### AutoFill
- [ ] Test 1 : Sauvegarde à l'inscription
- [ ] Test 2 : Sauvegarde à la connexion
- [ ] Test 3 : AutoFill simple
- [ ] Test 4 : AutoFill multi-comptes
- [ ] Test 5 : Vérification Réglages
- [ ] Test 14 : Changement de mot de passe

### Face ID
- [ ] Test 6 : Configuration
- [ ] Test 7 : Authentification réussie
- [ ] Test 8 : Authentification échouée
- [ ] Test 9 : Annulation
- [ ] Test 13 : Face ID non configuré

### Keychain
- [ ] Test 10 : Pré-remplissage email
- [ ] Test 11 : Suppression Keychain
- [ ] Test 15 : Synchronisation iCloud

### Robustesse
- [ ] Test 12 : Sans connexion
- [ ] Test 14 : Mots de passe différents

---

## 🎯 Résultats Attendus Globaux

### ✅ Tous les tests réussis = Configuration parfaite !

Votre app offre :
- 🔐 Sauvegarde automatique et sécurisée des mots de passe
- ⚡ Connexion en 2 secondes avec AutoFill
- 👁️ Connexion instantanée avec Face ID
- ☁️ Synchronisation entre tous les appareils
- 🛡️ Gestion d'erreur robuste

### ⚠️ Quelques tests échouent ?

Consultez la section Dépannage dans `AutoFill_Configuration_Visuelle.md`.

---

## 📝 Rapport de Test (Template)

```markdown
# Rapport de Test - AutoFill & Face ID

**Date :** _______________
**Appareil/Simulateur :** _______________
**iOS Version :** _______________

## AutoFill
- [ ] Sauvegarde inscription : ✅ / ❌
- [ ] Sauvegarde connexion : ✅ / ❌
- [ ] Suggestion AutoFill : ✅ / ❌
- [ ] Multi-comptes : ✅ / ❌

## Face ID
- [ ] Authentification réussie : ✅ / ❌
- [ ] Gestion d'erreur : ✅ / ❌
- [ ] Annulation : ✅ / ❌

## Keychain
- [ ] Pré-remplissage : ✅ / ❌
- [ ] Suppression : ✅ / ❌

## Notes
_______________________________________________
_______________________________________________

## Problèmes Rencontrés
_______________________________________________
_______________________________________________
```

---

**🎉 Bon test !**
