//
//  SessionHistoryViewModel.swift
//  RunningMan
//
//  ViewModel pour charger et gérer les détails d'une session historique
//

import Foundation
import MapKit
import FirebaseFirestore
import Combine

/// ViewModel pour gérer les données d'une session historique
@MainActor
class SessionHistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var participantStats: [ParticipantStats] = []
    @Published var routePoints: [CLLocationCoordinate2D] = []
    @Published var userNames: [String: String] = [:]  // userId -> displayName
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    let session: SessionModel
    private let db = Firestore.firestore()
    private let routeHistoryService = RouteHistoryService.shared
    
    // MARK: - Computed Properties
    
    /// Participants classés par distance (podium)
    var rankedParticipants: [ParticipantStats] {
        participantStats.sorted { $0.distance > $1.distance }
    }
    
    /// Dénivelé positif calculé à partir des points GPS
    var elevationGain: Double? {
        // TODO: Calculer depuis les altitudes des points GPS si disponibles (non stockées actuellement)
        nil
    }
    
    // MARK: - Initialization
    
    init(session: SessionModel) {
        self.session = session
    }
    
    // MARK: - Load Data
    
    /// Charge toutes les données nécessaires pour afficher la session historique
    func loadSessionDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Charger en parallèle pour optimiser
            async let stats = loadParticipantStats()
            async let route = loadRoutePoints()
            async let users = loadUserNames()
            
            // Attendre la fin des 3 chargements
            try await (stats, route, users)
            
            Logger.logSuccess("✅ Détails de session chargés", category: .service)
        } catch {
            Logger.logError(error, context: "loadSessionDetails", category: .service)
            errorMessage = "Erreur lors du chargement des détails"
        }
        
        isLoading = false
    }
    
    // MARK: - Load Participant Stats
    
    /// Charge les statistiques de tous les participants
    private func loadParticipantStats() async throws {
        guard let sessionId = session.id else { return }
        
        Logger.log("📊 Chargement des stats participants pour session: \(sessionId)", category: .service)
        
        let statsCollection = db.collection("sessions")
            .document(sessionId)
            .collection("participantStats")
        
        let snapshot = try await statsCollection.getDocuments()
        
        participantStats = snapshot.documents.compactMap { doc in
            try? doc.data(as: ParticipantStats.self)
        }
        
        Logger.log("✅ \(participantStats.count) stats chargées", category: .service)
    }
    
    // MARK: - Load Route Points
    
    /// Charge les points GPS du parcours enregistré
    /// Utilise RouteHistoryService: sessions/{sessionId}/routes/{userId}/points
    private func loadRoutePoints() async throws {
        guard let sessionId = session.id else { return }
        
        // Choisir un participant de référence pour l'affichage du parcours:
        // 1) créateur si présent, sinon 2) premier participant de la liste
        let referenceUserId: String? = {
            if session.participants.contains(session.creatorId) {
                return session.creatorId
            }
            return session.participants.first
        }()
        
        guard let userId = referenceUserId else {
            Logger.log("⚠️ Aucun participant pour charger le parcours", category: .service)
            routePoints = []
            return
        }
        
        Logger.log("🗺️ Chargement du parcours (userId: \(userId)) pour session: \(sessionId)", category: .service)
        
        do {
            let points = try await routeHistoryService.loadRoutePoints(sessionId: sessionId, userId: userId)
            let coords = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            routePoints = coords
            Logger.log("✅ \(routePoints.count) points GPS chargés", category: .service)
        } catch {
            Logger.logError(error, context: "loadRoutePoints", category: .service)
            routePoints = []
            throw error
        }
    }
    
    // MARK: - Load User Names
    
    /// Charge les noms des utilisateurs pour afficher les noms réels au lieu des IDs
    private func loadUserNames() async throws {
        Logger.log("👤 Chargement des noms d'utilisateurs", category: .service)
        
        // Charger tous les noms en parallèle
        await withTaskGroup(of: (String, String?).self) { group in
            for userId in session.participants {
                group.addTask {
                    let name = await self.fetchUserName(userId: userId)
                    return (userId, name)
                }
            }
            
            for await (userId, name) in group {
                if let name = name, !name.isEmpty {
                    userNames[userId] = name
                } else {
                    userNames[userId] = "Coureur #\(userId.prefix(6))"
                }
            }
        }
        
        Logger.log("✅ \(userNames.count) noms chargés", category: .service)
    }
    
    /// Récupère le nom d'un utilisateur depuis Firestore
    private func fetchUserName(userId: String) async -> String? {
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            return userDoc.data()?["displayName"] as? String
        } catch {
            Logger.log("⚠️ Erreur chargement nom pour \(userId): \(error)", category: .service)
            return nil
        }
    }
    
    // MARK: - Helper Functions
    
    /// Récupère le nom d'affichage d'un utilisateur
    /// - Parameter userId: ID de l'utilisateur
    /// - Returns: Nom d'affichage ou ID tronqué
    func getUserName(for userId: String) -> String {
        userNames[userId] ?? "Coureur #\(userId.prefix(6))"
    }
}

