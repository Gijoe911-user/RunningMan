//
//  SessionDetailView.swift
//  RunningMan
//
//  Vue de détail d'une session avec carte enrichie, KPI live et actions (rejoindre/terminer)
//

import SwiftUI
import MapKit
import FirebaseFirestore
import Combine

struct SessionDetailView: View {
    let session: SessionModel
    
    @Environment(\.dismiss) private var dismiss
    
    // Services unifiés
    @StateObject private var realtimeService = RealtimeLocationService.shared
    @StateObject private var trackingManager = TrackingManager.shared
    private let routeHistoryService = RouteHistoryService.shared
    private let sessionService = SessionService.shared
    
    // Carte enrichie
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var runnerLocations: [RunnerLocation] = []
    @State private var userRouteCoordinates: [CLLocationCoordinate2D] = []
    @State private var runnerRoutes: [String: [CLLocationCoordinate2D]] = [:]
    
    // UI
    @State private var showEndSessionConfirmation = false
    @State private var isJoining = false
    @State private var isLoadingRoutes = false
    @State private var squadName: String = "Session"
    @State private var showAlreadyTrackingAlert = false  // 🆕 Alerte si déjà en tracking
    
    // KPI Live (agrégées à partir de participantStats)
    @State private var liveDistance: Double = 0          // en mètres (moyenne/total selon besoin)
    @State private var liveAvgSpeed: Double = 0          // m/s
    @State private var liveCalories: Double = 0
    @State private var liveHeartRate: Double = 0
    
    // Listeners
    @State private var participantStatsListener: ListenerRegistration?
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Carte enrichie
                mapSection
                    .frame(height: 420)
                
