import Foundation
import CoreLocation
import Combine

// MARK: - Supporting Types

/// Progression de l'utilisateur dans la préparation marathon
struct MarathonProgress {
    let percentage: Double
    let daysRemaining: Int
}

/// ViewModel gérant l'état des sessions de course
///
/// Ce ViewModel orchestre :
/// - La session active et son cycle de vie
/// - Le tracking GPS et les tracés
/// - Les positions des autres coureurs en temps réel
/// - Les statistiques HealthKit (BPM, calories)
///
/// - Important: Ne doit **jamais** importer Firebase. Utilise uniquement les Services.
/// - SeeAlso: `SessionService`, `RealtimeLocationService`, `HealthKitManager`
@MainActor
class SessionsViewModel: NSObject, ObservableObject {
    
    // MARK: - Published Properties (UI State)
    
    /// Session de course actuellement active, `nil` si aucune session
    @Published var activeSession: SessionModel?
    
    /// Positions en temps réel des coureurs de la session
    @Published var runnerLocations: [RunnerLocation] = []
    
    /// Alias pour `runnerLocations` (compatibilité avec anciennes vues)
    @Published var activeRunners: [RunnerLocation] = []
    
    /// Position GPS de l'utilisateur actuel
    @Published var userLocation: CLLocationCoordinate2D?
    
    /// Tracé GPS de l'utilisateur pour la session en cours
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    /// Tracés GPS des autres coureurs (dictionnaire userId → coordonnées)
    @Published var runnerRoutes: [String: [CLLocationCoordinate2D]] = [:]
    
    /// Nombre de messages non lus dans le chat (feature non implémentée)
    @Published var unreadMessagesCount: Int = 0
    
    /// Progression dans la préparation marathon (feature non implémentée)
    @Published var marathonProgress: MarathonProgress?
    
    // MARK: - HealthKit Stats
    
    /// Rythme cardiaque actuel en BPM, `nil` si non disponible
    @Published var currentHeartRate: Double?
    
    /// Rythme cardiaque moyen de la session
    @Published var averageHeartRate: Double?
    
    /// Calories brûlées pendant la session
    @Published var currentCalories: Double?
    
    // MARK: - Services (Dependencies)
    
    private let realtimeService: RealtimeLocationService
    private let routeService = RouteTrackingService.shared
    private let healthKitManager = HealthKitManager.shared
    
    // MARK: - Private Properties
    
    /// Subscriptions Combine pour les flux de données
    private var cancellables = Set<AnyCancellable>()
    
    /// Tâche de rafraîchissement périodique des tracés des autres coureurs
    private var routeRefreshTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    override init() {
        self.realtimeService = RealtimeLocationService.shared
        super.init()
        bindOutputs()
        bindHealthKitOutputs()
        loadMockDataForNonBlockingUI()
    }
    
    // MARK: - Context & Lifecycle
    
    /// Configure le contexte de la squad pour le suivi en temps réel
    /// - Parameter squadId: Identifiant de la squad à surveiller
    func setContext(squadId: String) {
        Logger.log("🔧 SessionsViewModel context: \(squadId)", category: .session)
        realtimeService.setContext(squadId: squadId)
    }
    
    /// Démarre le suivi GPS de l'utilisateur
    func startLocationUpdates() {
        realtimeService.startLocationUpdates()
    }
    
    /// Demande un rafraîchissement de la position actuelle
    ///
    /// Utile pour centrer la carte sur l'utilisateur au démarrage.
    func centerOnUserLocation() {
        realtimeService.requestOneShotLocation()
    }
    
    // MARK: - Session Actions
    
