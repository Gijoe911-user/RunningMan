# 📋 Product Requirements Document (PRD)
## RunningMan - Application de Course Collaborative

**Dernière mise à jour :** 28 décembre 2024  
**Version du document :** 1.2

---

## 🎯 Vision du produit

RunningMan transforme la course à pied en expérience sociale et collaborative. Grâce aux "Squads", les utilisateurs peuvent s'entraîner ensemble, se challenger, et atteindre leurs objectifs même à distance.

**Mission :** Rendre la course plus motivante et sociale en permettant aux coureurs de partager leurs performances en temps réel.

---

## 👥 Personas

### 1. Le Coureur Régulier (Sarah, 32 ans)
- Court 3-4 fois par semaine
- Veut rester motivée avec des amis
- Utilise déjà Strava mais trouve ça trop "compétitif"
- **Besoin** : Une app qui combine social + tracking

### 2. Le Préparateur Marathon (Marc, 28 ans)
- Prépare son premier marathon
- Suit un programme structuré
- Veut des feedbacks et des encouragements
- **Besoin** : Coaching + communauté

### 3. Le Débutant (Julie, 25 ans)
- Commence la course
- Intimidée par les apps "pro"
- Cherche un groupe accueillant
- **Besoin** : Simplicité + soutien

---

## ✨ Fonctionnalités

### Tableau de bord des fonctionnalités

| Fonctionnalité | Statut | Priorité | Phase | Notes |
|----------------|--------|----------|-------|-------|
| **Authentification** | ✅ Livré | P0 | MVP | Firebase Auth |
| **Gestion Squads** | ✅ Livré | P0 | MVP | Créer/Rejoindre/Quitter |
| **Sessions actives** | ✅ Livré | P0 | MVP | Démarrer/Terminer |
| **Tracking GPS** | ✅ Livré | P0 | MVP | Tracé temps réel |
| **Localisation temps réel** | ✅ Livré | P0 | MVP | Voir les autres coureurs |
| **Widget stats** | ✅ Livré | P1 | MVP | Distance, temps, BPM, calories |
| **Carte améliorée** | ✅ Livré | P1 | MVP | Polyline + contrôles |
| **HealthKit (BPM)** | 🚧 En cours | P1 | Phase 1 | Monitoring cardiaque |
| **HealthKit (Calories)** | 🚧 En cours | P1 | Phase 1 | Calcul dépense |
| **Notifications live** | 📋 Planifié | P1 | Phase 1 | Alertes quand un membre de la squad court |
| **Chat textuel** | 📋 Planifié | P2 | Phase 2 | Messages dans les sessions |
| **Partage photos** | 📋 Planifié | P2 | Phase 2 | Capture + upload et Album de la course|
| **Intégration Strava** | 🔮 Backlog | P2 | Phase 2 | Sync bidirectionnelle |
| **Voice Chat** | 🔮 Backlog | P3 | Phase 3 | Push-to-talk pendant la course |
| **Apple Watch** | 🔮 Backlog | P3 | Phase 3 | App compagnon watchOS |
| **Intégration Garmin** | 🔮 Backlog | P3 | Phase 3 | Sync activités |
| **Analyse IA** | 🔮 Backlog | P4 | Phase 4 | Coaching post-course et plan d'entrainement ajusté|
| **Programme Marathon** | 🔮 Backlog | P4 | Phase 4 | Plans structurés |
| **Playlist Boost** | 🔮 Backlog | P4 | Phase 4 | Propose une playlist universel adapter au rythme cible (fonction du BPM et de l allure)  |


**Légende des statuts :**
- ✅ **Livré** : Disponible en production
- 🚧 **En cours** : Développement actif
- 📋 **Planifié** : Dans le backlog immédiat
- 🔮 **Backlog** : Fonctionnalité future

**Légende des priorités :**
- **P0** : Critique (MVP)
- **P1** : Important (Quick wins)
- **P2** : Utile (Différenciateurs)
- **P3** : Nice to have (Avancé)
- **P4** : Innovation (Long terme)

---

## 🗓️ Roadmap détaillée

### ✅ Phase 0 : MVP (Décembre 2024) - TERMINÉ

**Objectif :** Permettre aux utilisateurs de créer des squads et de courir ensemble avec tracking GPS.

- [x] Authentification Firebase (email/password)
- [x] Création et gestion des Squads
- [x] Système d'invitation par code
- [x] Démarrage de sessions de course
- [x] Tracking GPS en temps réel
- [x] Affichage des positions sur carte
- [x] Tracé de la route (polyline)
- [x] Widget de statistiques (temps, distance)
- [x] Architecture MVVM propre

