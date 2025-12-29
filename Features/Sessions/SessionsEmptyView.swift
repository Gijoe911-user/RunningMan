//
//  SessionsEmptyView.swift
//  RunningMan
//
//  Vue affichée quand aucun squad n'est sélectionné
//

import SwiftUI

/// Vue affichée quand aucun squad n'est sélectionné
///
/// Affiche un écran vide élégant avec :
/// - Icône animée
/// - Message expliquant qu'il faut sélectionner un squad
/// - Bouton pour créer une session (si squad sélectionné)
///
/// **Usage :**
/// ```swift
/// if squadsVM.selectedSquad == nil {
///     SessionsEmptyView()
/// }
/// ```
struct SessionsEmptyView: View {
    
    // MARK: - Environment
    
    @Environment(SquadViewModel.self) private var squadVM
    
    // MARK: - State
    
    @State private var showCreateSession = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Icon animé
                animatedIcon
                
                // Message
                message
                
                // Bouton (si squad sélectionné)
                if let squad = squadVM.selectedSquad {
                    createSessionButton(squad: squad)
                } else {
                    noSquadMessage
                }
            }
        }
        .sheet(isPresented: $showCreateSession) {
            if let squad = squadVM.selectedSquad {
                CreateSessionView(squad: squad)
            }
        }
    }
    
    // MARK: - View Components
    
    /// Icône animée avec dégradé
    private var animatedIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.coralAccent.opacity(0.3), Color.coralAccent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
            
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.coralAccent)
                .symbolEffect(.pulse)
        }
    }
    
    /// Message principal
    private var message: some View {
        VStack(spacing: 12) {
            Text("Aucune session active")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Créez une session pour commencer à courir avec votre squad")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    /// Bouton pour créer une session
    private func createSessionButton(squad: SquadModel) -> some View {
        Button {
            showCreateSession = true
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                Text("Démarrer une session")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
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
    
    /// Message quand aucun squad n'est sélectionné
    private var noSquadMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellowAccent)
            Text("Sélectionnez un squad d'abord")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Preview

#Preview {
    SessionsEmptyView()
        .environment(SquadViewModel())
}
