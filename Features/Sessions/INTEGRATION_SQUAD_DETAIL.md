# 🔧 Intégration Sessions dans SquadDetailView

**Objectif :** Ajouter accès à l'historique et session active depuis la page squad

---

## Code à Ajouter

### Étape 1 : Importer SessionHistoryView

Dans `SquadDetailView.swift`, ajouter après les membres :

```swift
// MARK: - Sessions Section

private var sessionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Sessions")
            .font(.headline)
            .foregroundColor(.white)
        
        VStack(spacing: 12) {
            // Session active (si existe)
            if let activeSessionId = squad.activeSessions?.first {
                NavigationLink(destination: activeSessionDestination(sessionId: activeSessionId)) {
                    activeSessionCard
                }
            }
            
            // Bouton Historique
            NavigationLink(destination: SessionHistoryView(squadId: squad.id ?? "")) {
                historyButton
            }
        }
    }
}

private var activeSessionCard: some View {
    HStack(spacing: 12) {
        // Indicateur animé
        Circle()
            .fill(Color.green)
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 4)
                    .scaleEffect(1.5)
            }
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Session en cours")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text("Voir les coureurs actifs")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        
        Spacer()
        
        Image(systemName: "chevron.right")
            .foregroundColor(.white.opacity(0.5))
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 12))
}

private var historyButton: some View {
    HStack(spacing: 12) {
        Image(systemName: "clock.badge.checkmark")
            .font(.title3)
            .foregroundColor(.coralAccent)
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Historique des sessions")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Text("Voir toutes les courses passées")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        
        Spacer()
        
        Image(systemName: "chevron.right")
            .foregroundColor(.white.opacity(0.5))
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .clipShape(RoundedRectangle(cornerRadius: 12))
}

private func activeSessionDestination(sessionId: String) -> some View {
    // Charger la session et naviguer
    ActiveSessionLoader(sessionId: sessionId)
}

// Helper pour charger une session active
struct ActiveSessionLoader: View {
    let sessionId: String
    @State private var session: SessionModel?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.coralAccent)
            } else if let session = session {
                ActiveSessionDetailView(session: session)
            } else {
                Text("Session introuvable")
                    .foregroundColor(.white)
            }
        }
        .task {
            await loadSession()
        }
    }
    
    private func loadSession() async {
        do {
            let db = Firestore.firestore()
            let doc = try await db.collection("sessions").document(sessionId).getDocument()
            session = try? doc.data(as: SessionModel.self)
        } catch {
            print("Error loading session: \(error)")
        }
        isLoading = false
    }
}
```

### Étape 2 : Ajouter dans le body

Dans le `ScrollView` de `SquadDetailView`, après `membersSection` :

```swift
ScrollView {
    VStack(spacing: 20) {
        // ... code existant ...
        
        // Membres
        membersSection
        
        // ✅ AJOUTER ICI
        sessionsSection
            .padding(.horizontal, 20)
        
    }
    .padding(.top, 20)
}
```

---

## Résultat Visuel

```
┌─────────────────────────────────┐
│ Squad Detail                    │
├─────────────────────────────────┤
│                                 │
│ Membres (3)                     │
│ [Liste des membres]             │
│                                 │
│ Sessions                        │ ← NOUVEAU
│ ┌─────────────────────────────┐ │
│ │ 🟢 Session en cours         │ │ ← Si active
│ │ Voir les coureurs actifs   →│ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 🕐 Historique des sessions  │ │ ← Toujours visible
│ │ Voir toutes les courses... →│ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

---

## Alternative Simplifiée (5 min)

Si vous voulez aller plus vite, version minimaliste :

```swift
// Juste ajouter après membersSection
if let squadId = squad.id {
    NavigationLink(destination: SessionHistoryView(squadId: squadId)) {
        HStack {
            Image(systemName: "clock.badge.checkmark")
            Text("Historique des sessions")
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding(.horizontal, 20)
}
```

---

**Temps estimé :** 30 minutes (version complète) ou 5 minutes (version simple)
