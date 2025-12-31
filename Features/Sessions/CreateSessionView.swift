//
//  CreateSessionView.swift
//  RunningMan
//
//  Vue pour créer une nouvelle session d'entraînement
//

import SwiftUI

struct CreateSessionView: View {
    let squad: SquadModel
    let onSessionCreated: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(SquadViewModel.self) private var squadVM
    
    @State private var activityType: ActivityType = .training
    @State private var targetDistance: String = ""
    @State private var targetDuration: String = ""
    @State private var useQuickDistance = true  // ✅ Toggle pour distance rapide
    @State private var quickDistance: Double = 5.0  // ✅ Distance pré-définie
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    init(squad: SquadModel, onSessionCreated: (() -> Void)? = nil) {
        self.squad = squad
        self.onSessionCreated = onSessionCreated
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Type de session
                        sessionTypeSection
                        
                        // Objectifs
                        goalsSection
                        
                        // Bouton Créer
                        createButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Nouvelle session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.coralAccent)
                    .disabled(isCreating)
                }
            }
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "figure.run")
                        .font(.title)
                        .foregroundColor(.white)
                }
            
            VStack(spacing: 4) {
                Text("Créer une session")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("pour \(squad.name)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Session Type Section
    
    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type de session")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(ActivityType.allCases, id: \.self) { type in
                    SessionTypeCard(
                        type: type,
                        isSelected: activityType == type
                    ) {
                        activityType = type
                    }
                }
            }
        }
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Objectifs (optionnel)")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Distance - Mode Rapide
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Distance cible", systemImage: "location.fill")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                useQuickDistance.toggle()
                                // Vider le champ personnalisé lors du retour au mode rapide
                                if useQuickDistance {
                                    targetDistance = ""
                                }
                            }
                        } label: {
                            Text(useQuickDistance ? "Personnalisé" : "Rapide")
                                .font(.caption)
                                .foregroundColor(.coralAccent)
                        }
                    }
                    
                    if useQuickDistance {
                        // ✅ Picker pour sélection rapide
                        Picker("Distance", selection: $quickDistance) {
                            Text("1 km").tag(1.0)
                            Text("3 km").tag(3.0)
                            Text("5 km").tag(5.0)
                            Text("10 km").tag(10.0)
                            Text("15 km").tag(15.0)
                            Text("21 km").tag(21.1)
                            Text("42 km").tag(42.2)
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        // ✅ TextField avec binding filtré pour saisie personnalisée
                        HStack {
                            TextField("Ex: 10", text: filteredDistanceBinding)
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundColor(.white)
                            
                            Text("km")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 40)
                        }
                    }
                }
                
                // Durée
                VStack(alignment: .leading, spacing: 8) {
                    Label("Durée cible", systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        TextField("Ex: 60", text: filteredDurationBinding)
                            .keyboardType(.numberPad)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundColor(.white)
                        
                        Text("min")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 40)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Filtered Bindings
    
    /// Binding filtré pour la distance (uniquement chiffres et un point/virgule)
    private var filteredDistanceBinding: Binding<String> {
        Binding(
            get: { targetDistance },
            set: { newValue in
                // Filtrer immédiatement au niveau du binding
                var filtered = newValue.filter { "0123456789.,".contains($0) }
                
                // Remplacer les virgules par des points
                filtered = filtered.replacingOccurrences(of: ",", with: ".")
                
                // Ne garder qu'un seul point
                if filtered.filter({ $0 == "." }).count > 1 {
                    if let firstDotIndex = filtered.firstIndex(of: ".") {
                        var result = ""
                        var dotSeen = false
                        for char in filtered {
                            if char == "." {
                                if !dotSeen {
                                    result.append(char)
                                    dotSeen = true
                                }
                            } else {
                                result.append(char)
                            }
                        }
                        filtered = result
                    }
                }
                
                // Limiter à 2 décimales
                if let dotIndex = filtered.firstIndex(of: ".") {
                    let afterDot = filtered[filtered.index(after: dotIndex)...]
                    if afterDot.count > 2 {
                        let beforeDot = filtered[..<filtered.index(after: dotIndex)]
                        let twoDecimals = afterDot.prefix(2)
                        filtered = String(beforeDot) + String(twoDecimals)
                    }
                }
                
                // Limiter à 3 chiffres avant le point (999.99 km max)
                if let dotIndex = filtered.firstIndex(of: ".") {
                    let beforeDot = filtered[..<dotIndex]
                    if beforeDot.count > 3 {
                        let limited = beforeDot.prefix(3)
                        filtered = String(limited) + String(filtered[dotIndex...])
                    }
                } else if filtered.count > 3 {
                    filtered = String(filtered.prefix(3))
                }
                
                targetDistance = filtered
            }
        )
    }
    
    /// Binding filtré pour la durée (uniquement chiffres)
    private var filteredDurationBinding: Binding<String> {
        Binding(
            get: { targetDuration },
            set: { newValue in
                // Filtrer immédiatement - uniquement les chiffres
                let filtered = newValue.filter { $0.isNumber }
                // Limiter à 4 chiffres (9999 minutes max = 166 heures)
                targetDuration = String(filtered.prefix(4))
            }
        )
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button {
            createSession()
        } label: {
            HStack {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Créer et rejoindre")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.coralAccent, Color.pinkAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isCreating)
        .opacity(isCreating ? 0.6 : 1.0)
    }
    
    // MARK: - Actions
    
    private func createSession() {
        guard let squadId = squad.id else {
            errorMessage = "Squad ID non valide"
            return
        }
        
        guard let userId = AuthService.shared.currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        isCreating = true
        
        Task {
            // ✅ FIX: Timeout de 10 secondes pour la création
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if isCreating {
                    Logger.log("⏱️ Timeout lors de la création de session", category: .session)
                    isCreating = false
                    errorMessage = "La création prend trop de temps. Vérifiez votre connexion."
                }
            }
            
            do {
                // Vérifier d'abord s'il existe déjà une session active
                Logger.log("🔍 Vérification session active pour squad: \(squadId)", category: .session)
                
                if let existingSession = try await SessionService.shared.getActiveSession(squadId: squadId) {
                    Logger.log("⚠️ Une session active existe déjà: \(existingSession.id ?? "unknown")", category: .session)
                    timeoutTask.cancel()
                    isCreating = false
                    errorMessage = "Une session est déjà active pour cette squad"
                    return
                }
                
                Logger.log("🚀 Création de la session...", category: .session)
                
                // Créer la session via le service
                let _ = try await SessionService.shared.createSession(
                    squadId: squadId,
                    creatorId: userId,
                    startLocation: nil
                )
                
                timeoutTask.cancel()
                isCreating = false
                
                Logger.logSuccess("✅ Session créée avec succès", category: .session)
                
                // Fermer la sheet
                dismiss()
                
                // Notifier que la session est créée
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSessionCreated?()
                }
                
            } catch {
                timeoutTask.cancel()
                isCreating = false
                errorMessage = error.localizedDescription
                Logger.logError(error, context: "createSession", category: .session)
            }
        }
    }
}

// MARK: - Session Type Card

struct SessionTypeCard: View {
    let type: ActivityType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? colorForType : .white.opacity(0.7))
                    .frame(width: 30)
                
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colorForType)
                }
            }
            .padding()
            .background(isSelected ? colorForType.opacity(0.2) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(colorForType, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var colorForType: Color {
        switch type {
        case .training: return .coralAccent
        case .race: return .red
        case .interval: return .orange
        case .recovery: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    CreateSessionView(squad: SquadModel(
        name: "Marathon Paris 2024",
        description: "Préparation marathon",
        inviteCode: "ABC123",
        creatorId: "user1",
        members: ["user1": .admin]
    ))
    .preferredColorScheme(.dark)
}
