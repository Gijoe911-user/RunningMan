# 🗂️ Organisation des Fichiers - RunningMan

**Organisation par dossier logique pour faciliter la navigation**

---

## 📂 Structure Recommandée

```
RunningMan/
│
├── 📱 App/                                    # Point d'entrée
│   ├── RunningManApp.swift                   ✅ Entry point
│   └── ContentView.swift                     ✅ Root navigation
│
├── 🎨 Core/                                   # Composants centraux
│   ├── Models/
│   │   ├── UserModel.swift                   ✅ Modèle utilisateur
│   │   ├── SquadModel.swift                  ✅ Modèle squad
│   │   ├── SessionModel.swift                ❌ À créer
│   │   └── MessageModel.swift                ❌ À créer
│   │
│   ├── Services/
│   │   ├── AuthService.swift                 ✅ Authentication complète
│   │   ├── SquadService.swift                ✅ Gestion squads
│   │   ├── SessionService.swift              ❌ À créer
│   │   ├── LocationService.swift             ❌ À créer
│   │   ├── MessageService.swift              ❌ À créer
│   │   └── PhotoService.swift                ❌ À créer
│   │
│   ├── Helpers/
│   │   ├── KeychainHelper.swift              ✅ Sauvegarde sécurisée
│   │   ├── BiometricAuthHelper.swift         ✅ Face ID / Touch ID
│   │   ├── Logger.swift                      ✅ Logging (si existe)
│   │   └── Constants.swift                   ✅ Constantes
│   │
│   └── Extensions/
│       ├── Color+Extensions.swift            ❓ À créer si nécessaire
│       └── View+Extensions.swift             ❓ À créer si nécessaire
│
├── 🎭 Features/                               # Fonctionnalités par module
│   │
│   ├── Authentication/
│   │   ├── Views/
│   │   │   └── LoginView.swift               ✅ Connexion/Inscription
│   │   │
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift           ✅ Logic authentification
│   │
│   ├── Squads/
│   │   ├── Views/
│   │   │   ├── SquadsListView.swift          ✅ Liste des squads
│   │   │   ├── CreateSquadView.swift         ✅ Création squad
│   │   │   ├── JoinSquadView.swift           ✅ Rejoindre squad
│   │   │   ├── SquadDetailView.swift         🚧 Détail squad
│   │   │   └── Components/
│   │   │       ├── SquadCard.swift           ✅ (dans SquadsListView)
│   │   │       └── EmptySquadsView.swift     ✅ (dans SquadsListView)
│   │   │
│   │   └── ViewModels/
│   │       └── SquadsViewModel.swift         ✅ Logic squads
│   │
│   ├── Sessions/
│   │   ├── Views/
│   │   │   ├── SessionsListView.swift        🚧 Vue principale
│   │   │   ├── MapView.swift                 🚧 Carte MapKit
│   │   │   ├── CreateSessionView.swift       ❌ À créer
│   │   │   └── Components/
│   │   │       ├── ActiveSessionCard.swift   ❌ À extraire
│   │   │       ├── RunnerAvatar.swift        ❌ À extraire
│   │   │       └── CommunicationBar.swift    ❌ À extraire
│   │   │
│   │   └── ViewModels/
│   │       └── SessionsViewModel.swift       🚧 Logic sessions
│   │
│   ├── Messages/
│   │   ├── Views/
│   │   │   └── MessagesView.swift            ❌ À créer
│   │   │
│   │   └── ViewModels/
│   │       └── MessagesViewModel.swift       ❌ À créer
│   │
│   └── Profile/
│       ├── Views/
│       │   └── ProfileView.swift             ✅ Profil utilisateur
│       │
│       └── ViewModels/
│           └── ProfileViewModel.swift        ❌ À créer si nécessaire
│
├── 📚 Documentation/
│   ├── STATUS.md                             ✅ État actuel (nouveau)
│   ├── TODO.md                               ✅ Liste des tâches
│   ├── QUICKSTART.md                         ✅ Guide démarrage
│   ├── FILE_TREE.md                          ✅ Structure fichiers
│   ├── INDEX_AUTOFILL_FILES.md               ✅ Guide AutoFill
│   ├── ORGANIZATION.md                       ✅ Ce fichier
│   └── StrategyCodingwithAgent.md            ✅ Stratégie dev
│
└── 🎨 Resources/
    ├── Assets.xcassets/
    │   └── Colors/                           ✅ Palette couleurs
    │       ├── DarkNavy.colorset
    │       ├── CoralAccent.colorset
    │       ├── PinkAccent.colorset
    │       ├── BlueAccent.colorset
    │       ├── PurpleAccent.colorset
    │       ├── GreenAccent.colorset
    │       └── YellowAccent.colorset
    │
    └── Config/
        ├── GoogleService-Info.plist          ✅ Firebase config
        └── Info.plist                        ✅ Permissions
```

---

## 📊 État Actuel vs Structure Idéale

