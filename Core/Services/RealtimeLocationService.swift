//
//  RealtimeLocationService.swift
//  RunningMan
//
//  Orchestration: observe session active + publie localisation + stream des runners
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class RealtimeLocationService: ObservableObject {
    
    static let shared = RealtimeLocationService(
        locationProvider: .shared,
        sessionService: .shared,
        repository: RealtimeLocationRepository(),
        membershipRepository: SquadMembershipRepository.shared
    )
    
    // Dépendances
    private let locationProvider: LocationProvider
    private let sessionService: SessionService
    private let repository: RealtimeLocationRepositoryProtocol
    private let membershipRepository: SquadMembershipRepositoryProtocol
    
    // État
    @Published private(set) var activeSession: SessionModel?
    @Published private(set) var runnerLocations: [RunnerLocation] = []
    @Published private(set) var userCoordinate: CLLocationCoordinate2D?
    
    // Internes
    private var locationTask: Task<Void, Never>?
    private var sessionStreamTask: Task<Void, Never>?
    private var runnersStreamTask: Task<Void, Never>?
    
    init(
        locationProvider: LocationProvider,
        sessionService: SessionService,
        repository: RealtimeLocationRepositoryProtocol,
        membershipRepository: SquadMembershipRepositoryProtocol
    ) {
        self.locationProvider = locationProvider
        self.sessionService = sessionService
        self.repository = repository
        self.membershipRepository = membershipRepository
    }
    
    // MARK: - Contexte
    
    func setContext(squadId: String) {
        Logger.log("[AUDIT-RLS-01] 🔧 RealtimeLocationService.setContext - squadId: \(squadId)", category: .location)
        membershipRepository.setCurrentSquadId(squadId)
        observeActiveSession(for: squadId)
        bindOwnLocation()
    }
    
    func clearContext() {
        membershipRepository.clear()
        cancelAllStreams()
        activeSession = nil
        runnerLocations = []
    }
    
    // MARK: - Public API
    
    func startLocationUpdates() {
        Logger.log("[AUDIT-RLS-02] 📍 RealtimeLocationService.startLocationUpdates appelé", category: .location)
        locationProvider.startUpdating()
    }
    
    func requestOneShotLocation() {
        Logger.log("[AUDIT-RLS-03] 🎯 RealtimeLocationService.requestOneShotLocation appelé", category: .location)
        locationProvider.requestOneShotLocation()
    }
    
    // MARK: - Private
    
    private func observeActiveSession(for squadId: String) {
        sessionStreamTask?.cancel()
        sessionStreamTask = Task { [weak self] in
            guard let self else { return }
            for await session in sessionService.observeActiveSession(squadId: squadId) {
                await MainActor.run {
                    self.activeSession = session
                }
                // (Re)brancher l’observation des runners selon la session
                if let sessionId = session?.id {
                    observeRunnerLocations(sessionId: sessionId)
                } else {
                    runnersStreamTask?.cancel()
                    await MainActor.run {
                        self.runnerLocations = []
                    }
                }
            }
        }
    }
    
    private func observeRunnerLocations(sessionId: String) {
        runnersStreamTask?.cancel()
        runnersStreamTask = Task { [weak self] in
            guard let self else { return }
            for await runners in repository.observeRunnerLocations(sessionId: sessionId) {
                await MainActor.run {
                    self.runnerLocations = runners
                }
            }
        }
    }
    
    private func bindOwnLocation() {
        locationTask?.cancel()
        locationTask = Task { [weak self] in
            guard let self else { return }
            // Observe les changements de position via Published
            for await _ in self.locationProvider.$currentCoordinate.values {
                let coord = self.locationProvider.currentCoordinate
                
                Logger.log("[AUDIT-LIVE-03] 🔄 LocationProvider.currentCoordinate changé → \(coord.map { "lat: \($0.latitude), lon: \($0.longitude)" } ?? "nil")", category: .location)
                
                await MainActor.run {
                    self.userCoordinate = coord
                    Logger.log("[AUDIT-LIVE-04] 📌 userCoordinate publié → \(coord.map { "lat: \($0.latitude), lon: \($0.longitude)" } ?? "nil")", category: .location)
                }
                
                // Publier la position si session active et userId disponible
                guard
                    let sessionId = self.activeSession?.id,
                    let userId = AuthService.shared.currentUserId,
                    let coord = coord
                else { 
                    Logger.log("[AUDIT-LIVE-05] ⚠️ Pas de publication Firestore (session: \(self.activeSession?.id ?? "nil"), userId: \(AuthService.shared.currentUserId ?? "nil"), coord: \(coord != nil))", category: .location)
                    continue 
                }
                
                do {
                    try await self.repository.publishLocation(sessionId: sessionId, userId: userId, coordinate: coord)
                    Logger.log("[AUDIT-LIVE-06] ✅ Position publiée dans Firestore", category: .location)
                } catch {
                    Logger.logError(error, context: "publishLocation", category: .location)
                }
            }
        }
    }
    
    private func cancelAllStreams() {
        sessionStreamTask?.cancel()
        runnersStreamTask?.cancel()
        locationTask?.cancel()
    }
}

