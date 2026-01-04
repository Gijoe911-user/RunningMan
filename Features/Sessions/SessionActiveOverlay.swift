//
//  SessionActiveOverlay.swift
//  RunningMan
//
//  Overlay affiché pendant une session active
//

import SwiftUI

/// Overlay principal affiché en bas de l'écran pendant une session active
///
/// Affiche :
/// - Titre et type de session
/// - Stats rapides (coureurs, objectif, temps)
/// - Liste compacte des coureurs actifs
/// - **Contrôles de tracking (Play/Pause/Stop)** via `SessionTrackingControlsView`
///
/// **Position :** Bas de l'écran, au-dessus de la carte
///
/// **Architecture :**
/// - Utilise `SessionsViewModel` pour les données de session et coureurs
/// - Utilise `TrackingManager` pour les contrôles de tracking
/// - Synchronise les deux systèmes lors de l'arrêt
///
/// **Usage :**
/// ```swift
/// if let session = viewModel.activeSession {
///     SessionActiveOverlay(session: session, viewModel: viewModel)
/// }
/// ```
///
/// - SeeAlso: `SessionsListView`, `SessionsViewModel`, `TrackingManager`, `SessionTrackingControlsView`
struct SessionActiveOverlay: View {
    
    // MARK: - Properties
    
    /// Session de course active
    let session: SessionModel
    
    /// ViewModel pour accéder aux données en temps réel
    @ObservedObject var viewModel: SessionsViewModel
    
    // MARK: - Tracking Manager
    
    /// Manager de tracking pour les contrôles Play/Pause/Stop
    @ObservedObject private var trackingManager = TrackingManager.shared
    
    // MARK: - State
    
    /// État local du tracking
    @State private var currentTrackingState: TrackingState = .idle
    
    /// Affiche la confirmation avant de terminer la session
    @State private var showEndConfirmation = false
    
    /// Indique si la terminaison est en cours
    @State private var isEnding = false
    
    /// Message d'erreur éventuel
    @State private var errorMessage: String?
    
    // MARK: - Body
    
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
                    await stopTrackingAndEndSession()
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
        .onAppear {
            // Synchroniser l'état au démarrage
            currentTrackingState = trackingManager.trackingState
            
            // Démarrer automatiquement le tracking si pas encore fait
            if trackingManager.trackingState == .idle {
                Task {
                    _ = await trackingManager.startTracking(for: session)
                }
            }
        }
        .onChange(of: trackingManager.trackingState) { _, newState in
            currentTrackingState = newState
        }
    }
    
    // MARK: - View Components
    
    /// Panel principal avec toutes les infos de la session
    private var sessionInfoPanel: some View {
        VStack(spacing: 16) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Titre de la session
            sessionHeader
            
            // Stats rapides (remplacé par StatBadgeCompact)
            quickStats
            
            // Liste des coureurs
            if !viewModel.activeRunners.isEmpty {
                activaRunnersList
            }
            
            // Contrôles de tracking (Play/Pause/Stop)
            trackingControls
        }
        .padding()
    }
    
    /// En-tête avec titre et type de session
    private var sessionHeader: some View {
        VStack(spacing: 4) {
            Text(session.title ?? "Session Active")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(session.activityType.displayName)
                .font(.caption)
                .foregroundColor(.coralAccent)
        }
    }
    
    /// Stats rapides (coureurs, objectif, temps) -> StatBadgeCompact
    private var quickStats: some View {
        HStack(spacing: 20) {
            StatBadgeCompact(
                icon: "figure.run",
                value: "\(viewModel.activeRunners.count)",
                label: "Coureurs"
            )
            
            if let distance = session.targetDistanceMeters {
                StatBadgeCompact(
                    icon: "location.fill",
                    value: String(format: "%.1f km", distance / 1000),
                    label: "Objectif"
                )
            }
            
            StatBadgeCompact(
                icon: "clock.fill",
                value: timeElapsed,
                label: "Temps"
            )
        }
        .padding(.vertical, 8)
    }
    
    /// Liste horizontale des coureurs actifs
    private var activaRunnersList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Coureurs actifs")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.7))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.activeRunners.prefix(5)) { runner in
                        // RunnerCompactCard inline
                        VStack(spacing: 6) {
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
                                                .font(.caption)
                                        }
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.coralAccent.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.coralAccent)
                                            .font(.caption)
                                    }
                            }
                            
                            // Nom
                            Text(runner.displayName)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: 60)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
    
    /// Contrôles de tracking (Play/Pause/Stop)
    private var trackingControls: some View {
        SessionTrackingControlsView(
            session: session,
            trackingState: $currentTrackingState,
            onStart: {
                _ = await trackingManager.startTracking(for: session)
            },
            onPause: {
                await trackingManager.pauseTracking()
            },
            onResume: {
                await trackingManager.resumeTracking()
            },
            onStop: {
                // Arrêter le tracking ET la session
                await stopTrackingAndEndSession()
            }
        )
    }
    
    /// Bouton pour terminer la session (ANCIEN - GARDÉ EN COMMENTAIRE)
    private var endSessionButton_OLD: some View {
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
    
    // MARK: - Computed Properties
    
    /// Temps écoulé depuis le début de la session
    private var timeElapsed: String {
        let elapsed = Date().timeIntervalSince(session.startedAt)
        return SessionStatsFormatters.formatTimeElapsed(elapsed)
    }
    
    // MARK: - Actions
    
    /// Arrête le tracking TrackingManager ET termine la session dans SessionsViewModel
    private func stopTrackingAndEndSession() async {
        Logger.log("🔴 stopTrackingAndEndSession() appelé", category: .session)
        
        guard !isEnding else {
            Logger.log("⚠️ Déjà en cours de terminaison, ignoré", category: .session)
            return
        }
        
        isEnding = true
        errorMessage = nil
        
        do {
            // 1. Arrêter le tracking dans TrackingManager
            Logger.log("🛑 Arrêt du TrackingManager...", category: .session)
            try await trackingManager.stopTracking()
            Logger.log("✅ TrackingManager arrêté", category: .session)
            
            // 2. Attendre un peu que tout se finalise
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
            
            // 3. Terminer la session dans SessionsViewModel
            Logger.log("🛑 Terminaison de la session via SessionsViewModel...", category: .session)
            try await viewModel.endSession()
            Logger.log("✅ Session terminée", category: .session)
            
            isEnding = false
        } catch {
            Logger.logError(error, context: "stopTrackingAndEndSession", category: .session)
            errorMessage = error.localizedDescription
            isEnding = false
        }
    }
    
    /// Termine la session active (ANCIEN - utilise seulement SessionsViewModel)
    private func endSession_OLD() async {
        Logger.log("🔴 endSession() appelé - isEnding: \(isEnding)", category: .session)
        
        guard !isEnding else {
            Logger.log("⚠️ Déjà en cours de terminaison, ignoré", category: .session)
            return
        }
        
        isEnding = true
        errorMessage = nil
        
        Logger.log("🔄 Début de la terminaison...", category: .session)
        
        do {
            try await viewModel.endSession()
            Logger.log("✅ endSession() réussi, isEnding = false", category: .session)
            isEnding = false
        } catch {
            Logger.log("❌ endSession() échoué: \(error.localizedDescription)", category: .session)
            errorMessage = error.localizedDescription
            isEnding = false
        }
    }
}

// MARK: - StatBadgeCompact is now imported from SessionCardComponents.swift

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        SessionActiveOverlay(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                startedAt: Date().addingTimeInterval(-1245),
                status: .active,
                participants: ["user1", "user2"]
            ),
            viewModel: SessionsViewModel()
        )
    }
}
