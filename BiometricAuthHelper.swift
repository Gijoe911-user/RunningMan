//
//  BiometricAuthHelper.swift
//  RunningMan
//
//  Helper pour gérer l'authentification biométrique (Face ID / Touch ID)
//

import LocalAuthentication
import SwiftUI

/// Helper pour gérer l'authentification biométrique
class BiometricAuthHelper {
    
    static let shared = BiometricAuthHelper()
    
    private init() {}
    
    // MARK: - Biometric Type
    
    /// Type de biométrie disponible sur l'appareil
    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
        
        var displayName: String {
            switch self {
            case .none: return "Aucune"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }
        
        var iconName: String {
            switch self {
            case .none: return "lock"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .opticID: return "opticid"
            }
        }
    }
    
    // MARK: - Check Availability
    
    /// Vérifie si la biométrie est disponible sur l'appareil
    /// - Returns: True si disponible
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Retourne le type de biométrie disponible
    /// - Returns: Type de biométrie (FaceID, TouchID, OpticID, ou none)
    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        // iOS 11+
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    // MARK: - Authenticate
    
    /// Authentifie l'utilisateur avec la biométrie
    /// - Parameter reason: Raison affichée à l'utilisateur
    /// - Returns: True si l'authentification a réussi
    func authenticate(reason: String = "Connectez-vous à RunningMan") async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Vérifier si disponible
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            Logger.log("⚠️ Biométrie non disponible: \(error?.localizedDescription ?? "inconnu")", category: .auth)
            throw BiometricError.biometricUnavailable
        }
        
        // Configurer le contexte
        context.localizedCancelTitle = "Annuler"
        context.localizedFallbackTitle = "Utiliser le mot de passe"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                Logger.logSuccess("Authentification biométrique réussie", category: .auth)
            }
            
            return success
            
        } catch let error as LAError {
            Logger.logError(error, context: "Biometric authentication", category: .auth)
            throw BiometricError.from(laError: error)
        }
    }
    
    /// Authentifie avec fallback sur code/mot de passe de l'appareil
    /// - Parameter reason: Raison affichée à l'utilisateur
    /// - Returns: True si l'authentification a réussi
    func authenticateWithFallback(reason: String = "Connectez-vous à RunningMan") async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            Logger.log("⚠️ Authentification appareil non disponible", category: .auth)
            throw BiometricError.authenticationUnavailable
        }
        
        context.localizedCancelTitle = "Annuler"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            if success {
                Logger.logSuccess("Authentification appareil réussie", category: .auth)
            }
            
            return success
            
        } catch let error as LAError {
            Logger.logError(error, context: "Device authentication", category: .auth)
            throw BiometricError.from(laError: error)
        }
    }
}

// MARK: - Biometric Error

/// Erreurs possibles lors de l'authentification biométrique
enum BiometricError: LocalizedError {
    case biometricUnavailable
    case authenticationUnavailable
    case authenticationFailed
    case userCancel
    case userFallback
    case biometryNotEnrolled
    case biometryLockout
    case appCancel
    case invalidContext
    case notInteractive
    case passcodeNotSet
    case systemCancel
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .biometricUnavailable:
            return "La biométrie n'est pas disponible sur cet appareil"
        case .authenticationUnavailable:
            return "L'authentification n'est pas disponible"
        case .authenticationFailed:
            return "L'authentification a échoué"
        case .userCancel:
            return "Authentification annulée"
        case .userFallback:
            return "L'utilisateur a choisi le mot de passe"
        case .biometryNotEnrolled:
            return "Aucune biométrie configurée. Configurez Face ID ou Touch ID dans les Réglages."
        case .biometryLockout:
            return "Biométrie verrouillée après trop de tentatives. Utilisez le code de l'appareil."
        case .appCancel:
            return "Authentification annulée par l'app"
        case .invalidContext:
            return "Contexte d'authentification invalide"
        case .notInteractive:
            return "Interaction requise"
        case .passcodeNotSet:
            return "Aucun code configuré sur l'appareil"
        case .systemCancel:
            return "Authentification annulée par le système"
        case .unknown:
            return "Erreur inconnue"
        }
    }
    
    static func from(laError: LAError) -> BiometricError {
        switch laError.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        case .passcodeNotSet:
            return .passcodeNotSet
        case .systemCancel:
            return .systemCancel
        default:
            return .unknown
        }
    }
}

// MARK: - SwiftUI View Extension

extension View {
    
    /// Présente une authentification biométrique
    /// - Parameters:
    ///   - isPresented: Binding pour contrôler la présentation
    ///   - reason: Raison affichée à l'utilisateur
    ///   - onSuccess: Action à exécuter en cas de succès
    ///   - onFailure: Action à exécuter en cas d'échec
    /// - Returns: Vue modifiée
    func biometricAuthentication(
        isPresented: Binding<Bool>,
        reason: String = "Authentifiez-vous pour continuer",
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (BiometricError) -> Void = { _ in }
    ) -> some View {
        self.onChange(of: isPresented.wrappedValue) { oldValue, newValue in
            guard newValue else { return }
            
            Task {
                do {
                    let success = try await BiometricAuthHelper.shared.authenticate(reason: reason)
                    
                    await MainActor.run {
                        isPresented.wrappedValue = false
                        if success {
                            onSuccess()
                        }
                    }
                } catch let error as BiometricError {
                    await MainActor.run {
                        isPresented.wrappedValue = false
                        onFailure(error)
                    }
                } catch {
                    await MainActor.run {
                        isPresented.wrappedValue = false
                        onFailure(.unknown)
                    }
                }
            }
        }
    }
}

