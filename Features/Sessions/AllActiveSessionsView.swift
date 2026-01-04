//
//  AllActiveSessionsView.swift
//  RunningMan
//
//  Vue globale affichant toutes les sessions actives de toutes les squads
//

import SwiftUI
import MapKit
import Combine

struct AllActiveSessionsView: View {
    @StateObject private var viewModel = AllActiveSessionsViewModel()
    @State private var showCreateSession = false
    @State private var selectedSquad: SquadModel?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Chargement des sessions...")
                        .tint(.coralAccent)
                } else if viewModel.activeSessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // En-tête avec statistiques
                            statsHeader
                            
                            // Liste des sessions actives
                            ForEach(viewModel.activeSessions) { session in
                                DetailedActiveSessionCard(
                                    session: session,
                                    squad: viewModel.squadsDict[session.squadId],
                                    creator: viewModel.usersDict[session.creatorId],
                                    currentUserId: AuthService.shared.currentUserId ?? ""
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadAllActiveSessions()
                    }
                }
            }
            .navigationTitle("Sessions actives")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        // Bouton pour créer une session dans chaque squad
                        ForEach(viewModel.userSquads) { squad in
                            Button {
                                selectedSquad = squad
                                showCreateSession = true
                            } label: {
                                Label(squad.name, systemImage: "plus.circle.fill")
                            }
                            .disabled(viewModel.hasActiveSession(in: squad.id ?? "", userId: AuthService.shared.currentUserId ?? ""))
                        }
                        
                        Divider()
                        
                        Button {
                            Task {
                                await viewModel.loadAllActiveSessions()
                            }
                        } label: {
                            Label("Actualiser", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.coralAccent)
                    }
                }
            }
            .sheet(isPresented: $showCreateSession) {
                if let squad = selectedSquad {
                    CreateSessionWithProgramView(squad: squad) {
                        Task {
                            await viewModel.loadAllActiveSessions()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadAllActiveSessions()
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            SessionStatBadge(
                icon: "person.3.fill",
                value: "\(viewModel.totalRunners)",
                label: "Coureurs"
            )
            
            SessionStatBadge(
                icon: "figure.run",
                value: "\(viewModel.activeSessions.count)",
                label: "Sessions"
            )
            
            SessionStatBadge(
                icon: "flame.fill",
                value: String(format: "%.1f km", viewModel.totalDistance),
                label: "Distance totale"
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.coralAccent, .pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Aucune session active")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Créez une session pour commencer à courir avec votre squad")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Boutons de création par squad
            if !viewModel.userSquads.isEmpty {
                VStack(spacing: 12) {
                    ForEach(viewModel.userSquads) { squad in
                        Button {
                            selectedSquad = squad
                            showCreateSession = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Créer dans \(squad.name)")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.coralAccent, .pinkAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel.hasActiveSession(in: squad.id ?? "", userId: AuthService.shared.currentUserId ?? ""))
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

// MARK: - Detailed Active Session Card

struct DetailedActiveSessionCard: View {
    let session: SessionModel
    let squad: SquadModel?
    let creator: RunnerUserModel?
    let currentUserId: String
    
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(spacing: 16) {
                // En-tête : Squad + Créateur
                HStack(spacing: 12) {
                    // Avatar du créateur
                    if let photoURL = creator?.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.coralAccent.opacity(0.3))
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
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Nom du créateur
                        Text(creator?.displayName ?? "Coureur")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Nom de la squad
                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.caption)
                            Text(squad?.name ?? "Squad")
                        }
                        .font(.caption)
                        .foregroundColor(.coralAccent)
                    }
                    
                    Spacer()
                    
                    // Badge du type de session
                    SessionTypeBadge(type: session.activityType)
                }
                
                // Titre de la session
                if let title = session.title, !title.isEmpty {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Lieu de la session
                if let locationName = session.meetingLocationName {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.pinkAccent)
                        
                        Text(locationName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                    }
                }
                
                // Stats de la session
                HStack(spacing: 16) {
                    SessionStat(icon: "location.fill", value: String(format: "%.2f km", session.distanceInKilometers))
                    SessionStat(icon: "clock.fill", value: formatDuration(session.durationSeconds ?? 0))
                    SessionStat(icon: "person.3.fill", value: "\(session.participants.count)")
                    
                    Spacer()
                    
                    // Indicateur si l'utilisateur participe déjà
                    if session.participants.contains(currentUserId) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("En cours")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Rejoindre")
                            .font(.caption.bold())
                            .foregroundColor(.coralAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.coralAccent.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        session.participants.contains(currentUserId) ? Color.green : Color.white.opacity(0.1),
                        lineWidth: 2
                    )
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                // ✅ FIX: Utiliser SessionDetailView au lieu de ActiveSessionDetailView
                SessionDetailView(session: session)
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

// MARK: - Supporting Views

// Modèle utilisateur local pour cette vue
struct RunnerUserModel: Codable, Identifiable {
    var id: String?
    var displayName: String
    var photoURL: String?
}

struct SessionStatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.coralAccent)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionTypeBadge: View {
    let type: ActivityType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.caption)
            Text(type.displayName)
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(colorForType.opacity(0.3))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(colorForType, lineWidth: 1)
        }
    }
    
    private var colorForType: Color {
        switch type {
        case .training: return .coralAccent
        case .race: return .red
        case .interval: return .orange
        case .recovery: return .green
        }
    }
}

struct SessionStat: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.coralAccent)
            
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
    }
}

