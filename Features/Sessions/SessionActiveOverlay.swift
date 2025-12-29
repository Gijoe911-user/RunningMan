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
/// - Bouton "Terminer la session"
///
/// **Position :** Bas de l'écran, au-dessus de la carte
///
/// **Usage :**
/// ```swift
/// if let session = viewModel.activeSession {
///     SessionActiveOverlay(session: session, viewModel: viewModel)
/// }
/// ```
///
/// - SeeAlso: `SessionsListView`, `SessionsViewModel`
struct SessionActiveOverlay: View {
    
    // MARK: - Properties
    
    /// Session de course active
    let session: SessionModel
    
    /// ViewModel pour accéder aux données en temps réel
    @ObservedObject var viewModel: SessionsViewModel
    
    // MARK: - State
    
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
            
            // Stats rapides
            quickStats
            
            // Liste des coureurs
            if !viewModel.activeRunners.isEmpty {
                activaRunnersList
            }
            
            // Bouton terminer
            endSessionButton
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
    
    /// Stats rapides (coureurs, objectif, temps)
    private var quickStats: some View {
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
    
    /// Bouton pour terminer la session
    private var endSessionButton: some View {
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
    
    /// Termine la session active
    private func endSession() async {
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
