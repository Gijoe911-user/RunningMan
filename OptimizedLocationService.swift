//
//  OptimizedLocationService.swift
//  RunningMan
//
//  Service de localisation GPS OPTIMISÉ pour réduire les écritures Firestore
//
//  🎯 Objectifs :
//  - Réduire les écritures Firestore de 90%
//  - Envoyer les positions en batch toutes les 30 secondes
//  - Conserver la précision pour les statistiques locales
//  - Permettre un contrôle manuel du tracking (Start/Stop)
//

import Foundation
import UIKit
import CoreLocation
import FirebaseFirestore
import Combine

/// Configuration du tracking GPS optimisé
struct TrackingConfiguration {
    /// Fréquence de mise à jour GPS (en mètres)
    /// Plus petit = plus précis mais plus de calculs
    var gpsUpdateDistance: CLLocationDistance = 10.0
    
    /// Intervalle d'envoi des positions vers Firestore (en secondes)
    /// Par défaut : 30 secondes (au lieu de chaque point)
    var firestoreUploadInterval: TimeInterval = 30.0
    
    /// Intervalle de mise à jour de la position temps réel (en secondes)
    /// Position actuelle sur la carte pour les autres utilisateurs
    var realtimePositionInterval: TimeInterval = 15.0
    
    /// Nombre maximal de points à envoyer dans un batch
    var maxBatchSize: Int = 10
    
    /// Seuil de précision GPS minimum (en mètres)
    /// Les positions avec une précision > 50m sont ignorées
    var minimumAccuracy: CLLocationAccuracy = 50.0
    
    /// Mode économie de batterie (réduit la fréquence GPS)
    var batterySaverMode: Bool = false
    
    /// Configuration pour mode économie de batterie
    var batterySaverGpsDistance: CLLocationDistance = 30.0
    var batterySaverUploadInterval: TimeInterval = 60.0
}

/// Service de localisation GPS optimisé
@MainActor
class OptimizedLocationService: NSObject, ObservableObject {
    
    static let shared = OptimizedLocationService()
    
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    /// Configuration du tracking
    var configuration = TrackingConfiguration()
    
    /// Position actuelle de l'utilisateur
    @Published var currentLocation: CLLocation?
    
    /// Statut de l'autorisation
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Indique si le tracking est actif (contrôlé par l'utilisateur)
    @Published var isTracking = false
    
    /// ID de la session active
    private var activeSessionId: String?
    
    /// ID de l'utilisateur actuel
    private var currentUserId: String?
    
    /// Buffer local des positions (avant envoi vers Firestore)
    private var locationBuffer: [CLLocation] = []
    
    /// Dernière position envoyée vers Firestore
    private var lastUploadedLocation: CLLocation?
    
    /// Date du dernier envoi vers Firestore
    private var lastUploadTime: Date?
    
    /// Date du dernier envoi de position temps réel
    private var lastRealtimeUpdate: Date?
    
    /// Statistiques de tracking
    @Published var trackingStats: EnhancedTrackingStats = EnhancedTrackingStats()
    
    /// Dernière position pour calcul de distance
    private var lastLocation: CLLocation?
    
    /// Timer pour les envois périodiques
    private var uploadTimer: Timer?
    
    /// Timer pour les stats
    private var statsTimer: Timer?
    
    /// Listener pour les positions des autres coureurs
    private var locationListener: ListenerRegistration?
    
    /// Positions des autres coureurs
    @Published var runnerLocations: [String: LocationPoint] = [:]
    
    /// Compteur d'écritures Firestore (pour debug)
    @Published var firestoreWriteCount: Int = 0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = configuration.gpsUpdateDistance
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .fitness
        
        authorizationStatus = locationManager.authorizationStatus
        
        Logger.log("✅ OptimizedLocationService initialisé", category: .location)
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        Logger.log("📍 Demande d'autorisation de localisation", category: .location)
        locationManager.requestWhenInUseAuthorization()
    }
    
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Start Tracking (Contrôle Manuel)
    
