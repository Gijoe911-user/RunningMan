# Configuration Info.plist pour Face ID

## 🔐 Ajouter la description Face ID

Pour utiliser Face ID dans votre app, vous DEVEZ ajouter une description dans votre fichier `Info.plist`.

---

## 📝 Méthode 1 : Via l'interface Xcode

### Étape 1 : Ouvrir Info.plist

1. Dans le **Project Navigator**, trouvez et cliquez sur **Info.plist**
2. Le fichier s'ouvre dans l'éditeur principal

### Étape 2 : Ajouter la clé

1. Cliquez sur le **+** à côté de "Information Property List"
2. Une nouvelle ligne apparaît
3. Commencez à taper : `Privacy - Face ID Usage Description`
4. Xcode devrait auto-compléter. Appuyez sur Entrée.

### Étape 3 : Ajouter la valeur

Dans la colonne "Value", entrez :
```
RunningMan utilise Face ID pour une connexion rapide et sécurisée
```

Ou personnalisez selon vos besoins :
```
Authentifiez-vous rapidement avec Face ID pour accéder à votre compte
```

---

## 📝 Méthode 2 : Édition du fichier XML (avancé)

Si vous préférez éditer le XML directement :

### Étape 1 : Ouvrir en tant que Source Code

1. Clic droit sur **Info.plist**
2. Sélectionnez **Open As** → **Source Code**

### Étape 2 : Ajouter les lignes

Ajoutez ces lignes avant le `</dict>` final :

```xml
<key>NSFaceIDUsageDescription</key>
<string>RunningMan utilise Face ID pour une connexion rapide et sécurisée</string>
```

Exemple complet :
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    
    <!-- ... autres clés ... -->
    
    <!-- Face ID Usage Description -->
    <key>NSFaceIDUsageDescription</key>
    <string>RunningMan utilise Face ID pour une connexion rapide et sécurisée</string>
    
</dict>
</plist>
```

### Étape 3 : Retourner à Property List

1. Clic droit sur **Info.plist**
2. Sélectionnez **Open As** → **Property List**

---

## 🌍 Localisation (Optionnel)

Pour supporter plusieurs langues :

### Étape 1 : Créer InfoPlist.strings

1. File → New → File...
2. Sélectionnez **Strings File**
3. Nommez-le `InfoPlist.strings`
4. Sauvegardez

### Étape 2 : Localiser

1. Sélectionnez `InfoPlist.strings`
2. Dans l'inspecteur de fichier (à droite), cliquez sur **Localize...**
3. Ajoutez les langues souhaitées

### Étape 3 : Traduire

Dans chaque version linguistique de `InfoPlist.strings` :

**Français (fr) :**
```
"NSFaceIDUsageDescription" = "RunningMan utilise Face ID pour une connexion rapide et sécurisée";
```

**Anglais (en) :**
```
"NSFaceIDUsageDescription" = "RunningMan uses Face ID for quick and secure login";
```

**Espagnol (es) :**
```
"NSFaceIDUsageDescription" = "RunningMan utiliza Face ID para un inicio de sesión rápido y seguro";
```

---

## ⚙️ Vérification

### Méthode 1 : Build et Run

1. Lancez l'app sur un appareil ou simulateur
2. Déclenchez une authentification Face ID
3. La première fois, une alerte système devrait apparaître avec votre message

### Méthode 2 : Vérifier Info.plist

Dans Xcode, ouvrez Info.plist et vérifiez que vous voyez :

```
┌─────────────────────────────────────────────────────────────┐
│ Information Property List                           Dictionary│
│   Privacy - Face ID Usage Description               String    │
│   RunningMan utilise Face ID pour une connexion...           │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚠️ Erreurs courantes

### Erreur : "This app has crashed because it attempted to access privacy-sensitive data without a usage description"

**Problème :** La clé `NSFaceIDUsageDescription` est manquante

**Solution :**
1. Vérifiez que la clé est bien ajoutée dans Info.plist
2. Clean Build Folder (⌘+Shift+K)
3. Rebuild

### Erreur : Face ID ne se déclenche pas

**Problème :** Sur simulateur, Face ID n'est pas "Enrolled"

**Solution :**
1. Dans le simulateur : Features → Face ID → Enrolled
2. Relancez l'authentification

### Message n'apparaît pas

**Problème :** L'utilisateur a déjà accepté une fois

**Solution :**
- La permission est demandée une seule fois
- Pour retester : Réglages → Général → Transférer ou réinitialiser → Effacer contenu et réglages

---

## 📚 Clés alternatives

Si vous utilisez d'autres fonctionnalités biométriques :

### Touch ID (optionnel)
```xml
<key>NSFaceIDUsageDescription</key>
<string>RunningMan utilise Face ID ou Touch ID pour une connexion rapide et sécurisée</string>
```

### Messages génériques
```xml
<key>NSFaceIDUsageDescription</key>
<string>Authentifiez-vous pour accéder à vos données sécurisées</string>
```

---

## 🎯 Bonnes pratiques

### Message clair et concis
✅ Bon : "Connexion rapide avec Face ID"
❌ Mauvais : "L'app a besoin de Face ID"

### Expliquer le bénéfice
✅ Bon : "Protégez vos données d'entraînement avec Face ID"
❌ Mauvais : "Face ID requis"

### Adapter au contexte
- **Connexion :** "Connectez-vous rapidement avec Face ID"
- **Paiement :** "Confirmez votre achat avec Face ID"
- **Sécurité :** "Protégez vos données sensibles avec Face ID"

---

## 📱 Test sur simulateur

### Configurer Face ID

1. Lancez le simulateur
2. **Features** → **Face ID** → **Enrolled**

### Simuler succès/échec

Pendant l'authentification :
- **Features** → **Face ID** → **Matching Face** = Succès ✅
- **Features** → **Face ID** → **Non-matching Face** = Échec ❌

### Raccourcis clavier

- **⌘+Shift+H** : Home
- **⌘+L** : Lock/Unlock
- **Features → Face ID** : Contrôles biométrie

---

## 🔗 Ressources

- [Apple Documentation - NSFaceIDUsageDescription](https://developer.apple.com/documentation/bundleresources/information_property_list/nsfaceidusagedescription)
- [LocalAuthentication Framework](https://developer.apple.com/documentation/localauthentication)
- [App Review Guidelines - Privacy](https://developer.apple.com/app-store/review/guidelines/#privacy)

---

**✅ Une fois cette configuration terminée, votre app pourra utiliser Face ID !**
