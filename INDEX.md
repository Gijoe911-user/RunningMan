# 📋 Index de la Documentation - RunningMan

**Guide de navigation rapide dans toute la documentation du projet**

---

## 🎯 Par Où Commencer ?

```
Vous êtes nouveau sur le projet ?
        ↓
    Lisez README.md (si existe) ou STATUS.md
        ↓
Vous voulez développer une feature ?
        ↓
    Consultez TODO.md pour les tâches prioritaires
        ↓
Vous cherchez la structure du projet ?
        ↓
    Consultez ORGANIZATION.md ou FILE_TREE.md
```

---

## 📚 Documents Principaux

### 1. 📊 STATUS.md - État Actuel du Projet ⭐
**Ce que c'est :** Vue complète de ce qui fonctionne et ce qui reste à faire

**Contient :**
- ✅ Ce qui fonctionne (testé)
- 🚧 Ce qui est en cours
- ❌ Ce qui reste à faire
- 📊 Progression globale (60%)
- 🐛 Problèmes connus
- 🎯 Prochaines étapes recommandées

**Quand consulter :** Avant de commencer à coder, pour savoir où en est le projet

**Dernière mise à jour :** 24 Décembre 2025

---

### 2. 📋 TODO.md - Liste des Tâches Prioritaires ⭐
**Ce que c'est :** Liste détaillée de toutes les tâches à faire, ordonnées par priorité

**Contient :**
- ✅ Tâches complétées
- 🔴 Priorité haute (cette semaine)
- 🟡 Priorité moyenne (semaine prochaine)
- 🟢 Priorité basse (plus tard)
- 📊 Estimations de temps
- 🎯 Ordre de développement recommandé
- 💻 Code templates pour chaque service

**Quand consulter :** Tous les jours, pour savoir quoi faire ensuite

**Dernière mise à jour :** 24 Décembre 2025

---

### 3. 🗂️ ORGANIZATION.md - Organisation des Fichiers
**Ce que c'est :** Guide sur la structure du projet et conventions de nommage

**Contient :**
- 📂 Structure recommandée (idéale)
- 📊 État actuel vs idéal
- 🚧 Fichiers à réorganiser (optionnel)
- 📝 Conventions de nommage
- 🎯 Plan de réorganisation progressive
- 💡 Conseils sur l'architecture

**Quand consulter :** 
- Quand vous créez un nouveau fichier (où le mettre ?)
- Quand vous voulez refactorer
- Quand vous ne savez pas comment nommer quelque chose

**Dernière mise à jour :** 24 Décembre 2025

---

### 4. 📁 FILE_TREE.md - Arborescence Complète
**Ce que c'est :** Vue détaillée de tous les fichiers du projet avec descriptions

**Contient :**
- 📂 Structure complète du projet
- 📊 Statistiques (nombre de fichiers, lignes de code)
- 🎯 Organisation par fonctionnalité
- 🗺️ Navigation flow
- 🎨 Design system
- 🔧 Services à créer
- 📱 Écrans par tab
- 📈 Progression Phase 1

**Quand consulter :**
- Vue d'ensemble du projet
- Comprendre l'architecture globale
- Trouver où est un fichier spécifique

---

### 5. 🚀 QUICKSTART.md - Guide de Démarrage Rapide
**Ce que c'est :** Configuration du projet en 15 minutes

**Contient :**
- ⚡ Configuration Firebase (5 min)
- ⚡ Configuration Xcode (5 min)
- ⚡ Build & Test (5 min)
- 🎯 Tests sur device physique
- 🐛 Troubleshooting

**Quand consulter :**
- Premier lancement du projet
- Configuration d'un nouvel environnement
- Onboarding nouveau développeur

---

### 6. 🔐 INDEX_AUTOFILL_FILES.md - Guide AutoFill & Face ID
**Ce que c'est :** Index complet de tous les documents sur AutoFill et biométrie

**Contient :**
- 📖 Liste de tous les guides AutoFill
- 💻 Helpers (KeychainHelper, BiometricAuthHelper)
- 🎯 Parcours recommandés (débutant, intermédiaire, avancé)
- 🔍 Recherche rapide
- ✅ Checklist

