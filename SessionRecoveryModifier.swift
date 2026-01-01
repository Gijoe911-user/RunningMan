//
//  SessionRecoveryModifier.swift
//  RunningMan
//
//  Modificateur pour afficher l'alerte de récupération de session
//  🛡️ À appliquer sur la vue racine de l'app
//

import SwiftUI

/// Modificateur pour gérer la récupération de session interrompue
struct SessionRecoveryModifier: ViewModifier {
    
    @StateObject private var recoveryManager = SessionRecoveryManager.shared
    @State private var isPerformingAction = false
    
    func body(content: Content) -> some View {
        content
            .task {
                // Vérifier au démarrage de l'app
                await recoveryManager.checkForInterruptedSession()
            }
            .alert("Session interrompue détectée", isPresented: $recoveryManager.shouldShowRecoveryAlert) {
                // Bouton Reprendre
                Button("Reprendre") {
                    performAction {
                        _ = await recoveryManager.resumeSession()
                    }
                }
                
                // Bouton Terminer
                Button("Terminer") {
                    performAction {
                        _ = await recoveryManager.endInterruptedSession()
                    }
                }
                
                // Bouton Plus tard
                Button("Plus tard", role: .cancel) {
                    recoveryManager.dismissAlert()
                }
            } message: {
                if let session = recoveryManager.interruptedSession {
                    Text("""
                    Vous avez une session active qui n'a pas été terminée.
                    
                    Démarrée il y a \(formatTimeSince(session.startedAt))
                    Distance : \(String(format: "%.2f km", session.distanceInKilometers))
                    
                    Voulez-vous la reprendre ou la terminer ?
                    """)
                }
            }
            .overlay {
                // Overlay de chargement pendant l'action
                if isPerformingAction {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            
                            Text("Traitement en cours...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func performAction(_ action: @escaping () async -> Void) {
        guard !isPerformingAction else { return }
        
        isPerformingAction = true
        
        Task {
            await action()
            
            await MainActor.run {
                isPerformingAction = false
            }
        }
    }
    
    private func formatTimeSince(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - View Extension

extension View {
    /// Ajoute la gestion de récupération de session interrompue
    func handleSessionRecovery() -> some View {
        modifier(SessionRecoveryModifier())
    }
}
