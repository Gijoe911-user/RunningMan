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
            if authVM.isLoading || (authVM.isAuthenticated && !squadVM.hasAttemptedLoad) {
                // Écran de chargement initial OU chargement des squads
                loadingView
                    .transition(.opacity)
            } else if authVM.isAuthenticated {
                // Utilisateur connecté
                if squadVM.hasSquads {
                    // A déjà rejoint ou créé un squad
                    MainTabView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    // Première connexion ou pas encore de squad
                    OnboardingSquadView()
                        .transition(.scale.combined(with: .opacity))
                }
            } else {
                // Non authentifié - Afficher l'écran de connexion
                LoginView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isLoading)
        .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: squadVM.hasSquads)
        .task(id: authVM.isAuthenticated) {
            // Charger les squads automatiquement quand l'utilisateur se connecte
            if authVM.isAuthenticated {
                Logger.log("🔄 Chargement des squads après authentification", category: .ui)
                await squadVM.loadUserSquads()
                Logger.log("✅ Squads chargées: \(squadVM.userSquads.count), hasSquads: \(squadVM.hasSquads)", category: .ui)
            }
        }
        .onChange(of: authVM.isAuthenticated) { oldValue, newValue in
            Logger.log("🔄 isAuthenticated changé: \(oldValue) -> \(newValue)", category: .ui)
        }
        .onChange(of: squadVM.hasAttemptedLoad) { oldValue, newValue in
            Logger.log("🔄 hasAttemptedLoad changé: \(oldValue) -> \(newValue)", category: .ui)
        }
        .onChange(of: squadVM.hasSquads) { oldValue, newValue in
            Logger.log("🔄 hasSquads changé: \(oldValue) -> \(newValue)", category: .ui)
        }
        .onChange(of: authVM.isLoading) { oldValue, newValue in
            Logger.log("🔄 isLoading changé: \(oldValue) -> \(newValue)", category: .ui)
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
        .environment(SquadViewModel())
}

#Preview("Non authentifié") {
    let authVM = AuthViewModel()
    RootView()
        .environment(authVM)
        .environment(SquadViewModel())
}
