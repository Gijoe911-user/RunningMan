//
//  SessionModel.swift
//  RunningMan
//
//  Created by AI Assistant on 24/12/2025.
//

import Foundation
import FirebaseFirestore

/// Modèle représentant une session de course
struct SessionModel: Identifiable, Codable, Hashable {
    
    // MARK: - Properties (Stored Properties - Toutes optionnelles pour Firestore)
    
    @DocumentID var id: String?
    var manualId: String? // 🔥 Champ de secours si @DocumentID échoue
    
    /// ID réel garanti (ne sera jamais nil si au moins un des deux existe)
    var realId: String {
        return id ?? manualId ?? "ID_MANQUANT"
    }
    
    var squadId: String
    var creatorId: String
    
    // Propriétés principales (optionnelles pour décodage gracieux)
    private var _startedAt: Date?
    private var _status: SessionStatus?
    private var _participants: [String]?
    
    var endedAt: Date?
    
    // Statistiques (tous optionnels pour rétrocompatibilité totale)
    var totalDistanceMeters: Double?
    var durationSeconds: TimeInterval?
    var averageSpeed: Double?
    var startLocation: GeoPoint?
    var messageCount: Int?
    
    // Champs optionnels
    var targetDistanceMeters: Double?
    var targetDuration: TimeInterval?
    var title: String?
    var notes: String?
    
    private var _activityType: ActivityType?
    
    // 🆕 Programme d'entraînement associé
    var trainingProgramId: String?
    
    // 🆕 Localisation de la session (pour identifier où se retrouver)
    var meetingLocationName: String?
    var meetingLocationCoordinate: GeoPoint?
    
    // 🆕 NOUVEAUX CHAMPS - Refonte Incrément 3 (tous optionnels)
    private var _runType: RunType?
    private var _visibility: SessionVisibility?
    private var _isJoinable: Bool?
    
    var maxParticipants: Int?
    
    // 🆕 Gestion des états individuels des participants
    /// État de chaque participant dans la session
    /// Key: userId, Value: état du participant
    var participantStates: [String: ParticipantSessionState]?
    
    // 🆕 HEARTBEAT - Tracking de l'activité des participants
    /// Dernière activité de chaque participant (timestamp + état tracking/spectateur)
    /// Key: userId, Value: dernière mise à jour
    var participantActivity: [String: ParticipantActivity]?
    
    private var _createdAt: Date?
    private var _updatedAt: Date?
    
    // MARK: - Computed Properties (Valeurs par défaut)
    
    /// Date de début de la session (défaut: Date actuelle)
    var startedAt: Date {
        get { _startedAt ?? Date() }
        set { _startedAt = newValue }
    }
    
    /// Statut de la session (défaut: .scheduled)
    var status: SessionStatus {
        get { _status ?? .scheduled }
        set { _status = newValue }
    }
    
    /// Liste des participants (défaut: tableau vide)
    var participants: [String] {
        get { _participants ?? [] }
        set { _participants = newValue }
    }
    
    /// Type d'activité (défaut: .training)
    var activityType: ActivityType {
        get { _activityType ?? .training }
        set { _activityType = newValue }
    }
    
    /// Type de run (défaut: .solo)
    var runType: RunType {
        get { _runType ?? .solo }
        set { _runType = newValue }
    }
    
    /// Visibilité de la session (défaut: .squad)
    var visibility: SessionVisibility {
        get { _visibility ?? .squad }
        set { _visibility = newValue }
    }
    
    /// Indique si la session est ouverte aux nouveaux participants (défaut: true)
    var isJoinable: Bool {
        get { _isJoinable ?? true }
        set { _isJoinable = newValue }
    }
    
    /// Date de création (défaut: Date actuelle)
    var createdAt: Date {
        get { _createdAt ?? Date() }
        set { _createdAt = newValue }
    }
    
    /// Date de dernière mise à jour (défaut: Date actuelle)
    var updatedAt: Date {
        get { _updatedAt ?? Date() }
        set { _updatedAt = newValue }
    }
    
    // MARK: - Initialization
    
