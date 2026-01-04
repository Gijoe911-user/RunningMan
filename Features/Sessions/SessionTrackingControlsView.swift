//
//  SessionTrackingControlsView.swift
//  RunningMan
//
//  Contrôles de tracking (Play/Pause/Stop) pour une session active
//  🎯 Affiche les boutons selon l'état du TrackingManager (source de vérité)
//
//  🆕 MODIFICATIONS v2.0 (3 janvier 2026) :
//  - Mode Spectateur : Pas de démarrage automatique du tracking
//  - Système Heartbeat : Détection automatique des participants inactifs > 60s
//  - Fin de session : Ne se termine que si TOUS les coureurs sont inactifs/terminés
//

import SwiftUI

/// Vue de contrôle pour le tracking d'une session
///
/// Affiche les boutons Play/Pause/Stop selon l'état actuel du tracking.
/// Utilise l'état du TrackingManager comme source de vérité, pas le statut Firestore.
///
/// **États possibles :**
/// - `.idle` : Affiche "Démarrer"
/// - `.active` : Affiche "Pause" et "Stop"
/// - `.paused` : Affiche "Reprendre" et "Stop"
/// - `.stopping` : Affiche un spinner
///
/// **Usage :**
/// ```swift
/// SessionTrackingControlsView(
///     session: session,
///     trackingState: $trackingState,
///     onStart: { await trackingManager.startTracking(for: session) },
///     onPause: { await trackingManager.pauseTracking() },
///     onResume: { await trackingManager.resumeTracking() },
///     onStop: { await stopTrackingAndEndSession() }
/// )
/// ```
struct SessionTrackingControlsView: View {
    
    // MARK: - Properties
    
    /// Session en cours
    let session: SessionModel
    
    /// État du tracking (bindé depuis le parent)
    @Binding var trackingState: TrackingState
    
    /// Callbacks pour les actions
    let onStart: () async -> Void
    let onPause: () async -> Void
    let onResume: () async -> Void
    let onStop: () async -> Void
    
    /// État local pour les animations
    @State private var isProcessing = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            // Indicateur d'état
            stateIndicator
            
            // Boutons de contrôle
            controlButtons
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - State Indicator
    
    /// Indicateur visuel de l'état du tracking
    private var stateIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor)
                .frame(width: 12, height: 12)
                .shadow(color: stateColor.opacity(0.5), radius: 4)
            
            Text(stateLabel)
                .font(.caption.bold())
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    /// Couleur de l'indicateur selon l'état
    private var stateColor: Color {
        switch trackingState {
        case .idle:
            return .gray
        case .active:
            return .green
        case .paused:
            return .orange
        case .stopping:
            return .red
        }
    }
    
    /// Label de l'indicateur selon l'état
    private var stateLabel: String {
        switch trackingState {
        case .idle:
            return "Prêt à démarrer"
        case .active:
            return "Tracking actif"
        case .paused:
            return "En pause"
        case .stopping:
            return "Arrêt en cours..."
        }
    }
    
    // MARK: - Control Buttons
    
    /// Boutons de contrôle selon l'état
    private var controlButtons: some View {
        HStack(spacing: 12) {
            switch trackingState {
            case .idle:
                // Démarrer
                startButton
                
            case .active:
                // Pause + Stop
                pauseButton
                stopButton
                
            case .paused:
                // Reprendre + Stop
                resumeButton
                stopButton
                
            case .stopping:
                // Spinner
                stoppingIndicator
            }
        }
    }
    
    // MARK: - Individual Buttons
    
    /// Bouton Démarrer
    private var startButton: some View {
        Button {
            guard !isProcessing else { return }
            isProcessing = true
            Task {
                await onStart()
                isProcessing = false
            }
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                    Text("Démarrer")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.green, .green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isProcessing)
    }
    
    /// Bouton Pause
    private var pauseButton: some View {
        Button {
            guard !isProcessing else { return }
            isProcessing = true
            Task {
                await onPause()
                isProcessing = false
            }
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "pause.fill")
                    Text("Pause")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.orange, .orange.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isProcessing)
    }
    
    /// Bouton Reprendre
    private var resumeButton: some View {
        Button {
            guard !isProcessing else { return }
            isProcessing = true
            Task {
                await onResume()
                isProcessing = false
            }
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "play.fill")
                    Text("Reprendre")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.green, .green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isProcessing)
    }
    
    /// Bouton Stop (plus petit, sur le côté)
    private var stopButton: some View {
        Button {
            guard !isProcessing else { return }
            isProcessing = true
            Task {
                await onStop()
                isProcessing = false
            }
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                }
            }
            .foregroundColor(.white)
            .frame(width: 60)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.red, .red.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isProcessing)
    }
    
    /// Indicateur d'arrêt en cours
    private var stoppingIndicator: some View {
        HStack {
            ProgressView()
                .tint(.white)
            Text("Arrêt en cours...")
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // État idle
        SessionTrackingControlsView(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                startedAt: Date(),
                status: .active,
                participants: ["user1"]
            ),
            trackingState: .constant(.idle),
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
        
        // État active
        SessionTrackingControlsView(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                startedAt: Date(),
                status: .active,
                participants: ["user1"]
            ),
            trackingState: .constant(.active),
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
        
        // État paused
        SessionTrackingControlsView(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                startedAt: Date(),
                status: .paused,
                participants: ["user1"]
            ),
            trackingState: .constant(.paused),
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
    }
    .padding()
    .background(Color.darkNavy)
}
