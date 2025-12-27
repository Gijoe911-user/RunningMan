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
    @Environment(SquadViewModel.self) private var squadVM
    
    @State private var squadName = ""
    @State private var squadDescription = ""
    @State private var isPublic = true
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showSuccessSheet = false
    @State private var createdSquad: SquadModel?
    
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
            .sheet(isPresented: $showSuccessSheet) {
                if let squad = createdSquad {
                    SquadCreatedSuccessView(squad: squad) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func createSquad() {
        isCreating = true
        
        Task {
            let success = await squadVM.createSquad(
                name: squadName,
                description: squadDescription
            )
            
            isCreating = false
            
            if success {
                // Afficher l'écran de succès avec le code d'invitation
                if let squad = squadVM.userSquads.first(where: { $0.name == squadName }) {
                    createdSquad = squad
                    showSuccessSheet = true
                }
            } else if let error = squadVM.errorMessage {
                errorMessage = error
            }
        }
    }
}

// MARK: - Squad Created Success View

struct SquadCreatedSuccessView: View {
    let squad: SquadModel
    let onDismiss: () -> Void
    
    @State private var copiedToClipboard = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Icône de succès
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.greenAccent.opacity(0.3), Color.greenAccent.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.greenAccent)
                            .symbolEffect(.bounce)
                    }
                    
                    // Message de succès
                    VStack(spacing: 12) {
                        Text("Squad créé ! 🎉")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Partagez ce code pour inviter vos amis")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Code d'invitation
                    VStack(spacing: 16) {
                        Text("Code d'invitation")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 12) {
                            Text(squad.inviteCode)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(.coralAccent)
                                .tracking(4)
                            
                            Button {
                                UIPasteboard.general.string = squad.inviteCode
                                copiedToClipboard = true
                                
                                // Feedback haptique
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                
                                // Réinitialiser après 2 secondes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedToClipboard = false
                                }
                            } label: {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                    .font(.title3)
                                    .foregroundColor(copiedToClipboard ? .greenAccent : .white)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if copiedToClipboard {
                            Text("Copié !")
                                .font(.caption)
                                .foregroundColor(.greenAccent)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Bouton Terminer
                    Button {
                        onDismiss()
                    } label: {
                        Text("Terminer")
                            .font(.headline)
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
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Succès")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Preview

#Preview {
    CreateSquadView()
        .preferredColorScheme(.dark)
}
