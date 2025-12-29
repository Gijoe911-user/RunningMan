# 📜 Changelog
## Historique des modifications - RunningMan

Toutes les modifications notables du projet sont documentées ici.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

---

## [Non publié]

### 🚧 En cours
- HealthKit : Monitoring cardiaque en temps réel
- HealthKit : Calcul des calories brûlées
- NotificationService : Alertes live quand un membre démarre une session

---

## [1.0.0] - 2024-12-24

### 🎉 Première version MVP

#### ✨ Ajouté
- **Authentification** : Connexion/Inscription via Firebase Auth (email/password)
- **Gestion des Squads** :
  - Création de squads avec nom et description
  - Système d'invitation par code unique (6 caractères)
  - Rejoindre une squad avec un code
  - Quitter une squad
  - Affichage des membres avec avatars
- **Sessions de course** :
  - Démarrage de sessions actives
  - Terminaison de sessions
  - Statuts : Active, Scheduled, Ended
  - Tracking du temps écoulé
- **Tracking GPS** :
  - Suivi de la position en temps réel
  - Enregistrement du tracé (route)
  - Affichage sur carte MapKit
  - Polyline du parcours
  - Sauvegarde du tracé dans Firebase
- **Carte améliorée** :
  - EnhancedSessionMapView avec contrôles
  - Bouton recentrer sur l'utilisateur
  - Affichage des autres coureurs avec marqueurs
  - Tracé de la route en direct
- **Widget de statistiques** :
  - SessionStatsWidget avec 4 métriques
  - Temps écoulé (HH:MM:SS)
  - Distance (mètres → km)
  - BPM (préparé pour HealthKit)
  - Calories (préparé pour HealthKit)
- **Architecture** :
  - MVVM avec Services isolés
  - ViewModels avec `@Published` uniquement pour l'UI
  - Services pour Firebase, GPS, HealthKit
  - Logger centralisé avec catégories
  - Gestion d'erreurs avec `enum` et `LocalizedError`

#### 🛠️ Technique
- Swift 6.0 + SwiftUI
- Firebase Firestore pour la base de données temps réel
- Firebase Auth pour l'authentification
- CoreLocation pour le GPS
- Combine pour les flux de données
- Architecture MVVM stricte

---

## [0.9.0] - 2024-12-20

### Préparation MVP

#### ✨ Ajouté
- Prototype de SessionsListView
- Prototype de SquadHubView
- Modèles de données : SessionModel, SquadModel
- Services de base : SessionService, SquadService
- Configuration Firebase initiale

#### 🐛 Corrigé
- Crash au démarrage si Firebase non initialisé
- Problème de cycle de référence dans RealtimeLocationService

---

## [0.8.0] - 2024-12-15

### Architecture initiale

#### ✨ Ajouté
- Structure du projet
- Configuration Xcode
- Intégration Firebase via CocoaPods
- Première version de AuthService
- Écran de login basique

---

## Convention de nommage des commits

Pour garder un historique Git propre, utiliser ce format :

```
<type>(<scope>): <description courte>

[Corps optionnel avec détails]

[Footer optionnel avec références]
```

### Types
- **feat** : Nouvelle fonctionnalité
- **fix** : Correction de bug
- **docs** : Documentation uniquement
- **style** : Formatage, point-virgules manquants, etc. (pas de changement de code)
- **refactor** : Refactoring sans changer le comportement
- **perf** : Amélioration de performance
- **test** : Ajout/modification de tests
- **chore** : Tâches de maintenance (build, dépendances, etc.)

### Scopes
- **session** : Tout ce qui concerne les sessions de course
- **squad** : Gestion des squads
- **auth** : Authentification
- **map** : Carte et localisation
- **health** : HealthKit
- **notif** : Notifications
- **ui** : Interface utilisateur
- **service** : Services backend
- **config** : Configuration du projet

### Exemples

```bash
# Nouvelle fonctionnalité
feat(health): ajout monitoring cardiaque HealthKit

# Correction de bug
fix(session): correction crash lors de la terminaison de session

# Documentation
docs(readme): mise à jour instructions d'installation Firebase

# Refactoring
refactor(services): isolation de Firebase dans SessionService

# Performance
perf(map): optimisation du rafraîchissement de la carte (30s → 10s)

# Tests
test(session): ajout tests unitaires pour SessionsViewModel
```

---

## Liens utiles

- [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/)
- [Semantic Versioning](https://semver.org/lang/fr/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Dernière mise à jour :** 28 décembre 2024
