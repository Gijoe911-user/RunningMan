//
//  RouteHistoryService.swift
//  RunningMan
//
//  Service pour gérer l'historique des parcours GPS
//

import Foundation
import FirebaseFirestore
import CoreLocation

/// Service de gestion de l'historique des parcours
class RouteHistoryService {
    
    static let shared = RouteHistoryService()
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private init() {
        Logger.log("RouteHistoryService initialisé", category: .location)
    }
    
    // MARK: - Save Route Point (ancienne structure)
    
    /// Enregistre un point GPS dans l'historique du parcours (ancienne structure)
    func saveRoutePoint(
        sessionId: String,
        userId: String,
        location: CLLocation
    ) async throws {
        
        let point = RoutePoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            speed: max(0, location.speed),
            horizontalAccuracy: location.horizontalAccuracy,
            timestamp: location.timestamp
        )
        
        let pointRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
            .collection("points")
            .document("\(Int(location.timestamp.timeIntervalSince1970))")
        
        try pointRef.setData(from: point)
    }
    
    // MARK: - Load Route Points
    
    /// Charge tous les points GPS d'un parcours
    func loadRoutePoints(
        sessionId: String,
        userId: String
    ) async throws -> [RoutePoint] {
        
        // 1) Structure moderne /routes/{sessionId_userId}
        let modernRouteRef = db.collection("routes")
            .document("\(sessionId)_\(userId)")
        
        let modernDoc = try await modernRouteRef.getDocument()
        
        if modernDoc.exists, let data = modernDoc.data() {
            let geoPoints = data["points"] as? [GeoPoint]
            let timestamps = data["pointsTimestamps"] as? [Timestamp]
            let version = (data["version"] as? Int) ?? 1
            
            if let geoPoints, let timestamps, timestamps.count == geoPoints.count {
                // Lecture moderne fiable avec timestamps
                var points: [RoutePoint] = []
                points.reserveCapacity(geoPoints.count)
                for i in 0..<geoPoints.count {
                    let gp = geoPoints[i]
                    let ts = timestamps[i].dateValue()
                    points.append(RoutePoint(
                        latitude: gp.latitude,
                        longitude: gp.longitude,
                        altitude: 0,
                        speed: 0,
                        horizontalAccuracy: 0,
                        timestamp: ts
                    ))
                }
                
                // Filtrer doublons consécutifs
                let filtered = filterConsecutiveDuplicates(points: points)
                Logger.log("Points GPS chargés (moderne v\(version) + timestamps): \(filtered.count)", category: .location)
                return filtered
            } else if geoPoints != nil {
                // Doc moderne présent mais incomplet => fallback
                Logger.log("⚠️ Doc routes moderne incomplet (pas de pointsTimestamps) → fallback ancien", category: .location)
            }
        }
        
        // 2) Fallback: Ancienne structure /sessions/{sessionId}/routes/{userId}/points
        let pointsRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
            .collection("points")
            .order(by: "timestamp", descending: false)
        
        let snapshot = try await pointsRef.getDocuments()
        
        var points = snapshot.documents.compactMap { doc -> RoutePoint? in
            try? doc.data(as: RoutePoint.self)
        }
        
        points = filterConsecutiveDuplicates(points: points)
        
        Logger.log("Points GPS chargés (ancienne): \(points.count)", category: .location)
        return points
    }
    
    // MARK: - Create/Update User Route (ancienne structure)
    
    func updateUserRoute(
        sessionId: String,
        userId: String,
        distance: Double,
        duration: TimeInterval,
        averageSpeed: Double,
        maxSpeed: Double,
        pointsCount: Int
    ) async throws {
        
        let routeRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
        
        let routeDoc = try await routeRef.getDocument()
        
        if routeDoc.exists {
            try await routeRef.updateData([
                "totalDistance": distance,
                "duration": duration,
                "averageSpeed": averageSpeed,
                "maxSpeed": maxSpeed,
                "pointsCount": pointsCount,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } else {
            let route = UserRoute(
                sessionId: sessionId,
                userId: userId,
                startedAt: Date(),
                totalDistance: distance,
                duration: duration,
                pointsCount: pointsCount,
                averageSpeed: averageSpeed,
                maxSpeed: maxSpeed
            )
            
            try routeRef.setData(from: route)
        }
        
        Logger.log("Parcours mis à jour: \(distance)m, \(pointsCount) points", category: .location)
    }
    
    // MARK: - End User Route (ancienne structure)
    
    func endUserRoute(sessionId: String, userId: String) async throws {
        let routeRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
        
        try await routeRef.updateData([
            "endedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        Logger.logSuccess("Parcours terminé", category: .location)
    }
    
    // MARK: - Get User Route (ancienne structure)
    
    func getUserRoute(
        sessionId: String,
        userId: String
    ) async throws -> UserRoute? {
        
        let routeRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
        
        let doc = try await routeRef.getDocument()
        
        guard doc.exists else { return nil }
        
        return try doc.data(as: UserRoute.self)
    }
    
    // MARK: - Get All Routes for Session (ancienne structure)
    
    func getAllRoutesForSession(sessionId: String) async throws -> [UserRoute] {
        let routesRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
        
        let snapshot = try await routesRef.getDocuments()
        
        let routes = snapshot.documents.compactMap { doc -> UserRoute? in
            try? doc.data(as: UserRoute.self)
        }
        
        return routes
    }
    
    // MARK: - Get User's All Routes (non implémenté)
    
    func getAllRoutesForUser(userId: String) async throws -> [UserRoute] {
        Logger.log("⚠️ getAllRoutesForUser() nécessite une implémentation complète", category: .location)
        return []
    }
    
    // MARK: - Calculate Route Statistics
    
    func calculateRouteStatistics(points: [RoutePoint]) -> (distance: Double, duration: TimeInterval, avgSpeed: Double, maxSpeed: Double) {
        guard points.count > 1 else {
            return (0, 0, 0, 0)
        }
        
        var totalDistance: Double = 0
        var maxSpeed: Double = 0
        var speedSum: Double = 0
        var validSpeedCount: Int = 0
        
        for i in 1..<points.count {
            let previousPoint = points[i-1]
            let currentPoint = points[i]
            
            let previousLocation = previousPoint.location
            let currentLocation = currentPoint.location
            
            let distance = currentLocation.distance(from: previousLocation)
            
            // Filtrer les distances aberrantes (> 100m entre deux points)
            if distance < 100 {
                totalDistance += distance
            }
            
            if let speed = currentPoint.speed, speed >= 0 {
                speedSum += speed
                validSpeedCount += 1
                if speed > maxSpeed { maxSpeed = speed }
            }
        }
        
        let duration = points.last!.timestamp.timeIntervalSince(points.first!.timestamp)
        let avgSpeed = validSpeedCount > 0 ? speedSum / Double(validSpeedCount) : 0
        
        return (totalDistance, duration, avgSpeed, maxSpeed)
    }
    
    // MARK: - Stream Route Points (ancienne structure)
    
    func streamRoutePoints(
        sessionId: String,
        userId: String
    ) -> AsyncStream<[RoutePoint]> {
        
        AsyncStream { continuation in
            let pointsRef = db.collection("sessions")
                .document(sessionId)
                .collection("routes")
                .document(userId)
                .collection("points")
                .order(by: "timestamp", descending: false)
            
            let listener = pointsRef.addSnapshotListener { snapshot, error in
                if let error = error {
                    Logger.logError(error, context: "streamRoutePoints", category: .location)
                    continuation.yield([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    continuation.yield([])
                    return
                }
                
                var points = documents.compactMap { doc -> RoutePoint? in
                    try? doc.data(as: RoutePoint.self)
                }
                points = self.filterConsecutiveDuplicates(points: points)
                
                continuation.yield(points)
            }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    // MARK: - Delete Route (ancienne structure)
    
    func deleteRoute(sessionId: String, userId: String) async throws {
        let routeRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
        
        // Supprimer tous les points
        let pointsRef = routeRef.collection("points")
        let snapshot = try await pointsRef.getDocuments()
        
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        batch.deleteDocument(routeRef)
        
        try await batch.commit()
        
        Logger.logSuccess("Parcours supprimé", category: .location)
    }
    
    // MARK: - Helpers
    
    /// Filtre les doublons consécutifs exacts (même lat/lon)
    private func filterConsecutiveDuplicates(points: [RoutePoint]) -> [RoutePoint] {
        guard !points.isEmpty else { return [] }
        var filtered: [RoutePoint] = []
        filtered.reserveCapacity(points.count)
        
        var lastLat: Double?
        var lastLon: Double?
        
        for p in points {
            if let ll = lastLat, let lo = lastLon, abs(p.latitude - ll) < .ulpOfOne, abs(p.longitude - lo) < .ulpOfOne {
                continue
            }
            filtered.append(p)
            lastLat = p.latitude
            lastLon = p.longitude
        }
        return filtered
    }
}

