import Foundation
import FirebaseFirestore

// MARK: - Session Errors

enum SessionError: LocalizedError {
    case sessionNotFound
    case invalidSession
    case notAuthorized
    case alreadyJoined
    case alreadyEnded
    
    var errorDescription: String? {
        switch self {
        case .sessionNotFound: return "Session introuvable"
        case .invalidSession: return "Session invalide"
        case .notAuthorized: return "Non autorisé"
        case .alreadyJoined: return "Déjà participant"
        case .alreadyEnded: return "Session terminée"
        }
    }
}

class SessionService {
    
    static let shared = SessionService()
    
    // Computed property pour éviter le crash Firebase au démarrage
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private init() {
        Logger.log("SessionService initialisé", category: .session)
    }
    
    // MARK: - Create Session
    
    func createSession(
        squadId: String,
        creatorId: String,
        startLocation: GeoPoint? = nil
    ) async throws -> SessionModel {
        
        Logger.log("Création d'une nouvelle session pour squad: \(squadId)", category: .session)
        print("🔨 createSession appelé pour squadId: \(squadId)")
        
        var session = SessionModel(
            squadId: squadId,
            creatorId: creatorId,
            startedAt: Date(),
            status: .active,
            participants: [creatorId],
            startLocation: startLocation
        )
        
        let sessionRef = db.collection("sessions").document()
        session.id = sessionRef.documentID
        
        print("💾 Enregistrement session dans Firestore: \(sessionRef.documentID)")
        try sessionRef.setData(from: session)
        try await addSessionToSquad(squadId: squadId, sessionId: sessionRef.documentID)
        
        Logger.logSuccess("Session créée avec succès: \(sessionRef.documentID)", category: .session)
        print("✅ Session enregistrée - ID: \(sessionRef.documentID), Status: \(session.status.rawValue), SquadId: \(session.squadId)")
        return session
    }
    
    // MARK: - Join / Leave / Status
    