// MARK: - Usage Examples
/*
 ═══════════════════════════════════════════════════════════════════════════
 EXEMPLES D'UTILISATION :
 ═══════════════════════════════════════════════════════════════════════════
 
 // 1. Bouton de connexion rapide avec biométrie
 struct LoginView: View {
     @Environment(AuthViewModel.self) private var authVM
     @State private var showBiometricAuth = false
     @State private var errorMessage: String?
     
     var body: some View {
         VStack {
             // Formulaire de connexion normal...
             
             // Bouton de connexion rapide si des identifiants sont sauvegardés
             if authVM.hasSavedCredentials() {
                 Button {
                     showBiometricAuth = true
                 } label: {
                     HStack {
                         Image(systemName: BiometricAuthHelper.shared.biometricType().iconName)
                         Text("Connexion rapide avec \(BiometricAuthHelper.shared.biometricType().displayName)")
                     }
                     .foregroundStyle(.coralAccent)
                 }
                 .padding()
             }
         }
         .biometricAuthentication(isPresented: $showBiometricAuth) {
             // Succès : connexion automatique
             Task {
                 await authVM.attemptQuickLogin()
             }
         } onFailure: { error in
             // Échec : afficher l'erreur
             errorMessage = error.errorDescription
         }
         .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
             Button("OK") {
                 errorMessage = nil
             }
         } message: {
             if let message = errorMessage {
                 Text(message)
             }
         }
     }
 }
 
 // 2. Approche plus manuelle avec contrôle total
 struct LoginView: View {
     @Environment(AuthViewModel.self) private var authVM
     
     func authenticateWithBiometrics() {
         // Vérifier la disponibilité
         guard BiometricAuthHelper.shared.isBiometricAvailable() else {
             print("Biométrie non disponible")
             return
         }
         
         Task {
             do {
                 // Authentifier
                 let success = try await BiometricAuthHelper.shared.authenticate(
                     reason: "Connectez-vous à RunningMan"
                 )
                 
                 if success {
                     // Connexion rapide
                     await authVM.attemptQuickLogin()
                 }
             } catch let error as BiometricError {
                 print("Erreur: \(error.errorDescription ?? "Inconnue")")
             }
         }
     }
     
     var body: some View {
         Button("Se connecter avec Face ID") {
             authenticateWithBiometrics()
         }
     }
 }
 
 // 3. Affichage adaptatif selon le type de biométrie
 struct QuickLoginButton: View {
     let action: () -> Void
     
     private var biometricType: BiometricAuthHelper.BiometricType {
         BiometricAuthHelper.shared.biometricType()
     }
     
     var body: some View {
         if biometricType != .none {
             Button(action: action) {
                 HStack {
                     Image(systemName: biometricType.iconName)
                         .font(.title2)
                     
                     VStack(alignment: .leading, spacing: 2) {
                         Text("Connexion rapide")
                             .font(.headline)
                         Text("Avec \(biometricType.displayName)")
                             .font(.caption)
                             .foregroundStyle(.secondary)
                     }
                 }
                 .padding()
                 .frame(maxWidth: .infinity)
                 .background(.ultraThinMaterial)
                 .clipShape(RoundedRectangle(cornerRadius: 12))
             }
         }
     }
 }
 
 // 4. Afficher dans LoginView
 struct LoginView: View {
     @Environment(AuthViewModel.self) private var authVM
     @State private var showBiometric = false
     
     var body: some View {
         VStack(spacing: 20) {
             // ... formulaire normal ...
             
             if authVM.hasSavedCredentials() {
                 Divider()
                 
                 QuickLoginButton {
                     showBiometric = true
                 }
             }
         }
         .biometricAuthentication(isPresented: $showBiometric) {
             Task {
                 await authVM.attemptQuickLogin()
             }
         }
     }
 }
 
 // 5. Verrouiller une section sensible de l'app
 struct SettingsView: View {
     @State private var isAuthenticated = false
     @State private var showAuth = false
     
     var body: some View {
         Group {
             if isAuthenticated {
                 // Contenu sensible
                 Text("Paramètres de sécurité")
             } else {
                 Button("Déverrouiller") {
                     showAuth = true
                 }
             }
         }
         .biometricAuthentication(isPresented: $showAuth) {
             isAuthenticated = true
         }
     }
 }
 
 ═══════════════════════════════════════════════════════════════════════════
 
 📝 CONFIGURATION REQUISE :
 
 1. Info.plist :
    - Ajoutez la clé NSFaceIDUsageDescription
    - Message : "RunningMan utilise Face ID pour une connexion rapide et sécurisée"
 
 2. Capabilities :
    - Aucune capability spéciale requise
    - Face ID/Touch ID fonctionne out-of-the-box
 
 3. Test :
    - Sur simulateur : Features → Face ID → Enrolled
    - Simuler succès/échec depuis le menu Features → Face ID
 
 ═══════════════════════════════════════════════════════════════════════════
*/
