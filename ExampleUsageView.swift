//
//  ExampleUsageView.swift
//  RunningMan
//
//  Exemple complet d'intégration du système de tracking
//  📚 À utiliser comme référence
//

import SwiftUI

// MARK: - Exemple 1 : App avec TabView

struct ExampleAppView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var squadViewModel = SquadViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environment(authViewModel)
                    .environment(squadViewModel)
                    // 🔑 IMPORTANT : Ajouter le modifier de récupération
                    .handleSessionRecovery()
            } else {
                LoginView()
                    .environment(authViewModel)
            }
        }
    }
}

// MARK: - TabView Principal

struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1 : Dashboard
            HomeView()
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }
            
            // Tab 2 : Sessions (NOUVEAU)
            AllSessionsView()
                .tabItem {
                    Label("Sessions", systemImage: "figure.run")
                }
            
            // Tab 3 : Squads
            SquadsView()
                .tabItem {
                    Label("Squads", systemImage: "person.3.fill")
                }
            
            // Tab 4 : Profil
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle.fill")
                }
        }
    }
}

// MARK: - Exemple 2 : Créer une Session depuis une Squad

struct SquadDetailViewExample: View {
    let squad: SquadModel
    @Environment(SquadViewModel.self) private var squadVM
    @State private var showCreateSession = false
    @State private var showTracking = false
    @State private var createdSession: SessionModel?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Infos de la squad
                squadInfoSection
                
