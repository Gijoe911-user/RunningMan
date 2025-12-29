# 🔗 Guide d'Intégration SessionStatsWidget

**Date :** 29 décembre 2024  
**Statut :** Widget connecté ✅ | Badges non utilisés ⚠️

---

## 📊 État Actuel de l'Intégration

### ✅ **SessionStatsWidget** : CONNECTÉ

Le widget principal est **déjà intégré** dans `SessionsListView.swift` :

```swift
// SessionsListView.swift, lignes 60-68
if let session = viewModel.activeSession {
    HStack {
        Spacer()
        SessionStatsWidget(
            session: session,
            currentHeartRate: viewModel.currentHeartRate,      // ✅ Connecté
            currentCalories: viewModel.currentCalories,        // ✅ Connecté
            routeDistance: calculateRouteDistance(...)         // ✅ Connecté
        )
        .frame(maxWidth: 400)
        Spacer()
    }
    .padding(.top, 60)
    .padding(.horizontal)
}
```

**Données connectées :**
- ✅ `session` : Session active du ViewModel
- ✅ `currentHeartRate` : Depuis `viewModel.currentHeartRate` (HealthKit)
- ✅ `currentCalories` : Depuis `viewModel.currentCalories` (HealthKit)
- ✅ `routeDistance` : Calculé depuis `viewModel.routeCoordinates`

---

## ⚠️ **Badges Compacts** : NON UTILISÉS

Les composants `HeartRateBadge` et `CaloriesBadge` sont créés mais **jamais utilisés** dans l'app.

**Où les voir :**
- Uniquement dans le `#Preview` du widget
- Pas dans l'interface réelle

---

## 🎯 Comment Voir les Données en Vrai

### Option 1 : Tester dans l'App (Recommandé)

**Étapes :**
1. Lancer l'app (`Cmd + R`)
2. Se connecter
3. Sélectionner un Squad
4. Créer une session
5. **Le widget apparaît automatiquement** avec :
   - ⏱️ Temps : Démarre à 00:00 et s'incrémente
   - 📍 Distance : 0 m (augmente si vous bougez avec GPS actif)
   - ❤️ BPM : `--` (nécessite HealthKit configuré)
   - 🔥 Calories : `--` (nécessite HealthKit configuré)

### Option 2 : Vérifier le Preview dans Xcode

**Étapes :**
1. Ouvrir `SessionStatsWidget.swift`
2. Activer le Canvas (Cmd + Option + Return)
3. Voir le preview avec données mock :
   - Temps : 20:45
   - Distance : 2.34 km
   - BPM : 145
   - Calories : 187

---

## 🔧 Pourquoi HeartRateBadge n'est pas visible ?

### Raison 1 : Non Intégré dans l'UI

Les badges sont créés mais **pas appelés** dans `SessionsListView.swift`.

**Solution :** Intégrer manuellement (voir section "Intégrations Optionnelles")

### Raison 2 : HealthKit Non Configuré

Pour voir des vraies données BPM/Calories, il faut :

1. **Activer HealthKit** dans Xcode :
   - Target RunningMan → Signing & Capabilities
   - `+ Capability` → HealthKit

2. **Configurer les permissions** :
   ```swift
   // HealthKitManager.swift doit demander l'autorisation
   healthKitManager.requestAuthorization()
   ```

3. **Tester sur device physique** :
   - HealthKit ne fonctionne **pas** sur simulateur
   - Besoin d'un iPhone/Apple Watch réel

---

## 📍 Où Est Affiché le Widget ?

### Interface de l'App

```
┌──────────────────────────────────────────┐
│  Navigation Bar                          │
├──────────────────────────────────────────┤
│                                          │
│      📍 CARTE (EnhancedSessionMapView)   │
│                                          │
│   ┌────────────────────────────────┐    │
│   │  📊 SessionStatsWidget         │    │ ← ICI (si session active)
│   │  ⏱️ 20:45    📍 2.34 km        │    │
│   │  ❤️  --      🔥  --            │    │
│   └────────────────────────────────┘    │
│                                          │
│                                          │
│   [Participants Overlay]                 │
│                                          │
│   ┌────────────────────────────────┐    │
│   │  Session Active Overlay        │    │
│   │  - Infos session               │    │
│   │  - Liste coureurs              │    │
│   │  - Bouton "Terminer"           │    │
│   └────────────────────────────────┘    │
└──────────────────────────────────────────┘
```