### ✅ Bien Organisé
```
✅ AuthService.swift                    # Service d'auth complet
✅ SquadService.swift                   # Service squads complet
✅ UserModel.swift                      # Modèle utilisateur
✅ SquadModel.swift                     # Modèle squad
✅ KeychainHelper.swift                 # Helper keychain
✅ BiometricAuthHelper.swift            # Helper biométrie
✅ LoginView.swift                      # Vue connexion
✅ Documentation/                       # Docs bien organisées
```

### 🚧 À Réorganiser

#### 1. Features/Squads/ - Noms de fichiers inconsistants
**Actuel :**
```
FeaturesSquadsSquadsListView.swift      ❌ Nom trop long
FeaturesSquadsSquadsViewModel.swift     ❌ Nom trop long
```

**Recommandé :**
```
SquadsListView.swift                    ✅ Plus simple
SquadsViewModel.swift                   ✅ Plus clair
```

**Action :** Renommer les fichiers (ou garder si Xcode les organise bien)

---

#### 2. Components à Extraire

**Actuellement dans SquadsListView.swift :**
```swift
struct SquadCard: View { }              # À extraire
struct EmptySquadsView: View { }        # À extraire
```

**Recommandé :**
```
Features/Squads/Views/Components/
├── SquadCard.swift                     # Vue réutilisable
└── EmptySquadsView.swift               # Vue réutilisable
```

**Avantage :** Réutilisabilité, fichiers plus petits, meilleure lisibilité

**Priorité :** 🟢 Basse (optionnel, mais bonne pratique)

---

#### 3. Sessions - À Structurer

**Actuel :**
```
FeaturesSessionsSessionsListView.swift  # Vue principale avec tout dedans
```

**Recommandé :**
```
Features/Sessions/Views/
├── SessionsListView.swift              # Vue principale (simplifiée)
├── MapView.swift                       # Carte extraite
└── Components/
    ├── ActiveSessionCard.swift         # Card session active
    ├── MarathonProgressCard.swift      # Card progression
    ├── RunnerAvatar.swift              # Avatar coureur
    └── CommunicationBar.swift          # Barre communication
```

**Priorité :** 🟡 Moyenne (améliore maintenabilité)

---

## 🎯 Plan de Réorganisation (Optionnel)

### Option 1 : Réorganisation Complète (3-4h)
**Avantages :**
- ✅ Structure professionnelle
- ✅ Fichiers plus petits et lisibles
- ✅ Composants réutilisables
- ✅ Facilite le travail en équipe

**Inconvénients :**
- ❌ Temps nécessaire
- ❌ Risque de casser quelque chose
- ❌ Retarde les features

**Recommandation :** ⛔ **Pas maintenant** - Finir MVP d'abord

---

### Option 2 : Réorganisation Progressive (Recommandé)
**Principe :** Réorganiser au fur et à mesure du développement

**Exemple :**
- Quand vous travaillez sur `SessionsListView`, extrayez les composants
- Quand vous créez `MessageService`, mettez-le dans `Core/Services/`
- Gardez l'existant tel quel s'il fonctionne

**Avantages :**
- ✅ Pas de refactoring massif
- ✅ Structure s'améliore progressivement
- ✅ Pas de risque de tout casser

**Recommandation :** ✅ **C'est ce qu'on fait déjà**

---

### Option 3 : Garder Tel Quel
**Si :** L'app fonctionne, vous êtes seul sur le projet, priorité = features

**Recommandation :** ✅ **Valide pour MVP**

---

## 📝 Conventions de Nommage

### Fichiers
```
✅ PascalCase pour les Views         # LoginView.swift
✅ PascalCase pour les Models        # UserModel.swift
✅ PascalCase pour les Services      # AuthService.swift
✅ PascalCase pour les ViewModels    # SquadsViewModel.swift
✅ PascalCase pour les Helpers       # KeychainHelper.swift
```

### Variables & Propriétés
```swift
✅ camelCase pour les variables      # var currentUser: User?
✅ camelCase pour les fonctions      # func loadSquads()
✅ PascalCase pour les types         # enum SquadMemberRole
✅ UPPER_SNAKE_CASE pour constantes  # let MAX_SQUAD_SIZE = 50
```

### Fichiers Actuels à Renommer (Optionnel)
```
FeaturesSquadsSquadsListView.swift       →  SquadsListView.swift
FeaturesSquadsSquadsViewModel.swift      →  SquadsViewModel.swift
FeaturesSessionsSessionsListView.swift   →  SessionsListView.swift
```

**Note :** Si Xcode affiche le nom court dans l'éditeur, ce n'est pas urgent

---

## 🗄️ Organisation par Dossier

### Core/ - Composants centraux réutilisables
**Contient :**
- Models (structures de données)
- Services (business logic)
- Helpers (utilitaires)
- Extensions (extensions Swift)

**Ne contient pas :**
- Views (dans Features/)
- ViewModels (dans Features/)

---