                // Bouton pour créer une session
                createSessionButton
            }
            .padding()
        }
        .navigationTitle(squad.name)
        .sheet(isPresented: $showCreateSession) {
            QuickCreateSessionView(squad: squad) { session in
                // Session créée, afficher la vue de tracking
                createdSession = session
                showTracking = true
            }
        }
        .fullScreenCover(isPresented: $showTracking) {
            if let session = createdSession {
                NavigationStack {
                    SessionTrackingView(session: session)
                }
            }
        }
    }
    
    private var squadInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(squad.name)
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("\(squad.members.count) membres")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var createSessionButton: some View {
        Button {
            showCreateSession = true
        } label: {
            Label("Démarrer une session", systemImage: "play.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.coralAccent, Color.pinkAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Exemple 3 : Utilisation Directe du TrackingManager

struct DirectTrackingExample: View {
    let session: SessionModel
    
    @StateObject private var trackingManager = TrackingManager.shared
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Stats
            statsSection
            
            // Contrôles manuels
            controlsSection
        }
        .padding()
        .alert("Terminer la session ?", isPresented: $showConfirmation) {
            Button("Annuler", role: .cancel) { }
            Button("Terminer", role: .destructive) {
                Task {
                    try? await trackingManager.stopTracking()
                }
            }
        }
        .task {
            // Démarrer automatiquement
            _ = await trackingManager.startTracking(for: session)
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            // Distance
            StatRow(
                icon: "location.fill",
                title: "Distance",
                value: String(format: "%.2f km", trackingManager.currentDistance / 1000),
                color: .coralAccent
            )
            
            // Durée
            StatRow(
                icon: "clock.fill",
                title: "Durée",
                value: formatDuration(trackingManager.currentDuration),
                color: .blue
            )
            
            // Vitesse
            StatRow(
                icon: "speedometer",
                title: "Vitesse",
                value: String(format: "%.1f km/h", trackingManager.currentSpeed * 3.6),
                color: .green
            )
        }
    }
    
    private var controlsSection: some View {
        HStack(spacing: 16) {
            // Play / Pause
            Button {
                Task {
                    if trackingManager.isTracking {
                        await trackingManager.pauseTracking()
                    } else if trackingManager.isPaused {
                        await trackingManager.resumeTracking()
                    }
                }
            } label: {
                Image(systemName: trackingManager.isTracking ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.coralAccent)
            }
            
            // Stop
            Button {
                showConfirmation = true
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Exemple 4 : Observer une Session en Mode Supporter

struct SupporterViewExample: View {
    let session: SessionModel
    
    @StateObject private var viewModel = ActiveSessionViewModel()
    
    var body: some View {
        VStack {
            // Carte avec positions en temps réel
            EnhancedSessionMapView(
                userLocation: viewModel.userLocation,
                runnerLocations: viewModel.runnerLocations,
                routeCoordinates: []  // Pas de tracé pour le supporter
            )
            .frame(height: 400)
            
            // Liste des coureurs actifs
            List(viewModel.runnerLocations) { runner in
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    
                    Text(runner.displayName)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("En direct")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .task {
            if let sessionId = session.id {
                await viewModel.startObserving(sessionId: sessionId)
            }
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }
}

// MARK: - Exemple 5 : Récupération Personnalisée

struct CustomRecoveryExample: View {
    @StateObject private var recoveryManager = SessionRecoveryManager.shared
    @State private var showCustomAlert = false
    
    var body: some View {
        VStack {
            Text("Mon App")
                .font(.largeTitle)
        }
        .task {
            // Vérifier au démarrage
            await recoveryManager.checkForInterruptedSession()
            
            // Afficher une alerte personnalisée
            if recoveryManager.interruptedSession != nil {
                showCustomAlert = true
            }
        }
        .alert("Oups ! Session interrompue", isPresented: $showCustomAlert) {
            Button("Reprendre ma course") {
                Task {
                    let success = await recoveryManager.resumeSession()
                    if success {
                        // Naviguer vers SessionTrackingView
                    }
                }
            }
            
            Button("Terminer et sauvegarder") {
                Task {
                    _ = await recoveryManager.endInterruptedSession()
                }
            }
            
            Button("Ignorer") {
                recoveryManager.dismissAlert()
            }
        } message: {
            if let session = recoveryManager.interruptedSession {
                Text("Vous avez une session de \(String(format: "%.2f km", session.distanceInKilometers)) qui attend.")
            }
        }
    }
}

// MARK: - Exemple 6 : Widget personnalisé avec stats

struct TrackingStatsWidget: View {
    @StateObject private var trackingManager = TrackingManager.shared
    
    var body: some View {
        if let session = trackingManager.activeTrackingSession {
            HStack(spacing: 16) {
                // Distance
                VStack {
                    Text(String(format: "%.2f", trackingManager.currentDistance / 1000))
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("km")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // Durée
                VStack {
                    Text(formatDuration(trackingManager.currentDuration))
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("temps")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // État
                VStack {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 12, height: 12)
                    
                    Text(trackingManager.trackingState.displayName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            Text("Aucun tracking actif")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var stateColor: Color {
        switch trackingManager.trackingState {
        case .idle: return .gray
        case .active: return .green
        case .paused: return .orange
        case .stopping: return .red
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Exemple 7 : Notification Locale après 30 min de pause

import UserNotifications

struct TrackingNotificationExample {
    
    static func scheduleResumeReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Course en pause"
        content.body = "Votre session est en pause depuis 30 minutes. Reprendre ?"
        content.sound = .default
        content.categoryIdentifier = "TRACKING_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    static func cancelResumeReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// Utilisation dans TrackingManager :
// pauseTracking() → TrackingNotificationExample.scheduleResumeReminder()
// resumeTracking() → TrackingNotificationExample.cancelResumeReminder()

// MARK: - Preview

#Preview("App Complète") {
    ExampleAppView()
        .preferredColorScheme(.dark)
}

#Preview("Tracking Direct") {
    NavigationStack {
        DirectTrackingExample(
            session: SessionModel(
                squadId: "squad1",
                creatorId: "user1",
                participants: ["user1"]
            )
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Widget Stats") {
    TrackingStatsWidget()
        .padding()
        .background(Color.darkNavy)
        .preferredColorScheme(.dark)
}
