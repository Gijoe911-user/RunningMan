//
//  JoinSquadView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue pour rejoindre un squad existant avec un code d'accès
struct JoinSquadView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(SquadViewModel.self) private var squadVM
    
    @State private var accessCode = ""
    @State private var isJoining = false
    @State private var showSuccessSheet = false
    @State private var joinedSquad: SquadModel?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Icône
                    Image(systemName: "key.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.coralAccent)
                        .symbolEffect(.bounce)
                    
                    // Titre et description
                    VStack(spacing: 12) {
                        Text("Rejoindre un Squad")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Entrez le code d'accès fourni par le créateur du squad")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // Champ code d'accès
                    VStack(spacing: 16) {
                        TextField("CODE D'ACCÈS", text: $accessCode)
                            .textCase(.uppercase)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 40)
                            .onChange(of: accessCode) { oldValue, newValue in
                                // Limiter à 6 caractères
                                if newValue.count > 6 {
                                    accessCode = String(newValue.prefix(6))
                                }
                                // Effacer l'erreur lors de la saisie
                                squadVM.clearMessages()
                            }
                        
                        if let error = squadVM.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Text("Le code contient 6 caractères")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Bouton rejoindre
                    Button {
                        joinSquad()
                    } label: {
                        HStack {
                            if isJoining {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Rejoindre le Squad")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            accessCode.count == 6 
                                ? LinearGradient(
                                    colors: [Color.coralAccent, Color.pinkAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(accessCode.count != 6 || isJoining)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
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
            .sheet(isPresented: $showSuccessSheet) {
                if let squad = joinedSquad {
                    SquadJoinedSuccessView(squad: squad) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Join Squad
    
    private func joinSquad() {
        isJoining = true
        
        Task {
            let success = await squadVM.joinSquad(inviteCode: accessCode)
            
            isJoining = false
            
            if success {
                // Afficher l'écran de succès
                if let squad = squadVM.userSquads.last {
                    joinedSquad = squad
                    showSuccessSheet = true
                }
            }
        }
    }
}

// MARK: - Squad Joined Success View

struct SquadJoinedSuccessView: View {
    let squad: SquadModel
    let onDismiss: () -> Void
    
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
                        Text("Bienvenue ! 🎉")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Vous avez rejoint")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(squad.name)
                            .font(.title2.bold())
                            .foregroundColor(.coralAccent)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // Description du squad
                    if !squad.description.isEmpty {
                        Text(squad.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                    
                    // Bouton Terminer
                    Button {
                        onDismiss()
                    } label: {
                        Text("Commencer")
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
    JoinSquadView()
        .preferredColorScheme(.dark)
}
