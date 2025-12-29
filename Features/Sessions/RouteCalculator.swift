//
//  RouteCalculator.swift
//  RunningMan
//
//  Utilitaires pour les calculs de tracés GPS
//

import Foundation
import CoreLocation

/// Utilitaires de calcul pour les tracés GPS
///
/// Fonctions pures pour :
/// - Calculer la distance totale d'un tracé
/// - Calculer la vitesse moyenne
/// - Calculer l'allure
///
/// **Avantages :**
/// - Code réutilisable
/// - Tests unitaires faciles
/// - Pas d'état, pas de side effects
///
/// - SeeAlso: `SessionStatsFormatters`
enum RouteCalculator {
    
    // MARK: - Distance Calculation
    
    /// Calcule la distance totale d'un tracé GPS
    ///
    /// Utilise la formule de distance entre deux points GPS
    /// (méthode CoreLocation `distance(from:)`).
    ///
    /// - Parameter coordinates: Liste des coordonnées GPS du tracé
    /// - Returns: Distance totale en mètres
    ///
    /// **Exemple :**
    /// ```swift
    /// let distance = RouteCalculator.calculateTotalDistance(coordinates)
    /// // distance = 2340.5 (en mètres)
    /// ```
    static func calculateTotalDistance(from coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count >= 2 else { return 0 }
        
        var totalDistance: Double = 0
        
        for i in 1..<coordinates.count {
            let loc1 = CLLocation(
                latitude: coordinates[i-1].latitude,
                longitude: coordinates[i-1].longitude
            )
            let loc2 = CLLocation(
                latitude: coordinates[i].latitude,
                longitude: coordinates[i].longitude
            )
            totalDistance += loc1.distance(from: loc2)
        }
        
        return totalDistance
    }
    
    // MARK: - Speed Calculation
    
    /// Calcule la vitesse moyenne d'un tracé
    ///
    /// - Parameters:
    ///   - distance: Distance totale en mètres
    ///   - duration: Durée totale en secondes
    /// - Returns: Vitesse moyenne en mètres par seconde, `nil` si durée nulle
    ///
    /// **Exemple :**
    /// ```swift
    /// let speed = RouteCalculator.calculateAverageSpeed(
    ///     distance: 2000,  // 2 km
    ///     duration: 600    // 10 minutes
    /// )
    /// // speed = 3.33 m/s (soit ~12 km/h)
    /// ```
    static func calculateAverageSpeed(distance: Double, duration: TimeInterval) -> Double? {
        guard duration > 0 else { return nil }
        return distance / duration
    }
    
    // MARK: - Pace Calculation
    
    /// Calcule l'allure (min/km)
    ///
    /// - Parameters:
    ///   - distance: Distance totale en mètres
    ///   - duration: Durée totale en secondes
    /// - Returns: Allure en secondes par kilomètre, `nil` si distance nulle
    ///
    /// **Exemple :**
    /// ```swift
    /// let pace = RouteCalculator.calculatePace(
    ///     distance: 5000,   // 5 km
    ///     duration: 1500    // 25 minutes
    /// )
    /// // pace = 300 secondes/km (soit 5:00 /km)
    /// ```
    static func calculatePace(distance: Double, duration: TimeInterval) -> Double? {
        guard distance > 0 else { return nil }
        let distanceInKm = distance / 1000
        return duration / distanceInKm
    }
    
    // MARK: - Elevation Calculation (Future)
    
    /// Calcule le dénivelé positif total
    ///
    /// - Note: ⚠️ Non implémenté - Prévu Phase 3
    /// - Parameter coordinates: Coordonnées avec altitude
    /// - Returns: Dénivelé positif en mètres
    static func calculateElevationGain(from coordinates: [CLLocation]) -> Double {
        // TODO: Phase 3 - Nécessite CLLocation avec altitude
        Logger.log("⚠️ RouteCalculator.calculateElevationGain() - Non implémenté", category: .location)
        return 0
    }
    
    // MARK: - Validation
    
    /// Vérifie si un tracé est valide
    ///
    /// Un tracé est considéré valide s'il contient :
    /// - Au moins 2 points
    /// - Une distance totale > 0
    ///
    /// - Parameter coordinates: Coordonnées du tracé
    /// - Returns: `true` si le tracé est valide
    static func isValidRoute(_ coordinates: [CLLocationCoordinate2D]) -> Bool {
        guard coordinates.count >= 2 else { return false }
        let distance = calculateTotalDistance(from: coordinates)
        return distance > 0
    }
}
