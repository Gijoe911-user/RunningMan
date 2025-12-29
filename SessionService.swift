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
    
    // ✅ Cache pour éviter les requêtes multiples
    private var sessionCache: [String: (sessions: [SessionModel], timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 5.0  // ✅ 5 secondes (réduit pour le développement)
    
    private init() {
        Logger.log("SessionService initialisé", category: .session)
    }
    
    // ✅ Méthode publique pour invalider le cache (utile lors du pull-to-refresh)
    func invalidateCache(squadId: String? = nil) {
        if let squadId = squadId {
            sessionCache.removeValue(forKey: "active_\(squadId)")
            sessionCache.removeValue(forKey: "history_\(squadId)")
            Logger.log("🗑️ Cache invalidé pour squad: \(squadId)", category: .service)
        } else {
            sessionCache.removeAll()
            Logger.log("🗑️ Cache complet invalidé", category: .service)
        }
    }
    
    // ✅ Méthode pour forcer le rafraîchissement (ignore le cache)
    func forceRefresh(squadId: String) async throws -> [SessionModel] {
        Logger.log("🔄 Rafraîchissement forcé pour squad: \(squadId)", category: .service)
        invalidateCache(squadId: squadId)
        return try await getActiveSessions(squadId: squadId)
    }
    
    // MARK: - Create Session
    
    /// Crée une nouvelle session - Version RAPIDE avec fire-and-forget
    func createSession(
        squadId: String,
        creatorId: String,
        startLocation: GeoPoint? = nil
    ) async throws -> SessionModel {
        
        Logger.log("Création d'une nouvelle session pour squad: \(squadId)", category: .session)
        print("🔨 createSession appelé pour squadId: \(squadId)")
        
        // Créer la session localement (sans ID, @DocumentID le gérera)
        let session = SessionModel(
            squadId: squadId,
            creatorId: creatorId,
            startedAt: Date(),
            status: .active,
            participants: [creatorId],
            startLocation: startLocation
        )
        
        let sessionRef = db.collection("sessions").document()
        
        print("💾 Enregistrement session dans Firestore: \(sessionRef.documentID)")
        
        // 🚀 Fire-and-forget pour l'enregistrement
        Task.detached {
            do {
                try sessionRef.setData(from: session)
                Logger.log("✅ Session enregistrée dans Firestore", category: .session)
            } catch {
                Logger.log("⚠️ Erreur enregistrement session: \(error.localizedDescription)", category: .session)
            }
        }
        
        // Ajouter à la squad en arrière-plan
        Task.detached { [weak self] in
            do {
                try await self?.addSessionToSquad(squadId: squadId, sessionId: sessionRef.documentID)
                Logger.log("✅ Session ajoutée à la squad", category: .session)
            } catch {
                Logger.log("⚠️ Erreur ajout à la squad: \(error.localizedDescription)", category: .session)
            }
        }
        
        // Invalider le cache immédiatement
        invalidateCache(squadId: squadId)
        
        Logger.logSuccess("Session créée (async): \(sessionRef.documentID)", category: .session)
        print("✅ Session lancée - ID: \(sessionRef.documentID), Status: \(session.status.rawValue)")
        
        // ✅ Relire depuis Firestore pour obtenir la session avec @DocumentID correctement assigné
        // Retourner immédiatement pour ne pas bloquer (les listeners temps réel mettront à jour l'UI)
        var sessionWithId = session
        sessionWithId.id = sessionRef.documentID  // Assignation temporaire pour compatibilité immédiate
        
        return sessionWithId
    }
    
    // MARK: - Join / Leave / Status
    
    func joinSession(sessionId: String, userId: String) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // 🚀 Fire-and-forget pour l'ajout du participant
        Task.detached {
            do {
                try await sessionRef.updateData([
                    "participants": FieldValue.arrayUnion([userId]),
                    "updatedAt": FieldValue.serverTimestamp()
                ])
                Logger.log("✅ Participant ajouté à la session", category: .service)
            } catch {
                Logger.log("⚠️ Erreur ajout participant: \(error.localizedDescription)", category: .service)
            }
        }
        
        // Stats initiales pour le participant (en arrière-plan aussi)
        Task.detached {
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
            try? statsRef.setData(from: stats)
        }
    }
    
    func leaveSession(sessionId: String, userId: String) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // 🚀 Fire-and-forget
        Task.detached {
            try? await sessionRef.updateData([
                "participants": FieldValue.arrayRemove([userId]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    func pauseSession(sessionId: String) async throws {
        // 🚀 Fire-and-forget
        Task.detached { [weak self] in
            try? await self?.db.collection("sessions").document(sessionId).updateData([
                "status": SessionStatus.paused.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    func resumeSession(sessionId: String) async throws {
        // 🚀 Fire-and-forget
        Task.detached { [weak self] in
            try? await self?.db.collection("sessions").document(sessionId).updateData([
                "status": SessionStatus.active.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
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
    
    /// Termine une session - Version RAPIDE avec fire-and-forget
    /// Retourne immédiatement après avoir lancé les opérations en arrière-plan
    func endSession(sessionId: String) async throws {
        Logger.log("🛑 Tentative de fin de session: \(sessionId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // 🚀 OPTIMISATION 1: Lire la session sans await bloquant
        let document = try await sessionRef.getDocument()
        
        guard document.exists else {
            Logger.log("❌ Session \(sessionId) introuvable dans Firestore", category: .session)
            throw SessionError.sessionNotFound
        }
        
        // Récupérer les infos nécessaires
        guard let session = try? document.data(as: SessionModel.self) else {
            Logger.log("⚠️ Session corrompue, suppression en arrière-plan", category: .session)
            
            // Fire-and-forget : Supprimer en arrière-plan sans bloquer
            Task.detached {
                do {
                    try await sessionRef.delete()
                    Logger.log("✅ Session corrompue supprimée", category: .session)
                } catch {
                    Logger.log("⚠️ Échec suppression session corrompue", category: .session)
                }
            }
            
            throw SessionError.invalidSession
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(session.startedAt)
        let squadId = session.squadId
        
        Logger.log("📝 Lancement fin de session \(sessionId) - durée: \(duration)s", category: .session)
        
        // 🚀 OPTIMISATION 2: Fire-and-forget pour la mise à jour Firestore
        // On lance l'opération SANS attendre la réponse
        Task.detached { [weak self] in
            do {
                try await sessionRef.updateData([
                    "status": SessionStatus.ended.rawValue,
                    "endedAt": FieldValue.serverTimestamp(),
                    "durationSeconds": duration,
                    "updatedAt": FieldValue.serverTimestamp()
                ])
                Logger.log("✅ Session terminée dans Firestore", category: .session)
                
                // Retirer de la squad (sans bloquer)
                try? await self?.removeSessionFromSquad(squadId: squadId, sessionId: sessionId)
                
            } catch {
                Logger.log("⚠️ Erreur fin session (non bloquante): \(error.localizedDescription)", category: .session)
            }
        }
        
        // 🚀 OPTIMISATION 3: Invalider le cache immédiatement
        invalidateCache(squadId: squadId)
        
        // ✅ Retour IMMÉDIAT - Les listeners temps réel vont synchroniser l'UI
        Logger.logSuccess("✅ Fin de session lancée (async)", category: .session)
    }
    
    // MARK: - Update Participant Stats
    
    /// Met à jour les statistiques d'un participant dans une session
    /// 🚀 Version fire-and-forget pour ne pas bloquer l'UI
    func updateParticipantStats(
        sessionId: String,
        userId: String,
        distance: Double,
        duration: TimeInterval,
        averageSpeed: Double,
        maxSpeed: Double
    ) async throws {
        // 🚀 Fire-and-forget - Ne pas bloquer
        Task.detached { [weak self] in
            let statsRef = self?.db.collection("sessions")
                .document(sessionId)
                .collection("participantStats")
                .document(userId)
            
            try? await statsRef?.updateData([
                "distance": distance,
                "duration": duration,
                "averageSpeed": averageSpeed,
                "maxSpeed": maxSpeed,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    /// 🆕 Met à jour les stats biométriques en temps réel (HealthKit)
    /// 🚀 Version fire-and-forget pour ne pas bloquer l'UI
    func updateParticipantLiveStats(
        sessionId: String,
        userId: String,
        stats: ParticipantStats
    ) async throws {
        // 🚀 Fire-and-forget - Ne pas bloquer
        Task.detached { [weak self] in
            let statsRef = self?.db.collection("sessions")
                .document(sessionId)
                .collection("participantStats")
                .document(userId)
            
            var updateData: [String: Any] = [
                "userId": userId,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
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
            
            if stats.distance > 0 {
                updateData["distance"] = stats.distance
            }
            
            try? await statsRef?.setData(updateData, merge: true)
        }
    }
    
    // MARK: - Update Session Stats (Aggregate)
    
    /// Met à jour les statistiques globales de la session (distance totale, etc.)
    /// 🚀 Version fire-and-forget pour ne pas bloquer l'UI
    func updateSessionStats(
        sessionId: String,
        totalDistance: Double,
        averageSpeed: Double
    ) async throws {
        // 🚀 Fire-and-forget
        Task.detached { [weak self] in
            try? await self?.db.collection("sessions").document(sessionId).updateData([
                "totalDistanceMeters": totalDistance,
                "averageSpeed": averageSpeed,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    /// Met à jour la durée de la session en temps réel
    /// 🚀 Version fire-and-forget pour ne pas bloquer l'UI
    func updateSessionDuration(sessionId: String, duration: TimeInterval) async throws {
        // 🚀 Fire-and-forget
        Task.detached { [weak self] in
            try? await self?.db.collection("sessions").document(sessionId).updateData([
                "durationSeconds": duration,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    // MARK: - Get Active Session
    
    /// Récupère la session active pour un squad donné (requête unique)
    func getActiveSession(squadId: String) async throws -> SessionModel? {
        Logger.log("🔍 Vérification session active pour squad: \(squadId)", category: .service)
        
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
            .order(by: "startedAt", descending: true)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let doc = snapshot.documents.first else {
            Logger.log("ℹ️ Aucune session active", category: .service)
            return nil
        }
        
        do {
            let session = try doc.data(as: SessionModel.self)
            Logger.log("✅ Session active trouvée: \(session.id ?? "unknown")", category: .service)
            return session
        } catch {
            Logger.log("⚠️ Session \(doc.documentID) ignorée (erreur décodage): \(error.localizedDescription)", category: .service)
            return nil
        }
    }

    // MARK: - Real-time Observation (Modern AsyncStream)
    
    /// Stream de toutes les sessions actives d'un squad
    func streamActiveSessions(squadId: String) -> AsyncStream<[SessionModel]> {
        AsyncStream { continuation in
            let query = self.db.collection("sessions")
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
            let docRef = self.db.collection("sessions").document(sessionId)
            
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
            let query = self.db.collection("sessions")
                .whereField("squadId", isEqualTo: squadId)
                .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
                .order(by: "startedAt", descending: true)
                .limit(to: 1)
            
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ ERROR observeActiveSession: \(error.localizedDescription)")
                    continuation.yield(nil)
                    return
                }
                
                print("📦 Snapshot reçu: \(snapshot?.documents.count ?? 0) document(s)")
                
                if let doc = snapshot?.documents.first {
                    print("📄 Document trouvé: \(doc.documentID)")
                    
                    do {
                        let session = try doc.data(as: SessionModel.self)
                        print("✅ Session décodée: \(session.id ?? "no-id") - status: \(session.status.rawValue)")
                        continuation.yield(session)
                    } catch {
                        print("⚠️ Session \(doc.documentID) ignorée (erreur décodage)")
                        print("   Erreur: \(error.localizedDescription)")
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
        // ✅ FIX: Vérifier le cache d'abord
        let cacheKey = "history_\(squadId)"
        if let cached = sessionCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration {
            Logger.log("📦 Cache hit pour historique: \(squadId)", category: .service)
            return cached.sessions
        }
        
        Logger.log("📜 Récupération historique pour squad: \(squadId)", category: .service)
        
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", isEqualTo: SessionStatus.ended.rawValue)
            .order(by: "endedAt", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        // ✅ Filtrer silencieusement les sessions avec erreur de décodage
        // @DocumentID gère automatiquement l'assignation de l'ID
        let sessions = snapshot.documents.compactMap { doc -> SessionModel? in
            do {
                let session = try doc.data(as: SessionModel.self)
                return session
            } catch {
                Logger.log("⚠️ Session HISTORIQUE \(doc.documentID) ignorée (erreur décodage): \(error.localizedDescription)", category: .service)
                return nil
            }
        }
        
        // ✅ FIX: Mettre en cache
        sessionCache[cacheKey] = (sessions, Date())
        
        Logger.logSuccess("✅ \(sessions.count) sessions historiques récupérées", category: .service)
        return sessions
    }
    
    /// Récupère toutes les sessions actives d'un squad
    func getActiveSessions(squadId: String) async throws -> [SessionModel] {
        // ✅ FIX: Vérifier le cache d'abord
        let cacheKey = "active_\(squadId)"
        if let cached = sessionCache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration {
            Logger.log("📦 Cache hit pour sessions actives: \(squadId)", category: .service)
            return cached.sessions
        }
        
        Logger.log("🔍 Récupération sessions actives pour squad: \(squadId)", category: .service)
        
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
            .order(by: "startedAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        
        // ✅ Filtrer silencieusement les sessions avec erreur de décodage
        // @DocumentID gère automatiquement l'assignation de l'ID
        let sessions = snapshot.documents.compactMap { doc -> SessionModel? in
            do {
                let session = try doc.data(as: SessionModel.self)
                return session
            } catch {
                Logger.log("⚠️ Session \(doc.documentID) ignorée (erreur décodage): \(error.localizedDescription)", category: .service)
                return nil
            }
        }
        
        // ✅ FIX: Mettre en cache
        sessionCache[cacheKey] = (sessions, Date())
        
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

// MARK: - Timeout Helper

/// Erreur levée quand un timeout est atteint
struct TimeoutError: Error {
    let message: String
}

/// Exécute une tâche async avec un timeout
func withTimeout<T>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        // Tâche 1 : L'opération réelle
        group.addTask {
            try await operation()
        }
        
        // Tâche 2 : Le timeout
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError(message: "Operation timed out after \(seconds) seconds")
        }
        
        // Attendre la première tâche qui se termine
        let result = try await group.next()!
        
        // Annuler l'autre tâche
        group.cancelAll()
        
        return result
    }
}
