//
//  AuthViewModel.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import Foundation
import SwiftUI

/// ViewModel pour gérer l'état d'authentification de l'application
@MainActor
@Observable
class AuthViewModel {
    
    // MARK: - Published Properties
    
    /// Utilisateur actuellement connecté
    var currentUser: UserModel?
    
    /// État de chargement
    var isLoading = false
    
    /// Message d'erreur
    var errorMessage: String?
    
    /// Indique si l'utilisateur est authentifié
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    /// Indique si l'utilisateur a rejoint au moins une squad
    var hasSquad: Bool {
        currentUser?.hasSquad ?? false
    }
    
    // MARK: - Services
    
    private let authService = AuthService.shared
    
    // MARK: - Initialization
    
    init() {
        // Démarrer la vérification d'authentification de manière asynchrone
        // pour éviter tout problème d'initialisation
        Task { @MainActor in
            await checkAuthState()
        }
    }
    
    // MARK: - Check Auth State
    
    /// Vérifie si un utilisateur est déjà connecté au lancement de l'app
    func checkAuthState() async {
        isLoading = true
        
        defer { isLoading = false }
        
        guard let userId = authService.currentUserId else {
            Logger.log("Aucun utilisateur connecté", category: .auth)
            return
        }
        
        do {
            currentUser = try await authService.getUserProfile(userId: userId)
            Logger.logSuccess("Utilisateur reconnecté automatiquement", category: .auth)
        } catch {
            Logger.logError(error, context: "checkAuthState", category: .auth)
            errorMessage = "Erreur lors de la récupération du profil"
        }
    }
    
    // MARK: - Sign Up
    
    /// Crée un nouveau compte utilisateur
    func signUp(email: String, password: String, displayName: String) async {
        
        Logger.log("🔵 signUp appelé - email: \(email), displayName: \(displayName)", category: .auth)
        
        // Validation
        guard !email.isEmpty, !password.isEmpty, !displayName.isEmpty else {
            Logger.logWarning("❌ Validation échouée: champs vides", category: .auth)
            withAnimation {
                errorMessage = "Tous les champs sont obligatoires"
            }
            return
        }
        
        // Valider le format de l'email
        guard isValidEmail(email) else {
            Logger.logWarning("❌ Validation échouée: format d'email invalide", category: .auth)
            withAnimation {
                errorMessage = "Format d'email invalide. Utilisez un email valide (ex: nom@exemple.com)"
            }
            return
        }
        
        guard password.count >= 6 else {
            Logger.logWarning("❌ Validation échouée: mot de passe trop court", category: .auth)
            withAnimation {
                errorMessage = "Le mot de passe doit contenir au moins 6 caractères"
            }
            return
        }
        
        Logger.log("✅ Validation réussie, démarrage de l'inscription...", category: .auth)
        isLoading = true
        errorMessage = nil
        
        do {
            Logger.log("🔄 Appel authService.signUp...", category: .auth)
            currentUser = try await authService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
            Logger.logSuccess("Inscription réussie", category: .auth)
        } catch {
            Logger.logError(error, context: "signUp", category: .auth)
            withAnimation {
                errorMessage = handleError(error)
            }
        }
        
        Logger.log("🏁 Fin de signUp, isLoading = false", category: .auth)
        isLoading = false
    }
    
    // MARK: - Sign In
    
