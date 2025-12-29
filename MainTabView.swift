//
//  MainTabView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

// Navigation principale avec TabView pour l'application
struct MainTabView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        // ✅ @Bindable permet de créer un binding depuis un @Observable
        @Bindable var appState = appState
        
        ZStack {
            TabView(selection: $appState.selectedTab) {
                // Onglet 0 : Dashboard
                DashboardView()
                    .tabItem {
                        Label("Accueil", systemImage: "house.fill")
                    }
                    .tag(0)
                
                // Onglet 1 : Squads
                SquadListView()
                    .tabItem {
                        Label("Squads", systemImage: "person.3.fill")
                    }
                    .tag(1)
                
                // Onglet 2 : Sessions (Liste complète) ← Vue corrigée !
                AllSessionsView()
                    .tabItem {
                        Label("Sessions", systemImage: "list.bullet.rectangle.fill")
                    }
                    .tag(2)
                
                // Onglet 3 : Profil
                ProfileView()
                    .tabItem {
                        Label("Profil", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            .tint(.coralAccent) // Couleur des icônes sélectionnées
            
            // ✅ Bouton d'urgence (DEBUG uniquement)
            // TODO: Décommenter quand EmergencyCleanupButton.swift sera ajouté au projet
            /*
            #if DEBUG
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    EmergencyCleanupButton()
                        .padding()
                        .padding(.bottom, 60) // Au-dessus de la TabBar
                }
            }
            #endif
            */
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}
