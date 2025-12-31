//
//  SquadService.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import Foundation
import FirebaseFirestore

/// Service de gestion des Squads (groupes de course)
/// Gère la création, rejoindre, quitter et synchronisation avec Firestore
class SquadService {
    
    static let shared = SquadService()
    
    // Utiliser une computed property pour garantir que Firebase est configuré
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private init() {
        Logger.log("SquadService initialisé", category: .squads)
    }
    
    // MARK: - Create Squad
    
    /// Crée une nouvelle squad
    /// - Parameters:
    ///   - name: Nom de la squad
    ///   - description: Description de la squad
    ///   - creatorId: ID de l'utilisateur créateur
    /// - Returns: SquadModel créé
    func createSquad(
        name: String,
        description: String,
        creatorId: String
    ) async throws -> SquadModel {
        
        Logger.log("Création d'une nouvelle squad: \(name)", category: .squads)
        
        // 1. Générer un code d'invitation unique
        let inviteCode = try await generateUniqueInviteCode()
        
        // 2. Créer le modèle de squad
        var squad = SquadModel(
            name: name,
            description: description,
            inviteCode: inviteCode,
            creatorId: creatorId,
            members: [creatorId: .admin] // Le créateur est automatiquement admin
        )
        
        // 3. Créer le document dans Firestore
        let squadRef = db.collection("squads").document()
        squad.id = squadRef.documentID
        
        try squadRef.setData(from: squad)
        
        // 4. Ajouter la squad à la liste des squads de l'utilisateur
        try await addSquadToUser(userId: creatorId, squadId: squadRef.documentID)
        
        Logger.logSuccess("Squad créée avec succès: \(squadRef.documentID)", category: .squads)
        
        return squad
    }
    
    // MARK: - Join Squad
    
    /// Rejoindre une squad avec un code d'invitation
    /// - Parameters:
    ///   - inviteCode: Code d'invitation à 6 caractères
    ///   - userId: ID de l'utilisateur qui rejoint
    /// - Returns: SquadModel rejointe
    func joinSquad(inviteCode: String, userId: String) async throws -> SquadModel {
        
        Logger.log("Tentative de rejoindre une squad avec le code: \(inviteCode)", category: .squads)
        
        // 1. Rechercher la squad par code d'invitation
        let squadsRef = db.collection("squads")
        let query = squadsRef.whereField("inviteCode", isEqualTo: inviteCode.uppercased())
        
        let snapshot: QuerySnapshot
        do {
            snapshot = try await query.getDocuments()
        } catch {
            // Gérer spécifiquement les erreurs de quota
            if (error as NSError).code == 8 { // RESOURCE_EXHAUSTED
                Logger.logError(error, context: "joinSquad - Quota Firebase épuisé", category: .squads)
                throw SquadError.quotaExceeded
            }
            throw error
        }
        
        guard let document = snapshot.documents.first else {
            throw SquadError.invalidInviteCode
        }
        
        var squad = try document.data(as: SquadModel.self)
        
        // 2. Vérifier si l'utilisateur n'est pas déjà membre
        guard !squad.isMember(userId: userId) else {
            throw SquadError.alreadyMember
        }
        
        // 3. Ajouter l'utilisateur comme membre
        squad.members[userId] = .member
        
        // 4. Mettre à jour Firestore
        do {
            try document.reference.setData(from: squad, merge: true)
        } catch {
            if (error as NSError).code == 8 {
                throw SquadError.quotaExceeded
            }
            throw error
        }
        
        // 5. Ajouter la squad à la liste des squads de l'utilisateur
        do {
            try await addSquadToUser(userId: userId, squadId: document.documentID)
        } catch {
            if (error as NSError).code == 8 {
                throw SquadError.quotaExceeded
            }
            throw error
        }
        
        Logger.logSuccess("Squad rejointe avec succès: \(document.documentID)", category: .squads)
        
        return squad
    }
    
    // MARK: - Get Squad
    
    /// Récupère une squad par son ID
    func getSquad(squadId: String) async throws -> SquadModel? {
        let squadRef = db.collection("squads").document(squadId)
        let document = try await squadRef.getDocument()
        
        guard document.exists else {
            return nil
        }
        
        return try document.data(as: SquadModel.self)
    }
    
    // MARK: - Get User Squads
    
    /// Récupère toutes les squads d'un utilisateur
    func getUserSquads(userId: String) async throws -> [SquadModel] {
        let squadsRef = db.collection("squads")
        let query = squadsRef.whereField("members.\(userId)", isGreaterThan: "")
        let snapshot = try await query.getDocuments()
        
        var squads: [SquadModel] = []
        for document in snapshot.documents {
            if let squad = try? document.data(as: SquadModel.self) {
                squads.append(squad)
            }
        }
        
        Logger.log("Squads récupérées pour l'utilisateur: \(squads.count)", category: .squads)
        
        return squads
    }
    
