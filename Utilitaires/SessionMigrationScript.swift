//
//  SessionMigrationScript.swift
//  RunningMan
//
//  Script pour diagnostiquer et réparer les sessions corrompues dans Firestore
//
//  USAGE:
//  1. Copier ce script dans un Playground ou un fichier temporaire
//  2. Exécuter pour réparer toutes les sessions
//

import Foundation
import FirebaseFirestore

/// Script de migration pour réparer les sessions corrompues
class SessionMigrationScript {
    
    private let db = Firestore.firestore()
    
    /// Diagnostique une session spécifique
    func diagnoseSession(sessionId: String) async {
        do {
            let doc = try await db.collection("sessions").document(sessionId).getDocument()
            
            guard doc.exists else {
                print("❌ Session \(sessionId) n'existe pas")
                return
            }
            
            let data = doc.data() ?? [:]
            print("📋 Session \(sessionId):")
            print("   Champs présents: \(data.keys.sorted())")
            
            // Vérifier les champs obligatoires
            let requiredFields = [
                "squadId", "creatorId", "startedAt", "status",
                "participants", "sessionType", "totalDistanceMeters",
                "durationSeconds", "averageSpeed"  // ← Probablement manquant
            ]
            
            for field in requiredFields {
                if data[field] != nil {
                    print("   ✅ \(field)")
                } else {
                    print("   ❌ \(field) - MANQUANT")
                }
            }
            
        } catch {
            print("❌ Erreur: \(error)")
        }
    }
    
    /// Répare toutes les sessions d'une squad
    func repairAllSessions(squadId: String) async {
        print("🔧 Réparation des sessions pour squad: \(squadId)")
        
        do {
            let snapshot = try await db.collection("sessions")
                .whereField("squadId", isEqualTo: squadId)
                .getDocuments()
            
            print("📦 \(snapshot.documents.count) sessions trouvées")
            
            var repairedCount = 0
            var failedCount = 0
            
            for doc in snapshot.documents {
                let result = await repairSession(doc: doc)
                if result {
                    repairedCount += 1
                } else {
                    failedCount += 1
                }
            }
            
            print("✅ Réparation terminée:")
            print("   ✅ Réparées: \(repairedCount)")
            print("   ❌ Échecs: \(failedCount)")
            
        } catch {
            print("❌ Erreur: \(error)")
        }
    }
    
    /// Répare une session individuelle
    private func repairSession(doc: QueryDocumentSnapshot) async -> Bool {
        let data = doc.data()
        let sessionId = doc.documentID
        
        // Vérifier si averageSpeed existe
        if data["averageSpeed"] != nil {
            print("ℹ️ Session \(sessionId) - OK (aucune réparation nécessaire)")
            return true
        }
        
        print("🔧 Réparation de \(sessionId)...")
        
        // Ajouter les champs manquants
        var updates: [String: Any] = [:]
        
        if data["averageSpeed"] == nil {
            updates["averageSpeed"] = 0.0
        }
        
        if data["maxSpeed"] == nil {
            updates["maxSpeed"] = 0.0
        }
        
        if data["elevationGain"] == nil {
            updates["elevationGain"] = 0.0
        }
        
        // Mettre à jour Firestore
        do {
            try await db.collection("sessions").document(sessionId).updateData(updates)
            print("   ✅ Session \(sessionId) réparée")
            return true
        } catch {
            print("   ❌ Échec: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Répare TOUTES les sessions de l'app
    func repairAllSessionsGlobal() async {
        print("🌍 Réparation GLOBALE de toutes les sessions...")
        
        do {
            let snapshot = try await db.collection("sessions").getDocuments()
            
            print("📦 \(snapshot.documents.count) sessions trouvées")
            
            var repairedCount = 0
            var failedCount = 0
            
            for doc in snapshot.documents {
                let result = await repairSession(doc: doc)
                if result {
                    repairedCount += 1
                } else {
                    failedCount += 1
                }
            }
            
            print("✅ Réparation globale terminée:")
            print("   ✅ Réparées: \(repairedCount)")
            print("   ❌ Échecs: \(failedCount)")
            
        } catch {
            print("❌ Erreur: \(error)")
        }
    }
}

// MARK: - Usage

/*
 Dans votre AppDelegate ou une vue de debug:
 
 Task {
     let migrationScript = SessionMigrationScript()
     
     // Option 1: Diagnostiquer une session spécifique
     await migrationScript.diagnoseSession(sessionId: "lVuj56YAK8C32QvQDFGG")
     
     // Option 2: Réparer toutes les sessions d'une squad
     await migrationScript.repairAllSessions(squadId: "5wJ3sJuz6k1SXErC5Beo")
     
     // Option 3: Réparer TOUTES les sessions (⚠️ ATTENTION)
     // await migrationScript.repairAllSessionsGlobal()
 }
*/
