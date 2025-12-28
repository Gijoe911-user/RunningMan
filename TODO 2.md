# 📋 TODO - RunningMan / SquadRun

> **Dernière mise à jour :** 27 Décembre 2025  
> **Version :** Phase 1 MVP en cours

---

## 🚨 PRIORITÉ IMMÉDIATE - Bugs Critiques

### 🔴 Crash au démarrage
- [ ] **URGENT** : Corriger l'initialisation Firebase
  - Problème : `FirebaseApp.configure()` pas appelé avant Auth
  - Solution : Ajouter `init()` dans `@main struct`
  - Fichier : `RunningManApp.swift`

### 🔴 Erreurs SessionService.swift
- [ ] Résoudre les erreurs de compilation dans `SessionService.swift`
  - `SessionModel` ambigu
  - `Logger.Category.sessions` manquant
  - `SessionError` introuvable
  - Voir les erreurs détaillées dans le fichier

---

## 🏗️ Phase 1 - MVP Core Features

### ✅ Architecture & UI (COMPLÉTÉ)

#### Core
- [x] Point d'entrée app avec Firebase setup
- [x] État global de l'application
- [x] Navigation root (Auth/Main)
- [x] Navigation tabs (3 onglets)

#### Models
- [x] User model
- [x] Squad & SquadMember models
- [x] RunSession model
- [x] RunnerLocation model
- [x] Message model

#### Design System
- [x] Palette de couleurs Dark Mode
- [x] Composants UI réutilisables
- [x] CustomTextField
- [x] CommunicationButton
- [x] MapControlButton
- [x] Cards (Session, Marathon, Squad, Stat)
- [x] RunnerAvatar

---

### 🔥 Firebase Backend (EN COURS)

#### Configuration Firebase
- [x] Projet Firebase créé
- [x] Authentication activée (Email/Password)
- [x] Firestore Database créée
- [x] Storage bucket créé
- [ ] GoogleService-Info.plist vérifié et ajouté au projet
- [ ] Firebase SDK correctement initialisé dans l'app

#### Services Backend
- [x] AuthenticationService (créé)
- [x] FirestoreService (créé)
- [x] LocationService (créé)
- [ ] SessionService (bugs à corriger)
- [ ] MessageService
- [ ] PhotoService

#### Collections Firestore
- [x] Schema défini (`FirebaseSchema.swift`)
- [ ] Collections créées :
  - [ ] `users`
  - [ ] `squads`
  - [ ] `sessions`
  - [ ] `messages`
  - [ ] `locations`
- [ ] Règles de sécurité configurées
- [ ] Index composites créés

---

### 🔐 Authentication (COMPLÉTÉ)

- [x] Vue Login/Signup
- [x] AuthViewModel avec @Observable
- [x] Validation des champs
- [x] Création de compte Firebase
- [x] Connexion
- [x] Déconnexion
- [x] Persistance de session
- [x] Création profil utilisateur dans Firestore
- [x] Gestion erreurs avec ErrorBanner
- [x] États de chargement
- [x] AutoFill passwords (optionnel)

---

### 👥 Squads (COMPLÉTÉ UI / Backend partiel)

#### UI Complétée
- [x] Liste des squads
- [x] SquadCard avec aperçu membres
- [x] Empty state
- [x] Modal création squad
- [x] Modal rejoindre squad
- [x] Code unique de squad
- [x] Toggle Public/Privé

#### Backend À Connecter
- [ ] Créer squad dans Firestore
- [ ] Rejoindre squad avec code
- [ ] Lister les squads de l'utilisateur
- [ ] Sync temps réel des squads
- [ ] Gestion des membres
- [ ] Distinction Coureurs/Supporters

---

### 🏃 Sessions - Écran Principal (COMPLÉTÉ UI / Backend partiel)

#### UI Complétée
- [x] Carte MapKit plein écran
- [x] ActiveSessionCard
- [x] MarathonProgressCard
- [x] Avatars des coureurs (scroll horizontal)
- [x] CommunicationBar (Micro, Photo, Messages)
- [x] Contrôles carte (centrer, zoom)
- [x] Annotations coureurs sur carte
- [x] Affichage distances