    // MARK: - Leave Squad
    
    /// Quitter une squad
    /// - Parameters:
    ///   - squadId: ID de la squad à quitter
    ///   - userId: ID de l'utilisateur qui quitte
    func leaveSquad(squadId: String, userId: String) async throws {
        
        Logger.log("Tentative de quitter la squad: \(squadId)", category: .squads)
        
        // 1. Récupérer la squad
        guard var squad = try await getSquad(squadId: squadId) else {
            throw SquadError.squadNotFound
        }
        
        // 2. Vérifier que l'utilisateur est membre
        guard squad.isMember(userId: userId) else {
            throw SquadError.notAMember
        }
        
        // 3. Empêcher le créateur de quitter s'il y a d'autres membres
        if squad.creatorId == userId && squad.memberCount > 1 {
            throw SquadError.creatorCannotLeave
        }
        
        // 4. Retirer l'utilisateur de la squad
        squad.members.removeValue(forKey: userId)
        
        // 5. Si la squad est vide, la supprimer complètement
        if squad.members.isEmpty {
            try await deleteSquad(squadId: squadId)
        } else {
            // Sinon, mettre à jour Firestore
            let squadRef = db.collection("squads").document(squadId)
            try squadRef.setData(from: squad, merge: true)
        }
        
        // 6. Retirer la squad de la liste de l'utilisateur
        try await removeSquadFromUser(userId: userId, squadId: squadId)
        
        Logger.logSuccess("Squad quittée avec succès", category: .squads)
    }
    
    // MARK: - Update Squad
    
    /// Met à jour les informations d'une squad
    func updateSquad(_ squad: SquadModel) async throws {
        guard let squadId = squad.id else {
            throw SquadError.invalidSquadId
        }
        
        let squadRef = db.collection("squads").document(squadId)
        try squadRef.setData(from: squad, merge: true)
        
        Logger.logSuccess("Squad mise à jour: \(squadId)", category: .squads)
    }
    
    // MARK: - Delete Squad
    
    /// Supprime une squad complètement
    private func deleteSquad(squadId: String) async throws {
        let squadRef = db.collection("squads").document(squadId)
        try await squadRef.delete()
        
        Logger.logSuccess("Squad supprimée: \(squadId)", category: .squads)
    }
    
    // MARK: - Helper Methods
    
    /// Ajoute une squad à la liste des squads d'un utilisateur
    private func addSquadToUser(userId: String, squadId: String) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "squads": FieldValue.arrayUnion([squadId])
        ])
    }
    
    /// Retire une squad de la liste des squads d'un utilisateur
    private func removeSquadFromUser(userId: String, squadId: String) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "squads": FieldValue.arrayRemove([squadId])
        ])
    }
    
    /// Génère un code d'invitation unique qui n'existe pas déjà
    private func generateUniqueInviteCode() async throws -> String {
        var attempts = 0
        let maxAttempts = 10
        
        while attempts < maxAttempts {
            let code = SquadModel.generateInviteCode()
            
            // Vérifier si le code existe déjà
            let squadsRef = db.collection("squads")
            let query = squadsRef.whereField("inviteCode", isEqualTo: code)
            let snapshot = try await query.getDocuments()
            
            if snapshot.documents.isEmpty {
                return code
            }
            
            attempts += 1
        }
        
        throw SquadError.codeGenerationFailed
    }
    
    // MARK: - Change Member Role
    
    /// Change le rôle d'un membre dans une squad (admin uniquement)
    func changeMemberRole(
        squadId: String,
        userId: String,
        newRole: SquadMemberRole,
        requesterId: String
    ) async throws {
        
        guard var squad = try await getSquad(squadId: squadId) else {
            throw SquadError.squadNotFound
        }
        
        // Vérifier que le requérant est admin
        guard squad.isAdmin(userId: requesterId) else {
            throw SquadError.insufficientPermissions
        }
        
        // Vérifier que l'utilisateur cible est membre
        guard squad.isMember(userId: userId) else {
            throw SquadError.notAMember
        }
        
        // Empêcher de retirer le rôle admin du créateur
        if userId == squad.creatorId && newRole != .admin {
            throw SquadError.cannotChangeCreatorRole
        }
        
        // Mettre à jour le rôle
        squad.members[userId] = newRole
        
        try await updateSquad(squad)
        
        Logger.logSuccess("Rôle mis à jour pour l'utilisateur \(userId)", category: .squads)
    }
}

// MARK: - Temps réel (Firestore Listeners)

import FirebaseFirestore

extension SquadService {
    
