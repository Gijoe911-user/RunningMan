//
//  SquadViewModel.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import Foundation
import SwiftUI

/// ViewModel pour gérer l'état des squads
@MainActor
@Observable
class SquadViewModel {
    
    // MARK: - Published Properties
    
    /// Liste des squads de l'utilisateur
    var userSquads: [SquadModel] = []
    
    /// Squad actuellement sélectionnée
    var selectedSquad: SquadModel?
    
    /// État de chargement
    var isLoading = false
    
    /// Message d'erreur
    var errorMessage: String?
    
    /// Message de succès
    var successMessage: String?
    
    // MARK: - Services
    
    private let squadService = SquadService.shared
    private let authService = AuthService.shared
    
    // MARK: - Real-time Listener
    
    // Stocker la tâche d'observation
    private var observationTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    
    /// Indique si l'utilisateur fait partie d'au moins une squad
    var hasSquads: Bool {
        !userSquads.isEmpty
    }
    
    /// ID de l'utilisateur actuel
    private var currentUserId: String? {
        authService.currentUserId
    }
    
    // MARK: - Load User Squads
    
    /// Charge toutes les squads de l'utilisateur
    func loadUserSquads() async {
        guard let userId = currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            userSquads = try await squadService.getUserSquads(userId: userId)
            
            // Sélectionner automatiquement la première squad si aucune n'est sélectionnée
            if selectedSquad == nil, let firstSquad = userSquads.first {
                selectedSquad = firstSquad
            }
            
            Logger.logSuccess("Squads chargées: \(userSquads.count)", category: .squads)
        } catch {
            Logger.logError(error, context: "loadUserSquads", category: .squads)
            errorMessage = "Erreur lors du chargement des squads"
        }
        
