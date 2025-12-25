//
//  SessionServiceTests.swift
//  RunningMan
//
//  Tests manuels pour SessionService
//  À exécuter dans la console ou créer des tests unitaires
//

import Foundation

/*
 
 TESTS MANUELS À EFFECTUER :
 
 1. Test Création de Session
 ────────────────────────────────
 
 Task {
     do {
         let session = try await SessionService.shared.createSession(
             squadId: "VOTRE_SQUAD_ID",
             creatorId: "VOTRE_USER_ID",
             title: "Test Session",
             sessionType: .training
         )
         
         print("✅ Session créée: \(session.id ?? "unknown")")
         print("   - Squad: \(session.squadId)")
         print("   - Status: \(session.status)")
         print("   - Participants: \(session.participantCount)")
     } catch {
         print("❌ Erreur: \(error.localizedDescription)")
     }
 }
 
 
 2. Test Récupération Session Active
 ────────────────────────────────────
 
 Task {
     do {
         if let session = try await SessionService.shared.getActiveSession(squadId: "VOTRE_SQUAD_ID") {
             print("✅ Session active trouvée: \(session.id ?? "unknown")")
             print("   - Durée: \(session.formattedDuration)")
             print("   - Distance: \(session.formattedDistance)")
         } else {
             print("ℹ️ Aucune session active")
         }
     } catch {
         print("❌ Erreur: \(error.localizedDescription)")
     }
 }
 
 
 3. Test Rejoindre Session
 ──────────────────────────
 
 Task {
     do {
         try await SessionService.shared.joinSession(
             sessionId: "VOTRE_SESSION_ID",
             userId: "AUTRE_USER_ID"
         )
         print("✅ Session rejointe")
     } catch {
         print("❌ Erreur: \(error.localizedDescription)")
     }
 }
 
 
 4. Test Terminer Session
 ─────────────────────────
 
 Task {
     do {
         try await SessionService.shared.endSession(
             sessionId: "VOTRE_SESSION_ID",
             finalDistance: 5000 // 5 km en mètres
         )
         print("✅ Session terminée")
     } catch {
         print("❌ Erreur: \(error.localizedDescription)")
     }
 }
 
 
 5. Test Observer Session en Temps Réel
 ───────────────────────────────────────
 
 Task {
     for await session in SessionService.shared.observeActiveSession(squadId: "VOTRE_SQUAD_ID") {
         if let session = session {
             print("🔄 Update session: \(session.formattedDuration) - \(session.formattedDistance)")
         } else {
             print("ℹ️ Aucune session active")
         }
     }
 }
 
 
 6. Test Historique Sessions
 ────────────────────────────
 
 Task {
     do {
         let sessions = try await SessionService.shared.getSessionHistory(
             squadId: "VOTRE_SQUAD_ID",
             limit: 10
         )
         
         print("✅ Historique récupéré: \(sessions.count) sessions")
         for session in sessions {
             print("   - \(session.title ?? "Sans titre"): \(session.formattedDistance)")
         }
     } catch {
         print("❌ Erreur: \(error.localizedDescription)")
     }
 }
 
 
 VÉRIFICATIONS DANS FIREBASE CONSOLE :
 ═════════════════════════════════════
 
 1. Collection "sessions"
    ├── Document {sessionId}
    │   ├── squadId: string
    │   ├── creatorId: string
    │   ├── status: "ACTIVE" | "PAUSED" | "ENDED"
    │   ├── participants: array
    │   ├── startedAt: timestamp
    │   ├── totalDistanceMeters: number
    │   └── durationSeconds: number
 
 2. Collection "squads"
    └── Document {squadId}
        └── activeSessions: array [sessionId1, sessionId2, ...]
 
 
 CHECKLIST DE TEST :
 ═══════════════════
 
 [  ] 1. Créer une session → Vérifier dans Firestore
 [  ] 2. Vérifier que squadId est ajouté à squad.activeSessions
 [  ] 3. Récupérer session active → Retourne la bonne session
 [  ] 4. Rejoindre session → participants.count augmente
 [  ] 5. Terminer session → status = "ENDED", endedAt != null
 [  ] 6. Vérifier que sessionId est retiré de squad.activeSessions
 [  ] 7. Observer session en temps réel → Reçoit les updates
 [  ] 8. Récupérer historique → Retourne les sessions terminées
 [  ] 9. Pause/Resume session → Status change correctement
 [  ] 10. Quitter session → participants.count diminue
 
 
 CAS D'ERREUR À TESTER :
 ═══════════════════════
 
 [  ] Terminer une session déjà terminée → Erreur
 [  ] Rejoindre une session qui n'existe pas → Erreur
 [  ] Créer session sans être membre de la squad → (À implémenter)
 [  ] Rejoindre une session terminée → Erreur
 
 
 TESTS DE PERFORMANCE :
 ══════════════════════
 
 [  ] Créer 10 sessions rapidement → Pas d'erreur
 [  ] Observer session avec updates fréquents → Pas de lag
 [  ] Récupérer historique de 100 sessions → Temps < 2s
 
 */

// MARK: - Helpers pour Tests Manuels

#if DEBUG
extension SessionService {
    
    /// Helper pour créer une session de test rapidement
    func createTestSession(squadId: String, userId: String) async throws -> SessionModel {
        return try await createSession(
            squadId: squadId,
            creatorId: userId,
            title: "Session de Test",
            sessionType: .training,
            targetDistance: 5000 // 5 km
        )
    }
    
    /// Helper pour simuler une mise à jour de distance
    func simulateDistanceUpdate(sessionId: String) async throws {
        let distances: [Double] = [1000, 2000, 3000, 4000, 5000] // Mètres
        
        for distance in distances {
            try await updateDistance(sessionId: sessionId, distanceMeters: distance)
            print("📍 Distance mise à jour: \(distance)m")
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
        }
    }
}

extension SessionModel {
    
    /// Affiche les infos de la session dans la console
    func printInfo() {
        print("""
        ═══════════════════════════════
        Session: \(id ?? "unknown")
        ───────────────────────────────
        Squad: \(squadId)
        Status: \(status.rawValue)
        Type: \(sessionType.rawValue)
        ───────────────────────────────
        Participants: \(participantCount)
        Distance: \(formattedDistance)
        Durée: \(formattedDuration)
        Vitesse moy: \(formattedAverageSpeed)
        Allure moy: \(formattedAveragePace)
        ───────────────────────────────
        Début: \(startedAt)
        Fin: \(endedAt?.description ?? "En cours")
        ═══════════════════════════════
        """)
    }
}
#endif
