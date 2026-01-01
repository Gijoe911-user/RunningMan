//
//  SessionTrackingControlsView.swift
//  RunningMan
//
//  Contrôles de tracking : Play / Pause / Stop
//  🎮 Interface pour gérer le tracking GPS en temps réel
//

import SwiftUI

struct SessionTrackingControlsView: View {
    let session: SessionModel
    @Binding var trackingState: TrackingState
    let onStart: () async -> Void
    let onPause: () async -> Void
    let onResume: () async -> Void
    let onStop: () async -> Void
    
    @State private var showStopConfirmation = false
    @State private var isPerformingAction = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Bouton principal : Start / Resume / Pause
            primaryButton
            
            // Bouton Stop (visible uniquement si actif ou en pause)
            if trackingState != .idle {
                stopButton
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .alert("Terminer la session ?", isPresented: $showStopConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Terminer", role: .destructive) {
                performAction {
                    await onStop()
                }
            }
        } message: {
            Text("Votre session sera sauvegardée et le tracking arrêté.")
        }
    }
    
    // MARK: - Primary Button
    
    @ViewBuilder
    private var primaryButton: some View {
        Button {
            performPrimaryAction()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(primaryButtonColor)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: primaryButtonIcon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryButtonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(primaryButtonSubtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
        .disabled(isPerformingAction || trackingState == .stopping)
        .opacity(isPerformingAction ? 0.6 : 1.0)
    }
    
    // MARK: - Stop Button
    
    private var stopButton: some View {
        Button {
            showStopConfirmation = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 56, height: 56)
                
                if trackingState == .stopping {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(trackingState == .stopping)
    }
    
    // MARK: - Computed Properties
    
    private var primaryButtonIcon: String {
        switch trackingState {
        case .idle:
            return "play.fill"
        case .active:
            return "pause.fill"
        case .paused:
            return "play.fill"
        case .stopping:
            return "hourglass"
        }
    }
    
    private var primaryButtonTitle: String {
        switch trackingState {
        case .idle:
            return "Démarrer"
        case .active:
            return "Pause"
        case .paused:
            return "Reprendre"
        case .stopping:
            return "Arrêt..."
        }
    }
    
    private var primaryButtonSubtitle: String {
        switch trackingState {
        case .idle:
            return "Lancer le tracking"
        case .active:
            return "Mettre en pause"
        case .paused:
            return "Continuer la course"
        case .stopping:
            return "Sauvegarde en cours"
        }
    }
    
    private var primaryButtonColor: Color {
        switch trackingState {
        case .idle:
            return .coralAccent
        case .active:
            return .orange
        case .paused:
            return .green
        case .stopping:
            return .gray
        }
    }
    
    // MARK: - Actions
    
    private func performPrimaryAction() {
        switch trackingState {
        case .idle:
            performAction {
                await onStart()
            }
        case .active:
            performAction {
                await onPause()
            }
        case .paused:
            performAction {
                await onResume()
            }
        case .stopping:
            break // Pas d'action pendant l'arrêt
        }
    }
    
    private func performAction(_ action: @escaping () async -> Void) {
        guard !isPerformingAction else { return }
        
        isPerformingAction = true
        
        Task {
            await action()
            
            // Attendre un peu pour que l'état se mette à jour
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                isPerformingAction = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // État Idle
        SessionTrackingControlsView(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                participants: ["user1"]
            ),
            trackingState: .constant(.idle),
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
        
        // État Active
        SessionTrackingControlsView(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                participants: ["user1"]
            ),
            trackingState: .constant(.active),
            onStart: {},
            onPause: {},
            onResume: {},
            onStop: {}
        )
        
        // État Paused
        SessionTrackingControlsView(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
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
    .preferredColorScheme(.dark)
}