// MARK: - ViewModel

@MainActor
class AllActiveSessionsViewModel: ObservableObject {
    @Published var activeSessions: [SessionModel] = []
    @Published var userSquads: [SquadModel] = []
    @Published var squadsDict: [String: SquadModel] = [:]
    @Published var usersDict: [String: RunnerUserModel] = [:]
    @Published var isLoading = false
    
    var totalRunners: Int {
        let allParticipants = activeSessions.flatMap { $0.participants }
        return Set(allParticipants).count
    }
    
    var totalDistance: Double {
        activeSessions.reduce(0) { $0 + $1.distanceInKilometers }
    }
    
    func loadAllActiveSessions() async {
        guard let userId = AuthService.shared.currentUserId else { return }
        
        isLoading = true
        
        do {
            // 1. Charger les squads de l'utilisateur
            userSquads = try await SquadService.shared.getUserSquads(userId: userId)
            
            // 2. Pour chaque squad, récupérer les sessions actives
            var allSessions: [SessionModel] = []
            
            for squad in userSquads {
                guard let squadId = squad.id else { continue }
                
                let sessions = try await SessionService.shared.getActiveSessions(squadId: squadId)
                allSessions.append(contentsOf: sessions)
                
                // Stocker la squad dans le dictionnaire
                squadsDict[squadId] = squad
            }
            
            // 3. Charger les infos des créateurs
            // TODO: Implémenter UserService
            let creatorIds = Set(allSessions.map { $0.creatorId })
            for creatorId in creatorIds {
                // Placeholder: Créer un UserModel basique
                usersDict[creatorId] = RunnerUserModel(
                    id: creatorId,
                    displayName: "Coureur", // TODO: Récupérer le vrai nom
                    photoURL: nil
                )
            }
            
            // 4. Trier par date de création (plus récentes en premier)
            activeSessions = allSessions.sorted { $0.startedAt > $1.startedAt }
            
            Logger.logSuccess("✅ \(activeSessions.count) sessions actives chargées", category: .service)
            
        } catch {
            Logger.logError(error, context: "loadAllActiveSessions", category: .service)
        }
        
        isLoading = false
    }
    
    /// Vérifie si l'utilisateur a déjà une session active dans cette squad
    func hasActiveSession(in squadId: String, userId: String) -> Bool {
        activeSessions.contains { session in
            session.squadId == squadId &&
            session.creatorId == userId &&
            session.status == .active
        }
    }
}

// MARK: - Preview

#Preview {
    AllActiveSessionsView()
        .preferredColorScheme(.dark)
}
