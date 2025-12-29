//
//  NoSessionOverlay.swift
//  RunningMan
//
//  Overlay affiché quand aucune session n'est active
//

import SwiftUI

/// Overlay affiché quand aucune session n'est active
///
/// Affiche :
/// - Icône illustrative
/// - Message explicatif
/// - Bouton pour créer une session
///
/// **Position :** Centre de l'écran, au-dessus de la carte
///
/// **Usage :**
/// ```swift
/// NoSessionOverlay(onCreateSession: { showCreateSession = true })
/// ```
struct NoSessionOverlay: View {
    
    // MARK: - Properties
    
    /// Callback appelé quand l'utilisateur clique sur "Créer une session"
    let onCreateSession: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                // Icône
                icon
                
                // Message
                message
                
                // Bouton
                createButton
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding()
            
            Spacer()
        }
    }
    
    // MARK: - View Components
    
    /// Icône illustrative avec dégradé
    private var icon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.coralAccent.opacity(0.3), Color.pinkAccent.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
            
            Image(systemName: "figure.run.circle")
                .font(.system(size: 40))
                .foregroundColor(.coralAccent)
        }
    }
    
    /// Message explicatif
    private var message: some View {
        VStack(spacing: 8) {
            Text("Aucune session active")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            Text("Créez une session pour commencer à courir avec votre squad")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    /// Bouton pour créer une session
    private var createButton: some View {
        Button(action: onCreateSession) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Créer une session")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
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
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.darkNavy
            .ignoresSafeArea()
        
        NoSessionOverlay(onCreateSession: {
            print("Créer une session")
        })
    }
}
