//
//  SessionModels+Extensions.swift
//  RunningMan
//
//  Extensions et nouveaux types pour la refonte Sessions
//

import Foundation
import FirebaseFirestore

// NOTE: SessionType, SessionVisibility et RunType sont définis dans SessionModel.swift
// Ce fichier contient uniquement les extensions et types supplémentaires

// MARK: - Session Model Extension

extension SessionModel {
    /// Titre formaté pour affichage
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        
        // Génération automatique
        switch runType {
        case .solo:
            return "Run Solo"
        case .group:
            return "Run de Groupe"
        case .none:
            return "Spectateur"
        }
    }
    
    /// Indicateur de capacité (participants / max)
    var capacityText: String? {
        guard let maxParticipants = maxParticipants else {
            return nil
        }
        
        return "\(participants.count)/\(maxParticipants)"
    }
    
    /// Indique si la session est pleine
    var isFull: Bool {
        guard let maxParticipants = maxParticipants else {
            return false
        }
        
        return participants.count >= maxParticipants
    }
    
    /// Durée depuis le début
    var durationSinceStart: TimeInterval {
        Date().timeIntervalSince(startedAt)
    }
    
    /// Durée formatée (ex: "45 min")
    var formattedDurationSinceStart: String {
        let duration = durationSinceStart
        let minutes = Int(duration) / 60
        
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)min"
        }
    }
}

// MARK: - Session Error Extensions

extension SessionError {
    static let notJoinable = SessionError.custom("Cette session ne peut pas être rejointe")
    static let sessionFull = SessionError.custom("Cette session est complète")
    static let alreadyInSession = SessionError.custom("Vous participez déjà à cette session")
    
    static func custom(_ message: String) -> SessionError {
        // Vous devrez ajouter ce cas dans SessionError
        .invalidSession
    }
}

// MARK: - Live Feed Item

/// Élément du fil d'encouragements en temps réel
struct LiveFeedItem: Codable, Identifiable {
    @DocumentID var id: String?
    
    var sessionId: String
    var userId: String
    var userName: String?  // Dénormalisé pour performance
    var userPhotoURL: String?
    
    var type: LiveFeedType
    var content: String?
    var photoURL: String?
    
    var timestamp: Date
    @ServerTimestamp var serverTimestamp: Timestamp?
    
    /// Réactions (likes, etc.)
    var reactions: [String: Int] = [:]  // ["❤️": 5, "👏": 3]
}

enum LiveFeedType: String, Codable {
    case cheer = "CHEER"  // Encouragement
    case message = "MESSAGE"  // Message texte
    case photo = "PHOTO"  // Photo partagée
    case achievement = "ACHIEVEMENT"  // Milestone (5km, 10km, etc.)
    case joined = "JOINED"  // Quelqu'un a rejoint
    case left = "LEFT"  // Quelqu'un a quitté
}

// MARK: - Notification Model

/// Notification "Live Run Started"
struct LiveRunNotification: Codable, Identifiable {
    @DocumentID var id: String?
    
    var type: String  // "LIVE_RUN_STARTED"
    var sessionId: String
    var creatorId: String
    var creatorName: String
    var squadId: String
    var squadName: String
    
    var timestamp: Date
    @ServerTimestamp var serverTimestamp: Timestamp?
    
    var isRead: Bool = false
}

// MARK: - Session Discovery

/// Résumé d'une session pour la découverte
struct SessionDiscovery: Identifiable {
    let id: String
    let session: SessionModel
    var creatorName: String?
    var participantNames: [String: String] = [:]  // userId: displayName
    
    init(session: SessionModel) {
        self.id = session.id ?? UUID().uuidString
        self.session = session
    }
}

// MARK: - Session Create Options

/// Options pour la création d'une session
struct SessionCreateOptions {
    var squadId: String
    var creatorId: String
    var activityType: ActivityType
    var runType: RunType
    var visibility: SessionVisibility
    var title: String?
    var isJoinable: Bool
    var maxParticipants: Int?
    var startLocation: GeoPoint?
    
    init(
        squadId: String,
        creatorId: String,
        activityType: ActivityType = .training,
        runType: RunType = .solo,
        visibility: SessionVisibility = .squad,
        title: String? = nil,
        isJoinable: Bool = true,
        maxParticipants: Int? = nil,
        startLocation: GeoPoint? = nil
    ) {
        self.squadId = squadId
        self.creatorId = creatorId
        self.activityType = activityType
        self.runType = runType
        self.visibility = visibility
        self.title = title
        self.isJoinable = isJoinable
        self.maxParticipants = maxParticipants
        self.startLocation = startLocation
    }
}