    init(
        id: String? = nil,
        manualId: String? = nil,
        squadId: String,
        creatorId: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        status: SessionStatus = .scheduled,
        participants: [String] = [],
        totalDistanceMeters: Double? = nil,
        durationSeconds: TimeInterval? = nil,
        averageSpeed: Double? = nil,
        startLocation: GeoPoint? = nil,
        messageCount: Int? = nil,
        targetDistanceMeters: Double? = nil,
        targetDuration: TimeInterval? = nil,
        title: String? = nil,
        notes: String? = nil,
        activityType: ActivityType = .training,
        trainingProgramId: String? = nil,
        meetingLocationName: String? = nil,
        meetingLocationCoordinate: GeoPoint? = nil,
        runType: RunType = .solo,
        visibility: SessionVisibility = .squad,
        isJoinable: Bool = true,
        maxParticipants: Int? = nil,
        participantStates: [String: ParticipantSessionState]? = nil,
        participantActivity: [String: ParticipantActivity]? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.manualId = manualId
        self.squadId = squadId
        self.creatorId = creatorId
        self._startedAt = startedAt
        self.endedAt = endedAt
        self._status = status
        self._participants = participants
        self.totalDistanceMeters = totalDistanceMeters
        self.durationSeconds = durationSeconds
        self.averageSpeed = averageSpeed
        self.startLocation = startLocation
        self.messageCount = messageCount
        self.targetDistanceMeters = targetDistanceMeters
        self.targetDuration = targetDuration
        self.title = title
        self.notes = notes
        self._activityType = activityType
        self.trainingProgramId = trainingProgramId
        self.meetingLocationName = meetingLocationName
        self.meetingLocationCoordinate = meetingLocationCoordinate
        self._runType = runType
        self._visibility = visibility
        self._isJoinable = isJoinable
        self.maxParticipants = maxParticipants
        self.participantStates = participantStates
        self.participantActivity = participantActivity
        self._createdAt = createdAt ?? Date()
        self._updatedAt = updatedAt ?? Date()
    }
    
    
    // MARK: - CodingKeys
    
    /// ⚠️ IMPORTANT : 'manualId' mappe aussi le champ 'id' de Firestore comme secours
    private enum CodingKeys: String, CodingKey {
        // @DocumentID gère 'id' automatiquement, mais on ajoute manualId comme backup
        case manualId = "id"  // 🔥 Champ de secours mappé sur "id" dans Firestore
        case squadId
        case creatorId
        case _startedAt = "startedAt"
        case endedAt
        case _status = "status"
        case _participants = "participants"
        case totalDistanceMeters
        case durationSeconds
        case averageSpeed
        case startLocation
        case messageCount
        case targetDistanceMeters
        case targetDuration
        case title
        case notes
        case _activityType = "activityType"
        case trainingProgramId
        case meetingLocationName
        case meetingLocationCoordinate
        case _runType = "runType"
        case _visibility = "visibility"
        case _isJoinable = "isJoinable"
        case maxParticipants
        case participantStates
        case participantActivity
        case _createdAt = "createdAt"
        case _updatedAt = "updatedAt"
    }
    
    // MARK: - Codable (Custom Implementation for Graceful Decoding)
    
    /// Décodeur custom ultra-tolérant : tous les champs sont optionnels sauf squadId et creatorId
    /// ⚠️ **IMPORTANT : L'ID est décodé via @DocumentID ET manualId pour double sécurité**
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Diagnostic détaillé en cas d'erreur
        do {
            // 🔥 Décoder manualId comme backup (mappe sur le champ "id" de Firestore)
            manualId = try container.decodeIfPresent(String.self, forKey: .manualId)
            
            // ⚠️ @DocumentID injecte automatiquement l'ID après notre init()
            // Si ça échoue, on aura au moins manualId
            
            // Champs REQUIS (avec diagnostic d'erreur)
            guard let decodedSquadId = try container.decodeIfPresent(String.self, forKey: .squadId) else {
                print("❌ ERREUR DÉCODAGE : squadId manquant")
                throw DecodingError.keyNotFound(
                    CodingKeys.squadId,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "squadId est requis")
                )
            }
            squadId = decodedSquadId
            
