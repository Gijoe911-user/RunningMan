//
//  MigrationScript.swift
//  RunningMan
//
//  Script de migration pour passer de squadIds à squads
//  À exécuter UNE SEULE FOIS pour migrer les données existantes
//

import Foundation
import FirebaseFirestore

/// Script de migration pour adapter les documents utilisateurs au nouveau modèle
class UserModelMigrationScript {
    
    private let db = Firestore.firestore()
    
    /// Migre tous les utilisateurs de squadIds vers squads
    func migrateAllUsers() async throws {
        Logger.log("🔄 Début de la migration des utilisateurs...", category: .auth)
        
        let usersRef = db.collection("users")
        let snapshot = try await usersRef.getDocuments()
        
        var migratedCount = 0
        var skippedCount = 0
        var errorCount = 0
        
        for document in snapshot.documents {
            do {
                let data = document.data()
                
                // Vérifier si l'ancien champ existe
                if let squadIds = data["squadIds"] as? [String] {
                    Logger.log("Migration utilisateur: \(document.documentID)", category: .auth)
                    
                    // Créer le nouveau champ
                    try await document.reference.updateData([
                        "squads": squadIds,
                        "squadIds": FieldValue.delete() // Supprimer l'ancien champ
                    ])
                    
                    migratedCount += 1
                    Logger.logSuccess("✅ Utilisateur \(document.documentID) migré", category: .auth)
                } else if data["squads"] != nil {
                    // L'utilisateur est déjà migré
                    skippedCount += 1
                } else {
                    // Aucun champ squad, créer un array vide
                    try await document.reference.updateData([
                        "squads": []
                    ])
                    migratedCount += 1
                }
            } catch {
                errorCount += 1
                Logger.logError(error, context: "Migration utilisateur \(document.documentID)", category: .auth)
            }
        }
        
        Logger.logSuccess("""
        🎉 Migration terminée:
        - Migrés: \(migratedCount)
        - Déjà à jour: \(skippedCount)
        - Erreurs: \(errorCount)
        """, category: .auth)
    }
    
    /// Migre un seul utilisateur (pour test)
    func migrateUser(userId: String) async throws {
        Logger.log("🔄 Migration de l'utilisateur: \(userId)", category: .auth)
        
        let userRef = db.collection("users").document(userId)
        let document = try await userRef.getDocument()
        
        guard document.exists else {
            Logger.logWarning("⚠️ Utilisateur introuvable", category: .auth)
            return
        }
        
        let data = document.data() ?? [:]
        
        if let squadIds = data["squadIds"] as? [String] {
            try await userRef.updateData([
                "squads": squadIds,
                "squadIds": FieldValue.delete()
            ])
            Logger.logSuccess("✅ Utilisateur migré avec succès", category: .auth)
        } else if data["squads"] != nil {
            Logger.log("ℹ️ Utilisateur déjà migré", category: .auth)
        } else {
            try await userRef.updateData([
                "squads": []
            ])
            Logger.logSuccess("✅ Champ squads créé", category: .auth)
        }
    }
    
    /// Vérifie l'état de migration de tous les utilisateurs
    func checkMigrationStatus() async throws -> (migrated: Int, needMigration: Int) {
        let usersRef = db.collection("users")
        let snapshot = try await usersRef.getDocuments()
        
        var migrated = 0
        var needMigration = 0
        
        for document in snapshot.documents {
            let data = document.data()
            
            if data["squads"] != nil {
                migrated += 1
            } else if data["squadIds"] != nil {
                needMigration += 1
            }
        }
        
        Logger.log("""
        📊 État de migration:
        - Migrés: \(migrated)
        - À migrer: \(needMigration)
        """, category: .auth)
        
        return (migrated, needMigration)
    }
}

// MARK: - Comment utiliser ce script

/*
 Pour exécuter ce script de migration:
 
 1. Dans votre AppDelegate ou App principale, ajoutez :
 
    let migrationScript = UserModelMigrationScript()
    
    Task {
        do {
            // Vérifier l'état
            let status = try await migrationScript.checkMigrationStatus()
            
            if status.needMigration > 0 {
                print("⚠️ \(status.needMigration) utilisateurs nécessitent une migration")
                
                // Lancer la migration
                try await migrationScript.migrateAllUsers()
            } else {
                print("✅ Tous les utilisateurs sont à jour")
            }
        } catch {
            print("❌ Erreur de migration: \(error)")
        }
    }
 
 2. OU pour un utilisateur spécifique :
 
    Task {
        try await migrationScript.migrateUser(userId: "USER_ID_HERE")
    }
 
 3. N'oubliez pas de SUPPRIMER ce code après la migration !
 */
