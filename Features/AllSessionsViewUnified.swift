//
//  AllSessionsViewUnified.swift
//  RunningMan
//
//  Vue unifiée listant toutes les sessions actives avec le nouveau SessionRowCard
//  🎯 Permet de tracker UNE session et supporter plusieurs autres
//

import SwiftUI

struct AllSessionsViewUnified: View {
    @StateObject private var viewModel = SessionTrackingViewModel()
    @Environment(SquadViewModel.self) private var squadVM
    
    @State private var showCreateSession = false
    @State private var selectedSquadForSession: SquadModel?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section 1 : Session de tracking active de l'utilisateur
                        if let trackingSession = viewModel.myActiveTrackingSession {
                            activeTrackingSection(trackingSession)
                        }
                        
                        // Section 2 : Sessions suivies en tant que supporter
                        if !viewModel.supporterSessions.isEmpty {
                            supporterSessionsSection
                        }
                        
                        // Section 3 : Toutes les sessions disponibles (avec SessionRowCard)
                        if !viewModel.allActiveSessions.isEmpty {
                            availableSessionsSection
                        }
                        
                        // Section 4 : Historique récent
                        if !viewModel.recentHistory.isEmpty {
                            historySection
                        }
                        
                        // Message si aucune session
                        if viewModel.allActiveSessions.isEmpty &&
                           viewModel.recentHistory.isEmpty &&
                           !viewModel.isLoading {
                            emptyStateView
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await loadSessions()
                }
                
                // Overlay de chargement
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.coralAccent)
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    createSessionMenu
                }
            }
            .task {
                // Chargement initial
                await loadSessions()
            }
            .onAppear {
                // Retry après un court délai pour éviter la "page vide" si le listener/squads ne sont pas prêts
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                    await loadSessions()
                }
            }
            .sheet(isPresented: $showCreateSession) {
                if let squad = selectedSquadForSession {
                    QuickCreateSessionView(squad: squad) { session in
                        Task {
                            _ = await viewModel.startTracking(for: session)
                            await loadSessions()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Section 1: Session de Tracking Active
    
    private func activeTrackingSection(_ session: SessionModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ma session active")
                .font(.headline)
                .foregroundColor(.white)
            
            NavigationLink {
                // Navigation unifiée vers la nouvelle vue détail
                SessionDetailView(session: session)
            } label: {
                TrackingSessionCard(
                    session: session,
                    distance: viewModel.trackingDistance,
                    duration: viewModel.trackingDuration,
                    state: viewModel.trackingState
                )
            }
        }
    }
    
    // MARK: - Section 2: Sessions en mode Supporter
    
    private var supporterSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions que je supporte")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(viewModel.supporterSessions) { session in
                NavigationLink {
                    // Navigation unifiée vers la nouvelle vue détail
                    SessionDetailView(session: session)
                } label: {
                    SupporterSessionCard(session: session)
                }
            }
        }
    }
    
    // MARK: - Section 3: Sessions Disponibles (NOUVEAU avec SessionRowCard)
    
    private var availableSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions actives dans mes squads")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(viewModel.allActiveSessions) { session in
                // Navigation globale vers le détail; les boutons internes restent actifs
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    SessionRowCard(
                        session: session,
                        isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
                        onJoin: {
                            Task {
                                if let sessionId = session.id {
                                    _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
                                    await loadSessions()
                                }
                            }
                        },
                        onStartTracking: {
                            Task {
                                _ = await viewModel.startTracking(for: session)
                                await loadSessions()
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Section 4: Historique Récent
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique récent")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(viewModel.recentHistory) { session in
                NavigationLink {
                    SessionHistoryDetailView(session: session)
                } label: {
                    HistorySessionCard(session: session)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(.coralAccent.opacity(0.5))
            
            Text("Aucune session active")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Créez une session pour commencer à courir avec votre squad")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Menu de Création
    
    private var createSessionMenu: some View {
        Menu {
            ForEach(squadVM.userSquads) { squad in
                Button {
                    selectedSquadForSession = squad
                    showCreateSession = true
                } label: {
                    Label(squad.name, systemImage: "plus.circle")
                }
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(.coralAccent)
        }
        .disabled(viewModel.isLoading || !viewModel.canStartTracking)
    }
    
    // MARK: - Actions
    
    private func loadSessions() async {
        // 🆕 La méthode ne prend plus de paramètres, elle utilise l'userId en interne
        viewModel.loadAllActiveSessions()
    }
}

// MARK: - Quick Create Session View (Vue rapide de création)

struct QuickCreateSessionView: View {
    let squad: SquadModel
    let onCreated: (SessionModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // En-tête
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.coralAccent)
                        
                        Text("Créer une session")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("pour \(squad.name)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bouton Créer
                    Button {
                        createSession()
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Créer et démarrer le tracking")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.coralAccent, Color.pinkAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isCreating)
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.coralAccent)
                    .disabled(isCreating)
                }
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
    
    private func createSession() {
        guard let squadId = squad.id else {
            errorMessage = "Squad invalide"
            return
        }
        
        guard let userId = AuthService.shared.currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        isCreating = true
        
        Task {
            do {
                let session = try await SessionService.shared.createSession(
                    squadId: squadId,
                    creatorId: userId,
                    startLocation: nil
                )
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                    onCreated(session)
                }
                
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AllSessionsViewUnified()
        .preferredColorScheme(.dark)
        .environment(SquadViewModel())
}