**Position :**
- En haut de l'écran (sous navigation bar)
- Centré horizontalement
- Flottant au-dessus de la carte
- Max width: 400pt

---

## 🚀 Intégrations Optionnelles

### 1️⃣ **Ajouter les Badges dans SessionActiveOverlay**

Si vous voulez voir les badges **séparés** du widget principal :

```swift
// Dans SessionsListView.swift, dans SessionActiveOverlay

struct SessionActiveOverlay: View {
    let session: SessionModel
    @ObservedObject var viewModel: SessionsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                // ... autres contenus ...
                
                // 🆕 Ajouter les badges
                HStack(spacing: 12) {
                    HeartRateBadge(bpm: viewModel.currentHeartRate)
                    CaloriesBadge(calories: viewModel.currentCalories)
                }
                .padding(.vertical, 8)
                
                // ... reste du contenu ...
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}
```

**Résultat :**
Les badges apparaîtront dans l'overlay du bas avec les infos de session.

---

### 2️⃣ **Remplacer les StatBadge par les Nouveaux Badges**

Actuellement, `SessionActiveOverlay` utilise `StatBadge` pour afficher les stats. On peut les remplacer :

```swift
// ❌ ANCIEN (StatBadge)
HStack(spacing: 20) {
    StatBadge(
        icon: "figure.run",
        value: "\(viewModel.activeRunners.count)",
        label: "Coureurs"
    )
    StatBadge(
        icon: "clock.fill",
        value: timeElapsed,
        label: "Temps"
    )
}

// ✅ NOUVEAU (avec HeartRateBadge et CaloriesBadge)
HStack(spacing: 12) {
    HeartRateBadge(bpm: viewModel.currentHeartRate)
    CaloriesBadge(calories: viewModel.currentCalories)
}
```

---

### 3️⃣ **Créer une Vue de Détails Post-Session**

Pour afficher les badges après la fin d'une session :

```swift
struct SessionSummaryView: View {
    let session: SessionModel
    let finalStats: SessionStats
    
    var body: some View {
        VStack(spacing: 20) {
            // Widget complet
            SessionStatsWidget(
                session: session,
                currentHeartRate: finalStats.averageHeartRate,
                currentCalories: finalStats.totalCalories,
                routeDistance: finalStats.totalDistance
            )
            
            // Badges détaillés
            HStack(spacing: 12) {
                HeartRateBadge(bpm: finalStats.averageHeartRate)
                CaloriesBadge(calories: finalStats.totalCalories)
            }
            
            // Graphiques
            // ...
        }
    }
}
```

---

## 🧪 Test Complet : Voir Toutes les Données

### Étape 1 : Configurer HealthKit (Optionnel)

Si vous voulez voir BPM et Calories réels :

1. **Xcode** :
   - Target → Capabilities → HealthKit ✅

2. **Info.plist** :
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>RunningMan a besoin d'accéder à votre rythme cardiaque</string>
   ```

3. **Tester sur iPhone réel** (pas simulateur)

### Étape 2 : Lancer une Session

```
1. Ouvrir l'app
2. Sélectionner un Squad
3. Créer une session
4. Vérifier que le widget apparaît
5. Observer les mises à jour :
   - ⏱️ Temps s'incrémente (chaque seconde)
   - 📍 Distance augmente (si GPS actif)
   - ❤️ BPM affiche "--" (ou valeur si HealthKit activé)
   - 🔥 Calories affiche "--" (ou valeur si HealthKit activé)
