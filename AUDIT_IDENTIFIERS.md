# 🔍 Audit des Composants - Identifiants de Logs

> Créé le : 03/01/2026  
> Objectif : Tracer l'utilisation réelle des composants pour identifier ce qui est obsolète

---

## 📋 Identifiants Ajoutés

### TrackingManager.swift
| ID | Méthode | Description |
|----|---------|-------------|
| `AUDIT-TM-01` | `startTracking(for:)` | Démarrage du tracking GPS |
| `AUDIT-TM-02` | `pauseTracking()` | Mise en pause |
| `AUDIT-TM-03` | `resumeTracking()` | Reprise après pause |
| `AUDIT-TM-04` | `stopTracking()` | Arrêt et sauvegarde |

### SessionsListView.swift
| ID | Méthode | Description |
|----|---------|-------------|
| `AUDIT-SLV-01` | `onRecenter` | Recentrage carte sur utilisateur |
| `AUDIT-SLV-02` | `setupView()` | Configuration initiale |
| `AUDIT-SLV-03` | `configureSquadContext()` | Configuration contexte squad |
| `AUDIT-SLV-04` | `saveCurrentRoute()` | Sauvegarde du tracé |

### SessionCardComponents.swift
| ID | Composant | Description |
|----|-----------|-------------|
| `AUDIT-TSC-01` | `TrackingSessionCard` | Card session active avec GPS |
| `AUDIT-HSC-01` | `HistorySessionCard` | Card session historique |

### RouteTrackingService.swift
| ID | Méthode | Description |
|----|---------|-------------|
| `AUDIT-RTS-01` | `addRoutePoint(_:)` | Ajout d'un point GPS |
| `AUDIT-RTS-02` | `getCurrentRoute()` | Récupération du tracé |
| `AUDIT-RTS-03` | `clearRoute()` | Réinitialisation |
| `AUDIT-RTS-04` | `saveRoute(sessionId:userId:)` | Sauvegarde Firebase |
| `AUDIT-RTS-05` | `loadRoute(sessionId:userId:)` | Chargement depuis Firebase |

### RealtimeLocationService.swift
| ID | Méthode | Description |
|----|---------|-------------|
| `AUDIT-RLS-01` | `setContext(squadId:)` | Définition du contexte squad |
| `AUDIT-RLS-02` | `startLocationUpdates()` | Démarrage géolocalisation |
| `AUDIT-RLS-03` | `requestOneShotLocation()` | Localisation ponctuelle |

### SquadDetailView.swift
| ID | Méthode | Description |
|----|---------|-------------|
| `AUDIT-SDV-01` | `refreshable` | Invalidation du cache |
| `AUDIT-SDV-02` | `task` | Configuration contexte |

### SquadSessionsListView.swift
| ID | Méthode | Description |
|----|---------|-------------|
| `AUDIT-SSL-01` | `loadSessions()` | Chargement des sessions |

---

## 🎯 Comment Utiliser Cet Audit

### 1. Lancer l'Application en Mode Debug

Activez tous les logs :
```swift
// Dans Logger ou votre système de logs
let showAuditLogs = true
```

### 2. Parcourir Tous les Scénarios

Effectuez une **passe complète** de l'application :

#### Scénario 1 : Navigation de Base
- [ ] Ouvrir l'onglet Accueil
- [ ] Ouvrir l'onglet Squads
- [ ] Ouvrir l'onglet Sessions
- [ ] Ouvrir l'onglet Profil

#### Scénario 2 : Gestion des Squads
- [ ] Créer une squad
- [ ] Rejoindre une squad avec code
- [ ] Ouvrir détail d'une squad
- [ ] Copier le code d'invitation
- [ ] Partager le code
- [ ] Voir les sessions d'une squad

#### Scénario 3 : Sessions Actives
- [ ] Créer une session
- [ ] Démarrer le tracking GPS
- [ ] Mettre en pause
- [ ] Reprendre
- [ ] Terminer la session
- [ ] Visualiser les stats

#### Scénario 4 : Historique
- [ ] Voir l'onglet historique
- [ ] Ouvrir une session passée
- [ ] Consulter les 3 tabs (Overview/Participants/Carte)
- [ ] Voir le parcours GPS

#### Scénario 5 : Carte et Localisation
- [ ] Recentrer la carte
- [ ] Voir les autres coureurs
- [ ] Sauvegarder le tracé

### 3. Analyser les Logs

Dans Xcode Console, filtrer par `[AUDIT-` :

```bash
# Exemple de logs attendus
[AUDIT-TM-01] 🚀 TrackingManager.startTracking appelé
[AUDIT-RLS-02] 📍 RealtimeLocationService.startLocationUpdates appelé
[AUDIT-RTS-01] 📍 RouteTrackingService.addRoutePoint - total: 42
[AUDIT-SLV-01] 🎯 SessionsListView.onRecenter appelé
```

### 4. Identifier les Composants Non Utilisés

Si après la passe complète, certains identifiants **n'apparaissent jamais** :
- ❌ Le composant est **probablement obsolète**
- 🗑️ Candidat à la suppression

Si un identifiant apparaît **trop souvent** (spam) :
- ⚠️ Peut-être un problème de performance
- 🔄 Possibilité d'optimisation

---

## 📊 Template de Rapport d'Audit

Après avoir effectué la passe :

```markdown
## Rapport d'Audit - [Date]

### ✅ Composants Utilisés (logs détectés)
- [AUDIT-TM-01] ✅ Vu 3 fois
- [AUDIT-SLV-02] ✅ Vu 1 fois
- [AUDIT-RTS-01] ✅ Vu 156 fois (normal, ajout de points GPS)
- ...

### ⚠️ Composants Suspects (jamais vus)
- [AUDIT-XXX-XX] ❌ Jamais vu → Candidat suppression
- ...

### 🔍 Composants à Investiguer
- [AUDIT-YYY-YY] ⚠️ Vu 2000 fois (spam possible)
- ...

### 🗑️ Recommandations de Suppression
- Fichier X : Raison Y
- Composant Z : Raison W
```

---

## 🗑️ Fichiers Déjà Identifiés comme Doublons

Ces fichiers ont été créés par erreur et doivent être **supprimés manuellement** :

```bash
# Doublons à supprimer
SessionTrackingViewModel.swift         # Doublon de TrackingManager.swift
SessionTrackingControls.swift          # Fonctionnalité déjà dans TrackingManager
SessionsListView+TrackingIntegration.swift  # Guide inutile

# Documentation redondante
TRACKING_GPS_GUIDE.md
TRACKING_IMPLEMENTATION_SUMMARY.md
TRACKING_VISUAL_GUIDE.md
QUICK_START_TRACKING.md
```

**⚠️ Important :** Ces fichiers n'ont **PAS** d'identifiants d'audit car ils sont des doublons purs.

---

## 🔄 Prochaines Étapes

1. ✅ **Effectuer la passe complète** avec tous les scénarios
2. 📊 **Remplir le rapport d'audit**
3. 🗑️ **Supprimer les fichiers doublons identifiés**
4. 🔍 **Analyser les composants suspects**
5. 🧹 **Nettoyer le code obsolète**
6. 📝 **Mettre à jour DEPENDENCY_MAP.md**

---

**🎯 Objectif Final :** Une base de code propre, sans doublons, avec uniquement les composants réellement utilisés.
