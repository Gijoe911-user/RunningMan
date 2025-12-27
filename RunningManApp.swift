//
//  RunningManApp.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 19/12/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Firebase est déjà configuré dans l'init de RunningManApp
    Logger.log("AppDelegate initialisé", category: .firebase)
    return true
  }
}

@main
struct RunningManApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authViewModel: AuthViewModel
    @State private var squadViewModel = SquadViewModel()
    
    // Initialise Firebase AVANT la création de authViewModel
    init() {
        // Configure Firebase en premier
        FirebaseApp.configure()
        Logger.log("Firebase configuré dans l'initializer de App", category: .firebase)
        
        // Maintenant on peut créer authViewModel en toute sécurité
        _authViewModel = State(initialValue: AuthViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel) // Injection moderne iOS 17+
                .environment(squadViewModel) // Injection SquadViewModel
                .preferredColorScheme(.dark)
        }
    }
}