        isLoading = false
    }
    
    // MARK: - Create Squad
    
    /// Crée une nouvelle squad
    func createSquad(name: String, description: String) async -> Bool {
        guard let userId = currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return false
        }
        
        guard !name.isEmpty else {
            errorMessage = "Le nom de la squad est obligatoire"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let newSquad = try await squadService.createSquad(
                name: name,
                description: description,
                creatorId: userId
            )
            
            userSquads.append(newSquad)
            selectedSquad = newSquad
            
            successMessage = "Squad créée avec succès ! Code d'invitation : \(newSquad.inviteCode)"
            Logger.logSuccess("Squad créée: \(newSquad.name)", category: .squads)
            
            isLoading = false
            return true
        } catch {
            Logger.logError(error, context: "createSquad", category: .squads)
            errorMessage = "Erreur lors de la création de la squad"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Join Squad
    
    /// Rejoindre une squad avec un code d'invitation
    func joinSquad(inviteCode: String) async -> Bool {
        guard let userId = currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return false
        }
        
        guard !inviteCode.isEmpty else {
            errorMessage = "Code d'invitation requis"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let joinedSquad = try await squadService.joinSquad(
                inviteCode: inviteCode.uppercased(),
                userId: userId
            )
            
            userSquads.append(joinedSquad)
            selectedSquad = joinedSquad
            
            successMessage = "Vous avez rejoint \(joinedSquad.name) !"
            Logger.logSuccess("Squad rejointe: \(joinedSquad.name)", category: .squads)
            
            isLoading = false
            return true
        } catch let error as SquadError {
            errorMessage = error.localizedDescription
            Logger.logError(error, context: "joinSquad", category: .squads)
            isLoading = false
            return false
        } catch {
            errorMessage = "Erreur lors de la tentative de rejoindre la squad"
            Logger.logError(error, context: "joinSquad", category: .squads)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Leave Squad
    
    /// Quitter une squad
    func leaveSquad(squadId: String) async -> Bool {
        guard let userId = currentUserId else {
            errorMessage = "Utilisateur non connecté"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await squadService.leaveSquad(squadId: squadId, userId: userId)
            
            // Retirer la squad de la liste locale
            userSquads.removeAll { $0.id == squadId }
            
            // Si c'était la squad sélectionnée, sélectionner la première disponible
            if selectedSquad?.id == squadId {
                selectedSquad = userSquads.first
            }
            
            successMessage = "Vous avez quitté la squad"
            Logger.logSuccess("Squad quittée", category: .squads)
            
            isLoading = false
            return true
        } catch let error as SquadError {
            errorMessage = error.localizedDescription
            Logger.logError(error, context: "leaveSquad", category: .squads)
            isLoading = false
            return false
        } catch {
            errorMessage = "Erreur lors de la sortie de la squad"
            Logger.logError(error, context: "leaveSquad", category: .squads)
            isLoading = false
            return false
        }
    }
    
    // MARK: - Refresh Squad
    
    /// Rafraîchit les données d'une squad spécifique
    func refreshSquad(squadId: String) async {
        do {
            guard let updatedSquad = try await squadService.getSquad(squadId: squadId) else {
                errorMessage = "Squad introuvable"
                return
            }
            
            // Mettre à jour dans la liste
            if let index = userSquads.firstIndex(where: { $0.id == squadId }) {
                userSquads[index] = updatedSquad
            }
            
            // Mettre à jour si c'est la squad sélectionnée
            if selectedSquad?.id == squadId {
                selectedSquad = updatedSquad
            }
            
            Logger.log("Squad rafraîchie: \(squadId)", category: .squads)
        } catch {
            Logger.logError(error, context: "refreshSquad", category: .squads)
        }
    }
    
    // MARK: - Select Squad
    
    /// Sélectionne une squad
    func selectSquad(_ squad: SquadModel) {
        selectedSquad = squad
        Logger.log("Squad sélectionnée: \(squad.name)", category: .squads)
    }
    
    // MARK: - Get Squad Invite Code
    
    /// Récupère le code d'invitation d'une squad
    func getInviteCode(for squad: SquadModel) -> String {
        return squad.inviteCode
    }
    
    // MARK: - Check User Role
    
    /// Vérifie si l'utilisateur est admin d'une squad
    func isAdmin(in squad: SquadModel) -> Bool {
        guard let userId = currentUserId else { return false }
        return squad.isAdmin(userId: userId)
    }
    
    /// Vérifie si l'utilisateur peut créer des sessions dans une squad
    func canCreateSession(in squad: SquadModel) -> Bool {
        guard let userId = currentUserId else { return false }
        return squad.canCreateSession(userId: userId)
    }
    
    // MARK: - Clear Messages
    
    /// Efface les messages d'erreur et de succès
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Real-time Updates
    
    /// Démarre l'observation en temps réel des squads de l'utilisateur
    func startObservingSquads() {
        guard let userId = currentUserId else { return }
        
        // Empêcher de créer plusieurs listeners
        guard observationTask == nil else {
            Logger.log("Listener déjà actif, ignorer la demande", category: .squads)
            return
        }
        
        // Créer un nouveau listener
        observationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            let stream = squadService.streamUserSquads(userId: userId)
            
            for await squads in stream {
                // Vérifier si la tâche a été annulée
                guard !Task.isCancelled else {
                    Logger.log("Observation des squads annulée", category: .squads)
                    break
                }
                
                // Mettre à jour la liste locale
                self.userSquads = squads
                
                // Mettre à jour la squad sélectionnée si elle a changé
                if let selectedId = self.selectedSquad?.id,
                   let updatedSelected = squads.first(where: { $0.id == selectedId }) {
                    self.selectedSquad = updatedSelected
                } else if self.selectedSquad != nil && !squads.contains(where: { $0.id == self.selectedSquad?.id }) {
                    // Si la squad sélectionnée n'existe plus, sélectionner la première disponible
                    self.selectedSquad = squads.first
                }
                
                Logger.log("Squads mises à jour en temps réel: \(squads.count)", category: .squads)
            }
            
            Logger.log("Stream des squads terminé", category: .squads)
        }
    }
    
    /// Arrête l'observation en temps réel
    func stopObservingSquads() {
        observationTask?.cancel()
        observationTask = nil
        Logger.log("Observation des squads arrêtée", category: .squads)
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Note: observationTask est MainActor isolé et ne peut pas être accédé depuis deinit
        // La tâche sera automatiquement nettoyée quand self est deallocated grâce à [weak self]
        // Bonne pratique : appelez stopObservingSquads() explicitement dans .onDisappear de la vue
    }
}
