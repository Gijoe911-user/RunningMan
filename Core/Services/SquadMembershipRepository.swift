//
//  SquadMembershipRepository.swift
//  RunningMan
//
//  Fournit un stockage simple du contexte de squad sélectionnée
//

import Foundation

protocol SquadMembershipRepositoryProtocol {
    var currentSquadId: String? { get }
    func setCurrentSquadId(_ squadId: String)
    func clear()
}

final class SquadMembershipRepository: SquadMembershipRepositoryProtocol {
    static let shared = SquadMembershipRepository()
    
    private(set) var currentSquadId: String?
    
    private init() {}
    
    func setCurrentSquadId(_ squadId: String) {
        currentSquadId = squadId
    }
    
    func clear() {
        currentSquadId = nil
    }
}