    /// Termine la session active
    ///
    /// Cette méthode :
    /// 1. Arrête le tracking GPS
    /// 2. Arrête l'auto-save des routes
    /// 3. Arrête le monitoring HealthKit
    /// 4. Attend 2 secondes pour que toutes les écritures se terminent
    /// 5. Marque la session comme terminée dans Firebase
    /// 6. Annule les tâches de rafraîchissement
    ///
    /// - Throws: `SessionError` si la terminaison échoue
    func endSession() async throws {
        Logger.log("🔴 SessionsViewModel.endSession() appelé", category: .session)
        
        guard let session = activeSession else {
            Logger.log("⚠️ Aucune session active à terminer", category: .session)
            return
        }
        
        guard let sessionId = session.id else {
            Logger.log("❌ Session ID manquant, impossible de terminer", category: .session)
            throw SessionError.invalidSession
        }
        
        Logger.log("🛑 Arrêt de la session \(sessionId)...", category: .session)
        
        // ✅ FIX CRITIQUE: Arrêter TOUTES les écritures AVANT de terminer
        
        // 1. Arrêter le tracking GPS
        LocationProvider.shared.stopUpdating()
        Logger.log("✅ Tracking GPS arrêté", category: .session)
        
        // 2. Arrêter l'auto-save des routes (CRITIQUE !)
        routeService.stopAutoSave()
        Logger.log("✅ Auto-save routes arrêté", category: .session)
        
        // 3. Arrêter le monitoring HealthKit
        stopHealthKitMonitoring()
        Logger.log("✅ HealthKit arrêté", category: .session)
        
        // 4. Annuler le rafraîchissement des tracés
        routeRefreshTask?.cancel()
        Logger.log("✅ Tâches de rafraîchissement annulées", category: .session)
        
        // ✅ FIX: Attendre 2 secondes pour que toutes les écritures en cours se terminent
        Logger.log("⏳ Attente de 2 secondes pour finaliser les écritures...", category: .session)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        Logger.log("✅ Attente terminée", category: .session)
        
        // 5. Terminer la session dans Firebase (maintenant que tout est arrêté)
        do {
            try await SessionService.shared.endSession(sessionId: sessionId)
            Logger.logSuccess("✅ Session terminée dans Firebase", category: .session)
        } catch {
            Logger.logError(error, context: "SessionService.endSession", category: .session)
            throw error
        }
        
        Logger.logSuccess("✅✅ Session complètement terminée", category: .session)
    }
    
    // MARK: - Future Features (Stubs)
    
    /// Active/désactive le microphone pour le push-to-talk
    ///
    /// - Note: ⚠️ Fonctionnalité non implémentée (Phase 3)
    /// - SeeAlso: `FeatureFlags.voiceChat`
    func toggleMicrophone() {
        guard FeatureFlags.voiceChat else {
            Logger.log("⚠️ Voice chat désactivé (Feature Flag)", category: .audio)
            return
        }
        
        // TODO: Phase 3 - Implémenter le Push-to-Talk
        Logger.log("🎤 Microphone toggled", category: .audio)
    }
    
    /// Capture une photo pendant la course
    ///
    /// - Note: ⚠️ Fonctionnalité non implémentée (Phase 2)
    /// - SeeAlso: `FeatureFlags.photoSharing`
    func takePhoto() {
        guard FeatureFlags.photoSharing else {
            Logger.log("⚠️ Photo sharing désactivé (Feature Flag)", category: .general)
            return
        }
        
        // TODO: Phase 2 - Implémenter la capture photo et l'upload Firebase Storage
        Logger.log("📸 Take photo", category: .general)
    }
    
    /// Ouvre le chat de la session
    ///
    /// - Note: ⚠️ Fonctionnalité non implémentée (Phase 2)
    /// - SeeAlso: `FeatureFlags.textMessaging`
    func openMessages() {
        guard FeatureFlags.textMessaging else {
            Logger.log("⚠️ Text messaging désactivé (Feature Flag)", category: .general)
            return
        }
        
        // TODO: Phase 2 - Déclencher la navigation vers le chat de la session
        Logger.log("💬 Open messages", category: .general)
    }
    
    // MARK: - Internal Logic (Binding & Sync)
    
