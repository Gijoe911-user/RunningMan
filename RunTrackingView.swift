//
//  RunTrackingView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue pour tracker une course en temps réel
struct RunTrackingView: View {
    
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var distance: Double = 0.0
    @State private var duration: TimeInterval = 0
    @State private var pace: String = "0:00"
    @State private var calories: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkNavy
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Stats principales
                    VStack(spacing: 40) {
                        // Distance
                        VStack(spacing: 8) {
                            Text(String(format: "%.2f", distance))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("kilomètres")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Stats secondaires
                        HStack(spacing: 40) {
                            // Durée
                            VStack(spacing: 4) {
                                Text(formatDuration(duration))
                                    .font(.title.bold())
                                    .foregroundColor(.coralAccent)
                                
                                Text("Temps")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Rythme
                            VStack(spacing: 4) {
                                Text(pace)
                                    .font(.title.bold())
                                    .foregroundColor(.blueAccent)
                                
                                Text("Rythme /km")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Calories
                            VStack(spacing: 4) {
                                Text("\(calories)")
                                    .font(.title.bold())
                                    .foregroundColor(.yellowAccent)
                                
                                Text("Calories")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Boutons de contrôle
                    VStack(spacing: 16) {
                        if !isRunning {
                            // Bouton Démarrer
                            Button {
                                startRun()
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.title2)
                                    Text("Démarrer")
                                        .font(.title3.bold())
                                }
                                .foregroundColor(.white)
                                .frame(width: 240, height: 70)
                                .background(
                                    LinearGradient(
                                        colors: [Color.coralAccent, Color.pinkAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: .coralAccent.opacity(0.5), radius: 10, y: 5)
                            }
                        } else {
                            // Boutons Pause et Stop
                            HStack(spacing: 20) {
                                // Pause/Resume
                                Button {
                                    togglePause()
                                } label: {
                                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 70, height: 70)
                                        .background(Color.blueAccent) // explicite Color.
                                        .clipShape(Circle())
                                }
                                
                                // Stop
                                Button {
                                    stopRun()
                                } label: {
                                    Image(systemName: "stop.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 70, height: 70)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Course")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Actions
    
    private func startRun() {
        isRunning = true
        isPaused = false
        // TODO: Démarrer le tracking GPS et le timer
    }
    
    private func togglePause() {
        isPaused.toggle()
        // TODO: Mettre en pause ou reprendre le tracking
    }
    
    private func stopRun() {
        isRunning = false
        isPaused = false
        // TODO: Arrêter le tracking et sauvegarder la course
        // Réinitialiser les stats
        distance = 0
        duration = 0
        pace = "0:00"
        calories = 0
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview("Idle") {
    RunTrackingView()
        .preferredColorScheme(.dark)
}

#Preview("Running") {
    // Aperçu simple sans mutation des @State internes pour éviter les erreurs de ViewBuilder
    RunTrackingView()
        .preferredColorScheme(.dark)
}