    /// Connecte un utilisateur existant
    func signIn(email: String, password: String) async {
        
        // Validation
        guard !email.isEmpty, !password.isEmpty else {
            withAnimation {
                errorMessage = "Email et mot de passe requis"
            }
            return
        }
        
        // Valider le format de l'email
        guard isValidEmail(email) else {
            withAnimation {
                errorMessage = "Format d'email invalide. Utilisez un email valide (ex: nom@exemple.com)"
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await authService.signIn(email: email, password: password)
            Logger.logSuccess("Connexion réussie", category: .auth)
        } catch {
            Logger.logError(error, context: "signIn", category: .auth)
            withAnimation {
                errorMessage = handleError(error)
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    /// Déconnecte l'utilisateur actuel
    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
            errorMessage = nil
            Logger.logSuccess("Déconnexion réussie", category: .auth)
        } catch {
            Logger.logError(error, context: "signOut", category: .auth)
            errorMessage = "Erreur lors de la déconnexion"
        }
    }
    
    // MARK: - Password Reset
    
    /// Envoie un email de réinitialisation de mot de passe
    func sendPasswordReset(email: String) async -> Bool {
        
        guard !email.isEmpty else {
            withAnimation {
                errorMessage = "Email requis"
            }
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.sendPasswordReset(email: email)
            Logger.logSuccess("Email de réinitialisation envoyé", category: .auth)
            isLoading = false
            return true
        } catch {
            Logger.logError(error, context: "sendPasswordReset", category: .auth)
            withAnimation {
                errorMessage = "Impossible d'envoyer l'email de réinitialisation"
            }
            isLoading = false
            return false
        }
    }
    
    // MARK: - Update Profile
    
    /// Met à jour le profil de l'utilisateur
    func updateProfile(displayName: String? = nil, photoPath: String? = nil) async {
        
        guard var user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        if let displayName = displayName {
            user.displayName = displayName
        }
        
        if let photoPath = photoPath {
            user.photoURL = photoPath
        }
        
        do {
            try await authService.updateUserProfile(user)
            currentUser = user
            Logger.logSuccess("Profil mis à jour", category: .auth)
        } catch {
            Logger.logError(error, context: "updateProfile", category: .auth)
            errorMessage = "Erreur lors de la mise à jour du profil"
        }
        
        isLoading = false
    }
    
    // MARK: - Refresh User
    
    /// Rafraîchit les données de l'utilisateur depuis Firestore
    func refreshUser() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            currentUser = try await authService.getUserProfile(userId: userId)
            Logger.log("Profil utilisateur rafraîchi", category: .auth)
        } catch {
            Logger.logError(error, context: "refreshUser", category: .auth)
        }
    }
    
    // MARK: - Error Handling
    
    /// Convertit les erreurs Firebase en messages lisibles
    private func handleError(_ error: Error) -> String {
        let nsError = error as NSError
        let errorCode = nsError.code
        
        Logger.log("Code d'erreur Firebase: \(errorCode)", category: .auth)
        Logger.log("Domaine d'erreur: \(nsError.domain)", category: .auth)
        
        // Erreurs personnalisées AuthError
        if nsError.domain == "RunningMan.AuthError" {
            return error.localizedDescription
        }
        
        // Erreurs Firebase Auth
        switch errorCode {
        case 17004: // ERROR_INVALID_EMAIL
            return "Format d'email invalide. Utilisez un email valide (ex: nom@exemple.com)"
        case 17007: // EMAIL_ALREADY_IN_USE
            return "Cette adresse email est déjà utilisée"
        case 17008: // INVALID_EMAIL (autre variante)
            return "Adresse email invalide"
        case 17009: // WRONG_PASSWORD
            return "Mot de passe incorrect"
        case 17011: // USER_NOT_FOUND
            return "Aucun compte associé à cet email"
        case 17026: // WEAK_PASSWORD
            return "Le mot de passe est trop faible"
        case 17020: // NETWORK_ERROR
            return "Erreur réseau. Vérifiez votre connexion."
        case 17999: // INVALID_CREDENTIAL
            return "Identifiants invalides. Vérifiez votre email et mot de passe."
        default:
            Logger.log("Erreur non gérée: \(error.localizedDescription)", category: .auth)
            return error.localizedDescription
        }
    }
    
    // MARK: - Clear Error
    
    /// Efface le message d'erreur
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Email Validation
    
    /// Valide le format d'un email
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        let isValid = emailPredicate.evaluate(with: email)
        
