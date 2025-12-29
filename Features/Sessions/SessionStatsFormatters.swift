//
//  SessionStatsFormatters.swift
//  RunningMan
//
//  Formatters pour les statistiques de session
//

import Foundation

/// Utilitaires de formatage pour les statistiques de course
///
/// Centralise toutes les logiques de formatage pour :
/// - Temps écoulé (HH:MM:SS)
/// - Distance (mètres → km)
/// - Fréquence cardiaque (BPM)
/// - Calories (kcal)
///
/// **Avantages :**
/// - Code réutilisable
/// - Tests unitaires faciles
/// - Séparation des responsabilités
///
/// - SeeAlso: `SessionStatsWidget`, `SessionModel`
enum SessionStatsFormatters {
    
    // MARK: - Constants
    
    /// Seuil pour passer de mètres à kilomètres
    private static let metersToKilometersThreshold: Double = 1000
    
    /// Placeholder pour valeurs indisponibles
    private static let unavailablePlaceholder = "--"
    
    // MARK: - Time Formatting
    
    /// Formate une durée en temps écoulé
    ///
    /// Format de sortie :
    /// - Si < 1h : "MM:SS" (ex: "05:30")
    /// - Si ≥ 1h : "H:MM:SS" (ex: "1:05:30")
    ///
    /// - Parameter interval: Durée en secondes
    /// - Returns: Temps formaté
    static func formatTimeElapsed(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Distance Formatting
    
    /// Formate une distance en mètres ou kilomètres
    ///
    /// Format de sortie :
    /// - Si < 1000m : "X m" (ex: "340 m")
    /// - Si ≥ 1000m : "X.XX km" (ex: "2.34 km")
    ///
    /// - Parameter meters: Distance en mètres
    /// - Returns: Distance formatée avec unité
    static func formatDistance(_ meters: Double) -> String {
        if meters < metersToKilometersThreshold {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.2f km", meters / metersToKilometersThreshold)
        }
    }
    
    // MARK: - Heart Rate Formatting
    
    /// Formate une fréquence cardiaque
    ///
    /// Format de sortie :
    /// - Si disponible : "XXX" (ex: "145")
    /// - Si indisponible : "--"
    ///
    /// - Parameter bpm: Fréquence cardiaque en BPM, `nil` si indisponible
    /// - Returns: BPM formaté ou placeholder
    static func formatHeartRate(_ bpm: Double?) -> String {
        guard let bpm = bpm else {
            return unavailablePlaceholder
        }
        return "\(Int(bpm))"
    }
    
    // MARK: - Calories Formatting
    
    /// Formate des calories brûlées
    ///
    /// Format de sortie :
    /// - Si disponible : "XXX" (ex: "187")
    /// - Si indisponible : "--"
    ///
    /// - Parameter calories: Calories brûlées, `nil` si indisponible
    /// - Returns: Calories formatées ou placeholder
    static func formatCalories(_ calories: Double?) -> String {
        guard let calories = calories else {
            return unavailablePlaceholder
        }
        return "\(Int(calories))"
    }
    
    // MARK: - Pace Formatting (Future)
    
    /// Formate l'allure (min/km)
    ///
    /// - Note: ⚠️ Non implémenté - Prévu Phase 2
    /// - Parameter secondsPerKilometer: Allure en secondes par kilomètre
    /// - Returns: Allure formatée (ex: "5:30 /km")
    static func formatPace(_ secondsPerKilometer: Double?) -> String {
        guard let pace = secondsPerKilometer, pace > 0 else {
            return unavailablePlaceholder
        }
        
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    // MARK: - Speed Formatting (Future)
    
    /// Formate la vitesse (km/h)
    ///
    /// - Note: ⚠️ Non implémenté - Prévu Phase 2
    /// - Parameter metersPerSecond: Vitesse en mètres par seconde
    /// - Returns: Vitesse formatée (ex: "12.5 km/h")
    static func formatSpeed(_ metersPerSecond: Double?) -> String {
        guard let speed = metersPerSecond, speed > 0 else {
            return unavailablePlaceholder
        }
        
        let kmPerHour = speed * 3.6
        return String(format: "%.1f km/h", kmPerHour)
    }
}
