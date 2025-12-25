//
//  RootView.swift
//  RunningMan
//
//  Point d'entrée principal qui gère la navigation Auth vs Main
//

import SwiftUI

struct CoreRootView: View {
    @Environment(AuthViewModel.self) private var authVM
    
    var body: some View {
        content
            .animation(.easeInOut, value: authVM.isAuthenticated)
    }
    
    @ViewBuilder
    private var content: some View {
        if authVM.isAuthenticated {
            // TODO: Remplacer par le vrai MainTabView de votre projet
            // Si votre fichier s'appelle CoreNavigationMainTabView.swift,
            // alors la structure devrait s'appeler MainTabView aussi
            // Sinon, créez une vue temporaire ci-dessous
            PlaceholderMainView()
        } else {
            LoginView()
        }
    }
}

// Vue temporaire en attendant de connecter le vrai MainTabView
private struct PlaceholderMainView: View {
    @Environment(AuthViewModel.self) private var authVM
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                
                Text("Connexion réussie !")
                    .font(.largeTitle)
                    .bold()
                
                if let user = authVM.currentUser {
                    Text("Bienvenue, \(user.displayName) 👋")
                        .font(.title2)
                }
                
                Text("L'application principale se chargera ici")
                    .foregroundStyle(.secondary)
                
                Button {
                    authVM.signOut()
                } label: {
                    Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                        .padding()
                        .background(.red.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding(.top, 40)
            }
            .navigationTitle("RunningMan")
        }
    }
}
