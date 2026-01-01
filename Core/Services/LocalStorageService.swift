//
//  LocalStorageService.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 23/12/2025.
//

import Foundation
import UIKit
import AVFoundation

/// Service de stockage local pour les images et fichiers audio
/// Alternative gratuite à Firebase Storage
class LocalStorageService {
    
    static let shared = LocalStorageService()
    
    private init() {
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Directories
    
    /// Dossiers de stockage local
    enum StorageDirectory: String {
        case userProfiles = "UserProfiles"
        case squadProfiles = "SquadProfiles"
        case sessionPhotos = "SessionPhotos"
        case audioMessages = "AudioMessages"
        case temp = "Temp"
    }
    
    /// Obtient le chemin du dossier Documents
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Crée les dossiers nécessaires s'ils n'existent pas
    private func createDirectoriesIfNeeded() {
        let directories: [StorageDirectory] = [
            .userProfiles,
            .squadProfiles,
            .sessionPhotos,
            .audioMessages,
            .temp
        ]
        
        for directory in directories {
            let path = documentsDirectory.appendingPathComponent(directory.rawValue)
            if !FileManager.default.fileExists(atPath: path.path) {
                try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
                Logger.log("Dossier créé: \(directory.rawValue)", category: .general)
            }
        }
    }
    
    // MARK: - Save Image
    
    /// Sauvegarde une image localement
    /// - Parameters:
    ///   - image: L'image à sauvegarder
    ///   - directory: Le dossier de destination
    ///   - filename: Le nom du fichier (sans extension)
    /// - Returns: Le chemin local du fichier sauvegardé
    func saveImage(
        _ image: UIImage,
        in directory: StorageDirectory,
        filename: String
    ) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            Logger.logError(
                NSError(domain: "LocalStorage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l'image en JPEG"]),
                context: "saveImage",
                category: .general
            )
            return nil
        }
        
        let fileURL = documentsDirectory
            .appendingPathComponent(directory.rawValue)
            .appendingPathComponent("\(filename).jpg")
        
        do {
            try data.write(to: fileURL)
            let relativePath = "\(directory.rawValue)/\(filename).jpg"
            Logger.logSuccess("Image sauvegardée: \(relativePath)", category: .general)
            return relativePath
        } catch {
            Logger.logError(error, context: "saveImage", category: .general)
            return nil
        }
    }
    
    // MARK: - Load Image
    
    /// Charge une image depuis le stockage local
    /// - Parameter path: Chemin relatif de l'image (ex: "UserProfiles/user123.jpg")
    /// - Returns: L'image chargée ou nil si introuvable
    func loadImage(from path: String) -> UIImage? {
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Logger.logWarning("Image introuvable: \(path)", category: .general)
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // MARK: - Save Audio
    
    /// Sauvegarde un fichier audio localement
    /// - Parameters:
    ///   - sourceURL: URL temporaire du fichier audio enregistré
    ///   - filename: Nom du fichier (sans extension)
    /// - Returns: Le chemin local du fichier sauvegardé
    func saveAudio(
        from sourceURL: URL,
        filename: String
    ) -> String? {
        let destinationURL = documentsDirectory
            .appendingPathComponent(StorageDirectory.audioMessages.rawValue)
            .appendingPathComponent("\(filename).m4a")
        
        do {
            // Copie le fichier temporaire vers le dossier permanent
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            let relativePath = "\(StorageDirectory.audioMessages.rawValue)/\(filename).m4a"
            Logger.logSuccess("Audio sauvegardé: \(relativePath)", category: .audio)
            return relativePath
        } catch {
            Logger.logError(error, context: "saveAudio", category: .audio)
            return nil
        }
    }
    
    // MARK: - Get Audio URL
    
    /// Récupère l'URL complète d'un fichier audio
    /// - Parameter path: Chemin relatif (ex: "AudioMessages/msg123.m4a")
    /// - Returns: URL complète du fichier
    func getAudioURL(from path: String) -> URL? {
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Logger.logWarning("Fichier audio introuvable: \(path)", category: .audio)
            return nil
        }
        
        return fileURL
    }
    
    // MARK: - Delete File
    
    /// Supprime un fichier du stockage local
    /// - Parameter path: Chemin relatif du fichier
    func deleteFile(at path: String) {
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Logger.logWarning("Fichier à supprimer introuvable: \(path)", category: .general)
            return
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            Logger.logSuccess("Fichier supprimé: \(path)", category: .general)
        } catch {
            Logger.logError(error, context: "deleteFile", category: .general)
        }
    }
    
    // MARK: - Get File Size
    
    /// Récupère la taille d'un fichier
    /// - Parameter path: Chemin relatif du fichier
    /// - Returns: Taille en octets ou nil si erreur
    func getFileSize(at path: String) -> Int64? {
        let fileURL = documentsDirectory.appendingPathComponent(path)
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int64
        } catch {
            Logger.logError(error, context: "getFileSize", category: .general)
            return nil
        }
    }
    
    // MARK: - Clear Cache
    
    /// Supprime tous les fichiers temporaires
    func clearTempFiles() {
        let tempURL = documentsDirectory.appendingPathComponent(StorageDirectory.temp.rawValue)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: tempURL, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            Logger.logSuccess("Fichiers temporaires supprimés", category: .general)
        } catch {
            Logger.logError(error, context: "clearTempFiles", category: .general)
        }
    }
    
    // MARK: - Calculate Total Storage Used
    
    /// Calcule l'espace de stockage total utilisé par l'app
    /// - Returns: Taille en octets
    func getTotalStorageUsed() -> Int64 {
        var totalSize: Int64 = 0
        
        let directories: [StorageDirectory] = [
            .userProfiles,
            .squadProfiles,
            .sessionPhotos,
            .audioMessages
        ]
        
        for directory in directories {
            let directoryURL = documentsDirectory.appendingPathComponent(directory.rawValue)
            
            if let files = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.fileSizeKey]) {
                for file in files {
                    if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
            }
        }
        
        return totalSize
    }
    
    /// Formate la taille en string lisible (ex: "2.5 MB")
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Helper Extensions

extension LocalStorageService {
    
    /// Génère un nom de fichier unique basé sur un timestamp
    static func generateUniqueFilename(prefix: String = "file") -> String {
        let timestamp = Date().timeIntervalSince1970
        let randomSuffix = UUID().uuidString.prefix(8)
        return "\(prefix)_\(Int(timestamp))_\(randomSuffix)"
    }
}
