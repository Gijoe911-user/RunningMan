//
//  ActiveSessionDetailView.swift
//  RunningMan
//
//  Vue détaillée pour une session active avec stats en temps réel
//

import SwiftUI
import MapKit
import Combine

struct ActiveSessionDetailView: View {
    let session: SessionModel
    @StateObject private var viewModel = ActiveSessionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEndConfirmation = false
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Carte avec positions
                mapSection
                    .frame(height: 400)
                
                // Stats et participants
                statsSection
            }
        }
        .navigationTitle("Session en cours")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canEndSession {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEndConfirmation = true
                    } label: {
                        Text("Terminer")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .alert("Terminer la session ?", isPresented: $showEndConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Terminer", role: .destructive) {
                Task {
                    await endSession()
                }
            }
        } message: {
            Text("Cette action mettra fin à la session pour tous les participants.")
        }
        .task {
            await viewModel.startObserving(sessionId: session.id ?? "")
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        EnhancedSessionMapView(
            userLocation: viewModel.userLocation,
            runnerLocations: viewModel.runnerLocations
        )
        .overlay(alignment: .topTrailing) {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("En direct")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding()
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session info card
                sessionInfoCard
                
                // Live stats
                liveStatsGrid
                
                // Participants with real-time stats
                participantsSection
            }
            .padding()
        }
    }
    
    private var sessionInfoCard: some View {
        VStack(spacing: 12) {
            // Type et durée
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.activityType.displayName)
                        .font(.caption)
                        .foregroundColor(.coralAccent)
                    
                    Text("Session active")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("DURÉE")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatDuration())
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
            }
            
            // Progression
            if let targetDistance = session.targetDistanceMeters {
                ProgressView(value: session.totalDistanceMeters, total: targetDistance)
                    .tint(.coralAccent)
                
                HStack {
                    Text("\(String(format: "%.2f", session.distanceInKilometers)) km")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Objectif: \(String(format: "%.2f", targetDistance / 1000)) km")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var liveStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            LiveStatCard(
                icon: "location.fill",
                title: "Distance",
                value: String(format: "%.2f km", session.distanceInKilometers),
                color: .coralAccent
            )
            
            LiveStatCard(
                icon: "speedometer",
                title: "Allure moy.",
                value: session.averagePaceMinPerKm,
                color: .pinkAccent
            )
            
            LiveStatCard(
                icon: "flame.fill",
                title: "Vitesse moy.",
                value: String(format: "%.1f km/h", session.averageSpeedKmh),
                color: .orange
            )
            
            LiveStatCard(
                icon: "figure.run",
                title: "Coureurs",
                value: "\(session.participants.count)",
                color: .green
            )
        }
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants actifs")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(viewModel.runnerLocations) { runner in
                ParticipantStatsCard(runner: runner)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canEndSession: Bool {
        guard let userId = AuthService.shared.currentUserId else { return false }
        return session.creatorId == userId
    }
    
    // MARK: - Actions
    
    private func endSession() async {
        guard let sessionId = session.id else { return }
        
        do {
            try await SessionService.shared.endSession(sessionId: sessionId)
            dismiss()
        } catch {
            print("Error ending session: \(error)")
        }
    }
    
    private func formatDuration() -> String {
        let duration = Date().timeIntervalSince(session.startedAt)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Live Stat Card

struct LiveStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Participant Stats Card

struct ParticipantStatsCard: View {
    let runner: RunnerLocation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let photoURL = runner.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.coralAccent.opacity(0.3))
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(.coralAccent)
                        }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.coralAccent.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.coralAccent)
                    }
            }
            
            // Nom et position
            VStack(alignment: .leading, spacing: 4) {
                Text(runner.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label {
                        Text("Position mise à jour")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    } icon: {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.coralAccent)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Active Session ViewModel

@MainActor
class ActiveSessionViewModel: ObservableObject {
    @Published var runnerLocations: [RunnerLocation] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var centerOnUserTrigger: Bool = false
    @Published var currentSession: SessionModel?
    
    private let realtimeService = RealtimeLocationService.shared
    private let routeService = RouteTrackingService.shared
    private let sessionService = SessionService.shared
    private var cancellables = Set<AnyCancellable>()
    private var sessionId: String?
    private var sessionObservationTask: Task<Void, Never>?
    
    func startObserving(sessionId: String) async {
        self.sessionId = sessionId
        
        Logger.log("🎬 Démarrage observation session: \(sessionId)", category: .location)
        
        // 1. Observer les mises à jour de la session elle-même
        observeSessionUpdates(sessionId: sessionId)
        
        // 2. Bind les positions des coureurs depuis le service temps réel
        realtimeService.$runnerLocations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] runners in
                self?.runnerLocations = runners
                Logger.log("👥 Coureurs reçus: \(runners.count)", category: .location)
            }
            .store(in: &cancellables)
        
        // 3. Bind la position de l'utilisateur
        realtimeService.$userCoordinate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinate in
                self?.userLocation = coordinate
                
                // Ajouter au tracé si coordinate existe
                if let coordinate = coordinate {
                    self?.routeService.addRoutePoint(coordinate)
                    self?.routeCoordinates = self?.routeService.getCurrentRoute() ?? []
                    
                    // Logger moins verbeux
                    if let count = self?.routeCoordinates.count, count % 10 == 0 {
                        Logger.log("📍 Route: \(count) points", category: .location)
                    }
                }
            }
            .store(in: &cancellables)
        
        // 4. Démarrer les mises à jour de localisation
        realtimeService.startLocationUpdates()
        
        // 5. S'assurer que la session active est observée
        if let session = realtimeService.activeSession {
            Logger.log("✅ Session active déjà détectée: \(session.id ?? "unknown")", category: .location)
        } else {
            Logger.log("⚠️ Aucune session active détectée, tentative de démarrage manuel", category: .location)
            // Démarrer l'observation manuelle pour cette session
            await startManualLocationTracking(sessionId: sessionId)
        }
        
        Logger.logSuccess("🎯 Observation session démarrée", category: .location)
    }
    
    private func observeSessionUpdates(sessionId: String) {
        sessionObservationTask?.cancel()
        sessionObservationTask = Task { [weak self] in
            guard let self else { return }
            
            for await session in sessionService.observeSession(sessionId: sessionId) {
                await MainActor.run {
                    if let session = session {
                        self.currentSession = session
                        Logger.log("🔄 Session mise à jour: distance=\(session.totalDistanceMeters)m", category: .service)
                    }
                }
            }
        }
    }
    
    private func startManualLocationTracking(sessionId: String) async {
        // Publier la position actuelle immédiatement
        guard let userId = AuthService.shared.currentUserId,
              let coordinate = realtimeService.userCoordinate else {
            Logger.log("⚠️ Impossible de publier la position: userId ou coordinate manquant", category: .location)
            return
        }
        
        do {
            let repository = RealtimeLocationRepository()
            try await repository.publishLocation(sessionId: sessionId, userId: userId, coordinate: coordinate)
            Logger.logSuccess("📍 Position initiale publiée", category: .location)
        } catch {
            Logger.logError(error, context: "startManualLocationTracking", category: .location)
        }
    }
    
    func stopObserving() {
        cancellables.removeAll()
        sessionObservationTask?.cancel()
        
        // Sauvegarder le tracé si disponible
        if let sessionId = sessionId,
           let userId = AuthService.shared.currentUserId,
           !routeCoordinates.isEmpty {
            Task {
                do {
                    try await routeService.saveRoute(sessionId: sessionId, userId: userId)
                    Logger.logSuccess("💾 Tracé sauvegardé automatiquement", category: .location)
                } catch {
                    Logger.logError(error, context: "saveRoute on stop", category: .location)
                }
            }
        }
        
        Logger.log("🛑 Observation arrêtée", category: .location)
    }
    
    func centerOnUser() {
        centerOnUserTrigger.toggle()
        Logger.log("🎯 Recentrage sur l'utilisateur", category: .location)
    }
    
    func exportRouteAsGPX() async -> URL? {
        guard !routeCoordinates.isEmpty else {
            Logger.log("⚠️ Aucun tracé à exporter", category: .location)
            return nil
        }
        
        do {
            let sessionName = sessionId ?? "Session"
            let fileURL = try routeService.saveGPXToFile(route: routeCoordinates, sessionName: sessionName)
            Logger.logSuccess("✅ GPX exporté: \(fileURL.lastPathComponent)", category: .location)
            return fileURL
        } catch {
            Logger.logError(error, context: "exportRouteAsGPX", category: .location)
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActiveSessionDetailView(session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            startedAt: Date().addingTimeInterval(-1800),
            participants: ["user1", "user2"],
            totalDistanceMeters: 3500,
            durationSeconds: 1800,
            averageSpeed: 2.5,
            targetDistanceMeters: 5000
        ))
    }
    .preferredColorScheme(.dark)
}
