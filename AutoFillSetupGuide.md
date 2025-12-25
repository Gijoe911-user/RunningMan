# Guide : Configuration AutoFill pour RunningMan

Ce guide vous explique comment configurer votre projet Xcode pour que l'application **Mots de passe** d'Apple reconnaisse et sauvegarde automatiquement les identifiants de connexion.

## ✅ Ce qui est déjà fait dans le code

Le code SwiftUI a été mis à jour avec les attributs nécessaires :

- ✅ `.textContentType(.username)` sur le champ email
- ✅ `.textContentType(.password)` pour la connexion
- ✅ `.textContentType(.newPassword)` pour l'inscription
- ✅ `.submitLabel()` pour une meilleure navigation au clavier

## 🔧 Configuration Xcode (Étapes manuelles)

### Étape 1 : Activer Associated Domains

1. Ouvrez votre projet dans Xcode
2. Sélectionnez votre target **RunningMan**
3. Allez dans l'onglet **Signing & Capabilities**
4. Cliquez sur **+ Capability**
5. Recherchez et ajoutez **Associated Domains**

### Étape 2 : Ajouter le domaine AutoFill

Dans la section **Associated Domains** qui vient d'apparaître :

1. Cliquez sur le **+** pour ajouter un nouveau domaine
2. Entrez : `webcredentials:runningman.app`
   
   ⚠️ **Remplacez `runningman.app` par votre véritable nom de domaine**
   
   Exemples :
   - Si votre site est `https://monapp.com` → utilisez `webcredentials:monapp.com`
   - Si vous n'avez pas encore de domaine, vous pouvez utiliser : `webcredentials:localhost`

### Étape 3 : Configuration du fichier apple-app-site-association

Sur votre serveur web, créez un fichier `apple-app-site-association` (sans extension) :

```json
{
  "webcredentials": {
    "apps": [
      "TEAM_ID.com.votrecompagnie.RunningMan"
    ]
  }
}
```

**Comment trouver votre TEAM_ID et Bundle ID :**

1. **TEAM_ID** : Dans Xcode, allez dans Signing & Capabilities → Team
2. **Bundle ID** : Dans l'onglet General → Bundle Identifier

**Où placer ce fichier :**

Le fichier doit être accessible à cette URL :
```
https://votredomaine.com/.well-known/apple-app-site-association
```

ou

```
https://votredomaine.com/apple-app-site-association
```

**Configuration serveur :**

Le fichier doit être servi avec le header HTTP :
```
Content-Type: application/json
```

## 🧪 Test sans domaine (Développement)

Si vous n'avez pas encore de domaine, vous pouvez tester localement :

### Option 1 : Utiliser localhost

1. Dans Associated Domains, ajoutez : `webcredentials:localhost`
2. L'AutoFill fonctionnera dans le simulateur

### Option 2 : Test manuel

Sans domaine configuré, vous pouvez toujours :
- Utiliser le bouton **Clé** au-dessus du clavier iOS
- Sélectionner manuellement vos identifiants sauvegardés
- iOS proposera de sauvegarder les nouveaux identifiants après connexion

## 📱 Comment tester

### Test 1 : Sauvegarde des identifiants

1. Lancez l'app sur un appareil ou simulateur
2. Inscrivez-vous ou connectez-vous avec des identifiants
3. Après connexion réussie, iOS devrait afficher une bannière :
   > "Souhaitez-vous enregistrer ce mot de passe ?"
4. Appuyez sur **Enregistrer le mot de passe**

### Test 2 : AutoFill lors de la connexion

1. Déconnectez-vous de l'app
2. Revenez à l'écran de connexion
3. Touchez le champ email ou mot de passe
4. Au-dessus du clavier, appuyez sur l'icône **Clé** 🔑
5. Sélectionnez vos identifiants sauvegardés

### Test 3 : Vérification dans Réglages

1. Ouvrez **Réglages** → **Mots de passe**
2. Recherchez "RunningMan" ou votre email
3. Vérifiez que les identifiants sont sauvegardés

## 🔍 Dépannage

### L'app n'apparaît pas dans Mots de passe

**Solution :**
- Vérifiez que vous avez ajouté `.textContentType()` aux champs
- Vérifiez que Associated Domains est bien activé
- Réinstallez l'app (supprimez complètement puis réinstallez)
- Sur un appareil physique, vérifiez que iCloud Keychain est activé

### Le bouton "Enregistrer le mot de passe" n'apparaît pas

**Solution :**
- iOS ne propose pas toujours la sauvegarde immédiatement
- Essayez de vous connecter 2-3 fois
- Vérifiez que les identifiants ne sont pas déjà sauvegardés
- Sur simulateur, réinitialisez le Keychain : Device → Erase All Content and Settings

### AutoFill ne suggère pas mes identifiants

**Solution :**
- Vérifiez que le fichier `apple-app-site-association` est accessible
- Vérifiez le TEAM_ID et Bundle ID dans le fichier
- Attendez 24h pour la propagation des modifications
- Réinstallez complètement l'app

## 💡 Conseils supplémentaires

### Pour une expérience optimale :

1. **Ajoutez un nom d'affichage :**
   ```swift
   TextField("Email", text: $email)
       .textContentType(.username)
       .autocorrectionDisabled()
       .textInputAutocapitalization(.never)
   ```

2. **Gérez le submit avec actions :**
   ```swift
   TextField("Email", text: $email)
       .onSubmit {
           // Focus sur le champ suivant
       }
   ```

3. **Proposez Face ID / Touch ID :**
   - Utilisez `LocalAuthentication` framework pour permettre l'authentification biométrique

## 🔐 Sécurité

- ✅ Les mots de passe sont stockés de manière sécurisée dans le Keychain iCloud
- ✅ Le chiffrement est géré automatiquement par iOS
- ✅ Les mots de passe sont synchronisés entre tous les appareils de l'utilisateur
- ✅ Aucun stockage en clair dans votre code ou base de données locale

## 📚 Ressources Apple

- [Password AutoFill Documentation](https://developer.apple.com/documentation/security/password_autofill)
- [Associated Domains Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_associated-domains)
- [Supporting Associated Domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains)

---

**Note :** Les modifications du code Swift sont déjà appliquées. Il ne reste que la configuration manuelle dans Xcode et sur votre serveur web.
