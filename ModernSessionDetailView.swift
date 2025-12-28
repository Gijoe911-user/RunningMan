//
//  ModernSessionDetailView.swift
//  RunningMan
//
//  Vue de détail de session avec le nouveau design
//

import SwiftUI
import MapKit

struct ModernSessionDetailView: View {
    let session: SessionModel
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var locationService = LocationService.shared
    
    @State private var showEndSessionConfirmation = false
    @State private var squadName: String = "Session"
    @State private var runnerLocations: [RunnerLocation] = []
    @State private var selectedRunnerId: String?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var userRoutePoints: [RoutePoint] = []
    
    var body: some View {
        ZStack {
            // Background avec dégradé
            LinearGradient(
                colors: [Color.darkNavy, Color.darkNavy.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Map section avec overlay moderne
                mapSection
                    .frame(height: 450)
                
                // Contenu scrollable
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Session Header Card
                        sessionHeaderCard
                        
                        // Stats rapides
                        quickStatsCard
                        
                        // Participants avec nouveau design
                        participantsCard
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, 100) // Espace pour la barre d'actions
                }
            }
            
            // Barre d'actions en bas
            VStack {
                Spacer()
                
                ActionButtonBar(
                    onMicroTap: { /* TODO: Voice message */ },
                    onPhotoTap: { /* TODO: Take photo */ },
                    onMessagesTap: { /* TODO: Open chat */ },
                    unreadCount: 0
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(squadName)
                    .font(.sectionTitle)
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if canEndSession {
                    Button {
                        showEndSessionConfirmation = true
                    } label: {
                        GlassButton(
                            icon: "stop.fill",
                            action: { showEndSessionConfirmation = true },
                            size: 40,
                            iconSize: 18,
                            tint: .red
                        )
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
            await loadData()
        }
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        ZStack(alignment: .topTrailing) {
            // Carte
            MapView(
                runnerLocations: runnerLocations,
                userLocation: locationService.currentLocation?.coordinate,
                routePoints: userRoutePoints,
                mapPosition: $mapPosition
            )
            .ignoresSafeArea(edges: .top)
            
            // Overlay avec badges de distance
            VStack {
                Spacer()
                
                HStack {
                    // Badges des autres coureurs
                    ForEach(runnerLocations.prefix(3)) { runner in
                        DistanceBadge(
                            distance: runner.latitude, // TODO: calculer vraie distance
                            size: 70
                        )
                    }
                    
                    Spacer()
                }
                .padding(.leading, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            
            // Contrôles de la carte (zoom, centrer)
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: Spacing.sm) {
                        GlassButton(
                            icon: "plus",
                            action: { /* TODO: Zoom in */ },
                            size: 44,
                            iconSize: 20
                        )
                        
                        GlassButton(
                            icon: "minus",
                            action: { /* TODO: Zoom out */ },
                            size: 44,
                            iconSize: 20
                        )
                        
                        GlassButton(
                            icon: "location.fill",
                            action: { /* TODO: Center on user */ },
                            size: 44,
                            iconSize: 20,
                            tint: .coralAccent
                        )
                    }
                    .padding(.trailing, Spacing.lg)
                }
                
                Spacer()
            }
            .padding(.top, 60) // Éviter la notch
            
            // Statut GPS
            if locationService.isTracking {
                VStack {
                    GlassCard(
                        cornerRadius: CornerRadius.medium,
                        padding: EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                    ) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text("Tracking actif")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Session Header Card
    
    private var sessionHeaderCard: some View {
        GlassCard {
            VStack(spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Session démarrée")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatTime(session.startedAt))
                            .font(.sectionTitle)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Durée")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatDuration(session.startedAt))
                            .font(.sectionTitle)
                            .foregroundColor(.coralAccent)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Stats Card
    
    private var quickStatsCard: some View {
        GlassCard {
            HStack(spacing: Spacing.xl) {
                StatItem(
                    icon: "figure.run",
                    value: "5.2",
                    unit: "km",
                    color: .coralAccent
                )
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                StatItem(
                    icon: "speedometer",
                    value: "5'30\"",
                    unit: "/km",
                    color: .blueAccent
                )
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                StatItem(
                    icon: "flame.fill",
                    value: "245",
                    unit: "kcal",
                    color: .yellowAccent
                )
            }
        }
    }
    
    // MARK: - Participants Card
    
    private var participantsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text("Participants")
                        .font(.sectionTitle)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(session.participants.count)")
                        .font(.sectionTitle)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Stack de badges
                ParticipantsStack(
                    participants: session.participants,
                    maxVisible: 5,
                    badgeSize: 50
                )
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.vertical, Spacing.xs)
                
                // Liste détaillée
                VStack(spacing: Spacing.sm) {
                    ForEach(session.participants.prefix(3), id: \.self) { userId in
                        ModernParticipantRow(
                            userId: userId,
                            sessionId: session.id ?? "",
                            isSelected: selectedRunnerId == userId,
                            onTap: {
                                centerMapOnRunner(userId: userId)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private var canEndSession: Bool {
        guard let userId = AuthService.shared.currentUserId else { return false }
        return session.creatorId == userId
    }
    
    private func centerMapOnRunner(userId: String) {
        selectedRunnerId = userId
        
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
    
    private func loadData() async {
        await loadSquadName()
        
        if let sessionId = session.id,
           let userId = AuthService.shared.currentUserId {
            
            if !locationService.isAuthorized {
                locationService.requestAuthorization()
            }
            
            locationService.startTracking(sessionId: sessionId, userId: userId)
            await observeUserRoute(sessionId: sessionId, userId: userId)
        }
        
        if let sessionId = session.id {
            await observeRunnerLocations(sessionId: sessionId)
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
                    locationService.stopTracking()
                    try await SessionService.shared.endSession(sessionId: sessionId)
                    dismiss()
                }
            } catch {
                print("Error ending session: \(error)")
            }
        }
    }
    
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

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.stat(size: 24))
                .foregroundColor(.white)
            
            Text(unit)
                .font(.smallLabel)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Participant Row

struct ModernParticipantRow: View {
    let userId: String
    let sessionId: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var displayName: String = "..."
    @State private var isRunning: Bool = false
    
    private var isCurrentUser: Bool {
        userId == AuthService.shared.currentUserId
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Avatar
                ParticipantBadge(
                    imageURL: nil,
                    initial: displayName.prefix(1).uppercased(),
                    size: 44,
                    borderColor: isSelected ? .coralAccent : .white,
                    borderWidth: isSelected ? 3 : 2
                )
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(isCurrentUser ? "Vous" : displayName)
                        .font(.subtitle)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isRunning ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                        
                        Text(isRunning ? "En course" : "En attente")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.coralAccent)
                }
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(isSelected ? Color.coralAccent.opacity(0.15) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .task {
            await loadUserName()
        }
    }
    
    private func loadUserName() async {
        do {
            if let user = try await AuthService.shared.getUserProfile(userId: userId) {
                displayName = user.displayName
            }
        } catch {
            displayName = "Coureur #\(userId.prefix(6))"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModernSessionDetailView(session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            startedAt: Date().addingTimeInterval(-1800),
            participants: ["user1", "user2", "user3"]
        ))
    }
    .preferredColorScheme(.dark)
}
