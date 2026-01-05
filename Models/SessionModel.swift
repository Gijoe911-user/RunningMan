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
    
    // MARK: - Properties
    
    @DocumentID var id: String?
    var squadId: String
    var creatorId: String
    var startedAt: Date
    var endedAt: Date?
    var status: SessionStatus
    var participants: [String]
    
    // Statistiques (tous optionnels pour rétrocompatibilité totale)
    var totalDistanceMeters: Double?
    var durationSeconds: TimeInterval?
    var averageSpeed: Double?
    var startLocation: GeoPoint?
    var messageCount: Int?
    
    // Champs optionnels
    var targetDistanceMeters: Double?
    var targetDuration: TimeInterval?  // 🆕 Durée cible pour la session (en secondes)
    var title: String?
    var notes: String?
    var activityType: ActivityType  // Avec défaut .training si absent
    
    // 🆕 Programme d'entraînement associé
    var trainingProgramId: String?
    
    // 🆕 Localisation de la session (pour identifier où se retrouver)
    var meetingLocationName: String?        // Ex: "Parc de la Tête d'Or, Lyon"
    var meetingLocationCoordinate: GeoPoint?  // Coordonnées du lieu de RDV
    
    // 🆕 NOUVEAUX CHAMPS - Refonte Incrément 3 (tous optionnels)
    var runType: RunType?
    var visibility: SessionVisibility?
    var isJoinable: Bool?
    var maxParticipants: Int?
    
    // 🆕 Gestion des états individuels des participants
    /// État de chaque participant dans la session
    /// Key: userId, Value: état du participant
    var participantStates: [String: ParticipantSessionState]?
    
    // 🆕 HEARTBEAT - Tracking de l'activité des participants
    /// Dernière activité de chaque participant (timestamp + état tracking/spectateur)
    /// Key: userId, Value: dernière mise à jour
    var participantActivity: [String: ParticipantActivity]?
    
    var createdAt: Date?
    var updatedAt: Date?
    
    // MARK: - Initialization
    
    init(
        id: String? = nil,
        squadId: String,
        creatorId: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        status: SessionStatus = .active,
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
        runType: RunType? = .solo,
        visibility: SessionVisibility? = .squad,
        isJoinable: Bool? = true,
        maxParticipants: Int? = nil,
        participantStates: [String: ParticipantSessionState]? = nil,
        participantActivity: [String: ParticipantActivity]? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.squadId = squadId
        self.creatorId = creatorId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.status = status
        self.participants = participants
        self.totalDistanceMeters = totalDistanceMeters
        self.durationSeconds = durationSeconds
        self.averageSpeed = averageSpeed
        self.startLocation = startLocation
        self.messageCount = messageCount
        self.targetDistanceMeters = targetDistanceMeters
        self.targetDuration = targetDuration
        self.title = title
        self.notes = notes
        self.activityType = activityType
        self.trainingProgramId = trainingProgramId
        self.meetingLocationName = meetingLocationName
        self.meetingLocationCoordinate = meetingLocationCoordinate
        self.runType = runType
        self.visibility = visibility
        self.isJoinable = isJoinable
        self.maxParticipants = maxParticipants
        self.participantStates = participantStates
        self.participantActivity = participantActivity
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }
    
    
    // MARK: - CodingKeys
    
    private enum CodingKeys: String, CodingKey {
        case id
        case squadId
        case creatorId
        case startedAt
        case endedAt
        case status
        case participants
        case totalDistanceMeters
        case durationSeconds
        case averageSpeed
        case startLocation
        case messageCount
        case targetDistanceMeters
        case targetDuration
        case title
        case notes
        case activityType
        case trainingProgramId
        case meetingLocationName
        case meetingLocationCoordinate
        case runType
        case visibility
        case isJoinable
        case maxParticipants
        case participantStates
        case participantActivity
        case createdAt
        case updatedAt
    }
    
    // MARK: - Custom Decoder (Graceful Decoding)
    
    /// 🛡️ Décodeur custom ultra-résilient
    ///
    /// Utilise `decodeIfPresent` pour TOUS les champs (sauf les 2 essentiels).
    /// Garantit zéro crash même si Firestore contient des données corrompues.
    ///
    /// **Champs strictement requis :**
    /// - `squadId` : Nécessaire pour identifier la squad
    /// - `creatorId` : Nécessaire pour les permissions
    ///
    /// **Tous les autres champs :** Valeurs par défaut si absents
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 🔥 Champs strictement requis (crash si absents)
        squadId = try container.decode(String.self, forKey: .squadId)
        creatorId = try container.decode(String.self, forKey: .creatorId)
        
        // 🆕 TOUS les autres champs utilisent decodeIfPresent
        // Note: @DocumentID est géré automatiquement par Firestore
        // On ne le décode PAS manuellement ici
        
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? Date()
        endedAt = try container.decodeIfPresent(Date.self, forKey: .endedAt)
        status = try container.decodeIfPresent(SessionStatus.self, forKey: .status) ?? .scheduled
        participants = try container.decodeIfPresent([String].self, forKey: .participants) ?? []
        
        // Statistiques
        totalDistanceMeters = try container.decodeIfPresent(Double.self, forKey: .totalDistanceMeters)
        durationSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .durationSeconds)
        averageSpeed = try container.decodeIfPresent(Double.self, forKey: .averageSpeed)
        startLocation = try container.decodeIfPresent(GeoPoint.self, forKey: .startLocation)
        messageCount = try container.decodeIfPresent(Int.self, forKey: .messageCount)
        
        // Champs optionnels
        targetDistanceMeters = try container.decodeIfPresent(Double.self, forKey: .targetDistanceMeters)
        targetDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .targetDuration)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        activityType = try container.decodeIfPresent(ActivityType.self, forKey: .activityType) ?? .training
        
        // Programme et localisation
        trainingProgramId = try container.decodeIfPresent(String.self, forKey: .trainingProgramId)
        meetingLocationName = try container.decodeIfPresent(String.self, forKey: .meetingLocationName)
        meetingLocationCoordinate = try container.decodeIfPresent(GeoPoint.self, forKey: .meetingLocationCoordinate)
        
        // Nouveaux champs Refonte Incrément 3
        runType = try container.decodeIfPresent(RunType.self, forKey: .runType)
        visibility = try container.decodeIfPresent(SessionVisibility.self, forKey: .visibility)
        isJoinable = try container.decodeIfPresent(Bool.self, forKey: .isJoinable)
        maxParticipants = try container.decodeIfPresent(Int.self, forKey: .maxParticipants)
        
        // États des participants
        participantStates = try container.decodeIfPresent([String: ParticipantSessionState].self, forKey: .participantStates)
        participantActivity = try container.decodeIfPresent([String: ParticipantActivity].self, forKey: .participantActivity)
        
        // Timestamps
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    // MARK: - Custom Encoder
    
    /// Encodeur custom pour synchroniser avec le décodeur
    ///
    /// Encode tous les champs (sauf `id` qui est géré par @DocumentID)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Note: @DocumentID gère automatiquement l'encodage de `id`
        // On ne l'encode PAS manuellement
        
        try container.encode(squadId, forKey: .squadId)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(endedAt, forKey: .endedAt)
        try container.encode(status, forKey: .status)
        try container.encode(participants, forKey: .participants)
        
        // Statistiques
        try container.encodeIfPresent(totalDistanceMeters, forKey: .totalDistanceMeters)
        try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
        try container.encodeIfPresent(averageSpeed, forKey: .averageSpeed)
        try container.encodeIfPresent(startLocation, forKey: .startLocation)
        try container.encodeIfPresent(messageCount, forKey: .messageCount)
        
        // Champs optionnels
        try container.encodeIfPresent(targetDistanceMeters, forKey: .targetDistanceMeters)
        try container.encodeIfPresent(targetDuration, forKey: .targetDuration)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(activityType, forKey: .activityType)
        
        // Programme et localisation
        try container.encodeIfPresent(trainingProgramId, forKey: .trainingProgramId)
        try container.encodeIfPresent(meetingLocationName, forKey: .meetingLocationName)
        try container.encodeIfPresent(meetingLocationCoordinate, forKey: .meetingLocationCoordinate)
        
        // Nouveaux champs Refonte Incrément 3
        try container.encodeIfPresent(runType, forKey: .runType)
        try container.encodeIfPresent(visibility, forKey: .visibility)
        try container.encodeIfPresent(isJoinable, forKey: .isJoinable)
        try container.encodeIfPresent(maxParticipants, forKey: .maxParticipants)
        
        // États des participants
        try container.encodeIfPresent(participantStates, forKey: .participantStates)
        try container.encodeIfPresent(participantActivity, forKey: .participantActivity)
        
        // Timestamps
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
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
    static func == (lhs: SessionModel, rhs: SessionModel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
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
    var distance: Double = 0
    var duration: TimeInterval = 0
    var averageSpeed: Double = 0
    var maxSpeed: Double = 0
    var locationPointsCount: Int = 0
    var joinedAt: Date = Date()
    var leftAt: Date?
    
    // 🆕 HealthKit - Données biométriques
    var currentHeartRate: Double?  // BPM actuel
    var averageHeartRate: Double?  // BPM moyen
    var maxHeartRate: Double?      // BPM max
    var minHeartRate: Double?      // BPM min
    var calories: Double?          // Calories brûlées
    var heartRateUpdatedAt: Date?  // Dernière mise à jour
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

