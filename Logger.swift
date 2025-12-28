//
//  Logger.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 20/12/2025.
//

import Foundation
import OSLog

/// Système de logging centralisé pour l'application
/// Utilise OSLog pour une performance optimale et un débogage efficace
enum Logger {
    
    /// Active/désactive les logs en mode debug
    /// À mettre sur `false` en production
    static var isDebugMode = true
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.runningman.app"
    
    /// Catégories de logs pour une meilleure organisation
    enum Category: String {
        case general = "General"
        case auth = "Auth"  // Renommé de 'authentication' à 'auth' pour éviter ambiguïté
        case firebase = "Firebase"
        case location = "Location"
        case audio = "Audio"
        case session = "Session"
        case squads = "Squads"  // Renommé de 'squad' à 'squads' pour éviter ambiguïté
        case network = "Network"
        case service = "Service"  // Pour les services généraux (SessionService, etc.)
    }
    
    /// Log un message dans la console avec catégorisation
    /// - Parameters:
    ///   - message: Le message à logger
    ///   - category: La catégorie du log (défaut: .general)
    ///   - type: Le type de log OSLog (défaut: .debug)
    static func log(
        _ message: String,
        category: Category = .general,
        type: OSLogType = .debug
    ) {
        guard isDebugMode else { return }
        
        let logger = OSLog(subsystem: subsystem, category: category.rawValue)
        os_log("%{public}@", log: logger, type: type, message)
    }
    
    /// Log une erreur avec contexte
    /// - Parameters:
    ///   - error: L'erreur à logger
    ///   - context: Le contexte où l'erreur s'est produite
    ///   - category: La catégorie du log
    static func logError(
        _ error: Error,
        context: String,
        category: Category = .general
    ) {
        guard isDebugMode else { return }
        
        let logger = OSLog(subsystem: subsystem, category: category.rawValue)
        let message = "❌ ERROR in \(context): \(error.localizedDescription)"
        os_log("%{public}@", log: logger, type: .error, message)
    }
    
    /// Log un succès d'opération
    /// - Parameters:
    ///   - message: Message de succès
    ///   - category: Catégorie du log
    static func logSuccess(
        _ message: String,
        category: Category = .general
    ) {
        guard isDebugMode else { return }
        
        let logger = OSLog(subsystem: subsystem, category: category.rawValue)
        os_log("✅ %{public}@", log: logger, type: .info, message)
    }
    
    /// Log un avertissement
    /// - Parameters:
    ///   - message: Message d'avertissement
    ///   - category: Catégorie du log
    static func logWarning(
        _ message: String,
        category: Category = .general
    ) {
        guard isDebugMode else { return }
        
        let logger = OSLog(subsystem: subsystem, category: category.rawValue)
        os_log("⚠️ %{public}@", log: logger, type: .default, message)
    }
}
