//
//  HealthStatsBadges.swift
//  RunningMan
//
//  Badges compacts pour afficher les stats de santé (BPM, Calories)
//

import SwiftUI

// MARK: - Heart Rate Badge

/// Badge compact pour afficher la fréquence cardiaque
///
/// Affiche un badge arrondi avec :
/// - Icône de cœur animée (pulse si données disponibles)
/// - Valeur BPM ou "--" si indisponible
/// - Label "BPM"
///
/// **Animation :**
/// L'icône pulse uniquement quand des données sont disponibles
///
/// **Usage :**
/// ```swift
/// HeartRateBadge(bpm: viewModel.currentHeartRate)
/// ```
///
/// - Parameter bpm: Fréquence cardiaque en battements par minute, `nil` si non disponible
/// - SeeAlso: `HealthKitManager`, `SessionStatsWidget`
struct HeartRateBadge: View {
    
    // MARK: - Properties
    
    /// Fréquence cardiaque en BPM, `nil` si non disponible
    let bpm: Double?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 6) {
            // Icône de cœur avec animation pulse
            Image(systemName: "heart.fill")
                .font(.body)
                .foregroundColor(.red)
                .symbolEffect(.pulse, isActive: bpm != nil)
            
            // Valeur ou placeholder
            if let bpm = bpm {
                Text("\(Int(bpm))")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("BPM")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text("-- BPM")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}

// MARK: - Calories Badge

/// Badge compact pour afficher les calories brûlées
///
/// Affiche un badge arrondi avec :
/// - Icône de flamme orange
/// - Valeur en kcal ou "--" si indisponible
/// - Label "kcal"
///
/// **Usage :**
/// ```swift
/// CaloriesBadge(calories: viewModel.currentCalories)
/// ```
///
/// - Parameter calories: Calories brûlées, `nil` si non disponible
/// - SeeAlso: `HealthKitManager`, `SessionStatsWidget`
struct CaloriesBadge: View {
    
    // MARK: - Properties
    
    /// Calories brûlées, `nil` si non disponible
    let calories: Double?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 6) {
            // Icône de flamme
            Image(systemName: "flame.fill")
                .font(.body)
                .foregroundColor(.orange)
            
            // Valeur ou placeholder
            if let calories = calories {
                Text("\(Int(calories))")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Text("-- kcal")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Avec données
            HStack(spacing: 12) {
                HeartRateBadge(bpm: 145)
                CaloriesBadge(calories: 187)
            }
            
            // Sans données
            HStack(spacing: 12) {
                HeartRateBadge(bpm: nil)
                CaloriesBadge(calories: nil)
            }
        }
        .padding()
    }
}
