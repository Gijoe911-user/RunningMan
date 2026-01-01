//
//  SessionTrackingView.swift
//  RunningMan
//
//  Vue complète pour tracker une session avec stats en temps réel
//  🏃 Affiche les contrôles + stats + carte
//

import SwiftUI
import MapKit

struct SessionTrackingView: View {
    let session: SessionModel
    @StateObject private var trackingManager = TrackingManager.shared
    @State private var currentTrackingState: TrackingState = .idle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Carte avec tracé GPS
                mapSection
                    .frame(maxHeight: .infinity)
                
                // Stats en temps réel
                statsSection
                
                // Contrôles de tracking
                controlsSection
                    .padding()
            }
        }
        .navigationTitle("Session en cours")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Démarrer automatiquement le tracking si ce n'est pas déjà fait
            if trackingManager.activeTrackingSession == nil {
                _ = await trackingManager.startTracking(for: session)
            }
        }
        .onChange(of: trackingManager.trackingState) { _, newValue in
            // Synchroniser l'état local avec TrackingManager
            currentTrackingState = newValue
        }
        .onAppear {
            // Initialiser l'état local
            currentTrackingState = trackingManager.trackingState
        }
    }
    
    // MARK: - Map Section
    
    private var mapSection: some View {
        TrackingMapView(
            userLocation: trackingManager.routeCoordinates.last,
            routeCoordinates: trackingManager.routeCoordinates
        )
        .overlay(alignment: .topTrailing) {
            // Indicateur d'état
            stateIndicator
                .padding()
        }
    }
    
    private var stateIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)
            
            Text(currentTrackingState.displayName)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    private var stateColor: Color {
        switch currentTrackingState {
        case .idle: return .gray
        case .active: return .green
        case .paused: return .orange
        case .stopping: return .red
        }
    }
    
    // MARK: - Stats Section (utilise StatCard réutilisable)
    
    private var statsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Distance
                StatCard(
                    icon: "location.fill",
                    value: FormatHelper.formattedDistance(trackingManager.currentDistance),
                    label: "Distance",
                    color: .coralAccent
                )
                
                // Durée
                StatCard(
                    icon: "clock.fill",
                    value: FormatHelper.formattedDuration(trackingManager.currentDuration),
                    label: "Durée",
                    color: .pinkAccent
                )
                
                // Allure
                StatCard(
                    icon: "speedometer",
                    value: FormatHelper.formattedPace(trackingManager.currentSpeed),
                    label: "Allure",
                    color: .blue
                )
                
                // Vitesse
                StatCard(
                    icon: "gauge.high",
                    value: FormatHelper.formattedSpeed(trackingManager.currentSpeed),
                    label: "Vitesse",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
        .frame(height: 120)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
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
                do {
                    try await trackingManager.stopTracking()
                    dismiss()
                } catch {
                    Logger.logError(error, context: "stopTracking", category: .session)
                }
            }
        )
    }
}

// MARK: - Tracking Map View

struct TrackingMapView: View {
    let userLocation: CLLocationCoordinate2D?
    let routeCoordinates: [CLLocationCoordinate2D]
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var lastUserLocation: CLLocationCoordinate2D?
    
    var body: some View {
        Map(position: $cameraPosition) {
            // Position de l'utilisateur
            if let userLocation = userLocation {
                Annotation("Vous", coordinate: userLocation) {
                    ZStack {
                        Circle()
                            .fill(Color.coralAccent)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            // Tracé GPS
            if !routeCoordinates.isEmpty {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(
                        LinearGradient(
                            colors: [Color.coralAccent, Color.pinkAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 4
                    )
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .onChange(of: userLocation?.latitude) { _, _ in
            // Centrer la carte quand la position change
            centerOnUserLocation()
        }
        .onChange(of: userLocation?.longitude) { _, _ in
            // Centrer la carte quand la position change
            centerOnUserLocation()
        }
        .onAppear {
            // Centrer au démarrage
            centerOnUserLocation()
        }
    }
    
    private func centerOnUserLocation() {
        guard let location = userLocation else { return }
        
        // Vérifier si la position a vraiment changé
        if let last = lastUserLocation,
           abs(last.latitude - location.latitude) < 0.0001 &&
           abs(last.longitude - location.longitude) < 0.0001 {
            return
        }
        
        lastUserLocation = location
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: location,
                    distance: 1000,
                    heading: 0,
                    pitch: 0
                )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionTrackingView(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                participants: ["user1"]
            )
        )
    }
    .preferredColorScheme(.dark)
}
