//
//  LocationProvider.swift
//  RunningMan
//
//  Encapsule CLLocationManager et expose la localisation courante en toute sécurité
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationProvider: NSObject, ObservableObject {
    
    static let shared = LocationProvider()
    
    // Sorties observables
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?
    @Published private(set) var currentSpeed: Double = 0.0  // m/s
    @Published private(set) var currentAltitude: Double = 0.0  // mètres
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isUpdating: Bool = false
    
    // Config
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest {
        didSet {
            manager.desiredAccuracy = desiredAccuracy
            Logger.log("🎯 Précision GPS mise à jour: \(desiredAccuracy)", category: .location)
        }
    }
    
    var distanceFilter: CLLocationDistance = 5 {  // 🎯 Optimisé à 5m pour un tracking plus réactif
        didSet {
            manager.distanceFilter = distanceFilter
            Logger.log("📏 Filtre de distance mis à jour: \(distanceFilter)m", category: .location)
        }
    }
    
    // Internes
    private let manager = CLLocationManager()
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = desiredAccuracy
        manager.distanceFilter = distanceFilter
        // Ne pas forcer allowsBackgroundLocationUpdates ici pour éviter les crashs
        // L'activation se fera côté projet (Capabilities + Info.plist) puis ici si besoin.
        manager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - API
    
    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }
    
    func startUpdating() {
        // Si permissions pas encore accordées, demander WhenInUse par défaut
        if authorizationStatus == .notDetermined {
            requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
        isUpdating = true
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
        isUpdating = false
    }
    
    func requestOneShotLocation() {
        manager.requestLocation()
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            authorizationStatus = status
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in
            Logger.log("[AUDIT-LIVE-07] 🛰️ CLLocationManager didUpdateLocations → lat: \(last.coordinate.latitude), lon: \(last.coordinate.longitude), accuracy: \(last.horizontalAccuracy)m", category: .location)
            
            // 🎯 FILTRE CRITIQUE : Rejeter les points GPS de mauvaise précision
            // Si précision > 50m, on ignore le point pour éviter les erreurs de triangulation MapKit
            guard last.horizontalAccuracy <= 50 else {
                Logger.log("⚠️ Point GPS rejeté (précision insuffisante: \(last.horizontalAccuracy)m)", category: .location)
                return
            }
            
            currentCoordinate = last.coordinate
            
            // Vitesse (m/s) - CLLocation fournit déjà la vitesse
            // Si négative, c'est invalide → on met 0
            currentSpeed = max(0, last.speed)
            
            // Altitude
            currentAltitude = last.altitude
            
            Logger.log("[AUDIT-LIVE-08] 📡 currentCoordinate publié → lat: \(last.coordinate.latitude), lon: \(last.coordinate.longitude)", category: .location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // On logge simplement; pas d'UI ici
        Task { @MainActor in
            Logger.logError(error, context: "LocationProvider.didFailWithError", category: .location)
        }
    }
}
