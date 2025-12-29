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
    
    // Statistiques
    var totalDistanceMeters: Double
    var durationSeconds: TimeInterval
    var averageSpeed: Double
    var startLocation: GeoPoint?
    var messageCount: Int
    
    // Champs optionnels
    var targetDistanceMeters: Double?
    var title: String?
    var notes: String?
    var activityType: ActivityType
    
    // 🆕 NOUVEAUX CHAMPS - Refonte Incrément 3
    var runType: RunType?
    var visibility: SessionVisibility?
    var isJoinable: Bool?
    var maxParticipants: Int?
    
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
        totalDistanceMeters: Double = 0,
        durationSeconds: TimeInterval = 0,
        averageSpeed: Double = 0,
        startLocation: GeoPoint? = nil,
        messageCount: Int = 0,
        targetDistanceMeters: Double? = nil,
        title: String? = nil,
        notes: String? = nil,
        activityType: ActivityType = .training,
        runType: RunType? = .solo,
        visibility: SessionVisibility? = .squad,
        isJoinable: Bool? = true,
        maxParticipants: Int? = nil,
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
        self.title = title
        self.notes = notes
        self.activityType = activityType
        self.runType = runType
        self.visibility = visibility
        self.isJoinable = isJoinable
        self.maxParticipants = maxParticipants
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }
    
    // ✅ @DocumentID gère automatiquement l'ID
    // ✅ Pas de CodingKeys personnalisé
    // ✅ Pas de init(from:) / encode(to:) personnalisé
    
    // MARK: - Computed Properties (Logique métier)
    
    var isActive: Bool { status == .active }
    var isPaused: Bool { status == .paused }
    var isEnded: Bool { status == .ended }
    
    var distanceInKilometers: Double { totalDistanceMeters / 1000.0 }
    
    var formattedDuration: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        let seconds = Int(durationSeconds) % 60
        return hours > 0 ? String(format: "%02d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
    }
    
    var averageSpeedKmh: Double { averageSpeed * 3.6 }
    
    var averagePaceMinPerKm: String {
        guard averageSpeed > 0 else { return "--:--" }
        let minutesPerKm = (1000.0 / averageSpeed) / 60.0
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Hashable Implementation
    static func == (lhs: SessionModel, rhs: SessionModel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Enums

enum SessionStatus: String, Codable {
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

