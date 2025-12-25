//
//  SessionService.swift
//  RunningMan
//
//  Created by AI Assistant on 24/12/2025.
//

import Foundation
import FirebaseFirestore

/// Service de gestion des sessions de course
/// Gère la création, pause, reprise, fin et observation des sessions
class SessionService {
    
    static let shared = SessionService()
    
    private let db = Firestore.firestore()
    
    private init() {
        Logger.log("SessionService initialisé", category: .session)
    }
    
    // MARK: - Create Session
    
    /// Crée une nouvelle session de course
    /// - Parameters:
    ///   - squadId: ID de la squad
    ///   - creatorId: ID de l'utilisateur qui crée la session
    ///   - title: Titre de la session (optionnel)
    ///   - sessionType: Type de session (training, race, casual)
    ///   - targetDistance: Distance cible en mètres (optionnel)
    /// - Returns: SessionModel créé avec son ID
    func createSession(
        squadId: String,
        creatorId: String,
        title: String? = nil,
        sessionType: SessionType = .training,
        targetDistance: Double? = nil
    ) async throws -> SessionModel {
        
        Logger.log("Création d'une nouvelle session pour squad: \(squadId)", category: .session)
        
        // 1. Créer le modèle de session
        var session = SessionModel(
            squadId: squadId,
            creatorId: creatorId,
            startedAt: Date(),
            status: .active,
            participants: [creatorId], // Le créateur est automatiquement participant
            targetDistanceMeters: targetDistance,
            title: title,
            sessionType: sessionType
        )
        
        // 2. Créer le document dans Firestore
        let sessionRef = db.collection("sessions").document()
        session.id = sessionRef.documentID
        
        try sessionRef.setData(from: session)
        
        // 3. Ajouter la session aux activeSessions de la squad
        try await addSessionToSquad(squadId: squadId, sessionId: sessionRef.documentID)
        
        Logger.logSuccess("Session créée avec succès: \(sessionRef.documentID)", category: .session)
        
        return session
    }
    
    // MARK: - End Session
    
    /// Termine une session
    /// - Parameters:
    ///   - sessionId: ID de la session à terminer
    ///   - finalDistance: Distance finale en mètres
    func endSession(sessionId: String, finalDistance: Double? = nil) async throws {
        
        Logger.log("Fin de la session: \(sessionId)", category: .session)
        
        // 1. Récupérer la session
        guard var session = try await getSession(sessionId: sessionId) else {
            throw SessionError.sessionNotFound
        }
        
        // 2. Mettre à jour le statut et la date de fin
        session.status = .ended
        session.endedAt = Date()
        
        // 3. Calculer la durée finale
        session.durationSeconds = Date().timeIntervalSince(session.startedAt)
        
        // 4. Mettre à jour la distance finale si fournie
        if let finalDistance = finalDistance {
            session.totalDistanceMeters = finalDistance
        }
        
        // 5. Sauvegarder dans Firestore
        try await updateSession(session)
        
        // 6. Retirer la session des activeSessions de la squad
        try await removeSessionFromSquad(squadId: session.squadId, sessionId: sessionId)
        
        Logger.logSuccess("Session terminée: \(sessionId)", category: .session)
    }
    
    // MARK: - Pause/Resume Session
    
    /// Met en pause une session
    func pauseSession(sessionId: String) async throws {
        guard var session = try await getSession(sessionId: sessionId) else {
            throw SessionError.sessionNotFound
        }
        
        guard session.status == .active else {
            throw SessionError.invalidSessionStatus
        }
        
        session.status = .paused
        try await updateSession(session)
        
        Logger.log("Session mise en pause: \(sessionId)", category: .session)
    }
    
    /// Reprend une session en pause
    func resumeSession(sessionId: String) async throws {
        guard var session = try await getSession(sessionId: sessionId) else {
            throw SessionError.sessionNotFound
        }
        
        guard session.status == .paused else {
            throw SessionError.invalidSessionStatus
        }
        
        session.status = .active
        try await updateSession(session)
        
        Logger.log("Session reprise: \(sessionId)", category: .session)
    }
    
    // MARK: - Join/Leave Session
    
    /// Rejoindre une session en cours
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui rejoint
    func joinSession(sessionId: String, userId: String) async throws {
        
        Logger.log("Utilisateur \(userId) rejoint la session \(sessionId)", category: .session)
        
        guard var session = try await getSession(sessionId: sessionId) else {
            throw SessionError.sessionNotFound
        }
        
        // Vérifier que la session est active
        guard session.status == .active else {
            throw SessionError.sessionNotActive
        }
        
        // Ajouter l'utilisateur aux participants
        session.addParticipant(userId: userId)
        
        try await updateSession(session)
        
        Logger.logSuccess("Utilisateur \(userId) a rejoint la session", category: .session)
    }
    
    /// Quitter une session en cours
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui quitte
    func leaveSession(sessionId: String, userId: String) async throws {
        
        Logger.log("Utilisateur \(userId) quitte la session \(sessionId)", category: .session)
        
        guard var session = try await getSession(sessionId: sessionId) else {
            throw SessionError.sessionNotFound
        }
        
        // Retirer l'utilisateur des participants
        session.removeParticipant(userId: userId)
        
        try await updateSession(session)
        
        Logger.log("Utilisateur \(userId) a quitté la session", category: .session)
    }
    
