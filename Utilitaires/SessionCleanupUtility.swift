//
//  SessionCleanupUtility.swift
//  RunningMan
//
//  Utilitaire de debug pour nettoyer les sessions actives
//

import Foundation
import FirebaseFirestore

/// Utilitaire pour nettoyer/réparer les sessions en base de données
///
/// ⚠️ **ATTENTION** : Cet utilitaire est destiné au **développement uniquement**.
/// Ne pas utiliser en production sans précautions.
///
/// **Cas d'usage :**
/// - Nettoyer toutes les sessions actives bloquées
/// - Forcer la terminaison d'une session spécifique
/// - Réparer les sessions avec des données corrompues
@MainActor
class SessionCleanupUtility {
    
    static let shared = SessionCleanupUtility()
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private init() {}
    
    // MARK: - Force End All Sessions
    
    /// Force la terminaison de **toutes** les sessions actives dans Firestore
    ///
    /// Cette méthode :
    /// 1. Récupère toutes les sessions avec status ACTIVE ou PAUSED
    /// 2. Les marque comme ENDED
    /// 3. Les retire des squads
    /// 4. Invalide le cache
    ///
    /// - Returns: Nombre de sessions terminées
    /// - Throws: Erreur Firestore en cas d'échec
    func forceEndAllActiveSessions() async throws -> Int {
        Logger.log("🧹 Début du nettoyage des sessions actives...", category: .service)
        
        let query = db.collection("sessions")
            .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
        
        let snapshot = try await query.getDocuments()
        
        Logger.log("🔍 Trouvé \(snapshot.documents.count) sessions actives", category: .service)
        
        var successCount = 0
        
        for doc in snapshot.documents {
            do {
                try await forceEndSession(documentId: doc.documentID, data: doc.data())
                successCount += 1
            } catch {
                Logger.logError(error, context: "forceEndSession(\(doc.documentID))", category: .service)
            }
        }
        
        // Invalider tout le cache
        SessionService.shared.invalidateCache()
        
        Logger.logSuccess("✅✅ \(successCount)/\(snapshot.documents.count) sessions nettoyées", category: .service)
        return successCount
    }
    
    // MARK: - Force End Specific Session
    
    /// Force la terminaison d'une session spécifique
    ///
    /// - Parameter sessionId: ID de la session à terminer
    /// - Throws: Erreur Firestore en cas d'échec
    func forceEndSessionById(sessionId: String) async throws {
        Logger.log("🛑 Terminaison forcée de la session: \(sessionId)", category: .service)
        
        let docRef = db.collection("sessions").document(sessionId)
        let document = try await docRef.getDocument()
        
        guard document.exists, let data = document.data() else {
            Logger.log("❌ Session \(sessionId) introuvable", category: .service)
            throw SessionError.sessionNotFound
        }
        
        try await forceEndSession(documentId: sessionId, data: data)
        
        // Invalider le cache pour cette squad
        if let squadId = data["squadId"] as? String {
            SessionService.shared.invalidateCache(squadId: squadId)
        }
        
        Logger.logSuccess("✅ Session \(sessionId) terminée avec succès", category: .service)
    }
    
    // MARK: - Force End Sessions for Squad
    
    /// Force la terminaison de toutes les sessions actives d'une squad
    ///
    /// - Parameter squadId: ID de la squad
    /// - Returns: Nombre de sessions terminées
    /// - Throws: Erreur Firestore en cas d'échec
    func forceEndSquadSessions(squadId: String) async throws -> Int {
        Logger.log("🧹 Nettoyage des sessions de la squad: \(squadId)", category: .service)
        
        let query = db.collection("sessions")
            .whereField("squadId", isEqualTo: squadId)
            .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
        
        let snapshot = try await query.getDocuments()
        
        Logger.log("🔍 Trouvé \(snapshot.documents.count) sessions actives pour cette squad", category: .service)
        
        var successCount = 0
        
        for doc in snapshot.documents {
            do {
                try await forceEndSession(documentId: doc.documentID, data: doc.data())
                successCount += 1
            } catch {
                Logger.logError(error, context: "forceEndSession(\(doc.documentID))", category: .service)
            }
        }
        
        // Invalider le cache pour cette squad
        SessionService.shared.invalidateCache(squadId: squadId)
        
        Logger.logSuccess("✅ \(successCount)/\(snapshot.documents.count) sessions de la squad nettoyées", category: .service)
        return successCount
    }
    
