//
//  SessionsListView.swift
//  RunningMan
//
//  Vue principale pour afficher et gérer les sessions de course
//

import SwiftUI
import Combine
import CoreLocation
import MapKit

/// Vue principale de l'onglet Sessions
///
/// Affiche :
/// - Une carte avec le tracé GPS en temps réel
/// - Le widget de stats pendant une session active
/// - L'overlay avec infos de session et participants
/// - Un état vide si aucune session
///
/// **Architecture :**
/// - Fichier principal < 200 lignes
/// - Sous-composants extraits (SessionActiveOverlay, etc.)
/// - Logique déléguée aux helpers (RouteCalculator)
///
/// **Navigation :**
/// - Toolbar avec bouton "+" pour créer une session
/// - Sheet pour CreateSessionView
///
/// - SeeAlso: `SessionsViewModel`, `SessionActiveOverlay`, `NoSessionOverlay`
struct SessionsListView: View {
    
    // MARK: - Environment
    
    @Environment(SquadViewModel.self) private var squadsVM
    
    // MARK: - State
    
    @StateObject private var viewModel = SessionsViewModel()
    @State private var configuredSquadId: String? = nil
    @State private var showCreateSession = false
    @State private var recentSessions: [SessionModel] = []  // 🆕 Historique récent
    @State private var isLoadingHistory = false  // 🆕 État de chargement
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Carte avec tracé GPS
                mapView
                
                // Overlays conditionnels
                if let session = viewModel.activeSession {
                    activeSessionContent(session: session)
                } else {
                    // 🆕 Pas de session active : afficher l'historique
                    noActiveSessionContent
                }
            }
            .navigationTitle("Course")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showCreateSession) {
                if let squad = squadsVM.selectedSquad {
                    CreateSessionView(squad: squad) {
                        // ✅ Callback : Recharger les sessions après création
                        Task {
                            await loadRecentSessions()
                        }
                    }
                }
            }
            .onAppear {
                setupView()
            }
            .task(id: squadsVM.selectedSquad?.id) {
                configureSquadContext()
                await loadRecentSessions()  // 🆕 Charger l'historique
            }
        }
    }
    
    // MARK: - View Components
    
    /// Carte principale avec tracé GPS
    private var mapView: some View {
        EnhancedSessionMapView(
            userLocation: viewModel.userLocation,
            runnerLocations: viewModel.activeRunners,
            routeCoordinates: viewModel.routeCoordinates,
            runnerRoutes: [:], // TODO: Ajouter les tracés des autres coureurs
            onRecenter: {
                Logger.log("[AUDIT-SLV-01] 🎯 SessionsListView.onRecenter appelé", category: .location)
            },
            onSaveRoute: {
                saveCurrentRoute()
            }
        )
        .ignoresSafeArea(edges: .top)
    }
    
    /// Contenu affiché pendant une session active
    private func activeSessionContent(session: SessionModel) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Widget de stats flottant
            statsWidget(session: session)
            
            Spacer()
            
            // Participants overlay
            if !viewModel.activeRunners.isEmpty {
                participantsOverlay
            }
            
            // Overlay principal
            SessionActiveOverlay(session: session, viewModel: viewModel)
        }
    }
    
    /// Contenu affiché quand il n'y a pas de session active (historique + bouton créer)
    private var noActiveSessionContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ScrollView {
                VStack(spacing: 20) {
                    // État vide avec bouton créer
                    NoSessionOverlay(onCreateSession: { showCreateSession = true })
                        .padding(.horizontal)
                    
                    // 🆕 Section historique récent
                    if !recentSessions.isEmpty {
                        recentSessionsSection
                    } else if isLoadingHistory {
                        ProgressView()
                            .tint(.white)
                            .padding()
                    }
                }
                .padding(.bottom, 40)
            }
            .background(.ultraThinMaterial)
        }
    }
    
    /// Section des sessions récentes
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête
            HStack {
                Text("Sessions récentes")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                if squadsVM.selectedSquad != nil {
                    NavigationLink {
                        SquadSessionsListView(squad: squadsVM.selectedSquad!)
                    } label: {
                        Text("Tout voir")
                            .font(.subheadline)
                            .foregroundColor(.coralAccent)
                    }
                }
            }
            .padding(.horizontal)
            
            // Liste des sessions (max 5)
            ForEach(recentSessions.prefix(5)) { session in
                NavigationLink {
                    SessionHistoryDetailView(session: session)
                } label: {
                    RecentSessionCard(session: session)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical)
    }
    
    /// Widget de statistiques en direct
    private func statsWidget(session: SessionModel) -> some View {
        HStack {
            Spacer()
            SessionStatsWidget(
                session: session,
                currentHeartRate: viewModel.currentHeartRate,
                currentCalories: viewModel.currentCalories,
                routeDistance: RouteCalculator.calculateTotalDistance(from: viewModel.routeCoordinates)
            )
            .frame(maxWidth: 400)
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal)
    }
    
    /// Overlay des participants actifs
    private var participantsOverlay: some View {
        SessionParticipantsOverlay(
            participants: viewModel.activeRunners,
            userLocation: viewModel.userLocation,
            onRunnerTap: { runnerId in
                Logger.log("🎯 Clic sur coureur: \(runnerId)", category: .location)
                // TODO: Centrer la carte sur ce coureur
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    /// Contenu de la toolbar
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                if squadsVM.selectedSquad != nil && canCreateSession {
                    showCreateSession = true
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(canCreateSession ? .coralAccent : .gray)
                    .font(.title2)
            }
            .disabled(!canCreateSession)
        }
    }
    
    /// Vérifie si l'utilisateur peut créer une session
    private var canCreateSession: Bool {
        guard let squad = squadsVM.selectedSquad,
              AuthService.shared.currentUserId != nil else {
            return false
        }
        
        // ✅ Autoriser TOUS les membres d'une squad
        return !squad.members.isEmpty
    }
    
    // MARK: - Actions
    
    /// Configure la vue au démarrage
    private func setupView() {
        Logger.log("[AUDIT-SLV-02] 🔧 SessionsListView.setupView appelé", category: .ui)
        viewModel.startLocationUpdates()
        viewModel.centerOnUserLocation()
    }
    
    /// Configure le contexte de la squad sélectionnée
    private func configureSquadContext() {
        Logger.log("[AUDIT-SLV-03] 🎯 SessionsListView.configureSquadContext appelé", category: .ui)
        guard let squadId = squadsVM.selectedSquad?.id else { return }
        if configuredSquadId != squadId {
            viewModel.setContext(squadId: squadId)
            configuredSquadId = squadId
        }
    }
    
    /// 🆕 Charge les sessions récentes pour toutes les squads de l'utilisateur
    private func loadRecentSessions() async {
        Logger.log("[AUDIT-SLV-05] 📜 Chargement des sessions récentes...", category: .session)
        isLoadingHistory = true
        
        var allSessions: [SessionModel] = []
        
        // Parcourir toutes les squads de l'utilisateur
        for squad in squadsVM.userSquads {
            guard let squadId = squad.id else { continue }
            
            do {
                // Récupérer les sessions de l'historique
                let sessions = try await SessionService.shared.getSessionHistory(squadId: squadId)
                allSessions.append(contentsOf: sessions)
            } catch {
                Logger.logError(error, context: "loadRecentSessions(squad: \(squadId))", category: .session)
                // Continue avec les autres squads même en cas d'erreur
            }
        }
        
        // Trier par date décroissante et garder les 10 plus récentes
        let sortedSessions = allSessions.sorted { session1, session2 in
            let date1 = session1.endedAt ?? session1.startedAt
            let date2 = session2.endedAt ?? session2.startedAt
            return date1 > date2
        }
        
        await MainActor.run {
            recentSessions = Array(sortedSessions.prefix(10))
            isLoadingHistory = false
            Logger.logSuccess("[AUDIT-SLV-06] ✅ \(recentSessions.count) sessions récentes chargées", category: .session)
        }
    }
    
    /// Sauvegarde le tracé actuel dans Firebase
    private func saveCurrentRoute() {
        Logger.log("[AUDIT-SLV-04] 💾 SessionsListView.saveCurrentRoute appelé", category: .location)
        guard let session = viewModel.activeSession,
              let sessionId = session.id,
              let userId = AuthService.shared.currentUserId else {
            return
        }
        
        Task {
            do {
                try await RouteTrackingService.shared.saveRoute(
                    sessionId: sessionId,
                    userId: userId
                )
                Logger.logSuccess("✅ Tracé sauvegardé", category: .location)
            } catch {
                Logger.log("❌ Erreur sauvegarde tracé: \(error.localizedDescription)", category: .location)
            }
        }
    }
}

