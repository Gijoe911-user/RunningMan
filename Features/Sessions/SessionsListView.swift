//
//  SessionsListView.swift
//  RunningMan
//
//  Liste des sessions de course
//

import SwiftUI
import Combine
import CoreLocation
import MapKit

struct SessionsListView: View {
    @Environment(SquadViewModel.self) private var squadsVM
    
    @StateObject private var viewModel = SessionsViewModel()
    @State private var configuredSquadId: String? = nil
    @State private var showCreateSession = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Carte améliorée avec tracé et contrôles
                EnhancedSessionMapView(
                    userLocation: viewModel.userLocation,
                    runnerLocations: viewModel.activeRunners,
                    routeCoordinates: viewModel.routeCoordinates,
                    runnerRoutes: [:], // TODO: Ajouter les tracés des autres coureurs depuis ViewModel
                    onRecenter: {
                        Logger.log("🎯 Recentré sur l'utilisateur", category: .location)
                    },
                    onSaveRoute: {
                        saveCurrentRoute()
                    }
                )
                .ignoresSafeArea(edges: .top)
                
                // Overlay conditionnel selon l'état de la session
                if let session = viewModel.activeSession {
                    // Session active : afficher l'overlay avec infos + participants
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Overlay des participants (en haut de l'overlay principal)
                        if !viewModel.activeRunners.isEmpty {
                            SessionParticipantsOverlay(
                                participants: viewModel.activeRunners,
                                userLocation: viewModel.userLocation,
                                onRunnerTap: { runnerId in
                                    Logger.log("🎯 Clic sur coureur: \(runnerId)", category: .location)
                                    // TODO: Centrer la carte sur ce coureur
                                    // mapView.centerOnRunner(runnerId: runnerId)
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        }
                        
                        // Overlay principal de la session
                        SessionActiveOverlay(session: session, viewModel: viewModel)
                    }
                } else {
                    NoSessionOverlay(onCreateSession: { showCreateSession = true })
                }
            }
            .navigationTitle("Course")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if squadsVM.selectedSquad != nil {
                            showCreateSession = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.coralAccent)
                            .font(.title2)
                    }
                    .disabled(squadsVM.selectedSquad == nil)
                }
            }
            .sheet(isPresented: $showCreateSession) {
                if let squad = squadsVM.selectedSquad {
                    CreateSessionView(squad: squad)
                }
            }
            .onAppear {
                viewModel.startLocationUpdates()
                viewModel.centerOnUserLocation()
            }
            .task(id: squadsVM.selectedSquad?.id) {
                guard let squadId = squadsVM.selectedSquad?.id else { return }
                if configuredSquadId != squadId {
                    viewModel.setContext(squadId: squadId)
                    configuredSquadId = squadId
                }
            }
        }
    }
    
    // MARK: - Actions
    
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

// MARK: - Session Active Overlay

struct SessionActiveOverlay: View {
    let session: SessionModel
    @ObservedObject var viewModel: SessionsViewModel
    
