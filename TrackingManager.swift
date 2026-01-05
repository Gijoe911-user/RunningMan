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
import FirebaseFirestore  // 🆕 Pour FieldValue

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
    
    /// 🆕 Tracés GPS des autres participants (pour les supporters)
    @Published private(set) var otherRunnersRoutes: [String: [CLLocationCoordinate2D]] = [:]
    
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
    
    // 🆕 Sauvegarde automatique moderne avec Task
    private var autoSaveTask: Task<Void, Never>?
    private let autoSaveInterval: TimeInterval = 10  // 🎯 10 secondes pour feedback temps réel
    
    // 🆕 Buffer de points à sauvegarder
    private var pendingRoutePoints: [CLLocationCoordinate2D] = []
    private let pointsLock = NSLock()
    
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
        Logger.log("[AUDIT-TM-01] 🚀 TrackingManager.startTracking appelé", category: .location)
        Logger.log("[AUDIT-TM-01-DEBUG] 📋 Session reçue:", category: .location)
        Logger.log("   - id: \(session.id ?? "NIL")", category: .location)
        Logger.log("   - squadId: \(session.squadId)", category: .location)
        Logger.log("   - creatorId: \(session.creatorId)", category: .location)
        Logger.log("   - status: \(session.status.rawValue)", category: .location)
        
        // Vérifier qu'on peut démarrer
        guard canStartTracking else {
            Logger.log("⚠️ Impossible de démarrer : tracking déjà actif", category: .location)
            return false
        }
        
        guard let sessionId = session.id else {
            Logger.log("❌❌ ERREUR CRITIQUE : Session ID est NIL", category: .location)
            Logger.log("   - Cela signifie que la session n'a pas été chargée depuis Firestore", category: .location)
            Logger.log("   - Vérifier que la vue passe bien une session avec un ID valide", category: .location)
            return false
        }
        
        guard let userId = AuthService.shared.currentUserId else {
            Logger.log("❌ User ID manquant", category: .location)
            return false
        }
        
        Logger.log("✅ Validation OK - sessionId: \(sessionId), userId: \(userId)", category: .location)
        
        // Initialiser l'état LOCAL IMMÉDIATEMENT
        activeTrackingSession = session
        trackingState = .active  // ✅ État local actif AVANT Firebase
        sessionStartTime = Date()
        currentDistance = 0
        currentDuration = 0
        currentSpeed = 0
        totalPausedDuration = 0
        lastLocation = nil
        routeCoordinates = []
        
        // 🆕 Vider le buffer de points
        pointsLock.lock()
        pendingRoutePoints.removeAll()
        pointsLock.unlock()
        
        Logger.log("[AUDIT-TM-SEED-01] 🔄 État local passé à .active", category: .location)
        
        // 🎯 FIX SAUT VISUEL : Charger l'historique AVANT de démarrer le tracking live
        do {
            Logger.log("[AUDIT-TM-SEED-02] 📥 Chargement de l'historique...", category: .location)
            let (coordinates, timestamps) = try await routeService.loadRouteWithTimestamps(
                sessionId: sessionId,
                userId: userId
            )
            
            if !coordinates.isEmpty {
                // Seeder le service (pré-remplir la liste en mémoire)
                routeService.seedRoute(coordinates, timestamps: timestamps)
                
                // 🎯 CRITIQUE : Synchroniser routeCoordinates avec l'historique
                routeCoordinates = routeService.getCurrentRoute()
                
                Logger.logSuccess("[AUDIT-TM-SEED-03] ✅ Historique seedé: \(coordinates.count) points, routeCoordinates: \(routeCoordinates.count)", category: .location)
            } else {
                Logger.log("[AUDIT-TM-SEED-04] ℹ️ Aucun historique (nouvelle session)", category: .location)
                // Vider le RouteTrackingService seulement si pas d'historique
                routeService.clearRoute()
            }
        } catch {
            Logger.log("[AUDIT-TM-SEED-05] ⚠️ Chargement historique échoué (probablement nouvelle session): \(error)", category: .location)
            // Si le chargement échoue, c'est probablement une nouvelle session
            routeService.clearRoute()
        }
        
        // Démarrer les services de tracking live
        locationProvider.startUpdating()
        
        // 🎯 Configurer la précision GPS pour la course à pied
        locationProvider.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationProvider.distanceFilter = 10  // 10 mètres entre chaque point
        
        // 🆕 APPELER LA NOUVELLE MÉTHODE startMyTracking() - LE FIX PRINCIPAL
        Logger.log("[AUDIT-TM-02] 🚀 Appel SessionService.startMyTracking()...", category: .session)
        do {
            try await sessionService.startMyTracking(sessionId: sessionId, userId: userId)
            Logger.logSuccess("✅✅ startMyTracking() réussi - Session activée dans Firebase", category: .session)
        } catch {
            Logger.logError(error, context: "startMyTracking", category: .session)
            // ⚠️ Même si Firebase échoue, on continue le tracking localement
            Logger.log("⚠️ Échec Firebase, mais tracking local continue", category: .session)
        }
        
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
        
        // 🆕 Démarrer la boucle de sauvegarde automatique moderne (10s)
        startAutoSaveLoop(sessionId: sessionId, userId: userId)
        
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
        Logger.log("[AUDIT-TM-02] ⏸️ TrackingManager.pauseTracking appelé", category: .location)
        
        guard trackingState == .active else {
            Logger.log("⚠️ Tracking pas actif, pause impossible", category: .location)
            return
        }
        
        trackingState = .paused
        pausedTime = Date()
        
        // Arrêter les timers
        durationTimer?.invalidate()
        autoSaveTask?.cancel()  // 🆕 Annuler la Task de sauvegarde
        
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
        Logger.log("[AUDIT-TM-03] ▶️ TrackingManager.resumeTracking appelé", category: .location)
        
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
            startAutoSaveLoop(sessionId: sessionId, userId: userId)  // 🆕 Relancer la boucle
            
            // Mettre à jour le statut dans Firestore
            try? await sessionService.resumeSession(sessionId: sessionId)
        }
        
        Logger.logSuccess("✅ Tracking repris", category: .location)
    }
    
    // MARK: - Stop Tracking
    
    /// Arrête le tracking et sauvegarde la session
    func stopTracking() async throws {
        Logger.log("[AUDIT-TM-04] 🛑 TrackingManager.stopTracking appelé", category: .location)
        
        guard trackingState == .active || trackingState == .paused else {
            Logger.log("[AUDIT-TM-STOP-01] ⚠️ Aucun tracking actif à arrêter (état: \(trackingState.displayName))", category: .location)
            return
        }
        
        guard let session = activeTrackingSession else {
            Logger.log("[AUDIT-TM-STOP-02] ⚠️ Aucune session active", category: .location)
            return
        }
        
        guard let sessionId = session.id else {
            Logger.log("[AUDIT-TM-STOP-03] ❌ Session ID manquant", category: .location)
            throw TrackingError.invalidSession
        }
        
        Logger.log("[AUDIT-TM-STOP-04] 🔄 Passage à l'état .stopping", category: .location)
        trackingState = .stopping
        
        // 1. Arrêter tous les services
        Logger.log("[AUDIT-TM-STOP-05] ⏸️ Arrêt des services (timer, GPS, etc.)", category: .location)
        durationTimer?.invalidate()
        autoSaveTask?.cancel()
        locationProvider.stopUpdating()
        
        // 2. Arrêter HealthKit
        Logger.log("[AUDIT-TM-STOP-06] ❤️ Arrêt HealthKit", category: .location)
        healthKitManager.stopHeartRateQuery()
        do {
            try await healthKitManager.endWorkout()
            Logger.logSuccess("[AUDIT-TM-STOP-07] ✅ HealthKit workout terminé", category: .health)
        } catch {
            Logger.logError(error, context: "endWorkout", category: .health)
        }
        
        // 3. Sauvegarder une dernière fois
        Logger.log("[AUDIT-TM-STOP-08] 💾 Sauvegarde finale...", category: .location)
        await saveCurrentState()
        Logger.log("[AUDIT-TM-STOP-09] ✅ Sauvegarde finale terminée", category: .location)
        
        // 4. Attendre 2 secondes pour que toutes les écritures se terminent
        Logger.log("[AUDIT-TM-STOP-10] ⏳ Attente 2 secondes...", category: .location)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        Logger.log("[AUDIT-TM-STOP-11] ✅ Attente terminée", category: .location)
        
        // 5. Terminer la session dans Firestore
        Logger.log("[AUDIT-TM-STOP-12] 🏁 Terminaison de la session dans Firestore...", category: .location)
        do {
            try await sessionService.endSession(sessionId: sessionId)
            Logger.logSuccess("[AUDIT-TM-STOP-13] ✅ Session terminée dans Firestore", category: .location)
        } catch {
            Logger.logError(error, context: "sessionService.endSession", category: .location)
            // ⚠️ Ne pas bloquer le nettoyage même si Firestore échoue
            Logger.log("[AUDIT-TM-STOP-14] ⚠️ Firestore échoué, on continue le nettoyage local", category: .location)
        }
        
        // 6. Nettoyer l'état
        Logger.log("[AUDIT-TM-STOP-15] 🗑️ Nettoyage de l'état local", category: .location)
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
        
        Logger.logSuccess("[AUDIT-TM-STOP-16] ✅✅ Tracking complètement arrêté", category: .location)
    }
    
    // MARK: - 🆕 Load Routes (For Supporters)
    
    /// Charge le tracé GPS d'un participant depuis Firebase
    /// 🎯 Utilisé par les supporters pour voir le parcours des coureurs
    func loadRoute(sessionId: String, userId: String) async {
        Logger.log("📥 Chargement du tracé pour userId: \(userId)", category: .location)
        
        do {
            let coordinates = try await routeService.loadRoute(sessionId: sessionId, userId: userId)
            
            if coordinates.isEmpty {
                Logger.log("⚠️ Aucun point GPS trouvé pour ce coureur", category: .location)
                return
            }
            
            // Si c'est notre propre tracé, le mettre dans routeCoordinates
            if userId == AuthService.shared.currentUserId {
                routeCoordinates = coordinates
                Logger.logSuccess("✅ Mon tracé chargé: \(coordinates.count) points", category: .location)
            } else {
                // Sinon, dans otherRunnersRoutes
                otherRunnersRoutes[userId] = coordinates
                Logger.logSuccess("✅ Tracé de \(userId) chargé: \(coordinates.count) points", category: .location)
            }
        } catch {
            Logger.logError(error, context: "loadRoute", category: .location)
        }
    }
    
    /// Charge tous les tracés d'une session (pour les supporters)
    func loadAllRoutes(sessionId: String) async {
        Logger.log("📥 Chargement de tous les tracés de la session...", category: .location)
        
        do {
            let allRoutes = try await routeService.loadAllRoutes(sessionId: sessionId)
            
            for (userId, coordinates) in allRoutes {
                if userId == AuthService.shared.currentUserId {
                    routeCoordinates = coordinates
                } else {
                    otherRunnersRoutes[userId] = coordinates
                }
            }
            
            Logger.logSuccess("✅ \(allRoutes.count) tracés chargés", category: .location)
        } catch {
            Logger.logError(error, context: "loadAllRoutes", category: .location)
        }
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
        
        Logger.log("[AUDIT-TM-LIVE-01] 📍 handleNewLocation → lat: \(coordinate.latitude), lon: \(coordinate.longitude)", category: .location)
        
        // Ajouter au RouteTrackingService (source unique de vérité)
        routeService.addRoutePoint(coordinate)
        
        // 🎯 SYNCHRONISER depuis RouteTrackingService (pas append direct)
        routeCoordinates = routeService.getCurrentRoute()
        
        Logger.log("[AUDIT-TM-LIVE-02] 📊 routeCoordinates synchronisé → count: \(routeCoordinates.count)", category: .location)
        
        // 🆕 Ajouter au buffer de sauvegarde
        pointsLock.lock()
        pendingRoutePoints.append(coordinate)
        pointsLock.unlock()
        
        // Calculer la distance si on a une position précédente
        if let lastLocation = lastLocation {
            let distance = coordinate.distance(from: lastLocation)
            
            // Filtrer les valeurs aberrantes (plus de 500m entre 2 points)
            if distance < 500 {
                currentDistance += distance
                
                // Calculer la vitesse
                currentSpeed = locationProvider.currentSpeed
            }
        }
        
        lastLocation = coordinate
        
        // Publier la position dans Firestore (temps réel) - Fire-and-forget
        if let sessionId = activeTrackingSession?.id,
           let userId = AuthService.shared.currentUserId {
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
    
    // MARK: - 🆕 Auto-Save Loop (Modern Swift Concurrency)
    
    /// Démarre la boucle de sauvegarde automatique toutes les 10 secondes
    /// 🎯 Utilise Swift Concurrency pour une sauvegarde moderne et fiable
    private func startAutoSaveLoop(sessionId: String, userId: String) {
        // Annuler la Task précédente si existante
        autoSaveTask?.cancel()
        
        autoSaveTask = Task { @MainActor in
            Logger.log("🔄 Boucle de sauvegarde automatique démarrée (toutes les \(Int(autoSaveInterval))s)", category: .location)
            
            while !Task.isCancelled && trackingState == .active {
                // Attendre 10 secondes
                do {
                    try await Task.sleep(nanoseconds: UInt64(autoSaveInterval * 1_000_000_000))
                } catch {
                    // Task annulée
                    break
                }
                
                // Vérifier qu'on est toujours actif
                guard !Task.isCancelled && trackingState == .active else {
                    break
                }
                
                // Sauvegarder les points collectés
                await saveRoutePointsToFirebase(sessionId: sessionId, userId: userId)
            }
            
            Logger.log("⏸️ Boucle de sauvegarde automatique terminée", category: .location)
        }
    }
    
    /// Sauvegarde les points GPS collectés dans Firebase
    private func saveRoutePointsToFirebase(sessionId: String, userId: String) async {
        // Récupérer les points en attente
        pointsLock.lock()
        let pointsToSave = pendingRoutePoints
        pendingRoutePoints.removeAll()
        pointsLock.unlock()
        
        guard !pointsToSave.isEmpty else {
            Logger.log("⏭️ Aucun nouveau point à sauvegarder", category: .location)
            return
        }
        
        Logger.log("⏰ Sauvegarde automatique déclenchée - \(pointsToSave.count) nouveaux points", category: .location)
        
        // Sauvegarder via RouteTrackingService
        do {
            try await routeService.saveRoute(sessionId: sessionId, userId: userId)
            Logger.logSuccess("✅ Points GPS sauvegardés: \(pointsToSave.count) points", category: .location)
            
            // Mettre à jour les stats en même temps
            await updateSessionStats(sessionId: sessionId, userId: userId)
            
            // 🆕 Mettre à jour le heartbeat (participant toujours actif)
            await updateHeartbeat(sessionId: sessionId, userId: userId)
        } catch {
            Logger.logError(error, context: "saveRoutePointsToFirebase", category: .location)
            
            // ⚠️ Remettre les points dans le buffer en cas d'échec
            pointsLock.lock()
            pendingRoutePoints.insert(contentsOf: pointsToSave, at: 0)
            pointsLock.unlock()
        }
    }
    
    /// 🆕 Met à jour le heartbeat du participant pour indiquer qu'il est toujours actif
    private func updateHeartbeat(sessionId: String, userId: String) async {
        // Récupérer la position et le BPM actuels
        let location: GeoPoint? = {
            guard let coord = lastLocation else { return nil }
            return GeoPoint(latitude: coord.latitude, longitude: coord.longitude)
        }()
        
        let heartRate = healthKitManager.currentHeartRate
        
        do {
            try await sessionService.updateParticipantHeartbeat(
                sessionId: sessionId,
                userId: userId,
                location: location,
                heartRate: heartRate
            )
            // Logger désactivé pour ne pas polluer (appelé toutes les 10s)
            // Logger.log("💓 Heartbeat mis à jour", category: .location)
        } catch {
            // Erreur silencieuse pour le heartbeat (pas critique)
            Logger.log("⚠️ Échec mise à jour heartbeat: \(error)", category: .location)
        }
    }
    
    /// Met à jour les statistiques de la session
    private func updateSessionStats(sessionId: String, userId: String) async {
        let averageSpeed = currentDuration > 0 ? currentDistance / currentDuration : 0
        
        do {
            // Stats du participant
            try await sessionService.updateParticipantStats(
                sessionId: sessionId,
                userId: userId,
                distance: currentDistance,
                duration: currentDuration,
                averageSpeed: averageSpeed,
                maxSpeed: currentSpeed
            )
            
            // Stats de la session
            try await sessionService.updateSessionStats(
                sessionId: sessionId,
                totalDistance: currentDistance,
                averageSpeed: averageSpeed
            )
            
            // Durée
            try await sessionService.updateSessionDuration(
                sessionId: sessionId,
                duration: currentDuration
            )
            
            Logger.log("📊 Stats mises à jour: \(String(format: "%.2f", currentDistance/1000))km, \(String(format: "%.0f", currentDuration))s", category: .location)
        } catch {
            Logger.logError(error, context: "updateSessionStats", category: .location)
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
    
    /// ⚠️ DEPRECATED - Ancienne méthode avec Timer (gardée pour compatibilité)
    @available(*, deprecated, message: "Utiliser startAutoSaveLoop à la place")
    private func startAutoSave(sessionId: String, userId: String) {
        startAutoSaveLoop(sessionId: sessionId, userId: userId)
    }
    
    /// Sauvegarde l'état actuel (route + stats) - Utilisé pour la sauvegarde finale
    private func saveCurrentState() async {
        guard let sessionId = activeTrackingSession?.id,
              let userId = AuthService.shared.currentUserId else {
            return
        }
        
        Logger.log("💾 Sauvegarde finale de l'état actuel...", category: .location)
        
        // 1. Sauvegarder tous les points restants
        await saveRoutePointsToFirebase(sessionId: sessionId, userId: userId)
        
        // 2. Mettre à jour les stats une dernière fois
        await updateSessionStats(sessionId: sessionId, userId: userId)
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
