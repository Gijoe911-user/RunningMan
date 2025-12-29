//
//  StravaService.swift
//  RunningMan
//
//  Service pour l'intégration avec Strava
//  ⚠️ STUB - Implémentation à venir (Phase 2)
//

import Foundation

/// Service de synchronisation avec Strava
///
/// Ce service permet de :
/// - Authentifier l'utilisateur avec OAuth 2.0
/// - Envoyer des activités vers Strava
/// - Récupérer les activités Strava de l'utilisateur
///
/// - Note: Requiert une clé API Strava configurée dans Info.plist
/// - SeeAlso: `DataSyncProtocol`
final class StravaService: DataSyncProtocol {
    
    static let shared = StravaService()
    
    // MARK: - DataSyncProtocol Properties
    
    var serviceName: String {
        "Strava"
    }
    
    var isAuthenticated: Bool {
        // TODO: Vérifier le token d'accès dans le Keychain
        Logger.log("⚠️ StravaService.isAuthenticated - Non implémenté", category: .general)
        return false
    }
    
    // MARK: - Private Properties
    
    // TODO: Ajouter les clés API depuis Info.plist
    private let clientId: String = ""
    private let clientSecret: String = ""
    private var accessToken: String?
    
    private init() {
        Logger.log("StravaService initialisé (STUB)", category: .general)
    }
    
    // MARK: - DataSyncProtocol Methods
    
    /// Authentifie l'utilisateur avec Strava via OAuth 2.0
    /// - Returns: `true` si l'authentification réussit
    /// - Note: ⚠️ Non implémenté - Stub
    func authenticate() async throws -> Bool {
        Logger.log("⚠️ StravaService.authenticate() appelé - Fonctionnalité non implémentée", category: .general)
        
        // TODO: Phase 2
        // 1. Ouvrir le navigateur pour l'OAuth Strava
        // 2. Récupérer le code d'autorisation
        // 3. Échanger le code contre un access token
        // 4. Sauvegarder le token dans le Keychain
        
        throw StravaError.notImplemented
    }
    
    /// Déconnecte l'utilisateur de Strava
    /// - Note: ⚠️ Non implémenté - Stub
    func disconnect() async throws {
        Logger.log("⚠️ StravaService.disconnect() appelé - Fonctionnalité non implémentée", category: .general)
        
        // TODO: Phase 2
        // 1. Révoquer le token d'accès
        // 2. Supprimer les données du Keychain
        
        throw StravaError.notImplemented
    }
    
    /// Synchronise une session RunningMan vers Strava
    /// - Parameters:
    ///   - sessionId: ID de la session à synchroniser
    ///   - metadata: Métadonnées optionnelles (titre, description, etc.)
    /// - Returns: ID de l'activité créée sur Strava
    /// - Note: ⚠️ Non implémenté - Stub
    func syncActivity(sessionId: String, metadata: [String: Any]?) async throws -> String {
        Logger.log("⚠️ StravaService.syncActivity() appelé pour session: \(sessionId) - Fonctionnalité non implémentée", category: .general)
        
        // TODO: Phase 2
        // 1. Récupérer les données de la session depuis Firebase
        // 2. Convertir au format Strava (GPX ou JSON)
        // 3. Envoyer via l'API Strava /activities
        // 4. Retourner l'ID de l'activité créée
        
        throw StravaError.notImplemented
    }
    
    /// Récupère les activités Strava de l'utilisateur
    /// - Parameter since: Date de début pour la récupération
    /// - Returns: Liste des activités Strava
    /// - Note: ⚠️ Non implémenté - Stub
    func fetchActivities(since: Date) async throws -> [RemoteActivity] {
        Logger.log("⚠️ StravaService.fetchActivities() appelé - Fonctionnalité non implémentée", category: .general)
        
        // TODO: Phase 2
        // 1. Appeler l'API Strava /athlete/activities
        // 2. Parser les activités
        // 3. Convertir en RemoteActivity
        
        throw StravaError.notImplemented
    }
}

// MARK: - Strava Errors

enum StravaError: LocalizedError {
    case notImplemented
    case authenticationFailed
    case invalidToken
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Fonctionnalité Strava non encore implémentée"
        case .authenticationFailed:
            return "Échec de l'authentification Strava"
        case .invalidToken:
            return "Token Strava invalide ou expiré"
        case .apiError(let message):
            return "Erreur API Strava: \(message)"
        }
    }
}