**Quand consulter :**
- Implémenter AutoFill
- Ajouter Face ID / Touch ID
- Problèmes de Keychain

---

### 7. 📖 StrategyCodingwithAgent.md - Stratégie de Développement
**Ce que c'est :** Stratégie de développement avec un assistant IA

**Contient :**
- 🎯 Méthodologie de travail
- 💡 Bonnes pratiques
- 🚀 Optimisations du workflow

**Quand consulter :**
- Comprendre comment le projet a été développé
- Améliorer votre workflow avec IA

---

### 8. 📋 INDEX.md - Ce Fichier
**Ce que c'est :** Index de navigation dans toute la documentation

**Quand consulter :** Quand vous êtes perdu et ne savez pas quel document lire

---

## 🗂️ Documents Techniques (Référence)

### Code & Configurations

#### 📄 Constants.swift
- Constantes Firebase
- Configuration app

#### 📄 GoogleService-Info.plist
- Configuration Firebase
- Clés API

#### 📄 Info.plist
- Permissions (GPS, caméra, etc.)
- Configuration app

---

## 🎯 Guides Par Cas d'Usage

### "Je débute sur le projet"
1. Lisez `STATUS.md` (5 min)
2. Lisez `QUICKSTART.md` (15 min)
3. Suivez `TODO.md` tâche #6 (30 min)

---

### "Je veux développer une nouvelle feature"
1. Consultez `TODO.md` - Quelle est la priorité ?
2. Consultez `STATUS.md` - Quelles sont les dépendances ?
3. Consultez `ORGANIZATION.md` - Où créer les fichiers ?
4. Développez
5. Mettez à jour `STATUS.md` si nécessaire

---

### "Je veux comprendre l'architecture"
1. Lisez `FILE_TREE.md`
2. Lisez `ORGANIZATION.md`
3. Regardez le code dans l'ordre :
   - Models (UserModel, SquadModel)
   - Services (AuthService, SquadService)
   - Views (LoginView, SquadsListView)

---

### "Je veux savoir ce qui reste à faire"
1. Consultez `STATUS.md` - Section "À Faire"
2. Consultez `TODO.md` - Liste détaillée
3. Choisissez une tâche prioritaire

---

### "Je veux implémenter AutoFill / Face ID"
1. Lisez `INDEX_AUTOFILL_FILES.md`
2. Suivez le guide recommandé pour votre niveau
3. Testez avec les checklists

---

### "J'ai un bug / problème"
1. Consultez `STATUS.md` - Section "Problèmes Connus"
2. Consultez `TODO.md` - Section "Debug Checklist"
3. Consultez `QUICKSTART.md` - Section "Troubleshooting"

---

### "Je veux organiser/refactorer"
1. Lisez `ORGANIZATION.md`
2. Suivez le plan de réorganisation progressive
3. Mettez à jour `FILE_TREE.md` si grosse modif

---

## 📊 Matrice de Décision Rapide

| Vous voulez... | Consultez... |
|---------------|-------------|
| Savoir où en est le projet | `STATUS.md` |
| Savoir quoi faire ensuite | `TODO.md` |
| Comprendre la structure | `ORGANIZATION.md` |
| Configurer le projet | `QUICKSTART.md` |
| Ajouter Face ID | `INDEX_AUTOFILL_FILES.md` |
| Vue d'ensemble complète | `FILE_TREE.md` |
| Trouver un fichier | `FILE_TREE.md` ou `ORGANIZATION.md` |
| Résoudre un bug | `STATUS.md` (Problèmes Connus) |
| Créer un nouveau service | `TODO.md` (templates) |

---

## 🎨 Ressources Design

### Palette de Couleurs
```
DarkNavy    #1A1F3A  ████  Fond principal
CoralAccent #FF6B6B  ████  CTA / Coureurs
PinkAccent  #FF85A1  ████  Messages
BlueAccent  #4ECDC4  ████  Supporters
Purple      #9B59B6  ████  Micro
Green       #2ECC71  ████  Actif
Yellow      #F1C40F  ████  Objectifs
```

