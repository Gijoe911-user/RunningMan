# 🔐 Configuration Visuelle - AutoFill Mots de Passe

Ce guide visuel vous accompagne étape par étape pour configurer l'AutoFill dans votre projet Xcode.

---

## 📋 Checklist Rapide

Avant de commencer, assurez-vous d'avoir :
- [ ] Un compte développeur Apple (gratuit suffit pour le test)
- [ ] Xcode 14.0 ou supérieur
- [ ] Un appareil iOS 12+ ou simulateur
- [ ] (Optionnel) Un domaine web pour la production

---

## 🎯 Partie 1 : Configuration Xcode (5 minutes)

### Étape 1.1 : Ouvrir les Capabilities

1. Dans le **Project Navigator** (barre latérale gauche), cliquez sur votre projet **RunningMan** (icône bleue en haut)

2. Dans la liste des targets, sélectionnez **RunningMan** (sous TARGETS)

3. Cliquez sur l'onglet **Signing & Capabilities** (en haut)

```
┌─────────────────────────────────────────────────┐
│ General  Signing & Capabilities  Resource Tags  │ ← Cliquez ici
├─────────────────────────────────────────────────┤
│                                                  │
│  + Capability                                    │ ← Ensuite ici
│                                                  │
│  ▼ Signing                                       │
│     Team: Votre équipe                           │
│     Bundle Identifier: com.xxx.RunningMan        │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Étape 1.2 : Ajouter Associated Domains

1. Cliquez sur le bouton **+ Capability**

2. Dans la fenêtre qui s'ouvre, tapez "Associated" dans la recherche

3. Double-cliquez sur **Associated Domains**

```
┌─────────────────────────────────────┐
│ Search: Associated                  │
├─────────────────────────────────────┤
│ ✓ Associated Domains               │ ← Double-clic ici
│   □ Network Extensions             │
│   □ App Attest                     │
└─────────────────────────────────────┘
```

### Étape 1.3 : Configurer le Domain

Vous devriez maintenant voir une nouvelle section **Associated Domains** :

```
┌─────────────────────────────────────────────────┐
│  ▼ Associated Domains                           │
│                                                  │
│     Domains                                      │
│     + ┌──────────────────────────────────────┐  │
│       │                                      │  │ ← Cliquez sur +
│       └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

Cliquez sur **+** et entrez selon votre situation :

**🧪 Pour le développement/test :**
```
webcredentials:localhost
```

**🌐 Pour la production (remplacez par VOTRE domaine) :**
```
webcredentials:monapp.com
```

**📱 Exemples concrets :**
- Si votre backend est sur `https://api.runningman.fr` → `webcredentials:api.runningman.fr`
- Si vous utilisez Firebase → `webcredentials:runningman.firebaseapp.com`
- Pour tester localement → `webcredentials:localhost`

```
┌─────────────────────────────────────────────────┐
│  ▼ Associated Domains                           │
│                                                  │
│     Domains                                      │
│     + ┌──────────────────────────────────────┐  │
│       │ webcredentials:localhost           │  │
│       └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### ✅ Vérification Étape 1

Dans votre fichier **RunningMan.entitlements** (qui sera créé automatiquement), vous devriez voir :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>webcredentials:localhost</string>
    </array>
</dict>
</plist>
```

---

## 🌐 Partie 2 : Configuration Serveur (10 minutes)

### ⚠️ Cette partie est OPTIONNELLE pour le test local

Si vous utilisez `webcredentials:localhost`, vous pouvez **sauter cette partie** pour l'instant. iOS acceptera les identifiants même sans configuration serveur en développement.

### Configuration pour Production

Quand vous serez prêt à déployer :

#### Étape 2.1 : Trouver vos identifiants

