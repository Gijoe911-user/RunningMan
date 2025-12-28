//
//  ActiveSessionMapContainerView.swift
//  RunningMan
//
//  Exemple d'intégration complète de la carte améliorée avec overlay participants
//

import SwiftUI
import MapKit
import CoreLocation

struct ActiveSessionMapContainerView: View {
    let sessionId: String
    
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var runnerLocations: [RunnerLocation] = []
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var runnerRoutes: [String: [CLLocationCoordinate2D]] = [:]
    
    // Pour contrôler la carte depuis l'extérieur
    @State private var selectedRunnerId: String?
    @State private var mapTrigger: Int = 0
    
    var body: some View {
        ZStack {
            // Carte principale
            EnhancedSessionMapView(
                userLocation: userLocation,
                runnerLocations: runnerLocations,
                routeCoordinates: routeCoordinates,
                runnerRoutes: runnerRoutes,
                onRecenter: {
                    print("✅ Recentré sur l'utilisateur")
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                },
                onSaveRoute: {
                    saveRouteToGallery()
                }
            )
            .id(mapTrigger) // Permet de forcer le re-render si nécessaire
            
            // Overlay des participants (en bas)
            VStack {
                Spacer()
                
                SessionParticipantsOverlay(
                    participants: runnerLocations,
                    userLocation: userLocation,
                    onRunnerTap: { runnerId in
                        centerMapOnRunner(runnerId: runnerId)
                    }
                )
                .padding(Edge.Set.bottom, 100) // Au-dessus de la tab bar
            }
        }
        .onAppear {
            setupLocationUpdates()
            listenToSessionData()
        }
    }
    
    // MARK: - Location Updates
    
    private func setupLocationUpdates() {
        // Démarrer les mises à jour de localisation
        LocationProvider.shared.startUpdating()
        
        // Observer les changements de position
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            updateMyLocation()
        }
    }
    
    private func updateMyLocation() {
        guard let newLocation = LocationProvider.shared.currentCoordinate else { return }
        
        // Mettre à jour la position locale
        userLocation = newLocation
        
        // Ajouter au tracé
        routeCoordinates.append(newLocation)
        
        // Sauvegarder dans Firestore
        Task {
            await saveMyLocationToFirestore(location: newLocation)
        }
    }
    
    // MARK: - Firestore Listeners
    
    private func listenToSessionData() {
        // 1. Écouter les positions des autres coureurs
        listenToRunnerLocations()
        
        // 2. Écouter les tracés de tous les coureurs
        listenToAllRunnerRoutes()
    }
    
    private func listenToRunnerLocations() {
        // Exemple de listener Firestore pour les positions en temps réel
        Task {
            // TODO: Implémenter avec votre SessionService
            // let locations = try await SessionService.shared.listenToRunnerLocations(sessionId: sessionId)
            // runnerLocations = locations
            
            // Pour l'exemple, simulons des données
            runnerLocations = [
                RunnerLocation(
                    id: "user1",
                    displayName: "Jean Martin",
                    latitude: 48.8576,
                    longitude: 2.3532,
                    timestamp: Date(),
                    photoURL: nil
                ),
                RunnerLocation(
                    id: "user2",
                    displayName: "Marie Dubois",
                    latitude: 48.8556,
                    longitude: 2.3512,
                    timestamp: Date(),
                    photoURL: nil
                )
            ]
        }
    }
    
    private func listenToAllRunnerRoutes() {
        // Écouter les tracés de tous les participants
        Task {
            // TODO: Implémenter avec Firestore
            // Exemple de structure :
            /*
            db.collection("sessions")
                .document(sessionId)
                .collection("runnerRoutes")
                .addSnapshotListener { snapshot, error in
                    // Parser et mettre à jour runnerRoutes
                }
            */
            
            // Pour l'exemple, simulons des tracés
            runnerRoutes = [
                "user1": [
                    CLLocationCoordinate2D(latitude: 48.8576, longitude: 2.3532),
                    CLLocationCoordinate2D(latitude: 48.8581, longitude: 2.3537),
                    CLLocationCoordinate2D(latitude: 48.8586, longitude: 2.3542)
                ],
                "user2": [
                    CLLocationCoordinate2D(latitude: 48.8556, longitude: 2.3512),
                    CLLocationCoordinate2D(latitude: 48.8551, longitude: 2.3507),
                    CLLocationCoordinate2D(latitude: 48.8546, longitude: 2.3502)
                ]
            ]
        }
    }
    
    // MARK: - Actions
    
    private func centerMapOnRunner(runnerId: String) {
        print("🎯 Centrage de la carte sur le coureur: \(runnerId)")
        
        // Trouver le coureur
        guard let runner = runnerLocations.first(where: { $0.id == runnerId }) else {
            print("❌ Coureur non trouvé")
            return
        }
        
        // Option 1: Utiliser une référence directe (nécessite @State ou @Binding)
        // mapView.centerOnRunner(runnerId: runnerId)
        
        // Option 2: Mettre à jour la position via un binding partagé
        selectedRunnerId = runnerId
        mapTrigger += 1
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        print("✅ Carte centrée sur \(runner.displayName)")
    }
    
    private func saveRouteToGallery() {
        print("💾 Sauvegarde du tracé...")
        
        guard !routeCoordinates.isEmpty else {
            print("❌ Aucun tracé à sauvegarder")
            return
        }
        
        Task {
            // Calculer les statistiques
            let distance = calculateTotalDistance()
            
            // Sauvegarder dans Firestore ou localement
            // try await RouteService.shared.saveRoute(...)
            
            print("✅ Tracé sauvegardé : \(distance/1000) km, \(routeCoordinates.count) points")
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func saveMyLocationToFirestore(location: CLLocationCoordinate2D) async {
        // TODO: Implémenter avec votre SessionService
        /*
        do {
            try await SessionService.shared.updateMyLocation(
                sessionId: sessionId,
                location: location
            )
        } catch {
            print("❌ Erreur lors de la mise à jour de la position: \(error)")
        }
        */
    }
    
    // MARK: - Helpers
    
    private func calculateTotalDistance() -> Double {
        guard routeCoordinates.count >= 2 else { return 0 }
        
        var total: Double = 0
        for i in 1..<routeCoordinates.count {
            let loc1 = CLLocation(
                latitude: routeCoordinates[i-1].latitude,
                longitude: routeCoordinates[i-1].longitude
            )
            let loc2 = CLLocation(
                latitude: routeCoordinates[i].latitude,
                longitude: routeCoordinates[i].longitude
            )
            total += loc1.distance(from: loc2)
        }
        return total
    }
}

// MARK: - Preview

#Preview {
    ActiveSessionMapContainerView(sessionId: "session123")
        .preferredColorScheme(.dark)
}
