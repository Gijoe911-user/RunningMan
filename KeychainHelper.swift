//
//  KeychainHelper.swift
//  RunningMan
//
//  Helper pour gérer la sauvegarde manuelle des identifiants dans le Keychain
//  Note: iOS gère automatiquement l'AutoFill, mais ce helper peut être utile
//  pour sauvegarder d'autres données sensibles ou forcer la sauvegarde
//

import Foundation
import Security

/// Helper pour gérer les identifiants dans le Keychain
///
/// Utilisation:
/// ```swift
/// // Sauvegarder
/// KeychainHelper.shared.save(email: "user@example.com", password: "secret")
///
/// // Récupérer
/// if let credentials = KeychainHelper.shared.retrieve() {
///     print("Email: \(credentials.email)")
/// }
///
/// // Supprimer
/// KeychainHelper.shared.delete()
/// ```
final class KeychainHelper {
    
    static let shared = KeychainHelper()
    
    private let service = "com.runningman.credentials"
    private let emailKey = "userEmail"
    private let passwordKey = "userPassword"
    
    private init() {}
    
    // MARK: - Save Credentials
    
    /// Sauvegarde les identifiants dans le Keychain
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - password: Mot de passe (sera chiffré automatiquement)
    /// - Returns: True si la sauvegarde a réussi
    @discardableResult
    func save(email: String, password: String) -> Bool {
        Logger.log("💾 Sauvegarde des identifiants dans le Keychain", category: .auth)
        
        // Supprimer d'abord les anciennes valeurs si elles existent
        delete()
        
        // Sauvegarder l'email
        guard saveItem(key: emailKey, value: email) else {
            Logger.log("❌ Échec sauvegarde email", category: .auth)
            return false
        }
        
        // Sauvegarder le mot de passe
        guard saveItem(key: passwordKey, value: password) else {
            Logger.log("❌ Échec sauvegarde mot de passe", category: .auth)
            return false
        }
        
        Logger.log("✅ Identifiants sauvegardés avec succès", category: .auth)
        return true
    }
    
    // MARK: - Retrieve Credentials
    
    /// Récupère les identifiants depuis le Keychain
    /// - Returns: Tuple contenant email et password, ou nil si non trouvé
    func retrieve() -> (email: String, password: String)? {
        Logger.log("🔍 Récupération des identifiants depuis le Keychain", category: .auth)
        
        guard let email = retrieveItem(key: emailKey),
              let password = retrieveItem(key: passwordKey) else {
            Logger.log("⚠️ Aucun identifiant trouvé dans le Keychain", category: .auth)
            return nil
        }
        
        Logger.log("✅ Identifiants récupérés avec succès", category: .auth)
        return (email: email, password: password)
    }
    
    // MARK: - Delete Credentials
    
    /// Supprime les identifiants du Keychain (lors de la déconnexion)
    @discardableResult
    func delete() -> Bool {
        Logger.log("🗑️ Suppression des identifiants du Keychain", category: .auth)
        
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: emailKey
        ]
        
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: passwordKey
        ]
        
        SecItemDelete(emailQuery as CFDictionary)
        SecItemDelete(passwordQuery as CFDictionary)
        
        Logger.log("✅ Identifiants supprimés", category: .auth)
        return true
    }
    
    // MARK: - Check if Credentials Exist
    
    /// Vérifie si des identifiants existent dans le Keychain
    /// - Returns: True si des identifiants sont sauvegardés
    func hasCredentials() -> Bool {
        return retrieve() != nil
    }
    
    // MARK: - Private Helpers
    
    private func saveItem(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // L'élément existe déjà, le mettre à jour
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            return SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary) == errSecSuccess
        }
        
        return status == errSecSuccess
    }
    
    private func retrieveItem(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
}

// MARK: - Usage Examples
/*
 ═══════════════════════════════════════════════════════════════════════════
 EXEMPLES D'UTILISATION :
 ═══════════════════════════════════════════════════════════════════════════
 
 // 1. Sauvegarder après connexion réussie
 if await authViewModel.signIn(email: email, password: password) {
     KeychainHelper.shared.save(email: email, password: password)
 }
 
 // 2. Récupérer au lancement de l'app
 if let credentials = KeychainHelper.shared.retrieve() {
     self.email = credentials.email
     // Note: Ne pré-remplissez PAS le mot de passe pour des raisons de sécurité
     // Laissez l'utilisateur utiliser AutoFill ou Touch ID/Face ID
 }
 
 // 3. Supprimer à la déconnexion
 func signOut() {
     KeychainHelper.shared.delete()
     // ... reste de la logique de déconnexion
 }
 
 // 4. Vérifier si des identifiants existent
 if KeychainHelper.shared.hasCredentials() {
     showQuickLogin = true
 }
 
 ═══════════════════════════════════════════════════════════════════════════
 
 ⚠️ IMPORTANT - Bonnes pratiques :
 
 1. N'utilisez ce helper QUE pour :
    - Sauvegarder l'email pour pré-remplissage
    - Stocker des tokens d'authentification
    - Gérer des données sensibles additionnelles
 
 2. NE l'utilisez PAS pour :
    - Remplacer AutoFill (iOS le fait mieux)
    - Pré-remplir automatiquement les mots de passe
    - Contourner l'authentification biométrique
 
 3. Préférez toujours :
    - L'AutoFill natif d'iOS
    - Face ID / Touch ID avec LocalAuthentication
    - Les tokens de session plutôt que les mots de passe
 
 ═══════════════════════════════════════════════════════════════════════════
*/

// MARK: - Credentials Model

/// Modèle pour représenter les identifiants
struct Credentials {
    let email: String
    let password: String
    
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

extension KeychainHelper {
    
    /// Variante qui retourne un modèle Credentials
    func retrieveCredentials() -> Credentials? {
        guard let (email, password) = retrieve() else {
            return nil
        }
        return Credentials(email: email, password: password)
    }
}
