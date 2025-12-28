Pour génèrer un code propre et une architecture évolutive, 
le prompt doit être extrêmement structuré. 
Il doit définir la **stack technique**, l'**architecture** et les **priorités de développement**.

Voici une proposition de prompt "Master" et la roadmap associée pour lancer ton projet.

---

## 1. Le Prompt d'Initialisation (À copier-coller)

> **Rôle :** Tu es un Expert iOS Senior et Architecte Logiciel.
> **Projet :** "SquadRun" (Nom de code), une application iOS sociale pour la préparation et le suivi de marathons/évènements sportifs.
> **Philosophie :** Zéro focus sur la performance pure (allure/watts). Focus total sur l'humain, l'entraide, le lien audio et le partage d'émotions entre coureurs et supporters.
> **Stack Technique Imposée :**
> * **Langage :** Swift / SwiftUI.
> * **Architecture :** MVVM avec Clean Architecture.
> * **Backend/Temps Réel :** Firebase (Firestore pour les données, Storage pour les médias, Cloud Functions pour les notifications).
> * **Localisation :** CoreLocation avec gestion du background.
> * **Audio :** AVFoundation pour le système de "Talkie-Walkie" et notifications vocales.
> * **Connectivité :** CoreBluetooth pour la détection de proximité entre coureurs.
> * **UI :** Modern, épurée, utilisant les Live Activities d'iOS.
> 
> 
> **Objectif immédiat :** Initialise la structure du projet Xcode avec les dossiers (Views, ViewModels, Models, Services, Repositories). Implémente le système d'authentification et la création de "Groupes de Course" (Squads).
> **Consigne :** Ne génère pas tout d'un coup. Propose d'abord l'architecture des données (Schéma Firestore) avant de passer au code des vues.

---

## 2. La Roadmap de Développement

Voici l'ordre logique pour construire l'application, étape par étape. Tu peux donner ces phases une par une à ton agent IA.

### Phase 1 : Le Socle Social & Préparation

* **Système de Groupe :** Création d'une "Squad" avec un code d'invitation unique.
* **Mur de Préparation :** Un feed simple où l'on partage son état de forme ou ses doutes (pas de stats Strava, juste du texte/photo).
* **Check-list Collective :** Liste partagée (ex: "Qui apporte les gels ?", "Point de RDV à 8h00").

### Phase 2 : Le Mode "Course" (Live)

* **Géolocalisation Partagée :** Affichage des membres du groupe sur une carte en temps réel.
* **Système d'Audio-Coaching Social :**
* Implémentation du "Push-to-Talk" (Talkie-walkie).
* Synthèse vocale (TTS) : Lire les messages texte des proches directement dans les écouteurs du coureur.


* **Live Activities :** Affichage de la distance restante et de la position des amis sur l'écran de verrouillage des supporters.

### Phase 3 : Interaction Supporters & Médias

* **L'Applaudimètre :** Un bouton "Encourager" pour les supporters qui déclenche un son de foule dans les écouteurs du coureur.
* **Collecte Géolocalisée :** Utiliser les timestamps et les positions GPS pour lier les photos prises par les supporters aux coureurs qu'ils encourageaient à cet instant précis.

### Phase 4 : Le "Souvenir" (Post-Course)

* **Génération du Recap :** Un écran compilant la trace GPS globale, les meilleurs messages vocaux et les photos prises par le groupe.
* **Export Vidéo :** Un montage automatisé simple pour les réseaux sociaux.

---

## 3. Schéma de l'Architecture de l'Expérience

Pour que l'IA comprenne bien l'interaction entre les différents acteurs, voici comment les données doivent circuler :

### Les "Feature-Killer" à demander spécifiquement à l'IA :

1. **Le "Geofencing Support" :** Code une fonction qui prévient les supporters sur leur téléphone quand un coureur du groupe est à moins de 500 mètres de leur position GPS actuelle.
2. **L'Audio Spatialisé :** Demande à l'IA d'utiliser `AVAudioEnvironmentNode` pour que, si un coéquipier est derrière moi sur la carte, sa voix semble venir de derrière dans mes AirPods.
3. **Gestion de la Batterie :** Demande un service de localisation optimisé qui réduit la précision quand le téléphone est immobile pour économiser l'énergie sur un marathon de 4h+.


Voici le schéma de base de données (Firestore) 
Pour que l'on puisse coder une synchronisation fluide entre coureurs et supporters, on a besoin d'une structure de données robuste. Voici le schéma **Firebase Firestore** optimisé pour gérer les sessions (Course ou Entraînement) et les différents rôles (ceux qui courent et ceux qui regardent).

---

### 1. Structure de la Base de Données (Schéma Firestore)

