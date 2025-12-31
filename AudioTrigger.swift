//
//  AudioTrigger.swift
//  RunningMan
//
//  Messages vocaux contextuels déclenchés automatiquement
//

import Foundation

/// Trigger audio pour messages vocaux contextuels
///
/// Permet aux supporters (ou à l'app elle-même) d'enregistrer des messages
/// audio déclenchés selon des conditions GPS, d'allure ou de fréquence cardiaque.
///
/// **Cas d'usage :**
/// - Supporter enregistre un message d'encouragement au 30ème km d'un marathon
/// - Coach vocal activé quand l'allure descend sous 5:00/km
/// - Alerte santé si BPM > 180
///
/// **Workflow :**
/// 1. Utilisateur enregistre un message vocal
/// 2. Upload vers Firebase Storage → `audioUrl`
/// 3. `AudioTriggerService` surveille les conditions en temps réel
/// 4. Quand condition remplie → Diffusion du message (superposé à la musique)
/// 5. Marqué `hasBeenTriggered = true` pour éviter la répétition
///
/// - SeeAlso: `AudioTriggerService`, `MusicManager`
struct AudioTrigger: Codable, Identifiable, Hashable {
    
    // MARK: - Properties
    
    /// Identifiant unique
    var id: String = UUID().uuidString
    
    // MARK: Audio
    
    /// URL du fichier audio dans Firebase Storage
    ///
    /// Format : `gs://runningman.appspot.com/audio_triggers/{id}.m4a`
    var audioUrl: String
    
    /// Durée du message audio (en secondes)
    ///
    /// Utilisé pour gérer le volume de la musique pendant la diffusion.
    var durationSeconds: Double = 0.0
    
    // MARK: Identité de l'Émetteur
    
    /// ID de l'utilisateur qui a enregistré le message
    var fromUserId: String
    
    /// Nom affiché de l'émetteur
    var fromUserName: String
    
    /// Avatar de l'émetteur (optionnel)
    var fromUserAvatarUrl: String?
    
    // MARK: Condition de Déclenchement
    
    /// Type de trigger (distance, allure, BPM)
    var triggerType: TriggerType
    
    /// Valeur seuil du trigger
    ///
    /// **Unités selon le type :**
    /// - `.distanceKm` : Kilomètres (ex: 30.0 = au 30ème km)
    /// - `.pace` : Minutes par km (ex: 5.0 = 5:00/km)
    /// - `.heartRate` : BPM (ex: 180)
    var triggerValue: Double
    
    /// Condition de comparaison (égal, supérieur, inférieur)
    var comparison: TriggerComparison = .greaterThanOrEqual
    
    // MARK: Portée
    
    /// ID de la session (si trigger spécifique à une session)
    ///
    /// Si `nil`, le trigger est global à la squad.
    var sessionId: String?
    
    /// ID de la squad (si trigger global à la squad)
    ///
    /// Si `nil`, le trigger est personnel (seul l'utilisateur l'entend).
    var squadId: String?
    
    // MARK: État
    
    /// Indique si le trigger a déjà été déclenché
    ///
    /// Évite de rejouer le message plusieurs fois.
    var hasBeenTriggered: Bool = false
    
    /// Timestamp du déclenchement
    var triggeredAt: Date?
    
    /// Nombre de fois que le message a été entendu (stats)
    var playCount: Int = 0
    
    // MARK: Metadata
    
    /// Date de création du trigger
    var createdAt: Date = Date()
    
    /// Expiration du trigger (optionnel)
    ///
    /// Utile pour les triggers de session : auto-suppression après la session.
    var expiresAt: Date?
    
    // MARK: - Computed Properties
    
    /// Texte formaté de la condition
    ///
    /// Ex: "Au 30ème km", "Si allure < 5:00/km", "Si BPM > 180"
    var formattedCondition: String {
        let symbol = comparison.symbol
        let valueText: String
        
        switch triggerType {
        case .distanceKm:
            valueText = String(format: "%.1f km", triggerValue)
        case .pace:
            let minutes = Int(triggerValue)
            let seconds = Int((triggerValue - Double(minutes)) * 60)
            valueText = String(format: "%d:%02d/km", minutes, seconds)
        case .heartRate:
            valueText = "\(Int(triggerValue)) BPM"
        }
        
        if comparison == .equal {
            return "À \(valueText)"
        } else {
            return "Si \(triggerType.displayName) \(symbol) \(valueText)"
        }
    }
    
