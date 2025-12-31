# 🏃 Gestion des Sessions : Entraînement vs Course

## 📋 Règles implémentées

### ✅ **Sessions d'entraînement**
- **Qui peut créer ?** → Tous les membres de la squad
- **Combien ?** → Autant qu'ils veulent (illimité)
- **Types disponibles** :
  - Standard (course régulière)
  - Fractionné (intervalles)
  - Détente (récupération)

### 🏁 **Sessions de Course**
- **Qui peut créer ?** → Tous les membres de la squad
- **Combien ?** → **Une seule à la fois par squad**
- **Restriction** :
  - Si une course est déjà active → Proposition de **rejoindre la course existante**
  - Impossible de créer une nouvelle course tant qu'une autre est active

---

## 🔧 Implémentation technique

### 1. **Détection de course active**

#### `SessionService.swift` - Nouvelle méthode
```swift
func getActiveRaceSession(squadId: String) async throws -> SessionModel? {
    let snapshot = try await db.collection("sessions")
        .whereField("squadId", isEqualTo: squadId)
        .whereField("activityType", isEqualTo: "RACE")
        .whereField("status", isEqualTo: "ACTIVE")
        .limit(to: 1)
        .getDocuments()
    
    return snapshot.documents.first.map { try $0.data(as: SessionModel.self) }
}
```

---

### 2. **Flux de création avec vérification**

#### Étape 1 : Chargement initial
```swift
.task {
    await checkForActiveRace()
}
```
→ Récupère la course active (si elle existe) au démarrage

#### Étape 2 : Sélection "Course"
- L'utilisateur coche "Session de type Course"
- **Indicateur visuel** s'affiche si une course est déjà active :

```
⚠️ Course déjà active
Vous pourrez la rejoindre à l'étape suivante
```

#### Étape 3 : Clic sur "Suivant"
- **Vérification** : Y a-t-il une course active ?
  - **OUI** → Affiche un dialogue :
    ```
    🏁 Course en cours
    
    Une course est déjà en cours dans votre squad.
    Voulez-vous la rejoindre ?
    
    [Annuler]  [Rejoindre la course]
    ```
  
  - **NON** → Continue normalement vers l'étape 2

---

### 3. **Dialogue de proposition**

#### Options proposées :

1. **"Annuler"** → Retourne à l'étape 1, décoche "Course", permet de créer un entraînement
2. **"Rejoindre la course"** → Appelle `joinSession()` et ferme la vue

---

### 4. **Sécurité lors de la création**

Même si l'utilisateur passe toutes les étapes, une **vérification finale** est effectuée :

```swift
// Dans createSession()
if isRace {
    if let existingRace = try await SessionService.shared.getActiveRaceSession(squadId: squadId) {
        // Affiche le dialogue au lieu de créer
        showJoinRaceDialog = true
        return
    }
}
```

→ **Double sécurité** : impossible de créer 2 courses même en cas de race condition

---

## 🎯 Expérience utilisateur

### Scénario 1 : **Aucune course active**

1. Membre ouvre "Créer une session"
2. Coche "Session de type Course"
3. Remplit les informations (titre, lieu, programme)
4. Clique "Créer la session"
5. ✅ **Session de course créée avec succès**

---

### Scénario 2 : **Course déjà active (détectée au démarrage)**

