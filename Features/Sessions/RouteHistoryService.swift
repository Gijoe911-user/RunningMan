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
    
    // MARK: - Save Route Point
    
    /// Enregistre un point GPS dans l'historique du parcours
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
    ///   - location: Position GPS
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
        
        // Chemin: sessions/{sessionId}/routes/{userId}/points/{timestamp}
        let pointRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
            .collection("points")
            .document("\(Int(location.timestamp.timeIntervalSince1970))")
        
        try pointRef.setData(from: point)
        
        // Logger.log("Point GPS enregistré: \(point.latitude), \(point.longitude)", category: .location)
    }
    
    // MARK: - Load Route Points
    
    /// Charge tous les points GPS d'un parcours
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
    /// - Returns: Liste des points GPS ordonnés par timestamp
    func loadRoutePoints(
        sessionId: String,
        userId: String
    ) async throws -> [RoutePoint] {
        
        let pointsRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
            .collection("points")
            .order(by: "timestamp", descending: false)
        
        let snapshot = try await pointsRef.getDocuments()
        
        let points = snapshot.documents.compactMap { doc -> RoutePoint? in
            try? doc.data(as: RoutePoint.self)
        }
        
        Logger.log("Points GPS chargés: \(points.count)", category: .location)
        
        return points
    }
    
    // MARK: - Create/Update User Route
    
    /// Crée ou met à jour le parcours d'un utilisateur
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
    ///   - distance: Distance parcourue (m)
    ///   - duration: Durée (s)
    ///   - averageSpeed: Vitesse moyenne (m/s)
    ///   - maxSpeed: Vitesse max (m/s)
    ///   - pointsCount: Nombre de points
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
        
        // Vérifier si le document existe déjà
        let routeDoc = try await routeRef.getDocument()
        
        if routeDoc.exists {
            // Mettre à jour
            try await routeRef.updateData([
                "totalDistance": distance,
                "duration": duration,
                "averageSpeed": averageSpeed,
                "maxSpeed": maxSpeed,
                "pointsCount": pointsCount,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } else {
            // Créer
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
    
    // MARK: - End User Route
    
    /// Termine le parcours d'un utilisateur
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
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
    
    // MARK: - Get User Route
    
    /// Récupère le parcours d'un utilisateur
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
    /// - Returns: Parcours de l'utilisateur
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
    
    // MARK: - Get All Routes for Session
    
    /// Récupère tous les parcours d'une session
    /// - Parameter sessionId: ID de la session
    /// - Returns: Liste des parcours
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
    
    // MARK: - Get User's All Routes
    
    /// Récupère tous les parcours d'un utilisateur (toutes sessions)
    /// - Parameter userId: ID de l'utilisateur
    /// - Returns: Liste des parcours
    func getAllRoutesForUser(userId: String) async throws -> [UserRoute] {
        // Note: Cette requête nécessite un index composite dans Firestore
        // Pour l'instant, on charge session par session
        
        // Alternative: Créer une collection globale "routes" avec userId comme champ
        // routes/{routeId} { sessionId, userId, ... }
        
        // Pour simplifier, retournons un tableau vide pour l'instant
        // L'implémentation complète nécessiterait une restructuration
        
        Logger.log("⚠️ getAllRoutesForUser() nécessite une implémentation complète", category: .location)
        return []
    }
    
    // MARK: - Calculate Route Statistics
    
    /// Calcule les statistiques d'un parcours à partir des points
    /// - Parameter points: Liste des points GPS
    /// - Returns: Statistiques calculées
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
            
            // Calculer la distance entre les deux points
            let previousLocation = previousPoint.location
            let currentLocation = currentPoint.location
            
            let distance = currentLocation.distance(from: previousLocation)
            
            // Filtrer les distances aberrantes (> 100m entre deux points)
            if distance < 100 {
                totalDistance += distance
            }
            
            // Vitesse
            if let speed = currentPoint.speed, speed >= 0 {
                speedSum += speed
                validSpeedCount += 1
                
                if speed > maxSpeed {
                    maxSpeed = speed
                }
            }
        }
        
        let duration = points.last!.timestamp.timeIntervalSince(points.first!.timestamp)
        let avgSpeed = validSpeedCount > 0 ? speedSum / Double(validSpeedCount) : 0
        
        return (totalDistance, duration, avgSpeed, maxSpeed)
    }
    
    // MARK: - Stream Route Points
    
    /// Observe les points GPS d'un parcours en temps réel
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
    /// - Returns: Stream de points GPS
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
                
                let points = documents.compactMap { doc -> RoutePoint? in
                    try? doc.data(as: RoutePoint.self)
                }
                
                continuation.yield(points)
            }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    // MARK: - Delete Route
    
    /// Supprime un parcours et tous ses points
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
    func deleteRoute(sessionId: String, userId: String) async throws {
        let routeRef = db.collection("sessions")
            .document(sessionId)
            .collection("routes")
            .document(userId)
        
        // Supprimer tous les points
        let pointsRef = routeRef.collection("points")
        let snapshot = try await pointsRef.getDocuments()
        
        // Batch delete
        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // Supprimer le document route lui-même
        batch.deleteDocument(routeRef)
        
        try await batch.commit()
        
        Logger.logSuccess("Parcours supprimé", category: .location)
    }
}
