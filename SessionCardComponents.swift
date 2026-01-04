//
//  SessionCardComponents.swift
//  RunningMan
//
//  Composants de cartes réutilisables pour les sessions
//  ✅ DRY : Don't Repeat Yourself - Tous les composants de cartes sont ici
//

import SwiftUI
import FirebaseFirestore

// MARK: - Tracking Session Card (Ma session active avec GPS)

struct TrackingSessionCard: View {
    let session: SessionModel
    let distance: Double
    let duration: TimeInterval
    let state: TrackingState
    
    var body: some View {
        let _ = Logger.log("[AUDIT-TSC-01] 🎨 TrackingSessionCard affiché - state: \(state.displayName)", category: .ui)
        
        VStack(spacing: 16) {
            // En-tête
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.activityType.displayName.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(Color.coralAccent)
                    
                    Text("Session en cours")
                        .font(.title3.bold())
                        .foregroundColor(Color.white)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                    
                    Text(state.displayName)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.8))
                }
            }
            
            // Stats en temps réel
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DISTANCE")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text(FormatHelper.formattedDistance(distance))
                        .font(.title2.bold())
                        .foregroundColor(Color.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("DURÉE")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text(FormatHelper.formattedDuration(duration))
                        .font(.title2.bold())
                        .foregroundColor(Color.white)
                }
            }
            
            // Indicateur de navigation
            HStack {
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(Color.coralAccent)
                
                Text("Voir les détails")
                    .font(.subheadline)
                    .foregroundColor(Color.coralAccent)
                
                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.coralAccent.opacity(0.2), Color.pinkAccent.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
    
    private var stateColor: Color {
        switch state {
        case .idle: return Color.gray
        case .active: return Color.greenAccent
        case .paused: return Color.orange
        case .stopping: return Color.red
        }
    }
}

// MARK: - Supporter Session Card (Sessions que je suis)

