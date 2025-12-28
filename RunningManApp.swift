import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("🔥 Firebase configuré avec succès dans l'AppDelegate")
        return true
    }
}

@main
struct RunningManApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            // Utiliser un wrapper qui crée les ViewModels APRÈS que Firebase soit configuré
            AppRootView()
                .preferredColorScheme(.dark)
        }
    }
}

/// Vue wrapper qui initialise les ViewModels de manière lazy
struct AppRootView: View {
    // Ces ViewModels sont créés UNIQUEMENT quand cette vue est affichée,
    // donc APRÈS que l'AppDelegate ait configuré Firebase
    @State private var appState = AppState()
    @State private var authViewModel = AuthViewModel()
    @State private var squadViewModel = SquadViewModel()
    
    var body: some View {
        RootView()
            .environment(appState)
            .environment(authViewModel)
            .environment(squadViewModel)
    }
}