            guard let decodedCreatorId = try container.decodeIfPresent(String.self, forKey: .creatorId) else {
                print("❌ ERREUR DÉCODAGE : creatorId manquant")
                throw DecodingError.keyNotFound(
                    CodingKeys.creatorId,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "creatorId est requis")
                )
            }
            creatorId = decodedCreatorId
            
            // Tous les autres champs sont OPTIONNELS avec decodeIfPresent
            _startedAt = try container.decodeIfPresent(Date.self, forKey: ._startedAt)
            _status = try container.decodeIfPresent(SessionStatus.self, forKey: ._status)
            _participants = try container.decodeIfPresent([String].self, forKey: ._participants)
            
            endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
            
            // Stats (tous optionnels)
            totalDistanceMeters = try container.decodeIfPresent(Double.self, forKey: .totalDistanceMeters)
            durationSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .durationSeconds)
            averageSpeed = try container.decodeIfPresent(Double.self, forKey: .averageSpeed)
            startLocation = try container.decodeIfPresent(GeoPoint.self, forKey: .startLocation)
            messageCount = try container.decodeIfPresent(Int.self, forKey: .messageCount)
            
            // Target
            targetDistanceMeters = try container.decodeIfPresent(Double.self, forKey: .targetDistanceMeters)
            targetDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .targetDuration)
            title = try container.decodeIfPresent(String.self, forKey: .title)
            notes = try container.decodeIfPresent(String.self, forKey: .notes)
            
            _activityType = try container.decodeIfPresent(ActivityType.self, forKey: ._activityType)
            
            // Training
            trainingProgramId = try container.decodeIfPresent(String.self, forKey: .trainingProgramId)
            
            // Location
            meetingLocationName = try container.decodeIfPresent(String.self, forKey: .meetingLocationName)
            meetingLocationCoordinate = try container.decodeIfPresent(GeoPoint.self, forKey: .meetingLocationCoordinate)
            
            // Run type & visibility
            _runType = try container.decodeIfPresent(RunType.self, forKey: ._runType)
            _visibility = try container.decodeIfPresent(SessionVisibility.self, forKey: ._visibility)
            _isJoinable = try container.decodeIfPresent(Bool.self, forKey: ._isJoinable)
            
            maxParticipants = try container.decodeIfPresent(Int.self, forKey: .maxParticipants)
            
            // États participants (optionnels)
            participantStates = try container.decodeIfPresent([String: ParticipantSessionState].self, forKey: .participantStates)
            participantActivity = try container.decodeIfPresent([String: ParticipantActivity].self, forKey: .participantActivity)
            
            // Timestamps
            _createdAt = try container.decodeIfPresent(Date.self, forKey: ._createdAt)
            _updatedAt = try container.decodeIfPresent(Date.self, forKey: ._updatedAt)
            
        } catch let error as DecodingError {
            // Log détaillé de l'erreur
            switch error {
            case .keyNotFound(let key, let context):
                print("❌ ERREUR DÉCODAGE SessionModel : Clé manquante '\(key.stringValue)'")
                print("   Context: \(context.debugDescription)")
                print("   CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .typeMismatch(let type, let context):
                print("❌ ERREUR DÉCODAGE SessionModel : Type incompatible pour '\(type)'")
                print("   Context: \(context.debugDescription)")
                print("   CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("❌ ERREUR DÉCODAGE SessionModel : Valeur manquante pour type '\(type)'")
                print("   Context: \(context.debugDescription)")
                print("   CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("❌ ERREUR DÉCODAGE SessionModel : Données corrompues")
                print("   Context: \(context.debugDescription)")
                print("   CodingPath: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("❌ ERREUR DÉCODAGE SessionModel : Erreur inconnue - \(error)")
            }
            throw error
        } catch {
            print("❌ ERREUR DÉCODAGE SessionModel (autre) : \(error)")
            throw error
        }
    }
    
    /// Encodeur custom pour sauvegarder uniquement les valeurs non-nil
    /// ⚠️ L'ID n'est pas encodé car @DocumentID le gère automatiquement
    /// Mais on encode manualId comme backup
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // ⚠️ Ne PAS encoder l'ID - Firebase/Firestore le gère via @DocumentID
        // Mais on encode manualId pour assurer la persistance
        try container.encodeIfPresent(manualId, forKey: .manualId)
        
        // Champs requis
        try container.encode(squadId, forKey: .squadId)
        try container.encode(creatorId, forKey: .creatorId)
        
        // Champs optionnels (encoder seulement si non-nil)
        try container.encodeIfPresent(_startedAt, forKey: ._startedAt)
        try container.encodeIfPresent(_status, forKey: ._status)
        try container.encodeIfPresent(_participants, forKey: ._participants)
        
        try container.encodeIfPresent(endedAt, forKey: .endedAt)
        
        try container.encodeIfPresent(totalDistanceMeters, forKey: .totalDistanceMeters)
        try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
        try container.encodeIfPresent(averageSpeed, forKey: .averageSpeed)
        try container.encodeIfPresent(startLocation, forKey: .startLocation)
        try container.encodeIfPresent(messageCount, forKey: .messageCount)
        
        try container.encodeIfPresent(targetDistanceMeters, forKey: .targetDistanceMeters)
        try container.encodeIfPresent(targetDuration, forKey: .targetDuration)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        try container.encodeIfPresent(_activityType, forKey: ._activityType)
        
        try container.encodeIfPresent(trainingProgramId, forKey: .trainingProgramId)
        
        try container.encodeIfPresent(meetingLocationName, forKey: .meetingLocationName)
        try container.encodeIfPresent(meetingLocationCoordinate, forKey: .meetingLocationCoordinate)
        
        try container.encodeIfPresent(_runType, forKey: ._runType)
        try container.encodeIfPresent(_visibility, forKey: ._visibility)
        try container.encodeIfPresent(_isJoinable, forKey: ._isJoinable)
        
        try container.encodeIfPresent(maxParticipants, forKey: .maxParticipants)
        
        try container.encodeIfPresent(participantStates, forKey: .participantStates)
        try container.encodeIfPresent(participantActivity, forKey: .participantActivity)
        
        try container.encodeIfPresent(_createdAt, forKey: ._createdAt)
        try container.encodeIfPresent(_updatedAt, forKey: ._updatedAt)
    }
    
    // MARK: - Computed Properties (Logique métier)
    
    var isScheduled: Bool { status == .scheduled }
    var isActive: Bool { status == .active }
    var isPaused: Bool { status == .paused }
    var isEnded: Bool { status == .ended }
    
    var distanceInKilometers: Double { (totalDistanceMeters ?? 0) / 1000.0 }
    
    var formattedDuration: String {
        let duration: TimeInterval = durationSeconds ?? 0
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return hours > 0 ? String(format: "%02d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
    }
    
    var averageSpeedKmh: Double {
        let speed: Double = averageSpeed ?? 0
        return speed * 3.6
    }
    
    var averagePaceMinPerKm: String {
        guard let speed = averageSpeed, speed > 0 else { return "--:--" }
        let minutesPerKm = (1000.0 / speed) / 60.0
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Participant States
    
    /// Nombre de participants actuellement actifs (en course)
    var activeParticipantsCount: Int {
        participantStates?.values.filter { $0.status == .active }.count ?? 0
    }
    
    /// Nombre de participants en pause
    var pausedParticipantsCount: Int {
        participantStates?.values.filter { $0.status == .paused }.count ?? 0
    }
    
    /// Nombre de participants ayant terminé
    var finishedParticipantsCount: Int {
        participantStates?.values.filter { $0.status == .ended }.count ?? 0
    }
    
    /// Nombre de participants ayant abandonné
    var abandonedParticipantsCount: Int {
        participantStates?.values.filter { $0.status == .abandoned }.count ?? 0
    }
    
    /// Nombre total de participants ayant terminé ou abandonné
    var completedParticipantsCount: Int {
        finishedParticipantsCount + abandonedParticipantsCount
    }
    
    /// La session peut être terminée si tous les participants ont fini
    var canBeEnded: Bool {
        guard let states = participantStates, !states.isEmpty else {
            // Si pas d'états, on peut terminer (compatibilité avec anciennes sessions)
            return true
        }
        return states.values.allSatisfy { $0.hasFinished }
    }
    
    /// Indique si la session a au moins un participant actif
    var hasActiveParticipants: Bool {
        activeParticipantsCount > 0
    }
    
    /// État d'un participant spécifique
    /// - Parameter userId: ID de l'utilisateur
    /// - Returns: État du participant, ou nil s'il ne participe pas
    func participantState(for userId: String) -> ParticipantSessionState? {
        participantStates?[userId]
    }
    
    /// Vérifie si un utilisateur est actuellement actif dans la session
    /// - Parameter userId: ID de l'utilisateur
    /// - Returns: true si l'utilisateur est en course
    func isParticipantActive(_ userId: String) -> Bool {
        participantStates?[userId]?.isCurrentlyActive ?? false
    }
    
    // MARK: - Heartbeat & Activity Tracking
    
    /// Nombre de participants ACTUELLEMENT en train de tracker (pas spectateurs)
    var activeTrackingParticipantsCount: Int {
        participantActivity?.values.filter { $0.isTracking && !$0.isInactive }.count ?? 0
    }
    
    /// Nombre total de spectateurs (connectés mais pas en train de courir)
    var spectatorCount: Int {
        participantActivity?.values.filter { !$0.isTracking }.count ?? 0
    }
    
    /// Liste des IDs de participants inactifs (pas de signal depuis > 60s)
    var inactiveParticipantIds: [String] {
        guard let activity = participantActivity else { return [] }
        return activity.filter { $0.value.isInactive }.map { $0.key }
    }
    
    /// Vérifie si TOUS les participants tracking sont inactifs (session peut être terminée)
    var allTrackingParticipantsInactive: Bool {
        guard let activity = participantActivity, !activity.isEmpty else {
            // Si pas de données d'activité, utiliser l'ancienne logique
            return canBeEnded
        }
        
        // Filtrer uniquement les participants qui trackent
        let trackingParticipants = activity.values.filter { $0.isTracking }
        
        // Si aucun participant ne tracke, la session peut être terminée
        guard !trackingParticipants.isEmpty else { return true }
        
        // Tous les participants tracking doivent être inactifs
        return trackingParticipants.allSatisfy { $0.isInactive }
    }
    
    /// Obtient l'activité d'un participant spécifique
    func participantActivity(for userId: String) -> ParticipantActivity? {
        participantActivity?[userId]
    }
    
    /// Vérifie si un participant est considéré comme inactif (> 60s sans signal)
    func isParticipantInactive(_ userId: String) -> Bool {
        participantActivity?[userId]?.isInactive ?? false
    }

    // MARK: - Hashable Implementation
    static func == (lhs: SessionModel, rhs: SessionModel) -> Bool { 
        lhs.realId == rhs.realId 
    }
    func hash(into hasher: inout Hasher) { 
        hasher.combine(realId) 
    }
}

// MARK: - Enums

enum SessionStatus: String, Codable {
    case scheduled = "SCHEDULED"  // 🆕 Session créée mais pas encore démarrée
    case active = "ACTIVE"
    case paused = "PAUSED"
    case ended = "ENDED"
}

/// Type d'activité de la session (ancien sessionType renommé)
enum ActivityType: String, Codable, CaseIterable {
    case training = "TRAINING"
    case race = "RACE"
    case interval = "INTERVAL"
    case recovery = "RECOVERY"
    
    var displayName: String {
        switch self {
        case .training: return "Entraînement"
        case .race: return "Course"
        case .interval: return "Fractionné"
        case .recovery: return "Récupération"
        }
    }
    
    var icon: String {
        switch self {
        case .training: return "figure.run"
        case .race: return "trophy.fill"
        case .interval: return "waveform.path.ecg"
        case .recovery: return "leaf.fill"
        }
    }
}

/// 🆕 Type de run : Solo ou Groupe (Refonte Incrément 3)
enum RunType: String, Codable, CaseIterable {
    case solo = "SOLO"
    case group = "GROUP"
    
    var displayName: String {
        switch self {
        case .solo: return "Solo"
        case .group: return "Groupe"
        }
    }
    
    var icon: String {
        switch self {
        case .solo: return "person.fill"
        case .group: return "person.2.fill"
        }
    }
}

/// 🆕 Visibilité de la session (Refonte Incrément 3)
enum SessionVisibility: String, Codable, CaseIterable {
    case `private` = "PRIVATE"  // Invisible pour les autres
    case squad = "SQUAD"  // Visible par la squad
    
    var displayName: String {
        switch self {
        case .private: return "Privé"
        case .squad: return "Squad"
        }
    }
    
    var icon: String {
        switch self {
        case .private: return "lock.fill"
        case .squad: return "person.3.fill"
        }
    }
}

// MARK: - Participant Statistics

struct ParticipantStats: Codable {
    var userId: String
    var distance: Double
    var duration: TimeInterval
    var averageSpeed: Double
    var maxSpeed: Double
    var locationPointsCount: Int
    var joinedAt: Date
    var leftAt: Date?
    
    // 🆕 HealthKit - Données biométriques
    var currentHeartRate: Double?  // BPM actuel
    var averageHeartRate: Double?  // BPM moyen
    var maxHeartRate: Double?      // BPM max
    var minHeartRate: Double?      // BPM min
    var calories: Double?          // Calories brûlées
    var heartRateUpdatedAt: Date?  // Dernière mise à jour
    
    // MARK: - Codable (Graceful Decoding)
    
    private enum CodingKeys: String, CodingKey {
        case userId
        case distance
        case duration
        case averageSpeed
        case maxSpeed
        case locationPointsCount
        case joinedAt
        case leftAt
        case currentHeartRate
        case averageHeartRate
        case maxHeartRate
        case minHeartRate
        case calories
        case heartRateUpdatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Champs requis avec valeurs par défaut
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        distance = try container.decodeIfPresent(Double.self, forKey: .distance) ?? 0
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        averageSpeed = try container.decodeIfPresent(Double.self, forKey: .averageSpeed) ?? 0
        maxSpeed = try container.decodeIfPresent(Double.self, forKey: .maxSpeed) ?? 0
        locationPointsCount = try container.decodeIfPresent(Int.self, forKey: .locationPointsCount) ?? 0
        joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt) ?? Date()
        
        // Champs optionnels
        leftAt = try container.decodeIfPresent(Date.self, forKey: .leftAt)
        currentHeartRate = try container.decodeIfPresent(Double.self, forKey: .currentHeartRate)
        averageHeartRate = try container.decodeIfPresent(Double.self, forKey: .averageHeartRate)
        maxHeartRate = try container.decodeIfPresent(Double.self, forKey: .maxHeartRate)
        minHeartRate = try container.decodeIfPresent(Double.self, forKey: .minHeartRate)
        calories = try container.decodeIfPresent(Double.self, forKey: .calories)
        heartRateUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .heartRateUpdatedAt)
    }
    
    init(
        userId: String,
        distance: Double = 0,
        duration: TimeInterval = 0,
        averageSpeed: Double = 0,
        maxSpeed: Double = 0,
        locationPointsCount: Int = 0,
        joinedAt: Date = Date(),
        leftAt: Date? = nil,
        currentHeartRate: Double? = nil,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        minHeartRate: Double? = nil,
        calories: Double? = nil,
        heartRateUpdatedAt: Date? = nil
    ) {
        self.userId = userId
        self.distance = distance
        self.duration = duration
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.locationPointsCount = locationPointsCount
        self.joinedAt = joinedAt
        self.leftAt = leftAt
        self.currentHeartRate = currentHeartRate
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.minHeartRate = minHeartRate
        self.calories = calories
        self.heartRateUpdatedAt = heartRateUpdatedAt
    }
}

// MARK: - Location Point

struct LocationPoint: Codable {
    var userId: String
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var speed: Double
    var horizontalAccuracy: Double
    var timestamp: Date
    @ServerTimestamp var serverTimestamp: Timestamp?
    
    // MARK: - Codable (Graceful Decoding)
    
    private enum CodingKeys: String, CodingKey {
        case userId
        case latitude
        case longitude
        case altitude
        case speed
        case horizontalAccuracy
        case timestamp
        case serverTimestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Champs requis avec valeurs par défaut
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0
        altitude = try container.decodeIfPresent(Double.self, forKey: .altitude) ?? 0
        speed = try container.decodeIfPresent(Double.self, forKey: .speed) ?? 0
        horizontalAccuracy = try container.decodeIfPresent(Double.self, forKey: .horizontalAccuracy) ?? 0
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        serverTimestamp = try container.decodeIfPresent(Timestamp.self, forKey: .serverTimestamp)
    }
    
    init(
        userId: String,
        latitude: Double,
        longitude: Double,
        altitude: Double,
        speed: Double,
        horizontalAccuracy: Double,
        timestamp: Date,
        serverTimestamp: Timestamp? = nil
    ) {
        self.userId = userId
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speed = speed
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
        self.serverTimestamp = serverTimestamp
    }
}

// MARK: - Participant Activity (Heartbeat)

/// 🆕 Représente l'activité d'un participant dans une session
///
/// Utilisé pour le système de "heartbeat" qui détecte automatiquement
/// les participants inactifs (connexion perdue, app fermée, etc.)
///
/// **Logique d'inactivité :**
/// - Un participant est considéré inactif si `lastUpdate` > 60 secondes
/// - MAIS un coureur immobile qui envoie encore GPS/BPM reste actif
/// - Seul l'absence totale de signal déclenche l'inactivité
struct ParticipantActivity: Codable, Hashable {
    /// Date de la dernière activité (GPS, heartbeat, ou autre signal)
    var lastUpdate: Date
    
    /// Indique si le participant est en mode tracking (coureur) ou spectateur
    var isTracking: Bool
    
    /// Dernière position GPS connue (optionnelle)
    var lastLocation: GeoPoint?
    
    /// Dernier BPM connu (optionnel)
    var lastHeartRate: Double?
    
    // MARK: - Computed Properties
    
    /// Temps écoulé depuis la dernière activité (en secondes)
    var timeSinceLastUpdate: TimeInterval {
        Date().timeIntervalSince(lastUpdate)
    }
    
    /// Indique si le participant est considéré comme inactif (> 60s sans signal)
    var isInactive: Bool {
        timeSinceLastUpdate > 60
    }
    
    /// Indique si le participant est actif et en train de tracker
    var isActivelyTracking: Bool {
        isTracking && !isInactive
    }
    
    // MARK: - Initialization
    
    init(
        lastUpdate: Date = Date(),
        isTracking: Bool = false,
        lastLocation: GeoPoint? = nil,
        lastHeartRate: Double? = nil
    ) {
        self.lastUpdate = lastUpdate
        self.isTracking = isTracking
        self.lastLocation = lastLocation
        self.lastHeartRate = lastHeartRate
    }
    
    // MARK: - Codable (Graceful Decoding)
    
    private enum CodingKeys: String, CodingKey {
        case lastUpdate
        case isTracking
        case lastLocation
        case lastHeartRate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Champs avec valeurs par défaut si absents
        lastUpdate = try container.decodeIfPresent(Date.self, forKey: .lastUpdate) ?? Date()
        isTracking = try container.decodeIfPresent(Bool.self, forKey: .isTracking) ?? false
        lastLocation = try container.decodeIfPresent(GeoPoint.self, forKey: .lastLocation)
        lastHeartRate = try container.decodeIfPresent(Double.self, forKey: .lastHeartRate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(lastUpdate, forKey: .lastUpdate)
        try container.encode(isTracking, forKey: .isTracking)
        try container.encodeIfPresent(lastLocation, forKey: .lastLocation)
        try container.encodeIfPresent(lastHeartRate, forKey: .lastHeartRate)
    }
    
    // MARK: - Update Methods
    
    /// Met à jour le timestamp d'activité
    mutating func updateActivity() {
        lastUpdate = Date()
    }
    
    /// Met à jour avec une nouvelle position GPS
    mutating func updateLocation(_ location: GeoPoint) {
        lastUpdate = Date()
        lastLocation = location
    }
    
    /// Met à jour avec un nouveau BPM
    mutating func updateHeartRate(_ bpm: Double) {
        lastUpdate = Date()
        lastHeartRate = bpm
    }
    
    /// Bascule en mode tracking (coureur)
    mutating func startTracking() {
        isTracking = true
        lastUpdate = Date()
    }
    
    /// Bascule en mode spectateur
    mutating func stopTracking() {
        isTracking = false
        lastUpdate = Date()
    }
}