    /// Démarre le tracking GPS
    /// ⚠️ L'utilisateur doit appuyer sur "Démarrer" pour activer le tracking
    func startTracking(sessionId: String, userId: String) {
        guard isAuthorized else {
            Logger.log("⚠️ Autorisation de localisation requise", category: .location)
            requestAuthorization()
            return
        }
        
        guard !isTracking else {
            Logger.log("⚠️ Tracking déjà actif", category: .location)
            return
        }
        
        Logger.log("🚀 Démarrage du tracking optimisé", category: .location)
        Logger.log("  📡 GPS update: tous les \(configuration.gpsUpdateDistance)m", category: .location)
        Logger.log("  ☁️ Firestore upload: toutes les \(configuration.firestoreUploadInterval)s", category: .location)
        Logger.log("  📍 Position temps réel: toutes les \(configuration.realtimePositionInterval)s", category: .location)
        
        self.activeSessionId = sessionId
        self.currentUserId = userId
        self.isTracking = true
        
        // Réinitialiser
        trackingStats = EnhancedTrackingStats()
        trackingStats.startTime = Date()
        lastLocation = nil
        locationBuffer = []
        lastUploadTime = nil
        lastRealtimeUpdate = nil
        firestoreWriteCount = 0
        
        // Appliquer la configuration
        applyConfiguration()
        
        // Démarrer les mises à jour GPS
        locationManager.startUpdatingLocation()
        
        // Démarrer les timers
        startUploadTimer()
        startStatsTimer()
        
        // Observer les autres coureurs
        startObservingRunnerLocations(sessionId: sessionId)
        
        Logger.logSuccess("✅ Tracking démarré pour session: \(sessionId)", category: .location)
    }
    
    // MARK: - Stop Tracking (Contrôle Manuel)
    
    /// Arrête le tracking GPS
    /// ⚠️ L'utilisateur doit appuyer sur "Arrêter" pour désactiver le tracking
    func stopTracking() {
        guard isTracking else {
            Logger.log("⚠️ Tracking déjà inactif", category: .location)
            return
        }
        
        Logger.log("🛑 Arrêt du tracking", category: .location)
        
        // Envoyer les derniers points du buffer
        Task {
            await flushLocationBuffer()
        }
        
        // Arrêter le GPS
        locationManager.stopUpdatingLocation()
        
        // Arrêter les timers
        uploadTimer?.invalidate()
        uploadTimer = nil
        
        statsTimer?.invalidate()
        statsTimer = nil
        
        // Arrêter l'observation
        stopObservingRunnerLocations()
        
        // Finaliser le parcours dans Firestore
        if let sessionId = activeSessionId, let userId = currentUserId {
            Task {
                try? await RouteHistoryService.shared.endUserRoute(
                    sessionId: sessionId,
                    userId: userId
                )
            }
        }
        
        self.isTracking = false
        self.activeSessionId = nil
        self.currentUserId = nil
        self.locationBuffer = []
        
        Logger.logSuccess("✅ Tracking arrêté - \(firestoreWriteCount) écritures Firestore", category: .location)
    }
    
    // MARK: - Pause / Resume
    
    /// Met en pause le tracking (arrête l'envoi mais continue le GPS)
    func pauseTracking() {
        guard isTracking else { return }
        
        Logger.log("⏸️ Pause du tracking", category: .location)
        
        trackingStats.isPaused = true
        trackingStats.pauseStartTime = Date()
        
        // Arrêter les timers mais garder le GPS
        uploadTimer?.invalidate()
        uploadTimer = nil
    }
    
    /// Reprend le tracking après une pause
    func resumeTracking() {
        guard isTracking, trackingStats.isPaused else { return }
        
        Logger.log("▶️ Reprise du tracking", category: .location)
        
        // Calculer le temps de pause
        if let pauseStart = trackingStats.pauseStartTime {
            trackingStats.totalPauseTime += Date().timeIntervalSince(pauseStart)
        }
        
        trackingStats.isPaused = false
        trackingStats.pauseStartTime = nil
        
        // Redémarrer les timers
        startUploadTimer()
    }
    
    // MARK: - Configuration
    
    /// Applique la configuration de tracking
    private func applyConfiguration() {
        if configuration.batterySaverMode {
            locationManager.distanceFilter = configuration.batterySaverGpsDistance
            Logger.log("🔋 Mode économie de batterie activé", category: .location)
        } else {
            locationManager.distanceFilter = configuration.gpsUpdateDistance
        }
    }
    
    /// Active le mode économie de batterie
    func enableBatterySaver(_ enabled: Bool) {
        configuration.batterySaverMode = enabled
        
        if isTracking {
            applyConfiguration()
        }
        
        Logger.log("🔋 Mode économie: \(enabled ? "ON" : "OFF")", category: .location)
    }
    