Voici l'organisation logique que tu dois soumettre à l'agent IA :

* **Collections `Squads` (Groupes) :** Contient les infos permanentes du groupe.
* `squadId` (ID unique)
* `name`, `description`, `inviteCode`
* `members` (Map d'UID avec rôles par défaut)


* **Sub-collection `Sessions` :** C’est ici que la magie opère pour un évènement précis.
* `sessionId` (ID unique)
* `type`: "Race" | "Training"
* `status`: "Lobby" | "Live" | "Finished"
* **Sub-collection `Participants` :** (Données temps réel)
* `userId`: UID
* `role`: "Runner" | "Supporter"
* `isActive`: Boolean (si l'utilisateur est connecté à la session)
* `lastPosition`: Geopoint (seulement pour les Runners)
* `batteryLevel`: Int (crucial pour le suivi)


* **Sub-collection `LiveFeed` :** (Messages et Médias)
* `type`: "Audio" | "Photo" | "Cheer" (Applaudissement)
* `senderId`: UID
* `mediaUrl`: String
* `timestamp`: ServerTimestamp
* `location`: Geopoint (où le média a été créé)


---

### 2. Prompt Complémentaire pour l'Agent IA (Focus Sync & Session)

Ajoute ce texte à ton prompt initial pour que l'IA gère correctement l'aspect "Service" :

> **Module de Synchronisation Temps Réel :**
> "Implémente un 'SessionManager' utilisant les listeners temps réel de Firestore (`snapshotListener`).
> 1. L'application doit distinguer deux états : l'état 'Background' (le coureur a le téléphone en poche) et l'état 'Active'.
> 2. Crée une logique de 'Session' : quand un leader lance une 'Race Session', tous les membres reçoivent une notification push (FCM) pour rejoindre.
> 3. Les coureurs publient leur position toutes les 10-30 secondes (optimisé batterie).
> 4. Les supporters ne publient pas leur position mais écoutent les changements de position des coureurs pour mettre à jour la carte et envoyer des messages audio contextuels.
> 5. Prévois un 'MediaService' qui uploade les photos vers Firebase Storage et crée automatiquement une entrée dans le LiveFeed avec la position GPS du coureur le plus proche à cet instant."
> 
> 

---

### 3. Fonctionnement des deux modes

Il est important de préciser à l'IA comment gérer les deux cas de figure que tu as cités :

| Fonctionnalité | Mode **TRAINING** | Mode **RACE (Jour J)** |
| --- | --- | --- |
| **Géolocalisation** | Précision moyenne (économie batterie) | Haute précision (Live Tracking) |
| **Accès Supporter** | Souvent restreint (entre coureurs) | Ouvert à la famille et aux amis via lien |
| **Audio** | Talkie-walkie libre entre tous | Priorité au "Directeur de Course" / Supporters |
| **Fin de session** | Simple résumé individuel | "Capsule Temporelle" collective (vidéo/photos) |

---

### Prochaines étapes  :

1. un premier fichier de code `SessionModel.swift` propose la structure exacte pour commencer à coder les vues.
2. Modifie ContentView pour qu'il agisse comme un switch : 
=> Si l'utilisateur n'est pas connecté -> Afficher LoginView.
=> S'il est connecté mais n'a pas de Squad -> Afficher JoinOrCreateSquadView.
=> S'il est dans une Squad -> Afficher le MainDashboard (avec la carte et le flux social)."
3. Securité ; il faut définir les règles de sécurité Firebase** pour que seuls les membres d'une "Squad" puissent voir les positions GPS des autres 

Attention voici le code firebase que j'ai modifier et qu'il faut fixer :''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fonction pour vérifier si l'utilisateur est membre de la Squad
    function isSquadMember(squadId) {
      return request.auth != null && 
             exists(/databases/$(database)/documents/squads/$(squadId)/members/$(request.auth.uid));
    }

    // Gestion des Squads
    match /squads/{squadId} {
      allow create: if request.auth != null;
      allow read, update: if isSquadMember(squadId);
      
      // Accès aux membres de la squad
      match /members/{memberId} {
        allow read, write: if isSquadMember(squadId);
      }
      
      // Accès aux sessions au sein d'une squad
      match /sessions/{sessionId} {
        allow read, write: if isSquadMember(squadId);
        
        // Accès au LiveFeed de la session
        match /liveFeed/{itemId} {
          allow read, write: if isSquadMember(squadId);
        }
        
        // Accès aux participants en temps réel
        match /participants/{userId} {
          allow read: if isSquadMember(squadId);
          allow write: if request.auth.uid == userId; // Un participant ne modifie que ses propres infos (GPS, batterie)
        }
      }
    }
    
    // Profils utilisateurs
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