    // MARK: - Get Session
    
    /// Récupère une session par son ID
    func getSession(sessionId: String) async throws -> SessionModel? {
        let sessionRef = db.collection("sessions").document(sessionId)
        let document = try await sessionRef.getDocument()
        
        guard document.exists else {
            return nil
        }
        
        return try document.data(as: SessionModel.self)
    }
    
    // MARK: - Get Active Session
    
    /// Récupère la session active d'une squad (s'il y en a une)
    func getActiveSession(squadId: String) async throws -> SessionModel? {
        let sessionsRef = db.collection("sessions")
        let query = sessionsRef
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", isEqualTo: SessionStatus.active.rawValue)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try document.data(as: SessionModel.self)
    }
    
    // MARK: - Observe Active Session
    
    /// Observe les changements de la session active d'une squad en temps réel
    /// - Parameter squadId: ID de la squad
    /// - Returns: AsyncStream qui émet les mises à jour de session
    func observeActiveSession(squadId: String) -> AsyncStream<SessionModel?> {
        AsyncStream { continuation in
            let query = db.collection("sessions")
                .whereField("squadId", isEqualTo: squadId)
                .whereField("status", isEqualTo: SessionStatus.active.rawValue)
                .limit(to: 1)
            
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    Logger.logError(error, context: "observeActiveSession", category: .session)
                    continuation.yield(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    continuation.yield(nil)
                    return
                }
                
                do {
                    let session = try document.data(as: SessionModel.self)
                    continuation.yield(session)
                } catch {
                    Logger.logError(error, context: "decode session", category: .session)
                    continuation.yield(nil)
                }
            }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    // MARK: - Update Session
    
    /// Met à jour une session dans Firestore
    func updateSession(_ session: SessionModel) async throws {
        guard let sessionId = session.id else {
            throw SessionError.invalidSessionId
        }
        
        let sessionRef = db.collection("sessions").document(sessionId)
        try sessionRef.setData(from: session, merge: true)
    }
    
    /// Met à jour la distance totale d'une session
    func updateDistance(sessionId: String, distanceMeters: Double) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        try await sessionRef.updateData([
            "totalDistanceMeters": distanceMeters
        ])
    }
    
    /// Met à jour la durée d'une session
    func updateDuration(sessionId: String, durationSeconds: TimeInterval) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        try await sessionRef.updateData([
            "durationSeconds": durationSeconds
        ])
    }
    
    // MARK: - Get Session History
    
    /// Récupère l'historique des sessions d'une squad
    /// - Parameters:
    ///   - squadId: ID de la squad
    ///   - limit: Nombre maximum de sessions à récupérer
    /// - Returns: Liste des sessions triées par date (plus récente en premier)
    func getSessionHistory(squadId: String, limit: Int = 20) async throws -> [SessionModel] {
        let sessionsRef = db.collection("sessions")
        let query = sessionsRef
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", isEqualTo: SessionStatus.ended.rawValue)
            .order(by: "startedAt", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        var sessions: [SessionModel] = []
        for document in snapshot.documents {
            if let session = try? document.data(as: SessionModel.self) {
                sessions.append(session)
            }
        }
        
        Logger.log("Sessions récupérées pour squad \(squadId): \(sessions.count)", category: .session)
        
        return sessions
    }
    
    // MARK: - Helper Methods
    
    /// Ajoute une session aux activeSessions d'une squad
    private func addSessionToSquad(squadId: String, sessionId: String) async throws {
        let squadRef = db.collection("squads").document(squadId)
        try await squadRef.updateData([
            "activeSessions": FieldValue.arrayUnion([sessionId])
        ])
    }
    
    /// Retire une session des activeSessions d'une squad
    private func removeSessionFromSquad(squadId: String, sessionId: String) async throws {
        let squadRef = db.collection("squads").document(squadId)
        try await squadRef.updateData([
            "activeSessions": FieldValue.arrayRemove([sessionId])
        ])
    }
    
    // MARK: - Delete Session
    
    /// Supprime une session (admin uniquement, use with caution)
    func deleteSession(sessionId: String) async throws {
        // Récupérer la session pour obtenir le squadId
        guard let session = try await getSession(sessionId: sessionId) else {
            throw SessionError.sessionNotFound
        }
        
        // Retirer des activeSessions de la squad
        try await removeSessionFromSquad(squadId: session.squadId, sessionId: sessionId)
        
        // Supprimer le document
        let sessionRef = db.collection("sessions").document(sessionId)
        try await sessionRef.delete()
        
        Logger.logSuccess("Session supprimée: \(sessionId)", category: .session)
    }
}

// MARK: - SessionError

/// Erreurs personnalisées pour les sessions
enum SessionError: LocalizedError {
    case sessionNotFound
    case invalidSessionId
    case invalidSessionStatus
    case sessionNotActive
    case notAParticipant
    case alreadyParticipant
    
    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Session introuvable"
        case .invalidSessionId:
            return "ID de session invalide"
        case .invalidSessionStatus:
            return "Statut de session invalide pour cette opération"
        case .sessionNotActive:
            return "La session n'est pas active"
        case .notAParticipant:
            return "Vous ne participez pas à cette session"
        case .alreadyParticipant:
            return "Vous participez déjà à cette session"
        }
    }
}
