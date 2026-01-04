//
//  SessionStatsWidget.swift
//  RunningMan
//
//  Widget pour afficher les statistiques en temps réel pendant une session
//

import SwiftUI
import Combine

/// Widget d'affichage des statistiques en temps réel pendant une session de course
///
/// Ce widget affiche 4 métriques principales :
/// - ⏱️ Temps écoulé depuis le début de la session
/// - 📍 Distance parcourue (calculée depuis le tracé GPS)
/// - ❤️ Fréquence cardiaque actuelle (via HealthKit)
/// - 🔥 Calories brûlées (via HealthKit)
///
/// **Mise à jour automatique :**
/// - Le temps s'incrémente chaque seconde via un Timer Combine
/// - Les autres métriques se mettent à jour via les `@Published` du ViewModel
///
/// **Architecture :**
/// - Composant léger (< 150 lignes)
/// - Formatage délégué à `SessionStatsFormatters`
/// - Sous-composants séparés (`SessionStatCard`, badges)
///
/// **Usage :**
/// ```swift
/// SessionStatsWidget(
///     session: activeSession,
///     currentHeartRate: viewModel.currentHeartRate,
///     currentCalories: viewModel.currentCalories,
///     routeDistance: calculateRouteDistance()
/// )
/// ```
///
/// - SeeAlso: `SessionsViewModel`, `HealthKitManager`, `SessionStatsFormatters`
struct SessionStatsWidget: View {
    
    // MARK: - Properties
    
    /// Session de course active
    let session: SessionModel
    
    /// Fréquence cardiaque actuelle en BPM, `nil` si non disponible
    let currentHeartRate: Double?
    
    /// Calories brûlées depuis le début de la session
    let currentCalories: Double?
    
    /// Distance totale parcourue en mètres
    let routeDistance: Double
    
    // MARK: - State
    
    /// Heure actuelle pour calculer le temps écoulé (mise à jour chaque seconde)
    @State private var currentTime = Date()
    
    /// Timer Combine pour rafraîchir le temps chaque seconde
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            header
            
            // Grid de stats
            statsGrid
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - View Components
    
    /// En-tête du widget avec icône et titre
    private var header: some View {
        HStack {
            Image(systemName: "chart.xyaxis.line")
                .foregroundColor(.coralAccent)
            
            Text("Stats en direct")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    /// Grille 2x2 des statistiques principales
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // Temps écoulé
            SessionStatCard(
                icon: "clock.fill",
                value: timeElapsedFormatted,
                label: "Temps",
                color: Color.blue
            )
            
            // Distance
            SessionStatCard(
                icon: "location.fill",
                value: distanceFormatted,
                label: "Distance",
                color: Color.green
            )
            
            // Fréquence cardiaque
            SessionStatCard(
                icon: "heart.fill",
                value: heartRateFormatted,
                label: "BPM",
                color: Color.red
            )
            
            // Calories
            SessionStatCard(
                icon: "flame.fill",
                value: caloriesFormatted,
                label: "Calories",
                color: Color.orange
            )
        }
    }
    
    // MARK: - Computed Properties
    
    /// Temps écoulé depuis le début de la session, formaté (HH:MM:SS ou MM:SS)
    private var timeElapsedFormatted: String {
        let elapsed = currentTime.timeIntervalSince(session.startedAt)
        return SessionStatsFormatters.formatTimeElapsed(elapsed)
    }
    
    /// Distance formatée : "X m" si < 1km, sinon "X.XX km"
    private var distanceFormatted: String {
        SessionStatsFormatters.formatDistance(routeDistance)
    }
    
    /// Fréquence cardiaque formatée, "--" si non disponible
    private var heartRateFormatted: String {
        SessionStatsFormatters.formatHeartRate(currentHeartRate)
    }
    
    /// Calories formatées, "--" si non disponible
    private var caloriesFormatted: String {
        SessionStatsFormatters.formatCalories(currentCalories)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Widget complet avec données
            SessionStatsWidget(
                session: SessionModel(
                    squadId: "squad1",
                    creatorId: "user1",
                    startedAt: Date().addingTimeInterval(-1245), // 20min45s ago
                    status: .active,
                    participants: ["user1", "user2"]
                ),
                currentHeartRate: 145,
                currentCalories: 187,
                routeDistance: 2340
            )
            .padding()
            
            // Badges compacts séparés
            HStack(spacing: 12) {
                HeartRateBadge(bpm: 145)
                CaloriesBadge(calories: 187)
            }
            .padding()
        }
    }
}
