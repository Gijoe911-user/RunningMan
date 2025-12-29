//
//  SessionDetailsPanel.swift
//  RunningMan
//
//  Panel de détails d'une session active (sous la carte)
//

import SwiftUI
import CoreLocation

/// Panel détaillé affiché sous la carte pendant une session active
///
/// Contient :
/// - Liste des participants (cliquables pour centrer la carte)
/// - Stats détaillées (allure, vitesse, etc.)
/// - Bouton terminer la session
///
/// **Position :** Sous la carte, scrollable
///
/// **Usage :**
/// ```swift
/// SessionDetailsPanel(
///     session: activeSession,
///     viewModel: viewModel,
///     currentDistance: 2500,
///     onRunnerTap: { runnerId in /* centrer carte */ },
///     onEndSession: { /* terminer */ }
/// )
/// ```
struct SessionDetailsPanel: View {
    
    // MARK: - Properties
    
    /// Session active
    let session: SessionModel
    
    /// ViewModel pour accéder aux données
    @ObservedObject var viewModel: SessionsViewModel
    
    /// Distance actuelle en mètres
    let currentDistance: Double
    
    /// Callback quand on clique sur un coureur
    let onRunnerTap: (String) -> Void
    
    /// Callback pour terminer la session
    let onEndSession: () -> Void
    
    // MARK: - State
    
    @State private var showEndConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle pour indiquer que c'est scrollable
            handle
            
            // Stats rapides (sticky)
            quickStatsRow
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Participants
                    if !viewModel.activeRunners.isEmpty {
                        participantsSection
                    }
                    
                    // Détails session
                    detailsSection
                    
                    // Bouton terminer
                    endSessionButton
                }
                .padding()
            }
        }
        .background(Color.darkNavy)
        .alert("Terminer la session ?", isPresented: $showEndConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Terminer", role: .destructive) {
                onEndSession()
            }
        } message: {
            Text("Cette action mettra fin à la session pour tous les participants.")
        }
    }
    
    // MARK: - View Components
    
    /// Handle de scroll
    private var handle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 4)
            .padding(.top, 8)
    }
    
    /// Ligne de stats rapides
    private var quickStatsRow: some View {
        HStack(spacing: 20) {
            // Temps
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text(timeElapsed)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Distance
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                Text(SessionStatsFormatters.formatDistance(currentDistance))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Coureurs
            HStack(spacing: 6) {
                Image(systemName: "figure.run")
                    .foregroundColor(.coralAccent)
                Text("\(viewModel.activeRunners.count)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal)
    }
    
    /// Section participants
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.activeRunners) { runner in
                        ParticipantCard(runner: runner) {
                            onRunnerTap(runner.id)
                        }
                    }
                }
            }
        }
    }
    
    /// Section détails avec KPI
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistiques")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Distance
                DetailKPICard(
                    icon: "location.fill",
                    title: "Distance",
                    value: SessionStatsFormatters.formatDistance(currentDistance),
                    color: .green
                )
                
                // Allure
                DetailKPICard(
                    icon: "speedometer",
                    title: "Allure",
                    value: paceFormatted,
                    color: .purple
                )
                
                // Vitesse
                DetailKPICard(
                    icon: "gauge.high",
                    title: "Vitesse",
                    value: speedFormatted,
                    color: .cyan
                )
                
                // BPM
                if let bpm = viewModel.currentHeartRate {
                    DetailKPICard(
                        icon: "heart.fill",
                        title: "BPM",
                        value: "\(Int(bpm))",
                        color: .red
                    )
                }
            }
        }
    }
    
    /// Bouton terminer
    private var endSessionButton: some View {
        Button {
            showEndConfirmation = true
        } label: {
            HStack {
                Image(systemName: "stop.circle.fill")
                Text("Terminer la session")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Computed Properties
    
    /// Temps écoulé formaté
    private var timeElapsed: String {
        let elapsed = Date().timeIntervalSince(session.startedAt)
        return SessionStatsFormatters.formatTimeElapsed(elapsed)
    }
    
    /// Allure formatée (min/km)
    private var paceFormatted: String {
        let elapsed = Date().timeIntervalSince(session.startedAt)
        guard let pace = RouteCalculator.calculatePace(distance: currentDistance, duration: elapsed) else {
            return "--"
        }
        return SessionStatsFormatters.formatPace(pace)
    }
    
    /// Vitesse formatée (km/h)
    private var speedFormatted: String {
        let elapsed = Date().timeIntervalSince(session.startedAt)
        guard let speed = RouteCalculator.calculateAverageSpeed(distance: currentDistance, duration: elapsed) else {
            return "--"
        }
        return SessionStatsFormatters.formatSpeed(speed)
    }
}

// MARK: - Participant Card

/// Carte de participant cliquable
struct ParticipantCard: View {
    let runner: RunnerLocation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
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
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.coralAccent.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(.coralAccent)
                        }
                }
                
                // Nom
                Text(runner.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Indicateur "centrer sur"
                Text("Centrer")
                    .font(.caption2)
                    .foregroundColor(.coralAccent)
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Detail KPI Card

/// Carte KPI détaillée
struct DetailKPICard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        SessionDetailsPanel(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                startedAt: Date().addingTimeInterval(-1245),
                status: .active,
                participants: ["user1", "user2"],
                targetDistanceMeters: 5000
            ),
            viewModel: SessionsViewModel(),
            currentDistance: 2500,
            onRunnerTap: { id in
                print("Centrer sur: \(id)")
            },
            onEndSession: {
                print("Terminer")
            }
        )
    }
}
