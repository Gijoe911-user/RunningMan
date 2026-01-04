//
//  SessionHistoryDetailView.swift
//  RunningMan
//
//  Vue de détail pour une session historique (terminée)
//  Affiche les statistiques, participants, et le parcours enregistré
//

import SwiftUI
import MapKit
import FirebaseFirestore
import Combine

/// Vue de détail complète pour une session terminée
///
/// Affiche :
/// - Statistiques globales de la session
/// - Carte avec le parcours enregistré
/// - Liste des participants avec leurs performances individuelles
/// - Podium (classement par distance ou vitesse)
///
/// **Différence avec SessionDetailView :**
/// - Pas de tracking en temps réel
/// - Données historiques figées
/// - Focus sur l'analyse et le partage
///
/// - SeeAlso: `SessionDetailView` pour les sessions actives
struct SessionHistoryDetailView: View {
    
    // MARK: - Properties
    
    let session: SessionModel
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SessionHistoryViewModel
    
    @State private var selectedTab: HistoryTab = .overview
    @State private var mapPosition: MapCameraPosition = .automatic
    
    // MARK: - Initialization
    
    init(session: SessionModel) {
        self.session = session
        _viewModel = StateObject(wrappedValue: SessionHistoryViewModel(session: session))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // En-tête avec stats principales
                    headerSection
                    
                    // Tabs
                    tabSelector
                    
                    // Contenu selon l'onglet sélectionné
                    switch selectedTab {
                    case .overview:
                        overviewSection
                    case .participants:
                        participantsSection
                    case .map:
                        mapSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Détail de la session")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSessionDetails()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    // MARK: - Header Section (Inline)
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Titre et date
            VStack(spacing: 8) {
                Text(session.title ?? "Session de course")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(formatDate(session.startedAt))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Stats principales (remplace SessionStatCard)
            HStack(spacing: 20) {
                InlineStatCardBig(
                    icon: "figure.run",
                    value: String(format: "%.2f km", session.distanceInKilometers),
                    label: "Distance",
                    color: .coralAccent
                )
                
                InlineStatCardBig(
                    icon: "clock.fill",
                    value: session.formattedDuration,
                    label: "Durée",
                    color: .blueAccent
                )
                
                InlineStatCardBig(
                    icon: "person.3.fill",
                    value: "\(session.participants.count)",
                    label: "Coureurs",
                    color: .greenAccent
                )
            }
            
            // Stats secondaires (remplace SessionSecondaryStatRow)
            HStack(spacing: 20) {
                InlineSecondaryStat(
                    icon: "speedometer",
                    label: "Vitesse moy.",
                    value: String(format: "%.1f km/h", session.averageSpeedKmh)
                )
                
                InlineSecondaryStat(
                    icon: "flame.fill",
                    label: "Allure",
                    value: session.averagePaceMinPerKm
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(HistoryTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(selectedTab == tab ? .coralAccent : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab
                            ? Color.coralAccent.opacity(0.2)
                            : Color.clear
                    )
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Overview Section (Inline remplacements)
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            // Session info (remplace SessionInfoCard)
            VStack(alignment: .leading, spacing: 12) {
                Text("Informations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    infoRow(label: "Type", value: session.activityType.displayName)
                    infoRow(label: "Statut", value: session.status.rawValue)
                    infoRow(label: "Début", value: formatTime(session.startedAt))
                    infoRow(label: "Fin", value: session.endedAt != nil ? formatTime(session.endedAt!) : "En cours")
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Podium (remplace SessionPodiumRow + SessionEmptyStateView)
            if session.participants.count > 1 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🏆 Classement")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if viewModel.participantStats.isEmpty {
                        emptyStateView(icon: "trophy.fill", message: "Chargement du classement...")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.rankedParticipants.enumerated()), id: \.element.userId) { index, stat in
                                podiumRow(rank: index + 1,
                                          name: viewModel.getUserName(for: stat.userId),
                                          distanceMeters: stat.distance,
                                          averageSpeed: stat.averageSpeed)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // Notes (remplace SessionNotesCard)
            if let notes = session.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .foregroundColor(.coralAccent)
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    // MARK: - Participants Section (Inline)
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants (\(session.participants.count))")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.participantStats.isEmpty {
                emptyStateView(icon: "person.3.fill", message: "Chargement des participants...")
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.participantStats, id: \.userId) { stat in
                        participantDetailCard(
                            name: viewModel.getUserName(for: stat.userId),
                            distance: stat.distance,
                            duration: stat.duration,
                            avgSpeed: stat.averageSpeed,
                            state: session.participantState(for: stat.userId)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Map Section (Inline)
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📍 Parcours")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.routePoints.isEmpty {
                emptyStateView(
                    icon: "map.fill",
                    message: "Aucun parcours enregistré",
                    subtitle: "Le tracking GPS n'était pas actif pendant cette session"
                )
            } else {
                VStack(spacing: 12) {
                    // Carte avec le parcours
                    Map(position: $mapPosition) {
                        // Ligne du parcours
                        MapPolyline(coordinates: viewModel.routePoints)
                            .stroke(Color.coralAccent, lineWidth: 3)
                        
                        // Point de départ
                        if let firstPoint = viewModel.routePoints.first {
                            Annotation("Départ", coordinate: firstPoint) {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(Color.green)
                                    .padding(8)
                                    .background(Circle().fill(Color.white))
                                    .shadow(radius: 4)
                            }
                        }
                        
                        // Point d'arrivée
                        if let lastPoint = viewModel.routePoints.last {
                            Annotation("Arrivée", coordinate: lastPoint) {
                                Image(systemName: "flag.checkered")
                                    .foregroundColor(Color.red)
                                    .padding(8)
                                    .background(Circle().fill(Color.white))
                                    .shadow(radius: 4)
                            }
                        }
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Stats du parcours (remplace SessionMapStatItem)
                    HStack(spacing: 20) {
                        mapStatItem(icon: "point.topleft.down.curvedto.point.bottomright.up.fill",
                                    label: "Points GPS",
                                    value: "\(viewModel.routePoints.count)")
                        
                        if let elevationGain = viewModel.elevationGain {
                            mapStatItem(icon: "arrow.up.right",
                                        label: "Dénivelé +",
                                        value: String(format: "%.0f m", elevationGain))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Inline Subviews
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
    
    private func emptyStateView(icon: String, message: String, subtitle: String? = nil) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.coralAccent)
            Text(message)
                .font(.subheadline.bold())
                .foregroundColor(.white)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func podiumRow(rank: Int, name: String, distanceMeters: Double, averageSpeed: Double) -> some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.headline)
                .foregroundColor(rank == 1 ? .yellowAccent : .white)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Label(String(format: "%.2f km", distanceMeters / 1000.0), systemImage: "figure.run")
                    Text("•")
                    Label(String(format: "%.1f km/h", averageSpeed * 3.6), systemImage: "speedometer")
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func participantDetailCard(name: String, distance: Double, duration: TimeInterval, avgSpeed: Double, state: ParticipantSessionState?) -> some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(Color.coralAccent.opacity(0.25))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill")
                    .foregroundColor(.coralAccent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Label(String(format: "%.2f km", distance / 1000.0), systemImage: "figure.run")
                    Text("•")
                    Label(formatDuration(duration), systemImage: "clock")
                    Text("•")
                    Label(String(format: "%.1f km/h", avgSpeed * 3.6), systemImage: "speedometer")
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // État (si disponible)
            if let state = state {
                HStack(spacing: 6) {
                    Circle()
                        .fill(stateColor(for: state.status))
                        .frame(width: 8, height: 8)
                    Text(state.status.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Status Color Mapping (uses ParticipantStatus)
    private func stateColor(for status: ParticipantStatus) -> Color {
        switch status {
        case .waiting: return .gray
        case .active: return .green
        case .paused: return .orange
        case .ended: return .gray
        case .abandoned: return .red
        }
    }
    
    private func mapStatItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.coralAccent)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return hours > 0
        ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        : String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Types

enum HistoryTab: CaseIterable {
    case overview
    case participants
    case map
    
    var title: String {
        switch self {
        case .overview: return "Vue d'ensemble"
        case .participants: return "Coureurs"
        case .map: return "Carte"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .participants: return "person.3.fill"
        case .map: return "map.fill"
        }
    }
}

// MARK: - Inline Cards (private)

private struct InlineStatCardBig: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct InlineSecondaryStat: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.coralAccent)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionHistoryDetailView(
            session: SessionModel(
                squadId: "squad123",
                creatorId: "user1",
                startedAt: Date().addingTimeInterval(-3600),
                endedAt: Date(),
                status: .ended,
                participants: ["user1", "user2", "user3"],
                totalDistanceMeters: 5000,
                durationSeconds: 1800,
                averageSpeed: 2.78
            )
        )
    }
    .preferredColorScheme(.dark)
}
