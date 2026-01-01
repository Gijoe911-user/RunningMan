//
//  SquadsViewModel.swift
//  RunningMan
//
//  ViewModel pour gérer les Squads
//

import Foundation
import Combine

@MainActor
class SquadsViewModel: ObservableObject {
    @Published var squads: [SquadModel] = []
    @Published var isLoading: Bool = false
    
    func loadSquads() {
        isLoading = true
        
        // TODO: Charger depuis Firestore
        // Pour Phase 1, utiliser des données mock
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            self.squads = self.getMockSquads()
            self.isLoading = false
        }
    }
    
    private func getMockSquads() -> [SquadModel] {
        [
            SquadModel(
                id: "squad1",
                name: "Paris Runners 🏃",
                description: "Groupe de runners parisiens",
                inviteCode: "PARIS1",
                creatorId: "user1",
                createdAt: Date(),
                members: [
                    "user1": .admin,
                    "user2": .member,
                    "user3": .member
                ],
                activeSessions: []
            ),
            SquadModel(
                id: "squad2",
                name: "Marathon Club",
                description: "Préparation marathon",
                inviteCode: "MARAT1",
                creatorId: "user4",
                createdAt: Date(),
                members: [
                    "user4": .admin,
                    "user5": .member
                ],
                activeSessions: []
            )
        ]
    }
}
