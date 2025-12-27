//
//  CreateSquadView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue pour créer un nouveau squad
struct CreateSquadView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var squadName = ""
    @State private var squadDescription = ""
    @State private var isPublic = true
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image placeholder
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.coralAccent, Color.pinkAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                        
                        // Formulaire
                        VStack(spacing: 16) {
                            // Nom du squad
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nom du squad")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                TextField("Ex: Marathon 2024", text: $squadName)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundColor(.white)
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                TextField("Décrivez votre squad...", text: $squadDescription, axis: .vertical)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundColor(.white)
                            }
                            
                            // Public/Privé (pour future utilisation)
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $isPublic) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Squad public")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        
                                        Text("Tout le monde peut rejoindre")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .tint(.coralAccent)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        
                        // Bouton Créer
                        Button {
                            createSquad()
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Créer le squad")
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
                        .disabled(squadName.isEmpty || isCreating)
                        .opacity(squadName.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Créer un Squad")
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
    
    // MARK: - Actions
    
    private func createSquad() {
        guard let userId = AuthService.shared.currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        isCreating = true
        
        Task {
            do {
                let squad = try await SquadService.shared.createSquad(
                    name: squadName,
                    description: squadDescription,
                    creatorId: userId
                )
                
                print("✅ Squad créée: \(squad.id ?? "unknown")")
                print("   Code d'invitation: \(squad.inviteCode)")
                
                // Fermer la vue
                dismiss()
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isCreating = false
        }
    }
}

// MARK: - Preview

#Preview {
    CreateSquadView()
        .preferredColorScheme(.dark)
}