struct SupporterSessionCard: View {
    let session: SessionModel
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blueAccent.opacity(0.2))
                    .frame(width: 45, height: 45)
                
                Image(systemName: "eyes.inverse")
                    .font(.title3)
                    .foregroundColor(Color.blueAccent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.activityType.displayName)
                    .font(.caption.bold())
                    .foregroundColor(Color.blueAccent)
                
                Text("\(session.participants.count) coureurs en live")
                    .font(.subheadline.bold())
                    .foregroundColor(Color.white)
                
                HStack(spacing: 8) {
                    Label(session.formattedDistance, systemImage: "figure.run")
                    Text("•")
                    Label(session.formattedSessionDuration, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.white.opacity(0.3))
        }
        .padding()
        .background(Color.blueAccent.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blueAccent.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - History Session Card (Sessions terminées)

struct HistorySessionCard: View {
    let session: SessionModel
    
    var body: some View {
        let _ = Logger.log("[AUDIT-HSC-01] 🎨 HistorySessionCard affiché - sessionId: \(session.id ?? "unknown")", category: .ui)
        
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 45, height: 45)
                
                Image(systemName: session.activityType.icon)
                    .font(.title3)
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.activityType.displayName)
                    .font(.caption.bold())
                    .foregroundColor(Color.white.opacity(0.5))
                
                if let endedAt = session.endedAt {
                    Text(endedAt.formattedDateTime)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.white)
                }
                
                HStack(spacing: 8) {
                    Label(session.formattedDistance, systemImage: "figure.run")
                    Text("•")
                    Label(session.formattedSessionDuration, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color.white.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stat Badge Compact (Badge de statistique compact)

struct StatBadgeCompact: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.coralAccent)
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(Color.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session Row Card (Liste des sessions actives)

struct SessionRowCard: View {
    let session: SessionModel
    let isMyTracking: Bool
    let onJoin: () -> Void
    let onStartTracking: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.coralAccent, Color.pinkAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: session.activityType.icon)
                                .foregroundColor(.white)
                                .font(.footnote.bold())
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.activityType.displayName)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                if isMyTracking {
                    Text("Ma session")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.coralAccent.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            
            // Stats ligne
            HStack(spacing: 12) {
                Label(session.formattedDistance, systemImage: "figure.run")
                Text("•")
                Label(session.formattedSessionDuration, systemImage: "clock")
                Spacer()
                Text("\(session.participants.count) part.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
            
            // Actions
            HStack(spacing: 10) {
                Button(action: onJoin) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text("Rejoindre")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: onStartTracking) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                        Text("Démarrer le tracking")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.coralAccent, Color.pinkAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var statusColor: Color {
        switch session.status {
        case .active: return .greenAccent
        case .paused: return .orange
        case .scheduled: return .yellowAccent
        case .ended: return .gray
        }
    }
    
    private var statusText: String {
        switch session.status {
        case .active: return "En cours"
        case .paused: return "En pause"
        case .scheduled: return "Programmé"
        case .ended: return "Terminé"
        }
    }
}

// MARK: - Live Stat Card (déplacé depuis ActiveSessionDetailView)

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

// MARK: - Session Stat Card (pour SessionStatsWidget)

/// Carte de statistique pour le widget de stats en temps réel
struct SessionStatCard: View {
    let icon: String
    let value: String
    let label: String  // Peut aussi être appelé "title" via l'init personnalisé
    let color: Color
    
    // Init standard avec "label"
    init(icon: String, value: String, label: String, color: Color) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
    }
    
    // Init alternatif avec "title" pour compatibilité
    init(icon: String, value: String, title: String, color: Color) {
        self.icon = icon
        self.value = value
        self.label = title
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Alias pour compatibilité

/// Alias pour SessionStatCard (pour éviter les erreurs de compilation)
typealias StatCard = SessionStatCard

// MARK: - Participant Stats Card (déplacé depuis ActiveSessionDetailView)

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
                .fill(Color.greenAccent)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Participant Row (pour SessionDetailView)

/// Ligne de participant avec avatar, nom et stats en temps réel
struct ParticipantRow: View {
    let sessionId: String
    let userId: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var displayName: String = "Chargement..."
    @State private var photoURL: String?
    @State private var distance: Double = 0
    @State private var avgSpeed: Double = 0
    @State private var currentHeartRate: Double?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                if let photoURL = photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(isSelected ? Color.coralAccent.opacity(0.4) : Color.white.opacity(0.1))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(isSelected ? .coralAccent : .white.opacity(0.6))
                            }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(isSelected ? Color.coralAccent.opacity(0.4) : Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(isSelected ? .coralAccent : .white.opacity(0.6))
                        }
                }
                
                // Infos participant
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        // Distance
                        if distance > 0 {
                            Label(distance.formattedDistanceKm, systemImage: "figure.run")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Vitesse
                        if avgSpeed > 0 {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Label(avgSpeed.formattedSpeedKmh, systemImage: "speedometer")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Fréquence cardiaque
                        if let hr = currentHeartRate, hr > 0 {
                            Text("•")
                                .foregroundColor(.white.opacity(0.5))
                            Label("\(Int(hr)) bpm", systemImage: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                // Indicateur de sélection
                if isSelected {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.coralAccent)
                } else {
                    Image(systemName: "location.circle")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding()
            .background(isSelected ? Color.coralAccent.opacity(0.1) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .task {
            await loadParticipantData()
        }
    }
    
    // MARK: - Load Data
    
    private func loadParticipantData() async {
        // 1. Charger le profil utilisateur depuis Firestore
        await loadUserProfile()
        
        // 2. Charger les stats en temps réel
        await loadParticipantStats()
    }
    
    private func loadUserProfile() async {
        let db = Firestore.firestore()
        
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            
            if let data = doc.data() {
                await MainActor.run {
                    displayName = data["displayName"] as? String ?? "Inconnu"
                    photoURL = data["photoURL"] as? String
                }
            }
        } catch {
            Logger.logError(error, context: "loadUserProfile(userId: \(userId))", category: .service)
        }
    }
    
    private func loadParticipantStats() async {
        guard !sessionId.isEmpty else { return }
        let db = Firestore.firestore()
        
        do {
            let doc = try await db.collection("sessions")
                .document(sessionId)
                .collection("participantStats")
                .document(userId)
                .getDocument()
            
            if let data = doc.data() {
                await MainActor.run {
                    distance = data["distance"] as? Double ?? 0
                    avgSpeed = data["averageSpeed"] as? Double ?? 0
                    currentHeartRate = data["currentHeartRate"] as? Double
                }
            }
        } catch {
            Logger.logError(error, context: "loadParticipantStats(session: \(sessionId), user: \(userId))", category: .service)
        }
    }
}

// MARK: - Preview

#Preview("Tracking Card") {
    TrackingSessionCard(
        session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            participants: ["user1"],
            totalDistanceMeters: 5200,
            durationSeconds: 2730
        ),
        distance: 5200,
        duration: 2730,
        state: .active
    )
    .padding()
    .background(Color.darkNavy)
}

#Preview("Supporter Card") {
    SupporterSessionCard(
        session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            participants: ["user1", "user2", "user3"],
            totalDistanceMeters: 2100,
            durationSeconds: 900
        )
    )
    .padding()
    .background(Color.darkNavy)
}

#Preview("History Card") {
    HistorySessionCard(
        session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            endedAt: Date().addingTimeInterval(-86400),
            status: .ended,
            participants: ["user1"],
            totalDistanceMeters: 10200,
            durationSeconds: 3600
        )
    )
    .padding()
    .background(Color.darkNavy)
}

#Preview("Session Row Card") {
    SessionRowCard(
        session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            startedAt: Date().addingTimeInterval(-1200),
            participants: ["user1", "user2"],
            totalDistanceMeters: 3500,
            durationSeconds: 1200,
            averageSpeed: 2.8
        ),
        isMyTracking: true,
        onJoin: {},
        onStartTracking: {}
    )
    .padding()
    .background(Color.darkNavy)
}

