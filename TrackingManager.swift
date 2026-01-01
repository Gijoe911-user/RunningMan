//
//  TrackingManager.swift
//  RunningMan
//
//  Gère le tracking GPS d'une session active avec sauvegarde automatique
//  🎯 UNE SEULE SESSION DE TRACKING ACTIVE À LA FOIS
//

import Foundation
import CoreLocation
import Combine
import HealthKit

/// État du tracking de la session
enum TrackingState: Equatable {
    case idle              // Pas de tracking
    case active            // Tracking en cours
    case paused            // Tracking en pause
    case stopping          // En cours d'arrêt
    
    var displayName: String {
        switch self {
        case .idle: return "Inactif"
        case .active: return "En cours"
        case .paused: return "En pause"
        case .stopping: return "Arrêt..."
        }
    }
}

/// Manager principal pour le tracking GPS des sessions
@MainActor
class TrackingManager: ObservableObject {
    
    static let shared = TrackingManager()
    
    // MARK: - Published Properties
    
    /// Session actuellement trackée
    @Published private(set) var activeTrackingSession: SessionModel?
    
    /// État du tracking
    @Published private(set) var trackingState: TrackingState = .idle
    
    /// Distance parcourue pendant la session (en mètres)
    @Published private(set) var currentDistance: Double = 0
    
    /// Durée de la session (en secondes)
    @Published private(set) var currentDuration: TimeInterval = 0
    
    /// Vitesse actuelle (en m/s)
    @Published private(set) var currentSpeed: Double = 0
    
    /// Tracé GPS complet de la session
    @Published private(set) var routeCoordinates: [CLLocationCoordinate2D] = []
    
    /// Indique si on peut démarrer un tracking
    var canStartTracking: Bool {
        trackingState == .idle
    }
    
    /// Indique si un tracking est en cours
    var isTracking: Bool {
        trackingState == .active
    }
    
    /// Indique si le tracking est en pause
    var isPaused: Bool {
        trackingState == .paused
    }
    
    // MARK: - Private Properties
    
    private let locationProvider = LocationProvider.shared
    private let routeService = RouteTrackingService.shared
    private let sessionService = SessionService.shared
    private let healthKitManager = HealthKitManager.shared
    
    // Timer pour calculer la durée
    private var durationTimer: Timer?
    private var sessionStartTime: Date?
    private var pausedTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    
    // Position précédente pour calculer la distance
    private var lastLocation: CLLocationCoordinate2D?
    
    // Sauvegarde automatique toutes les 3 minutes
    private var autoSaveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 180  // 3 minutes = 180 secondes
    
