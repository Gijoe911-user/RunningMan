//
//  SessionRecoveryManager.swift
//  RunningMan
//
//  Gère la récupération des sessions interrompues
//  🛡️ Permet de reprendre ou terminer une session après un crash/batterie
//

import Foundation
import Combine

/// Manager pour récupérer les sessions interrompues
@MainActor
class SessionRecoveryManager: ObservableObject {
    
    static let shared = SessionRecoveryManager()
    
    // MARK: - Published Properties
    
    /// Session interrompue détectée
    @Published var interruptedSession: SessionModel?
    
    /// Indique si on doit afficher l'alerte de récupération
    @Published var shouldShowRecoveryAlert = false
    
    // MARK: - Services
    
    private let sessionService = SessionService.shared
    private let authService = AuthService.shared
    
    // MARK: - Initialization
    
    private init() {
        Logger.log("🛡️ SessionRecoveryManager initialisé", category: .session)
    }
    
    // MARK: - Check for Interrupted Session
    
    /// Vérifie s'il existe une session interrompue pour l'utilisateur
    func checkForInterruptedSession() async {
        guard authService.currentUserId != nil else {
            Logger.log("⚠️ Pas d'utilisateur connecté pour vérifier les sessions interrompues", category: .session)
            return
        }
        
        Logger.log("🔍 Recherche de sessions interrompues pour l'utilisateur...", category: .session)
        
        // TODO: Implémenter getUserActiveSessions dans SessionService
        // Pour l'instant, la vérification est désactivée
        Logger.log("ℹ️ Vérification des sessions interrompues (à implémenter)", category: .session)
        
        /* CODE À RÉACTIVER QUAND getUserActiveSessions SERA IMPLÉMENTÉ :
        guard let userId = authService.currentUserId else { return }
        do {
            let sessions = try await sessionService.getUserActiveSessions(userId: userId)
            
            if let session = sessions.first {
                Logger.log("⚠️ Session interrompue détectée: \(session.id ?? "unknown")", category: .session)
                interruptedSession = session
                shouldShowRecoveryAlert = true
            } else {
                Logger.log("✅ Aucune session interrompue", category: .session)
            }
        } catch {
            Logger.logError(error, context: "checkForInterruptedSession", category: .session)
        }
        */
    }
    
    // MARK: - Resume Session
    
    /// Reprend une session interrompue
    func resumeSession() async -> Bool {
        guard let session = interruptedSession else {
            Logger.log("⚠️ Aucune session à reprendre", category: .session)
            return false
        }
        
        Logger.log("🔄 Reprise de la session interrompue: \(session.id ?? "unknown")", category: .session)
        
        // Démarrer le tracking pour cette session
        let success = await TrackingManager.shared.startTracking(for: session)
        
        if success {
            Logger.logSuccess("✅ Session reprise avec succès", category: .session)
            interruptedSession = nil
            shouldShowRecoveryAlert = false
        } else {
            Logger.log("❌ Échec de la reprise", category: .session)
        }
        
        return success
    }
    
    // MARK: - End Interrupted Session
    
    /// Termine une session interrompue et sauvegarde l'état actuel
    func endInterruptedSession() async -> Bool {
        guard let session = interruptedSession else {
            Logger.log("⚠️ Aucune session à terminer", category: .session)
            return false
        }
        
        guard let sessionId = session.id else {
            Logger.log("❌ Session ID manquant", category: .session)
            return false
        }
        
        Logger.log("🛑 Terminaison de la session interrompue: \(sessionId)", category: .session)
        
        do {
            // Terminer la session dans Firestore
            try await sessionService.endSession(sessionId: sessionId)
            
            Logger.logSuccess("✅ Session interrompue terminée", category: .session)
            
            interruptedSession = nil
            shouldShowRecoveryAlert = false
            
            return true
            
        } catch {
            Logger.logError(error, context: "endInterruptedSession", category: .session)
            return false
        }
    }
    
    // MARK: - Dismiss Alert
    
    /// Ignore l'alerte de récupération (pas recommandé)
    func dismissAlert() {
        Logger.log("⚠️ Alerte de récupération ignorée", category: .session)
        shouldShowRecoveryAlert = false
        
        // Note: La session reste "ACTIVE" dans Firestore
        // Elle apparaîtra toujours dans AllSessionsView
    }
}
