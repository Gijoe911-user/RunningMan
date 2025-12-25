//
//  AuthService.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Service d'authentification Firebase
/// Gère la création de compte, connexion, déconnexion et synchronisation avec Firestore
class AuthService {
    
    static let shared = AuthService()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {
        Logger.log("AuthService initialisé", category: .auth)
    }
    
    /// Utilisateur actuellement connecté (Firebase Auth)
    var currentUser: User? {
        auth.currentUser
    }
    
    /// ID de l'utilisateur connecté
    var currentUserId: String? {
        currentUser?.uid
    }
    
    /// Vérifie si un utilisateur est connecté
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    // MARK: - Sign Up
    
    /// Crée un nouveau compte utilisateur
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - password: Mot de passe (min 6 caractères)
    ///   - displayName: Nom d'affichage
    /// - Returns: UserModel créé dans Firestore
    func signUp(
        email: String,
        password: String,
        displayName: String
    ) async throws -> UserModel {
        
        // Nettoyer les entrées
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Logger.log("Tentative de création de compte pour: '\(cleanEmail)'", category: .auth)
        Logger.log("DisplayName: '\(cleanDisplayName)', Email length: \(cleanEmail.count), Password length: \(password.count)", category: .auth)
        
        // 1. Créer l'utilisateur dans Firebase Auth
        let authResult = try await auth.createUser(withEmail: cleanEmail, password: password)
        let uid = authResult.user.uid
        
        Logger.logSuccess("Compte Firebase créé: \(uid)", category: .auth)
        
        // 2. Créer le profil utilisateur dans Firestore
        let newUser = UserModel(
            id: uid,
            displayName: cleanDisplayName,
            email: cleanEmail,
            createdAt: Date(),
            squadIds: [],
            preferences: UserPreferences()
        )
        
        try await createUserProfile(newUser)
        
        Logger.logSuccess("Profil utilisateur créé dans Firestore", category: .auth)
        
        return newUser
    }
    
    // MARK: - Sign In
    
    /// Connecte un utilisateur existant
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - password: Mot de passe
    /// - Returns: UserModel depuis Firestore
    func signIn(email: String, password: String) async throws -> UserModel {
        
        // Nettoyer l'email (supprimer les espaces blancs)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Logger.log("Tentative de connexion pour: '\(cleanEmail)'", category: .auth)
        Logger.log("Email length: \(cleanEmail.count), Password length: \(password.count)", category: .auth)
        
        // Log chaque caractère de l'email pour détecter les caractères invisibles
        Logger.log("Email caractères: \(cleanEmail.map { "\($0)" }.joined(separator: ","))", category: .auth)
        
        // Log des codes ASCII/Unicode
        let asciiCodes = cleanEmail.unicodeScalars.map { String($0.value) }.joined(separator: ",")
        Logger.log("Email codes Unicode: \(asciiCodes)", category: .auth)
        
        // 1. Connexion Firebase Auth
        do {
            let authResult = try await auth.signIn(withEmail: cleanEmail, password: password)
            let uid = authResult.user.uid
            
            Logger.logSuccess("Connexion Firebase réussie: \(uid)", category: .auth)
            
            // 2. Récupérer le profil utilisateur depuis Firestore
            if let userModel = try await getUserProfile(userId: uid) {
                Logger.logSuccess("Profil utilisateur récupéré", category: .auth)
                return userModel
            } else {
                // Le profil n'existe pas, créons-le automatiquement
                Logger.logWarning("Profil Firestore manquant, création automatique...", category: .auth)
                
                let newUser = UserModel(
                    id: uid,
                    displayName: authResult.user.displayName ?? cleanEmail.components(separatedBy: "@").first ?? "Utilisateur",
                    email: cleanEmail,
                    createdAt: Date(),
                    squadIds: [],
                    preferences: UserPreferences()
                )
                
                try await createUserProfile(newUser)
                Logger.logSuccess("Profil Firestore créé automatiquement", category: .auth)
                
                return newUser
            }
        } catch {
            Logger.logError(error, context: "signIn", category: .auth)
            Logger.log("Firebase error code: \((error as NSError).code)", category: .auth)
            Logger.log("Firebase error domain: \((error as NSError).domain)", category: .auth)
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    /// Déconnecte l'utilisateur actuel
    func signOut() throws {
        try auth.signOut()
        Logger.logSuccess("Utilisateur déconnecté", category: .auth)
    }
    
    // MARK: - Firestore Operations
    
    /// Crée le profil utilisateur dans Firestore
    private func createUserProfile(_ user: UserModel) async throws {
        guard let userId = user.id else {
            throw AuthError.invalidUserId
        }
        
        let userRef = db.collection("users").document(userId)
        try userRef.setData(from: user)
    }
    
    /// Récupère le profil utilisateur depuis Firestore
    func getUserProfile(userId: String) async throws -> UserModel? {
        let userRef = db.collection("users").document(userId)
        let document = try await userRef.getDocument()
        
        guard document.exists else {
            return nil
        }
        
        return try document.data(as: UserModel.self)
    }
    
    /// Met à jour le profil utilisateur dans Firestore
    func updateUserProfile(_ user: UserModel) async throws {
        guard let userId = user.id else {
            throw AuthError.invalidUserId
        }
        
        let userRef = db.collection("users").document(userId)
        try userRef.setData(from: user, merge: true)
        
        Logger.logSuccess("Profil utilisateur mis à jour", category: .auth)
    }
    
    // MARK: - Password Reset
    
    /// Envoie un email de réinitialisation de mot de passe
    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
        Logger.logSuccess("Email de réinitialisation envoyé à: \(email)", category: .auth)
    }
    
    // MARK: - Update Display Name
    
    /// Met à jour le nom d'affichage de l'utilisateur
    func updateDisplayName(_ newName: String) async throws {
        guard let user = currentUser else {
            throw AuthError.userNotAuthenticated
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        try await changeRequest.commitChanges()
        
        Logger.logSuccess("Nom d'affichage mis à jour: \(newName)", category: .auth)
    }
    
    // MARK: - Delete Account
    
    /// Supprime le compte utilisateur (Auth + Firestore)
    func deleteAccount() async throws {
        guard let user = currentUser, let userId = user.uid as String? else {
            throw AuthError.userNotAuthenticated
        }
        
        // 1. Supprimer le document Firestore
        try await db.collection("users").document(userId).delete()
        
        // 2. Supprimer l'utilisateur Firebase Auth
        try await user.delete()
        
        Logger.logSuccess("Compte supprimé: \(userId)", category: .auth)
    }
}

// MARK: - AuthError

/// Erreurs personnalisées pour l'authentification
enum AuthError: LocalizedError {
    case userNotAuthenticated
    case userProfileNotFound
    case invalidUserId
    case invalidEmail
    case weakPassword
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "Aucun utilisateur connecté"
        case .userProfileNotFound:
            return "Profil utilisateur introuvable dans la base de données"
        case .invalidUserId:
            return "ID utilisateur invalide"
        case .invalidEmail:
            return "Adresse email invalide"
        case .weakPassword:
            return "Le mot de passe doit contenir au moins 6 caractères"
        }
    }
}