    // Observation de la localisation
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        Logger.log("🎯 TrackingManager initialisé", category: .location)
    }
    
    // MARK: - Start Tracking
    
    /// Démarre le tracking pour une session
    /// - Parameter session: La session à tracker
    /// - Returns: `true` si le tracking a démarré, `false` sinon
    func startTracking(for session: SessionModel) async -> Bool {
        Logger.log("🚀 Demande de démarrage tracking pour session: \(session.id ?? "unknown")", category: .location)
        
        // Vérifier qu'on peut démarrer
        guard canStartTracking else {
            Logger.log("⚠️ Impossible de démarrer : tracking déjà actif", category: .location)
            return false
        }
        
        guard let sessionId = session.id else {
            Logger.log("❌ Session ID manquant", category: .location)
            return false
        }
        
        guard let userId = AuthService.shared.currentUserId else {
            Logger.log("❌ User ID manquant", category: .location)
            return false
        }
        
        // Initialiser l'état
        activeTrackingSession = session
        trackingState = .active
        sessionStartTime = Date()
        currentDistance = 0
        currentDuration = 0
        currentSpeed = 0
        totalPausedDuration = 0
        lastLocation = nil
        routeCoordinates = []
        
        // Démarrer les services
        locationProvider.startUpdating()
        routeService.clearRoute()
        
        // Démarrer HealthKit
        if healthKitManager.isAvailable {
            let authorized = await healthKitManager.requestAuthorization()
            if authorized {
                healthKitManager.startHeartRateQuery(sessionId: sessionId)
                do {
                    try await healthKitManager.startWorkout(activityType: .running)
                    Logger.logSuccess("✅ HealthKit workout démarré", category: .health)
                } catch {
                    Logger.logError(error, context: "startWorkout", category: .health)
                }
            }
        }
        
        // Démarrer la sauvegarde automatique (toutes les 3 minutes)
        startAutoSave(sessionId: sessionId, userId: userId)
        
        // Observer les mises à jour de localisation
        observeLocationUpdates()
        
        // Démarrer le timer de durée
        startDurationTimer()
        
        Logger.logSuccess("✅ Tracking démarré pour session: \(sessionId)", category: .location)
        return true
    }
    
    // MARK: - Pause Tracking
    
    /// Met le tracking en pause
    func pauseTracking() async {
        Logger.log("⏸️ Pause du tracking", category: .location)
        
        guard trackingState == .active else {
            Logger.log("⚠️ Tracking pas actif, pause impossible", category: .location)
            return
        }
        
        trackingState = .paused
        pausedTime = Date()
        
        // Arrêter les timers
        durationTimer?.invalidate()
        autoSaveTimer?.invalidate()
        
        // Arrêter les updates GPS (économie batterie)
        locationProvider.stopUpdating()
        
        // Mettre à jour le statut de la session dans Firestore
        if let sessionId = activeTrackingSession?.id {
            try? await sessionService.pauseSession(sessionId: sessionId)
            
            // Sauvegarder l'état actuel
            await saveCurrentState()
        }
        
        Logger.logSuccess("✅ Tracking en pause", category: .location)
    }
    
    // MARK: - Resume Tracking
    
    /// Reprend le tracking après une pause
    func resumeTracking() async {
        Logger.log("▶️ Reprise du tracking", category: .location)
        
        guard trackingState == .paused else {
            Logger.log("⚠️ Tracking pas en pause, reprise impossible", category: .location)
            return
        }
        
        // Calculer la durée de la pause
        if let pausedTime = pausedTime {
            totalPausedDuration += Date().timeIntervalSince(pausedTime)
        }
        pausedTime = nil
        
        trackingState = .active
        
        // Redémarrer les services
        locationProvider.startUpdating()
        startDurationTimer()
        
        if let sessionId = activeTrackingSession?.id,
           let userId = AuthService.shared.currentUserId {
            startAutoSave(sessionId: sessionId, userId: userId)
            
            // Mettre à jour le statut dans Firestore
            try? await sessionService.resumeSession(sessionId: sessionId)
        }
        
        Logger.logSuccess("✅ Tracking repris", category: .location)
    }
    
    // MARK: - Stop Tracking
    
    /// Arrête le tracking et sauvegarde la session
    func stopTracking() async throws {
        Logger.log("🛑 Arrêt du tracking", category: .location)
        
        guard trackingState == .active || trackingState == .paused else {
            Logger.log("⚠️ Aucun tracking actif à arrêter", category: .location)
            return
        }
        
        guard let session = activeTrackingSession else {
            Logger.log("⚠️ Aucune session active", category: .location)
            return
        }
        
        guard let sessionId = session.id else {
            Logger.log("❌ Session ID manquant", category: .location)
            throw TrackingError.invalidSession
        }
        
        guard let userId = AuthService.shared.currentUserId else {
            Logger.log("❌ User ID manquant", category: .location)
            throw TrackingError.userNotAuthenticated
        }
        
        trackingState = .stopping
        
        // 1. Arrêter tous les services
        durationTimer?.invalidate()
        autoSaveTimer?.invalidate()
        locationProvider.stopUpdating()
        
        // 2. Arrêter HealthKit
        healthKitManager.stopHeartRateQuery()
        do {
            try await healthKitManager.endWorkout()
            Logger.logSuccess("✅ HealthKit workout terminé", category: .health)
        } catch {
            Logger.logError(error, context: "endWorkout", category: .health)
        }
        
        // 3. Sauvegarder une dernière fois
        Logger.log("💾 Sauvegarde finale...", category: .location)
        await saveCurrentState()
        
        // 4. Attendre 2 secondes pour que toutes les écritures se terminent
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 5. Terminer la session dans Firestore
        Logger.log("🏁 Terminaison de la session dans Firestore...", category: .location)
        try await sessionService.endSession(sessionId: sessionId)
        
        // 6. Nettoyer l'état
        trackingState = .idle
        activeTrackingSession = nil
        routeCoordinates = []
        currentDistance = 0
        currentDuration = 0
        currentSpeed = 0
        lastLocation = nil
        sessionStartTime = nil
        totalPausedDuration = 0
        cancellables.removeAll()
        
        Logger.logSuccess("✅ Tracking arrêté et session sauvegardée", category: .location)
    }
    
    // MARK: - Private Methods
    
    /// Observe les mises à jour de localisation
    private func observeLocationUpdates() {
        locationProvider.$currentCoordinate
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                Task { @MainActor [weak self] in
                    await self?.handleNewLocation(coordinate)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Traite une nouvelle position GPS
    private func handleNewLocation(_ coordinate: CLLocationCoordinate2D) async {
        guard trackingState == .active else { return }
        
        // Ajouter au tracé
        routeCoordinates.append(coordinate)
        routeService.addRoutePoint(coordinate)
        
        // Calculer la distance si on a une position précédente
        if let lastLocation = lastLocation {
            let distance = coordinate.distance(from: lastLocation)
            
            // Filtrer les valeurs aberrantes (plus de 500m entre 2 points)
            if distance < 500 {
                currentDistance += distance
                
                // Calculer la vitesse
                currentSpeed = locationProvider.currentSpeed ?? 0
            }
        }
        
        lastLocation = coordinate
        
        // Publier la position dans Firestore (temps réel)
        if let sessionId = activeTrackingSession?.id,
           let userId = AuthService.shared.currentUserId {
            // Fire-and-forget pour ne pas bloquer
            Task.detached {
                let repository = RealtimeLocationRepository()
                try? await repository.publishLocation(
                    sessionId: sessionId,
                    userId: userId,
                    coordinate: coordinate
                )
            }
        }
    }
    
    /// Démarre le timer de durée
    private func startDurationTimer() {
        durationTimer?.invalidate()
        
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard self.trackingState == .active else { return }
                guard let startTime = self.sessionStartTime else { return }
                
                let elapsed = Date().timeIntervalSince(startTime) - self.totalPausedDuration
                self.currentDuration = max(0, elapsed)
            }
        }
    }
    
    /// Démarre la sauvegarde automatique toutes les 3 minutes
    private func startAutoSave(sessionId: String, userId: String) {
        autoSaveTimer?.invalidate()
        
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.saveCurrentState()
            }
        }
        
        Logger.log("🔄 Auto-sauvegarde activée (toutes les \(Int(autoSaveInterval))s)", category: .location)
    }
    
    /// Sauvegarde l'état actuel (route + stats)
    private func saveCurrentState() async {
        guard let sessionId = activeTrackingSession?.id,
              let userId = AuthService.shared.currentUserId else {
            return
        }
        
        Logger.log("💾 Sauvegarde de l'état actuel...", category: .location)
        
        // 1. Sauvegarder le tracé GPS
        do {
            try await routeService.saveRoute(sessionId: sessionId, userId: userId)
            Logger.log("✅ Tracé sauvegardé: \(routeCoordinates.count) points", category: .location)
        } catch {
            Logger.logError(error, context: "saveRoute", category: .location)
        }
        
        // 2. Sauvegarder les stats du participant
        let averageSpeed = currentDuration > 0 ? currentDistance / currentDuration : 0
        
        do {
            try await sessionService.updateParticipantStats(
                sessionId: sessionId,
                userId: userId,
                distance: currentDistance,
                duration: currentDuration,
                averageSpeed: averageSpeed,
                maxSpeed: currentSpeed
            )
            Logger.log("✅ Stats sauvegardées", category: .location)
        } catch {
            Logger.logError(error, context: "updateParticipantStats", category: .location)
        }
        
        // 3. Mettre à jour les stats de la session
        do {
            try await sessionService.updateSessionStats(
                sessionId: sessionId,
                totalDistance: currentDistance,
                averageSpeed: averageSpeed
            )
        } catch {
            Logger.logError(error, context: "updateSessionStats", category: .location)
        }
        
        // 4. Mettre à jour la durée
        do {
            try await sessionService.updateSessionDuration(
                sessionId: sessionId,
                duration: currentDuration
            )
        } catch {
            Logger.logError(error, context: "updateSessionDuration", category: .location)
        }
    }
}

// MARK: - Errors

enum TrackingError: LocalizedError {
    case alreadyTracking
    case invalidSession
    case userNotAuthenticated
    case locationServicesDisabled
    
    var errorDescription: String? {
        switch self {
        case .alreadyTracking:
            return "Un tracking est déjà en cours"
        case .invalidSession:
            return "Session invalide"
        case .userNotAuthenticated:
            return "Utilisateur non connecté"
        case .locationServicesDisabled:
            return "Services de localisation désactivés"
        }
    }
}

// MARK: - CLLocationCoordinate2D Extension

extension CLLocationCoordinate2D {
    /// Calcule la distance (en mètres) entre deux coordonnées
    func distance(from other: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return location1.distance(from: location2)
    }
}