    @State private var showEndConfirmation = false
    @State private var isEnding = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Panel infos session
            sessionInfoPanel
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.2), radius: 10, y: -5)
                .padding()
        }
        .alert("Terminer la session ?", isPresented: $showEndConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Terminer", role: .destructive) {
                Task {
                    await endSession()
                }
            }
        } message: {
            Text("Cette action mettra fin à la session pour tous les participants.")
        }
        .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private var sessionInfoPanel: some View {
        VStack(spacing: 16) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Titre de la session
            VStack(spacing: 4) {
                Text(session.title ?? "Session Active")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text(session.activityType.displayName)
                    .font(.caption)
                    .foregroundColor(.coralAccent)
            }
            
            // Stats rapides
            HStack(spacing: 20) {
                StatBadge(
                    icon: "figure.run",
                    value: "\(viewModel.activeRunners.count)",
                    label: "Coureurs"
                )
                
                if let distance = session.targetDistanceMeters {
                    StatBadge(
                        icon: "location.fill",
                        value: String(format: "%.1f km", distance / 1000),
                        label: "Objectif"
                    )
                }
                
                StatBadge(
                    icon: "clock.fill",
                    value: timeElapsed,
                    label: "Temps"
                )
            }
            .padding(.vertical, 8)
            
            // Liste compacte des runners
            if !viewModel.activeRunners.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coureurs actifs")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.7))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.activeRunners.prefix(5)) { runner in
                                RunnerCompactCard(runner: runner)
                            }
                            
                            if viewModel.activeRunners.count > 5 {
                                Text("+\(viewModel.activeRunners.count - 5)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 50, height: 50)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            
            // Bouton terminer
            Button {
                if !isEnding {
                    showEndConfirmation = true
                }
            } label: {
                HStack {
                    if isEnding {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        Text("Terminaison en cours...")
                    } else {
                        Image(systemName: "stop.circle.fill")
                        Text("Terminer la session")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isEnding ? Color.red.opacity(0.6) : Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isEnding)
            .animation(.easeInOut, value: isEnding)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func endSession() async {
        Logger.log("🔴 endSession() appelé - isEnding: \(isEnding)", category: .session)
        
        guard !isEnding else {
            Logger.log("⚠️ Déjà en cours de terminaison, ignoré", category: .session)
            return
        }
        
        isEnding = true
        errorMessage = nil // Reset les erreurs précédentes
        
        Logger.log("🔄 Début de la terminaison...", category: .session)
        
        do {
            try await viewModel.endSession()
            // SUCCESS: La vue se mettra à jour automatiquement quand activeSession sera nil
            Logger.log("✅ endSession() réussi, isEnding = false", category: .session)
            isEnding = false
        } catch {
            // ERROR: Afficher l'erreur et permettre de réessayer
            Logger.log("❌ endSession() échoué: \(error.localizedDescription)", category: .session)
            errorMessage = error.localizedDescription
            isEnding = false
        }
    }
    
    private var timeElapsed: String {
        let elapsed = Date().timeIntervalSince(session.startedAt)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SessionsEmptyView: View {
    @Environment(SquadViewModel.self) private var squadVM
    @State private var showCreateSession = false
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.coralAccent.opacity(0.3), Color.coralAccent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.coralAccent)
                        .symbolEffect(.pulse)
                }
                
                VStack(spacing: 12) {
                    Text("Aucune session active")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Créez une session pour commencer à courir avec votre squad")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                if let squad = squadVM.selectedSquad {
                    Button {
                        showCreateSession = true
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Démarrer une session")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
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
                    .sheet(isPresented: $showCreateSession) {
                        CreateSessionView(squad: squad)
                    }
                    
                    // 🧪 DEBUG: Bouton pour voir la carte (TEMPORAIRE)
                    #if DEBUG
                    Text("Debug: Voir la carte de test")
                        .font(.caption.bold())
                        .foregroundColor(.yellowAccent)
                        .padding(.top, 20)
                    
                    Text("Pour tester: Démarrez une vraie session ci-dessus ↑")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    #endif
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellowAccent)
                        Text("Sélectionnez un squad d'abord")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
}

struct RunnerRowView: View {
    let runner: RunnerLocation
    
    var body: some View {
        HStack {
            if let photoURL = runner.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text(runner.displayName)
                    .font(.headline)
                Text(runner.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.coralAccent)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct RunnerCompactCard: View {
    let runner: RunnerLocation
    
    var body: some View {
        VStack(spacing: 4) {
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
            
            // Nom
            Text(runner.displayName)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 60)
    }
}

// MARK: - SessionMapView
// Note: SessionMapView a été remplacé par EnhancedSessionMapView
// Voir EnhancedSessionMapView.swift pour la version complète avec tracés et contrôles

// MARK: - Runner Map Marker
// Note: RunnerMapMarker est maintenant défini dans EnhancedSessionMapView.swift
// Cette version locale a été retirée pour éviter les redéclarations

// MARK: - No Session Overlay

struct NoSessionOverlay: View {
    let onCreateSession: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                // Icône
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.coralAccent.opacity(0.3), Color.pinkAccent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "figure.run.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.coralAccent)
                }
                
                VStack(spacing: 8) {
                    Text("Aucune session active")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text("Créez une session pour commencer à courir avec votre squad")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: onCreateSession) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Créer une session")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.coralAccent, Color.pinkAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .coralAccent.opacity(0.5), radius: 10, y: 5)
                }
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding()
            
            Spacer()
        }
    }
}



#Preview {
    // Pour l’aperçu, on peut injecter un SquadViewModel mock si nécessaire
    SessionsListView()
        .environment(SquadViewModel())
}
