//
//  CreateSessionView.swift
//  RunningMan
//
//  Created by AI Assistant on 24/12/2025.
//

import SwiftUI

/// Vue pour créer une nouvelle session de course
struct CreateSessionView: View {
    let squad: SquadModel
    
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var sessionType: SessionType = .training
    @State private var targetDistance: String = ""
    @State private var hasTargetDistance: Bool = false
    @State private var isCreating: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("DarkNavy")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Type de session
                        sessionTypeSection
                        
                        // Titre (optionnel)
                        titleSection
                        
                        // Distance cible (optionnel)
                        targetDistanceSection
                        
                        // Bouton créer
                        createButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Nouvelle Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.white)
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
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("CoralAccent"))
            
            Text("Démarrer une session")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Squad : \(squad.name)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
    }
    
    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type de session")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                SessionTypeButton(
                    type: .training,
                    icon: "figure.run",
                    label: "Entraînement",
                    isSelected: sessionType == .training
                ) {
                    sessionType = .training
                }
                
                SessionTypeButton(
                    type: .race,
                    icon: "flag.checkered",
                    label: "Course",
                    isSelected: sessionType == .race
                ) {
                    sessionType = .race
                }
                
                SessionTypeButton(
                    type: .casual,
                    icon: "figure.walk",
                    label: "Décontracté",
                    isSelected: sessionType == .casual
                ) {
                    sessionType = .casual
                }
            }
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Titre (optionnel)")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("Ex: Course du dimanche", text: $title)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }
    
    private var targetDistanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $hasTargetDistance) {
                Text("Objectif de distance")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .tint(Color("CoralAccent"))
            
            if hasTargetDistance {
                HStack {
                    TextField("Ex: 5", text: $targetDistance)
                        .textFieldStyle(.plain)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    
                    Text("km")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                }
            }
        }
    }
    
    private var createButton: some View {
        Button {
            createSession()
        } label: {
            HStack {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.circle.fill")
                    Text("Démarrer la session")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color("CoralAccent"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isCreating)
        .padding(.top)
    }
    
    // MARK: - Actions
    
    private func createSession() {
        guard let userId = AuthService.shared.currentUserId else { return }
        guard let squadId = squad.id else { return }
        
        isCreating = true
        
        Task {
            do {
                // Convertir la distance de km en mètres
                var targetMeters: Double? = nil
                if hasTargetDistance, let distance = Double(targetDistance.replacingOccurrences(of: ",", with: ".")) {
                    targetMeters = distance * 1000 // km -> mètres
                }
                
                let session = try await SessionService.shared.createSession(
                    squadId: squadId,
                    creatorId: userId,
                    title: title.isEmpty ? nil : title,
                    sessionType: sessionType,
                    targetDistance: targetMeters
                )
                
                print("✅ Session créée: \(session.id ?? "unknown")")
                
                // Fermer la vue et potentiellement naviguer vers la vue de session
                dismiss()
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isCreating = false
        }
    }
}

// MARK: - Session Type Button

private struct SessionTypeButton: View {
    let type: SessionType
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected ? Color("CoralAccent") : Color.white.opacity(0.1)
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    CreateSessionView(squad: SquadModel(
        name: "Marathon Paris 2024",
        description: "Préparation collective",
        inviteCode: "ABC123",
        creatorId: "user1",
        members: ["user1": .admin]
    ))
}
