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
        
        // 🆕 Initialiser l'état du créateur comme "waiting"
        let initialParticipantStates: [String: ParticipantSessionState] = [
            creatorId: .waiting()
        ]
        
        // Créer la session localement (sans ID, @DocumentID le gérera)
        let session = SessionModel(
            squadId: squadId,
            creatorId: creatorId,
            startedAt: Date(),
            status: .scheduled, // 🆕 Commence en "scheduled", devient "active" quand premier participant démarre
            participants: [creatorId],
            startLocation: startLocation,
            participantStates: initialParticipantStates
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
                    // 🆕 Initialiser l'état du nouveau participant comme "waiting"
                    "participantStates.\(userId).status": ParticipantStatus.waiting.rawValue,
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
    
    /// Met à jour des champs spécifiques d'une session
    func updateSessionFields(sessionId: String, fields: [String: Any]) async throws {
        var updateData = fields
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await db.collection("sessions")
            .document(sessionId)
            .updateData(updateData)
        
        Logger.logSuccess("✅ Session \(sessionId) mise à jour", category: .service)
    }
    
    /// Récupère la session de course active pour une squad (s'il y en a une)
    func getActiveRaceSession(squadId: String) async throws -> SessionModel? {
        let snapshot = try await db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("activityType", isEqualTo: ActivityType.race.rawValue)
            .whereField("status", isEqualTo: SessionStatus.active.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            Logger.log("✅ Aucune course active pour squad: \(squadId)", category: .service)
            return nil
        }
        
        let session = try document.data(as: SessionModel.self)
        Logger.log("🏁 Course active détectée: \(session.id ?? "unknown")", category: .service)
        return session
    }
    
    /// Vérifie si un utilisateur a déjà une session active dans une squad donnée
    func getUserActiveSession(squadId: String, userId: String) async throws -> SessionModel? {
        let snapshot = try await db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("creatorId", isEqualTo: userId)
            .whereField("status", isEqualTo: SessionStatus.active.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try document.data(as: SessionModel.self)
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
    
    // MARK: - Participant Tracking Management
    
    /// 🆕 Démarre le tracking pour un participant spécifique
    ///
    /// Marque le participant comme "actif" dans la session. Si c'est le premier
    /// participant à démarrer, la session passe de "scheduled" à "active".
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui démarre
    /// - Throws: `SessionError` si la session n'existe pas
    func startParticipantTracking(
        sessionId: String,
        userId: String
    ) async throws {
        Logger.log("🚀 Démarrage tracking pour participant: \(userId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // Mettre à jour l'état du participant
        try await sessionRef.updateData([
            "participantStates.\(userId).status": ParticipantStatus.active.rawValue,
            "participantStates.\(userId).startedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        // Vérifier si c'est le premier participant à démarrer
        let document = try await sessionRef.getDocument()
        guard let session = try? document.data(as: SessionModel.self) else {
            throw SessionError.invalidSession
        }
        
        // Si la session est encore "scheduled", l'activer
        if session.status == .scheduled {
            try await sessionRef.updateData([
                "status": SessionStatus.active.rawValue,
                "startedAt": FieldValue.serverTimestamp()
            ])
            Logger.log("✅ Session activée (premier participant)", category: .session)
        }
        
        Logger.logSuccess("✅ Tracking démarré pour participant \(userId)", category: .session)
    }
    
    /// 🆕 Termine le tracking pour un participant spécifique
    ///
    /// Marque le participant comme ayant terminé sa course. Ne termine PAS
    /// la session entière - les autres participants peuvent continuer.
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui termine
    ///   - finalDistance: Distance finale en mètres
    ///   - finalDuration: Durée finale en secondes
    /// - Throws: `SessionError` si la session n'existe pas
    func endParticipantTracking(
        sessionId: String,
        userId: String,
        finalDistance: Double,
        finalDuration: TimeInterval
    ) async throws {
        Logger.log("🏁 Fin du tracking pour participant: \(userId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // Mettre à jour l'état du participant
        try await sessionRef.updateData([
            "participantStates.\(userId).status": ParticipantStatus.ended.rawValue,
            "participantStates.\(userId).endedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        // Mettre à jour les stats finales du participant
        try await updateParticipantStats(
            sessionId: sessionId,
            userId: userId,
            distance: finalDistance,
            duration: finalDuration,
            averageSpeed: finalDuration > 0 ? finalDistance / finalDuration : 0,
            maxSpeed: 0 // Sera mis à jour par le tracking GPS
        )
        
        Logger.logSuccess("✅ Participant \(userId) a terminé sa course", category: .session)
    }
    
    /// 🆕 Marque un participant comme ayant abandonné
    ///
    /// Le participant est marqué comme "abandoned" mais ses statistiques
    /// partielles sont conservées.
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui abandonne
    /// - Throws: `SessionError` si la session n'existe pas
    func abandonParticipantTracking(
        sessionId: String,
        userId: String
    ) async throws {
        Logger.log("⚠️ Abandon pour participant: \(userId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        try await sessionRef.updateData([
            "participantStates.\(userId).status": ParticipantStatus.abandoned.rawValue,
            "participantStates.\(userId).endedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        Logger.log("✅ Participant \(userId) marqué comme abandonné", category: .session)
    }
    
    /// 🆕 Met en pause le tracking d'un participant
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui se met en pause
    /// - Throws: `SessionError` si la session n'existe pas
    func pauseParticipantTracking(
        sessionId: String,
        userId: String
    ) async throws {
        Logger.log("⏸️ Pause tracking pour participant: \(userId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        try await sessionRef.updateData([
            "participantStates.\(userId).status": ParticipantStatus.paused.rawValue,
            "participantStates.\(userId).lastPausedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        Logger.log("✅ Participant \(userId) en pause", category: .session)
    }
    
    /// 🆕 Reprend le tracking d'un participant après une pause
    ///
    /// Calcule automatiquement la durée de pause et l'ajoute au total.
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui reprend
    /// - Throws: `SessionError` si la session n'existe pas
    func resumeParticipantTracking(
        sessionId: String,
        userId: String
    ) async throws {
        Logger.log("▶️ Reprise tracking pour participant: \(userId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // Récupérer l'état actuel pour calculer la durée de pause
        let document = try await sessionRef.getDocument()
        guard let session = try? document.data(as: SessionModel.self),
              let participantState = session.participantStates?[userId],
              let lastPausedAt = participantState.lastPausedAt else {
            throw SessionError.invalidSession
        }
        
        // Calculer la durée de pause
        let pauseDuration = Date().timeIntervalSince(lastPausedAt)
        let totalPausedDuration = participantState.pausedDuration + pauseDuration
        
        try await sessionRef.updateData([
            "participantStates.\(userId).status": ParticipantStatus.active.rawValue,
            "participantStates.\(userId).pausedDuration": totalPausedDuration,
            "participantStates.\(userId).lastPausedAt": FieldValue.delete(), // Supprimer lastPausedAt
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        Logger.log("✅ Participant \(userId) a repris", category: .session)
    }
    
    /// 🆕 Vérifie si tous les participants ont fini et termine la session si nécessaire
    ///
    /// Appelé automatiquement après qu'un participant termine ou abandonne.
    /// Si tous les participants ont fini (ended ou abandoned), la session
    /// est automatiquement terminée.
    ///
    /// - Parameter sessionId: ID de la session à vérifier
    /// - Throws: `SessionError` si la session n'existe pas
    func checkAndEndSessionIfComplete(sessionId: String) async throws {
        Logger.log("🔍 Vérification si session peut être terminée: \(sessionId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        let document = try await sessionRef.getDocument()
        
        guard let session = try? document.data(as: SessionModel.self) else {
            throw SessionError.invalidSession
        }
        
        // Vérifier si tous les participants ont fini
        if session.canBeEnded {
            Logger.log("✅ Tous les participants ont terminé, fin automatique de session", category: .session)
            try await endSession(sessionId: sessionId)
        } else {
            let activeCount = session.activeParticipantsCount
            let pausedCount = session.pausedParticipantsCount
            Logger.log("ℹ️ Session continue : \(activeCount) actif(s), \(pausedCount) en pause", category: .session)
        }
    }
    
    // MARK: - End Session
    
    /// Termine une session pour TOUS les participants
    ///
    /// ⚠️ **Important :** Cette fonction termine la session globalement.
    /// Elle devrait être appelée UNIQUEMENT dans ces cas :
    /// - Tous les participants ont fini/abandonné (via `checkAndEndSessionIfComplete`)
    /// - Timeout atteint (ex: 4h après le démarrage)
    /// - Annulation manuelle par un admin de la squad
    ///
    /// Pour terminer le tracking d'UN SEUL participant, utilisez `endParticipantTracking()`.
    ///
    /// - Parameter sessionId: ID de la session à terminer
    /// - Throws: `SessionError` si la session n'existe pas
    func endSession(sessionId: String) async throws {
        Logger.log("🛑 Fin de session pour tous les participants: \(sessionId)", category: .session)
        
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