                // Contenu
                ScrollView {
                    VStack(spacing: 20) {
                        // KPI live
                        liveStatsGrid
                        
                        // Actions "Rejoindre" si applicable
                        if showJoinButton {
                            joinButton
                        }
                        
                        // Participants
                        participantsSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(squadName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if canEndSession {
                    Button {
                        showEndSessionConfirmation = true
                    } label: {
                        Text("Terminer")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .alert("Terminer la session ?", isPresented: $showEndSessionConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Terminer", role: .destructive) {
                endSession()
            }
        } message: {
            Text("Cette action mettra fin à la session pour tous les participants.")
        }
        .alert("Tracking déjà actif", isPresented: $showAlreadyTrackingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Vous trackez déjà une autre session. Terminez-la avant de rejoindre celle-ci.")
        }
        .task {
            await loadInitialData()
            await startRealtimeBindings()
            await loadAllParticipantsRoutes()
            startParticipantStatsListener()
        }
        .onDisappear {
            stopParticipantStatsListener()
            // On n’arrête pas le tracking ici (peut continuer en arrière-plan)
        }
    }
    
    // MARK: - Map Section (EnhancedSessionMapView)
    
    private var mapSection: some View {
        ZStack(alignment: .bottom) {
            EnhancedSessionMapView(
                userLocation: userLocation,
                runnerLocations: runnerLocations,
                routeCoordinates: userRouteCoordinates,
                runnerRoutes: runnerRoutes,
                onRecenter: {
                    // Rien de spécial à faire côté vue, le service publie déjà
                },
                onSaveRoute: {
                    Task { await exportCurrentRoute() }
                },
                onRunnerTapped: { runnerId in
                    // Optionnel: centrer sur un coureur (disponible via méthode centerOnRunner)
                }
            )
            .onReceive(realtimeService.$userCoordinate) { newValue in
                userLocation = newValue
            }
            .onReceive(realtimeService.$runnerLocations) { newValue in
                runnerLocations = newValue
            }
            
            // 🎯 OVERLAY : Contrôles de tracking en bas de la carte
            if showTrackingControls {
                trackingControlsOverlay
                    .padding()
            }
        }
    }
    
    // MARK: - Live KPI
    
    private var liveStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            LiveStatCard(
                icon: "location.fill",
                title: "Distance",
                value: liveDistance.formattedDistanceKm,
                color: Color.coralAccent
            )
            LiveStatCard(
                icon: "speedometer",
                title: "Allure moy.",
                value: liveAvgSpeed.formattedPaceMinKm,
                color: Color.pinkAccent
            )
            LiveStatCard(
                icon: "flame.fill",
                title: "Calories",
                value: String(format: "%.0f kcal", liveCalories),
                color: Color.yellowAccent
            )
            LiveStatCard(
                icon: "heart.fill",
                title: "FC",
                value: liveHeartRate > 0 ? "\(Int(liveHeartRate)) bpm" : "--",
                color: Color.red
            )
        }
    }
    
    // MARK: - Participants Section
    
    // MARK: - Tracking Controls
    
    /// Contrôles de tracking compacts en overlay sur la carte
    private var trackingControlsOverlay: some View {
        HStack(spacing: 12) {
            // Indicateur d'état
            HStack(spacing: 6) {
                Circle()
                    .fill(trackingStateColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: trackingStateColor.opacity(0.5), radius: 4)
                
                Text(trackingStateLabel)
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Boutons selon l'état
            trackingActionButtons
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    /// Couleur selon l'état du tracking
    private var trackingStateColor: Color {
        switch trackingManager.trackingState {
        case .idle:
            return .gray
        case .active:
            return .green
        case .paused:
            return .orange
        case .stopping:
            return .red
        }
    }
    
    /// Label selon l'état du tracking
    private var trackingStateLabel: String {
        switch trackingManager.trackingState {
        case .idle:
            return "Prêt"
        case .active:
            return "En cours"
        case .paused:
            return "Pause"
        case .stopping:
            return "Arrêt..."
        }
    }
    
    /// Boutons d'action selon l'état
    @ViewBuilder
    private var trackingActionButtons: some View {
        switch trackingManager.trackingState {
        case .idle:
            // Démarrer
            Button {
                Task {
                    Logger.log("[AUDIT-SDV-CTRL-01] ▶️ Démarrage tracking demandé", category: .session)
                    let started = await trackingManager.startTracking(for: session)
                    if started {
                        Logger.logSuccess("[AUDIT-SDV-CTRL-02] ✅ Tracking démarré", category: .session)
                    } else {
                        Logger.log("[AUDIT-SDV-CTRL-03] ⚠️ Échec démarrage tracking", category: .session)
                    }
                }
            } label: {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.green)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    )
            }
            
        case .active:
            // Pause + Stop
            HStack(spacing: 8) {
                Button {
                    Task {
                        Logger.log("[AUDIT-SDV-CTRL-04] ⏸️ Pause tracking demandée", category: .session)
                        await trackingManager.pauseTracking()
                        Logger.logSuccess("[AUDIT-SDV-CTRL-05] ✅ Tracking en pause", category: .session)
                    }
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.orange)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        )
                }
                
                Button {
                    Task {
                        Logger.log("[AUDIT-SDV-CTRL-08] ⏹️ Arrêt tracking demandé", category: .session)
                        do {
                            try await trackingManager.stopTracking()
                            Logger.logSuccess("[AUDIT-SDV-CTRL-09] ✅ Tracking arrêté", category: .session)
                        } catch {
                            Logger.logError(error, context: "stopTracking", category: .session)
                        }
                    }
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.red)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        )
                }
            }
            