#### Backend À Connecter
- [ ] Créer une session
- [ ] Rejoindre/quitter une session
- [ ] Démarrer/arrêter tracking GPS
- [ ] Envoyer positions en temps réel
- [ ] Sync positions des autres coureurs
- [ ] Pause/Resume session
- [ ] Terminer session
- [ ] Calcul de distance parcourue
- [ ] Calcul de vitesse moyenne/max

---

### 📍 Localisation GPS (COMPLÉTÉ Config / Backend partiel)

#### Configuration
- [x] CoreLocation setup
- [x] LocationManager dans SessionsViewModel
- [x] Permissions Info.plist
- [x] Background Modes configuré

#### Fonctionnalités
- [x] Demande de permissions
- [x] Tracking position utilisateur
- [x] Affichage sur carte
- [ ] **Envoi vers Firebase en temps réel**
- [ ] **Observation positions autres coureurs**
- [ ] Optimisation batterie (réduire fréquence si arrêt)
- [ ] Gestion perte de signal GPS
- [ ] Calcul de distance avec précision

---

### 💬 Messages & Communication (NON DÉMARRÉ)

#### Text-to-Speech
- [ ] TextToSpeechService
- [ ] Configuration AVAudioSession
- [ ] Conversion message texte → audio
- [ ] Lecture automatique pour coureurs
- [ ] Queue de messages
- [ ] Gestion interruptions

#### Messages Texte
- [ ] MessageService
- [ ] Envoyer message dans session
- [ ] Recevoir messages temps réel
- [ ] Badge non-lus sur bouton Messages
- [ ] Vue liste de messages
- [ ] Notification sonore nouveau message

---

### 📷 Photos (NON DÉMARRÉ)

- [ ] PhotoService
- [ ] Prendre photo depuis session
- [ ] Upload vers Firebase Storage
- [ ] Géolocalisation de la photo
- [ ] Afficher dans timeline
- [ ] Télécharger photos
- [ ] Miniatures optimisées
- [ ] Galerie de session

---

### 👤 Profile (COMPLÉTÉ UI / Backend partiel)

#### UI Complétée
- [x] Avatar et info utilisateur
- [x] StatCards (Courses, Distance, Squads)
- [x] Options menu
- [x] Bouton déconnexion

#### Backend À Connecter
- [ ] Charger profil depuis Firestore
- [ ] Mettre à jour profil
- [ ] Calculer statistiques réelles
- [ ] Historique des courses
- [ ] Upload photo de profil
- [ ] Paramètres utilisateur

---

## 🔧 Améliorations & Polish

### Gestion d'Erreurs
- [x] ErrorBanner composant
- [ ] Gestion perte connexion réseau
- [ ] Retry automatique pour requêtes
- [ ] Messages d'erreur utilisateur clairs
- [ ] Logs détaillés pour debug

### UX / États
- [x] ProgressView pendant chargements
- [ ] Skeleton loaders
- [ ] Pull-to-refresh
- [ ] États vides avec illustrations
- [ ] Animations de transitions
- [ ] Haptic feedback

### Performance
- [ ] Cache local des données Firestore
- [ ] Offline persistence Firestore
- [ ] Optimisation batterie GPS
- [ ] Compression images avant upload
- [ ] Pagination des listes
- [ ] Debouncing des recherches

### Tests
- [ ] Tests unitaires ViewModels
- [ ] Tests services Firebase
- [ ] Tests LocationManager
- [ ] Tests UI (UI Testing)
- [ ] Tests intégration

---

## 🎯 Phase 2 - Features Avancées (À PLANIFIER)

### Audio Live
- [ ] Push-to-Talk (micro en temps réel)
- [ ] AVAudioSession configuration
- [ ] Streaming audio Firebase
- [ ] Mix avec TTS

### Live Activities
- [ ] Configuration Live Activity
- [ ] Widget Lock Screen
- [ ] Dynamic Island
- [ ] Mise à jour temps réel stats

