# 🏃 Architecture des Sessions d'Entraînement - RunningMan

## 📋 Vue d'ensemble

L'application permet désormais à **chaque coureur** de créer des sessions d'entraînement avec :
- ✅ **Localisation** : Lieu de rendez-vous pour retrouver les autres coureurs
- ✅ **Programmes d'entraînement** : Objectifs personnalisables (distance, temps, allure, fractionné)
- ✅ **Type de session** : Standard, Fractionné, Détente, ou Course (une seule à la fois)
- ✅ **Import/Export JSON** : Partage et réutilisation des programmes
- 🚧 **V2 : Apple Intelligence** : Génération de programmes adaptés

---

## 🏗️ Architecture des composants

### 1. **Modèles**

#### `TrainingProgramModel.swift`
```swift
struct TrainingProgram {
    var name: String
    var theme: TrainingTheme  // .standard, .interval, .recovery
    var targetDistance: Double?
    var targetDuration: Int?
    var targetPaceMin/Max: Int?
    var intervalSegments: [IntervalSegment]?
    var isPublic: Bool
    var usageCount: Int
}

enum TrainingTheme {
    case standard     // Course régulière
    case interval     // Fractionné
    case recovery     // Détente/Récupération
}

struct IntervalSegment {
    var type: .warmup / .work / .rest / .cooldown
    var duration: Int?
    var distance: Double?
    var targetPace: Int?
    var repetitions: Int
}
```

#### `SessionModel.swift` (étendu)
```swift
struct SessionModel {
    // Nouveau champs:
    var trainingProgramId: String?              // ID du programme associé
    var meetingLocationName: String?            // Ex: "Parc de la Tête d'Or"
    var meetingLocationCoordinate: GeoPoint?    // Coordonnées GPS
}
```

---

### 2. **Services**

#### `TrainingProgramService.swift`
Gère les opérations CRUD sur les programmes :

- **Création** : `createProgram(_:squadId:)`
- **Lecture** : `getPrograms(squadId:)`, `getUserPrograms(squadId:userId:)`
- **Mise à jour** : `updateProgram(_:squadId:)`
- **Suppression** : `deleteProgram(programId:squadId:)`
- **Association** : `attachProgramToSession(programId:sessionId:squadId:)`
- **Import/Export** : `exportProgram(_:)`, `importProgram(from:squadId:userId:)`

#### `SessionService.swift` (étendu)
Nouvelle méthode :
- `updateSessionFields(sessionId:fields:)` : Met à jour des champs spécifiques

---

### 3. **Vues**

#### `CreateSessionWithProgramView.swift`
Vue principale en **4 étapes** pour créer une session complète :

**Étape 1 : Informations de base**
- Titre de la session
- Type : Course (une seule active) ou Entraînement
- Thème : Standard / Fractionné / Détente

**Étape 2 : Localisation**
- Toggle "Définir un lieu de RDV"
- Sélection via `LocationPickerView`
- Affichage du nom + coordonnées GPS

**Étape 3 : Programme d'entraînement**
- Toggle "Associer un programme"
- Choisir un programme existant
- Créer un nouveau programme
- Affichage des objectifs (distance, temps, allure)

**Étape 4 : Récapitulatif**
- Vérification des informations
- Bouton "Créer la session"

**Indicateur de progression** : Points cliquables pour naviguer entre les étapes

---

## 🔧 Fonctionnalités clés

### 1. **Une seule session de Course à la fois**
```swift
if isRace {
    // Vérifier qu'il n'existe pas déjà une session active de type "race"
    let existingRace = try await SessionService.shared.getActiveRaceSessions(squadId: squadId)
    if !existingRace.isEmpty {
        throw SessionError.raceAlreadyActive
    }
}
```

### 2. **Programmes prédéfinis (Templates)**
```swift
TrainingProgram.templates(for: userId)
// Retourne :
// - 5 km Standard
// - 8 x 400m (fractionné)
// - Récupération 30 min
// - 10 km Endurance
```