```

### Étape 3 : Vérifier les Logs

Dans la console Xcode :

```
🗺️ DEBUG - userLocation: ✅
🗺️ DEBUG - activeRunners: 1
🗺️ DEBUG - routeCoordinates: 0 points (au début)
📊 Stats Widget affiché
```

---

## 🐛 Problèmes Courants

### Problème 1 : Widget Pas Visible

**Causes possibles :**
- Aucune session active → Le widget n'apparaît que si `viewModel.activeSession != nil`
- Trop haut/bas → Ajuster `.padding(.top, 60)`

**Solution :**
```swift
// Vérifier dans SessionsListView.swift
if let session = viewModel.activeSession {
    // Le widget est ici ✅
}
```

### Problème 2 : BPM et Calories Affichent "--"

**C'est normal !** 

**Causes :**
- HealthKit non configuré
- Pas d'autorisation donnée
- Simulateur (HealthKit ne fonctionne que sur device réel)

**Solution :**
```swift
// Dans SessionsViewModel.swift, vérifier que HealthKit est initialisé
if FeatureFlags.heartRateMonitoring {
    healthKitManager.startHeartRateQuery(sessionId: sessionId)
}
```

### Problème 3 : Distance Reste à 0 m

**Causes possibles :**
- GPS désactivé
- Pas d'autorisation localisation
- Simulateur (simuler une course avec Location → Custom Location)

**Solution :**
```
Simulateur :
Features → Location → Freeway Drive (pour simuler mouvement)
```

---

## 📊 Données Mockées vs Réelles

| Métrique | Mockées (Preview) | Réelles (App) |
|----------|-------------------|---------------|
| **Temps** | 20:45 | ✅ Temps réel depuis `session.startedAt` |
| **Distance** | 2340 m | ✅ Calculée depuis GPS |
| **BPM** | 145 | ⚠️ HealthKit requis (sinon `--`) |
| **Calories** | 187 | ⚠️ HealthKit requis (sinon `--`) |

---

## ✅ Checklist de Vérification

### Widget Principal
- [x] SessionStatsWidget créé
- [x] Connecté dans SessionsListView
- [x] Données passées depuis ViewModel
- [x] S'affiche quand session active

### Badges Compacts
- [x] HeartRateBadge créé
- [x] CaloriesBadge créé
- [ ] **Non utilisés dans l'app** (seulement Preview)
- [ ] À intégrer manuellement (optionnel)

### Données
- [x] Temps : Fonctionne (Timer)
- [x] Distance : Fonctionne (GPS)
- [ ] BPM : Nécessite HealthKit configuré
- [ ] Calories : Nécessite HealthKit configuré

---

## 🎯 Recommandations

### Pour Voir le Widget Maintenant (Sans HealthKit)

1. ✅ Lancer l'app
2. ✅ Créer une session
3. ✅ Observer Temps et Distance
4. ⚠️ BPM et Calories afficheront `--` (normal sans HealthKit)

### Pour Voir Toutes les Données (Avec HealthKit)

1. Activer HealthKit dans Xcode
2. Tester sur iPhone réel
3. Donner les permissions HealthKit
4. Démarrer une session
5. Toutes les métriques s'afficheront

### Pour Utiliser les Badges Séparés

1. Suivre "Intégrations Optionnelles" ci-dessus
2. Ajouter dans `SessionActiveOverlay`
3. Ou créer une vue `SessionSummaryView`

---

## 📝 Résumé

| Composant | Créé | Connecté | Visible |
|-----------|------|----------|---------|
| **SessionStatsWidget** | ✅ | ✅ | ✅ |
| **SessionStatCard** | ✅ | ✅ (via Widget) | ✅ |
| **HeartRateBadge** | ✅ | ❌ | ❌ (seulement Preview) |
| **CaloriesBadge** | ✅ | ❌ | ❌ (seulement Preview) |
| **SessionStatsFormatters** | ✅ | ✅ (via Widget) | N/A |

---

**Question ?** Voulez-vous que je :
1. ✅ Intègre les badges dans l'overlay principal ?
2. ✅ Configure HealthKit pour voir les vraies données ?
3. ✅ Crée une vue de résumé post-session ?

---

**Date :** 29 décembre 2024  
**Auteur :** Assistant Architecture RunningMan