1. **Team ID** :
   - Dans Xcode : Signing & Capabilities → Team
   - Ou sur [developer.apple.com](https://developer.apple.com) → Membership

2. **Bundle ID** :
   - Dans Xcode : General → Bundle Identifier
   - Format : `com.votrecompagnie.RunningMan`

#### Étape 2.2 : Créer le fichier apple-app-site-association

Sur votre serveur, créez le fichier suivant :

**Nom du fichier :** `apple-app-site-association` (sans extension !)

**Contenu :**
```json
{
  "webcredentials": {
    "apps": [
      "ABCD1234.com.votrecompagnie.RunningMan"
    ]
  }
}
```

Remplacez :
- `ABCD1234` par votre **Team ID**
- `com.votrecompagnie.RunningMan` par votre **Bundle ID**

**Exemple complet :**
```json
{
  "webcredentials": {
    "apps": [
      "X8FM9Q7G8P.com.jocelyngiard.RunningMan"
    ]
  }
}
```

#### Étape 2.3 : Placer le fichier

Le fichier doit être accessible à l'une de ces URLs :

**Option 1 (Recommandée) :**
```
https://votredomaine.com/.well-known/apple-app-site-association
```

**Option 2 :**
```
https://votredomaine.com/apple-app-site-association
```

#### Étape 2.4 : Configuration serveur web

Le fichier doit être servi avec :
- **Content-Type:** `application/json`
- **HTTPS obligatoire** (pas de HTTP)
- **Pas de redirection**

**Pour Apache (.htaccess) :**
```apache
<Files "apple-app-site-association">
    Header set Content-Type application/json
</Files>
```

**Pour Nginx :**
```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
}
```

**Pour Express.js :**
```javascript
app.get('/.well-known/apple-app-site-association', (req, res) => {
  res.type('application/json');
  res.sendFile(__dirname + '/apple-app-site-association');
});
```

#### Étape 2.5 : Vérifier la configuration

Testez dans votre navigateur :
```
https://votredomaine.com/.well-known/apple-app-site-association
```

Vous devriez voir le JSON s'afficher.

---

## 🧪 Partie 3 : Test (2 minutes)

### Test 1 : Enregistrement d'un nouveau mot de passe

1. **Lancez l'app** sur un simulateur ou appareil

2. **Inscrivez-vous** ou **connectez-vous** avec :
   - Email : `test@example.com`
   - Mot de passe : `Test1234!`

3. **Après la connexion réussie**, vous devriez voir apparaître une bannière en haut :
   ```
   ┌─────────────────────────────────────────┐
   │  Enregistrer le mot de passe ?         │
   │  Pour test@example.com                 │
   │                                         │
   │  [Jamais pour ce site]  [Enregistrer] │
   └─────────────────────────────────────────┘
   ```

4. **Appuyez sur "Enregistrer"**

### Test 2 : Récupération avec AutoFill

1. **Déconnectez-vous** de l'app

2. **Revenez à l'écran de connexion**

3. **Touchez le champ Email ou Mot de passe**

4. **Regardez au-dessus du clavier** :
   ```
   ┌───────────────────────────────────────────────┐
   │  🔑  test@example.com                       │ ← Touchez ici
   └───────────────────────────────────────────────┘
   │  Q  W  E  R  T  Y  U  I  O  P             │
   │   A  S  D  F  G  H  J  K  L               │
   │    Z  X  C  V  B  N  M                    │
   └───────────────────────────────────────────────┘
   ```

5. **Appuyez sur la suggestion** → Les champs seront remplis automatiquement !

### Test 3 : Vérification dans Réglages

1. Ouvrez **Réglages** → **Mots de passe**

2. Authentifiez-vous avec Face ID / Touch ID

3. Recherchez **"localhost"** ou votre domaine

4. Vous devriez voir votre identifiant listé

---

## 🔧 Dépannage

### ❌ Problème : La bannière "Enregistrer le mot de passe" n'apparaît pas

**Solutions :**

✅ **Vérifiez le code :**
- Les champs doivent avoir `.textContentType(.username)` et `.textContentType(.password)`
- ✅ Déjà fait dans votre `LoginView.swift`

✅ **Vérifiez Xcode :**
- Associated Domains est activé
- Le domaine commence bien par `webcredentials:`

✅ **iOS a besoin de temps :**
- Connectez-vous 2-3 fois
- iOS ne propose pas toujours immédiatement

✅ **Sur simulateur :**
- Parfois capricieux
- Réinitialisez : Device → Erase All Content and Settings
- Relancez l'app

### ❌ Problème : AutoFill ne suggère pas mes identifiants

**Solutions :**

✅ **Vérifiez que le mot de passe est enregistré :**
- Réglages → Mots de passe
- Cherchez votre app ou localhost

✅ **Le champ doit avoir le focus :**
- Touchez le champ Email ou Mot de passe
- La barre de suggestion apparaît au-dessus du clavier

✅ **Réinstallez l'app :**
```bash
# Supprimez complètement l'app du simulateur/appareil
# Puis relancez depuis Xcode
```

### ❌ Problème : Ça marchait mais plus maintenant

**Solutions :**

✅ **Nettoyez le build :**
- Xcode : Product → Clean Build Folder (⌘+Shift+K)
- Relancez

✅ **Vérifiez le Bundle ID :**
- N'a pas changé accidentellement ?
- General → Bundle Identifier

✅ **Sur appareil physique :**
- Réglages → Mots de passe → Options de remplissage automatique
- Vérifiez que "Mots de passe iCloud" est activé

---

## 💡 Astuces Avancées

### 🔄 Pré-remplir l'email au lancement

Utilisez `KeychainHelper` pour sauvegarder juste l'email :

```swift
// Dans LoginView, après connexion réussie
if success {
    KeychainHelper.shared.save(email: email, password: password)
}

// Au lancement de LoginView
.onAppear {
    if let credentials = KeychainHelper.shared.retrieve() {
        self.email = credentials.email
        // Ne pré-remplissez PAS le mot de passe !
    }
}
```

### 🔐 Ajouter Face ID / Touch ID

Pour une expérience encore meilleure :

```swift
import LocalAuthentication

func authenticateWithBiometrics() {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        let reason = "Connectez-vous avec Face ID"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            if success {
                // Récupérer les identifiants et connecter automatiquement
                if let credentials = KeychainHelper.shared.retrieve() {
                    Task {
                        await authVM.signIn(email: credentials.email, password: credentials.password)
                    }
                }
            }
        }
    }
}
```

### 🎨 Personnaliser l'icône AutoFill

iOS utilise automatiquement l'icône de votre app dans les suggestions AutoFill. Assurez-vous d'avoir une belle icône d'app !

---

## 📊 Récapitulatif

### ✅ Ce qui est fait automatiquement par iOS :

- Chiffrement des mots de passe
- Synchronisation iCloud entre appareils
- Suggestions contextuelles
- Génération de mots de passe forts (lors de l'inscription)
- Détection automatique des formulaires de connexion

### ✅ Ce que vous avez configuré :

- `textContentType` sur les champs
- Associated Domains capability
- Keychain Helper pour stockage additionnel

### 🎯 Résultat final :

Votre app offre maintenant une expérience de connexion moderne et sécurisée, similaire aux apps professionnelles !

---

## 🚀 Prochaines Étapes

1. **Testez sur un appareil réel** (pas juste le simulateur)
2. **Configurez votre domaine de production** quand vous en aurez un
3. **Ajoutez Face ID / Touch ID** pour une connexion en un clic
4. **Implémentez "Se connecter avec Apple"** pour encore plus de facilité

---

**Besoin d'aide ?** Consultez la [documentation Apple](https://developer.apple.com/documentation/security/password_autofill)