### 3. **Import/Export JSON**
```swift
// Export
let jsonData = try program.exportToJSON()
let fileURL = try TrainingProgramService.shared.exportProgram(program)
// → TrainingProgram_5km_Standard_2025-12-30.json

// Import
let program = try TrainingProgramService.shared.importProgram(
    from: fileURL,
    squadId: squadId,
    userId: userId
)
```

Format JSON :
```json
{
  "name": "8 x 400m",
  "theme": "interval",
  "description": "Séance de fractionné court",
  "targetDistance": null,
  "targetDuration": null,
  "intervalSegments": [
    {
      "type": "warmup",
      "duration": 600,
      "repetitions": 1
    },
    {
      "type": "work",
      "distance": 400,
      "targetPace": 240,
      "repetitions": 8
    },
    {
      "type": "rest",
      "duration": 90,
      "repetitions": 8
    },
    {
      "type": "cooldown",
      "duration": 600,
      "repetitions": 1
    }
  ]
}
```

---

## 📱 Expérience utilisateur

### Création de session (flux complet)

1. **Coureur ouvre "Créer une session"**
   - Navigation en 4 étapes
   - Barre de progression visuelle
   - Possibilité de revenir en arrière

2. **Étape 1 : Infos de base**
   - Saisie du titre
   - Toggle "Session de Course" (limite : 1 seule active)
   - Choix du thème (Standard/Fractionné/Détente)

3. **Étape 2 : Lieu de RDV**
   - Toggle "Définir un lieu"
   - Carte interactive ou recherche d'adresse
   - Affichage du nom + coordonnées

4. **Étape 3 : Programme**
   - Toggle "Associer un programme"
   - **Choisir** parmi les programmes existants (personnels + publics)
   - **Créer** un nouveau programme (objectifs personnalisés)
   - **Importer** depuis un fichier JSON

5. **Étape 4 : Récapitulatif**
   - Vérification visuelle
   - Bouton "Créer et rejoindre"

---

## 🔐 Structure Firestore

```
squads/{squadId}/
  └── trainingPrograms/{programId}
      ├── name: string
      ├── theme: string
      ├── targetDistance: number
      ├── targetDuration: number
      ├── targetPaceMin: number
      ├── targetPaceMax: number
      ├── intervalSegments: array
      ├── isPublic: boolean
      ├── usageCount: number
      ├── createdBy: string
      ├── createdAt: timestamp
      └── updatedAt: timestamp

sessions/{sessionId}
  ├── ... (champs existants)
  ├── trainingProgramId: string (référence)
  ├── meetingLocationName: string
  └── meetingLocationCoordinate: GeoPoint
```

---

## 🚀 Prochaines étapes

### À implémenter maintenant :

1. **LocationPickerView** ✅ À créer
   - Carte MapKit interactive
   - Recherche d'adresse (MKLocalSearch)
   - Géolocalisation actuelle
   - Liste de lieux récents

2. **TrainingProgramPickerView** ✅ À créer
   - Liste des programmes personnels
   - Liste des programmes publics de la squad
   - Filtres par thème
   - Tri par popularité (usageCount)

3. **CreateTrainingProgramView** ✅ À créer
   - Formulaire pour créer un programme
   - Éditeur d'intervalles (fractionné)
   - Calcul automatique de durée estimée
   - Validation des objectifs

4. **Affichage du programme pendant la session** ✅ À faire
   - Dans `ActiveSessionDetailView`
   - Progression par rapport aux objectifs
   - Alertes lors des changements d'intervalle
   - Feedback en temps réel (allure actuelle vs cible)

