# 🧪 Tests Simulateur - Guide Rapide

**Durée :** 5 minutes

---

## ✅ Test 1 : Build & Lancement (1 min)

```bash
1. Cmd + B (Build)
   → Vérifier : Aucune erreur de compilation

2. Cmd + R (Run)
   → L'app se lance
```

**Résultat attendu :**
- ✅ Build réussit
- ✅ App s'ouvre sur l'écran de connexion

---

## ✅ Test 2 : Créer une Session (2 min)

```
1. Se connecter (ou créer un compte)
2. Aller dans Squads
3. Créer une squad "Test Course"
4. Ouvrir la squad
5. Taper "Démarrer une session"
6. Créer la session
```

**Résultat attendu :**
- ✅ Session créée
- ✅ Navigation vers l'onglet "Course"
- ✅ Carte s'affiche

---

## ✅ Test 3 : Carte avec Position Simulée (2 min)

```
1. Dans le simulateur :
   Simulateur → Features → Location → City Run

2. Observer :
   - Position utilisateur apparaît (point bleu)
   - Tracé rouge se dessine
   - Stats se mettent à jour
```

**Résultat attendu :**
- ✅ Point bleu se déplace
- ✅ Ligne rouge apparaît
- ✅ Distance augmente

---

## ✅ Test 4 : Contrôles Carte (1 min)

```
1. Taper sur 🎯 (Recentrer)
   → Carte se centre sur votre position

2. Taper sur 💾 (Sauvegarder)
   → Alerte "Tracé sauvegardé !"

3. Taper sur 💬 (Messages)
   → Sheet messages s'ouvre
```

**Résultat attendu :**
- ✅ Boutons répondent
- ✅ Animations fluides
- ✅ Pas de crash

---

## 🐛 Si Problèmes

### Carte ne s'affiche pas
```
- Vérifier : Map permissions dans Info.plist
- Console : Chercher erreurs MapKit
```

### Tracé n'apparaît pas
```
- Vérifier : routeCoordinates.count > 0
- Console : "📍 Point ajouté au tracé"
```

### Build échoue
```
- Clean Build Folder : Cmd + Shift + K
- Rebuild : Cmd + B
```

---

**Prochaine étape :** Tests sur device physique
