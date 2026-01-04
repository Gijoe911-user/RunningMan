# ✅ Implémentation des Boutons de Contrôle - SessionTrackingView

**Date :** 4 janvier 2026  
**Statut :** ✅ IMPLÉMENTÉ

---

## 🎯 Objectif

Implémenter deux boutons distincts pour contrôler le tracking GPS :

1. **Bouton Play/Pause** : Démarrer/Mettre en pause l'activité
2. **Bouton Stop** : Terminer définitivement l'activité

---

## 📊 Vue d'Ensemble

### États du Tracking

| État | Description | Bouton Visible | Action |
|------|-------------|---------------|--------|
| **Spectateur** | GPS éteint, mode visualisation | "Démarrer l'activité" (grand bouton) | → Passe en `.idle` puis `.active` |
| **Idle** | Tracking initialisé mais pas démarré | Play (cercle coral) | → Démarre le GPS |
| **Active** | Tracking en cours, GPS actif | Pause (cercle orange) + Stop (cercle rouge) | → Met en pause |
| **Paused** | Tracking en pause, GPS arrêté | Play (cercle vert) + Stop (cercle rouge) | → Reprend le GPS |
| **Stopping** | Arrêt en cours | Désactivés | → Sauvegarde et ferme |

---

## 🎨 Interface Utilisateur

### Mode Spectateur (Défaut)

