//
//  SessionDetailView.swift
//  RunningMan
//
//  Vue de détail d'une session avec carte et participants
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct SessionDetailView: View {
    let session: SessionModel
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var locationService = LocationService.shared
    
    @State private var showEndSessionConfirmation = false
    @State private var squadName: String = "Session"
    @State private var runnerLocations: [RunnerLocation] = []
    @State private var selectedRunnerId: String?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var userRoutePoints: [RoutePoint] = []  // Points du parcours de l'utilisateur
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Map section
                mapSection
                    .frame(height: 400)
                
                // Participants section
                participantsSection
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
        .task {
            await loadSquadName()
            
            // Démarrer le tracking pour cette session
            if let sessionId = session.id,
               let userId = AuthService.shared.currentUserId {
                
                // Demander l'autorisation si nécessaire
                if !locationService.isAuthorized {
                    locationService.requestAuthorization()
                }
                
                // Démarrer le tracking
                locationService.startTracking(sessionId: sessionId, userId: userId)
                
                // Observer le parcours de l'utilisateur en temps réel
                await observeUserRoute(sessionId: sessionId, userId: userId)
            }
            
            // Observer les positions des coureurs en temps réel
            if let sessionId = session.id {
                await observeRunnerLocations(sessionId: sessionId)
            }
        }
        .onDisappear {
            // NE PAS arrêter le tracking pour permettre le mode arrière-plan
            // Le tracking continuera même si l'utilisateur quitte la vue
            // locationService.stopTracking()
        }
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        ZStack(alignment: .topTrailing) {
            MapView(
                runnerLocations: runnerLocations,
                userLocation: locationService.currentLocation?.coordinate,
                routePoints: userRoutePoints,
                mapPosition: $mapPosition
            )
            .ignoresSafeArea(edges: .top)
            
            // Légende de localisation
            if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                locationDeniedBanner
            } else if locationService.isTracking {
                VStack {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                        Text("Tracking actif")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
                    
                    Spacer()
                }
            }
        }
    }
    
    private var locationDeniedBanner: some View {
        VStack {
            VStack(spacing: 8) {
                Image(systemName: "location.slash.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Localisation désactivée")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Activez la localisation pour suivre votre position")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Button {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                } label: {
                    Text("Ouvrir les paramètres")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.coralAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()
            
            Spacer()
        }
    }
    
    // MARK: - Participants Section
    
    private var participantsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Session info
                sessionInfoCard
                
                // Participants
                participantsList
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var sessionInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session démarrée")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatTime(session.startedAt))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Durée")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(formatDuration(session.startedAt))
                        .font(.headline)
                        .foregroundColor(.coralAccent)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var participantsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants (\(session.participants.count))")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(session.participants, id: \.self) { userId in
                    ParticipantRow(
                        sessionId: session.id ?? "",
                        userId: userId,
                        isSelected: selectedRunnerId == userId,
                        onTap: {
                            centerMapOnRunner(userId: userId)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canEndSession: Bool {
        guard let userId = AuthService.shared.currentUserId else { return false }
        return session.creatorId == userId
    }
    
    // MARK: - Actions
    
    private func centerMapOnRunner(userId: String) {
        selectedRunnerId = userId
        
        // Trouver la position du coureur
        if let runner = runnerLocations.first(where: { $0.id == userId }) {
            withAnimation {
                mapPosition = .region(
                    MKCoordinateRegion(
                        center: runner.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                )
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
    
    private func observeRunnerLocations(sessionId: String) async {
        let repository = RealtimeLocationRepository()
        let stream = repository.observeRunnerLocations(sessionId: sessionId)
        
        for await locations in stream {
            runnerLocations = locations
        }
    }
    
    private func observeUserRoute(sessionId: String, userId: String) async {
        let routeService = RouteHistoryService.shared
        let stream = routeService.streamRoutePoints(sessionId: sessionId, userId: userId)
        
        for await points in stream {
            userRoutePoints = points
        }
    }
    
    private func endSession() {
        Task {
            do {
                if let sessionId = session.id {
                    // Arrêter le tracking avant de terminer la session
                    locationService.stopTracking()
                    
                    try await SessionService.shared.endSession(sessionId: sessionId)
                    dismiss()
                }
            } catch {
                print("Error ending session: \(error)")
            }
        }
    }
    
    // MARK: - Formatting
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes % 60)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {
    let sessionId: String
    let userId: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var displayName: String = "Chargement..."
    @State private var isRunning: Bool = false
    @State private var stats: ParticipantStats?
    @State private var lastLocationUpdate: Date?
    
    private var isCurrentUser: Bool {
        userId == AuthService.shared.currentUserId
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(isRunning ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: isCurrentUser ? "person.fill.checkmark" : "person.fill")
                            .font(.caption)
                            .foregroundColor(isRunning ? .green : .gray)
                    }
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(Color.coralAccent, lineWidth: 3)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(isCurrentUser ? "Vous" : displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if isCurrentUser {
                            Text("(\(displayName))")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isRunning ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                        
                        Text(isRunning ? "En course" : "En attente")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Stats de course (réelles depuis Firestore)
                if let stats = stats, stats.distance > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f km", stats.distance / 1000))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.coralAccent)
                        
                        if stats.averageSpeed > 0 {
                            let pace = formatPace(speed: stats.averageSpeed)
                            Text(pace)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                // Indicateur de sélection
                if isSelected {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.coralAccent)
                }
            }
            .padding()
            .background(isSelected ? Color.coralAccent.opacity(0.1) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .task {
            await loadUserData()
            await startObservingParticipant()
        }
    }
    
    private func loadUserData() async {
        // Charger le nom de l'utilisateur
        do {
            if let user = try await AuthService.shared.getUserProfile(userId: userId) {
                displayName = user.displayName
            }
        } catch {
            displayName = "Utilisateur #\(userId.prefix(6))"
        }
    }
    
    private func startObservingParticipant() async {
        let db = Firestore.firestore()
        
        // Observer les stats du participant
        let statsRef = db.collection("sessions")
            .document(sessionId)
            .collection("participantStats")
            .document(userId)
        
        // Observer la dernière position pour déterminer si actif
        let locationRef = db.collection("sessions")
            .document(sessionId)
            .collection("locations")
            .document(userId)
        
        // Écouter les changements de stats
        statsRef.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists else { return }
            
            if let participantStats = try? snapshot.data(as: ParticipantStats.self) {
                Task { @MainActor in
                    self.stats = participantStats
                }
            }
        }
        
        // Écouter les changements de position pour déterminer si actif
        locationRef.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists else { return }
            
            if let data = snapshot.data(),
               let timestamp = data["timestamp"] as? Timestamp {
                let locationDate = timestamp.dateValue()
                
                Task { @MainActor in
                    self.lastLocationUpdate = locationDate
                    
                    // Considérer le coureur comme actif si dernière mise à jour < 30 secondes
                    let timeSinceUpdate = Date().timeIntervalSince(locationDate)
                    self.isRunning = timeSinceUpdate < 30
                }
            }
        }
    }
    
    private func formatPace(speed: Double) -> String {
        guard speed > 0 else { return "--:--/km" }
        let minutesPerKm = (1000.0 / speed) / 60.0
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        return String(format: "%d'%02d\"/km", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionDetailView(session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            startedAt: Date().addingTimeInterval(-1800), // 30 min ago
            participants: ["user1", "user2"]
        ))
    }
    .preferredColorScheme(.dark)
}
