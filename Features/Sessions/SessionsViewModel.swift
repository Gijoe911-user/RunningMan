//
//  SessionsViewModel.swift
//  RunningMan
//
//  ViewModel pour gérer la logique de la vue Sessions (version temps réel)
//

import Foundation
import CoreLocation
import Combine

// MARK: - Supporting Types
struct MarathonProgress {
    let percentage: Double
    let daysRemaining: Int
}

@MainActor
class SessionsViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var activeSession: SessionModel?
    @Published var runnerLocations: [RunnerLocation] = []
    @Published var activeRunners: [RunnerLocation] = [] // compat UI existante
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = [] // Tracé GPS
    @Published var unreadMessagesCount: Int = 0
    @Published var marathonProgress: MarathonProgress?
    
    // MARK: - Services
    private let realtimeService: RealtimeLocationService
    private let routeService = RouteTrackingService.shared
    
    // MARK: - Subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        self.realtimeService = RealtimeLocationService.shared
        super.init()
        bindOutputs()
        loadMockDataForNonBlockingUI()
    }
    
    // MARK: - Context
    func setContext(squadId: String) {
        Logger.log("🔧 SessionsViewModel.setContext appelé avec squadId: \(squadId)", category: .session)
        realtimeService.setContext(squadId: squadId)
    }
    
    // MARK: - Location Management (proxys vers LocationProvider via service)
    func startLocationUpdates() {
        realtimeService.startLocationUpdates()
    }
    
    func centerOnUserLocation() {
        realtimeService.requestOneShotLocation()
    }
    
    func zoomIn() {
        // TODO: Implémenter zoom via Map region (piloté par la vue)
    }
    
    func zoomOut() {
        // TODO: Implémenter zoom via Map region (piloté par la vue)
    }
    
    // MARK: - Session Actions
    
    /// Termine la session active
    func endSession() async throws {
        guard let session = activeSession,
              let sessionId = session.id else {
            Logger.log("❌ Impossible de terminer la session: pas de session active", category: .session)
            throw SessionError.sessionNotFound
        }
        
        guard let userId = AuthService.shared.currentUserId else {
            Logger.log("❌ Utilisateur non connecté", category: .session)
            throw SessionError.notAuthorized
        }
        
        // Vérifier que l'utilisateur est le créateur
        guard session.creatorId == userId else {
            Logger.log("❌ Seul le créateur peut terminer la session", category: .session)
            throw SessionError.notAuthorized
        }
        
        Logger.log("🛑 Fin de la session \(sessionId)...", category: .session)
        
        // Arrêter le tracking de localisation (via LocationProvider)
        LocationProvider.shared.stopUpdating()
        
        // Terminer la session dans Firestore
        try await SessionService.shared.endSession(sessionId: sessionId)
        
        Logger.logSuccess("✅ Session terminée avec succès", category: .session)
        
        // La session sera automatiquement mise à nil via le listener
    }
    
    // MARK: - Communication Actions
    func toggleMicrophone() {
        // TODO: Phase 2 - Implémenter Push-to-Talk
        Logger.log("Microphone toggled", category: .audio)
    }
    
    func takePhoto() {
        // TODO: Implémenter capture photo
        Logger.log("Take photo", category: .general)
    }
    
    func openMessages() {
        // TODO: Navigation vers messages
        Logger.log("Open messages", category: .general)
    }
    
    // MARK: - Bind outputs from service
    private func bindOutputs() {
        realtimeService.$activeSession
            .receive(on: RunLoop.main)
            .sink { [weak self] session in
                Logger.log("📥 SessionsViewModel reçoit session: \(session?.id ?? "nil")", category: .session)
                self?.activeSession = session
            }
            .store(in: &cancellables)
        
        realtimeService.$runnerLocations
            .receive(on: RunLoop.main)
            .sink { [weak self] runners in
                Logger.log("👥 SessionsViewModel reçoit \(runners.count) runners", category: .location)
                self?.runnerLocations = runners
                self?.activeRunners = runners // compat UI existante
            }
            .store(in: &cancellables)
        
        realtimeService.$userCoordinate
            .receive(on: RunLoop.main)
            .sink { [weak self] coord in
                if let coord = coord {
                    Logger.log("📍 SessionsViewModel reçoit position: \(coord.latitude), \(coord.longitude)", category: .location)
                    
                    // Ajouter au tracé
                    self?.routeService.addRoutePoint(coord)
                    self?.routeCoordinates = self?.routeService.getCurrentRoute() ?? []
                }
                self?.userLocation = coord
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mock Data (temporaire, pour ne pas casser l’UI si pas de session)
    private func loadMockDataForNonBlockingUI() {
        // On ne remplit que les infos non critiques pour éviter les écrans vides si pas de session
        marathonProgress = MarathonProgress(percentage: 0.67, daysRemaining: 8)
        unreadMessagesCount = 0
    }
}