```
┌─────────────────────────────────────────┐
│                                         │
│           🗺️ CARTE GPS                  │
│                                         │
│                                         │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  ▶️ Démarrer l'activité           │  │
│  │  (Grand bouton coral/pink)        │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Mode Tracking Actif

```
┌─────────────────────────────────────────┐
│  🟢 En cours                            │
│           🗺️ CARTE GPS                  │
│     📍 Tracé GPS en temps réel          │
│                                         │
│                                         │
│   ⏸️ (80px)      🛑 (60px)             │
│   PAUSE          TERMINER               │
│  (Orange/Rouge)  (Rouge)                │
└─────────────────────────────────────────┘
```

### Mode Tracking En Pause

```
┌─────────────────────────────────────────┐
│  🟠 En pause                            │
│           🗺️ CARTE GPS                  │
│     📍 Tracé GPS figé                   │
│                                         │
│                                         │
│   ▶️ (80px)      🛑 (60px)             │
│   REPRENDRE      TERMINER               │
│  (Vert/Coral)    (Rouge)                │
└─────────────────────────────────────────┘
```

---

## 🔧 Fonctionnalités Implémentées

### 1. Bouton "Démarrer l'activité" (Mode Spectateur)

**Fichier :** `SessionTrackingView.swift`  
**Lignes :** ~152-177

#### Comportement

1. **Clic** → Affiche une confirmation
2. **Confirmation** → Vérifie si une autre session est active
3. **Si aucune session active** :
   - ✅ Démarre le `TrackingManager`
   - ✅ Met à jour Firestore (`startParticipantTracking`)
   - ✅ Passe en mode coureur (`isSpectatorMode = false`)
4. **Si session active ailleurs** :
   - ❌ Affiche une erreur : "Vous êtes déjà en train de courir dans une autre session"

#### Code Clé

```swift
private var spectatorModeButtons: some View {
    Button {
        showStartTrackingConfirmation = true
    } label: {
        HStack(spacing: 12) {
            Image(systemName: "play.fill")
                .font(.system(size: 24, weight: .bold))
            
            Text("Démarrer l'activité")
                .font(.headline)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(
            LinearGradient(
                colors: [Color.coralAccent, Color.pinkAccent],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

---

### 2. Bouton Play/Pause (Mode Tracking)

**Fichier :** `SessionTrackingView.swift`  
**Lignes :** ~227-287

#### Comportement

**État Active → Pause :**
- Clic → Met en pause le GPS
- Met à jour Firestore (`pauseParticipantTracking`)
- Changement visuel : Cercle orange/rouge, icône pause

**État Paused → Active :**
- Clic → Reprend le GPS
- Met à jour Firestore (`resumeParticipantTracking`)
- Changement visuel : Cercle vert/coral, icône play

#### Code Clé

```swift
private var trackingControlButtons: some View {
    HStack(spacing: 20) {
        // Bouton Play/Pause
        Button {
            Task {
                await handlePlayPause()
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: playPauseGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: playPauseIcon)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Label dynamique
                Text(playPauseLabel)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        
        // ...
    }
}
```

#### Couleurs Dynamiques

| État | Couleurs du Gradient | Label |
|------|---------------------|-------|
| **Active** | Orange → Rouge | "Pause" |
| **Paused** | Vert → Coral | "Reprendre" |
| **Idle** | Coral → Pink | "Démarrer" |

---

### 3. Bouton Stop (Mode Tracking)

**Fichier :** `SessionTrackingView.swift`  
**Lignes :** ~289-320

#### Comportement

1. **Clic** → Affiche une confirmation
2. **Confirmation** → Arrête le tracking
3. **Actions :**
   - ✅ Arrête le `TrackingManager`
   - ✅ Récupère les statistiques finales (distance, durée)
   - ✅ Met à jour Firestore (`endParticipantTracking`)
   - ✅ Ferme la vue (`dismiss()`)

#### Code Clé

```swift
if currentTrackingState == .active || currentTrackingState == .paused {
    Button {
        showStopConfirmation = true
    } label: {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "stop.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Terminer")
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}
```

---

## 🔒 Garde-Fou : Une Activité à la Fois

### Implémentation

**Fichier :** `SessionTrackingView.swift`  
**Fonction :** `startTracking()`  
**Lignes :** ~337-371

#### Logique

Avant de démarrer le tracking, le système vérifie :

```swift
// Récupérer toutes les sessions actives de l'utilisateur
let activeSessions = try await SessionService.shared.getAllActiveSessions(userId: userId)

// Filtrer celles où l'utilisateur est en train de tracker
let trackingSessions = activeSessions.filter { sess in
    sess.participantActivity?[userId]?.isTracking == true && sess.id != sessionId
}

if !trackingSessions.isEmpty {
    // ❌ Bloquer le démarrage
    errorMessage = "Vous êtes déjà en train de courir dans une autre session."
    showError = true
    return
}
```

#### Résultat

- ✅ **Un seul tracking actif** par utilisateur à la fois
- ✅ **Support illimité** (mode spectateur) dans toutes les autres sessions

---

## 📱 Intégration Firestore

### Actions Firestore Implémentées

| Action Utilisateur | Fonction Firestore | Champs Mis à Jour |
|-------------------|-------------------|-------------------|
| **Démarrer tracking** | `startParticipantTracking()` | `participantStates.{userId}.status = ACTIVE`<br>`participantActivity.{userId}.isTracking = true` |
| **Mettre en pause** | `pauseParticipantTracking()` | `participantStates.{userId}.status = PAUSED` |
| **Reprendre** | `resumeParticipantTracking()` | `participantStates.{userId}.status = ACTIVE` |
| **Terminer** | `endParticipantTracking()` | `participantStates.{userId}.status = ENDED`<br>`participantActivity.{userId}.isTracking = false` |

---

## 🧪 Tests à Effectuer

### Test 1 : Mode Spectateur → Tracking

**Scénario :**
1. Ouvrir une session existante
2. Vérifier que le bouton "Démarrer l'activité" est visible
3. Cliquer sur "Démarrer l'activité"
4. Confirmer dans l'alerte

**Résultat Attendu :**
- ✅ GPS démarre
- ✅ Tracé GPS commence à s'afficher
- ✅ Badge passe de "👁️ Spectateur" à "🟢 En cours"
- ✅ Boutons Play/Pause + Stop apparaissent

---

### Test 2 : Play/Pause

**Scénario :**
1. Tracking actif
2. Cliquer sur le bouton Pause (orange)
3. Attendre 5 secondes
4. Cliquer sur le bouton Reprendre (vert)

**Résultat Attendu :**
- ✅ GPS s'arrête à la pause
- ✅ Tracé GPS figé
- ✅ Badge passe à "🟠 En pause"
- ✅ GPS reprend après clic sur Reprendre
- ✅ Tracé GPS continue depuis le dernier point

---

### Test 3 : Stop

**Scénario :**
1. Tracking actif ou en pause
2. Cliquer sur le bouton Stop (rouge)
3. Confirmer dans l'alerte

**Résultat Attendu :**
- ✅ GPS s'arrête
- ✅ Statistiques finales sauvegardées dans Firestore
- ✅ Vue se ferme automatiquement
- ✅ Retour à la liste des sessions

---

### Test 4 : Garde-Fou

**Scénario :**
1. Démarrer tracking dans "Session A"
2. Ouvrir "Session B" (dans AllActiveSessionsView)
3. Cliquer sur "Démarrer l'activité" dans "Session B"

**Résultat Attendu :**
- ❌ Alerte : "Vous êtes déjà en train de courir dans une autre session"
- ✅ Tracking ne démarre pas dans "Session B"
- ✅ "Session A" reste active

---

### Test 5 : Mode Spectateur Multi-Sessions

**Scénario :**
1. Session A : Tracking actif
2. Ouvrir AllActiveSessionsView
3. Cliquer sur Session B, Session C, Session D

**Résultat Attendu :**
- ✅ Session A : Badge "En cours"
- ✅ Session B, C, D : Badge "Spectateur"
- ✅ Toutes les cartes affichent les tracés existants
- ✅ Pas de démarrage automatique du GPS

---

## 📚 Fichiers Modifiés

### SessionTrackingView.swift

**Modifications :**
1. ✅ Ajout de `errorMessage` et `showError` (gestion d'erreurs)
2. ✅ Fonction `startTracking()` avec garde-fou
3. ✅ Fonction `handlePlayPause()` avec synchronisation Firestore
4. ✅ Fonction `stopTracking()` améliorée
5. ✅ Boutons visuellement améliorés (labels, couleurs dynamiques)

**Lignes Modifiées :** ~15 (ajout états), ~337-420 (fonctions), ~227-287 (boutons)

---

## 🎯 Prochaines Étapes

### Étape 4 : Ajuster le Timeout (120s)

**Fichier :** `SessionModel.swift`  
**Ligne :** ~260

```swift
// Changer de 60 à 120
var isInactive: Bool {
    timeSinceLastUpdate > 120  // ✅ 2 minutes
}
```

---

### Étape 5 : Tester Multi-Sessions

**Tester :**
- Un utilisateur avec plusieurs squads
- Plusieurs sessions actives simultanées
- Mode spectateur dans plusieurs sessions à la fois

---

### Étape 6 : Déjà implémenté ! ✅

Le garde-fou "Une activité à la fois" est déjà en place.

---

## ✅ Checklist

- [x] **Bouton "Démarrer l'activité"** visible en mode spectateur
- [x] **Bouton Play/Pause** avec couleurs et labels dynamiques
- [x] **Bouton Stop** avec confirmation
- [x] **Garde-fou** : une seule session en tracking à la fois
- [x] **Synchronisation Firestore** à chaque changement d'état
- [x] **Gestion d'erreurs** avec alertes
- [x] **Tests manuels** à effectuer

---

## 🎉 Félicitations !

Vous avez maintenant un système complet de contrôle du tracking GPS avec :

✅ Mode spectateur par défaut  
✅ Démarrage manuel explicite  
✅ Play/Pause/Stop séparés  
✅ Garde-fou une activité à la fois  
✅ Synchronisation Firestore temps réel  
✅ Interface utilisateur claire et intuitive  

**Prêt à tester !** 🚀
