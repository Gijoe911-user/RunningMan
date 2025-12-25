//
//  MainTabView.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import SwiftUI

// Navigation principale avec TabView pour l'application
struct MainTabView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Onglet 1 : Dashboard
            DashboardView()
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }
                .tag(0)
            
            // Onglet 2 : Squads
            SquadListView()
                .tabItem {
                    Label("Squads", systemImage: "person.3.fill")
                }
                .tag(1)
            
            // Onglet 3 : Course
            RunTrackingView()
                .tabItem {
                    Label("Course", systemImage: "figure.run")
                }
                .tag(2)
            
            // Onglet 4 : Profil
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.coralAccent) // Couleur des icônes sélectionnées
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(AuthViewModel())
        .preferredColorScheme(.dark)
}
