//
//  AppState.swift
//  RunningMan
//
//  Gère l'état global de l'application (authentification, session active, etc.)
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserModel? = nil
    @Published var activeSession: SessionModel? = nil
    
    init() {
        // Vérifier si un utilisateur est déjà connecté
        if Auth.auth().currentUser != nil {
            self.isAuthenticated = true
            // TODO: Charger les données utilisateur depuis Firestore
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
            self.currentUser = nil
            self.activeSession = nil
        } catch {
            print("Erreur lors de la déconnexion: \(error.localizedDescription)")
        }
    }
}