**Date de livraison :** 24 décembre 2024

---

### 🚧 Phase 1 : Santé & Engagement (Janvier 2025)

**Objectif :** Améliorer l engagement avec HealthKit et les notifications. Autoriser plusieurs sessions active en // sur une squad pour les entrainements (pas pour la course qui peut etre activé par n importe quel coureur mais unique si plusieurs SaS c'est le 1er coureur du Sas qui devra declencher)

**Fonctionnalités :**

1. **HealthKit Complet** (P1)
   - [x] Demande d'autorisation
   - [ ] Monitoring rythme cardiaque en direct
   - [ ] Calcul calories brûlées
   - [ ] Enregistrement des workouts dans l'app Santé
   - [ ] Historique cardiaque post-session
   - **Estimation :** 5 jours

2. **Notifications Live** (P1)
   - [ ] Alert quand un membre de la squad démarre une session
   - [ ] Autoriser les coureurs de la squad créer des Sessions de type entrainemt en meme temps
   - [ ] Rappels de sessions planifiées
   - [ ] Notifications d'achievements
   - [ ] Deep-linking vers les sessions
   - **Estimation :** 3 jours

3. **Améliorations UI** (P2)
   - [ ] Graphiques de performance
   - [ ] Badge de distance/durée
   - [ ] Animations fluides
   - **Estimation :** 2 jours

**Date de livraison cible :** 15 janvier 2025

---

### 📋 Phase 2 : Social & Intégrations (Février 2025)

**Objectif :** Renforcer l'aspect social et s'intégrer aux plateformes existantes.

**Fonctionnalités :**

1. **Chat Textuel** (P2)
   - [ ] Messages dans les sessions actives
   - [ ] Historique de chat par session
   - [ ] Notifications de nouveaux messages
   - [ ] Emojis rapides (👍 🔥 💪)
   - **Estimation :** 4 jours

2. **Partage de Photos** (P2)
   - [ ] Capture photo pendant la course
   - [ ] Upload vers Firebase Storage
   - [ ] Galerie de la session
   - [ ] Partage sur réseaux sociaux
   - **Estimation :** 3 jours

3. **Intégration Strava** (P2)
   - [ ] Authentification OAuth 2.0
   - [ ] Export des sessions vers Strava
   - [ ] Import des activités Strava
   - [ ] Affichage du profil Strava
   - **Estimation :** 5 jours

4. **Améliorations Squad** (P2)
   - [ ] Feed d'activité de la squad
   - [ ] Classements hebdomadaires
   - [ ] Challenges squad (distance, durée)
   - **Estimation :** 4 jours

**Date de livraison cible :** 28 février 2025

---

### 🔮 Phase 3 : Écosystème Apple (Mars 2025)

**Objectif :** Offrir une expérience multi-appareils avec Apple Watch.

**Fonctionnalités :**

1. **Voice Chat** (P3)
   - [ ] Push-to-talk pendant la course
   - [ ] Canaux vocaux par session
   - [ ] Détection de bruit ambiant
   - [ ] Économie de batterie
   - **Estimation :** 7 jours

2. **Apple Watch App** (P3)
   - [ ] Démarrage de session depuis la Watch
   - [ ] Affichage des stats en direct
   - [ ] Contrôles vocaux (Siri)
   - [ ] Complications Watch Face
   - [ ] Sync avec iPhone
   - **Estimation :** 10 jours

3. **Intégration Garmin** (P3)
   - [ ] Authentification
   - [ ] Sync activités
   - [ ] Support des appareils Garmin
   - **Estimation :** 4 jours

4. **Widgets iOS** (P3)
   - [ ] Widget Home Screen avec stats
   - [ ] Widget Lock Screen (Live Activities)
   - [ ] Dynamic Island pour sessions actives
   - **Estimation :** 3 jours

**Date de livraison cible :** 31 mars 2025

---

### 🔮 Phase 4 : Intelligence & Marathon (Avril-Mai 2025)

**Objectif :** Devenir un outil de coaching avec IA et programmes structurés.

**Fonctionnalités :**

1. **Analyse IA Post-Course** (P4)
   - [ ] Analyse de la performance
   - [ ] Suggestions d'amélioration
   - [ ] Détection de fatigue
   - [ ] Prédiction de temps (ex: 10k, semi, marathon)
   - **Estimation :** 8 jours

2. **Programme Marathon** (P4)
   - [ ] Plans d'entraînement structurés (12, 16, 20 semaines)
   - [ ] Suivi de progression
   - [ ] Ajustement dynamique selon performances
   - [ ] Notifications de rappel d'entraînement
   - **Estimation :** 10 jours

