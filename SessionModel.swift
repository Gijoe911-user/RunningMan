//
//  SessionModel.swift
//  RunningMan
//
//  Created by AI Assistant on 24/12/2025.
//

import Foundation
import FirebaseFirestore

/// Modèle représentant une session de course
/// Collection Firestore : `sessions/{sessionId}`
struct SessionModel: Identifiable, Codable {
    
    /// ID unique de la session
    @DocumentID var id: String?
    
    /// ID de la squad associée
    var squadId: String
    
    /// ID du créateur de la session
    var creatorId: String
    
    /// Date et heure de début de la session
    var startedAt: Date
    
    /// Date et heure de fin de la session (nil si en cours)
    var endedAt: Date?
    
    /// Statut actuel de la session
    var status: SessionStatus
    
    /// Liste des participants (userIds)
    var participants: [String]
    
    /// Distance totale parcourue par le groupe (en mètres)
    var totalDistanceMeters: Double
    
    /// Durée totale de la session (en secondes)
    var durationSeconds: TimeInterval
    
    /// Objectif de distance (optionnel, en mètres)
    var targetDistanceMeters: Double?
    
    /// Titre de la session (optionnel)
    var title: String?
    
    /// Notes ou description de la session
    var notes: String?
    
    /// Type de session
    var sessionType: SessionType
    
    // MARK: - Initialisation
    
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
        targetDistanceMeters: Double? = nil,
        title: String? = nil,
        notes: String? = nil,
        sessionType: SessionType = .training
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
        self.targetDistanceMeters = targetDistanceMeters
        self.title = title
        self.notes = notes
        self.sessionType = sessionType
    }
}

// MARK: - SessionStatus

/// Statut d'une session de course
enum SessionStatus: String, Codable {
    case active = "ACTIVE"      // Session en cours
    case paused = "PAUSED"      // Session en pause
    case ended = "ENDED"        // Session terminée
}

// MARK: - SessionType

/// Type de session
enum SessionType: String, Codable {
    case training = "TRAINING"        // Entraînement
    case race = "RACE"               // Course/Marathon
    case casual = "CASUAL"           // Course décontractée
}

// MARK: - Helper Extensions

extension SessionModel {
    
    /// Durée formatée (HH:MM:SS)
    var formattedDuration: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        let seconds = Int(durationSeconds) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Distance formatée en km
    var formattedDistance: String {
        let km = totalDistanceMeters / 1000.0
        return String(format: "%.2f km", km)
    }
    
    /// Vitesse moyenne (km/h)
    var averageSpeed: Double {
        guard durationSeconds > 0 else { return 0 }
        let hours = durationSeconds / 3600.0
        let km = totalDistanceMeters / 1000.0
        return km / hours
    }
    
    /// Vitesse moyenne formatée
    var formattedAverageSpeed: String {
        return String(format: "%.2f km/h", averageSpeed)
    }
    
    /// Allure moyenne (min/km)
    var averagePace: Double {
        guard totalDistanceMeters > 0 else { return 0 }
        let km = totalDistanceMeters / 1000.0
        let minutes = durationSeconds / 60.0
        return minutes / km
    }
    
    /// Allure moyenne formatée (mm:ss/km)
    var formattedAveragePace: String {
        let minutes = Int(averagePace)
        let seconds = Int((averagePace - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    /// Vérifie si la session est active
    var isActive: Bool {
        status == .active
    }
    
    /// Vérifie si la session est terminée
    var isEnded: Bool {
        status == .ended
    }
    
    /// Nombre de participants
    var participantCount: Int {
        participants.count
    }
    
    /// Ajoute un participant
    mutating func addParticipant(userId: String) {
        if !participants.contains(userId) {
            participants.append(userId)
        }
    }
    
    /// Retire un participant
    mutating func removeParticipant(userId: String) {
        participants.removeAll { $0 == userId }
    }
    
    /// Vérifie si un utilisateur participe
    func isParticipant(userId: String) -> Bool {
        participants.contains(userId)
    }
    
    /// Met à jour la durée (appelé régulièrement pendant la session)
    mutating func updateDuration() {
        guard status == .active else { return }
        durationSeconds = Date().timeIntervalSince(startedAt)
    }
}

// MARK: - SessionStats

/// Statistiques détaillées d'une session (pour affichage)
struct SessionStats: Codable {
    var sessionId: String
    var totalDistance: Double
    var duration: TimeInterval
    var averageSpeed: Double
    var averagePace: Double
    var maxSpeed: Double
    var participantCount: Int
    var startedAt: Date
    var endedAt: Date?
}


struct LiveFeedItem: Identifiable, Codable {
    @DocumentID var id: String?
    var type: FeedItemType // .audio, .photo, .cheer, .info
    var senderId: String
    var senderName: String
    var contentUrl: String? // URL vers Firebase Storage (vocal ou photo)
    var message: String?
    var timestamp: Date
    var location: GeoPoint? // Où l'item a été créé
    
    enum FeedItemType: String, Codable {
        case audio, photo, cheer, info
    }
}