### Composants UI Principaux
- `SquadCard` - Carte squad
- `ActiveSessionCard` - Session active
- `RunnerAvatar` - Avatar coureur
- `CommunicationButton` - Bouton communication

---

## 🔧 Services & Models

### Services Implémentés ✅
- `AuthService.swift` - Authentification
- `SquadService.swift` - Gestion squads
- `KeychainHelper.swift` - Sauvegarde sécurisée
- `BiometricAuthHelper.swift` - Face ID / Touch ID

### Services À Créer ❌
- `SessionService.swift` - Gestion sessions
- `LocationService.swift` - Tracking GPS
- `MessageService.swift` - Messagerie
- `PhotoService.swift` - Photos

### Models Implémentés ✅
- `UserModel.swift` - Utilisateur
- `SquadModel.swift` - Squad

### Models À Créer ❌
- `SessionModel.swift` - Session de course
- `MessageModel.swift` - Message

---

## 📈 Progression Globale

```
Phase 1 MVP: 60% complété

✅ Architecture        100%
✅ UI Design           100%
✅ Authentication      100%
🚧 Squads               75%
🚧 Sessions             20%
🚧 GPS Tracking         40%
❌ Messages              0%
❌ Photos                0%
```

**Estimation restante :** 25-30 heures

---

## 🎯 Prochaines Actions Recommandées

### Aujourd'hui
1. ✅ Tester "Rejoindre une squad" (30 min)
2. ✅ Corriger SquadDetailView (2-3h)

### Cette Semaine
3. 🔴 Créer SessionService (3-4h)
4. 🔴 Créer LocationService (4-5h)
5. 🔴 Intégrer MapView temps réel (3h)

### Semaine Prochaine
6. 🟡 Messages basiques (3-4h)
7. 🟡 Text-to-Speech (2h)
8. 🔴 Tests device physique (2-3h)

---

## 💾 Commandes Utiles

```bash
# Build
Cmd + B

# Run
Cmd + R

# Clean
Cmd + Shift + K

# Git
git add .
git commit -m "feat: description"
git push
```

---

## 🆘 Aide Rapide

### Vous êtes bloqué ?
1. Consultez le document approprié dans la section "Guides Par Cas d'Usage"
2. Recherchez dans `STATUS.md` (Problèmes Connus)
3. Consultez les templates de code dans `TODO.md`

### Vous ne trouvez pas un fichier ?
1. Consultez `FILE_TREE.md` pour l'arborescence complète
2. Utilisez la recherche Xcode (Cmd + Shift + O)

### Vous ne savez pas quoi faire ?
1. Consultez `TODO.md` - Section "Commencer Maintenant"
2. Suivez l'ordre recommandé

---

## ✅ Checklist de Lecture

Documentation essentielle (déjà lue ?) :
- [ ] `STATUS.md` - État du projet
- [ ] `TODO.md` - Tâches prioritaires
- [ ] `ORGANIZATION.md` - Structure du projet

Documentation optionnelle (selon besoins) :
- [ ] `QUICKSTART.md` - Configuration initiale
- [ ] `FILE_TREE.md` - Arborescence complète
- [ ] `INDEX_AUTOFILL_FILES.md` - AutoFill/Face ID
- [ ] `StrategyCodingwithAgent.md` - Méthodologie

---

## 🎉 Félicitations !

Vous avez maintenant une vue complète de la documentation du projet RunningMan.

**Tous les documents sont à jour et synchronisés (24 Décembre 2025)**

### Structure de la documentation :
```
Documentation/
├── INDEX.md                          ⭐ Ce fichier (navigation)
├── STATUS.md                         ⭐ État actuel
├── TODO.md                           ⭐ Tâches prioritaires
├── ORGANIZATION.md                   ⭐ Structure projet
├── FILE_TREE.md                      📂 Arborescence
├── QUICKSTART.md                     🚀 Config rapide
├── INDEX_AUTOFILL_FILES.md           🔐 AutoFill guide
└── StrategyCodingwithAgent.md        📖 Méthodologie
```

---

**Dernière mise à jour :** 24 Décembre 2025  
**Version :** 1.0  
**Status :** ✅ Documentation organisée et à jour

🚀 **Prêt à coder !**
