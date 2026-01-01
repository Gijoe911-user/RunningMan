//
//  EXEMPLE_UTILISATION_SESSIONROWCARD.swift
//  RunningMan
//
//  Guide d'utilisation du composant SessionRowCard
//

import SwiftUI

// ========================================
// EXEMPLE 1 : Utilisation Simple
// ========================================

struct ExempleSimple: View {
    @StateObject private var viewModel = SessionTrackingViewModel()
    @Environment(SquadViewModel.self) private var squadVM
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.allActiveSessions) { session in
                    SessionRowCard(
                        session: session,
                        isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
                        onJoin: {
                            Task {
                                if let sessionId = session.id {
                                    _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
                                }
                            }
                        },
                        onStartTracking: {
                            Task {
                                _ = await viewModel.startTracking(for: session)
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .task {
            let squadIds = squadVM.userSquads.compactMap { $0.id }
            await viewModel.loadAllActiveSessions(squadIds: squadIds)
        }
    }
}

// ========================================
// EXEMPLE 2 : Avec Gestion d'Erreurs
// ========================================

struct ExempleAvecGestionErreurs: View {
    @StateObject private var viewModel = SessionTrackingViewModel()
    @Environment(SquadViewModel.self) private var squadVM
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.allActiveSessions) { session in
                    SessionRowCard(
                        session: session,
                        isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
                        onJoin: {
                            Task {
                                await joinSession(session)
                            }
                        },
                        onStartTracking: {
                            Task {
                                await startTracking(session)
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Une erreur est survenue")
        }
    }
    
    private func joinSession(_ session: SessionModel) async {
        guard let sessionId = session.id else {
            errorMessage = "Session invalide"
            showError = true
            return
        }
        
        let success = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
        if !success {
            errorMessage = viewModel.errorMessage ?? "Impossible de rejoindre la session"
            showError = true
        }
    }
    
    private func startTracking(_ session: SessionModel) async {
        let success = await viewModel.startTracking(for: session)
        if !success {
            errorMessage = viewModel.errorMessage ?? "Impossible de démarrer le tracking"
            showError = true
        }
    }
}

// ========================================
// EXEMPLE 3 : Avec Navigation
// ========================================

struct ExempleAvecNavigation: View {
    @StateObject private var viewModel = SessionTrackingViewModel()
    @Environment(SquadViewModel.self) private var squadVM
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.allActiveSessions) { session in
                        // Wrapper pour permettre la navigation
                        Button {
                            // Navigation vers les détails (optionnel)
                        } label: {
                            SessionRowCard(
                                session: session,
                                isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
                                onJoin: {
                                    Task {
                                        if let sessionId = session.id {
                                            _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
                                        }
                                    }
                                },
                                onStartTracking: {
                                    Task {
                                        _ = await viewModel.startTracking(for: session)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain) // Important pour garder le style de la card
                    }
                }
                .padding()
            }
            .navigationTitle("Sessions actives")
            .refreshable {
                let squadIds = squadVM.userSquads.compactMap { $0.id }
                await viewModel.loadAllActiveSessions(squadIds: squadIds)
            }
        }
    }
}

// ========================================
// EXEMPLE 4 : Avec Filtrage
// ========================================

struct ExempleAvecFiltrage: View {
    @StateObject private var viewModel = SessionTrackingViewModel()
    @Environment(SquadViewModel.self) private var squadVM
    @State private var selectedActivityType: ActivityType?
    
    var filteredSessions: [SessionModel] {
        if let type = selectedActivityType {
            return viewModel.allActiveSessions.filter { $0.activityType == type }
        }
        return viewModel.allActiveSessions
    }
    
    var body: some View {
        VStack {
            // Filtres
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterButton(
                        title: "Tout",
                        isSelected: selectedActivityType == nil,
                        action: { selectedActivityType = nil }
                    )
                    
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        FilterButton(
                            title: type.displayName,
                            isSelected: selectedActivityType == type,
                            action: { selectedActivityType = type }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Liste des sessions
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(filteredSessions) { session in
                        SessionRowCard(
                            session: session,
                            isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
                            onJoin: {
                                Task {
                                    if let sessionId = session.id {
                                        _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
                                    }
                                }
                            },
                            onStartTracking: {
                                Task {
                                    _ = await viewModel.startTracking(for: session)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.coralAccent : Color.white.opacity(0.1)
                )
                .clipShape(Capsule())
        }
    }
}

// ========================================
// EXEMPLE 5 : Avec État Vide
// ========================================

struct ExempleAvecEtatVide: View {
    @StateObject private var viewModel = SessionTrackingViewModel()
    @Environment(SquadViewModel.self) private var squadVM
    
    var body: some View {
        ScrollView {
            if viewModel.allActiveSessions.isEmpty {
                // État vide
                VStack(spacing: 16) {
                    Image(systemName: "figure.run.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.coralAccent.opacity(0.5))
                    
                    Text("Aucune session active")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Créez une session pour commencer")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // Liste des sessions
                VStack(spacing: 12) {
                    ForEach(viewModel.allActiveSessions) { session in
                        SessionRowCard(
                            session: session,
                            isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
                            onJoin: {
                                Task {
                                    if let sessionId = session.id {
                                        _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
                                    }
                                }
                            },
                            onStartTracking: {
                                Task {
                                    _ = await viewModel.startTracking(for: session)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// ========================================
// EXEMPLE 6 : Avec Loading State
// ========================================

struct ExempleAvecLoading: View {
    @StateObject private var viewModel = SessionTrackingViewModel()
    @Environment(SquadViewModel.self) private var squadVM
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.allActiveSessions) { session in
                        SessionRowCard(
                            session: session,
                            isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
                            onJoin: {
                                Task {
                                    if let sessionId = session.id {
                                        _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
                                        await reloadSessions()
                                    }
                                }
                            },
                            onStartTracking: {
                                Task {
                                    _ = await viewModel.startTracking(for: session)
                                    await reloadSessions()
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            
            // Overlay de chargement
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.coralAccent)
                }
            }
        }
        .task {
            await reloadSessions()
        }
    }
    
    private func reloadSessions() async {
        let squadIds = squadVM.userSquads.compactMap { $0.id }
        await viewModel.loadAllActiveSessions(squadIds: squadIds)
    }
}

// ========================================
// EXEMPLE 7 : Personnalisation Avancée
// ========================================

struct ExemplePersonnalise: View {
    @StateObject private var viewModel = SessionTrackingViewModel()
    @Environment(SquadViewModel.self) private var squadVM
    @State private var selectedSession: SessionModel?
    @State private var showDetailSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.allActiveSessions) { session in
                    SessionRowCard(
                        session: session,
                        isMyTracking: session.id == viewModel.myActiveTrackingSession?.id,
                        onJoin: {
                            Task {
                                if let sessionId = session.id {
                                    _ = await viewModel.joinSessionAsSupporter(sessionId: sessionId)
                                }
                            }
                        },
                        onStartTracking: {
                            Task {
                                _ = await viewModel.startTracking(for: session)
                            }
                        }
                    )
                    .onTapGesture {
                        selectedSession = session
                        showDetailSheet = true
                    }
                    // Animations personnalisées
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: viewModel.allActiveSessions.count)
                }
            }
            .padding()
        }
        .sheet(item: $selectedSession) { session in
            // Vue de détail personnalisée
            SessionDetailSheet(session: session)
        }
    }
}

struct SessionDetailSheet: View {
    let session: SessionModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: session.activityType.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.coralAccent)
                
                Text(session.activityType.displayName)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("\(session.participants.count) participants")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.darkNavy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(.coralAccent)
                }
            }
        }
    }
}

// ========================================
// BONNES PRATIQUES
// ========================================

/*
 
 ✅ DO:
 - Utiliser @StateObject pour le ViewModel
 - Gérer les cas d'erreur avec @State + alert
 - Afficher un état de chargement (isLoading)
 - Rafraîchir les données avec .refreshable
 - Utiliser Task pour les appels async
 
 ❌ DON'T:
 - Ne pas utiliser @ObservedObject (préférer @StateObject)
 - Ne pas bloquer le main thread
 - Ne pas oublier de vérifier session.id avant utilisation
 - Ne pas ignorer les erreurs du ViewModel
 
 💡 TIPS:
 - Utilisez .buttonStyle(.plain) avec NavigationLink pour garder le style
 - Ajoutez des animations avec .animation() pour une meilleure UX
 - Pensez au pull-to-refresh avec .refreshable
 - Ajoutez des haptics feedback pour les interactions importantes
 
 */

// ========================================
// CONFIGURATION MINIMALE REQUISE
// ========================================

/*
 
 Pour utiliser SessionRowCard, assurez-vous d'avoir :
 
 1. SessionModel avec :
    - id: String?
    - activityType: ActivityType
    - participants: [String]
    - distanceInKilometers: Double
    - formattedDuration: String
 
 2. SessionTrackingViewModel avec :
    - @Published var myActiveTrackingSession: SessionModel?
    - @Published var allActiveSessions: [SessionModel]
    - func startTracking(for:) async -> Bool
    - func joinSessionAsSupporter(sessionId:) async -> Bool
    - func loadAllActiveSessions(squadIds:) async
 
 3. SquadViewModel en @Environment avec :
    - var userSquads: [SquadModel]
 
 4. ActivityType enum avec :
    - case training, race, interval, recovery
    - var displayName: String
    - var icon: String
 
 */
