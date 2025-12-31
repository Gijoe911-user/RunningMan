//
//  WeeklyGoal.swift
//  RunningMan
//
//  Objectif hebdomadaire pour le système de progression
//

import Foundation

/// Objectif hebdomadaire de l'utilisateur
///
/// Utilisé pour calculer l'indice de consistance via `ProgressionService`.
/// Un objectif peut être basé sur la distance (km) ou la durée (minutes).
///
/// **Cycle de vie :**
/// 1. Créé le lundi de chaque semaine (automatique ou manuel)
/// 2. Incrémenté après chaque session (`actualValue` += session stats)
/// 3. Marqué `isCompleted` si `actualValue >= targetValue`
/// 4. Archivé après 12 semaines (optimisation Firestore)
///
/// - SeeAlso: `ProgressionService.updateWeeklyGoals(for:with:)`
struct WeeklyGoal: Codable, Identifiable, Hashable {
    
    // MARK: - Properties
    
    /// Identifiant unique
    var id: String = UUID().uuidString
    
    /// Date du lundi de la semaine (à 00:00:00)
    ///
    /// Utilisé pour grouper les objectifs par semaine.
    /// Format : 2025-01-06 00:00:00 (exemple)
    var weekStartDate: Date
    
    /// Type d'objectif (distance ou durée)
    var targetType: GoalType
    
    /// Valeur cible
    ///
    /// - Si `targetType == .distance` : En mètres (ex: 20000 = 20 km)
    /// - Si `targetType == .duration` : En secondes (ex: 3600 = 60 min)
    var targetValue: Double
    
    /// Valeur réalisée (cumulée au fil des sessions)
    ///
    /// Même unité que `targetValue`.
    var actualValue: Double = 0.0
    
    /// Objectif complété (`actualValue >= targetValue`)
    var isCompleted: Bool = false
    
    /// IDs des sessions qui ont contribué à cet objectif
    ///
    /// Permet d'éviter de compter une session deux fois.
    var sessionsContributed: [String] = []
    
    /// Date de création de l'objectif
    var createdAt: Date = Date()
    
    // MARK: - Computed Properties
    
    /// Taux de complétion (0.0 - 1.0)
    ///
    /// Plafonné à 1.0 même si l'utilisateur dépasse l'objectif.
    var completionRate: Double {
        guard targetValue > 0 else { return 0.0 }
        return min(actualValue / targetValue, 1.0)
    }
    
    /// Taux de complétion en pourcentage (0-100)
    var completionPercentage: Int {
        Int(completionRate * 100)
    }
    
    /// Valeur restante pour atteindre l'objectif
    ///
    /// Retourne 0 si déjà complété.
    var remainingValue: Double {
        max(targetValue - actualValue, 0.0)
    }
    
    /// Valeur cible formatée (avec unité)
    var formattedTarget: String {
        switch targetType {
        case .distance:
            return String(format: "%.1f km", targetValue / 1000)
        case .duration:
            return formatDuration(targetValue)
        }
    }
    
    /// Valeur réalisée formatée (avec unité)
    var formattedActual: String {
        switch targetType {
        case .distance:
            return String(format: "%.1f km", actualValue / 1000)
        case .duration:
            return formatDuration(actualValue)
        }
    }
    
    /// Valeur restante formatée (avec unité)
    var formattedRemaining: String {
        switch targetType {
        case .distance:
            return String(format: "%.1f km", remainingValue / 1000)
        case .duration:
            return formatDuration(remainingValue)
        }
    }
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        weekStartDate: Date,
        targetType: GoalType,
        targetValue: Double,
        actualValue: Double = 0.0,
        isCompleted: Bool = false,
        sessionsContributed: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.targetType = targetType
        self.targetValue = targetValue
        self.actualValue = actualValue
        self.isCompleted = isCompleted
        self.sessionsContributed = sessionsContributed
        self.createdAt = createdAt
    }
    
    // MARK: - Methods
    
    /// Ajoute la contribution d'une session à l'objectif
    ///
    /// Vérifie que la session n'a pas déjà été comptée.
    ///
    /// - Parameters:
    ///   - sessionId: ID de la session
    ///   - value: Valeur à ajouter (distance en m ou durée en s)
    /// - Returns: `true` si ajouté, `false` si session déjà comptée
    mutating func addContribution(sessionId: String, value: Double) -> Bool {
        guard !sessionsContributed.contains(sessionId) else {
            return false
        }
        
        actualValue += value
        sessionsContributed.append(sessionId)
        
        // Marquer comme complété si objectif atteint
        if actualValue >= targetValue {
            isCompleted = true
        }
        
        return true
    }
    
    // MARK: - Private Helpers
    
    /// Formate une durée en secondes vers HH:MM:SS ou MM:SS
    ///
    /// - Parameter seconds: Durée en secondes
    /// - Returns: String formatée
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%dh%02dm", hours, minutes)
        } else {
            return String(format: "%dm%02ds", minutes, secs)
        }
    }
    
    // MARK: - Hashable
    
    static func == (lhs: WeeklyGoal, rhs: WeeklyGoal) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Types

/// Type d'objectif hebdomadaire
enum GoalType: String, Codable, CaseIterable {
    /// Objectif de distance (en kilomètres)
    case distance = "DISTANCE"
    
    /// Objectif de durée (en minutes)
    case duration = "DURATION"
    
    /// Nom affiché dans l'UI
    var displayName: String {
        switch self {
        case .distance: return "Distance"
        case .duration: return "Durée"
        }
    }
    
    /// Icône SF Symbol
    var icon: String {
        switch self {
        case .distance: return "location.fill"
        case .duration: return "clock.fill"
        }
    }
    
    /// Unité de mesure
    var unit: String {
        switch self {
        case .distance: return "km"
        case .duration: return "min"
        }
    }
}
