//
//  SessionTrackingViewModel.swift
//  RunningMan
//
//  ViewModel consolidé pour gérer le cycle de vie des sessions
//  🎯 Gère le tracking individuel, le support multi-sessions et l'historique
//

import Foundation
import CoreLocation
import Combine

@MainActor
class SessionTrackingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Session active de l'utilisateur (Tracking GPS en cours)
    @Published var myActiveTrackingSession: SessionModel?
    
    /// Sessions suivies en tant que spectateur
    @Published var supporterSessions: [SessionModel] = []
    
    /// Flux global des sessions actives dans les squads de l'utilisateur
    @Published var allActiveSessions: [SessionModel] = []
    
    /// NOUVEAU : Historique récent (issu de la V1) pour affichage global
    @Published var recentHistory: [SessionModel] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Stats de tracking temps réel liées au TrackingManager
    @Published var trackingDistance: Double = 0
    @Published var trackingDuration: TimeInterval = 0
    @Published var trackingSpeed: Double = 0
    @Published var trackingState: TrackingState = .idle
    
    // MARK: - Services
    
    private let trackingManager = TrackingManager.shared
    private let sessionService = SessionService.shared
    private let authService = AuthService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var canStartTracking: Bool { trackingManager.canStartTracking }
    private var currentUserId: String? { authService.currentUserId }
    
    // MARK: - Initialization
    
    init() {
        Logger.log("📱 SessionTrackingViewModel initialisé avec support Historique", category: .session)
        bindTrackingManager()
    }
    
    // MARK: - Bindings (Flux réactifs)
    
    private func bindTrackingManager() {
        // Synchronisation des stats et de l'état depuis le Manager unique
        Task {
            for await session in trackingManager.$activeTrackingSession.values {
                self.myActiveTrackingSession = session
            }
        }
        
        Task {
            for await state in trackingManager.$trackingState.values {
                self.trackingState = state
            }
        }
        
        Task {
            for await distance in trackingManager.$currentDistance.values {
                self.trackingDistance = distance
            }
        }
        
        Task {
            for await duration in trackingManager.$currentDuration.values {
                self.trackingDuration = duration
            }
        }
    }
    
    // MARK: - Core Logic (Load Data)
    
    /// Charge les sessions actives ET l'historique de manière asynchrone parallélisée
    func loadAllActiveSessions(squadIds: [String]) async {
        guard let userId = currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Utilisation d'un TaskGroup pour ne pas bloquer l'UI et charger plus vite
        await withTaskGroup(of: Void.self) { group in
            
            // Task 1 : Récupération des sessions LIVE (V2)
            group.addTask {
                var allSessions: [SessionModel] = []
                for squadId in squadIds {
                    if let sessions = try? await self.sessionService.getActiveSessions(squadId: squadId) {
                        allSessions.append(contentsOf: sessions)
                    }
                }
                
                let sessions = allSessions
                await MainActor.run {
                    self.allActiveSessions = sessions
                    self.updateSupporterList(allSessions: sessions, userId: userId)
                }
            }
            
            // Task 2 : Récupération de l'HISTORIQUE (V1 intégrée)
            group.addTask {
                var history: [SessionModel] = []
                for squadId in squadIds {
                    if let squadHistory = try? await self.sessionService.getSessionHistory(squadId: squadId, limit: 5) {
                        history.append(contentsOf: squadHistory)
                    }
                }
                let sortedHistory = history.sorted { ($0.endedAt ?? Date()) > ($1.endedAt ?? Date()) }
                await MainActor.run { self.recentHistory = sortedHistory }
            }
        }
        
        isLoading = false
    }
    
    private func updateSupporterList(allSessions: [SessionModel], userId: String) {
        if let trackingId = trackingManager.activeTrackingSession?.id {
            self.supporterSessions = allSessions.filter {
                $0.id != trackingId && $0.participants.contains(userId)
            }
        } else {
            self.supporterSessions = allSessions.filter { $0.participants.contains(userId) }
        }
    }
    
    // MARK: - Actions (Tracking & Support)
    
    func startTracking(for session: SessionModel) async -> Bool {
        guard canStartTracking else {
            errorMessage = "Un tracking est déjà en cours"
            return false
        }
        
        let success = await trackingManager.startTracking(for: session)
        if success {
            self.myActiveTrackingSession = session
        }
        return success
    }
    
    func stopTracking() async -> Bool {
        do {
            try await trackingManager.stopTracking()
            self.myActiveTrackingSession = nil
            // Ici, on pourrait déclencher un rafraîchissement de la Gamification (Indice de consistance)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func joinSessionAsSupporter(sessionId: String) async -> Bool {
        guard let userId = currentUserId else { return false }
        do {
            try await sessionService.joinSession(sessionId: sessionId, userId: userId)
            return true
        } catch {
            errorMessage = "Impossible de rejoindre"
            return false
        }
    }
    
    // MARK: - Formatters
    
    func formattedDistance(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1000)
    }
    
    func formattedDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return h > 0 ? String(format: "%02d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}