    /// Configure les liaisons entre les Services et les propriétés `@Published`
    ///
    /// Connecte :
    /// - `RealtimeLocationService` → `activeSession`, `runnerLocations`, `userLocation`
    /// - `RouteTrackingService` → `routeCoordinates`
    private func bindOutputs() {
        // 1. Gestion de la session active
        realtimeService.$activeSession
            .receive(on: RunLoop.main)
            .sink { [weak self] session in
                self?.activeSession = session
                if let sessionId = session?.id, let userId = AuthService.shared.currentUserId {
                    self?.setupActiveSessionProcess(sessionId: sessionId, userId: userId)
                } else {
                    self?.teardownActiveSessionProcess()
                }
            }
            .store(in: &cancellables)
            
        // 2. Positions des autres coureurs
        realtimeService.$runnerLocations
            .receive(on: RunLoop.main)
            .sink { [weak self] runners in
                self?.runnerLocations = runners
                self?.activeRunners = runners
            }
            .store(in: &cancellables)

        // 3. Ma position et mon tracé
        realtimeService.$userCoordinate
            .receive(on: RunLoop.main)
            .sink { [weak self] coord in
                guard let coord = coord else { return }
                self?.userLocation = coord
                self?.routeService.addRoutePoint(coord)
                self?.routeCoordinates = self?.routeService.getCurrentRoute() ?? []
            }
            .store(in: &cancellables)
    }

    /// Lie les statistiques HealthKit aux propriétés `@Published`
    private func bindHealthKitOutputs() {
        healthKitManager.$currentHeartRate.assign(to: &$currentHeartRate)
        healthKitManager.$currentCalories.assign(to: &$currentCalories)
    }
    
    // MARK: - Helper Methods
    
    /// Initialise tous les processus nécessaires quand une session démarre
    /// - Parameters:
    ///   - sessionId: ID de la session active
    ///   - userId: ID de l'utilisateur
    private func setupActiveSessionProcess(sessionId: String, userId: String) {
        routeService.startAutoSave(sessionId: sessionId, userId: userId)
        startHealthKitMonitoring(sessionId: sessionId)
        
        // Démarrer le rafraîchissement des tracés des autres toutes les 30s
        routeRefreshTask?.cancel()
        routeRefreshTask = Task {
            while !Task.isCancelled {
                await loadRunnerRoutes(sessionId: sessionId)
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 secondes
            }
        }
    }
    
    /// Nettoie tous les processus quand une session se termine
    private func teardownActiveSessionProcess() {
        routeService.stopAutoSave()
        stopHealthKitMonitoring()
        routeRefreshTask?.cancel()
    }

    /// Charge les tracés GPS de tous les coureurs de la session
    /// - Parameter sessionId: ID de la session
    private func loadRunnerRoutes(sessionId: String) async {
        do {
            let routes = try await routeService.loadAllRoutes(sessionId: sessionId)
            let currentUserId = AuthService.shared.currentUserId
            self.runnerRoutes = routes.filter { $0.key != currentUserId }
        } catch {
            Logger.logError(error, context: "loadRunnerRoutes")
        }
    }

    /// Démarre le monitoring HealthKit (BPM, calories, workout)
    /// - Parameter sessionId: ID de la session
    private func startHealthKitMonitoring(sessionId: String) {
        guard FeatureFlags.heartRateMonitoring else {
            Logger.log("⚠️ Heart rate monitoring désactivé (Feature Flag)", category: .health)
            return
        }
        
        Task {
            if !healthKitManager.isAuthorized {
                try? await healthKitManager.requestAuthorization()
            }
            healthKitManager.startHeartRateQuery(sessionId: sessionId)
            healthKitManager.startPeriodicStatsUpdate(sessionId: sessionId)
        }
    }

    /// Arrête tout le monitoring HealthKit
    private func stopHealthKitMonitoring() {
        guard FeatureFlags.heartRateMonitoring else { return }
        
        healthKitManager.stopHeartRateQuery()
        healthKitManager.stopWorkoutSession()
    }

    /// Charge des données de test pour ne pas bloquer le développement UI
    ///
    /// - Note: Cette méthode est temporaire et sera supprimée en production
    private func loadMockDataForNonBlockingUI() {
        // TODO: Supprimer en production
        marathonProgress = MarathonProgress(percentage: 0.67, daysRemaining: 8)
    }
}
