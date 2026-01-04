//
//  SquadSessionsListView.swift
//  RunningMan
//
//  Liste des sessions d'un squad (actives + historique)
//

import SwiftUI

struct SquadSessionsListView: View {
    let squad: SquadModel
    
    @State private var activeSessions: [SessionModel] = []
    @State private var historySessions: [SessionModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab: SessionTab = .active
    @State private var hasLoaded = false  // ✅ FIX: Cache pour éviter de recharger
    
    enum SessionTab {
        case active
        case history
    }
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented Control
                customSegmentedControl
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                
                // Content
                if isLoading {
                    ProgressView()
                        .tint(.coralAccent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $selectedTab) {
                        activeSessionsTab
                            .tag(SessionTab.active)
                        
                        historySessionsTab
                            .tag(SessionTab.history)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .navigationTitle("Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // ✅ FIX: Ne charger qu'une seule fois
            if !hasLoaded {
                await loadSessions()
                hasLoaded = true
            }
        }
        .refreshable {
            await loadSessions()
        }
        .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Custom Segmented Control
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            // Tab Active
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .active
                }
            } label: {
                Text("Actives")
                    .font(.subheadline.bold())
                    .foregroundColor(selectedTab == .active ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == .active ?
                        AnyView(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.coralAccent)
                        ) :
                        AnyView(Color.clear)
                    )
            }
            
            // Tab History
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = .history
                }
            } label: {
                Text("Historique")
                    .font(.subheadline.bold())
                    .foregroundColor(selectedTab == .history ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == .history ?
                        AnyView(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.coralAccent)
                        ) :
                        AnyView(Color.clear)
                    )
            }
        }
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Active Sessions Tab
    
    private var activeSessionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if activeSessions.isEmpty {
                    emptyActiveSessionsView
                } else {
                    ForEach(activeSessions.filter { $0.id != nil }) { session in
                        // ✅ FIX: Utiliser SessionHistoryDetailView en attendant ActiveSessionDetailView
                        NavigationLink(destination: SessionHistoryDetailView(session: session)) {
                            ActiveSessionCard(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - History Sessions Tab
    
    private var historySessionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if historySessions.isEmpty {
                    emptyHistoryView
                } else {
                    ForEach(historySessions.filter { $0.id != nil }) { session in
                        NavigationLink(destination: SessionHistoryDetailView(session: session)) {
                            HistorySessionCard(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty States
    
    private var emptyActiveSessionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(.coralAccent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Aucune session active")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("Créez une session pour commencer à courir avec votre squad")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.coralAccent.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Aucune session passée")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("Les sessions terminées apparaîtront ici")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Load Sessions
    
    private func loadSessions() async {
        guard let squadId = squad.id else {
            errorMessage = "Squad ID invalide"
            isLoading = false
            return
        }
        
        // ✅ Invalider le cache avant de recharger
        SessionService.shared.invalidateCache(squadId: squadId)
        Logger.log("[AUDIT-SSL-01] 🔄 SquadSessionsListView.loadSessions - Cache invalidé pour squad: \(squadId)", category: .ui)
        
        isLoading = true
        errorMessage = nil  // Reset l'erreur précédente
        
        // ✅ FIX: Timeout de sécurité réduit à 5 secondes
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 secondes
            if isLoading {
                Logger.log("⏱️ Timeout atteint lors du chargement des sessions", category: .service)
                isLoading = false
                // ✅ NE PAS afficher d'erreur si on a déjà des données
                if activeSessions.isEmpty && historySessions.isEmpty {
                    errorMessage = "Le chargement prend trop de temps. Veuillez réessayer."
                }
            }
        }
        
        do {
            // Charger les sessions actives
            activeSessions = try await SessionService.shared.getActiveSessions(squadId: squadId)
            
            // Charger l'historique
            historySessions = try await SessionService.shared.getSessionHistory(squadId: squadId)
            
            Logger.logSuccess("✅ Sessions chargées: \(activeSessions.count) actives, \(historySessions.count) historique", category: .service)
            
            // ✅ Annuler le timeout si le chargement réussit
            timeoutTask.cancel()
            isLoading = false
        } catch {
            Logger.logError(error, context: "loadSessions - squadId: \(squadId)", category: .service)
            
            // ✅ Annuler le timeout en cas d'erreur
            timeoutTask.cancel()
            
            // Message d'erreur plus informatif
            if activeSessions.isEmpty && historySessions.isEmpty {
                // Peut-être simplement qu'il n'y a pas de sessions (ce n'est pas une erreur)
                errorMessage = nil  // Pas d'erreur, juste vide
                Logger.log("ℹ️ Aucune session trouvée pour ce squad", category: .service)
            } else {
                errorMessage = "Erreur de chargement: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}

// MARK: - Active Session Card

struct ActiveSessionCard: View {
    let session: SessionModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = session.title {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(session.activityType.displayName)
                        .font(.caption)
                        .foregroundColor(.coralAccent)
                }
                
                Spacer()
                
                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(statusText)
                        .font(.caption.bold())
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.2))
                .clipShape(Capsule())
            }
            
            // Stats
            HStack(spacing: 20) {
                StatBadgeCompact(
                    icon: "figure.run",
                    value: "\(session.participants.count)",
                    label: "Coureurs"
                )
                
                StatBadgeCompact(
                    icon: "clock.fill",
                    value: timeElapsed,
                    label: "En cours"
                )
                
                if let targetDistance = session.targetDistanceMeters {
                    StatBadgeCompact(
                        icon: "location.fill",
                        value: String(format: "%.1f km", targetDistance / 1000),
                        label: "Objectif"
                    )
                }
            }
            
            // Join button
            HStack {
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Rejoindre")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.coralAccent)
                .clipShape(Capsule())
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var statusColor: Color {
        session.status == .active ? .green : .orange
    }
    
    private var statusText: String {
        session.status == .active ? "Active" : "Pause"
    }
    
    private var timeElapsed: String {
        let elapsed = Date().timeIntervalSince(session.startedAt)
        let minutes = Int(elapsed) / 60
        let hours = minutes / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes % 60)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Components are now imported from SessionCardComponents.swift
// HistorySessionCard and StatBadgeCompact are defined there

// MARK: - Preview

#Preview {
    NavigationStack {
        SquadSessionsListView(squad: SquadModel(
            name: "Marathon Paris 2024",
            description: "Préparation marathon",
            inviteCode: "ABC123",
            creatorId: "user1",
            members: ["user1": .admin]
        ))
    }
    .preferredColorScheme(.dark)
}
