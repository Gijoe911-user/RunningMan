//
//  SessionTrackingView.swift
//  RunningMan
//
//  Vue complète pour tracker une session avec stats en temps réel
//  🏃 Affiche les contrôles + stats + carte avec boutons en overlay
// Version Zstack la plus recente 
//

import SwiftUI
import MapKit

struct SessionTrackingView: View {
    let session: SessionModel
    @StateObject private var trackingManager = TrackingManager.shared
    @State private var currentTrackingState: TrackingState = .idle
    @State private var showStopConfirmation = false
    @State private var isSpectatorMode = true  // 🆕 Mode spectateur par défaut
    @State private var showStartTrackingConfirmation = false  // 🆕 Confirmation démarrage tracking
    @State private var errorMessage: String = ""
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            // Carte avec tracé GPS (plein écran)
            TrackingMapView(
                userLocation: trackingManager.routeCoordinates.last,
                routeCoordinates: trackingManager.routeCoordinates
            )
            
            // Badge de statut (haut à droite)
            VStack {
                HStack {
                    Spacer()
                    stateIndicator
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                }
                Spacer()
            }
            
            // Stats flottantes (haut, sous le badge)
            VStack {
                statsOverlay
                    .padding(.top, 110)
                Spacer()
            }
            
            // Boutons de contrôle (bas, sur la carte)
            VStack {
                Spacer()
                
                // 🆕 Mode Spectateur : Afficher "Démarrer l'activité"
                if isSpectatorMode && currentTrackingState == .idle {
                    spectatorModeButtons
                } else {
                    // Mode Coureur : Afficher Play/Pause/Stop
                    trackingControlButtons
                }
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .navigationTitle("Session en cours")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 🆕 MODE SPECTATEUR : Charger les routes existantes SANS démarrer le tracking
            if let sessionId = session.id {
                Logger.log("[SPECTATOR] 👁️ Entrée en mode spectateur - session: \(sessionId)", category: .ui)
                await loadExistingRoutes(sessionId: sessionId)
            }
        }
        .onChange(of: trackingManager.trackingState) { oldValue, newValue in
            // Synchroniser l'état local avec TrackingManager
            Logger.log("[AUDIT-STV-05] 🔄 État synchronisé: \(oldValue.displayName) → \(newValue.displayName)", category: .ui)
            currentTrackingState = newValue
            
            // Basculer hors du mode spectateur si le tracking démarre
            if newValue == .active {
                isSpectatorMode = false
            }
        }
        .onAppear {
            // Initialiser l'état local
            currentTrackingState = trackingManager.trackingState
            Logger.log("[AUDIT-STV-01] 🏃 SessionTrackingView.onAppear - session: \(session.id ?? "unknown")", category: .ui)
        }
        .alert("Terminer la session ?", isPresented: $showStopConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Terminer", role: .destructive) {
                Task {
                    await stopTracking()
                }
            }
        } message: {
            Text("Le tracking sera arrêté et la session sera sauvegardée.")
        }
        .alert("Démarrer l'activité ?", isPresented: $showStartTrackingConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Démarrer", role: .none) {
                Task {
                    await startTracking()
                }
            }
        } message: {
            Text("Votre GPS et HealthKit seront activés pour enregistrer votre parcours.")
        }
        .alert("Erreur", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - State Indicator (Badge en haut)
    
    private var stateIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor)
                .frame(width: 10, height: 10)
            
            Text(isSpectatorMode ? "👁️ Spectateur" : currentTrackingState.displayName)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    private var stateColor: Color {
        if isSpectatorMode {
            return .blue
        }
        
        switch currentTrackingState {
        case .idle: return .gray
        case .active: return .green
        case .paused: return .orange
        case .stopping: return .red
        }
    }
    
    // MARK: - Spectator Mode Buttons (Nouveau)
    
    private var spectatorModeButtons: some View {
        Button {
            Logger.log("[SPECTATOR] 🏃 Bouton 'Démarrer l'activité' pressé", category: .ui)
            showStartTrackingConfirmation = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Démarrer l'activité")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                LinearGradient(
                    colors: [Color.coralAccent, Color.pinkAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Stats Overlay (Flottant sous le badge)
    
    private var statsOverlay: some View {
        HStack(spacing: 12) {
            // Distance
            QuickStatBadge(
                icon: "location.fill",
                value: FormatHelper.formattedDistance(trackingManager.currentDistance),
                color: Color.coralAccent
            )
            
            // Durée
            QuickStatBadge(
                icon: "clock.fill",
                value: FormatHelper.formattedDuration(trackingManager.currentDuration),
                color: Color.pinkAccent
            )
            
            // Vitesse
            QuickStatBadge(
                icon: "gauge.high",
                value: FormatHelper.formattedSpeed(trackingManager.currentSpeed),
                color: Color.blueAccent
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tracking Control Buttons (Overlay bas)
    
    private var trackingControlButtons: some View {
        HStack(spacing: 20) {
            // Bouton Play/Pause (grand cercle coralAccent)
            Button {
                Logger.log("[AUDIT-STV-02] 🎮 Bouton Play/Pause pressé - état: \(currentTrackingState.displayName)", category: .ui)
                Task {
                    await handlePlayPause()
                }
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: playPauseGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: playPauseIcon)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Label sous le bouton
                    Text(playPauseLabel)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .disabled(currentTrackingState == .stopping)
            
            // Bouton Stop (petit cercle rouge)
            if currentTrackingState == .active || currentTrackingState == .paused {
                Button {
                    Logger.log("[AUDIT-STV-03] 🛑 Bouton Stop pressé", category: .ui)
                    showStopConfirmation = true
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "stop.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Label sous le bouton
                        Text("Terminer")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .disabled(currentTrackingState == .stopping)
            }
        }
    }
    
    private var playPauseIcon: String {
        switch currentTrackingState {
        case .idle:
            return "play.fill"
        case .active:
            return "pause.fill"
        case .paused:
            return "play.fill"
        case .stopping:
            return "stop.fill"
        }
    }
    
    private var playPauseLabel: String {
        switch currentTrackingState {
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
    
    private var playPauseGradientColors: [Color] {
        switch currentTrackingState {
        case .active:
            return [Color.orange, Color.red]  // Pause = Orange/Rouge
        case .paused:
            return [Color.green, Color.coralAccent]  // Reprendre = Vert
        default:
            return [Color.coralAccent, Color.pinkAccent]  // Démarrer = Coral
        }
    }
    
    // MARK: - Actions
    
    /// Gère le clic sur Play/Pause
    private func handlePlayPause() async {
        guard let sessionId = session.id,
              let userId = AuthService.shared.currentUserId else {
            errorMessage = "Session ou utilisateur invalide"
            showError = true
            return
        }
        
        do {
            if currentTrackingState == .active {
                // Mettre en pause
                await trackingManager.pauseTracking()
                
                try await SessionService.shared.pauseParticipantTracking(
                    sessionId: sessionId,
                    userId: userId
                )
                
                Logger.log("[TRACKING] ⏸️ Tracking mis en pause", category: .ui)
                
            } else if currentTrackingState == .paused {
                // Reprendre
                await trackingManager.resumeTracking()
                
                try await SessionService.shared.resumeParticipantTracking(
                    sessionId: sessionId,
                    userId: userId
                )
                
                Logger.log("[TRACKING] ▶️ Tracking repris", category: .ui)
                
            } else if currentTrackingState == .idle {
                // Démarrer (normalement pas appelé ici car bouton "Démarrer l'activité" est séparé)
                await startTracking()
            }
        } catch {
            errorMessage = "Erreur lors du changement d'état : \(error.localizedDescription)"
            showError = true
            Logger.logError(error, context: "handlePlayPause", category: .ui)
        }
    }
    
    // MARK: - Actions
    
    /// 🆕 Démarre le tracking (mode coureur)
    private func startTracking() async {
        Logger.log("[TRACKING] 🏃 Démarrage du tracking utilisateur", category: .ui)
        
        guard let sessionId = session.id,
              let userId = AuthService.shared.currentUserId else {
            errorMessage = "Session ou utilisateur invalide"
            showError = true
            return
        }
        
        // 🔴 GARDE-FOU : Vérifier qu'il n'y a pas déjà une session active
        do {
            // Récupérer toutes les sessions actives de l'utilisateur
            let activeSessions = try await SessionService.shared.getAllActiveSessions(userId: userId)
            
            // Filtrer celles où l'utilisateur est en train de tracker
            let trackingSessions = activeSessions.filter { sess in
                sess.participantActivity?[userId]?.isTracking == true && sess.id != sessionId
            }
            
            if !trackingSessions.isEmpty {
                // L'utilisateur tracke déjà dans une autre session
                errorMessage = "Vous êtes déjà en train de courir dans une autre session. Terminez-la avant d'en commencer une nouvelle."
                showError = true
                Logger.log("[TRACKING] ⚠️ Tracking bloqué : session active ailleurs", category: .ui)
                return
            }
            
            // OK : Démarrer le tracking
            let success = await trackingManager.startTracking(for: session)
            
            if success {
                // Mettre à jour Firestore : participant devient actif
                try await SessionService.shared.startParticipantTracking(
                    sessionId: sessionId,
                    userId: userId
                )
                
                isSpectatorMode = false
                Logger.logSuccess("[TRACKING] ✅ Tracking démarré - passage en mode coureur", category: .ui)
            } else {
                errorMessage = "Impossible de démarrer le GPS. Vérifiez vos permissions."
                showError = true
                Logger.log("[TRACKING] ⚠️ Échec démarrage tracking", category: .ui)
            }
            
        } catch {
            errorMessage = "Erreur lors de la vérification des sessions actives : \(error.localizedDescription)"
            showError = true
            Logger.logError(error, context: "startTracking", category: .ui)
        }
    }
    
    /// 🆕 Charge les routes existantes des participants (mode spectateur)
    private func loadExistingRoutes(sessionId: String) async {
        Logger.log("[SPECTATOR] 📥 Chargement des routes existantes...", category: .ui)
        
        // Charger toutes les routes de la session
        await trackingManager.loadAllRoutes(sessionId: sessionId)
        
        Logger.logSuccess("[SPECTATOR] ✅ Routes chargées", category: .ui)
    }
    
    private func stopTracking() async {
        Logger.log("[AUDIT-STV-04] 🛑 SessionTrackingView.stopTracking appelé", category: .session)
        
        guard let sessionId = session.id,
              let userId = AuthService.shared.currentUserId else {
            errorMessage = "Session ou utilisateur invalide"
            showError = true
            return
        }
        
        do {
            // Arrêter le TrackingManager
            try await trackingManager.stopTracking()
            
            // Mettre à jour Firestore : participant termine son tracking
            let finalDistance = trackingManager.currentDistance
            let finalDuration = trackingManager.currentDuration
            
            try await SessionService.shared.endParticipantTracking(
                sessionId: sessionId,
                userId: userId,
                finalDistance: finalDistance,
                finalDuration: finalDuration
            )
            
            Logger.logSuccess("[TRACKING] ✅ Tracking terminé et sauvegardé", category: .session)
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            errorMessage = "Erreur lors de l'arrêt du tracking : \(error.localizedDescription)"
            showError = true
            Logger.logError(error, context: "stopTracking", category: .session)
        }
    }
}

// MARK: - Quick Stat Badge (Inline)

private struct QuickStatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
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
                        lineWidth: 2.5  // 🎯 Réduit de 4 à 2.5 pour un trait plus fin
                    )
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .onChange(of: userLocation?.latitude) { _, _ in
            centerOnUserLocation()
        }
        .onChange(of: userLocation?.longitude) { _, _ in
            centerOnUserLocation()
        }
        .onAppear {
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
