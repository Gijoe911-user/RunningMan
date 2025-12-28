//
//  RouteHistoryView.swift
//  RunningMan
//
//  Vue pour afficher l'historique des parcours d'une session
//

import SwiftUI
import MapKit

struct RouteHistoryView: View {
    let session: SessionModel
    
    @State private var routes: [UserRoute] = []
    @State private var selectedRoute: UserRoute?
    @State private var selectedRoutePoints: [RoutePoint] = []
    @State private var isLoading = false
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Map with selected route
                if let selectedRoute = selectedRoute {
                    mapSection
                        .frame(height: 300)
                }
                
                // Routes list
                routesList
            }
        }
        .navigationTitle("Historique des parcours")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRoutes()
        }
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        ZStack {
            Map(position: $mapPosition) {
                // Route polyline
                if selectedRoutePoints.count > 1 {
                    MapPolyline(coordinates: selectedRoutePoints.map { $0.coordinate })
                        .stroke(.coralAccent, lineWidth: 3)
                }
                
                // Start marker
                if let firstPoint = selectedRoutePoints.first {
                    Annotation("Départ", coordinate: firstPoint.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "play.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // End marker
                if let lastPoint = selectedRoutePoints.last, selectedRoutePoints.count > 1 {
                    Annotation("Arrivée", coordinate: lastPoint.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "stop.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Route info overlay
            if let route = selectedRoute {
                VStack {
                    Spacer()
                    
                    RouteInfoCard(route: route)
                        .padding()
                }
            }
        }
    }
    
    // MARK: - Routes List
    
    private var routesList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Participants (\(routes.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if routes.isEmpty {
                    Text("Aucun parcours enregistré")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(routes) { route in
                            RouteRowView(
                                route: route,
                                isSelected: selectedRoute?.id == route.id,
                                onTap: {
                                    Task {
                                        await selectRoute(route)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Actions
    
    private func loadRoutes() async {
        guard let sessionId = session.id else { return }
        
        isLoading = true
        
        do {
            routes = try await RouteHistoryService.shared.getAllRoutesForSession(sessionId: sessionId)
            
            // Sélectionner automatiquement le premier
            if let firstRoute = routes.first {
                await selectRoute(firstRoute)
            }
        } catch {
            print("Error loading routes: \(error)")
        }
        
        isLoading = false
    }
    
    private func selectRoute(_ route: UserRoute) async {
        selectedRoute = route
        
        guard let sessionId = session.id else { return }
        
        do {
            let points = try await RouteHistoryService.shared.loadRoutePoints(
                sessionId: sessionId,
                userId: route.userId
            )
            
            selectedRoutePoints = points
            
            // Centrer la carte sur le parcours
            if let firstPoint = points.first, let lastPoint = points.last {
                let minLat = min(firstPoint.latitude, lastPoint.latitude)
                let maxLat = max(firstPoint.latitude, lastPoint.latitude)
                let minLon = min(firstPoint.longitude, lastPoint.longitude)
                let maxLon = max(firstPoint.longitude, lastPoint.longitude)
                
                let center = CLLocationCoordinate2D(
                    latitude: (minLat + maxLat) / 2,
                    longitude: (minLon + maxLon) / 2
                )
                
                let span = MKCoordinateSpan(
                    latitudeDelta: (maxLat - minLat) * 1.2,
                    longitudeDelta: (maxLon - minLon) * 1.2
                )
                
                withAnimation {
                    mapPosition = .region(MKCoordinateRegion(center: center, span: span))
                }
            }
        } catch {
            print("Error loading route points: \(error)")
        }
    }
}

// MARK: - Route Row View

struct RouteRowView: View {
    let route: UserRoute
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var userName: String = "Chargement..."
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(Color.coralAccent.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "figure.run")
                            .font(.caption)
                            .foregroundColor(.coralAccent)
                    }
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(Color.coralAccent, lineWidth: 3)
                        }
                    }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Label(String(format: "%.2f km", route.distanceInKm), systemImage: "arrow.triangle.swap")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Label(route.formattedDuration, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text(route.averagePace)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.coralAccent)
                    
                    Text("\(route.pointsCount) pts")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding()
            .background(isSelected ? Color.coralAccent.opacity(0.1) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .task {
            await loadUserName()
        }
    }
    
    private func loadUserName() async {
        do {
            if let user = try await AuthService.shared.getUserProfile(userId: route.userId) {
                userName = user.displayName
            }
        } catch {
            userName = "Coureur #\(route.userId.prefix(6))"
        }
    }
}

// MARK: - Route Info Card

struct RouteInfoCard: View {
    let route: UserRoute
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(String(format: "%.2f km", route.distanceInKm))
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Durée")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(route.formattedDuration)
                    .font(.title3.bold())
                    .foregroundColor(.coralAccent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Allure")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(route.averagePace)
                    .font(.title3.bold())
                    .foregroundColor(.blueAccent)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RouteHistoryView(session: SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            startedAt: Date().addingTimeInterval(-3600),
            participants: ["user1", "user2"]
        ))
    }
    .preferredColorScheme(.dark)
}
