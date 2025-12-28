//
//  LoginView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue de connexion et d'inscription
struct LoginView: View {
    
    @Environment(AuthViewModel.self) private var authVM
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUpMode = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blueAccent, Color.purpleAccent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Logo et titre
                        headerSection
                        
                        // Formulaire
                        formSection
                            .padding(.horizontal, 24)
                            .padding(.vertical, 32)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 60)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Loading overlay
                if authVM.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .alert("Réinitialiser le mot de passe", isPresented: $showForgotPassword) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                Button("Envoyer") {
                    Task {
                        let success = await authVM.sendPasswordReset(email: email)
                        if success {
                            showForgotPassword = false
                        }
                    }
                }
                
                Button("Annuler", role: .cancel) {
                    showForgotPassword = false
                }
            } message: {
                Text("Entrez votre adresse email pour recevoir un lien de réinitialisation")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundStyle(.white)
                .shadow(radius: 10)
            
            Text("RunningMan")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 5)
            
            Text("Courez ensemble, plus fort")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Mode toggle
            Picker("Mode", selection: $isSignUpMode.animation()) {
                Text("Connexion").tag(false)
                Text("Inscription").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            
            // Error message banner
            if let errorMessage = authVM.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Erreur")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Button {
                            withAnimation {
                                authVM.clearError()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Display Name (only for sign up)
            if isSignUpMode {
                TextField("Nom d'affichage", text: $displayName)
                    .textFieldStyle(LoginTextFieldStyle())
                    .autocorrectionDisabled()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Email
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textContentType(isSignUpMode ? .username : .username)
                        .submitLabel(.next)
                    
                    // Indicateur de validation
                    if !email.isEmpty {
                        Image(systemName: isValidEmailFormat(email) ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(isValidEmailFormat(email) ? .green : .red)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Message d'aide
                if !email.isEmpty && !isValidEmailFormat(email) {
                    Text("Format d'email invalide")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.leading, 4)
                }
            }
            
            // Password
            VStack(alignment: .leading, spacing: 4) {
                SecureTextFieldWithToggle(
                    placeholder: "Mot de passe",
                    text: $password,
                    isSignUpMode: isSignUpMode
                )
                
                // Indicateur de force du mot de passe (uniquement en mode inscription)
                if isSignUpMode && !password.isEmpty {
                    PasswordStrengthIndicator(password: password)
                }
            }
            
            // Forgot password (only in sign in mode)
            if !isSignUpMode {
                HStack {
                    Spacer()
                    Button("Mot de passe oublié ?") {
                        showForgotPassword = true
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            // Submit button
            Button {
                Logger.log("🔘 Bouton cliqué!", category: .auth)
                submitForm()
            } label: {
                HStack {
                    if authVM.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSignUpMode ? "S'inscrire" : "Se connecter")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: authVM.isLoading ? [Color.gray, Color.gray] : [Color.coralAccent, Color.pinkAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 10)
            .disabled(authVM.isLoading)
        }
    }
    
    // MARK: - Actions
    
    private func submitForm() {
        Logger.log("📝 Formulaire soumis - Mode: \(isSignUpMode ? "Inscription" : "Connexion")", category: .auth)
        Logger.log("📝 Email: \(email), DisplayName: \(displayName)", category: .auth)
        
        // Masquer le clavier
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        
        Task {
            Logger.log("🚀 Démarrage de la tâche async...", category: .auth)
            if isSignUpMode {
                Logger.log("➡️ Appel de signUp...", category: .auth)
                await authVM.signUp(
                    email: email,
                    password: password,
                    displayName: displayName
                )
                Logger.log("✅ SignUp terminé", category: .auth)
            } else {
                Logger.log("➡️ Appel de signIn...", category: .auth)
                await authVM.signIn(
                    email: email,
                    password: password
                )
                Logger.log("✅ SignIn terminé", category: .auth)
            }
        }
    }
    
    // MARK: - Email Validation
    
    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Login TextField Style (specific to login)

struct LoginTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - SecureTextField with Toggle

/// Champ de mot de passe avec bouton pour afficher/masquer
struct SecureTextFieldWithToggle: View {
    let placeholder: String
    @Binding var text: String
    var isSignUpMode: Bool = false
    @State private var isSecure: Bool = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                        .textContentType(isSignUpMode ? .newPassword : .password)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .textContentType(isSignUpMode ? .newPassword : .password)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(isSignUpMode ? .continue : .go)
            
            // Bouton œil pour afficher/masquer
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSecure.toggle()
                }
            } label: {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(isSecure ? .secondary : .blueAccent)
                    .font(.system(size: 16))
                    .frame(width: 24, height: 24)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSecure ? "Afficher le mot de passe" : "Masquer le mot de passe")
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFocused ? Color.blueAccent : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Password Strength Indicator

/// Indicateur de force du mot de passe
struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        calculateStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Barre de progression
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < strength.barCount ? strength.color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            
            // Message
            Text(strength.message)
                .font(.caption)
                .foregroundStyle(strength.color)
        }
        .padding(.horizontal, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private func calculateStrength(_ password: String) -> PasswordStrength {
        let length = password.count
        let hasUpperCase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowerCase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        var score = 0
        
        if length >= 8 { score += 1 }
        if length >= 12 { score += 1 }
        if hasUpperCase && hasLowerCase { score += 1 }
        if hasNumber { score += 1 }
        if hasSpecial { score += 1 }
        
        switch score {
        case 0...1:
            return PasswordStrength(
                barCount: 1,
                color: .red,
                message: "Mot de passe très faible"
            )
        case 2:
            return PasswordStrength(
                barCount: 2,
                color: .orange,
                message: "Mot de passe faible"
            )
        case 3:
            return PasswordStrength(
                barCount: 3,
                color: .yellow,
                message: "Mot de passe moyen"
            )
        case 4...5:
            return PasswordStrength(
                barCount: 4,
                color: .green,
                message: "Mot de passe fort"
            )
        default:
            return PasswordStrength(
                barCount: 0,
                color: .gray,
                message: ""
            )
        }
    }
}

// MARK: - Password Strength Model

struct PasswordStrength {
    let barCount: Int
    let color: Color
    let message: String
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
