//
//  AuthenticationView.swift
//  RunningMan
//
//  Écran d'authentification (Phase 1: Email/Password simple)
//

import SwiftUI
import FirebaseAuth

struct AuthenticationView: View {
    // ✅ Migration vers @Environment (syntaxe iOS 17+)
    @Environment(AppState.self) private var appState
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Fond dégradé
            LinearGradient(
                colors: [Color("DarkNavy"), Color("DarkNavy").opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo et titre
                VStack(spacing: 16) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("CoralAccent"), Color("CoralAccent").opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("RunningMan")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Courez ensemble, vibrez ensemble")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Formulaire
                VStack(spacing: 16) {
                    if isSignUp {
                        CustomTextField(
                            icon: "person.fill",
                            placeholder: "Nom d'affichage",
                            text: $displayName
                        )
                    }
                    
                    CustomTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    
                    CustomTextField(
                        icon: "lock.fill",
                        placeholder: "Mot de passe",
                        text: $password,
                        isSecure: true
                    )
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Color("CoralAccent"))
                            .padding(.horizontal)
                    }
                    
                    // Bouton principal
                    Button {
                        Task {
                            await handleAuthentication()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Créer un compte" : "Se connecter")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color("CoralAccent"))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(isLoading)
                    
                    // Toggle Sign Up / Sign In
                    Button {
                        withAnimation {
                            isSignUp.toggle()
                            errorMessage = nil
                        }
                    } label: {
                        Text(isSignUp ? "Déjà un compte ? Se connecter" : "Pas de compte ? S'inscrire")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
    }
    
    private func handleAuthentication() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Veuillez remplir tous les champs"
            return
        }
        
        if isSignUp && displayName.isEmpty {
            errorMessage = "Veuillez entrer un nom d'affichage"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                
                // Mettre à jour le profil
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
                
                // TODO: Créer l'utilisateur dans Firestore
            } else {
                _ = try await Auth.auth().signIn(withEmail: email, password: password)
            }
            
            appState.isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Custom TextField
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
