//
//  SquadModel.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 20/12/2025.
//

import Foundation
import FirebaseFirestore

/// Modèle représentant un groupe de course (Squad)
/// Collection Firestore : `squads/{squadId}`
struct SquadModel: Identifiable, Codable {
    
    /// ID unique de la squad
    @DocumentID var id: String?
    
    /// Nom de la squad
    var name: String
    
    /// Description de la squad
    var description: String
    
    /// Code d'invitation unique pour rejoindre la squad (6 caractères)
    var inviteCode: String
    
    /// ID du créateur de la squad
    var creatorId: String
    
    /// Date de création de la squad
    var createdAt: Date
    
    /// Image de profil de la squad (URL Firebase Storage)
    var photoURL: String?
    
    /// Membres de la squad avec leurs rôles
    var members: [String: SquadMemberRole] // [userId: role]
    
    /// Sessions actives de la squad
    var activeSessions: [String] // Liste des sessionIds actifs
    
    /// Statistiques de la squad
    var statistics: SquadStatistics?
    
    // MARK: - Initialisation
    
    init(
        id: String? = nil,
        name: String,
        description: String = "",
        inviteCode: String,
        creatorId: String,
        createdAt: Date = Date(),
        photoURL: String? = nil,
        members: [String: SquadMemberRole] = [:],
        activeSessions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.inviteCode = inviteCode
        self.creatorId = creatorId
        self.createdAt = createdAt
        self.photoURL = photoURL
        self.members = members
        self.activeSessions = activeSessions
    }
}

// MARK: - SquadMemberRole

/// Rôle d'un membre dans une squad
enum SquadMemberRole: String, Codable {
    case admin = "ADMIN"       // Créateur ou administrateur
    case member = "MEMBER"     // Membre régulier
    case coach = "COACH"       // Coach/entraîneur (peut créer des sessions)
}

// MARK: - SquadStatistics

/// Statistiques d'une squad
struct SquadStatistics: Codable {
    
    /// Nombre total de membres
    var totalMembers: Int = 0
    
    /// Nombre de courses complétées ensemble
    var totalRaces: Int = 0
    
    /// Nombre d'entraînements complétés
    var totalTrainings: Int = 0
    
    /// Distance totale parcourue par la squad (en mètres)
    var totalDistanceMeters: Double = 0
    
    /// Dernière activité de la squad
    var lastActivityDate: Date?
}

// MARK: - Helper Extensions

extension SquadModel {
    
    /// Génère un code d'invitation aléatoire unique de 6 caractères
    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Sans I, O, 0, 1 pour éviter confusion
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    /// Vérifie si un utilisateur est membre de la squad
    func isMember(userId: String) -> Bool {
        members.keys.contains(userId)
    }
    
    /// Vérifie si un utilisateur est admin de la squad
    func isAdmin(userId: String) -> Bool {
        members[userId] == .admin
    }
    
    /// Vérifie si un utilisateur peut créer des sessions (admin ou coach)
    func canCreateSession(userId: String) -> Bool {
        guard let role = members[userId] else { return false }
        return role == .admin || role == .coach
    }
    
    /// Nombre de membres actifs
    var memberCount: Int {
        members.count
    }
    
    /// Indique si la squad a des sessions actives
    var hasActiveSessions: Bool {
        !activeSessions.isEmpty
    }
}

// MARK: - SquadMember (Pour affichage dans les listes)

/// Structure légère pour afficher les membres d'une squad
struct SquadMember: Identifiable, Codable {
    var id: String // userId
    var displayName: String
    var photoURL: String?
    var role: SquadMemberRole
    var joinedAt: Date
}
