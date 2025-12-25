//
//  LoginView+BiometricExample.swift
//  RunningMan
//
//  Exemple complet d'intégration Face ID dans LoginView
//  Copiez les parties qui vous intéressent dans votre LoginView.swift existant
//

import SwiftUI

/*
 ═══════════════════════════════════════════════════════════════════════════
 EXEMPLE : LoginView avec Face ID
 ═══════════════════════════════════════════════════════════════════════════
 
 Cet exemple montre comment ajouter un bouton de connexion rapide avec Face ID
 dans votre LoginView existant.
 
 ⚠️ NE REMPLACEZ PAS votre LoginView.swift actuel !
 Copiez seulement les parties que vous voulez intégrer.
 
 ═══════════════════════════════════════════════════════════════════════════
*/

// MARK: - Exemple de LoginView avec Face ID

struct LoginViewWithBiometric: View {
    
    @Environment(AuthViewModel.self) private var authVM
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUpMode = false
    @State private var showForgotPassword = false
    
    // NOUVEAU : États pour Face ID
    @State private var showBiometricAuth = false
    @State private var biometricError: String?
    
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
                        
                        // NOUVEAU : Bouton de connexion rapide
                        if !isSignUpMode && authVM.hasSavedCredentials() {
                            quickLoginSection
                                .padding([.top], 20)
                                .padding([.horizontal], 20)
                        }
                        
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
            // NOUVEAU : Alert pour les erreurs biométriques
            .alert("Erreur d'authentification", isPresented: .constant(biometricError != nil)) {
                Button("OK") {
                    biometricError = nil
                }
            } message: {
                if let error = biometricError {
                    Text(error)
                }
            }
            // NOUVEAU : Modifier biométrique
            .biometricAuthentication(isPresented: $showBiometricAuth) {
                // Succès : connexion automatique
                Task {
                    let success = await authVM.attemptQuickLogin()
                    if !success {
                        biometricError = "Impossible de se connecter. Vérifiez votre connexion internet."
                    }
                }
            } onFailure: { error in
                // Échec : afficher l'erreur
                biometricError = error.errorDescription
            }
        }
    }
    
    // MARK: - Header Section (inchangé)
    
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
    
    // MARK: - Form Section (votre formulaire existant)
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // ... votre formulaire existant ...
            // (Mode toggle, champs, bouton submit)
            
            Text("Votre formulaire existant ici")
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - NOUVEAU : Quick Login Section
    
    private var quickLoginSection: some View {
        VStack(spacing: 16) {
            // Divider avec texte
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
                
                Text("OU")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Bouton Face ID / Touch ID
            Button {
                showBiometricAuth = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: biometricType.iconName)
                        .font(.title2)
                        .foregroundColor(.coralAccent)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connexion rapide")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("Avec \(biometricType.displayName)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
    
    // NOUVEAU : Computed property pour le type de biométrie
    private var biometricType: BiometricAuthHelper.BiometricType {
        BiometricAuthHelper.shared.biometricType()
    }
}

// MARK: - Version simplifiée (Bouton minimal)

/*
 Si vous voulez juste un bouton simple, copiez ceci dans votre LoginView :
 */

extension View {
    @ViewBuilder
    func quickLoginButton(
        isVisible: Bool,
        action: @escaping () -> Void
    ) -> some View {
        if isVisible {
            VStack(spacing: 12) {
                // Divider
                HStack {
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("OU")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal)
                    
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: 1)
                }
                
                // Bouton
                Button(action: action) {
                    HStack {
                        Image(systemName: BiometricAuthHelper.shared.biometricType().iconName)
                        Text("Connexion rapide")
                    }
                    .foregroundColor(.coralAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

// Usage dans votre LoginView :
/*
 .quickLoginButton(
     isVisible: !isSignUpMode && authVM.hasSavedCredentials()
 ) {
     showBiometricAuth = true
 }
*/

// MARK: - Exemple d'intégration dans votre LoginView existant

/*
 ═══════════════════════════════════════════════════════════════════════════
 INTÉGRATION ÉTAPE PAR ÉTAPE
 ═══════════════════════════════════════════════════════════════════════════
 
 ÉTAPE 1 : Ajouter les états
 ─────────────────────────────
 Dans votre LoginView, ajoutez ces @State :
 
 @State private var showBiometricAuth = false
 @State private var biometricError: String?
 
 
 ÉTAPE 2 : Ajouter le bouton
 ─────────────────────────────
 Après votre formSection, ajoutez :
 
 if !isSignUpMode && authVM.hasSavedCredentials() {
     VStack(spacing: 12) {
         HStack {
             Rectangle().fill(.white.opacity(0.3)).frame(height: 1)
             Text("OU").font(.caption).foregroundStyle(.white.opacity(0.7))
             Rectangle().fill(.white.opacity(0.3)).frame(height: 1)
         }
         
         Button {
             showBiometricAuth = true
         } label: {
             HStack {
                 Image(systemName: "faceid")
                 Text("Connexion rapide")
             }
             .foregroundColor(.coralAccent)
             .frame(maxWidth: .infinity)
             .padding()
             .background(.ultraThinMaterial)
             .clipShape(RoundedRectangle(cornerRadius: 12))
         }
     }
     .padding(.horizontal, 20)
     .padding(.top, 20)
 }
 
 
 ÉTAPE 3 : Ajouter le modifier biométrique
 ─────────────────────────────────────────
 À la fin de votre NavigationStack, avant la fermeture du body :
 
 .biometricAuthentication(isPresented: $showBiometricAuth) {
     Task {
         await authVM.attemptQuickLogin()
     }
 } onFailure: { error in
     biometricError = error.errorDescription
 }
 
 
 ÉTAPE 4 : Ajouter l'alert d'erreur
 ─────────────────────────────────
 Après vos autres .alert() :
 
 .alert("Erreur", isPresented: .constant(biometricError != nil)) {
     Button("OK") { biometricError = nil }
 } message: {
     if let error = biometricError {
         Text(error)
     }
 }
 
 
 ÉTAPE 5 : Utiliser signInAndSave
 ─────────────────────────────────
 Dans votre fonction submitForm(), remplacez :
 
 await authVM.signIn(email: email, password: password)
 
 Par :
 
 await authVM.signInAndSave(email: email, password: password)
 
 
 ═══════════════════════════════════════════════════════════════════════════
 C'EST TOUT ! 🎉
 ═══════════════════════════════════════════════════════════════════════════
 
 Votre LoginView aura maintenant :
 - ✅ AutoFill automatique (déjà fait avec textContentType)
 - ✅ Sauvegarde dans Keychain
 - ✅ Bouton de connexion rapide avec Face ID
 - ✅ Gestion des erreurs
 
 ═══════════════════════════════════════════════════════════════════════════
*/

// MARK: - Preview

#Preview {
    LoginViewWithBiometric()
        .environment(AuthViewModel())
}