    // MARK: - Internal Helper
    
    /// Termine une session en utilisant les données brutes (sans décodage du modèle)
    ///
    /// Cette méthode fonctionne même si le modèle `SessionModel` ne peut pas décoder la session.
    ///
    /// - Parameters:
    ///   - documentId: ID du document Firestore
    ///   - data: Données brutes du document
    private func forceEndSession(documentId: String, data: [String: Any]) async throws {
        Logger.log("🔧 Terminaison forcée: \(documentId)", category: .service)
        
        let sessionRef = db.collection("sessions").document(documentId)
        
        // Calculer la durée si possible
        var updateData: [String: Any] = [
            "status": SessionStatus.ended.rawValue,
            "endedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Calculer la durée si startedAt existe
        if let startedAtTimestamp = data["startedAt"] as? Timestamp {
            let startedAt = startedAtTimestamp.dateValue()
            let duration = Date().timeIntervalSince(startedAt)
            updateData["durationSeconds"] = duration
        }
        
        // Mettre à jour la session
        try await sessionRef.updateData(updateData)
        
        // Retirer de la squad
        if let squadId = data["squadId"] as? String {
            let squadRef = db.collection("squads").document(squadId)
            try await squadRef.updateData([
                "activeSessions": FieldValue.arrayRemove([documentId])
            ])
            
            Logger.log("✅ Session retirée de la squad: \(squadId)", category: .service)
        }
        
        Logger.log("✅ Session \(documentId) terminée", category: .service)
    }
    
    // MARK: - Diagnostic
    
    /// Liste toutes les sessions actives avec leurs informations de base
    ///
    /// Utile pour diagnostiquer les problèmes avant de nettoyer
    ///
    /// - Returns: Dictionnaire [sessionId: info]
    func listActiveSessions() async throws -> [String: [String: String]] {
        Logger.log("📋 Récupération de la liste des sessions actives...", category: .service)
        
        let query = db.collection("sessions")
            .whereField("status", in: [SessionStatus.active.rawValue, SessionStatus.paused.rawValue])
        
        let snapshot = try await query.getDocuments()
        
        var result: [String: [String: String]] = [:]
        
        for doc in snapshot.documents {
            let data = doc.data()
            
            var info: [String: String] = [:]
            info["id"] = doc.documentID
            info["status"] = data["status"] as? String ?? "UNKNOWN"
            info["squadId"] = data["squadId"] as? String ?? "UNKNOWN"
            info["creatorId"] = data["creatorId"] as? String ?? "UNKNOWN"
            
            if let startedAt = (data["startedAt"] as? Timestamp)?.dateValue() {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                info["startedAt"] = formatter.string(from: startedAt)
                
                let elapsed = Date().timeIntervalSince(startedAt)
                info["elapsedTime"] = String(format: "%.0f min", elapsed / 60)
            }
            
            result[doc.documentID] = info
        }
        
        Logger.log("📋 Trouvé \(result.count) sessions actives", category: .service)
        return result
    }
    
    // MARK: - Safety Check
    
    /// Vérifie si une session peut être terminée en toute sécurité
    ///
    /// - Parameter sessionId: ID de la session à vérifier
    /// - Returns: `true` si la session peut être terminée
    func canSafelyEndSession(sessionId: String) async -> Bool {
        do {
            let docRef = db.collection("sessions").document(sessionId)
            let document = try await docRef.getDocument()
            
            guard document.exists, let data = document.data() else {
                Logger.log("⚠️ Session \(sessionId) n'existe pas", category: .service)
                return false
            }
            
            // Vérifier le statut
            guard let status = data["status"] as? String,
                  (status == SessionStatus.active.rawValue || status == SessionStatus.paused.rawValue) else {
                Logger.log("⚠️ Session \(sessionId) n'est pas active", category: .service)
                return false
            }
            
            // Vérifier l'âge de la session
            if let startedAt = (data["startedAt"] as? Timestamp)?.dateValue() {
                let elapsed = Date().timeIntervalSince(startedAt)
                
                // Sessions de plus de 24h sont probablement bloquées
                if elapsed > 86400 {
                    Logger.log("⚠️ Session \(sessionId) est active depuis \(elapsed / 3600) heures", category: .service)
                    return true
                }
            }
            
            return true
            
        } catch {
            Logger.logError(error, context: "canSafelyEndSession", category: .service)
            return false
        }
    }
}

// MARK: - SwiftUI Debug View

#if DEBUG
import SwiftUI

/// Vue de debug pour gérer les sessions
///
/// **Usage :**
/// ```swift
/// NavigationLink("🧹 Session Cleanup") {
///     SessionCleanupDebugView()
/// }
/// ```
struct SessionCleanupDebugView: View {
    @State private var activeSessions: [String: [String: String]] = [:]
    @State private var isLoading = false
    @State private var resultMessage: String?
    
