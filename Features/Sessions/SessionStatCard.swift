//
//  SessionStatCard.swift
//  RunningMan
//
//  Carte individuelle pour afficher une métrique de session
//

import SwiftUI

/// Carte individuelle pour afficher une métrique unique de session
///
/// Composant réutilisable qui affiche :
/// - Une icône SF Symbol colorée
/// - Une valeur en grand format (titre)
/// - Un label descriptif
///
/// **Design :**
/// - Fond semi-transparent
/// - Coins arrondis
/// - Icône colorée en haut
/// - Valeur en gras au centre
/// - Label descriptif en bas
///
/// **Usage :**
/// ```swift
/// SessionStatCard(
///     icon: "clock.fill",
///     value: "20:45",
///     label: "Temps",
///     color: .blue
/// )
/// ```
///
/// - SeeAlso: `SessionStatsWidget`
struct SessionStatCard: View {
    
    // MARK: - Properties
    
    /// Nom de l'icône SF Symbol à afficher
    let icon: String
    
    /// Valeur formatée à afficher (ex: "2.34 km", "145 BPM")
    let value: String
    
    /// Label descriptif (ex: "Distance", "BPM", "Temps")
    let label: String
    
    /// Couleur de l'icône
    let color: Color
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Icône
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            // Valeur
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        HStack(spacing: 12) {
            SessionStatCard(
                icon: "clock.fill",
                value: "20:45",
                label: "Temps",
                color: .blue
            )
            
            SessionStatCard(
                icon: "location.fill",
                value: "2.34 km",
                label: "Distance",
                color: .green
            )
        }
        .padding()
    }
}
