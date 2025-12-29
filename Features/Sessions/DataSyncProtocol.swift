//
//  DataSyncProtocol.swift
//  RunningMan
//
//  Protocole pour la synchronisation avec des services tiers
//

import Foundation

/// Protocole générique pour tous les services de synchronisation de données
/// Permet d'ajouter Strava, Garmin, etc. sans modifier les ViewModels
protocol DataSyncProtocol {
    
    /// Nom du service (ex: "Strava", "Garmin")
    var serviceName: String { get }
    
    /// Indique si l'utilisateur est connecté au service
    var isAuthenticated: Bool { get }
    
    /// Authentifie l'utilisateur auprès du service
    /// - Returns: `true` si l'authentification réussit
    func authenticate() async throws -> Bool
    
    /// Déconnecte l'utilisateur du service
    func disconnect() async throws
    
    /// Synchronise une activité/session vers le service
    /// - Parameters:
    ///   - sessionId: Identifiant de la session à synchroniser
    ///   - metadata: Métadonnées optionnelles spécifiques au service
    /// - Returns: Identifiant de l'activité créée sur le service distant
    func syncActivity(sessionId: String, metadata: [String: Any]?) async throws -> String
    
    /// Récupère les activités depuis le service distant
    /// - Parameter since: Date à partir de laquelle récupérer les activités
    /// - Returns: Liste des activités récupérées
    func fetchActivities(since: Date) async throws -> [RemoteActivity]
}

// MARK: - Supporting Types

/// Représente une activité provenant d'un service distant
struct RemoteActivity: Identifiable {
    let id: String
    let serviceName: String
    let title: String
    let distance: Double // en mètres
    let duration: TimeInterval // en secondes
    let startDate: Date
    let activityType: String
    let externalUrl: URL?
}

// MARK: - Default Implementation

extension DataSyncProtocol {
    
    /// Synchronisation avec métadonnées par défaut
    func syncActivity(sessionId: String) async throws -> String {
        try await syncActivity(sessionId: sessionId, metadata: nil)
    }
}
