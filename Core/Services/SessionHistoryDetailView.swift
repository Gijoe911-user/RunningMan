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
    
    // MARK: - Header Section
    
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
            
            // Stats principales
            HStack(spacing: 20) {
                SessionStatCard(
                    icon: "figure.run",
                    value: String(format: "%.2f km", session.distanceInKilometers),
                    label: "Distance",
                    color: Color.coralAccent
                )
                
                SessionStatCard(
                    icon: "clock.fill",
                    value: session.formattedDuration,
                    label: "Durée",
                    color: Color.blue
                )
                
                SessionStatCard(
                    icon: "person.3.fill",
                    value: "\(session.participants.count)",
                    label: "Coureurs",
                    color: Color.green
                )
            }
            
            // Stats secondaires
            HStack(spacing: 20) {
                SessionSecondaryStatRow(
                    icon: "speedometer",
                    label: "Vitesse moy.",
                    value: String(format: "%.1f km/h", session.averageSpeedKmh)
                )
                
                SessionSecondaryStatRow(
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
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            // Session info
            SessionInfoCard(
                title: "Informations",
                items: [
                    ("Type", session.activityType.displayName),
                    ("Statut", session.status.rawValue),
                    ("Début", formatTime(session.startedAt)),
                    ("Fin", session.endedAt != nil ? formatTime(session.endedAt!) : "En cours")
                ]
            )
            
            // Podium (si plusieurs participants)
            if session.participants.count > 1 {
                podiumSection
            }
            
            // Notes (si présentes)
            if let notes = session.notes, !notes.isEmpty {
                SessionNotesCard(notes: notes)
            }
        }
    }
    
    private var podiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 Classement")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.participantStats.isEmpty {
                SessionEmptyStateView(
                    icon: "trophy.fill",
                    message: "Chargement du classement..."
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.rankedParticipants.enumerated()), id: \.element.userId) { index, stat in
                        SessionPodiumRow(
                            rank: index + 1,
                            participantStat: stat,
                            userName: viewModel.getUserName(for: stat.userId)
                        )
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Participants Section
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants (\(session.participants.count))")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.participantStats.isEmpty {
                SessionEmptyStateView(
                    icon: "person.3.fill",
                    message: "Chargement des participants..."
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.participantStats, id: \.userId) { stat in
                        SessionParticipantDetailCard(
                            participantStat: stat,
                            userName: viewModel.getUserName(for: stat.userId),
                            participantState: session.participantState(for: stat.userId)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📍 Parcours")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.routePoints.isEmpty {
                SessionEmptyStateView(
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
                    
                    // Stats du parcours
                    HStack(spacing: 20) {
                        SessionMapStatItem(
                            icon: "point.topleft.down.curvedto.point.bottomright.up.fill",
                            label: "Points GPS",
                            value: "\(viewModel.routePoints.count)"
                        )
                        
                        if let elevationGain = viewModel.elevationGain {
                            SessionMapStatItem(
                                icon: "arrow.up.right",
                                label: "Dénivelé +",
                                value: String(format: "%.0f m", elevationGain)
                            )
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
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
