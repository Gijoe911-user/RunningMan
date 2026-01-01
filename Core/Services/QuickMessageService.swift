//
//  QuickMessageService.swift
//  RunningMan
//
//  Service pour envoyer des messages rapides pendant une session
//

import Foundation
import FirebaseFirestore

/// Modèle de message rapide
struct QuickMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var sessionId: String
    var senderId: String
    var senderName: String
    var message: String
    var timestamp: Date
    var type: MessageType
    
    enum MessageType: String, Codable {
        case text = "TEXT"
        case quickReaction = "REACTION" // 👍, ❤️, 💪
    }
}

/// Service de gestion des messages rapides
class QuickMessageService {
    
    static let shared = QuickMessageService()
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private init() {}
    
    // MARK: - Send Messages
    
    /// Envoie un message texte
    func sendMessage(sessionId: String, senderId: String, senderName: String, text: String) async throws {
        Logger.log("💬 Envoi message: \(text)", category: .general)
        
        let message = QuickMessage(
            sessionId: sessionId,
            senderId: senderId,
            senderName: senderName,
            message: text,
            timestamp: Date(),
            type: .text
        )
        
        try db.collection("sessions")
            .document(sessionId)
            .collection("messages")
            .document()
            .setData(from: message)
        
        Logger.logSuccess("✅ Message envoyé", category: .general)
    }
    
    /// Envoie une réaction rapide (emoji)
    func sendReaction(sessionId: String, senderId: String, senderName: String, emoji: String) async throws {
        Logger.log("👍 Envoi réaction: \(emoji)", category: .general)
        
        let message = QuickMessage(
            sessionId: sessionId,
            senderId: senderId,
            senderName: senderName,
            message: emoji,
            timestamp: Date(),
            type: .quickReaction
        )
        
        try db.collection("sessions")
            .document(sessionId)
            .collection("messages")
            .document()
            .setData(from: message)
        
        Logger.logSuccess("✅ Réaction envoyée", category: .general)
    }
    
    // MARK: - Observe Messages
    
    /// Observe les nouveaux messages en temps réel
    func observeMessages(sessionId: String) -> AsyncStream<[QuickMessage]> {
        AsyncStream { continuation in
            let listener = db.collection("sessions")
                .document(sessionId)
                .collection("messages")
                .order(by: "timestamp", descending: false)
                .limit(toLast: 50) // Derniers 50 messages
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        Logger.log("❌ Erreur observation messages: \(error.localizedDescription)", category: .general)
                        continuation.yield([])
                        return
                    }
                    
                    let messages = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: QuickMessage.self)
                    } ?? []
                    
                    continuation.yield(messages)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}

// MARK: - Messages Prédéfinis

extension QuickMessageService {
    
    /// Messages rapides prédéfinis
    static let quickMessages = [
        "👍 Bien joué !",
        "💪 Allez !",
        "⚡ Accélérez !",
        "🐌 Ralentissez",
        "💧 Pause eau",
        "🏁 J'arrive !",
        "🆘 Besoin d'aide",
        "📍 Où êtes-vous ?"
    ]
    
    /// Réactions emoji
    static let quickReactions = ["👍", "❤️", "💪", "🔥", "⚡", "🎉"]
}
