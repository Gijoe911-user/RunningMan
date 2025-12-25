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
    
    @State private var accessCode = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    
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
                                errorMessage = nil
                            }
                        
                        if let error = errorMessage {
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
        }
    }
    
    // MARK: - Join Squad
    
    private func joinSquad() {
        guard let userId = AuthService.shared.currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        isJoining = true
        errorMessage = nil
        
        Task {
            do {
                let squad = try await SquadService.shared.joinSquad(
                    inviteCode: accessCode,
                    userId: userId
                )
                
                print("✅ Squad rejointe: \(squad.name)")
                print("   ID: \(squad.id ?? "unknown")")
                
                // Fermer la vue
                dismiss()
                
            } catch {
                errorMessage = error.localizedDescription
                isJoining = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    JoinSquadView()
        .preferredColorScheme(.dark)
}