    // MARK: - Location Processing
    
    /// Traite une nouvelle position GPS
    private func processNewLocation(_ location: CLLocation) {
        // Ignorer si en pause
        guard !trackingStats.isPaused else { return }
        
        // Filtrer les positions avec une précision faible
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < configuration.minimumAccuracy else {
            Logger.log("⚠️ Position ignorée (précision: \(location.horizontalAccuracy)m)", category: .location)
            return
        }
        
        // Mettre à jour la position actuelle
        currentLocation = location
        
        // Ajouter au buffer (pour envoi batch)
        locationBuffer.append(location)
        
        // Calculer les statistiques localement (pas d'écriture Firestore)
        updateTrackingStats(newLocation: location)
        
        // Vérifier si on doit envoyer une mise à jour temps réel
        let now = Date()
        if let lastUpdate = lastRealtimeUpdate {
            if now.timeIntervalSince(lastUpdate) >= configuration.realtimePositionInterval {
                sendRealtimePosition(location: location)
                lastRealtimeUpdate = now
            }
        } else {
            // Premier point, envoyer immédiatement
            sendRealtimePosition(location: location)
            lastRealtimeUpdate = now
        }
    }
    
    /// Envoie la position temps réel (pour la carte)
    /// ⚠️ UNE SEULE écriture Firestore toutes les 15 secondes
    private func sendRealtimePosition(location: CLLocation) {
        guard let sessionId = activeSessionId,
              let userId = currentUserId else {
            return
        }
        
        Task {
            do {
                let repository = RealtimeLocationRepository()
                try await repository.publishLocation(
                    sessionId: sessionId,
                    userId: userId,
                    coordinate: location.coordinate
                )
                
                firestoreWriteCount += 1
                Logger.log("📍 Position temps réel envoyée (\(firestoreWriteCount) écritures)", category: .location)
            } catch {
                Logger.logError(error, context: "sendRealtimePosition", category: .location)
            }
        }
    }
    
    /// Met à jour les statistiques locales (pas d'écriture Firestore)
    private func updateTrackingStats(newLocation: CLLocation) {
        trackingStats.pointsCount += 1
        
        // Calculer la distance
        if let last = lastLocation {
            let distance = newLocation.distance(from: last)
            
            // Filtrer les distances aberrantes
            if distance < 100 && distance > 0 {
                trackingStats.totalDistance += distance
            }
        }
        
        // Mettre à jour la vitesse
        if newLocation.speed >= 0 {
            trackingStats.currentSpeed = newLocation.speed
            
            if newLocation.speed > trackingStats.maxSpeed {
                trackingStats.maxSpeed = newLocation.speed
            }
        }
        
        // Calculer la durée (en excluant les pauses)
        if let startTime = trackingStats.startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            trackingStats.duration = elapsed - trackingStats.totalPauseTime
            
            // Calculer la vitesse moyenne
            if trackingStats.duration > 0 {
                trackingStats.averageSpeed = trackingStats.totalDistance / trackingStats.duration
            }
        }
        
