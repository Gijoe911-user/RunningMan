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
                    NoSessionOverlay(onCreateSession: { showCreateSession = true })
                }
            }
            .navigationTitle("Course")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showCreateSession) {
                if let squad = squadsVM.selectedSquad {
                    CreateSessionView(squad: squad)
                }
            }
            .onAppear {
                setupView()
            }
            .task(id: squadsVM.selectedSquad?.id) {
                configureSquadContext()
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
                Logger.log("🎯 Recentré sur l'utilisateur", category: .location)
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
              let userId = AuthService.shared.currentUserId else {
            return false
        }
        
        // Autoriser le créateur de la squad
        if squad.creatorId == userId {
            return true
        }
        
        // Autoriser les admins
        if let role = squad.members[userId], role == .admin {
            return true
        }
        
        // ✅ OPTION 1: Autoriser TOUS les membres (recommandé)
        // return squad.members[userId] != nil
        
        // ✅ OPTION 2: Restreindre aux admins uniquement (strict)
        return false
    }
    
    // MARK: - Actions
    
    /// Configure la vue au démarrage
    private func setupView() {
        viewModel.startLocationUpdates()
        viewModel.centerOnUserLocation()
    }
    
    /// Configure le contexte de la squad sélectionnée
    private func configureSquadContext() {
        guard let squadId = squadsVM.selectedSquad?.id else { return }
        if configuredSquadId != squadId {
            viewModel.setContext(squadId: squadId)
            configuredSquadId = squadId
        }
    }
    
    /// Sauvegarde le tracé actuel dans Firebase
    private func saveCurrentRoute() {
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

// MARK: - Preview

#Preview {
    SessionsListView()
        .environment(SquadViewModel())
}