// MARK: - Recent Session Card

/// Carte compacte pour afficher une session récente
struct RecentSessionCard: View {
    let session: SessionModel
    
    @State private var squadName: String = "Session"
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône selon le statut
            Circle()
                .fill(statusColor)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: statusIcon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
            
            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(squadName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                // Stats rapides (si disponibles)
                HStack(spacing: 12) {
                    // Distance - calculée si endedAt existe
                    if session.endedAt != nil {
                        Label("Session terminée", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    // Durée approximative
                    if let endDate = session.endedAt {
                        let duration = endDate.timeIntervalSince(session.startedAt)
                        Label(formatDuration(duration), systemImage: "clock.fill")
                            .font(.caption2)
                            .foregroundColor(.pinkAccent)
                    }
                    
                    Label("\(session.participants.count)", systemImage: "person.fill")
                        .font(.caption2)
                        .foregroundColor(.blueAccent)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .task {
            await loadSquadName()
        }
    }
    
    private var statusColor: Color {
        switch session.status {
        case .scheduled:
            return .gray
        case .active:
            return .green
        case .paused:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var statusIcon: String {
        switch session.status {
        case .scheduled:
            return "clock.fill"
        case .active:
            return "figure.run"
        case .paused:
            return "pause.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }
    
    private var formattedDate: String {
        let date = session.endedAt ?? session.startedAt
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func loadSquadName() async {
        do {
            if let squad = try await SquadService.shared.getSquad(squadId: session.squadId) {
                squadName = squad.name
            }
        } catch {
            Logger.logError(error, context: "loadSquadName", category: .service)
        }
    }
}

// MARK: - Preview

#Preview {
    SessionsListView()
        .environment(SquadViewModel())
}
