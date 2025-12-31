//
//  TrainingProgramService.swift
//  RunningMan
//
//  Service pour gérer les programmes d'entraînement
//

import Foundation
import FirebaseFirestore

class TrainingProgramService {
    
    static let shared = TrainingProgramService()
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    private init() {}
    
    // MARK: - CRUD Operations
    
    /// Crée un nouveau programme d'entraînement
    func createProgram(_ program: TrainingProgram, squadId: String) async throws -> TrainingProgram {
        let ref = db.collection("squads")
            .document(squadId)
            .collection("trainingPrograms")
            .document()
        
        var newProgram = program
        newProgram.id = ref.documentID
        
        try ref.setData(from: newProgram)
        
        Logger.logSuccess("✅ Programme créé: \(program.name)", category: .service)
        return newProgram
    }
    
    /// Récupère tous les programmes d'une squad
    func getPrograms(squadId: String) async throws -> [TrainingProgram] {
        let snapshot = try await db.collection("squads")
            .document(squadId)
            .collection("trainingPrograms")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let programs = snapshot.documents.compactMap { doc -> TrainingProgram? in
            try? doc.data(as: TrainingProgram.self)
        }
        
        Logger.log("📋 \(programs.count) programmes récupérés", category: .service)
        return programs
    }
    
    /// Récupère les programmes d'un utilisateur
    func getUserPrograms(squadId: String, userId: String) async throws -> [TrainingProgram] {
        let snapshot = try await db.collection("squads")
            .document(squadId)
            .collection("trainingPrograms")
            .whereField("createdBy", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let programs = snapshot.documents.compactMap { doc -> TrainingProgram? in
            try? doc.data(as: TrainingProgram.self)
        }
        
        return programs
    }
    
    /// Récupère les programmes publics d'une squad
    func getPublicPrograms(squadId: String) async throws -> [TrainingProgram] {
        let snapshot = try await db.collection("squads")
            .document(squadId)
            .collection("trainingPrograms")
            .whereField("isPublic", isEqualTo: true)
            .order(by: "usageCount", descending: true)
            .getDocuments()
        
        let programs = snapshot.documents.compactMap { doc -> TrainingProgram? in
            try? doc.data(as: TrainingProgram.self)
        }
        
        return programs
    }
    
    /// Met à jour un programme
    func updateProgram(_ program: TrainingProgram, squadId: String) async throws {
        guard let programId = program.id else {
            throw NSError(domain: "TrainingProgram", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Programme sans ID"
            ])
        }
        
        var updatedProgram = program
        updatedProgram.updatedAt = Date()
        
        let ref = db.collection("squads")
            .document(squadId)
            .collection("trainingPrograms")
            .document(programId)
        
        try ref.setData(from: updatedProgram)
        
        Logger.logSuccess("✅ Programme mis à jour", category: .service)
    }
    
    /// Supprime un programme
    func deleteProgram(programId: String, squadId: String) async throws {
        try await db.collection("squads")
            .document(squadId)
            .collection("trainingPrograms")
            .document(programId)
            .delete()
        
        Logger.logSuccess("🗑️ Programme supprimé", category: .service)
    }
    
    /// Incrémente le compteur d'utilisation
    func incrementUsageCount(programId: String, squadId: String) async throws {
        let ref = db.collection("squads")
            .document(squadId)
            .collection("trainingPrograms")
            .document(programId)
        
        try await ref.updateData([
            "usageCount": FieldValue.increment(Int64(1))
        ])
    }
    
    // MARK: - Import / Export
    
    /// Exporte un programme en JSON
    func exportProgram(_ program: TrainingProgram) throws -> URL {
        let jsonData = try program.exportToJSON()
        
        // Créer un fichier temporaire
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(program.exportFilename)
        
        try jsonData.write(to: fileURL)
        
        Logger.logSuccess("✅ Programme exporté: \(fileURL.lastPathComponent)", category: .service)
        return fileURL
    }
    
    /// Importe un programme depuis JSON et le sauvegarde
    func importProgram(from url: URL, squadId: String, userId: String) async throws -> TrainingProgram {
        let jsonData = try Data(contentsOf: url)
        var program = try TrainingProgram.importFromJSON(data: jsonData)
        
        // Remplacer le créateur par l'utilisateur actuel
        program.createdBy = userId
        program.createdAt = Date()
        program.updatedAt = Date()
        
        // Sauvegarder dans Firestore
        return try await createProgram(program, squadId: squadId)
    }
    
    // MARK: - Associations Session <-> Program
    
    /// Associe un programme à une session
    func attachProgramToSession(
        programId: String,
        sessionId: String,
        squadId: String
    ) async throws {
        // Mettre à jour la session avec l'ID du programme
        try await db.collection("sessions")
            .document(sessionId)
            .updateData([
                "trainingProgramId": programId,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        
        // Incrémenter le compteur d'usage du programme
        try await incrementUsageCount(programId: programId, squadId: squadId)
        
        Logger.logSuccess("✅ Programme associé à la session", category: .service)
    }
    
    /// Récupère le programme associé à une session
    func getProgramForSession(sessionId: String, squadId: String) async throws -> TrainingProgram? {
        // Récupérer la session
        let sessionDoc = try await db.collection("sessions")
            .document(sessionId)
            .getDocument()
        
        guard let programId = sessionDoc.data()?["trainingProgramId"] as? String else {
            return nil
        }
        
        // Récupérer le programme
        let programDoc = try await db.collection("squads")
            .document(squadId)
            .collection("trainingPrograms")
            .document(programId)
            .getDocument()
        
        return try? programDoc.data(as: TrainingProgram.self)
    }
}