### Bluetooth Proximity
- [ ] CoreBluetooth setup
- [ ] Détection proximité coureurs
- [ ] Notification "coureur proche"
- [ ] Groupement automatique

### Rôles & Permissions
- [ ] Admin squad
- [ ] Modérateur
- [ ] Inviter membres
- [ ] Exclure membres
- [ ] Permissions fines

### Notifications
- [ ] Push notifications setup
- [ ] Notification nouveau message
- [ ] Notification début session
- [ ] Notification proximité coureur
- [ ] Badges app

---

## 🎯 Phase 3 - Gamification (FUTUR)

### Galerie Photos
- [ ] Timeline de session
- [ ] Photos géolocalisées
- [ ] Filtres et effets
- [ ] Partage social

### Applaudimètre
- [ ] Compteur d'encouragements
- [ ] Animation visuelle
- [ ] Effets sonores
- [ ] Classement supporters

### Achievements
- [ ] Badges de progression
- [ ] Objectifs personnels
- [ ] Classements squad
- [ ] Défis hebdomadaires

### Analytics
- [ ] Statistiques détaillées
- [ ] Graphiques progression
- [ ] Comparaison avec autres
- [ ] Export données

---

## 📱 Configuration Xcode

### Info.plist (COMPLÉTÉ)
- [x] NSLocationWhenInUseUsageDescription
- [x] NSLocationAlwaysAndWhenInUseUsageDescription
- [x] NSCameraUsageDescription
- [x] NSPhotoLibraryUsageDescription
- [ ] NSMicrophoneUsageDescription (Phase 2)

### Capabilities
- [x] Background Modes: Location updates
- [ ] Push Notifications
- [ ] Associated Domains (AutoFill)

### Assets
- [x] Color Assets (DarkNavy, CoralAccent, etc.)
- [ ] App Icon
- [ ] Launch Screen
- [ ] SF Symbols custom (si besoin)

---

## 🐛 Bugs Connus

### Critiques
1. **Crash au démarrage** - Firebase non initialisé
2. **SessionService** - Erreurs de compilation multiples

### Mineurs
- [ ] Vérifier que les animations sont fluides
- [ ] Tester sur devices physiques (GPS)
- [ ] Vérifier gestion mémoire (leaks)

---

## 📝 Notes de Développement

### Priorités Actuelles
1. 🔥 Corriger crash Firebase au démarrage
2. 🔥 Corriger erreurs SessionService
3. 🔥 Tester auth complète (signup/login)
4. 🔥 Implémenter création/join session
5. 🔥 Sync GPS temps réel vers Firebase

### Décisions Techniques
- ✅ SwiftUI + Combine
- ✅ @Observable au lieu de @ObservableObject
- ✅ Firebase pour backend
- ✅ CoreLocation pour GPS
- ✅ MapKit pour cartes
- ⏳ AVFoundation pour audio (Phase 2)

### Dépendances
```
- Firebase Auth
- Firebase Firestore
- Firebase FirestoreSwift
- Firebase Storage
- (Future: Firebase Functions)
```

### Environnement
- **Xcode** : 15+
- **iOS** : 17.0+
- **Swift** : 6.0
- **Bundle ID** : `com.runningman.app` (à confirmer)

---

## ✅ Changelog

### 27 Décembre 2025
- ✅ Nettoyage fichiers MD obsolètes
- ✅ Création TODO.md centralisé
- 🔥 Identification crash Firebase au démarrage
- 🔥 Identification erreurs SessionService

### 26 Décembre 2025
- ✅ Migration @Observable complète
- ✅ Intégration SquadVM
- ✅ Implémentation redirection après création session

### 23 Décembre 2025
- ✅ Architecture complète Phase 1
- ✅ Tous les écrans UI créés
- ✅ Design system implémenté
- ✅ Models définis
- ✅ Firebase schema documenté

---

**Pour toute question ou clarification, se référer à :**
- `README.md` - Vue d'ensemble
- `ARCHITECTURE.md` - Détails techniques
- `FILE_TREE.md` - Structure des fichiers
