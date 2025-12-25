# 🛠️ RÉSOLUTION FINALE DES DOUBLONS - RUNNINGMAN

## ✅ Corrections automatiques effectuées

### 1. Migration de @EnvironmentObject vers @Environment
J'ai corrigé tous les fichiers pour utiliser le nouveau système `@Observable` :

- ✅ `RootView.swift` : `@EnvironmentObject` → `@Environment(AuthViewModel.self)`
- ✅ `OnboardingSquadView.swift` : Déjà correct
- ✅ `ProfileView.swift` : `@EnvironmentObject` → `@Environment(AuthViewModel.self)`
- ✅ `MainTabView.swift` : Correction des previews

### 2. Suppression du placeholder OnboardingSquadView
- ✅ Supprimé le doublon dans `RootView.swift` (lignes 74-82)

---

## 🗑️ FICHIERS À SUPPRIMER MANUELLEMENT

### ❌ SUPPRIMER : `FeaturesProfileProfileView.swift`
**Raison** : Doublon de ProfileView
- ⚠️ Utilise `AppState` (ancien système)
- ⚠️ Redéclare `StatCard` (déjà dans ProfileView.swift)
- ✅ **GARDER** : `ProfileView.swift` (utilise AuthViewModel)

**Action** :
1. Dans Xcode, sélectionne `FeaturesProfileProfileView.swift`
2. Clic-droit → Delete
3. Choisir "Move to Trash"

---

### ❌ SUPPRIMER : `FeaturesSquadsSquadViews.swift`
**Raison** : Ce fichier contient 3 structures en doublon :
- `CreateSquadView` (doublon avec `CreateSquadView.swift`)
- `JoinSquadView` 
- `SquadDetailView`

**Problème** : Ces structures sont aussi définies dans des fichiers séparés.

**Action** :
1. Ouvre `FeaturesSquadsSquadViews.swift`
2. Vérifie si tu utilises ces vues quelque part
3. Si non utilisées → Supprime le fichier complet
4. Si utilisées → Crée les fichiers séparés manquants (voir section suivante)

---

### ⚠️ ALTERNATIVE : Créer les fichiers manquants au lieu de supprimer

Si tu veux garder le code de `FeaturesSquadsSquadViews.swift`, crée ces fichiers séparés :

#### Créer `JoinSquadView.swift` :
```swift
//
//  JoinSquadView.swift
//  RunningMan
//

import SwiftUI

struct JoinSquadView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var accessCode = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.coralAccent)
                    
                    Text("Rejoindre une Squad")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Entrez le code d'accès fourni par le créateur")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Code d'accès
                    TextField("CODE", text: $accessCode)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.coralAccent)
                    }
                    
                    // Bouton rejoindre
                    Button {
                        // TODO: Implémenter joinSquad()
                    } label: {
                        HStack {
                            if isJoining {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Rejoindre")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(accessCode.isEmpty ? Color.gray : .coralAccent)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(accessCode.isEmpty || isJoining)
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.coralAccent)
                }
            }
        }
    }
}

#Preview {
    JoinSquadView()
        .preferredColorScheme(.dark)
}
```

#### Créer `SquadDetailView.swift` :
```swift
//
//  SquadDetailView.swift
//  RunningMan
//

import SwiftUI

struct SquadDetailView: View {
    let squad: SquadModel
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text(squad.name)
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("Détails de la Squad")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // TODO: Phase 1 - Implémenter détails complets
                }
                .padding()
            }
        }
        .navigationTitle(squad.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SquadDetailView(squad: SquadModel(
            id: "1",
            name: "Test Squad",
            creatorId: "creator123",
            memberIds: ["creator123"],
            createdAt: Date(),
            isPublic: true
        ))
    }
    .preferredColorScheme(.dark)
}
```

---

## 🔧 FICHIERS MANQUANTS À CRÉER

Tu utilises ces vues dans `MainTabView.swift` mais elles n'existent pas encore :

