//
//  CoreMainTabView.swift
//  RunningMan
//
//  Navigation principale de l'application
//

import SwiftUI

struct CoreNavigationMainTabView: View {
    // ✅ Migration vers @Environment (syntaxe iOS 17+)
    @Environment(AppState.self) private var appState
    
    enum Tab {
        case sessions
        case squads
        case profile
    }
    
    var body: some View {
        // ✅ @Bindable permet de créer un binding depuis @Observable
        @Bindable var appState = appState
        
        NavigationStack {
            TabView(selection: $appState.selectedTab) {
                // Onglet Sessions (Vue principale avec la carte)
                SessionsListView()
                    .tabItem {
                        Label("Sessions", systemImage: "figure.run")
                    }
                    .tag(2) // ✅ Utilisez les mêmes tags que MainTabView
                
                // Onglet Squads
                SquadListView()
                    .tabItem {
                        Label("Squads", systemImage: "person.3.fill")
                    }
                    .tag(1)
                
                // Onglet Profil
                ProfileView()
                    .tabItem {
                        Label("Profil", systemImage: "person.circle.fill")
                    }
                    .tag(3)
            }
            .tint(Color("CoralAccent"))
        }
    }
}
