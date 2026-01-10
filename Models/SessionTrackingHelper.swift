//
//  SessionTrackingHelper.swift
//  RunningMan
//
//  Helper pour démarrer le tracking avec validation de l'ID
//

import Foundation

/// Helper pour gérer le démarrage du tracking avec validation de l'ID
struct SessionTrackingHelper {
    
    /// Démarre le tracking pour une session en s'assurant qu'elle a un ID valide
    ///
    /// **Fix pour le problème "Session ID NIL" :**
    /// - Si la session a déjà un ID → Démarre directement
    /// - Si la session n'a PAS d'ID → Recharge depuis Firestore puis démarre
    ///
    /// - Parameters:
    ///   - session: Session à tracker (peut avoir un ID nil)
    ///   - trackingManager: TrackingManager à utiliser
    /// - Returns: `true` si le tracking a démarré, `false` sinon
    @MainActor
    static func startTracking(
        for session: SessionModel,
        using trackingManager: TrackingManager
    ) async -> Bool {
        
        // 🔍 Cas 1 : La session a déjà un ID valide
        if session.id != nil {
            Logger.log("✅ Session a déjà un ID, démarrage direct", category: .location)
            return await trackingManager.startTracking(for: session)
        }
        
        // 🔄 Cas 2 : Session sans ID → Recharger depuis Firestore
        Logger.log("⚠️ Session sans ID détectée, rechargement depuis Firestore...", category: .location)
        Logger.log("   - squadId: \(session.squadId)", category: .location)
        Logger.log("   - creatorId: \(session.creatorId)", category: .location)
        Logger.log("   - status: \(session.status.rawValue)", category: .location)
        
        do {
            // Chercher la session active dans la squad
            guard let reloadedSession = try await SessionService.shared.getActiveSession(squadId: session.squadId) else {
                Logger.log("❌ Impossible de recharger la session depuis Firestore", category: .location)
                return false
            }
            
            // Vérifier que la session rechargée a bien un ID
            guard reloadedSession.id != nil else {
                Logger.log("❌ Session rechargée n'a toujours pas d'ID", category: .location)
                return false
            }
            
            Logger.logSuccess("✅ Session rechargée avec ID: \(reloadedSession.id!)", category: .location)
            
            // Démarrer le tracking avec la session rechargée
            return await trackingManager.startTracking(for: reloadedSession)
            
        } catch {
            Logger.logError(error, context: "startTracking (rechargement)", category: .location)
            return false
        }
    }
    
    /// Démarre le tracking en forçant le rechargement depuis Firestore
    ///
    /// **Usage :** Quand on veut garantir qu'on a la version la plus récente de la session
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session (doit être non-nil)
    ///   - trackingManager: TrackingManager à utiliser
    /// - Returns: `true` si le tracking a démarré, `false` sinon
    @MainActor
    static func startTrackingById(
        _ sessionId: String,
        using trackingManager: TrackingManager
    ) async -> Bool {
        
        Logger.log("🔄 Chargement de la session depuis Firestore: \(sessionId)", category: .location)
        
        do {
            guard let session = try await SessionService.shared.getSession(sessionId: sessionId) else {
                Logger.log("❌ Session \(sessionId) introuvable", category: .location)
                return false
            }
            
            guard session.id != nil else {
                Logger.log("❌ Session chargée n'a pas d'ID", category: .location)
                return false
            }
            
            Logger.logSuccess("✅ Session chargée: \(session.id!)", category: .location)
            return await trackingManager.startTracking(for: session)
            
        } catch {
            Logger.logError(error, context: "startTrackingById", category: .location)
            return false
        }
    }
}

// MARK: - Extension pour faciliter l'utilisation

extension SessionTrackingHelper {
    
    /// Helper pour appeler startTracking avec TrackingManager.shared depuis les vues
    @MainActor
    static func startTrackingWithSharedManager(for session: SessionModel) async -> Bool {
        await startTracking(for: session, using: TrackingManager.shared)
    }
    
    /// Helper pour appeler startTrackingById avec TrackingManager.shared depuis les vues
    @MainActor
    static func startTrackingByIdWithSharedManager(_ sessionId: String) async -> Bool {
        await startTrackingById(sessionId, using: TrackingManager.shared)
    }
}

extension TrackingManager {
    
    /// Démarre le tracking avec validation automatique de l'ID
    ///
    /// **Wrapper pratique qui utilise SessionTrackingHelper en interne**
    ///
    /// - Parameter session: Session à tracker (peut avoir un ID nil)
    /// - Returns: `true` si le tracking a démarré, `false` sinon
    func startTrackingSafely(for session: SessionModel) async -> Bool {
        await SessionTrackingHelper.startTracking(for: session, using: self)
    }
}

// MARK: - Documentation

/// ## 🎯 Usage recommandé
///
/// **Dans votre vue de tracking :**
///
/// ```swift
/// SessionTrackingControlsView(
///     session: session,
///     trackingState: Binding(
///         get: { trackingManager.trackingState },
///         set: { _ in }
///     ),
///     onStart: {
///         // ✅ NOUVELLE MÉTHODE : Validation automatique de l'ID
///         let success = await SessionTrackingHelper.startTracking(
///             for: session,
///             using: trackingManager
///         )
///         
///         if !success {
///             print("❌ Échec démarrage tracking")
///         }
///     },
///     onPause: {
///         await trackingManager.pauseTracking()
///     },
///     onResume: {
///         await trackingManager.resumeTracking()
///     },
///     onStop: {
///         showEndConfirmation = true
///     }
/// )
/// ```
///
/// **OU avec l'extension :**
///
/// ```swift
/// onStart: {
///     let success = await trackingManager.startTrackingSafely(for: session)
///     if !success {
///         print("❌ Échec démarrage tracking")
///     }
/// }
/// ```
///
/// ## 🔍 Comment ça fonctionne ?
///
/// ```
/// 1. Vérifie si session.id != nil
///    ↓
/// 2a. Si OUI → Démarre directement
///    ↓
/// 2b. Si NON → Recharge depuis Firestore
///    ↓
/// 3. Vérifie que la session rechargée a un ID
///    ↓
/// 4. Démarre le tracking avec la session rechargée
/// ```
///
/// ## 🚨 Pourquoi ce fix est nécessaire ?
///
/// Certaines vues passent une **session locale** créée via `SessionModel(...)` au lieu
/// d'une session **chargée depuis Firestore**. Ces sessions locales n'ont pas d'ID.
///
/// Ce helper **recharge automatiquement** la session depuis Firestore pour garantir
/// qu'elle a un ID valide avant de démarrer le tracking.
