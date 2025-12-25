//
//  SOLUTION_RAPIDE_CRASH.md
//  RunningMan
//
//  Guide de résolution rapide du crash au démarrage
//

# 🚨 SOLUTION RAPIDE AU CRASH

## Problème
L'application crash avec l'erreur :
```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', 
reason: 'Invalid parameter not satisfying: !stayUp || CLClientIsBackgroundable(internal->fClient) || _CFMZEnabled()'
```

## ✅ Solution Immédiate (Déjà appliquée)

J'ai déjà corrigé le code dans `SessionsViewModel.swift` pour **désactiver temporairement** les mises à jour de localisation en arrière-plan.

L'app devrait maintenant **se lancer sans crasher** !

---

## ⚠️ Configuration Requise pour Activation Complète

Pour activer la localisation en arrière-plan (nécessaire pour le suivi en temps réel), suivez ces étapes :

### Étape 1 : Configurer Info.plist

Ouvrez votre `Info.plist` et ajoutez ces 3 clés **obligatoires** :

1. **NSLocationWhenInUseUsageDescription**
   - Type: String
   - Valeur: `RunningMan utilise votre position pour afficher votre parcours pendant vos courses.`

2. **NSLocationAlwaysAndWhenInUseUsageDescription**
   - Type: String
   - Valeur: `RunningMan a besoin d'accéder à votre position en arrière-plan pour partager votre position avec votre Squad.`

3. **UIBackgroundModes**
   - Type: Array
   - Ajoutez un item: `location`

### Étape 2 : Activer Background Modes dans Xcode

1. Sélectionnez votre target RunningMan
2. Allez dans l'onglet "Signing & Capabilities"
3. Cliquez sur "+ Capability"
4. Ajoutez "Background Modes"
5. Cochez ☑️ "Location updates"

### Étape 3 : Réactiver Background Location

Une fois les étapes 1 et 2 complétées, décommentez cette ligne dans `SessionsViewModel.swift` :

```swift
private func setupLocationManager() {
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.allowsBackgroundLocationUpdates = true  // ← Décommenter cette ligne
    locationManager.pausesLocationUpdatesAutomatically = false
}
```

---

## 🎨 Warnings de Couleurs (Non-bloquants)

Vous voyez ces warnings dans les logs :
```
No color named 'CoralAccent' found in asset catalog
No color named 'DarkNavy' found in asset catalog
```

### ✅ Solution déjà appliquée

J'ai créé le fichier `Color+Extensions.swift` qui fournit des **fallback automatiques** pour toutes les couleurs. Les warnings apparaîtront toujours dans les logs mais **ne causeront pas de crash**.

### 🎯 Pour éliminer les warnings (optionnel)

Créez les couleurs dans votre Asset Catalog :

1. Ouvrez `Assets.xcassets` dans Xcode
2. Clic droit → "New Color Set"
3. Nommez-la "CoralAccent"
4. Configurez la couleur en Any Appearance :
   - Hex: `FF6B6B`
5. Répétez pour "DarkNavy" :
   - Hex: `1A1F3A`

Voir le fichier `INFO_PLIST_SETUP.md` pour la liste complète des couleurs.

---

## 🧪 Tester l'Application

Après ces modifications :

1. **Nettoyez** : `Cmd + Shift + K`
2. **Buildez** : `Cmd + B`
3. **Lancez** : `Cmd + R`

L'app devrait maintenant se lancer sans crash ! 🎉

---

## 📋 Résumé des Changements

### Fichiers modifiés :
- ✅ `FeaturesSessionsSessionsViewModel.swift` - Background location désactivé temporairement

### Fichiers créés :
- ✅ `Color+Extensions.swift` - Fallbacks automatiques pour toutes les couleurs
- ✅ `INFO_PLIST_SETUP.md` - Guide complet de configuration
- ✅ `SOLUTION_RAPIDE_CRASH.md` - Ce fichier

---

## 🔍 Autres Warnings dans les Logs

Les warnings suivants sont **normaux dans le simulateur** et n'affectent pas le fonctionnement :

- ❌ `hapticpatternlibrary.plist` - Le simulateur ne supporte pas les haptics
- ❌ `NSLayoutConstraint` - Warnings de layout du clavier système
- ❌ `Result accumulator timeout` - Timing du clavier

Ces warnings disparaîtront sur un appareil physique.

---

## 💡 Prochaines Étapes

1. **Immédiat** : L'app fonctionne maintenant ✅
2. **Recommandé** : Configurez Info.plist pour la localisation (voir Étape 1 ci-dessus)
3. **Optionnel** : Créez les couleurs dans Asset Catalog pour éliminer les warnings

---

## 🆘 Besoin d'Aide ?

Si l'app crash toujours :

1. Vérifiez que vous avez bien les dernières modifications de `SessionsViewModel.swift`
2. Nettoyez le build folder : `Cmd + Shift + K`
3. Redémarrez Xcode
4. Supprimez l'app du simulateur et réinstallez

Si le problème persiste, partagez les nouveaux logs du crash.