        lastLocation = newLocation
    }
    
    // MARK: - Batch Upload
    
    /// Démarre le timer d'envoi batch
    private func startUploadTimer() {
        let interval = configuration.batterySaverMode ?
            configuration.batterySaverUploadInterval :
            configuration.firestoreUploadInterval
        
        uploadTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                await self.flushLocationBuffer()
            }
        }
    }
    
    /// Envoie tous les points du buffer vers Firestore en une seule opération
    private func flushLocationBuffer() async {
        guard !locationBuffer.isEmpty,
              let sessionId = activeSessionId,
              let userId = currentUserId else {
            return
        }
        
        Logger.log("☁️ Envoi de \(locationBuffer.count) points vers Firestore", category: .location)
        
        do {
            // Créer un batch Firestore pour envoyer plusieurs points en une seule requête
            let batch = db.batch()
            
            let routeRef = db.collection("sessions")
                .document(sessionId)
                .collection("routes")
                .document(userId)
                .collection("points")
            
            // Limiter à maxBatchSize points (Firestore limite à 500 opérations par batch)
            let pointsToSend = Array(locationBuffer.prefix(configuration.maxBatchSize))
            
            for location in pointsToSend {
                let pointRef = routeRef.document()
                let point = OptimizedRoutePoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    timestamp: location.timestamp,
                    altitude: location.altitude,
                    speed: location.speed >= 0 ? location.speed : nil,
                    horizontalAccuracy: location.horizontalAccuracy
                )
                
                try batch.setData(from: point, forDocument: pointRef)
            }
            
            // Envoyer le batch (UNE SEULE requête réseau)
            try await batch.commit()
            
            firestoreWriteCount += pointsToSend.count
            
            // Retirer les points envoyés du buffer
            locationBuffer.removeFirst(pointsToSend.count)
            
            Logger.logSuccess("✅ \(pointsToSend.count) points envoyés (\(firestoreWriteCount) écritures totales)", category: .location)
        } catch {
            Logger.logError(error, context: "flushLocationBuffer", category: .location)
        }
    }
    
    // MARK: - Stats Timer
    
    /// Démarre le timer de mise à jour des statistiques
    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                await self.updateStatsInFirestore()
            }
        }
    }
    
    /// Met à jour les statistiques dans Firestore (toutes les 10 secondes)
    private func updateStatsInFirestore() async {
        guard let sessionId = activeSessionId,
              let userId = currentUserId else {
            return
        }
        
        do {
            try await SessionService.shared.updateParticipantStats(
                sessionId: sessionId,
                userId: userId,
                distance: trackingStats.totalDistance,
                duration: trackingStats.duration,
                averageSpeed: trackingStats.averageSpeed,
                maxSpeed: trackingStats.maxSpeed
            )
            
            firestoreWriteCount += 1
        } catch {
            Logger.logError(error, context: "updateStatsInFirestore", category: .location)
        }
    }
    
    // MARK: - Observe Other Runners
    
    private func startObservingRunnerLocations(sessionId: String) {
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
                    if document.documentID == self.currentUserId {
                        continue
                    }
                    
                    if let location = try? document.data(as: LocationPoint.self) {
                        self.runnerLocations[document.documentID] = location
                    }
                }
            }
        }
    }
    
    private func stopObservingRunnerLocations() {
        locationListener?.remove()
        locationListener = nil
        runnerLocations.removeAll()
    }
}

// MARK: - CLLocationManagerDelegate

extension OptimizedLocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Ne traiter que si le tracking est actif
        if isTracking {
            processNewLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.logError(error, context: "locationManager", category: .location)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        Logger.log("📍 Statut d'autorisation: \(authorizationStatus.description)", category: .location)
        
        if !isAuthorized && isTracking {
            stopTracking()
        }
    }
}

// MARK: - Enhanced TrackingStats

/// Statistiques de tracking GPS étendues
struct EnhancedTrackingStats {
    /// Stats de base
    var base: TrackingStats = TrackingStats()
    
    /// Date de début du tracking
    var startTime: Date?
    
    /// Indique si le tracking est en pause
    var isPaused: Bool = false
    
    /// Date de début de la pause actuelle
    var pauseStartTime: Date?
    
    /// Temps total de pause (en secondes)
    var totalPauseTime: TimeInterval = 0
    
    /// Durée active (durée - pauses)
    var activeDuration: TimeInterval {
        base.duration - totalPauseTime
    }
    
    // Déléguer les propriétés de base
    var totalDistance: Double {
        get { base.totalDistance }
        set { base.totalDistance = newValue }
    }
    
    var duration: TimeInterval {
        get { base.duration }
        set { base.duration = newValue }
    }
    
    var currentSpeed: Double {
        get { base.currentSpeed }
        set { base.currentSpeed = newValue }
    }
    
    var averageSpeed: Double {
        get { base.averageSpeed }
        set { base.averageSpeed = newValue }
    }
    
    var maxSpeed: Double {
        get { base.maxSpeed }
        set { base.maxSpeed = newValue }
    }
    
    var pointsCount: Int {
        get { base.pointsCount }
        set { base.pointsCount = newValue }
    }
    
    var distanceInKm: Double { base.distanceInKm }
    var currentSpeedKmh: Double { base.currentSpeedKmh }
    var averageSpeedKmh: Double { base.averageSpeedKmh }
    var currentPace: String { base.currentPace }
    var averagePace: String { base.averagePace }
    var formattedDuration: String { base.formattedDuration }
}

// MARK: - OptimizedRoutePoint Model

/// Point de parcours simplifié pour le batch upload (optimisé)
struct OptimizedRoutePoint: Codable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var altitude: Double?
    var speed: Double?
    var horizontalAccuracy: Double?
}
