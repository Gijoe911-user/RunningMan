//
//  JoinOrCreateSquadView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue pour créer ou rejoindre une Squad
struct JoinOrCreateSquadView: View {
    
    @Environment(SquadViewModel.self) private var squadVM
    @Environment(AuthViewModel.self) private var authVM
    
    @State private var isCreatingSquad = false
    @State private var squadName = ""
    @State private var squadDescription = ""
    @State private var inviteCode = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 40)
                    
                    // Mode selection
                    modeSelector
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    
                    // Form
                    if isCreatingSquad {
                        createSquadForm
                    } else {
                        joinSquadForm
                    }
                    
                    Spacer()
                }
                
                // Loading overlay
                if squadVM.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        authVM.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .alert("Erreur", isPresented: .constant(squadVM.errorMessage != nil)) {
                Button("OK") {
                    squadVM.clearMessages()
                }
            } message: {
                Text(squadVM.errorMessage ?? "")
            }
            .alert("Succès", isPresented: .constant(squadVM.successMessage != nil)) {
                Button("OK") {
                    squadVM.clearMessages()
                }
            } message: {
                Text(squadVM.successMessage ?? "")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Rejoignez une Squad")
                .font(.title.bold())
            
            Text("Les Squads permettent de courir ensemble et de s'encourager mutuellement")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Mode Selector
    
    private var modeSelector: some View {
        Picker("Mode", selection: $isCreatingSquad.animation()) {
            Text("Rejoindre").tag(false)
            Text("Créer").tag(true)
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Join Squad Form
    
    private var joinSquadForm: some View {
        VStack(spacing: 20) {
            Text("Entrez le code d'invitation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Invite code input
                TextField("CODE", text: $inviteCode)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .onChange(of: inviteCode) { oldValue, newValue in
                        // Limiter à 6 caractères
                        if newValue.count > 6 {
                            inviteCode = String(newValue.prefix(6))
                        }
                        inviteCode = inviteCode.uppercased()
                    }
                
                Text("6 caractères")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Join button
                Button {
                    joinSquad()
                } label: {
                    Text("Rejoindre la Squad")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(inviteCode.count == 6 ? Color.blue : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(inviteCode.count != 6 || squadVM.isLoading)
            }
            .padding(.horizontal, 20)
            
            Divider()
                .padding(.vertical, 20)
            
            // Info card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Comment obtenir un code ?")
                        .font(.headline)
                }
                
                Text("Demandez à un membre de votre Squad de vous partager le code d'invitation depuis les paramètres de la Squad.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Create Squad Form
    
    private var createSquadForm: some View {
        VStack(spacing: 20) {
            Text("Créez votre Squad")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                // Squad name
                TextField("Nom de la Squad", text: $squadName)
                    .textFieldStyle(CustomTextFieldStyle())
                
                // Squad description
                TextField("Description (optionnel)", text: $squadDescription, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(3...6)
                
                // Create button
                Button {
                    createSquad()
                } label: {
                    Text("Créer la Squad")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(squadName.isEmpty ? Color.gray : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(squadName.isEmpty || squadVM.isLoading)
            }
            .padding(.horizontal, 20)
            
            Divider()
                .padding(.vertical, 20)
            
            // Info card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Astuce")
                        .font(.headline)
                }
                
                Text("Une fois la Squad créée, vous recevrez un code d'invitation unique à partager avec vos amis pour qu'ils puissent rejoindre votre groupe.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Actions
    
    private func joinSquad() {
        Task {
            let success = await squadVM.joinSquad(inviteCode: inviteCode)
            if success {
                inviteCode = ""
            }
        }
    }
    
    private func createSquad() {
        Task {
            let success = await squadVM.createSquad(
                name: squadName,
                description: squadDescription
            )
            if success {
                squadName = ""
                squadDescription = ""
            }
        }
    }
}

// MARK: - Preview

#Preview {
    JoinOrCreateSquadView()
        .environment(SquadViewModel())
        .environment(AuthViewModel())
}