### Features/ - Fonctionnalités par module
**Structure par feature :**
```
Features/[NomFeature]/
├── Views/                  # Toutes les vues de cette feature
│   ├── [MainView].swift
│   ├── [DetailView].swift
│   └── Components/         # Composants réutilisables
│       └── [Component].swift
│
└── ViewModels/            # ViewModels de cette feature
    └── [Feature]ViewModel.swift
```

**Avantages :**
- ✅ Facile de trouver tous les fichiers d'une feature
- ✅ Facilite le travail en parallèle sur différentes features
- ✅ Peut supprimer une feature complète facilement

---

## 📦 Dépendances Entre Modules

```
┌─────────────────────────────────────┐
│           App Layer                 │
│   (RunningManApp, ContentView)     │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│        Features Layer               │
│  (Authentication, Squads, etc.)     │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│          Core Layer                 │
│   (Services, Models, Helpers)       │
└─────────────────────────────────────┘
```

**Règles :**
- ✅ Features peuvent utiliser Core
- ✅ Core ne doit PAS importer Features
- ✅ Features ne devraient pas s'importer entre elles

---

## 🎨 Composants Partagés

### Actuellement dans les Views (À Extraire ?)
```
SquadCard                    # Dans SquadsListView
EmptySquadsView              # Dans SquadsListView
ActiveSessionCard            # À extraire de SessionsListView
RunnerAvatar                 # À extraire de SessionsListView
CommunicationBar             # À extraire de SessionsListView
```

### Option : Créer un dossier Shared/
```
Shared/
└── Components/
    ├── Cards/
    │   ├── SquadCard.swift
    │   └── ActiveSessionCard.swift
    │
    ├── Buttons/
    │   └── CommunicationButton.swift
    │
    └── Avatars/
        └── RunnerAvatar.swift
```

**Priorité :** 🟢 Basse (Phase 2 ou quand beaucoup de réutilisation)

---

## 📂 Suggestion de Migration Progressive

### Phase 1 : Compléter MVP (Priorité Actuelle) ✅
- ❌ Ne pas réorganiser maintenant
- ✅ Créer nouveaux fichiers dans la bonne structure
- ✅ Garder l'existant tel quel

**Fichiers à créer avec bonne structure :**
```
Core/Services/SessionService.swift          ✅ Nouveau → bon emplacement
Core/Services/LocationService.swift         ✅ Nouveau → bon emplacement
Core/Models/SessionModel.swift              ✅ Nouveau → bon emplacement
Features/Sessions/ViewModels/SessionsViewModel.swift  ✅ Bon emplacement
```

---

### Phase 2 : Refactoring (Après MVP)
**Quand :** MVP fonctionne, tests passent, avant ajout de grosses features

**Actions :**
1. Renommer fichiers (FeaturesSquadsSquadsListView → SquadsListView)
2. Extraire composants dans Components/
3. Créer dossier Shared/ si beaucoup de réutilisation
4. Tester que tout fonctionne

**Temps estimé :** 2-3 heures

**Bénéfices :**
- Code plus maintenable
- Onboarding nouveaux devs plus facile
- Base solide pour Phase 2

---

## 📋 Checklist d'Organisation

### Organisation Actuelle ✅
- [x] Services séparés (Auth, Squad)
- [x] Models séparés (User, Squad)
- [x] Helpers séparés (Keychain, Biometric)
- [x] Documentation centralisée
- [x] Constants séparé

### À Améliorer Plus Tard 🔄
- [ ] Renommer fichiers Features (enlever préfixe)
- [ ] Extraire composants dans Components/
- [ ] Créer dossier Shared/ pour composants réutilisables
- [ ] Ajouter tests unitaires par module
- [ ] Documenter chaque module avec README

---

## 🎯 Recommandation Finale

### Pour Aujourd'hui et Cette Semaine
✅ **Garder la structure actuelle**
✅ **Créer nouveaux fichiers dans la bonne structure**
✅ **Focus sur les fonctionnalités**

### Après MVP (dans 2-3 semaines)
✅ **Faire un refactoring d'organisation**
✅ **Extraire les composants**
✅ **Nettoyer les noms de fichiers**

---

## 📁 Structure Finale Objectif (Post-Refactoring)

```
RunningMan/
├── App/
├── Core/
│   ├── Models/
│   ├── Services/
│   ├── Helpers/
│   └── Extensions/
├── Features/
│   ├── Authentication/
│   ├── Squads/
│   ├── Sessions/
│   ├── Messages/
│   └── Profile/
├── Shared/
│   └── Components/
├── Documentation/
└── Resources/
```

**Status :** 80% déjà atteint ✅

---

## 💡 Conseil

> **"Make it work, make it right, make it fast"**
> 
> 1. **Make it work** ← Vous êtes ici (MVP)
> 2. **Make it right** ← Refactoring après MVP
> 3. **Make it fast** ← Optimisations Phase 2

**Ne vous bloquez pas sur l'organisation parfaite maintenant.**
**L'important : finir le MVP fonctionnel.**

---

**Dernière mise à jour :** 24 Décembre 2025  
**Version :** 1.0