### 1. Créer `DashboardView.swift`
```swift
//
//  DashboardView.swift
//  RunningMan
//

import SwiftUI

/// Vue principale du dashboard
struct DashboardView: View {
    
    @Environment(AuthViewModel.self) private var authVM
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack {
                    Text("Dashboard")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    if let user = authVM.currentUser {
                        Text("Bienvenue, \(user.displayName)!")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // TODO: Implémenter dashboard complet
                }
            }
            .navigationTitle("Accueil")
        }
    }
}

#Preview {
    DashboardView()
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}
```

### 2. Créer `SquadListView.swift`
```swift
//
//  SquadListView.swift
//  RunningMan
//

import SwiftUI

/// Liste des squads de l'utilisateur
struct SquadListView: View {
    
    @Environment(AuthViewModel.self) private var authVM
    @State private var showCreateSquad = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack {
                    Text("Mes Squads")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    // TODO: Afficher la liste des squads
                }
            }
            .navigationTitle("Squads")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSquad = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.coralAccent)
                    }
                }
            }
            .sheet(isPresented: $showCreateSquad) {
                CreateSquadView()
            }
        }
    }
}

#Preview {
    SquadListView()
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}
```

### 3. Créer `RunTrackingView.swift`
```swift
//
//  RunTrackingView.swift
//  RunningMan
//

import SwiftUI

/// Vue pour tracker une course en temps réel
struct RunTrackingView: View {
    
    @State private var isRunning = false
    @State private var distance: Double = 0.0
    @State private var duration: TimeInterval = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Distance
                    VStack(spacing: 8) {
                        Text(String(format: "%.2f", distance))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("km")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Durée
                    Text(formatDuration(duration))
                        .font(.title2)
                        .foregroundColor(.coralAccent)
                    
                    Spacer()
                    
                    // Bouton Start/Stop
                    Button {
                        isRunning.toggle()
                    } label: {
                        Text(isRunning ? "Arrêter" : "Démarrer")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 60)
                            .background(
                                isRunning ? Color.red : Color.coralAccent
                            )
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Course")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    RunTrackingView()
        .preferredColorScheme(.dark)
}
```

---

## 📋 CHECKLIST FINALE

### Étape 1 : Supprimer les doublons
- [ ] Supprimer `FeaturesProfileProfileView.swift`
- [ ] Supprimer `FeaturesSquadsSquadViews.swift` (ou extraire le code)

### Étape 2 : Créer les fichiers manquants
- [ ] Créer `DashboardView.swift`
- [ ] Créer `SquadListView.swift`
- [ ] Créer `RunTrackingView.swift`
- [ ] (Optionnel) Créer `JoinSquadView.swift` si non existant
- [ ] (Optionnel) Créer `SquadDetailView.swift` si non existant

### Étape 3 : Vérifier le projet
- [ ] Cmd + Shift + K (Clean Build)
- [ ] Cmd + B (Build)
- [ ] Vérifier qu'il n'y a plus d'erreurs "Invalid redeclaration"
- [ ] Cmd + R (Run) pour tester l'app

---

## 🎯 ARCHITECTURE FINALE

Après ces changements, tu auras une architecture propre :

```
RunningMan/
├── Core/
│   ├── RootView.swift ✅
│   └── MainTabView.swift ✅
├── Features/
│   ├── Auth/
│   │   ├── ViewModels/
│   │   │   └── AuthViewModel.swift ✅
│   │   └── Views/
│   │       └── LoginView.swift
│   ├── Onboarding/
│   │   └── OnboardingSquadView.swift ✅
│   ├── Dashboard/
│   │   └── DashboardView.swift 📝 À créer
│   ├── Squads/
│   │   ├── SquadListView.swift 📝 À créer
│   │   ├── CreateSquadView.swift ✅
│   │   ├── JoinSquadView.swift 📝 À créer
│   │   └── SquadDetailView.swift 📝 À créer
│   ├── Running/
│   │   └── RunTrackingView.swift 📝 À créer
│   └── Profile/
│       └── ProfileView.swift ✅
```

---

## 💡 CONSEIL

Une fois que tu as supprimé les doublons et créé les fichiers manquants :

1. **Clean le projet** : Cmd + Shift + K
2. **Build** : Cmd + B
3. Si ça compile → **Run** : Cmd + R

Si tu as des erreurs après ça, copie-colle le message d'erreur et je t'aiderai !
