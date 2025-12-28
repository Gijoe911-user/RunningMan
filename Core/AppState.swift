//
//  AppState.swift
//  RunningMan
//
//  Gère l'état global de l'application (authentification, session active, navigation, etc.)
//

import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
@Observable
class AppState {
    // MARK: - Navigation State
    /// Onglet sélectionné dans le MainTabView (0: Accueil, 1: Squads, 2: Sessions, 3: Profil)
    var selectedTab: Int = 0
    
    // MARK: - Authentication State
    var isAuthenticated: Bool = false
    var currentUser: UserModel? = nil
    
    // MARK: - Session State
    var activeSession: SessionModel? = nil
    
    // MARK: - Initialization
    
    init() {
        // Ne pas accéder à Firebase dans l'init
        // On vérifiera l'état d'authentification de manière asynchrone après
        Task { @MainActor in
            await checkInitialAuthState()
        }
    }
    
    /// Vérifie l'état d'authentification initial de manière asynchrone
    private func checkInitialAuthState() async {
        // Maintenant Firebase est garanti d'être configuré
        if Auth.auth().currentUser != nil {
            self.isAuthenticated = true
            // TODO: Charger les données utilisateur depuis Firestore
        }
    }
    
    // MARK: - Actions
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
            self.currentUser = nil
            self.activeSession = nil
            self.selectedTab = 0 // Retour à l'accueil après déconnexion
        } catch {
            print("Erreur lors de la déconnexion: \(error.localizedDescription)")
        }
    }
    
    /// Navigue vers l'onglet Sessions (Course)
    func navigateToSessions() {
        selectedTab = 2
    }
    
    /// Navigue vers l'onglet Squads
    func navigateToSquads() {
        selectedTab = 1
    }
}