5. **Restriction : Une seule session de Course** ✅ À implémenter
   ```swift
   func getActiveRaceSessions(squadId: String) async throws -> [SessionModel] {
       return try await db.collection("sessions")
           .whereField("squadId", isEqualTo: squadId)
           .whereField("activityType", isEqualTo: "race")
           .whereField("status", isEqualTo: "active")
           .getDocuments()
           .documents
           .compactMap { try? $0.data(as: SessionModel.self) }
   }
   ```

---

## 🧠 Version 2 : Apple Intelligence

### Objectif
Générer automatiquement un programme d'entraînement adapté au profil du coureur.

### Données nécessaires
- **Historique** : Sessions passées (distance, allure, durée)
- **Niveau** : Calculé à partir des performances récentes
- **Objectif** : Distance cible (ex: marathon = 42 km)
- **Disponibilité** : Nombre de jours d'entraînement par semaine

### Implémentation envisagée
```swift
import Foundation

class AppleIntelligenceTrainingGenerator {
    
    func generateProgram(
        for userId: String,
        targetDistance: Double,
        weeksToGoal: Int,
        sessionsPerWeek: Int
    ) async throws -> TrainingProgram {
        // 1. Analyser l'historique du coureur
        let history = try await getRunnerHistory(userId: userId)
        
        // 2. Calculer le niveau actuel (allure moyenne, distance max, VO2max estimé)
        let level = calculateLevel(from: history)
        
        // 3. Utiliser un LLM (via Foundation) pour générer un plan
        let prompt = """
        Crée un programme d'entraînement pour un coureur :
        - Niveau : \(level.description)
        - Objectif : \(targetDistance / 1000) km
        - Durée : \(weeksToGoal) semaines
        - Fréquence : \(sessionsPerWeek) sessions/semaine
        
        Format JSON avec sessions progressives incluant :
        - Endurance fondamentale
        - Fractionné court/long
        - Sorties longues
        - Récupération
        """
        
        // 4. Parser la réponse et créer le TrainingProgram
        let generatedProgram = try await callFoundationModel(prompt: prompt)
        return generatedProgram
    }
}
```

---

## 📊 Statistiques avancées (future V2)

### Suivi de progression par rapport au programme
```swift
struct ProgramProgressStats {
    var targetDistance: Double
    var completedDistance: Double
    var targetPace: Int  // sec/km
    var actualPace: Int
    var adherenceRate: Double  // % de respect du programme
    var estimatedCompletion: Date
}
```

### Alertes pendant la course
- "Ralentissez ! Allure cible : 5:30 /km, actuelle : 5:00 /km"
- "Changement d'intervalle dans 100m : Récupération 90 secondes"
- "Objectif atteint ! Distance : 5.0 km ✓"

---

## ✅ Résumé des fichiers créés

| Fichier | Description |
|---------|-------------|
| `TrainingProgramModel.swift` | Modèle de programme d'entraînement avec thèmes, objectifs, intervalles |
| `TrainingProgramService.swift` | Service CRUD + Import/Export JSON |
| `CreateSessionWithProgramView.swift` | Vue en 4 étapes pour créer une session complète |
| `SessionModel.swift` (modifié) | Ajout de `trainingProgramId`, `meetingLocationName`, `meetingLocationCoordinate` |
| `SessionService.swift` (modifié) | Ajout de `updateSessionFields()` |

---

## 🎯 Checklist d'intégration

- [x] Modèle `TrainingProgram` créé
- [x] Service `TrainingProgramService` implémenté
- [x] Vue `CreateSessionWithProgramView` créée
- [x] `SessionModel` étendu avec nouveaux champs
- [x] `SessionService.updateSessionFields()` ajouté
- [ ] `LocationPickerView` à implémenter
- [ ] `TrainingProgramPickerView` à implémenter
- [ ] `CreateTrainingProgramView` à implémenter
- [ ] Restriction "une seule session de Course" à coder
- [ ] Affichage du programme pendant la session
- [ ] Tests unitaires

---

**Auteur** : AI Assistant  
**Date** : 30 décembre 2025  
**Version** : 1.0
