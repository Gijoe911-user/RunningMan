//
//  RealtimeLocationRepository.swift
//  RunningMan
//
//  Accès Firestore pour publier et observer les positions en temps réel
//

import Foundation
import FirebaseFirestore
import CoreLocation

protocol RealtimeLocationRepositoryProtocol {
    func publishLocation(sessionId: String, userId: String, coordinate: CLLocationCoordinate2D) async throws
    func observeRunnerLocations(sessionId: String) -> AsyncStream<[RunnerLocation]>
}

final class RealtimeLocationRepository: RealtimeLocationRepositoryProtocol {
    
    private let db = Firestore.firestore()
    
    // Structure Firestore:
    // sessions/{sessionId}/locations/{userId}
    // {
    //   userId: String,
    //   latitude: Double,
    //   longitude: Double,
    //   timestamp: Timestamp,
    //   displayName: String? (optionnel),
    //   photoURL: String? (optionnel)
    // }
    
    func publishLocation(sessionId: String, userId: String, coordinate: CLLocationCoordinate2D) async throws {
        let docRef = db.collection("sessions").document(sessionId)
            .collection("locations").document(userId)
        
        // Récupérer le nom de l'utilisateur
        let displayName = try await getUserDisplayName(userId: userId)
        let photoURL = try? await getUserPhotoURL(userId: userId)
        
        var payload: [String: Any] = [
            "userId": userId,
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "timestamp": Timestamp(date: Date()),
            "displayName": displayName
        ]
        
        // Ajouter photoURL si disponible
        if let photoURL = photoURL {
            payload["photoURL"] = photoURL
        }
        
        try await docRef.setData(payload, merge: true)
    }
    
    // MARK: - Helpers
    
    private func getUserDisplayName(userId: String) async throws -> String {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        if let data = userDoc.data(),
           let displayName = data["displayName"] as? String {
            return displayName
        }
        
        return "Coureur" // Fallback
    }
    
    private func getUserPhotoURL(userId: String) async throws -> String? {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        if let data = userDoc.data(),
           let photoURL = data["photoURL"] as? String {
            return photoURL
        }
        
        return nil
    }
    
    func observeRunnerLocations(sessionId: String) -> AsyncStream<[RunnerLocation]> {
        AsyncStream { continuation in
            let collectionRef = db.collection("sessions").document(sessionId)
                .collection("locations")
            
            let listener = collectionRef.addSnapshotListener { snapshot, error in
                if let error = error {
                    Logger.logError(error, context: "observeRunnerLocations", category: .session)
                    continuation.yield([])
                    return
                }
                
                guard let snapshot = snapshot else {
                    continuation.yield([])
                    return
                }
                
                var runners: [RunnerLocation] = []
                
                for doc in snapshot.documents {
                    let data = doc.data()
                    guard
                        let userId = data["userId"] as? String,
                        let lat = data["latitude"] as? Double,
                        let lon = data["longitude"] as? Double,
                        let ts = data["timestamp"] as? Timestamp
                    else { continue }
                    
                    let displayName = data["displayName"] as? String
                    let photoURL = data["photoURL"] as? String
                    
                    let runner = RunnerLocation(
                        id: userId,
                        displayName: displayName ?? "Runner",
                        latitude: lat,
                        longitude: lon,
                        timestamp: ts.dateValue(),
                        photoURL: photoURL
                    )
                    runners.append(runner)
                }
                
                continuation.yield(runners)
            }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}

