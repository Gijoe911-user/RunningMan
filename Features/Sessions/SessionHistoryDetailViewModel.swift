//
//  SessionHistoryDetailViewModel.swift
//  RunningMan
//
//  ViewModel pour afficher les détails d'une session terminée avec tous les tracés
//

import Foundation
import CoreLocation
import Combine

@MainActor
class SessionHistoryDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var session: SessionModel
    @Published var allRoutes: [String: [CLLocationCoordinate2D]] = [:]
    @Published var participantNames: [String: String] = [:] // userId -> displayName
    @Published var isLoadingRoutes = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let routeService = RouteTrackingService.shared
    
    // MARK: - Initialization
    init(session: SessionModel) {
        self.session = session
    }
    
    // MARK: - Load Routes
    
    /// Charge tous les tracés de la session depuis Firestore
    func loadRoutes() async {
        guard let sessionId = session.id else {
            Logger.log("❌ Pas de sessionId", category: .location)
            return
        }
        
        isLoadingRoutes = true
        errorMessage = nil
        
        Logger.log("📥 Chargement des tracés de la session \(sessionId)...", category: .location)
        
        do {
            let routes = try await routeService.loadAllRoutes(sessionId: sessionId)
            
            await MainActor.run {
                self.allRoutes = routes
                self.isLoadingRoutes = false
                Logger.logSuccess("✅ \(routes.count) tracés chargés", category: .location)
            }
            
            // Charger les noms des participants
            await loadParticipantNames()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur lors du chargement des tracés: \(error.localizedDescription)"
                self.isLoadingRoutes = false
                Logger.logError(error, context: "loadRoutes", category: .location)
            }
        }
    }
    
    // MARK: - Load Participant Names
    
    /// Charge les noms des participants depuis leurs userId
    private func loadParticipantNames() async {
        var names: [String: String] = [:]
        
        for userId in session.participants {
            // TODO: Charger le nom depuis Firestore users collection
            // Pour l'instant, on utilise juste le userId
            names[userId] = "Coureur \(userId.prefix(4))"
        }
        
        await MainActor.run {
            self.participantNames = names
        }
    }
    
    // MARK: - Export GPX
    
    /// Exporte tous les tracés au format GPX
    func exportAllRoutesAsGPX() -> [URL] {
        var urls: [URL] = []
        
        for (userId, route) in allRoutes {
            let name = participantNames[userId] ?? userId
            do {
                let url = try routeService.saveGPXToFile(
                    route: route,
                    sessionName: "\(session.title ?? "Session")_\(name)"
                )
                urls.append(url)
            } catch {
                Logger.logError(error, context: "exportGPX", category: .location)
            }
        }
        
        return urls
    }
}