    var body: some View {
        List {
            Section {
                Button {
                    Task {
                        await loadActiveSessions()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Recharger la liste")
                    }
                }
                .disabled(isLoading)
            }
            
            Section("Sessions actives") {
                if activeSessions.isEmpty {
                    Text("Aucune session active")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(activeSessions.keys), id: \.self) { sessionId in
                        if let info = activeSessions[sessionId] {
                            SessionInfoRow(sessionId: sessionId, info: info) {
                                await endSession(sessionId)
                            }
                        }
                    }
                }
            }
            
            Section("Actions globales") {
                Button(role: .destructive) {
                    Task {
                        await endAllSessions()
                    }
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Terminer toutes les sessions")
                    }
                }
                .disabled(isLoading || activeSessions.isEmpty)
            }
            
            if let message = resultMessage {
                Section {
                    Text(message)
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Session Cleanup")
        .task {
            await loadActiveSessions()
        }
    }
    
    private func loadActiveSessions() async {
        isLoading = true
        resultMessage = nil
        
        do {
            activeSessions = try await SessionCleanupUtility.shared.listActiveSessions()
        } catch {
            resultMessage = "Erreur : \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func endSession(_ sessionId: String) async {
        isLoading = true
        resultMessage = nil
        
        do {
            try await SessionCleanupUtility.shared.forceEndSessionById(sessionId: sessionId)
            activeSessions.removeValue(forKey: sessionId)
            resultMessage = "✅ Session terminée"
        } catch {
            resultMessage = "❌ Erreur : \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func endAllSessions() async {
        isLoading = true
        resultMessage = nil
        
        do {
            let count = try await SessionCleanupUtility.shared.forceEndAllActiveSessions()
            activeSessions.removeAll()
            resultMessage = "✅ \(count) sessions terminées"
        } catch {
            resultMessage = "❌ Erreur : \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct SessionInfoRow: View {
    let sessionId: String
    let info: [String: String]
    let onEnd: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sessionId)
                .font(.caption.monospaced())
                .foregroundColor(.secondary)
            
            if let status = info["status"] {
                Label(status, systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(status == "ACTIVE" ? .green : .orange)
            }
            
            if let elapsed = info["elapsedTime"] {
                Label(elapsed, systemImage: "clock")
                    .font(.caption)
            }
            
            Button(role: .destructive) {
                Task {
                    await onEnd()
                }
            } label: {
                Text("Terminer")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SessionCleanupDebugView()
    }
}
#endif
