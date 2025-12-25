//
//  StrategyCodingwithAgent.MD
//  RunningMan
//
//  Created by jocelyn GIARD on 19/12/2025.
//

# Stratégie optimale Xcode + Claude pour vos projets iOS

## 🎯 Workflow recommandé en 5 phases

### **Phase 1 : Cadrage & Design (1 conversation)**
- Brief fonctionnel (objectif, cible, contraintes)
- Architecture de l'information (arborescence des vues)
- Design system (couleurs, typos, composants réutilisables)
- User flows principaux
→ Livrable : Document de conception + wireframes textuels

### **Phase 2 : Architecture technique (1 conversation)**
- Structure des dossiers et fichiers
- Modèle de données (SwiftData/Core Data)
- Services et managers (NetworkManager, LogManager, etc.)
- Patterns (MVVM, Repository, etc.)
→ Livrable : Schéma d'architecture + checklist des fichiers


### **Phase 3 : Développement itératif (plusieurs conversations)**
Par fonctionnalité isolée :
1. Je génère le code d'UN fichier à la fois
2. Vous testez dans Xcode
3. Vous validez ou demandez ajustements
4. On passe au fichier suivant
→ Une fonctionnalité = 1 conversation dédiée


### **Phase 4 : Intégration & Logs (1 conversation par cycle)**
- Consolidation des composants
- Ajout du système d'observabilité
- Tests d'intégration
→ Livrable : Build fonctionnel testable

### **Phase 5 : Documentation & Déploiement**
- README.md complet
- Documentation inline (DocC)
- Guide de déploiement
→ Livrable : Projet production-ready
---

## 📋 Instructions à conserver dans vos Préférences Claude

Copiez-collez ceci dans **Paramètres > Profil > Préférences** :

CONTEXTE iOS : Je développe des apps iOS avec Xcode. Je ne code pas mais maîtrise les concepts techniques (15 ans dans la tech).

COMMUNICATION :
- Répondre en français
- Expliquer les concepts avant le code
- Proposer des alternatives quand pertinent

STRATÉGIE DE DÉVELOPPEMENT :
- Développement phase par phase avec validation à chaque étape
- Un fichier/composant à la fois (fichiers < 300 lignes)
- Code modulaire et cloisonné (responsabilité unique)
- Archiver chaque modification dans un CHANGELOG.md

QUALITÉ DU CODE :
Toujours inclure :
1. Documentation inline (/// pour DocC)
2. Gestion d'erreurs exhaustive (do-catch, Result)
3. Logging avec toggle DEBUG (print + OSLog)
4. Accessibilité (accessibilityLabel, VoiceOver)
5. Preview SwiftUI pour chaque vue
6. Commentaires explicatifs pour logique complexe

ARCHITECTURE :
- MVVM strict (Model, ViewModel, View séparés)
- Services isolés (NetworkService, StorageService, etc.)
- Dépendances injectées (testabilité)
- SwiftData/Core Data pour persistance
- Async/await pour asynchrone

OPTIMISATION TOKENS :
- Ne générer qu'un seul fichier par réponse
- Omettre les imports standards sauf si spécifiques
- Résumer le contexte au lieu de répéter le code existant
- Utiliser des références ("modifier le ViewModel créé précédemment")

LIVRABLES ATTENDUS :
Pour chaque fichier généré :
1. Nom et chemin du fichier
2. Code complet du fichier
3. Explication des choix techniques
4. Checklist de tests à effectuer
5. Prochaine étape suggérée

CONTRAINTES MÉTIER :
- Sécurité : pas de données sensibles en clair
- Performance : lazy loading, cache intelligent
- Écodesign : limiter les appels réseau/batterie
- Accessibilité : iOS guidelines strictes

---
## 🔧 Outils complémentaires recommandés

### **1. Structure de projet type**
MonApp/
├── App/
│   ├── MonAppApp.swift
│   └── Configuration/
├── Core/
│   ├── Models/
│   ├── Services/
│   └── Utilities/
├── Features/
│   ├── FeatureA/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
├── Design/
│   └── Components/
├── Resources/
└── Documentation/
    ├── CHANGELOG.md
    └── ARCHITECTURE.md


### **2. Template de CHANGELOG.md** (à créer)
# Changelog - [Nom de l'app]

## [Phase en cours] - AAAA-MM-JJ

### Ajouté
- Fichier `XYZ.swift` : Description fonctionnalité

### Modifié
- `ABC.swift` : Correction du bug X

### Décisions techniques
- Choix de SwiftData plutôt que Core Data car...

## [Prochaine phase]
- [ ] Fonctionnalité à implémenter


### **3. Système de logging à implémenter**
// Logger.swift - À créer en priorité
import OSLog

enum Logger {
    static var isDebugMode = false // Toggle
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app"
    
    static func log(_ message: String, category: String = "General") {
        if isDebugMode {
            let logger = OSLog(subsystem: subsystem, category: category)
            os_log("%{public}@", log: logger, type: .debug, message)
        }
    }
}

---
## 💡 Workflow conversation optimisé

### **Début de projet :**
"Je veux créer une app [DESCRIPTION]. 
Commençons par la Phase 1 : définir le design et l'arborescence."

### **Pendant le développement :**
"Génère le fichier [NOM] pour la fonctionnalité [X].
Rappel du contexte : [résumé en 2 lignes]"

### **Pour modifications :**
"Dans le fichier [NOM], modifier la fonction [Y] pour [RAISON].
Seulement le code modifié, pas tout le fichier."

---
## ⚡ Réduction de la consommation de tokens
1. **Conversations dédiées** : 1 fonctionnalité = 1 chat (évite de recharger tout le contexte)
2. **Résumés de contexte** : En début de conversation suivante, donnez un résumé de 3-4 lignes
3. **Code incrémental** : Demandez uniquement les modifications sans jamais ecraser un fichier complet, pas la réécriture complète systématique quand on change juste quelques lignes
4. **Artefacts courts** : Visez 100-200 lignes max par fichier
5. **Documentation externe** : Gardez l'architecture dans un fichier séparé que vous référencez

---

## 🎬 Exemple de démarrage
**Vous :**
> "Je veux créer une app de suivi de marathon appelée RunTracker. Phase 1 : propose-moi l'arborescence des vues et le design system."

**Claude générera :**
- Liste des écrans
- Navigation entre écrans
- Design tokens (couleurs, espacements)
- Wireframes textuels

**Puis vous validez et passez à Phase 2, etc.**

---

Cette approche vous garantit un code **industrialisable, documenté, traçable et évolutif** tout en optimisant votre consommation de tokens. Voulez-vous qu'on démarre avec un projet concret pour tester ce workflow ?
