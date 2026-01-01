//
//  FeatureFlags.swift
//  RunningMan
//
//  Système de contrôle des fonctionnalités en développement
//

import Foundation

/// Contrôle l'activation/désactivation des fonctionnalités en développement
enum FeatureFlags {
    
    // MARK: - Communication Features
    
    /// Push-to-Talk pour communiquer pendant les courses
    static let voiceChat = false
    
    /// Système de messages texte dans les sessions
    static let textMessaging = false
    
    /// Partage de photos pendant la course
    static let photoSharing = false
    
    // MARK: - Integration Features
    
    /// Synchronisation avec Strava
    static let stravaIntegration = false
    
    /// Synchronisation avec Garmin
    static let garminIntegration = false
    
    /// Intégration Apple Watch
    static let appleWatchSync = false
    
    // MARK: - Health Features
    
    /// Monitoring cardiaque via HealthKit
    static let heartRateMonitoring = true
    
    /// Calcul des calories brûlées
    static let calorieTracking = true
    
    /// Analyse de la cadence de course
    static let cadenceAnalysis = false
    
    // MARK: - Advanced Features
    
    /// Notifications live des membres de la squad
    static let liveNotifications = false
    
    /// Partage en temps réel sur les réseaux sociaux
    static let socialSharing = false
    
    /// Analyse post-course avec IA
    static let aiCoaching = false
    
    // MARK: - Helper Methods
    
    /// Retourne toutes les fonctionnalités et leur état
    static var allFeatures: [(name: String, enabled: Bool)] {
        return [
            ("Voice Chat", voiceChat),
            ("Text Messaging", textMessaging),
            ("Photo Sharing", photoSharing),
            ("Strava Integration", stravaIntegration),
            ("Garmin Integration", garminIntegration),
            ("Apple Watch Sync", appleWatchSync),
            ("Heart Rate Monitoring", heartRateMonitoring),
            ("Calorie Tracking", calorieTracking),
            ("Cadence Analysis", cadenceAnalysis),
            ("Live Notifications", liveNotifications),
            ("Social Sharing", socialSharing),
            ("AI Coaching", aiCoaching)
        ]
    }
    
    /// Compte le nombre de fonctionnalités actives
    static var activeCount: Int {
        allFeatures.filter(\.enabled).count
    }
}