1. Membre ouvre "Créer une session"
2. **Indicateur** : "🏁 1 course active" (en haut de l'écran)
3. Coche "Session de type Course"
4. **Avertissement orange** s'affiche :
   ```
   ⚠️ Course déjà active
   Vous pourrez la rejoindre à l'étape suivante
   ```
5. Clique "Suivant"
6. **Dialogue** apparaît :
   ```
   Course en cours
   Voulez-vous rejoindre la course ?
   
   [Annuler]  [Rejoindre]
   ```
7. Options :
   - **Annuler** → Retourne à l'étape 1, peut créer un entraînement
   - **Rejoindre** → Rejoint la course et ferme la vue

---

### Scénario 3 : **Course créée pendant qu'un autre membre remplit le formulaire**

1. Membre A ouvre "Créer une session" (aucune course active)
2. Membre B crée une course entre-temps
3. Membre A coche "Course" et clique "Suivant"
4. **Vérification en temps réel** détecte la course de B
5. **Dialogue** proposé à Membre A :
   ```
   Course en cours
   Voulez-vous rejoindre la course de Membre B ?
   ```

→ **Évite les conflits** même en cas de création simultanée

---

## 📊 Différences Entraînement vs Course

| Critère | Entraînement | Course |
|---------|--------------|--------|
| **Nombre max par squad** | Illimité | 1 seule active |
| **Vérification avant création** | Non | Oui ✅ |
| **Proposition de rejoindre** | Non | Oui ✅ |
| **Thèmes disponibles** | Standard/Fractionné/Détente | N/A |
| **Programme d'entraînement** | Oui (optionnel) | Oui (optionnel) |
| **Lieu de RDV** | Oui (optionnel) | Oui (optionnel) |

---

## 🔄 Cycle de vie d'une Course

```
┌─────────────────────────────────────────────────┐
│  Membre A crée une Course                       │
│  → status: ACTIVE                                │
│  → activityType: RACE                            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Membre B tente de créer une Course             │
│  → Détection : Course déjà active                │
│  → Proposition : Rejoindre celle de A            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Membre B rejoint la course de A                │
│  → participants: [A, B]                          │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  La course se termine                            │
│  → status: ENDED                                 │
│  → Nouvelle course peut être créée               │
└─────────────────────────────────────────────────┘
```

---

## 🧪 Tests à effectuer

### Test 1 : **Création d'entraînement simple**
1. Ouvrir "Créer une session"
2. Laisser décoché "Course"
3. Remplir titre
4. Créer
5. ✅ Vérifier que la session est créée

### Test 2 : **Création de course (aucune active)**
1. Ouvrir "Créer une session"
2. Cocher "Course"
3. Remplir titre
4. Créer
5. ✅ Vérifier que la course est créée

### Test 3 : **Tentative de course (une déjà active)**
1. S'assurer qu'une course est active
2. Ouvrir "Créer une session"
3. Cocher "Course"
4. Cliquer "Suivant"
5. ✅ Vérifier que le dialogue apparaît
6. Cliquer "Rejoindre"
7. ✅ Vérifier qu'on a rejoint la course existante

### Test 4 : **Création simultanée (race condition)**
1. Sur 2 appareils, ouvrir "Créer une session" en même temps
2. Cocher "Course" sur les 2
3. Cliquer "Créer" sur le 1er
4. Cliquer "Créer" sur le 2ème
5. ✅ Vérifier que le 2ème voit le dialogue

### Test 5 : **Annulation du dialogue**
1. Course active détectée
2. Dialogue "Rejoindre la course ?" affiché
3. Cliquer "Annuler"
4. ✅ Vérifier retour à étape 1
5. ✅ Vérifier que "Course" est décoché
6. Pouvoir créer un entraînement

---

## 📝 Logs pour debug

```
// Au démarrage
✅ Aucune course active pour squad: squad123

// Tentative de création avec course existante
🏁 Course active détectée: session456

// Création réussie d'une course
✅ Session de Course créée: session789

// Jonction à une course
✅ Course rejointe avec succès: session456
```

---

## 🚀 Améliorations futures

### V2 : Notifications push
- Notifier tous les membres quand une course démarre
- "🏁 Jean a lancé une course ! Rejoindre ?"

### V2 : Aperçu de la course active
- Dans le dialogue, afficher :
  - Nombre de participants
  - Distance parcourue
  - Durée écoulée
  - Lieu de départ

### V2 : Permissions avancées
- Seul l'admin peut créer des courses
- Les membres peuvent seulement rejoindre

---

**Résumé** : Tous les membres peuvent créer des sessions, mais une seule Course peut être active à la fois. L'application détecte automatiquement les courses actives et propose de les rejoindre au lieu d'en créer une nouvelle.
