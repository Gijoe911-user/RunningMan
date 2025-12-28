//
//  LocationService.swift
//  RunningMan
//
//  Created on 27/12/2025.
//

import Foundation
import UIKit
import CoreLocation
import FirebaseFirestore
import Combine

/// Service de gestion de la localisation GPS
/// Gère le tracking GPS, l'envoi vers Firestore et l'observation des positions des autres coureurs
@MainActor
class LocationService: NSObject, ObservableObject {
    
    static let shared = LocationService()
    
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    
    // Utiliser une computed property pour garantir que Firebase est configuré
    private var db: Firestore {
        Firestore.firestore()
    }
    
    /// Position actuelle de l'utilisateur
    @Published var currentLocation: CLLocation?
    
    /// Statut de l'autorisation de localisation
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Indique si le tracking est actif
    @Published var isTracking = false
    
    /// Erreur de localisation
    @Published var locationError: Error?
    
    /// ID de la session active (nil si pas de session)
    private var activeSessionId: String?
    
    /// ID de l'utilisateur actuel
    private var currentUserId: String?
    
    /// Service d'historique des parcours
    private let routeHistoryService = RouteHistoryService.shared
    
    /// Tâche en arrière-plan
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    /// Listener Firestore pour les positions des autres coureurs
    private var locationListener: ListenerRegistration?
    
    /// Positions des autres coureurs
    @Published var runnerLocations: [String: LocationPoint] = [:]
    
    /// Statistiques de tracking
    @Published var trackingStats: TrackingStats = TrackingStats()
    
    /// Dernière position enregistrée (pour calculer la distance)
    private var lastLocation: CLLocation?
    
    /// Timer pour les mises à jour périodiques
    private var updateTimer: Timer?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Mettre à jour tous les 5 mètres
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .fitness
        
        authorizationStatus = locationManager.authorizationStatus
        
