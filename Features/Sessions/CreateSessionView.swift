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
                // Distance
                VStack(alignment: .leading, spacing: 8) {
                    Label("Distance cible", systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        TextField("Ex: 10", text: $targetDistance)
                            .keyboardType(.decimalPad)
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
                
                // Durée
                VStack(alignment: .leading, spacing: 8) {
                    Label("Durée cible", systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack {
                        TextField("Ex: 60", text: $targetDuration)
                            .keyboardType(.numberPad)
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
            do {
                // Vérifier d'abord s'il existe déjà une session active
                if let existingSession = try await SessionService.shared.getActiveSession(squadId: squadId) {
                    Logger.log("⚠️ Une session active existe déjà: \(existingSession.id ?? "unknown")", category: .session)
                    isCreating = false
                    errorMessage = "Une session est déjà active pour cette squad"
                    return
                }
                
                // Créer la session via le service
                let _ = try await SessionService.shared.createSession(
                    squadId: squadId,
                    creatorId: userId,
                    startLocation: nil
                )
                
                isCreating = false
                
                // Fermer la sheet
                dismiss()
                
                // Notifier que la session est créée
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onSessionCreated?()
                }
                
            } catch {
                isCreating = false
                errorMessage = error.localizedDescription
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
