//
//  SessionsViewModel.swift
//  RunningMan
//
//  ViewModel pour gérer la logique de la vue Sessions
//

import Foundation
import CoreLocation
import Combine

// MARK: - Supporting Types
struct MarathonProgress {
    let percentage: Double
    let daysRemaining: Int
}

@MainActor
class SessionsViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var activeSession: SessionModel?
    @Published var runnerLocations: [RunnerLocation] = []
    @Published var activeRunners: [RunnerLocation] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var unreadMessagesCount: Int = 0
    @Published var marathonProgress: MarathonProgress?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        
        // TODO: Phase 1 - Données de test
        loadMockData()
    }
    
    // MARK: - Location Management
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Note: allowsBackgroundLocationUpdates nécessite:
        // 1. UIBackgroundModes avec "location" dans Info.plist
        // 2. NSLocationAlwaysAndWhenInUseUsageDescription dans Info.plist
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startLocationUpdates() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func centerOnUserLocation() {
        locationManager.requestLocation()
    }
    
    func zoomIn() {
        // TODO: Implémenter zoom via Map region
    }
    
    func zoomOut() {
        // TODO: Implémenter zoom via Map region
    }
    
    // MARK: - Communication Actions
    func toggleMicrophone() {
        // TODO: Phase 2 - Implémenter Push-to-Talk
        print("Microphone toggled")
    }
    
    func takePhoto() {
        // TODO: Implémenter capture photo
        print("Take photo")
    }
    
    func openMessages() {
        // TODO: Navigation vers messages
        print("Open messages")
    }
    
    // MARK: - Mock Data (Phase 1)
    private func loadMockData() {
        // Session active mock
        activeSession = SessionModel(
            squadId: "squad1",
            creatorId: "user1",
            startedAt: Date(),
            status: .active,
            participants: ["user1", "user2", "user3", "user4"],
            totalDistanceMeters: 5420.0,
            durationSeconds: 1847.0,
            targetDistanceMeters: 10000.0,
            title: "Run Together",
            sessionType: .race
        )
        
        // Coureurs actifs mock
        activeRunners = [
            RunnerLocation(
                id: "user1",
                displayName: "Alice",
                latitude: 48.8566,
                longitude: 2.3522,
                timestamp: Date(),
                photoURL: nil
            ),
            RunnerLocation(
                id: "user2",
                displayName: "Bob",
                latitude: 48.8576,
                longitude: 2.3532,
                timestamp: Date(),
                photoURL: nil
            ),
            RunnerLocation(
                id: "user3",
                displayName: "Charlie",
                latitude: 48.8586,
                longitude: 2.3542,
                timestamp: Date(),
                photoURL: nil
            ),
            RunnerLocation(
                id: "user4",
                displayName: "Diana",
                latitude: 48.8596,
                longitude: 2.3552,
                timestamp: Date(),
                photoURL: nil
            )
        ]
        
        runnerLocations = activeRunners
        
        // Progression marathon mock
        marathonProgress = MarathonProgress(percentage: 0.67, daysRemaining: 8)
        
        // Messages non lus
        unreadMessagesCount = 3
    }
}

// MARK: - CLLocationManagerDelegate
extension SessionsViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            userLocation = location.coordinate
            // TODO: Envoyer la position à Firebase
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
