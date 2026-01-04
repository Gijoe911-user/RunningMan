//
//  SessionTrackingViewModel.swift
//  RunningMan
//
//  ViewModel consolidé pour gérer le cycle de vie des sessions
//  🎯 Gère le tracking individuel, le support multi-sessions et l'historique
// 3.1.2026

import Foundation
import CoreLocation
import Combine

@MainActor
class SessionTrackingViewModel: ObservableObject {
    
    // MARK: - Published Properties (Observées par la Vue)
    
    // État du tracking (lié au Manager)
    @Published var trackingState: TrackingState = .idle
    @Published var trackingDistance: Double = 0
    @Published var trackingDuration: TimeInterval = 0
    @Published var trackingSpeed: Double = 0
    
    // Données des sessions (liées au Service)
    @Published var myActiveTrackingSession: SessionModel?
    @Published var allActiveSessions: [SessionModel] = []
    @Published var supporterSessions: [SessionModel] = []
    @Published var recentHistory: [SessionModel] = [] // 🆕 Pour AllSessionsViewUnified
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 🆕 Propriété calculée pour vérifier si on peut démarrer
    var canStartTracking: Bool {
        trackingState == .idle
    }
    
    // MARK: - Dependencies
    
    private let trackingManager = TrackingManager.shared
    private let sessionService = SessionService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupSubscribers()
        refreshData()
    }
    
    // MARK: - Setup (Le "Pont" entre le Manager et l'UI)
    
    private func setupSubscribers() {
        // On écoute le TrackingManager et on répercute les changements sur l'UI
        trackingManager.$trackingState
            .assign(to: &$trackingState)
        
        trackingManager.$currentDistance
            .assign(to: &$trackingDistance)
        
        trackingManager.$currentDuration
            .assign(to: &$trackingDuration)
        
        trackingManager.$currentSpeed
            .assign(to: &$trackingSpeed)
            
        trackingManager.$activeTrackingSession
            .assign(to: &$myActiveTrackingSession)
    }
    
    // MARK: - Actions de Session
    
    /// Rafraîchit la liste des sessions disponibles dans les squads
    func refreshData() {
        Logger.log("[AUDIT-STVM-01] 🔄 SessionTrackingViewModel.refreshData appelé", category: .service)
        guard let userId = authService.currentUserId else { return }
        isLoading = true
        
        Task {
            do {
                // On récupère toutes les sessions actives via le service
                let sessions = try await sessionService.getAllActiveSessions(userId: userId)
                
                await MainActor.run {
                    self.allActiveSessions = sessions
                    // On filtre celles où on est supporter mais pas le créateur/runner actif
                    self.supporterSessions = sessions.filter {
                        $0.participants.contains(userId) && $0.id != myActiveTrackingSession?.id
                    }
                    self.isLoading = false
                }
            } catch {
                self.errorMessage = "Erreur de chargement des sessions"
                self.isLoading = false
            }
        }
    }
    
    /// 🆕 Alias pour AllSessionsViewUnified
    func loadAllActiveSessions() {
        Logger.log("[AUDIT-STVM-02] 📋 SessionTrackingViewModel.loadAllActiveSessions appelé", category: .service)
        refreshData()
    }
    
    /// Démarre le tracking pour une session donnée
    func startTracking(for session: SessionModel) async -> Bool {
        guard trackingState == .idle else {
            self.errorMessage = "Un tracking est déjà en cours"
            return false
        }
        
        return await trackingManager.startTracking(for: session)
    }
    
    /// Arrête le tracking
    func stopTracking() async {
        do {
            try await trackingManager.stopTracking()
            refreshData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// Rejoindre en tant que simple supporter
    func joinAsSupporter(sessionId: String) async {
        Logger.log("[AUDIT-STVM-03] 🤝 SessionTrackingViewModel.joinAsSupporter appelé - sessionId: \(sessionId)", category: .service)
        guard let userId = authService.currentUserId else { return }
        do {
            try await sessionService.joinSession(sessionId: sessionId, userId: userId)
            refreshData()
        } catch {
            self.errorMessage = "Impossible de rejoindre la session"
        }
    }
    
    /// 🆕 Alias pour AllSessionsViewUnified
    func joinSessionAsSupporter(sessionId: String) async {
        Logger.log("[AUDIT-STVM-04] 🤝 SessionTrackingViewModel.joinSessionAsSupporter (alias) appelé", category: .service)
        await joinAsSupporter(sessionId: sessionId)
    }
    
    // MARK: - Formatters
    
    var formattedDistance: String {
        String(format: "%.2f km", trackingDistance / 1000)
    }
    
    var formattedDuration: String {
        let h = Int(trackingDuration) / 3600
        let m = (Int(trackingDuration) % 3600) / 60
        let s = Int(trackingDuration) % 60
        return h > 0 ? String(format: "%02d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}
