//
//  EnhancedSessionMapView.swift
//  RunningMan
//
//  Carte améliorée avec tracé du parcours, contrôles et sauvegarde
//

import SwiftUI
import MapKit

struct EnhancedSessionMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let runnerLocations: [RunnerLocation]
    let routeCoordinates: [CLLocationCoordinate2D]
    let runnerRoutes: [String: [CLLocationCoordinate2D]] // NOUVEAU : Tracés par runner ID
    
    @State private var position: MapCameraPosition
    @State private var showAllRunners = false
    @State private var use3DElevation = false  // ✅ NOUVEAU: Toggle 2D/3D
    
    // Actions callback
    var onRecenter: (() -> Void)?
    var onSaveRoute: (() -> Void)?
    var onRunnerTapped: ((String) -> Void)?
    
    init(
        userLocation: CLLocationCoordinate2D?,
        runnerLocations: [RunnerLocation],
        routeCoordinates: [CLLocationCoordinate2D] = [],
        runnerRoutes: [String: [CLLocationCoordinate2D]] = [:], // NOUVEAU
        onRecenter: (() -> Void)? = nil,
        onSaveRoute: (() -> Void)? = nil,
        onRunnerTapped: ((String) -> Void)? = nil
    ) {
        self.userLocation = userLocation
        self.runnerLocations = runnerLocations
        self.routeCoordinates = routeCoordinates
        self.runnerRoutes = runnerRoutes
        self.onRecenter = onRecenter
        self.onSaveRoute = onSaveRoute
        self.onRunnerTapped = onRunnerTapped
        
        // Position initiale
        let center = userLocation ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        _position = State(initialValue: .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))
    }
    
    // Fonction publique pour centrer sur un coureur spécifique
    func centerOnRunner(runnerId: String) {
        guard let runner = runnerLocations.first(where: { $0.id == runnerId }) else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(
                MKCoordinateRegion(
                    center: runner.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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
                
                // Tracé de votre parcours (en dégradé coral/pink)
                if !routeCoordinates.isEmpty {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(Color.red, lineWidth: 15)  // ✅ TEST: Ligne ROUGE ÉPAISSE
                }
                
                // Tracés des autres coureurs (couleurs différentes)
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
            .mapStyle(.standard(elevation: use3DElevation ? .realistic : .flat))  // ✅ FIX: Toggle 2D/3D
            
            // Overlay avec infos et contrôles
            VStack {
                // Info tracé en haut à gauche
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
            
            // Contrôles carte à droite
            mapControls
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
            // Bouton recentrer sur moi (icône seule)
            MapControlButton(
                icon: "location.fill",
                color: .coralAccent,
                label: ""
            ) {
                recenterOnUser()
            }
            
            // Bouton voir tous les coureurs (icône seule)
            MapControlButton(
                icon: "person.2.fill",
                color: .blue,
                label: ""
            ) {
                showAllRunnersOnMap()
            }
            
            // Bouton zoom in (icône seule)
            MapControlButton(
                icon: "plus.magnifyingglass",
                color: .purple,
                label: ""
            ) {
                zoomIn()
            }
            
            // Bouton zoom out (icône seule)
            MapControlButton(
                icon: "minus.magnifyingglass",
                color: .purple,
                label: ""
            ) {
                zoomOut()
            }
            
            // Bouton sauvegarder le tracé (icône seule)
            if !routeCoordinates.isEmpty {
                MapControlButton(
                    icon: "arrow.down.doc.fill",
                    color: .green,
                    label: ""
                ) {
                    onSaveRoute?()
                }
            }
            
            // Bouton basculer 2D/3D (icône seule)
            MapControlButton(
                icon: use3DElevation ? "mountain.2.fill" : "map.fill",
                color: use3DElevation ? .orange : .gray,
                label: ""
            ) {
                withAnimation {
                    use3DElevation.toggle()
                }
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
        .padding(.trailing, 12)
        .padding(.top, 140) // Augmenté à 140px pour éviter le bouton +
    }
    
    // MARK: - Actions
    
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
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func zoomIn() {
        // Solution: Créer une nouvelle région basée sur l'actuelle
        // En utilisant .region directement
        let currentCenter = userLocation ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        
        // Créer une nouvelle région avec un span réduit
        // Note: On utilise un span par défaut si on ne peut pas extraire l'actuel
        let newSpan = MKCoordinateSpan(
            latitudeDelta: 0.005, // Moitié de 0.01
            longitudeDelta: 0.005
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(
                MKCoordinateRegion(
                    center: currentCenter,
                    span: newSpan
                )
            )
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func zoomOut() {
        // Solution: Créer une nouvelle région basée sur l'actuelle
        let currentCenter = userLocation ?? CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        
        // Créer une nouvelle région avec un span agrandi
        let newSpan = MKCoordinateSpan(
            latitudeDelta: 0.02, // Double de 0.01
            longitudeDelta: 0.02
        )
        
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(
                MKCoordinateRegion(
                    center: currentCenter,
                    span: newSpan
                )
            )
        }
        
        // Haptic feedback
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
        
        // Calculer la région qui contient tous les coureurs
        let region = calculateRegion(for: allCoordinates)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(region)
        }
        
        // Haptic feedback
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
            latitudeDelta: (maxLat - minLat) * 1.5, // Margin 50%
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Runner Colors
    
    /// Génère une couleur unique pour chaque coureur basée sur son ID
    private func runnerColor(for runnerId: String) -> Color {
        let colors: [Color] = [
            .blue, .green, .purple, .orange, .yellow, .cyan, .mint, .indigo
        ]
        
        // Utilise un hash simple pour obtenir un index cohérent
        let hash = abs(runnerId.hashValue)
        let index = hash % colors.count
        
        return colors[index]
    }
}

// MARK: - Map Control Button

struct MapControlButton: View {
    let icon: String
    let color: Color
    let label: String
    let action: () -> Void
    
    init(icon: String, color: Color, label: String = "", action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.label = label
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                )
        }
    }
}

// MARK: - User Location Marker

struct UserLocationMarker: View {
    var body: some View {
        ZStack {
            // Pulse animation
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 50, height: 50)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
        }
    }
}

// MARK: - Runner Map Marker

struct RunnerMapMarker: View {
    let runner: RunnerLocation
    
    var body: some View {
        ZStack {
            // Shadow circle
            Circle()
                .fill(runnerColor.opacity(0.3))
                .frame(width: 40, height: 40)
            
            // Main circle with photo or icon
            Circle()
                .fill(runnerColor.opacity(0.8))
                .frame(width: 30, height: 30)
                .overlay {
                    if let photoURL = runner.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
    }
    
    private var runnerColor: Color {
        let colors: [Color] = [
            .blue, .green, .purple, .orange, .yellow, .cyan, .mint, .indigo
        ]
        
        let hash = abs(runner.id.hashValue)
        let index = hash % colors.count
        
        return colors[index]
    }
}

// MARK: - Preview

#Preview {
    EnhancedSessionMapView(
        userLocation: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        runnerLocations: [
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
        ],
        routeCoordinates: [
            CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            CLLocationCoordinate2D(latitude: 48.8571, longitude: 2.3527),
            CLLocationCoordinate2D(latitude: 48.8576, longitude: 2.3532)
        ],
        runnerRoutes: [
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
    )
}
