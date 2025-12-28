# 🚀 Guide de Test Rapide - Nouvelles Fonctionnalités

**5 minutes pour tout tester !**

---

## 🎯 Test 1 : Carte Interactive (2 min)

### Sur Simulateur (Préparation)
```
1. Build & Run
2. Créer une session
3. Simulateur → Features → Location
4. Choisir "City Run" ou "Freeway Drive"
```

### Vérifier
- [ ] ✅ Tracé rouge apparaît sur la carte
- [ ] ✅ Position utilisateur visible (point bleu)
- [ ] ✅ Boutons 🎯 👥 💾 visibles en haut à droite

### Actions
```
Taper sur 🎯 (Recentrer)
→ Carte se centre sur votre position

Taper sur 💾 (Sauvegarder)
→ Alerte "Tracé sauvegardé !"
```

---

## 💬 Test 2 : Messages Rapides (3 min)

### Prérequis
- 2 simulateurs OU 2 devices
- 2 utilisateurs dans la même session

### User A (Device 1)
```
1. Taper sur le bouton flottant 💬 (en bas à droite)
2. Taper sur "👍 Bien joué !"
3. Le message apparaît dans votre liste
```

### User B (Device 2)
```
4. Ouvrir les messages (bouton 💬)
5. Voir le message de User A
6. Badge "1" apparaît sur le bouton
7. Répondre avec "💪 Allez !"
```

### User A
```
8. Message de User B apparaît en temps réel
9. ✅ Communication établie !
```

---

## 📍 Test 3 : Device Physique (10 min) - IMPORTANT

### Setup
```
1. Connecter iPhone
2. Build & Run
3. Autoriser localisation "Always"
4. Sortir dehors
```

### Actions
```
1. Créer une session
2. Marcher 300 mètres (4-5 minutes)
3. Observer :
   ✅ Tracé rouge se dessine en temps réel
   ✅ Distance augmente
   ✅ Stats se mettent à jour

4. Taper sur 🎯
   ✅ Carte se recentre

5. Taper sur 💾
   ✅ Confirmation sauvegarde

6. Terminer la session
   ✅ Tracé sauvegardé automatiquement
```

### Vérifier Firestore
```
Firebase Console → Firestore Database → Collection "routes"
→ Document "{sessionId}_{userId}"
→ Vérifier "points" contient des GeoPoints
```

---

## 🐛 Si Problèmes

### Tracé n'apparaît pas
```
Vérifier :
1. Location permissions → "Always"
2. Console logs : "📍 Point ajouté au tracé"
3. viewModel.routeCoordinates.count > 0
```

### Messages ne s'envoient pas
```
Vérifier :
1. Firebase configuré ✅
2. Session ID valide
3. Console : "💬 Envoi message"
4. Firestore rules permettent write
```

### Boutons carte invisibles
```
Vérifier :
1. EnhancedSessionMapView importé
2. Overlay aligné .topTrailing
3. Padding correct
```

---

## ✅ Checklist Finale

- [ ] Tracé GPS visible sur la carte
- [ ] Bouton recentrer fonctionne
- [ ] Bouton sauvegarder fonctionne
- [ ] Messages s'envoient et se reçoivent
- [ ] Badge messages fonctionne
- [ ] Haptic feedback à l'envoi
- [ ] Tracé sauvegardé dans Firestore
- [ ] Session se termine proprement

---

## 🎉 Si Tout Fonctionne

**Vous avez un MVP complet ! 🚀**

Prochaines étapes :
1. Inviter des amis à tester
2. Faire une vraie course à 2-3 personnes
3. Collecter les retours
4. Itérer sur les bugs

---

**Bon test ! 💪**
