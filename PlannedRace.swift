//
//  PlannedRace.swift
//  RunningMan
//
//  Course planifiée avec activation automatique
//

import Foundation
import FirebaseFirestore

/// Course planifiée avec activation automatique
///
/// Les courses planifiées s'activent automatiquement à **H-1** via
/// Cloud Functions Firebase ou un service de scheduling.
///
/// **Workflow :**
/// 1. Admin crée une `PlannedRace` avec date/heure de départ
/// 2. À H-1, Cloud Function crée automatiquement une `SessionModel`
/// 3. Tous les membres de la squad reçoivent une notification
/// 4. La session s'active à H pile (sans intervention manuelle)
///
/// **Cas d'usage :**
/// - Marathons officiels
/// - Courses d'entreprise
/// - Événements squad synchronisés
///
/// - SeeAlso: `SessionService.createSessionFromPlannedRace(_:)`
struct PlannedRace: Codable, Identifiable, Hashable {
    
    // MARK: - Properties
    
    /// Identifiant unique
    var id: String = UUID().uuidString
    
    /// Nom de la course
    ///
    /// Ex: "Marathon de Paris 2025", "10k Squad Challenge"
    var name: String
    
    /// Date et heure de départ prévue
    ///
    /// **Important :** Utilisé par la Cloud Function pour déclencher
    /// l'activation à H-1.
    var scheduledDate: Date
    
    /// Lieu de la course
    ///
    /// Ex: "Champs-Élysées, Paris", "Central Park, NYC"
    var location: String
    
    /// Distance de la course (en mètres)
    ///
    /// Optionnel : peut être `nil` pour courses à durée libre.
    var distance: Double?
    
    /// ID de la squad concernée
    var squadId: String
    
    // MARK: Métadonnées Compétition
    
    /// Numéro de dossard de l'utilisateur
    ///
    /// Permet d'identifier le coureur dans les résultats officiels.
    var bibNumber: String?
    
    /// URL de tracking officiel
    ///
    /// Lien vers le système de chronométrage externe (ex: LiveTrail).
    var officialTrackingUrl: String?
    
    // MARK: État d'Activation
    
    /// Indique si la session a été créée automatiquement
    ///
    /// Passe à `true` quand la Cloud Function a créé la session à H-1.
    var isActivated: Bool = false
    
    /// ID de la session créée automatiquement
    ///
    /// Lien vers `SessionModel.id` une fois activée.
    var activatedSessionId: String?
    
    /// Date effective d'activation
    ///
    /// Timestamp de création de la session (normalement H-1).
    var activatedAt: Date?
    
    // MARK: Metadata
    
    /// ID de l'utilisateur qui a créé la course planifiée
    var createdBy: String
    
    /// Date de création de la planification
    var createdAt: Date = Date()
    
    /// Dernière modification
    var updatedAt: Date = Date()
    
    // MARK: - Computed Properties
    
    /// Temps restant avant le départ
    ///
    /// Négatif si la course est passée.
    var timeUntilStart: TimeInterval {
        scheduledDate.timeIntervalSinceNow
    }
    
    /// Indique si la course est dans le futur
    var isUpcoming: Bool {
        timeUntilStart > 0
    }
    
    /// Indique si la course est dans moins de 24h
    var isImminent: Bool {
        timeUntilStart > 0 && timeUntilStart < 86400 // 24h en secondes
    }
    
    /// Distance formatée (avec unité)
    var formattedDistance: String {
        guard let distance = distance else { return "Distance libre" }
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    /// Date formatée (ex: "Dim 12 Jan 2025 à 9h00")
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM yyyy 'à' HH'h'mm"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: scheduledDate)
    }
    
    /// Temps restant formaté (ex: "Dans 5 jours", "Dans 2h30")
    var formattedTimeUntilStart: String {
        guard isUpcoming else { return "Passée" }
        
        let hours = Int(timeUntilStart) / 3600
        let days = hours / 24
        
        if days > 0 {
            return "Dans \(days) jour\(days > 1 ? "s" : "")"
        } else if hours > 0 {
            let remainingMinutes = (Int(timeUntilStart) % 3600) / 60
            return "Dans \(hours)h\(remainingMinutes > 0 ? String(format: "%02d", remainingMinutes) : "")"
        } else {
            let minutes = Int(timeUntilStart) / 60
            return "Dans \(minutes) min"
        }
    }
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        name: String,
        scheduledDate: Date,
        location: String,
        distance: Double? = nil,
        squadId: String,
        bibNumber: String? = nil,
        officialTrackingUrl: String? = nil,
        isActivated: Bool = false,
        activatedSessionId: String? = nil,
        activatedAt: Date? = nil,
        createdBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.scheduledDate = scheduledDate
        self.location = location
        self.distance = distance
        self.squadId = squadId
        self.bibNumber = bibNumber
        self.officialTrackingUrl = officialTrackingUrl
        self.isActivated = isActivated
        self.activatedSessionId = activatedSessionId
        self.activatedAt = activatedAt
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Methods
    
    /// Marque la course comme activée avec l'ID de session associée
    ///
    /// Appelé par la Cloud Function après création de la session.
    ///
    /// - Parameter sessionId: ID de la session créée
    mutating func markAsActivated(sessionId: String) {
        isActivated = true
        activatedSessionId = sessionId
        activatedAt = Date()
        updatedAt = Date()
    }
    
    // MARK: - Hashable
    
    static func == (lhs: PlannedRace, rhs: PlannedRace) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
