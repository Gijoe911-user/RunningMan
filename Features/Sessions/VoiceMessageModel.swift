//
//  VoiceMessageModel.swift
//  RunningMan
//
//  Modèle pour les messages vocaux et texte
//

import Foundation
import FirebaseFirestore

/// Type de message
enum MessageType: String, Codable {
    case text
    case voice
}

/// Modèle de message vocal/texte
struct VoiceMessage: Identifiable, Codable {
    @DocumentID var id: String?
    
    let senderId: String
    let senderName: String
    let recipientType: SharingScope  // all_my_squads, all_my_sessions, only_one
    let recipientId: String?  // ID de la squad, session ou utilisateur selon recipientType
    
    let messageType: MessageType
    let textContent: String?  // Pour les messages texte ou transcription
    let audioURL: String?  // URL Firebase Storage pour l'audio
    let audioDuration: TimeInterval?  // Durée en secondes
    
    let timestamp: Date
    let isRead: Bool
    let readAt: Date?
    
    // Métadonnées contextuelles
    let sessionId: String?  // Si envoyé depuis une session
    let squadId: String?  // Si envoyé à une squad
    
    var encodedId: String {
        id ?? "unknown"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case senderName
        case recipientType
        case recipientId
        case messageType
        case textContent
        case audioURL
        case audioDuration
        case timestamp
        case isRead
        case readAt
        case sessionId
        case squadId
    }
}

/// État de lecture d'un message pour un utilisateur
struct MessageReadStatus: Codable {
    let userId: String
    let messageId: String
    let isRead: Bool
    let readAt: Date?
    let autoRead: Bool  // Lecture automatique ou manuelle
}

/// Statistiques d'un message (pour le sender)
struct MessageStats: Codable {
    let messageId: String
    let totalRecipients: Int
    let readCount: Int
    let deliveredCount: Int
    let autoReadCount: Int
    
    var readPercentage: Double {
        guard totalRecipients > 0 else { return 0 }
        return Double(readCount) / Double(totalRecipients) * 100
    }
}