    /// Durée formatée du message audio
    var formattedDuration: String {
        let minutes = Int(durationSeconds) / 60
        let seconds = Int(durationSeconds) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Indique si le trigger est encore actif (non expiré)
    var isActive: Bool {
        guard let expiresAt = expiresAt else { return true }
        return Date() < expiresAt
    }
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        audioUrl: String,
        durationSeconds: Double = 0.0,
        fromUserId: String,
        fromUserName: String,
        fromUserAvatarUrl: String? = nil,
        triggerType: TriggerType,
        triggerValue: Double,
        comparison: TriggerComparison = .greaterThanOrEqual,
        sessionId: String? = nil,
        squadId: String? = nil,
        hasBeenTriggered: Bool = false,
        triggeredAt: Date? = nil,
        playCount: Int = 0,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.audioUrl = audioUrl
        self.durationSeconds = durationSeconds
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.fromUserAvatarUrl = fromUserAvatarUrl
        self.triggerType = triggerType
        self.triggerValue = triggerValue
        self.comparison = comparison
        self.sessionId = sessionId
        self.squadId = squadId
        self.hasBeenTriggered = hasBeenTriggered
        self.triggeredAt = triggeredAt
        self.playCount = playCount
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    // MARK: - Methods
    
    /// Vérifie si la condition est remplie
    ///
    /// - Parameters:
    ///   - currentValue: Valeur actuelle (distance, allure, BPM)
    /// - Returns: `true` si le trigger doit se déclencher
    func shouldTrigger(currentValue: Double) -> Bool {
        guard !hasBeenTriggered else { return false }
        guard isActive else { return false }
        
        switch comparison {
        case .equal:
            return abs(currentValue - triggerValue) < 0.1 // Tolérance 100m ou 0.1 min/km
        case .greaterThan:
            return currentValue > triggerValue
        case .greaterThanOrEqual:
            return currentValue >= triggerValue
        case .lessThan:
            return currentValue < triggerValue
        case .lessThanOrEqual:
            return currentValue <= triggerValue
        }
    }
    
    /// Marque le trigger comme déclenché
    mutating func markAsTriggered() {
        hasBeenTriggered = true
        triggeredAt = Date()
        playCount += 1
    }
    
    // MARK: - Hashable
    
    static func == (lhs: AudioTrigger, rhs: AudioTrigger) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Types

/// Type de trigger audio
enum TriggerType: String, Codable, CaseIterable {
    /// Déclenchement basé sur la distance parcourue
    case distanceKm = "DISTANCE_KM"
    
    /// Déclenchement basé sur l'allure actuelle
    case pace = "PACE"
    
    /// Déclenchement basé sur la fréquence cardiaque
    case heartRate = "HEART_RATE"
    
    /// Nom affiché dans l'UI
    var displayName: String {
        switch self {
        case .distanceKm: return "Distance"
        case .pace: return "Allure"
        case .heartRate: return "Rythme cardiaque"
        }
    }
    
    /// Icône SF Symbol
    var icon: String {
        switch self {
        case .distanceKm: return "location.fill"
        case .pace: return "speedometer"
        case .heartRate: return "heart.fill"
        }
    }
}

/// Opérateur de comparaison pour le trigger
enum TriggerComparison: String, Codable {
    case equal = "EQUAL"
    case greaterThan = "GREATER_THAN"
    case greaterThanOrEqual = "GREATER_THAN_OR_EQUAL"
    case lessThan = "LESS_THAN"
    case lessThanOrEqual = "LESS_THAN_OR_EQUAL"
    
    /// Symbole mathématique
    var symbol: String {
        switch self {
        case .equal: return "="
        case .greaterThan: return ">"
        case .greaterThanOrEqual: return "≥"
        case .lessThan: return "<"
        case .lessThanOrEqual: return "≤"
        }
    }
}
