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

@MainActor // 🆕 Swift 6 compliance
class SessionService {
    
    static let shared = SessionService()
    
    // Computed property pour éviter le crash Firebase au démarrage
    private var db: Firestore {
        Firestore.firestore()
    }
    
    // ✅ Cache pour éviter les requêtes multiples
    private var sessionCache: [String: (sessions: [SessionModel], timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 2.0  // ✅ 2 secondes (optimisé pour développement)
    
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
    ///
    /// ⚠️ **IMPORTANT pour la vision métier :**
    /// - La session est créée en statut `.scheduled` (GPS ÉTEINT)
    /// - Le créateur est ajouté comme participant en mode "waiting"
    /// - Le tracking GPS ne démarre PAS automatiquement
    /// - L'utilisateur doit cliquer sur "Démarrer" pour activer le GPS
    ///
    /// - Parameters:
    ///   - squadId: ID de la squad
    ///   - creatorId: ID de l'utilisateur créateur
    ///   - startLocation: Position GPS optionnelle (si disponible)
    /// - Returns: Session créée avec ID assigné
    /// - Throws: Erreur Firestore si l'enregistrement échoue
    func createSession(
        squadId: String,
        creatorId: String,
        startLocation: GeoPoint? = nil
    ) async throws -> SessionModel {
        
        Logger.log("🆕 Création d'une nouvelle session pour squad: \(squadId)", category: .session)
        print("🔨 createSession appelé pour squadId: \(squadId)")
        
        // 🆕 Initialiser l'état du créateur comme "waiting" (spectateur)
        let initialParticipantStates: [String: ParticipantSessionState] = [
            creatorId: .waiting()
        ]
        
        // 🆕 Initialiser l'activité du créateur comme spectateur (pas de tracking)
        let initialParticipantActivity: [String: ParticipantActivity] = [
            creatorId: ParticipantActivity(lastUpdate: Date(), isTracking: false)
        ]
        
        // Créer la session localement (sans ID, @DocumentID le gérera)
        let session = SessionModel(
            squadId: squadId,
            creatorId: creatorId,
            startedAt: Date(),
            status: .scheduled, // 🆕 Commence en "scheduled", devient "active" quand premier participant démarre
            participants: [creatorId],
            startLocation: startLocation,
            participantStates: initialParticipantStates,
            participantActivity: initialParticipantActivity
        )
        
        let sessionRef = db.collection("sessions").document()
        
        print("💾 Enregistrement session dans Firestore: \(sessionRef.documentID)")
        
        // ✅ SYNCHRONE : Enregistrer la session AVANT de retourner
        // Cela garantit que la session existe réellement en base
        do {
            try sessionRef.setData(from: session)
            Logger.log("✅ Session enregistrée dans Firestore", category: .session)
        } catch {
            Logger.log("❌ Erreur enregistrement session: \(error.localizedDescription)", category: .session)
            throw error
        }
        
        // Ajouter à la squad en arrière-plan (non-bloquant)
        Task { @MainActor [weak self] in
            do {
                try await self?.addSessionToSquad(squadId: squadId, sessionId: sessionRef.documentID)
                Logger.log("✅ Session ajoutée à la squad", category: .session)
            } catch {
                Logger.log("⚠️ Erreur ajout à la squad: \(error.localizedDescription)", category: .session)
            }
        }
        
        // Invalider le cache immédiatement
        invalidateCache(squadId: squadId)
        
        Logger.logSuccess("✅ Session créée: \(sessionRef.documentID)", category: .session)
        print("✅ Session lancée - ID: \(sessionRef.documentID), Status: \(session.status.rawValue)")
        
        // ✅ Créer une copie avec l'ID assigné manuellement
        // Note : Les listeners temps réel utiliseront @DocumentID automatiquement
        var sessionWithId = session
        sessionWithId.id = sessionRef.documentID
        
        return sessionWithId
    }
    
    // MARK: - Join / Leave / Status
    
    /// Ajoute un participant à une session existante
    ///
    /// ⚠️ **IMPORTANT pour la vision métier :**
    /// - Le participant est ajouté en mode "waiting" (spectateur)
    /// - Le GPS n'est PAS activé automatiquement
    /// - L'utilisateur doit cliquer sur "Démarrer" pour tracker
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session à rejoindre
    ///   - userId: ID de l'utilisateur qui rejoint
    /// - Throws: Erreur Firestore si l'opération échoue
    func joinSession(sessionId: String, userId: String) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // 🚀 Fire-and-forget pour l'ajout du participant
        Task { @MainActor in
            do {
                try await sessionRef.updateData([
                    "participants": FieldValue.arrayUnion([userId]),
                    // 🆕 Initialiser l'état du nouveau participant comme "waiting" (spectateur)
                    "participantStates.\(userId).status": ParticipantStatus.waiting.rawValue,
                    // 🆕 Initialiser l'activité du participant (spectateur, pas de tracking)
                    "participantActivity.\(userId).lastUpdate": FieldValue.serverTimestamp(),
                    "participantActivity.\(userId).isTracking": false,
                    "updatedAt": FieldValue.serverTimestamp()
                ])
                Logger.log("✅ Participant ajouté à la session", category: .service)
            } catch {
                Logger.log("⚠️ Erreur ajout participant: \(error.localizedDescription)", category: .service)
            }
        }
        
        // Stats initiales pour le participant (en arrière-plan aussi)
        Task { @MainActor in
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
        Task { @MainActor in
            try? await sessionRef.updateData([
                "participants": FieldValue.arrayRemove([userId]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    func pauseSession(sessionId: String) async throws {
        // 🚀 Fire-and-forget
        Task { @MainActor [weak self] in
            try? await self?.db.collection("sessions").document(sessionId).updateData([
                "status": SessionStatus.paused.rawValue,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }
    
    func resumeSession(sessionId: String) async throws {
        // 🚀 Fire-and-forget
        Task { @MainActor [weak self] in
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
            .whereField("status", in: [
                SessionStatus.scheduled.rawValue,  // ✅ Sessions en attente
                SessionStatus.active.rawValue,      // ✅ Sessions en cours
                SessionStatus.paused.rawValue       // ✅ Sessions en pause
            ])
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
            .whereField("status", in: [
                SessionStatus.scheduled.rawValue,  // ✅ Sessions en attente
                SessionStatus.active.rawValue,      // ✅ Sessions en cours
                SessionStatus.paused.rawValue       // ✅ Sessions en pause
            ])
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
    
    /// 🆕 **NOUVELLE MÉTHODE CLÉ** : Démarre MON tracking (appelée par l'utilisateur)
    ///
    /// **Vision métier :**
    /// - N'importe quel participant peut démarrer SON tracking (pas seulement le créateur)
    /// - Le participant est automatiquement ajouté s'il n'est pas déjà dans la session
    /// - Si c'est le premier à démarrer, la session passe de `SCHEDULED` → `ACTIVE`
    /// - Les autres participants peuvent démarrer après (tracking parallèle)
    ///
    /// **Séquence :**
    /// 1. Ajouter l'utilisateur aux participants (si nécessaire)
    /// 2. Marquer l'utilisateur comme "active" dans `participantStates`
    /// 3. Si session encore `SCHEDULED` → Activer la session
    /// 4. Mettre à jour `participantActivity` (heartbeat)
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session à rejoindre
    ///   - userId: ID de l'utilisateur qui démarre
    /// - Throws: `SessionError` si la session n'existe pas ou est terminée
    func startMyTracking(sessionId: String, userId: String) async throws {
        Logger.log("🚀 Démarrage de MON tracking pour session: \(sessionId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // 1. Vérifier que la session existe et n'est pas terminée
        let document = try await sessionRef.getDocument()
        guard let session = try? document.data(as: SessionModel.self) else {
            Logger.logError(SessionError.sessionNotFound, context: "startMyTracking", category: .session)
            throw SessionError.sessionNotFound
        }
        
        guard session.status != .ended else {
            Logger.log("⚠️ Impossible de démarrer : session terminée", category: .session)
            throw SessionError.alreadyEnded
        }
        
        // 2. Ajouter l'utilisateur aux participants (si pas déjà dedans)
        if !session.participants.contains(userId) {
            Logger.log("➕ Ajout participant \(userId) à la session", category: .session)
            try await sessionRef.updateData([
                "participants": FieldValue.arrayUnion([userId])
            ])
        }
        
        // 3. Marquer le participant comme "active" dans participantStates
        try await sessionRef.updateData([
            "participantStates.\(userId).status": ParticipantStatus.active.rawValue,
            "participantStates.\(userId).startedAt": FieldValue.serverTimestamp(),
            "participantActivity.\(userId).isTracking": true,
            "participantActivity.\(userId).lastUpdate": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        // 4. Si la session est encore "scheduled", l'activer
        if session.status == .scheduled {
            Logger.log("🎯 Premier participant à démarrer → Activation de la session", category: .session)
            try await sessionRef.updateData([
                "status": SessionStatus.active.rawValue,
                "startedAt": FieldValue.serverTimestamp()
            ])
        }
        
        Logger.logSuccess("✅ Tracking démarré avec succès pour \(userId)", category: .session)
    }
    
    /// 🆕 Arrête MON tracking (sans terminer la session pour les autres)
    ///
    /// **Vision métier :**
    /// - Le participant arrête SON tracking personnel
    /// - Les autres participants peuvent continuer
    /// - Si c'est le dernier participant actif, la session est terminée automatiquement
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur qui arrête
    ///   - finalDistance: Distance finale parcourue (en mètres)
    ///   - finalDuration: Durée totale du tracking (en secondes)
    /// - Throws: `SessionError` si la session n'existe pas
    func stopMyTracking(
        sessionId: String,
        userId: String,
        finalDistance: Double,
        finalDuration: TimeInterval
    ) async throws {
        Logger.log("🛑 Arrêt de MON tracking pour session: \(sessionId)", category: .session)
        
        // Utiliser la méthode existante
        try await endParticipantTracking(
            sessionId: sessionId,
            userId: userId,
            finalDistance: finalDistance,
            finalDuration: finalDuration
        )
        
        // Vérifier si tous les participants ont fini
        try await checkAndEndSessionIfComplete(sessionId: sessionId)
    }
    
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
    
    // MARK: - Heartbeat & Activity Tracking
    
    /// 🆕 Met à jour le heartbeat d'un participant (tracking actif)
    ///
    /// À appeler périodiquement (ex: toutes les 10s) par le TrackingManager
    /// pour indiquer que le participant est toujours actif.
    ///
    /// **Important :** Un coureur immobile qui envoie GPS/BPM reste actif.
    /// Seule l'absence totale de signal pendant > 60s déclenche l'inactivité.
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur
    ///   - location: Position GPS actuelle (optionnelle)
    ///   - heartRate: BPM actuel (optionnel)
    /// - Throws: `SessionError` si la session n'existe pas
    func updateParticipantHeartbeat(
        sessionId: String,
        userId: String,
        location: GeoPoint? = nil,
        heartRate: Double? = nil
    ) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        
        var updateData: [String: Any] = [
            "participantActivity.\(userId).lastUpdate": FieldValue.serverTimestamp(),
            "participantActivity.\(userId).isTracking": true,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let location = location {
            updateData["participantActivity.\(userId).lastLocation"] = location
        }
        
        if let heartRate = heartRate {
            updateData["participantActivity.\(userId).lastHeartRate"] = heartRate
        }
        
        try await sessionRef.updateData(updateData)
        
        // Logger verbose désactivé pour ne pas polluer les logs (appelé toutes les 10s)
        // Logger.log("💓 Heartbeat mis à jour pour \(userId)", category: .session)
    }
    
    /// 🆕 Met à jour l'activité d'un spectateur (pas de tracking)
    ///
    /// Indique qu'un utilisateur est présent dans la session mais ne tracke pas.
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - userId: ID de l'utilisateur spectateur
    /// - Throws: `SessionError` si la session n'existe pas
    func updateSpectatorActivity(
        sessionId: String,
        userId: String
    ) async throws {
        let sessionRef = db.collection("sessions").document(sessionId)
        
        try await sessionRef.updateData([
            "participantActivity.\(userId).lastUpdate": FieldValue.serverTimestamp(),
            "participantActivity.\(userId).isTracking": false,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        Logger.log("👁️ Spectateur \(userId) mis à jour", category: .session)
    }
    
    /// 🆕 Détecte et marque les participants inactifs (> 60s sans signal)
    ///
    /// À appeler périodiquement (ex: toutes les 30s) par un timer ou une Cloud Function.
    /// Si le dernier coureur actif devient inactif, termine automatiquement la session.
    ///
    /// - Parameter sessionId: ID de la session à vérifier
    /// - Throws: `SessionError` si la session n'existe pas
    func checkInactiveParticipants(sessionId: String) async throws {
        Logger.log("🔍 Vérification des participants inactifs: \(sessionId)", category: .session)
        
        let sessionRef = db.collection("sessions").document(sessionId)
        let document = try await sessionRef.getDocument()
        
        guard let session = try? document.data(as: SessionModel.self) else {
            throw SessionError.invalidSession
        }
        
        // Obtenir la liste des participants inactifs
        let inactiveIds = session.inactiveParticipantIds
        
        if !inactiveIds.isEmpty {
            Logger.log("⚠️ Participants inactifs détectés: \(inactiveIds)", category: .session)
            
            // Marquer chaque participant inactif comme "abandonné"
            for userId in inactiveIds {
                // Vérifier s'il était en tracking
                if session.participantActivity(for: userId)?.isTracking == true {
                    Logger.log("❌ Participant \(userId) marqué comme abandonné (inactivité)", category: .session)
                    
                    try? await sessionRef.updateData([
                        "participantStates.\(userId).status": ParticipantStatus.abandoned.rawValue,
                        "participantStates.\(userId).endedAt": FieldValue.serverTimestamp()
                    ])
                }
            }
        }
        
        // Vérifier si tous les participants tracking sont inactifs
        if session.allTrackingParticipantsInactive {
            Logger.log("🏁 Tous les participants tracking sont inactifs → fin automatique", category: .session)
            try await endSession(sessionId: sessionId)
        } else {
            let activeCount = session.activeTrackingParticipantsCount
            let spectatorCount = session.spectatorCount
            Logger.log("ℹ️ Session continue : \(activeCount) coureur(s), \(spectatorCount) spectateur(s)", category: .session)
        }
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
        
        // 🆕 Utiliser la nouvelle logique avec heartbeat
        if session.allTrackingParticipantsInactive {
            Logger.log("✅ Tous les participants tracking sont inactifs, fin automatique de session", category: .session)
            try await endSession(sessionId: sessionId)
        } else {
            let activeCount = session.activeTrackingParticipantsCount
            let spectatorCount = session.spectatorCount
            Logger.log("ℹ️ Session continue : \(activeCount) coureur(s), \(spectatorCount) spectateur(s)", category: .session)
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
            // 🛡️ SÉCURITÉ : Ne JAMAIS supprimer une session corrompue
            // Avec le nouveau décodeur gracieux, ce cas ne devrait plus arriver
            Logger.log("❌ Session corrompue détectée - Impossible de terminer", category: .session)
            Logger.log("   💡 Vérifiez SessionModel.init(from:) pour ajouter les champs manquants", category: .session)
            throw SessionError.invalidSession
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(session.startedAt)
        let squadId = session.squadId
        
        Logger.log("📝 Lancement fin de session \(sessionId) - durée: \(duration)s", category: .session)
        
        // 🚀 OPTIMISATION 2: Fire-and-forget pour la mise à jour Firestore
        // On lance l'opération SANS attendre la réponse
        Task { @MainActor [weak self] in
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
        Task { @MainActor [weak self] in
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
        Task { @MainActor [weak self] in
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
        Task { @MainActor [weak self] in
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
        Task { @MainActor [weak self] in
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
            .whereField("status", in: [
                SessionStatus.scheduled.rawValue,  // ✅ Sessions en attente
                SessionStatus.active.rawValue,      // ✅ Sessions en cours
                SessionStatus.paused.rawValue       // ✅ Sessions en pause
            ])
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
                .whereField("status", in: [
                    SessionStatus.scheduled.rawValue,  // ✅ Sessions en attente
                    SessionStatus.active.rawValue,      // ✅ Sessions en cours
                    SessionStatus.paused.rawValue       // ✅ Sessions en pause
                ])
            
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
                .whereField("status", in: [
                    SessionStatus.scheduled.rawValue,  // ✅ Sessions en attente
                    SessionStatus.active.rawValue,      // ✅ Sessions en cours
                    SessionStatus.paused.rawValue       // ✅ Sessions en pause
                ])
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
                    print("   🔑 Document ID depuis Firestore: \(doc.documentID)")
                    
                    do {
                        let session = try doc.data(as: SessionModel.self)
                        print("✅ Session décodée:")
                        print("   - ID après décodage: \(session.id ?? "❌ NIL")")
                        print("   - Document ID: \(doc.documentID)")
                        print("   - Status: \(session.status.rawValue)")
                        
                        if session.id == nil {
                            print("⚠️⚠️ PROBLÈME : L'ID est NIL après décodage !")
                            print("   - Firebase a fourni l'ID: \(doc.documentID)")
                            print("   - Mais @DocumentID ne l'a pas capturé")
                            print("   - Vérifier SessionModel.CodingKeys")
                        }
                        
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
            .whereField("status", in: [
                SessionStatus.scheduled.rawValue,  // ✅ Sessions en attente
                SessionStatus.active.rawValue,      // ✅ Sessions en cours
                SessionStatus.paused.rawValue       // ✅ Sessions en pause
            ])
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
        Logger.log("[AUDIT-SS-01] 📚 SessionService.getAllSessions - squadId: \(squadId)", category: .service)
        
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .order(by: "startedAt", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        let sessions = snapshot.documents.compactMap { try? $0.data(as: SessionModel.self) }
        
        Logger.logSuccess("✅ \(sessions.count) sessions totales récupérées", category: .service)
        return sessions
    }
    
    /// 🆕 Récupère toutes les sessions actives pour un utilisateur (tous ses squads)
    func getAllActiveSessions(userId: String) async throws -> [SessionModel] {
        Logger.log("[AUDIT-SS-02] 🌍 SessionService.getAllActiveSessions - userId: \(userId)", category: .service)
        
        // 1. Récupérer tous les squads de l'utilisateur
        let squadsSnapshot = try await db.collection("squads")
            .whereField("members.\(userId)", isNotEqualTo: NSNull())
            .getDocuments()
        
        let squadIds = squadsSnapshot.documents.compactMap { $0.documentID }
        
        guard !squadIds.isEmpty else {
            Logger.log("⚠️ Aucun squad trouvé pour cet utilisateur", category: .service)
            return []
        }
        
        Logger.log("🔍 Recherche de sessions actives dans \(squadIds.count) squads", category: .service)
        
        // 2. Récupérer toutes les sessions actives de ces squads
        // 🆕 INCLURE SCHEDULED : Une session en attente de démarrage doit être visible
        let sessionsSnapshot = try await db.collection("sessions")
            .whereField("squadId", in: squadIds)
            .whereField("status", in: [
                SessionStatus.scheduled.rawValue,  // ✅ Sessions en attente
                SessionStatus.active.rawValue,      // ✅ Sessions en cours
                SessionStatus.paused.rawValue       // ✅ Sessions en pause
            ])
            .order(by: "startedAt", descending: true)
            .getDocuments()
        
        let sessions = sessionsSnapshot.documents.compactMap { try? $0.data(as: SessionModel.self) }
        
        Logger.logSuccess("✅ \(sessions.count) sessions actives trouvées (scheduled/active/paused)", category: .service)
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
