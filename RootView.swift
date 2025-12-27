//
//  RootView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

/// Vue racine qui gère la navigation entre l'authentification et l'application principale
struct RootView: View {
    
    @Environment(AuthViewModel.self) private var authVM
    @Environment(SquadViewModel.self) private var squadVM
    
    var body: some View {
        Group {
            if authVM.isLoading {
                // Écran de chargement initial
                loadingView
            } else if authVM.isAuthenticated {
                // Utilisateur connecté
                if authVM.hasSquad {
                    // A déjà rejoint ou créé un squad
                    MainTabView()
                } else {
                    // Première connexion ou pas encore de squad
                    OnboardingSquadView()
                }
            } else {
                // Non authentifié - Afficher l'écran de connexion
                LoginView()
            }
        }
        .task(id: authVM.isAuthenticated) {
            // Charger les squads automatiquement quand l'utilisateur se connecte
            if authVM.isAuthenticated {
                await squadVM.loadUserSquads()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        ZStack {
            Color.darkNavy
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "figure.run")
                    .font(.system(size: 80))
                    .foregroundColor(.coralAccent)
                    .symbolEffect(.pulse)
                
                Text("RunningMan")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                ProgressView()
                    .tint(.coralAccent)
            }
        }
    }
}

// MARK: - Placeholders supprimés
// OnboardingSquadView est défini dans OnboardingSquadView.swift

// MARK: - Preview

#Preview("Chargement") {
    RootView()
        .environment(AuthViewModel())
}

#Preview("Non authentifié") {
    let authVM = AuthViewModel()
    RootView()
        .environment(authVM)
}