        Logger.log("LocationService initialisé", category: .location)
    }
    
    // MARK: - Authorization
    
    /// Demande l'autorisation de localisation
    func requestAuthorization() {
        Logger.log("Demande d'autorisation de localisation", category: .location)
        locationManager.requestWhenInUseAuthorization()
        
        // Pour le tracking en arrière-plan, demander "Always" après "WhenInUse"
        // locationManager.requestAlwaysAuthorization()
    }
    
    /// Vérifie si l'autorisation est accordée
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Start Tracking
    
    /// Démarre le tracking GPS pour une session
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
    func startTracking(sessionId: String, userId: String) {
        guard isAuthorized else {
            Logger.log("⚠️ Autorisation de localisation non accordée", category: .location)
            requestAuthorization()
            return
        }
        
        Logger.log("🚀 Démarrage du tracking pour session: \(sessionId)", category: .location)
        
        self.activeSessionId = sessionId
        self.currentUserId = userId
        self.isTracking = true
        
        // Réinitialiser les stats
        trackingStats = TrackingStats()
        lastLocation = nil
        
        // Démarrer les mises à jour de localisation
        locationManager.startUpdatingLocation()
        
        // Démarrer l'observation des autres coureurs
        startObservingRunnerLocations(sessionId: sessionId)
        
        // Démarrer le timer pour les mises à jour périodiques des stats
        startUpdateTimer()
        
        Logger.logSuccess("Tracking démarré", category: .location)
    }
    
    // MARK: - Stop Tracking
    
    /// Arrête le tracking GPS
    func stopTracking() {
        Logger.log("🛑 Arrêt du tracking", category: .location)
        
        // Terminer le parcours dans Firestore
        if let sessionId = activeSessionId, let userId = currentUserId {
            Task {
                do {
                    try await routeHistoryService.endUserRoute(
                        sessionId: sessionId,
                        userId: userId
                    )
                } catch {
                    Logger.logError(error, context: "endUserRoute", category: .location)
                }
            }
        }
        
        locationManager.stopUpdatingLocation()
        
        // Arrêter l'observation des autres coureurs
        stopObservingRunnerLocations()
        
        // Arrêter le timer
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Terminer la tâche en arrière-plan si active
        endBackgroundTask()
        
        self.isTracking = false
        self.activeSessionId = nil
        self.currentUserId = nil
        self.runnerLocations.removeAll()
        
        Logger.logSuccess("Tracking arrêté", category: .location)
    }
    
    // MARK: - Location Updates
    
    /// Envoie la position actuelle vers Firestore via RealtimeLocationRepository
    private func sendLocationToFirestore(location: CLLocation) {
        guard let sessionId = activeSessionId,
              let userId = currentUserId else {
            return
        }
        
        Task {
            do {
                // 1. Publier la position actuelle (pour la carte en temps réel)
                let repository = RealtimeLocationRepository()
                try await repository.publishLocation(
                    sessionId: sessionId,
                    userId: userId,
                    coordinate: location.coordinate
                )
                
                // 2. Enregistrer dans l'historique du parcours
                try await routeHistoryService.saveRoutePoint(
                    sessionId: sessionId,
                    userId: userId,
                    location: location
                )
                
                // Logger.log("📍 Position envoyée et enregistrée dans l'historique", category: .location)
            } catch {
                Logger.logError(error, context: "sendLocationToFirestore", category: .location)
            }
        }
    }
    
    /// Calcule et met à jour les statistiques de tracking
    private func updateTrackingStats(newLocation: CLLocation) {
        trackingStats.pointsCount += 1
        
        // Calculer la distance depuis la dernière position
        if let last = lastLocation {
            let distance = newLocation.distance(from: last)
            
            // Filtrer les distances aberrantes (> 100m en 5 secondes)
            if distance < 100 {
                trackingStats.totalDistance += distance
            }
        }
        
        // Mettre à jour la vitesse
        if newLocation.speed >= 0 {
            trackingStats.currentSpeed = newLocation.speed
            
            if newLocation.speed > trackingStats.maxSpeed {
                trackingStats.maxSpeed = newLocation.speed
            }
            
            // Calculer la vitesse moyenne
            if trackingStats.pointsCount > 0 {
                // Moyenne mobile
                trackingStats.averageSpeed = (trackingStats.averageSpeed * Double(trackingStats.pointsCount - 1) + newLocation.speed) / Double(trackingStats.pointsCount)
            }
        }
        
        lastLocation = newLocation
    }
    
    /// Met à jour les statistiques dans Firestore périodiquement
    private func updateStatsInFirestore() {
        guard let sessionId = activeSessionId,
              let userId = currentUserId else {
            return
        }
        
        Task {
            do {
                // 1. Mettre à jour les stats de participant (pour la session active)
                try await SessionService.shared.updateParticipantStats(
                    sessionId: sessionId,
                    userId: userId,
                    distance: trackingStats.totalDistance,
                    duration: trackingStats.duration,
                    averageSpeed: trackingStats.averageSpeed,
                    maxSpeed: trackingStats.maxSpeed
                )
                
                // 2. Mettre à jour le parcours (route) avec les stats complètes
                try await routeHistoryService.updateUserRoute(
                    sessionId: sessionId,
                    userId: userId,
                    distance: trackingStats.totalDistance,
                    duration: trackingStats.duration,
                    averageSpeed: trackingStats.averageSpeed,
                    maxSpeed: trackingStats.maxSpeed,
                    pointsCount: trackingStats.pointsCount
                )
                
            } catch {
                Logger.logError(error, context: "updateStatsInFirestore", category: .location)
            }
        }
    }
    
    // MARK: - Timer
    
    /// Démarre le timer pour les mises à jour périodiques
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Les timers s'exécutent sur le RunLoop, on doit explicitement aller sur le MainActor
            Task { @MainActor in
                self.updateStatsInFirestore()
                
                // Incrémenter la durée
                self.trackingStats.duration += 10
            }
        }
    }
    
    // MARK: - Observe Runner Locations
    
    /// Commence à observer les positions des autres coureurs
    private func startObservingRunnerLocations(sessionId: String) {
        Logger.log("👀 Observation des positions des coureurs pour session: \(sessionId)", category: .location)
        
        let locationsRef = db.collection("sessions")
            .document(sessionId)
            .collection("locations")
        
        locationListener = locationsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    Logger.logError(error, context: "observeRunnerLocations", category: .location)
                }
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            Task { @MainActor in
                for document in documents {
                    // Ne pas traiter sa propre position
                    if document.documentID == self.currentUserId {
                        continue
                    }
                    
                    if let location = try? document.data(as: LocationPoint.self) {
                        self.runnerLocations[document.documentID] = location
                    }
                }
                
                // Logger.log("📍 Positions mises à jour: \(self.runnerLocations.count) coureurs", category: .location)
            }
        }
    }
    
    /// Arrête l'observation des positions
    private func stopObservingRunnerLocations() {
        locationListener?.remove()
        locationListener = nil
        Logger.log("Observation des positions arrêtée", category: .location)
    }
    
    // MARK: - Helper Methods
    
    /// Calcule la distance entre deux coordonnées
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    // MARK: - Background Mode Support
    
    /// Démarre une tâche en arrière-plan pour continuer le tracking
    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    /// Termine la tâche en arrière-plan
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filtrer les positions avec une précision faible
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 50 else {
            Logger.log("⚠️ Position ignorée (précision: \(location.horizontalAccuracy)m)", category: .location)
            return
        }
        
        // Démarrer une tâche en arrière-plan si nécessaire
        if backgroundTask == .invalid {
            beginBackgroundTask()
        }
        
        // Mettre à jour la position actuelle
        currentLocation = location
        
        // Si tracking actif, envoyer vers Firestore et calculer stats
        if isTracking {
            sendLocationToFirestore(location: location)
            updateTrackingStats(newLocation: location)
        }
        
        // Terminer la tâche en arrière-plan
        endBackgroundTask()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.logError(error, context: "locationManager", category: .location)
        locationError = error
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        Logger.log("Statut d'autorisation changé: \(authorizationStatus.description)", category: .location)
        
        // Si autorisation refusée, arrêter le tracking
        if !isAuthorized && isTracking {
            stopTracking()
        }
    }
}

