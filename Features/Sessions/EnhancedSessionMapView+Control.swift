//
//  EnhancedSessionMapView+Control.swift
//  RunningMan
//
//  Extension pour contrôler la carte depuis l'extérieur via Binding
//

import SwiftUI
import MapKit

// MARK: - Approche alternative avec Binding pour contrôle externe

struct ControllableSessionMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let runnerLocations: [RunnerLocation]
    let routeCoordinates: [CLLocationCoordinate2D]
    let runnerRoutes: [String: [CLLocationCoordinate2D]]
    
    @Binding var focusedRunnerId: String?
    @State private var position: MapCameraPosition
    
    var onRecenter: (() -> Void)?
    var onSaveRoute: (() -> Void)?
    
    init(
        userLocation: CLLocationCoordinate2D?,
        runnerLocations: [RunnerLocation],
        routeCoordinates: [CLLocationCoordinate2D] = [],
        runnerRoutes: [String: [CLLocationCoordinate2D]] = [:],
        focusedRunnerId: Binding<String?>,
        onRecenter: (() -> Void)? = nil,
        onSaveRoute: (() -> Void)? = nil
    ) {
        self.userLocation = userLocation
        self.runnerLocations = runnerLocations
        self.routeCoordinates = routeCoordinates
        self.runnerRoutes = runnerRoutes
        self._focusedRunnerId = focusedRunnerId
        self.onRecenter = onRecenter
        self.onSaveRoute = onSaveRoute
        
        let center = userLocation ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        _position = State(initialValue: .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Map
            Map(position: $position) {
                // Position utilisateur
                if let userLocation = userLocation {
                    Annotation("Vous", coordinate: userLocation) {
                        UserLocationMarker()
                    }
                }
                
                // Autres coureurs
                ForEach(runnerLocations) { runner in
                    Annotation(runner.displayName, coordinate: runner.coordinate) {
                        RunnerMapMarker(runner: runner)
                    }
                }
                
                // Tracé de votre parcours
                if !routeCoordinates.isEmpty {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(
                            LinearGradient(
                                colors: [Color.coralAccent, Color.pinkAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 6
                        )
                }
                
                // Tracés des autres coureurs
                ForEach(Array(runnerRoutes.keys), id: \.self) { runnerId in
                    if let coordinates = runnerRoutes[runnerId], !coordinates.isEmpty {
                        MapPolyline(coordinates: coordinates)
                            .stroke(
                                runnerColor(for: runnerId),
                                lineWidth: 5
                            )
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            
            // Overlay avec infos
            VStack {
                HStack {
                    if !routeCoordinates.isEmpty {
                        routeInfoBadge
                    }
                    Spacer()
                }
                .padding(.leading)
                .padding(.top)
                
                Spacer()
            }
            
            // Contrôles
            mapControls
        }
        .onChange(of: focusedRunnerId) { oldValue, newValue in
            if let runnerId = newValue {
                centerOnRunner(runnerId: runnerId)
            }
        }
    }
    
    // MARK: - Route Info Badge
    
    private var routeInfoBadge: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.caption)
                    .foregroundColor(.coralAccent)
                
                Text("\(routeCoordinates.count) points")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            
            if routeCoordinates.count >= 2 {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Text(formattedDistance)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
    
    private var formattedDistance: String {
        let distance = calculateTotalDistance()
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.2f km", distance / 1000)
        }
    }
    
    private func calculateTotalDistance() -> Double {
        guard routeCoordinates.count >= 2 else { return 0 }
        
        var total: Double = 0
        for i in 1..<routeCoordinates.count {
            let loc1 = CLLocation(
                latitude: routeCoordinates[i-1].latitude,
                longitude: routeCoordinates[i-1].longitude
            )
            let loc2 = CLLocation(
                latitude: routeCoordinates[i].latitude,
                longitude: routeCoordinates[i].longitude
            )
            total += loc1.distance(from: loc2)
        }
        return total
    }
    
    // MARK: - Map Controls
    
    private var mapControls: some View {
        VStack(spacing: 8) {
            MapControlButton(icon: "location.fill", color: .coralAccent) {
                recenterOnUser()
            }
            
            MapControlButton(icon: "person.2.fill", color: .blue) {
                showAllRunnersOnMap()
            }
            
            MapControlButton(icon: "plus.magnifyingglass", color: .purple) {
                zoomIn()
            }
            
            MapControlButton(icon: "minus.magnifyingglass", color: .purple) {
                zoomOut()
            }
            
            if !routeCoordinates.isEmpty {
                MapControlButton(icon: "arrow.down.doc.fill", color: .green) {
                    onSaveRoute?()
                }
            }
        }
        .padding(.trailing, 12)
        .padding(.top, 140)
    }
    
    // MARK: - Actions
    
    private func centerOnRunner(runnerId: String) {
        guard let runner = runnerLocations.first(where: { $0.id == runnerId }) else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(
                MKCoordinateRegion(
                    center: runner.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func recenterOnUser() {
        guard let location = userLocation else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(
                MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
        
        onRecenter?()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func zoomIn() {
        let currentCenter = userLocation ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let newSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(MKCoordinateRegion(center: currentCenter, span: newSpan))
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func zoomOut() {
        let currentCenter = userLocation ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        let newSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(MKCoordinateRegion(center: currentCenter, span: newSpan))
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func showAllRunnersOnMap() {
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        if let userLocation = userLocation {
            allCoordinates.append(userLocation)
        }
        
        allCoordinates.append(contentsOf: runnerLocations.map { $0.coordinate })
        
        guard !allCoordinates.isEmpty else { return }
        
        let region = calculateRegion(for: allCoordinates)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(region)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Runner Colors
    
    private func runnerColor(for runnerId: String) -> Color {
        let colors: [Color] = [
            .blue, .green, .purple, .orange, .yellow, .cyan, .mint, .indigo
        ]
        
        let hash = abs(runnerId.hashValue)
        let index = hash % colors.count
        
        return colors[index]
    }
}

// MARK: - Exemple d'utilisation avec Binding

struct ExampleControllableMapUsage: View {
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var runnerLocations: [RunnerLocation] = []
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var runnerRoutes: [String: [CLLocationCoordinate2D]] = [:]
    
    // Binding pour contrôler la carte depuis l'extérieur
    @State private var focusedRunnerId: String? = nil
    
    var body: some View {
        ZStack {
            // Carte avec contrôle externe
            ControllableSessionMapView(
                userLocation: userLocation,
                runnerLocations: runnerLocations,
                routeCoordinates: routeCoordinates,
                runnerRoutes: runnerRoutes,
                focusedRunnerId: $focusedRunnerId, // BINDING
                onRecenter: {
                    print("Recentré")
                },
                onSaveRoute: {
                    print("Route sauvegardée")
                }
            )
            
            // Overlay des participants
            VStack {
                Spacer()
                
                SessionParticipantsOverlay(
                    participants: runnerLocations,
                    userLocation: userLocation,
                    onRunnerTap: { runnerId in
                        // Simplement mettre à jour le binding !
                        focusedRunnerId = runnerId
                    }
                )
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            // Charger les données...
            loadExampleData()
        }
    }
    
    private func loadExampleData() {
        userLocation = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        
        runnerLocations = [
            RunnerLocation(
                id: "user1",
                displayName: "Jean",
                latitude: 48.8576,
                longitude: 2.3532,
                timestamp: Date(),
                photoURL: nil
            ),
            RunnerLocation(
                id: "user2",
                displayName: "Marie",
                latitude: 48.8556,
                longitude: 2.3512,
                timestamp: Date(),
                photoURL: nil
            )
        ]
        
        routeCoordinates = [
            CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            CLLocationCoordinate2D(latitude: 48.8571, longitude: 2.3527),
            CLLocationCoordinate2D(latitude: 48.8576, longitude: 2.3532)
        ]
        
        runnerRoutes = [
            "user1": [
                CLLocationCoordinate2D(latitude: 48.8576, longitude: 2.3532),
                CLLocationCoordinate2D(latitude: 48.8581, longitude: 2.3537),
                CLLocationCoordinate2D(latitude: 48.8586, longitude: 2.3542)
            ],
            "user2": [
                CLLocationCoordinate2D(latitude: 48.8556, longitude: 2.3512),
                CLLocationCoordinate2D(latitude: 48.8551, longitude: 2.3507),
                CLLocationCoordinate2D(latitude: 48.8546, longitude: 2.3502)
            ]
        ]
    }
}

// MARK: - Preview

#Preview {
    ExampleControllableMapUsage()
        .preferredColorScheme(.dark)
}