        if !isValid {
            Logger.logWarning("Email invalide détecté: '\(email)'", category: .auth)
        }
        
        return isValid
    }
}


// Extension pour gérer automatiquement le Keychain lors de l'authentification
extension AuthViewModel {
    
    // MARK: - Sign In avec Keychain
    
    /// Connecte un utilisateur et sauvegarde automatiquement les identifiants dans le Keychain
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - password: Mot de passe
    ///   - saveToKeychain: Si true, sauvegarde les identifiants dans le Keychain (par défaut: true)
    func signInAndSave(email: String, password: String, saveToKeychain: Bool = true) async {
        // Utilise la méthode signIn existante
        await signIn(email: email, password: password)
        
        // Si la connexion a réussi et que la sauvegarde est activée
        if isAuthenticated && saveToKeychain {
            Logger.log("💾 Sauvegarde des identifiants dans le Keychain", category: .auth)
            KeychainHelper.shared.save(email: email, password: password)
        }
    }
    
    // MARK: - Sign Up avec Keychain
    
    /// Crée un compte et sauvegarde automatiquement les identifiants dans le Keychain
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - password: Mot de passe
    ///   - displayName: Nom d'affichage
    ///   - saveToKeychain: Si true, sauvegarde les identifiants dans le Keychain (par défaut: true)
    func signUpAndSave(email: String, password: String, displayName: String, saveToKeychain: Bool = true) async {
        // Utilise la méthode signUp existante
        await signUp(email: email, password: password, displayName: displayName)
        
        // Si l'inscription a réussi et que la sauvegarde est activée
        if isAuthenticated && saveToKeychain {
            Logger.log("💾 Sauvegarde des identifiants dans le Keychain", category: .auth)
            KeychainHelper.shared.save(email: email, password: password)
        }
    }
    
    // MARK: - Sign Out avec Keychain
    
    /// Déconnecte l'utilisateur et supprime les identifiants du Keychain
    /// - Parameter deleteFromKeychain: Si true, supprime les identifiants du Keychain (par défaut: false)
    func signOutAndDelete(deleteFromKeychain: Bool = false) {
        // Déconnexion normale
        signOut()
        
        // Supprimer du Keychain si demandé
        if deleteFromKeychain {
            Logger.log("🗑️ Suppression des identifiants du Keychain", category: .auth)
            KeychainHelper.shared.delete()
        }
    }
    
    // MARK: - Quick Login (Touch ID / Face ID)
    
    /// Tente une connexion rapide avec les identifiants sauvegardés
    /// Utile pour implémenter Touch ID / Face ID
    /// - Returns: True si des identifiants ont été trouvés et une tentative de connexion a été faite
    func attemptQuickLogin() async -> Bool {
        Logger.log("🔐 Tentative de connexion rapide", category: .auth)
        
        // Récupérer les identifiants du Keychain
        guard let credentials = KeychainHelper.shared.retrieve() else {
            Logger.log("⚠️ Aucun identifiant sauvegardé trouvé", category: .auth)
            return false
        }
        
        Logger.log("✅ Identifiants trouvés, connexion en cours...", category: .auth)
        
        // Tenter la connexion
        await signIn(email: credentials.email, password: credentials.password)
        
        return true
    }
    
    // MARK: - Pre-fill Email
    
    /// Récupère l'email sauvegardé pour pré-remplir le formulaire
    /// - Returns: L'email si disponible, nil sinon
    func getSavedEmail() -> String? {
        guard let credentials = KeychainHelper.shared.retrieve() else {
            return nil
        }
        return credentials.email
    }
    
    // MARK: - Check Saved Credentials
    
    /// Vérifie si des identifiants sont sauvegardés
    /// - Returns: True si des identifiants existent dans le Keychain
    func hasSavedCredentials() -> Bool {
        return KeychainHelper.shared.hasCredentials()
    }
}