    func joinSession(sessionId: String, userId: String) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        
        try await sessionRef.updateData([
            "participants": FieldValue.arrayUnion([userId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        // Stats initiales pour le participant
        let statsRef = sessionRef.collection("participantStats").document(userId)
        let stats = ParticipantStats(
            userId: userId,
            distance: 0,
            duration: 0,
            averageSpeed: 0,
            maxSpeed: 0,
            locationPointsCount: 0,
            joinedAt: Date()
        )
        try statsRef.setData(from: stats)
    }
    
    func leaveSession(sessionId: String, userId: String) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        try await sessionRef.updateData([
            "participants": FieldValue.arrayRemove([userId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    func pauseSession(sessionId: String) async throws {
        try await db.collection("sessions").document(sessionId).updateData([
            "status": SessionStatus.paused.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    func resumeSession(sessionId: String) async throws {
        try await db.collection("sessions").document(sessionId).updateData([
            "status": SessionStatus.active.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Get Session
    
    /// Récupère une session par son ID
    func getSession(sessionId: String) async throws -> SessionModel? {
        let document = try await db.collection("sessions").document(sessionId).getDocument()
        
        guard document.exists else {
            Logger.log("⚠️ Session introuvable: \(sessionId)", category: .service)
            return nil
        }
        
        let session = try document.data(as: SessionModel.self)
        Logger.log("✅ Session récupérée: \(sessionId)", category: .service)
        return session
    }
    
    // MARK: - End Session
    
    func endSession(sessionId: String) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        let document = try await sessionRef.getDocument()
        guard let session = try? document.data(as: SessionModel.self) else { throw SessionError.sessionNotFound }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(session.startedAt)
        
        try await sessionRef.updateData([
            "status": SessionStatus.ended.rawValue,
            "endedAt": FieldValue.serverTimestamp(),
            "durationSeconds": duration,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        try await removeSessionFromSquad(squadId: session.squadId, sessionId: sessionId)
    }
    
    // MARK: - Update Participant Stats
    
    /// Met à jour les statistiques d'un participant dans une session
    func updateParticipantStats(
        sessionId: String,
        userId: String,
        distance: Double,
        duration: TimeInterval,
        averageSpeed: Double,
        maxSpeed: Double
    ) async throws {
        let statsRef = db.collection("sessions")
            .document(sessionId)
            .collection("participantStats")
            .document(userId)
        
        try await statsRef.updateData([
            "distance": distance,
            "duration": duration,
            "averageSpeed": averageSpeed,
            "maxSpeed": maxSpeed,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        Logger.log("📊 Stats participant mises à jour: \(userId)", category: .service)
    }
    
    /// 🆕 Met à jour les stats biométriques en temps réel (HealthKit)
    func updateParticipantLiveStats(
        sessionId: String,
        userId: String,
        stats: ParticipantStats
    ) async throws {
        let statsRef = db.collection("sessions")
            .document(sessionId)
            .collection("participantStats")
            .document(userId)
        
        // Créer un dictionnaire avec seulement les champs non-nil
        var updateData: [String: Any] = [
            "userId": userId,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Ajouter les champs biométriques s'ils sont présents
        if let heartRate = stats.currentHeartRate {
            updateData["currentHeartRate"] = heartRate
        }
        if let avgHeartRate = stats.averageHeartRate {
            updateData["averageHeartRate"] = avgHeartRate
        }
        if let maxHeartRate = stats.maxHeartRate {
            updateData["maxHeartRate"] = maxHeartRate
        }
        if let minHeartRate = stats.minHeartRate {
            updateData["minHeartRate"] = minHeartRate
        }
        if let calories = stats.calories {
            updateData["calories"] = calories
        }
        if let heartRateUpdatedAt = stats.heartRateUpdatedAt {
            updateData["heartRateUpdatedAt"] = Timestamp(date: heartRateUpdatedAt)
        }
        
        // Ajouter distance si présente
        if stats.distance > 0 {
            updateData["distance"] = stats.distance
        }
        
        // Mettre à jour (ou créer si n'existe pas)
        try await statsRef.setData(updateData, merge: true)
        
        Logger.log("❤️ Stats biométriques mises à jour: \(userId) - BPM: \(stats.currentHeartRate ?? 0)", category: .service)
    }
    
    // MARK: - Update Session Stats (Aggregate)
    
    /// Met à jour les statistiques globales de la session (distance totale, etc.)
    func updateSessionStats(
        sessionId: String,
        totalDistance: Double,
        averageSpeed: Double
    ) async throws {
        try await db.collection("sessions").document(sessionId).updateData([
            "totalDistanceMeters": totalDistance,
            "averageSpeed": averageSpeed,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        Logger.log("📊 Stats session mises à jour", category: .service)
    }
    
    /// Met à jour la durée de la session en temps réel
    func updateSessionDuration(sessionId: String, duration: TimeInterval) async throws {
        try await db.collection("sessions").document(sessionId).updateData([
            "durationSeconds": duration,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Get Active Session
    
    /// Récupère la session active pour un squad donné (requête unique)
    func getActiveSession(squadId: String) async throws -> SessionModel? {
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
            .order(by: "startedAt", descending: true)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.first.flatMap { try? $0.data(as: SessionModel.self) }
    }

    // MARK: - Real-time Observation (Modern AsyncStream)
    
    /// Stream de toutes les sessions actives d'un squad
    func streamActiveSessions(squadId: String) -> AsyncStream<[SessionModel]> {
        AsyncStream { continuation in
            let query = db.collection("sessions")
                .whereField("squadId", isEqualTo: squadId)
                .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
            
            let listener = query.addSnapshotListener { snapshot, _ in
                let sessions = snapshot?.documents.compactMap { try? $0.data(as: SessionModel.self) } ?? []
                continuation.yield(sessions)
            }
            continuation.onTermination = { _ in listener.remove() }
        }
    }
    
    /// Stream d'une session active spécifique (avec mises à jour en temps réel)
    func observeSession(sessionId: String) -> AsyncStream<SessionModel?> {
        AsyncStream { continuation in
            let docRef = db.collection("sessions").document(sessionId)
            
            let listener = docRef.addSnapshotListener { snapshot, error in
                if let error = error {
                    Logger.logError(error, context: "observeSession", category: .service)
                    continuation.yield(nil)
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    Logger.log("⚠️ Session \(sessionId) introuvable", category: .service)
                    continuation.yield(nil)
                    return
                }
                
                if let session = try? snapshot.data(as: SessionModel.self) {
                    Logger.log("🔄 Session \(sessionId) mise à jour", category: .service)
                    continuation.yield(session)
                } else {
                    Logger.log("⚠️ Échec décodage session \(sessionId)", category: .service)
                    continuation.yield(nil)
                }
            }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    /// Stream de la session active d'un squad (une seule)
    func observeActiveSession(squadId: String) -> AsyncStream<SessionModel?> {
        print("🔍 observeActiveSession démarré pour squadId: \(squadId)")
        return AsyncStream { continuation in
            let query = db.collection("sessions")
                .whereField("squadId", isEqualTo: squadId)
                .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
                .order(by: "startedAt", descending: true)
                .limit(to: 1)
            
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ ERROR observeActiveSession: \(error.localizedDescription)")
                    // NE PAS TERMINER LE STREAM - juste yield nil et continuer
                    continuation.yield(nil)
                    return
                }
                
                print("📦 Snapshot reçu: \(snapshot?.documents.count ?? 0) document(s)")
                
                if let doc = snapshot?.documents.first {
                    print("📄 Document trouvé: \(doc.documentID)")
                    if let session = try? doc.data(as: SessionModel.self) {
                        print("✅ Session décodée: \(session.id ?? "no-id") - status: \(session.status.rawValue)")
                        continuation.yield(session)
                    } else {
                        print("⚠️ Échec décodage session")
                        continuation.yield(nil)
                    }
                } else {
                    print("⚠️ Aucun document trouvé")
                    continuation.yield(nil)
                }
            }
            continuation.onTermination = { @Sendable _ in
                print("🛑 observeActiveSession terminé")
                listener.remove()
            }
        }
    }

    // MARK: - Get Session History
    
    /// Récupère l'historique des sessions d'un squad
    func getSessionHistory(squadId: String, limit: Int = 50) async throws -> [SessionModel] {
        Logger.log("📜 Récupération historique pour squad: \(squadId)", category: .service)
        
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", isEqualTo: SessionStatus.ended.rawValue)
            .order(by: "endedAt", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        let sessions = snapshot.documents.compactMap { try? $0.data(as: SessionModel.self) }
        
        Logger.logSuccess("✅ \(sessions.count) sessions historiques récupérées", category: .service)
        return sessions
    }
    
    /// Récupère toutes les sessions actives d'un squad
    func getActiveSessions(squadId: String) async throws -> [SessionModel] {
        Logger.log("🔍 Récupération sessions actives pour squad: \(squadId)", category: .service)
        
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
            .order(by: "startedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        let sessions = snapshot.documents.compactMap { try? $0.data(as: SessionModel.self) }
        
        Logger.logSuccess("✅ \(sessions.count) sessions actives trouvées", category: .service)
        return sessions
    }
    
    /// Récupère toutes les sessions (actives + historique) d'un squad
    func getAllSessions(squadId: String, limit: Int = 100) async throws -> [SessionModel] {
        Logger.log("📚 Récupération toutes sessions pour squad: \(squadId)", category: .service)
        
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .order(by: "startedAt", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        let sessions = snapshot.documents.compactMap { try? $0.data(as: SessionModel.self) }
        
        Logger.logSuccess("✅ \(sessions.count) sessions totales récupérées", category: .service)
        return sessions
    }

    // MARK: - Helpers
    
    private func addSessionToSquad(squadId: String, sessionId: String) async throws {
        try await db.collection("squads").document(squadId).updateData([
            "activeSessions": FieldValue.arrayUnion([sessionId])
        ])
    }
    
    private func removeSessionFromSquad(squadId: String, sessionId: String) async throws {
        try await db.collection("squads").document(squadId).updateData([
            "activeSessions": FieldValue.arrayRemove([sessionId])
        ])
    }
}