    /// Observe en temps réel les squads d'un utilisateur.
    /// - Returns: ListenerRegistration à conserver et à supprimer côté appelant.
    @discardableResult
    func observeUserSquads(
        userId: String,
        listener: @escaping (Result<[SquadModel], Error>) -> Void
    ) -> ListenerRegistration {
        Task { @MainActor in
            Logger.log("Activation listener squads pour user: \(userId)", category: .squads)
        }
        
        let query = db.collection("squads")
            .whereField("members.\(userId)", isGreaterThan: "")
        
        let registration = query.addSnapshotListener { snapshot, error in
            if let error = error {
                Task { @MainActor in
                    Logger.logError(error, context: "observeUserSquads", category: .squads)
                }
                listener(.failure(error))
                return
            }
            
            guard let snapshot = snapshot else {
                listener(.success([]))
                return
            }
            
            let squads: [SquadModel] = snapshot.documents.compactMap { doc in
                do {
                    return try doc.data(as: SquadModel.self)
                } catch {
                    Task { @MainActor in
                        Logger.logError(error, context: "decode SquadModel \(doc.documentID)", category: .squads)
                    }
                    return nil
                }
            }
            
            listener(.success(squads))
        }
        
        return registration
    }
    
    /// Observe en temps réel une squad spécifique.
    @discardableResult
    func observeSquad(
        squadId: String,
        listener: @escaping (Result<SquadModel?, Error>) -> Void
    ) -> ListenerRegistration {
        Task { @MainActor in
            Logger.log("Activation listener squad: \(squadId)", category: .squads)
        }
        
        let ref = db.collection("squads").document(squadId)
        let registration = ref.addSnapshotListener { snapshot, error in
            if let error = error {
                Task { @MainActor in
                    Logger.logError(error, context: "observeSquad", category: .squads)
                }
                listener(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                listener(.success(nil))
                return
            }
            
            do {
                let squad = try snapshot.data(as: SquadModel.self)
                listener(.success(squad))
            } catch {
                Task { @MainActor in
                    Logger.logError(error, context: "decode SquadModel \(squadId)", category: .squads)
                }
                listener(.failure(error))
            }
        }
        return registration
    }
    
    /// Version AsyncSequence pour observer les squads d'un utilisateur.
    func streamUserSquads(userId: String) -> AsyncStream<[SquadModel]> {
        AsyncStream { continuation in
            let reg = observeUserSquads(userId: userId) { result in
                switch result {
                case .success(let squads):
                    continuation.yield(squads)
                case .failure(let error):
                    Task { @MainActor in
                        Logger.logError(error, context: "streamUserSquads", category: .squads)
                    }
                    // On peut choisir de terminer le stream sur erreur, ici on continue pour robustesse.
                }
            }
            continuation.onTermination = { _ in
                reg.remove()
                Task { @MainActor in
                    Logger.log("Listener user squads arrêté", category: .squads)
                }
            }
        }
    }
    
    /// Version AsyncSequence pour observer une squad spécifique.
    func streamSquad(squadId: String) -> AsyncStream<SquadModel?> {
        AsyncStream { continuation in
            let reg = observeSquad(squadId: squadId) { result in
                switch result {
                case .success(let squad):
                    continuation.yield(squad)
                case .failure(let error):
                    Task { @MainActor in
                        Logger.logError(error, context: "streamSquad", category: .squads)
                    }
                }
            }
            continuation.onTermination = { _ in
                reg.remove()
                Task { @MainActor in
                    Logger.log("Listener squad arrêté: \(squadId)", category: .squads)
                }
            }
        }
    }
}

// MARK: - SquadError

/// Erreurs personnalisées pour les squads
enum SquadError: LocalizedError {
    case invalidInviteCode
    case alreadyMember
    case squadNotFound
    case notAMember
    case creatorCannotLeave
    case invalidSquadId
    case codeGenerationFailed
    case insufficientPermissions
    case cannotChangeCreatorRole
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidInviteCode:
            return "Code d'invitation invalide"
        case .alreadyMember:
            return "Vous êtes déjà membre de cette squad"
        case .squadNotFound:
            return "Squad introuvable"
        case .notAMember:
            return "Vous n'êtes pas membre de cette squad"
        case .creatorCannotLeave:
            return "Le créateur ne peut pas quitter tant qu'il y a des membres. Transférez d'abord le rôle d'admin."
        case .invalidSquadId:
            return "ID de squad invalide"
        case .codeGenerationFailed:
            return "Impossible de générer un code d'invitation unique"
        case .insufficientPermissions:
            return "Vous n'avez pas les permissions nécessaires"
        case .cannotChangeCreatorRole:
            return "Le rôle du créateur ne peut pas être modifié"
        case .quotaExceeded:
            return "Quota Firebase dépassé. Veuillez réessayer dans quelques minutes ou contacter le support."
        }
    }
}
