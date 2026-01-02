//
//  SessionHistoryDetailMapView.swift
//  RunningMan
//
//  Vue détaillée d'une session terminée avec carte et tracés de tous les participants
//

import SwiftUI
import MapKit

struct SessionHistoryDetailMapView: View {
    let session: SessionModel
    
    @StateObject private var viewModel: SessionHistoryDetailViewModel
    @State private var showShareSheet = false
    
    init(session: SessionModel) {
        self.session = session
        self._viewModel = StateObject(wrappedValue: SessionHistoryDetailViewModel(session: session))
    }
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Carte avec tous les tracés
                    mapSection
                    
                    // Stats globales
                    statsSection
                    
                    // Liste des participants avec leurs tracés
                    participantsSection
                }
                .padding()
            }
        }
        .navigationTitle(session.title ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        exportGPX()
                    } label: {
                        Label("Exporter GPX", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        // TODO: Partager la session
                    } label: {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.coralAccent)
                }
            }
        }
        .task {
            await viewModel.loadRoutes()
        }
        .overlay {
            if viewModel.isLoadingRoutes {
                ProgressView("Chargement des tracés...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.coralAccent)
                
                Text("Tracés des participants")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !viewModel.allRoutes.isEmpty {
                    Text("\(viewModel.allRoutes.count) tracés")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.coralAccent.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            
            if viewModel.allRoutes.isEmpty && !viewModel.isLoadingRoutes {
                // Pas de tracés disponibles
                emptyMapPlaceholder
            } else {
                // Carte avec tous les tracés
                historyMapView
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var emptyMapPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.slash")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Aucun tracé disponible")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var historyMapView: some View {
        Map {
            // Afficher tous les tracés avec des couleurs différentes
            ForEach(Array(viewModel.allRoutes.keys), id: \.self) { userId in
                if let coordinates = viewModel.allRoutes[userId], !coordinates.isEmpty {
                    MapPolyline(coordinates: coordinates)
                        .stroke(
                            colorForUser(userId),
                            lineWidth: 4
                        )
                    
                    // Marqueur de départ (premier point)
                    if let start = coordinates.first {
                        Annotation("Départ", coordinate: start) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                }
                        }
                    }
                    
                    // Marqueur d'arrivée (dernier point)
                    if let end = coordinates.last, coordinates.count > 1 {
                        Annotation("Arrivée", coordinate: end) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .overlay {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                }
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.coralAccent)
                
                Text("Statistiques")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatHistoryCard(
                    icon: "figure.run",
                    value: "\(session.participants.count)",
                    label: "Participants",
                    color: .coralAccent
                )
                
                StatHistoryCard(
                    icon: "location.fill",
                    value: String(format: "%.2f km", session.distanceInKilometers),
                    label: "Distance",
                    color: .coralAccent
                )
                
                StatHistoryCard(
                    icon: "clock.fill",
                    value: session.formattedDuration,
                    label: "Durée",
                    color: .coralAccent
                )
                
                StatHistoryCard(
                    icon: "speedometer",
                    value: session.averagePaceMinPerKm,
                    label: "Allure",
                    color: .coralAccent
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Participants Section
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.coralAccent)
                
                Text("Participants")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            ForEach(Array(viewModel.allRoutes.keys), id: \.self) { userId in
                ParticipantRouteCard(
                    userId: userId,
                    displayName: viewModel.participantNames[userId] ?? "Coureur",
                    route: viewModel.allRoutes[userId] ?? [],
                    color: colorForUser(userId)
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Actions
    
    private func exportGPX() {
        let urls = viewModel.exportAllRoutesAsGPX()
        
        if !urls.isEmpty {
            Logger.logSuccess("✅ \(urls.count) fichiers GPX exportés", category: .location)
            // TODO: Afficher share sheet avec les URLs
        }
    }
    
    // MARK: - Helpers
    
    private func colorForUser(_ userId: String) -> Color {
        // Générer une couleur basée sur le hash du userId
        let hash = abs(userId.hashValue)
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow, .cyan]
        return colors[hash % colors.count]
    }
}

// MARK: - Participant Route Card

struct ParticipantRouteCard: View {
    let userId: String
    let displayName: String
    let route: [CLLocationCoordinate2D]
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Indicateur de couleur
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    Label("\(route.count) pts", systemImage: "point.3.filled.connected.trianglepath.dotted")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Label(formattedDistance, systemImage: "arrow.triangle.swap")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Minimap preview (optionnel)
            Image(systemName: "map.fill")
                .font(.title3)
                .foregroundColor(color.opacity(0.6))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var formattedDistance: String {
        guard route.count >= 2 else { return "0 m" }
        
        var total: Double = 0
        for i in 1..<route.count {
            let loc1 = CLLocation(
                latitude: route[i-1].latitude,
                longitude: route[i-1].longitude
            )
            let loc2 = CLLocation(
                latitude: route[i].latitude,
                longitude: route[i].longitude
            )
            total += loc1.distance(from: loc2)
        }
        
        if total < 1000 {
            return String(format: "%.0f m", total)
        } else {
            return String(format: "%.2f km", total / 1000)
        }
    }
}

// MARK: - Stat Card

struct StatHistoryCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionHistoryDetailMapView(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                startedAt: Date().addingTimeInterval(-3600),
                endedAt: Date(),  // ✅ Déplacé avant activityType
                status: .ended,
                participants: ["user1", "user2", "user3"],
                activityType: .training  // ✅ Déplacé après les paramètres obligatoires
            )
        )
    }
    .preferredColorScheme(.dark)
}
