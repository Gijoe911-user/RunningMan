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
    @State private var showSquadPicker = false  // 🆕 Picker pour choisir la squad
    @State private var selectedSquadForCreation: SquadModel?  // 🆕 Squad sélectionnée
    
    // 🆕 Nouvelles catégories de sessions
    @State private var myActiveSession: SessionModel?  // Ma session où je cours actuellement
    @State private var activeSessionsWithRunners: [SessionModel] = []  // Sessions actives avec coureurs
    @State private var scheduledSessions: [SessionModel] = []  // Sessions planifiées
    @State private var recentSessions: [SessionModel] = []  // Historique récent (5 dernières)
    @State private var isLoadingHistory = false  // 🆕 État de chargement
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Carte avec tracé GPS
                mapView
                
                // Overlays conditionnels selon les sessions disponibles
                contentOverlay
            }
            .navigationTitle("Course")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showSquadPicker) {
                SquadPickerSheet(
                    squads: squadsVM.userSquads,
                    onSquadSelected: { squad in
                        selectedSquadForCreation = squad
                        showSquadPicker = false
                        showCreateSession = true
                    }
                )
            }
            .sheet(isPresented: $showCreateSession) {
                if let squad = selectedSquadForCreation {
                    CreateSessionView(squad: squad) {
                        // ✅ Callback : Recharger les sessions après création
                        Task {
                            await loadAllSessions()
                        }
                    }
                }
            }
            .onAppear {
                setupView()
            }
            .task(id: squadsVM.selectedSquad?.id) {
                configureSquadContext()
                await loadAllSessions()  // 🆕 Charger toutes les catégories
            }
            .refreshable {
                await loadAllSessions()
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
    
    /// 🆕 Overlay de contenu intelligent selon le contexte
    @ViewBuilder
    private var contentOverlay: some View {
        if let mySession = myActiveSession {
            // 1️⃣ Je cours actuellement → Afficher ma session active
            activeSessionContent(session: mySession)
        } else {
            // 2️⃣ Je ne cours pas → Afficher un dashboard
            dashboardContent
        }
    }
    
    /// 🆕 Dashboard avec toutes les catégories de sessions
    private var dashboardContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 📍 Sessions actives avec coureurs (autres que moi)
                    if !activeSessionsWithRunners.isEmpty {
                        activeSessionsSection
                    }
                    
                    // 📅 Sessions planifiées
                    if !scheduledSessions.isEmpty {
                        scheduledSessionsSection
                    }
                    
                    // 📜 Historique récent
                    if !recentSessions.isEmpty {
                        recentSessionsSection
                    } else if !activeSessionsWithRunners.isEmpty || !scheduledSessions.isEmpty {
                        // Pas d'historique mais il y a des sessions → OK
                    } else if isLoadingHistory {
                        ProgressView()
                            .tint(.white)
                            .padding()
                    } else {
                        // Aucune session du tout → État vide
                        NoSessionOverlay(onCreateSession: {
                            if squadsVM.userSquads.count == 1 {
                                selectedSquadForCreation = squadsVM.userSquads.first
                                showCreateSession = true
                            } else {
                                showSquadPicker = true
                            }
                        })
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(.ultraThinMaterial)
        }
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
    
    /// 🆕 Section des sessions actives avec coureurs
    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    
                    Text("Sessions actives")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Liste des sessions
            ForEach(activeSessionsWithRunners) { session in
                NavigationLink {
                    SessionTrackingView(session: session)
                } label: {
                    ActiveSessionCardCompact(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    /// 🆕 Section des sessions planifiées
    private var scheduledSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.callout)
                        .foregroundColor(.blueAccent)
                    
                    Text("Sessions planifiées")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Liste des sessions
            ForEach(scheduledSessions) { session in
                NavigationLink {
                    SessionTrackingView(session: session)
                } label: {
                    ScheduledSessionCard(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    /// Section des sessions récentes
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.callout)
                        .foregroundColor(.pinkAccent)
                    
                    Text("Sessions récentes")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
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
                // 🆕 Si plusieurs squads, afficher le picker
                if squadsVM.userSquads.count > 1 {
                    showSquadPicker = true
                } else if let squad = squadsVM.userSquads.first {
                    // Une seule squad : créer directement
                    selectedSquadForCreation = squad
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
        guard AuthService.shared.currentUserId != nil else {
            return false
        }
        
        // ✅ Autoriser si l'utilisateur appartient à au moins une squad
        return !squadsVM.userSquads.isEmpty
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
    
    /// 🆕 Charge toutes les sessions (actives, planifiées, historique)
    private func loadAllSessions() async {
        Logger.log("[AUDIT-SLV-05] 📜 Chargement de toutes les sessions...", category: .session)
        isLoadingHistory = true
        
        guard let currentUserId = AuthService.shared.currentUserId else {
            isLoadingHistory = false
            return
        }
        
        var allActiveSessions: [SessionModel] = []
        var allHistorySessions: [SessionModel] = []
        
        // Parcourir toutes les squads de l'utilisateur
        for squad in squadsVM.userSquads {
            guard let squadId = squad.id else { continue }
            
            do {
                // 1️⃣ Récupérer les sessions actives
                let activeSessions = try await SessionService.shared.getActiveSessions(squadId: squadId)
                allActiveSessions.append(contentsOf: activeSessions)
                
                // 2️⃣ Récupérer l'historique
                let history = try await SessionService.shared.getSessionHistory(squadId: squadId)
                allHistorySessions.append(contentsOf: history)
                
            } catch {
                Logger.logError(error, context: "loadAllSessions(squad: \(squadId))", category: .session)
                // Continue avec les autres squads même en cas d'erreur
            }
        }
        
        // Trier l'historique par date décroissante
        let sortedHistory = allHistorySessions.sorted { (session1: SessionModel, session2: SessionModel) -> Bool in
            let date1 = session1.endedAt ?? session1.startedAt
            let date2 = session2.endedAt ?? session2.startedAt
            return date1 > date2
        }
        
        // Filtrer les sessions planifiées (status = .scheduled)
        let sortedScheduled = allActiveSessions.filter { $0.status == .scheduled }
            .sorted { (s1: SessionModel, s2: SessionModel) -> Bool in
                s1.startedAt < s2.startedAt
            }
        
        await MainActor.run {
            // Séparer ma session active des autres
            myActiveSession = allActiveSessions.first { session in
                session.participantActivity?[currentUserId]?.isTracking == true
            }
            
            // Les autres sessions actives (où d'autres coureurs courent)
            activeSessionsWithRunners = allActiveSessions.filter { session in
                // Exclure ma propre session
                if session.id == myActiveSession?.id {
                    return false
                }
                // Ne garder que celles avec au moins un coureur actif
                return session.participantActivity?.values.contains(where: { $0.isTracking }) == true
            }
            
            scheduledSessions = sortedScheduled
            recentSessions = Array(sortedHistory.prefix(10))
            isLoadingHistory = false
            
            Logger.logSuccess("[AUDIT-SLV-06] ✅ Sessions chargées - actives: \(allActiveSessions.count), planifiées: \(scheduledSessions.count), récentes: \(recentSessions.count)", category: .session)
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
        case .ended:
            return .blue
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
        case .ended:
            return "checkmark.circle.fill"
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

// MARK: - 🆕 Active Session Card (Compact)

/// Carte compacte pour une session active avec coureurs
struct ActiveSessionCardCompact: View {
    let session: SessionModel
    
    @State private var squadName: String = "Session"
    @State private var activeRunnersCount: Int = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Badge pulsant
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 30, height: 30)
                
                Image(systemName: "figure.run")
                    .font(.callout)
                    .foregroundColor(.white)
            }
            
            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(squadName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Text("\(activeRunnersCount)")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                    
                    Text(activeRunnersCount > 1 ? "coureurs actifs" : "coureur actif")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Heure de début
                Text("Commencé \(relativeTime)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Bouton rejoindre
            Button {
                // Navigation handled by parent NavigationLink
            } label: {
                Text("Rejoindre")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .task {
            await loadSessionDetails()
        }
    }
    
    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.localizedString(for: session.startedAt, relativeTo: Date())
    }
    
    private func loadSessionDetails() async {
        do {
            if let squad = try await SquadService.shared.getSquad(squadId: session.squadId) {
                squadName = squad.name
            }
            
            // Compter les coureurs actifs
            activeRunnersCount = session.participantActivity?.values.filter { $0.isTracking }.count ?? 0
        } catch {
            Logger.logError(error, context: "loadSessionDetails", category: .service)
        }
    }
}

// MARK: - 🆕 Scheduled Session Card

/// Carte pour une session planifiée
struct ScheduledSessionCard: View {
    let session: SessionModel
    
    @State private var squadName: String = "Session"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title ?? squadName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(squadName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Badge "Planifiée"
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    
                    Text("Planifiée")
                        .font(.caption2.bold())
                }
                .foregroundColor(.blueAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blueAccent.opacity(0.2))
                .clipShape(Capsule())
            }
            
            // Date et heure
            HStack(spacing: 12) {
                Label(formattedDate(session.startedAt), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Label(formattedTime(session.startedAt), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Notes si disponibles
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            // Participants
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                    .foregroundColor(.pinkAccent)
                
                Text("\(session.participants.count) participant(s)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                // Objectifs si définis
                if let targetDistance = session.targetDistanceMeters {
                    Label(FormatHelper.formattedDistance(targetDistance), systemImage: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.coralAccent)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .task {
            await loadSquadName()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
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

// MARK: - 🆕 Squad Picker Sheet

/// Sheet pour sélectionner une squad lors de la création de session
struct SquadPickerSheet: View {
    let squads: [SquadModel]
    let onSquadSelected: (SquadModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "figure.run.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.coralAccent)
                            
                            Text("Choisir une Squad")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Pour quelle squad souhaitez-vous créer une session ?")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Liste des squads
                        ForEach(squads) { squad in
                            Button {
                                onSquadSelected(squad)
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.coralAccent.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: "person.3.fill")
                                                .foregroundColor(.coralAccent)
                                        }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(squad.name)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        
                                        Text("\(squad.members.count) membre(s)")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Nouvelle session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.coralAccent)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SessionsListView()
        .environment(SquadViewModel())
}
