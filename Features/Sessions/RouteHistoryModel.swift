//
//  RouteHistoryModel.swift
//  RunningMan
//
//  Modèle pour l'historique des parcours GPS
//

import Foundation
import FirebaseFirestore
import CoreLocation

// MARK: - Route Point

/// Un point GPS dans l'historique du parcours
struct RoutePoint: Codable, Identifiable {
    var id: String { "\(timestamp.timeIntervalSince1970)" }
    
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var speed: Double?
    var horizontalAccuracy: Double
    var timestamp: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }
}

// MARK: - User Route

/// Parcours complet d'un utilisateur dans une session
struct UserRoute: Codable, Identifiable {
    @DocumentID var id: String?
    
    var sessionId: String
    var userId: String
    var startedAt: Date
    var endedAt: Date?
    
    /// Distance totale du parcours (en mètres)
    var totalDistance: Double = 0
    
    /// Durée totale (en secondes)
    var duration: TimeInterval = 0
    
    /// Nombre de points enregistrés
    var pointsCount: Int = 0
    
    /// Vitesse moyenne (m/s)
    var averageSpeed: Double = 0
    
    /// Vitesse maximale (m/s)
    var maxSpeed: Double = 0
    
    /// Métadonnées
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // MARK: - Computed Properties
    
    /// Distance en kilomètres
    var distanceInKm: Double {
        totalDistance / 1000.0
    }
    
    /// Vitesse moyenne en km/h
    var averageSpeedKmh: Double {
        averageSpeed * 3.6
    }
    
    /// Allure moyenne (min/km)
    var averagePace: String {
        guard averageSpeed > 0 else { return "--:--" }
        let minutesPerKm = (1000.0 / averageSpeed) / 60.0
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Durée formatée
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Route Summary

/// Résumé d'un parcours pour l'affichage dans une liste
struct RouteSummary: Identifiable {
    let id: String
    let sessionId: String
    let userId: String
    let date: Date
    let distance: Double
    let duration: TimeInterval
    let averagePace: String
    let pointsCount: Int
    
    init(from route: UserRoute) {
        self.id = route.id ?? UUID().uuidString
        self.sessionId = route.sessionId
        self.userId = route.userId
        self.date = route.startedAt
        self.distance = route.totalDistance
        self.duration = route.duration
        self.averagePace = route.averagePace
        self.pointsCount = route.pointsCount
    }
}