        case .paused:
            // Reprendre + Stop
            HStack(spacing: 8) {
                Button {
                    Task {
                        Logger.log("[AUDIT-SDV-CTRL-06] ▶️ Reprise tracking demandée", category: .session)
                        await trackingManager.resumeTracking()
                        Logger.logSuccess("[AUDIT-SDV-CTRL-07] ✅ Tracking repris", category: .session)
                    }
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.green)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        )
                }
                
                Button {
                    Task {
                        Logger.log("[AUDIT-SDV-CTRL-08] ⏹️ Arrêt tracking demandé", category: .session)
                        do {
                            try await trackingManager.stopTracking()
                            Logger.logSuccess("[AUDIT-SDV-CTRL-09] ✅ Tracking arrêté", category: .session)
                        } catch {
                            Logger.logError(error, context: "stopTracking", category: .session)
                        }
                    }
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.red)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        )
                }
            }
            
        case .stopping:
            // Spinner
            ProgressView()
                .tint(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                )
        }
    }
    
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants (\(session.participants.count))")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(session.participants, id: \.self) { userId in
                ParticipantRow(
                    sessionId: session.id ?? "",
                    userId: userId,
                    isSelected: false,
                    onTap: {
                        // Centrer la carte sur ce coureur
                        if let runner = runnerLocations.first(where: { $0.id == userId }) {
                            // Création d’une région via EnhancedSessionMapView.centerOnRunner si besoin
                            // Ici, on laisse le contrôle aux boutons de la carte
                            // mais on pourrait exposer un Binding/closure pour centrer
                            print("Center on runner \(runner.displayName)")
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Join Button
    
    private var joinButton: some View {
        Button {
            Task { await joinAndStartTracking() }
        } label: {
            HStack {
                if isJoining {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "person.badge.plus")
                    Text("Rejoindre et démarrer le tracking")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(colors: [.coralAccent, .pinkAccent], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isJoining)
    }
    
    // MARK: - Computed Properties
    
    /// Affiche les contrôles de tracking si l'utilisateur participe ET track cette session
    private var showTrackingControls: Bool {
        guard let userId = AuthService.shared.currentUserId else { return false }
        
        // Vérifier si on est participant
        let isParticipant = session.participants.contains(userId)
        
        // Vérifier si on track cette session
        let isTrackingThisSession = trackingManager.activeTrackingSession?.id == session.id
        
        return isParticipant && isTrackingThisSession
    }
    
    private var canEndSession: Bool {
        guard let userId = AuthService.shared.currentUserId else {
            Logger.log("[AUDIT-SDV-BTN-01] ⚠️ canEndSession = false (pas de userId)", category: .session)
            return false
        }
        
        let isCreator = session.creatorId == userId
        
        // 🎯 FIX UI BUG : Vérifier l'état du TrackingManager DIRECTEMENT
        // Ne pas se fier au statut Firestore qui peut être désynchronisé
        let isTrackingActive = trackingManager.trackingState == .active || trackingManager.trackingState == .paused
        let isTrackingThisSession = trackingManager.activeTrackingSession?.id == session.id
        
        // Fallback sur le statut Firestore si pas de tracking actif
        let isActiveOrPaused = session.status == .active || session.status == .paused
        
        let result = isCreator && ((isTrackingActive && isTrackingThisSession) || isActiveOrPaused)
        
        Logger.log("[AUDIT-SDV-BTN-02] 🔍 canEndSession = \(result) (creatorId: \(session.creatorId), userId: \(userId), isCreator: \(isCreator), trackingState: \(trackingManager.trackingState.displayName), firestoreStatus: \(session.status.rawValue), isTrackingThisSession: \(isTrackingThisSession))", category: .session)
        
        return result
    }
    
    private var showJoinButton: Bool {
        guard let userId = AuthService.shared.currentUserId else { return false }
        guard let sessionStatus = SessionStatus(rawValue: session.status.rawValue) else { return false }
        let isParticipant = session.participants.contains(userId)
        return !isParticipant && (sessionStatus == .active || sessionStatus == .paused)
    }
    
    // MARK: - Actions
    
    private func loadInitialData() async {
        await loadSquadName()
        userLocation = realtimeService.userCoordinate
        runnerLocations = realtimeService.runnerLocations
        
        // Charger route locale si TrackingManager a déjà des points
        if trackingManager.isTracking && trackingManager.activeTrackingSession?.id == session.id {
            userRouteCoordinates = trackingManager.routeCoordinates
            Logger.log("[AUDIT-SDV-05] 📊 Chargement initial depuis TrackingManager: \(trackingManager.routeCoordinates.count) points", category: .location)
        } else {
            Logger.log("[AUDIT-SDV-06] ℹ️ Tracking non actif, attente du stream Firestore", category: .location)
        }
    }
    
    private func startRealtimeBindings() async {
        // Contexte pour le service temps réel (nécessite squadId)
        realtimeService.setContext(squadId: session.squadId)
        realtimeService.startLocationUpdates()
        
        guard let sessionId = session.id, let userId = AuthService.shared.currentUserId else { return }
        
        // 🎯 FIX CRITIQUE : Utiliser TrackingManager si c'est une session active en cours de tracking
        if trackingManager.isTracking && trackingManager.activeTrackingSession?.id == sessionId {
            Logger.log("[AUDIT-SDV-01] 📍 Session active détectée → utilisation TrackingManager", category: .location)
            
            // Observer les changements de routeCoordinates depuis TrackingManager (tracking live)
            Task { @MainActor in
                for await coords in trackingManager.$routeCoordinates.values {
                    userRouteCoordinates = coords
                    Logger.log("[AUDIT-SDV-02] 📊 userRouteCoordinates mis à jour depuis TrackingManager: \(coords.count) points", category: .location)
                }
            }
        } else {
            Logger.log("[AUDIT-SDV-03] 📥 Session non active ou terminée → chargement depuis Firestore", category: .location)
            
            // Charger l'historique depuis Firestore (session terminée ou supporter)
            let stream = routeHistoryService.streamRoutePoints(sessionId: sessionId, userId: userId)
            Task {
                for await points in stream {
                    let coords = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                    await MainActor.run {
                        userRouteCoordinates = coords
                        Logger.log("[AUDIT-SDV-04] 📊 userRouteCoordinates mis à jour depuis Firestore: \(coords.count) points", category: .location)
                    }
                }
            }
        }
    }
    
    private func loadAllParticipantsRoutes() async {
        guard let sessionId = session.id else { return }
        isLoadingRoutes = true
        
        // Charger le tracé de chaque participant
        for userId in session.participants {
            do {
                let points = try await routeHistoryService.loadRoutePoints(sessionId: sessionId, userId: userId)
                let coords = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                await MainActor.run {
                    runnerRoutes[userId] = coords
                }
            } catch {
                Logger.logError(error, context: "loadAllParticipantsRoutes(\(userId))", category: .location)
            }
        }
        
        isLoadingRoutes = false
    }
    
    private func startParticipantStatsListener() {
        stopParticipantStatsListener()
        guard let sessionId = session.id else { return }
        let db = Firestore.firestore()
        
        let statsRef = db.collection("sessions")
            .document(sessionId)
            .collection("participantStats")
        
        participantStatsListener = statsRef.addSnapshotListener { snapshot, error in
            if let error = error {
                Logger.logError(error, context: "participantStatsListener", category: .service)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            var totalDistance: Double = 0
            var avgSpeedAccumulator: Double = 0
            var avgSpeedCount: Double = 0
            var totalCalories: Double = 0
            var lastHeartRate: Double = 0
            
            for doc in documents {
                if let stats = try? doc.data(as: ParticipantStats.self) {
                    totalDistance += stats.distance
                    if stats.averageSpeed > 0 {
                        avgSpeedAccumulator += stats.averageSpeed
                        avgSpeedCount += 1
                    }
                    if let calories = stats.calories {
                        totalCalories += calories
                    }
                    if let hr = stats.currentHeartRate {
                        // on prend la dernière mesure disponible
                        lastHeartRate = hr
                    }
                }
            }
            
            let avgSpeed = avgSpeedCount > 0 ? (avgSpeedAccumulator / avgSpeedCount) : 0
            
            Task { @MainActor in
                self.liveDistance = totalDistance
                self.liveAvgSpeed = avgSpeed
                self.liveCalories = totalCalories
                self.liveHeartRate = lastHeartRate
            }
        }
    }
    
    private func stopParticipantStatsListener() {
        participantStatsListener?.remove()
        participantStatsListener = nil
    }
    
    private func joinAndStartTracking() async {
        guard let sessionId = session.id,
              let userId = AuthService.shared.currentUserId else { return }
        
        Logger.log("[AUDIT-SDV-JOIN-01] 🤝 Tentative de rejoindre session: \(sessionId)", category: .session)
        
        // ⚠️ PROTECTION: Ne pas rejoindre si on track déjà une autre session
        if trackingManager.isTracking {
            if let activeSessionId = trackingManager.activeTrackingSession?.id {
                if activeSessionId == sessionId {
                    Logger.log("[AUDIT-SDV-JOIN-02] ℹ️ Déjà en train de tracker cette session", category: .session)
                    return
                } else {
                    Logger.log("[AUDIT-SDV-JOIN-03] ⚠️ ERREUR: Vous trackez déjà une autre session (\(activeSessionId)). Arrêtez-la d'abord !", category: .session)
                    await MainActor.run {
                        showAlreadyTrackingAlert = true
                    }
                    return
                }
            }
        }
        
        isJoining = true
        do {
            // 1) Rejoindre la session
            Logger.log("[AUDIT-SDV-JOIN-04] 📝 Ajout à la liste des participants...", category: .session)
            try await sessionService.joinSession(sessionId: sessionId, userId: userId)
            Logger.logSuccess("[AUDIT-SDV-JOIN-05] ✅ Rejoint la session", category: .session)
            
            // 2) Démarrer le tracking via TrackingManager (gère HealthKit)
            Logger.log("[AUDIT-SDV-JOIN-06] 🏃 Démarrage du tracking...", category: .session)
            let started = await trackingManager.startTracking(for: session)
            if !started {
                Logger.log("[AUDIT-SDV-JOIN-07] ⚠️ Échec démarrage tracking", category: .location)
            } else {
                Logger.logSuccess("[AUDIT-SDV-JOIN-08] ✅ Tracking démarré avec succès", category: .location)
            }
        } catch {
            Logger.logError(error, context: "joinAndStartTracking", category: .session)
        }
        isJoining = false
    }
    
    private func exportCurrentRoute() async {
        // Sauvegarde/export du tracé de l’utilisateur si disponible via TrackingManager/RouteHistoryService
        guard let sessionId = session.id,
              let userId = AuthService.shared.currentUserId else { return }
        
        do {
            let points = try await routeHistoryService.loadRoutePoints(sessionId: sessionId, userId: userId)
            let coords = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            guard !coords.isEmpty else {
                Logger.log("⚠️ Aucun point à exporter", category: .location)
                return
            }
            // Vous pouvez brancher ici un export GPX si nécessaire via RouteTrackingService si existant
            Logger.logSuccess("✅ Tracé prêt pour export (\(coords.count) points)", category: .location)
        } catch {
            Logger.logError(error, context: "exportCurrentRoute", category: .location)
        }
    }
    
    private func endSession() {
        Task {
            do {
                if let sessionId = session.id {
                    // Arrêter le tracking si c’est mon tracking en cours
                    if trackingManager.activeTrackingSession?.id == sessionId {
                        try? await trackingManager.stopTracking()
                    }
                    
                    try await sessionService.endSession(sessionId: sessionId)
                    dismiss()
                }
            } catch {
                Logger.logError(error, context: "endSession", category: .session)
            }
        }
    }
    
    private func loadSquadName() async {
        do {
            if let squad = try await SquadService.shared.getSquad(squadId: session.squadId) {
                squadName = squad.name
            }
        } catch {
            print("Error loading squad name: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionDetailView(session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            startedAt: Date().addingTimeInterval(-1800), // 30 min ago
            status: .active,
            participants: ["user1", "user2"]
        ))
    }
    .preferredColorScheme(.dark)
}
