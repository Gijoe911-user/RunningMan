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
    
    private enum CodingKeys: String, CodingKey {
        case id
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
    
    // MARK: - Codable (Automatic Synthesis)
    // ✅ Plus besoin de décodeur/encodeur custom !
    // Les computed properties gèrent automatiquement les valeurs par défaut
    
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

