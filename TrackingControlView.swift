//
//  TrackingControlView.swift
//  RunningMan
//
//  Vue de contrôle du tracking GPS avec boutons Start/Stop/Pause
//  Similaire à Runtastic / Strava
//

import SwiftUI
import CoreLocation

/// Vue de contrôle du tracking GPS
struct TrackingControlView: View {
    
    @ObservedObject var locationService = OptimizedLocationService.shared
    
    let sessionId: String
    let userId: String
    
    @State private var showStopConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Statistiques en temps réel
            statsSection
            
            // Boutons de contrôle
            controlButtons
            
            // Informations de debug (à retirer en production)
            if locationService.isTracking {
                debugInfo
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // Distance
                StatCard(
                    title: "Distance",
                    value: String(format: "%.2f", locationService.trackingStats.distanceInKm),
                    unit: "km",
                    icon: "figure.run"
                )
                
                // Durée
                StatCard(
                    title: "Durée",
                    value: locationService.trackingStats.formattedDuration,
                    unit: "",
                    icon: "timer"
                )
                
                // Allure
                StatCard(
                    title: "Allure",
                    value: locationService.trackingStats.currentPace,
                    unit: "/km",
                    icon: "speedometer"
                )
            }
            
            // Vitesse actuelle (grande)
            if locationService.isTracking {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    
                    Text(String(format: "%.1f", locationService.trackingStats.currentSpeedKmh))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    Text("km/h")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 16) {
            if !locationService.isTracking {
                // Bouton Démarrer
                Button(action: startTracking) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Démarrer")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                // Bouton Pause / Reprendre
                Button(action: togglePause) {
                    HStack {
                        Image(systemName: locationService.trackingStats.isPaused ? "play.fill" : "pause.fill")
                        Text(locationService.trackingStats.isPaused ? "Reprendre" : "Pause")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(locationService.trackingStats.isPaused ? Color.green : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Bouton Arrêter
                Button(action: { showStopConfirmation = true }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Arrêter")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .alert("Arrêter le tracking ?", isPresented: $showStopConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Arrêter", role: .destructive) {
                stopTracking()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir arrêter le tracking ? Les statistiques seront sauvegardées.")
        }
    }
    
    // MARK: - Debug Info
    
    private var debugInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Debug Info")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text("Points GPS: \(locationService.trackingStats.pointsCount)")
                .font(.caption2)
            
            Text("Écritures Firestore: \(locationService.firestoreWriteCount)")
                .font(.caption2)
            
            if let location = locationService.currentLocation {
                Text("Précision: \(String(format: "%.1f", location.horizontalAccuracy))m")
                    .font(.caption2)
            }
            
            Text("Config: Upload toutes les \(Int(locationService.configuration.firestoreUploadInterval))s")
                .font(.caption2)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private func startTracking() {
        locationService.startTracking(sessionId: sessionId, userId: userId)
    }
    
    private func togglePause() {
        if locationService.trackingStats.isPaused {
            locationService.resumeTracking()
        } else {
            locationService.pauseTracking()
        }
    }
    
    private func stopTracking() {
        locationService.stopTracking()
    }
}

// MARK: - Preview

#Preview {
    TrackingControlView(
        sessionId: "session123",
        userId: "user456"
    )
    .padding()
}