3. **Social Avancé** (P4)
   - [ ] Profils publics
   - [ ] Classements globaux
   - [ ] Événements virtuels (courses en ligne)
   - **Estimation :** 6 jours

4. **Gamification** (P4)
   - [ ] Système de badges
   - [ ] Niveaux de coureur
   - [ ] Défis quotidiens/hebdomadaires
   - **Estimation :** 5 jours

**Date de livraison cible :** 31 mai 2025

---

## 🎨 Wireframes & Design

### Écrans principaux

1. **Onboarding** : Présentation + Authentification
2. **Squad Hub** : Liste des squads + Créer/Rejoindre
3. **Session Active** : Carte + Widget stats + Liste participants
4. **Post-Session** : Résumé avec graphiques
5. **Profil** : Stats personnelles + Historique

**Figma :** [Lien vers les maquettes](#) (à ajouter)

---

## 🔧 Stack technique

### Frontend
- **Langage :** Swift 6.0
- **UI Framework :** SwiftUI
- **Architecture :** MVVM + Services
- **Tests :** Swift Testing (`@Test`, `#expect`)

### Backend
- **Backend as a Service :** Firebase
  - Firestore (base de données temps réel)
  - Firebase Auth (authentification)
  - Firebase Storage (photos)
  - Firebase Functions (logique serveur, optionnel)
- **Alternative future :** Backend custom Swift (Vapor) si croissance importante

### APIs Apple
- **CoreLocation** : GPS et suivi de position
- **HealthKit** : Rythme cardiaque, calories, workouts
- **UserNotifications** : Notifications locales et push
- **MapKit** : Affichage des cartes

### Intégrations tierces
- **Strava API** : Sync activités
- **Garmin Connect API** : Sync appareils Garmin
- **OpenAI API** (Phase 4) : Analyse IA

---

## 📊 Métriques de succès

### KPIs Phase 1 (Janvier)
- **Adoption HealthKit** : 60% des utilisateurs activent le monitoring cardiaque
- **Engagement notifications** : 40% cliquent sur les alertes "Live Run"
- **Rétention D7** : 50% des utilisateurs reviennent après 7 jours

### KPIs Phase 2 (Février)
- **Messages envoyés** : 5+ messages par session active
- **Photos partagées** : 30% des sessions incluent une photo
- **Connexion Strava** : 25% des utilisateurs connectent leur compte

### KPIs Phase 3 (Mars)
- **Adoption Watch** : 15% des utilisateurs utilisent l'app Watch
- **Voice Chat** : 20% des sessions utilisent le voice

### KPIs Phase 4 (Mai)
- **Programme Marathon** : 10% des utilisateurs suivent un programme
- **Taux de complétion** : 70% des utilisateurs terminent leur plan

---

## 🚨 Risques & Contraintes

### Risques techniques
1. **Batterie** : Le GPS + HealthKit consomment beaucoup
   - **Mitigation** : Optimiser les requêtes de localisation (tous les 10s au lieu de 1s)
   
2. **Latence temps réel** : Firebase peut avoir du lag
   - **Mitigation** : Utiliser des listeners efficaces + cache local

3. **Coût Firebase** : Si beaucoup d'utilisateurs, les lectures/écritures peuvent coûter cher
   - **Mitigation** : Pagination, batch reads, cache

### Contraintes légales
1. **RGPD** : Les données de localisation sont sensibles
   - **Action** : Ajouter une page de confidentialité + consentement explicite
   
2. **Apple Review** : Les apps de santé sont scrutées
   - **Action** : Tester exhaustivement HealthKit avant soumission

---

## 🤝 Parties prenantes

| Rôle | Nom | Responsabilité |
|------|-----|----------------|
| Product Owner | [À définir] | Vision produit + Roadmap |
| Lead Developer | [Développeur principal] | Architecture + Code review |
| Designer | [À définir] | UI/UX + Wireframes |
| QA | [À définir] | Tests + Validation |

---

## 📝 Notes de version

### v1.0.0 (24 décembre 2024)
- 🎉 Premier release MVP
- Squads fonctionnels
- Sessions avec tracking GPS
- Widget de stats

### v1.1.0 (Prévu : 15 janvier 2025)
- HealthKit complet
- Notifications live
- Améliorations UI

### v1.2.0 (Prévu : 28 février 2025)
- Chat textuel
- Partage de photos
- Intégration Strava

---

## 📞 Contact

Pour toute question sur ce PRD :
- Email : product@runningman.app
- Slack : #product-runningman

---

**Ce document est vivant et sera mis à jour régulièrement. Consultez le [CHANGELOG.md](./CHANGELOG.md) pour l'historique des modifications.**
