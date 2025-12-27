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
    @Published var unreadMessagesCount: Int = 0
    @Published var marathonProgress: MarathonProgress?
    
    // MARK: - Services
    private let realtimeService: RealtimeLocationService
    
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
                self?.activeSession = session
            }
            .store(in: &cancellables)
        
        realtimeService.$runnerLocations
            .receive(on: RunLoop.main)
            .sink { [weak self] runners in
                self?.runnerLocations = runners
                self?.activeRunners = runners // compat UI existante
            }
            .store(in: &cancellables)
        
        realtimeService.$userCoordinate
            .receive(on: RunLoop.main)
            .sink { [weak self] coord in
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

