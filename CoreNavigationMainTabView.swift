//
//  CoreNavigationMainTabView.swift
//  RunningMan
//
//  Navigation principale de l'application
//

import SwiftUI

struct CoreNavigationMainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .sessions
    
    enum Tab {
        case sessions
        case squads
        case profile
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Onglet Sessions (Vue principale avec la carte)
                SessionsListView()
                    .tabItem {
                        Label("Sessions", systemImage: "figure.run")
                    }
                    .tag(Tab.sessions)
                
                // Onglet Squads
                SquadsListView()
                    .tabItem {
                        Label("Squads", systemImage: "person.3.fill")
                    }
                    .tag(Tab.squads)
                
                // Onglet Profil
                ProfileView()
                    .tabItem {
                        Label("Profil", systemImage: "person.circle.fill")
                    }
                    .tag(Tab.profile)
            }
            .tint(Color("CoralAccent"))
        }
    }
}