// MARK: - Tracking Stats

/// Statistiques de tracking GPS
struct TrackingStats {
    /// Distance totale parcourue (en mètres)
    var totalDistance: Double = 0
    
    /// Durée totale (en secondes)
    var duration: TimeInterval = 0
    
    /// Vitesse actuelle (en m/s)
    var currentSpeed: Double = 0
    
    /// Vitesse moyenne (en m/s)
    var averageSpeed: Double = 0
    
    /// Vitesse maximale (en m/s)
    var maxSpeed: Double = 0
    
    /// Nombre de points GPS enregistrés
    var pointsCount: Int = 0
    
    // MARK: - Computed Properties
    
    /// Distance en kilomètres
    var distanceInKm: Double {
        totalDistance / 1000.0
    }
    
    /// Vitesse actuelle en km/h
    var currentSpeedKmh: Double {
        currentSpeed * 3.6
    }
    
    /// Vitesse moyenne en km/h
    var averageSpeedKmh: Double {
        averageSpeed * 3.6
    }
    
    /// Allure actuelle (min/km)
    var currentPace: String {
        guard currentSpeed > 0 else { return "--:--" }
        
        let minutesPerKm = (1000.0 / currentSpeed) / 60.0
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Allure moyenne (min/km)
    var averagePace: String {
        guard averageSpeed > 0 else { return "--:--" }
        
        let minutesPerKm = (1000.0 / averageSpeed) / 60.0
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Durée formatée (HH:mm:ss)
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

// MARK: - CLAuthorizationStatus Extension

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Non déterminé"
        case .restricted:
            return "Restreint"
        case .denied:
            return "Refusé"
        case .authorizedWhenInUse:
            return "Autorisé en utilisation"
        case .authorizedAlways:
            return "Toujours autorisé"
        @unknown default:
            return "Inconnu"
        }
    }
}
