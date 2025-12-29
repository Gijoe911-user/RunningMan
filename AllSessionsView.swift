//
//  AllSessionsView.swift
//  RunningMan
//
//  Vue globale de toutes les sessions (remplace SessionsListView dans l'onglet)
//

import SwiftUI

struct AllSessionsView: View {
    @Environment(SquadViewModel.self) private var squadVM
    
    @State private var activeSessions: [SessionModel] = []
    @State private var recentHistory: [SessionModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showMap = false
    @State private var hasLoaded = false  // ✅ FIX: Cache pour éviter de recharger
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.coralAccent)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Squads avec sessions actives
                            if !squadsWithActiveSessions.isEmpty {
                                squadsSection
                            }
                            
                            // Sessions actives (toutes)
                            if !activeSessions.isEmpty {
                                activeSessionsSection
                            } else if !isLoading {
                                noActiveSessionsBanner
                            }
                            
                            // Historique récent
                            if !recentHistory.isEmpty {
                                historySection
                            }
                            
                            // Empty state global
                            if activeSessions.isEmpty && recentHistory.isEmpty && !isLoading {
                                emptyState
                            }
                        }
                        .padding()
                    }
                }
                
                // Bouton flottant pour voir la carte (toujours visible si on a des squads)
                if !squadVM.userSquads.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                showMap = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "map.fill")
                                    Text("Carte")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color.coralAccent, Color.pinkAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Mes Sessions")
            .navigationDestination(isPresented: $showMap) {
                SessionsListView()  // L'ancienne vue carte
            }
            .task {
                // ✅ FIX: Ne charger qu'une seule fois
                if !hasLoaded {
                    await loadAllSessions()
                    hasLoaded = true
                }
            }
            .refreshable {
                await loadAllSessions()
            }
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Squads Section
    
    private var squadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mes Squads")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(squadsWithActiveSessions.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            
            ForEach(squadsWithActiveSessions) { squad in
                NavigationLink(destination: SquadSessionsListView(squad: squad)) {
                    SquadActiveSessionCard(squad: squad)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Active Sessions Section
    
    private var activeSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sessions actives")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text("Rejoignez une session en cours")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("\(activeSessions.count)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
            
            ForEach(activeSessions.filter { $0.id != nil }) { session in
                NavigationLink(destination: ActiveSessionDetailView(session: session)) {
                    ActiveSessionCard(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Historique récent")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                if recentHistory.count > 5 {
                    NavigationLink("Voir tout") {
                        // TODO: Vue d'historique complet
                        Text("Historique complet")
                    }
                    .font(.subheadline)
                    .foregroundColor(.coralAccent)
                }
            }
            
            ForEach(recentHistory.prefix(5).filter { $0.id != nil }) { session in
                NavigationLink(destination: SessionHistoryDetailView(session: session)) {
                    HistorySessionCard(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Empty States
    
    private var noActiveSessionsBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blueAccent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aucune session active")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text("Créez une session depuis votre squad")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
            .background(Color.blueAccent.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.coralAccent.opacity(0.3), Color.pinkAccent.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.coralAccent)
            }
            
            VStack(spacing: 12) {
                Text("Aucune session")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Rejoignez un squad et créez votre première session pour commencer à courir avec d'autres")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Bouton vers les squads
            NavigationLink {
                Text("Squads View")  // Placeholder - À remplacer par SquadListView()
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("Voir mes squads")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.purpleAccent, Color.blueAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var squadsWithActiveSessions: [SquadModel] {
        squadVM.userSquads.filter { $0.hasActiveSessions }  // ✅ CORRIGÉ
    }
    
    // MARK: - Load Data
    
    private func loadAllSessions() async {
        isLoading = true
        errorMessage = nil
        
        // Charger les sessions de TOUS les squads de l'utilisateur
        let userSquads = squadVM.userSquads  // ✅ CORRIGÉ
        
        guard !userSquads.isEmpty else {
            isLoading = false
            return
        }
        
        var allActiveSessions: [SessionModel] = []
        var allHistorySessions: [SessionModel] = []
        
        // ✅ FIX: Limiter à 2 requêtes parallèles max pour éviter de surcharger
        let maxConcurrency = 2
        var currentIndex = 0
        
        while currentIndex < userSquads.count {
            let batch = Array(userSquads[currentIndex..<min(currentIndex + maxConcurrency, userSquads.count)])
            
            await withTaskGroup(of: (active: [SessionModel]?, history: [SessionModel]?).self) { group in
                for squad in batch {
                    guard let squadId = squad.id else { continue }
                    
                    group.addTask {
                        let active = try? await SessionService.shared.getActiveSessions(squadId: squadId)
                        let history = try? await SessionService.shared.getSessionHistory(squadId: squadId, limit: 10)
                        return (active, history)
                    }
                }
                
                for await result in group {
                    if let active = result.active {
                        allActiveSessions.append(contentsOf: active)
                    }
                    if let history = result.history {
                        allHistorySessions.append(contentsOf: history)
                    }
                }
            }
            
            currentIndex += maxConcurrency
        }
        
        // Trier par date (plus récent en premier)
        activeSessions = allActiveSessions
            .filter { $0.id != nil }  // ✅ FIX: Filtrer les sessions sans ID
            .sorted { $0.startedAt > $1.startedAt }
        
        recentHistory = allHistorySessions
            .filter { $0.id != nil }  // ✅ FIX: Filtrer les sessions sans ID
            .sorted { ($0.endedAt ?? Date()) > ($1.endedAt ?? Date()) }
        
        Logger.logSuccess("✅ Chargé: \(activeSessions.count) actives, \(recentHistory.count) historique", category: .service)
        isLoading = false
    }
}

// MARK: - Squad Active Session Card

struct SquadActiveSessionCard: View {
    let squad: SquadModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Squad icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.coralAccent, .pinkAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            
            // Squad info
            VStack(alignment: .leading, spacing: 4) {
                Text(squad.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Session active")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AllSessionsView()
            .environment(SquadViewModel())
    }
    .preferredColorScheme(.dark)
}
