//
//  ProgressionColor.swift
//  RunningMan
//
//  Couleur de progression selon le taux de consistance
//

import SwiftUI

/// Couleur de progression selon le taux de consistance
///
/// Utilisée pour afficher visuellement l'indice de consistance d'un utilisateur.
///
/// **Seuils :**
/// - `excellent` : ≥ 75% - L'utilisateur maintient une excellente régularité
/// - `warning` : 50-74% - La régularité diminue, attention requise
/// - `critical` : < 50% - Réajustement suggéré
///
/// - SeeAlso: `ProgressionService.getProgressionColor(for:)`
enum ProgressionColor: String, Codable {
    /// Excellent (≥ 75%)
    case excellent = "GREEN"
    
    /// Alerte (50-74%)
    case warning = "YELLOW"
    
    /// Critique (< 50%)
    case critical = "RED"
    
    // MARK: - Computed Properties
    
    /// Couleur SwiftUI correspondante
    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .warning:
            return .yellow
        case .critical:
            return .red
        }
    }
    
    /// Nom affiché dans l'UI
    var displayName: String {
        switch self {
        case .excellent:
            return "Excellence"
        case .warning:
            return "Alerte"
        case .critical:
            return "Critique"
        }
    }
    
    /// Description détaillée pour l'utilisateur
    var description: String {
        switch self {
        case .excellent:
            return "Vous maintenez une excellente régularité !"
        case .warning:
            return "Attention, votre régularité diminue"
        case .critical:
            return "Reprenez votre rythme pour améliorer votre consistance"
        }
    }
    
    /// Icône SF Symbol
    var icon: String {
        switch self {
        case .excellent:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.circle.fill"
        }
    }
    
    /// Emoji associé
    var emoji: String {
        switch self {
        case .excellent:
            return "🔥"
        case .warning:
            return "⚠️"
        case .critical:
            return "📉"
        }
    }
}
