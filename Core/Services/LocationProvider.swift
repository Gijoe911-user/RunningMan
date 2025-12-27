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
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isUpdating: Bool = false
    
    // Config
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var distanceFilter: CLLocationDistance = 10 // mètres
    
    // Internes
    private let manager = CLLocationManager()
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = desiredAccuracy
        manager.distanceFilter = distanceFilter
        // Ne pas forcer allowsBackgroundLocationUpdates ici pour éviter les crashs
        // L’activation se fera côté projet (Capabilities + Info.plist) puis ici si besoin.
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
            currentCoordinate = last.coordinate
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // On logge simplement; pas d’UI ici
        Logger.logError(error, context: "LocationProvider.didFailWithError", category: .location)
    }
}

