//
//  SessionProgressBar.swift
//  RunningMan
//
//  Barre de progression pour afficher l'avancement vers un objectif
//

import SwiftUI

/// Barre de progression visuelle pour les objectifs de session
///
/// Affiche :
/// - Icône coureur animée qui avance
/// - Barre de progression
/// - Distance actuelle / objectif
///
/// **Design :**
/// - Compact et non intrusif
/// - Flotte au-dessus de la carte
/// - N'apparaît que si un objectif est défini
///
/// **Usage :**
/// ```swift
/// SessionProgressBar(
///     currentDistance: 2500,  // en mètres
///     targetDistance: 5000    // en mètres
/// )
/// ```
struct SessionProgressBar: View {
    
    // MARK: - Properties
    
    /// Distance actuelle parcourue en mètres
    let currentDistance: Double
    
    /// Distance objectif en mètres
    let targetDistance: Double
    
    // MARK: - Computed Properties
    
    /// Pourcentage de progression (0.0 à 1.0)
    private var progress: Double {
        guard targetDistance > 0 else { return 0 }
        return min(currentDistance / targetDistance, 1.0)
    }
    
    /// Texte de progression formaté
    private var progressText: String {
        let current = SessionStatsFormatters.formatDistance(currentDistance)
        let target = SessionStatsFormatters.formatDistance(targetDistance)
        return "\(current) / \(target)"
    }
    
    /// Couleur dynamique selon la progression
    private var progressColor: Color {
        switch progress {
        case 0..<0.5:
            return .coralAccent
        case 0.5..<0.8:
            return .orange
        case 0.8..<1.0:
            return .green
        default:
            return .pinkAccent // Objectif atteint !
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Barre de progression
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                
                // Barre de progression
                GeometryReader { geometry in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                    
                    // Icône coureur qui avance
                    Image(systemName: "figure.run")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(progressColor)
                        .clipShape(Circle())
                        .shadow(color: progressColor.opacity(0.5), radius: 4)
                        .offset(x: max(0, geometry.size.width * progress - 10))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
                .frame(height: 8)
                
                // Drapeau d'arrivée à la fin
                HStack {
                    Spacer()
                    Image(systemName: "flag.checkered")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .frame(height: 20)
            
            // Texte de progression
            Text(progressText)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Début de course
            SessionProgressBar(
                currentDistance: 500,
                targetDistance: 5000
            )
            
            // Mi-parcours
            SessionProgressBar(
                currentDistance: 2500,
                targetDistance: 5000
            )
            
            // Presque fini
            SessionProgressBar(
                currentDistance: 4200,
                targetDistance: 5000
            )
            
            // Objectif atteint
            SessionProgressBar(
                currentDistance: 5000,
                targetDistance: 5000
            )
        }
        .padding()
    }
}
