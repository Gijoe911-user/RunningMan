//
//  ParticipantSessionState.swift
//  RunningMan
//
//  État d'un participant dans une session
//

import Foundation

/// État d'un participant dans une session
///
/// Permet de suivre l'état individuel de chaque participant sans affecter
/// la session globale. Un participant peut terminer, abandonner, ou être en pause
/// tandis que d'autres continuent.
///
/// **Principe DRY :**
/// - Session = état global partagé
/// - ParticipantSessionState = état individuel par utilisateur
///
/// **Cycle de vie typique :**
/// ```
/// waiting → active → [paused] → ended
///                  ↘ abandoned
/// ```
///
/// - SeeAlso: `SessionModel.participantStates`
struct ParticipantSessionState: Codable, Hashable {
    
    // MARK: - Properties
    
    /// Statut actuel du participant
    var status: ParticipantStatus
    
    /// Date de démarrage du tracking pour ce participant
    var startedAt: Date?
    
    /// Date de fin du tracking (si terminé ou abandonné)
    var endedAt: Date?
    
    /// Durée totale en pause (cumulée)
    var pausedDuration: TimeInterval = 0
    
    /// Date du dernier début de pause (pour calculer pausedDuration)
    var lastPausedAt: Date?
    
    // MARK: - Computed Properties
    
    /// Durée active effective (sans les pauses)
    var activeDuration: TimeInterval {
        guard let start = startedAt else { return 0 }
        
        let end = endedAt ?? Date()
        let totalDuration = end.timeIntervalSince(start)
        return max(0, totalDuration - pausedDuration)
    }
    
    /// Indique si le participant est actuellement en course
    var isCurrentlyActive: Bool {
        status == .active
    }
    
    /// Indique si le participant a terminé (avec succès ou abandon)
    var hasFinished: Bool {
        status == .ended || status == .abandoned
    }
    
    // MARK: - Initialization
    
    init(
        status: ParticipantStatus = .waiting,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        pausedDuration: TimeInterval = 0,
        lastPausedAt: Date? = nil
    ) {
        self.status = status
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.pausedDuration = pausedDuration
        self.lastPausedAt = lastPausedAt
    }
    
    // MARK: - Status Management
    
    /// Démarre le tracking pour ce participant
    mutating func start() {
        guard status == .waiting else { return }
        status = .active
        startedAt = Date()
    }
    
    /// Met en pause le tracking
    mutating func pause() {
        guard status == .active else { return }
        status = .paused
        lastPausedAt = Date()
    }
    
    /// Reprend le tracking après une pause
    mutating func resume() {
        guard status == .paused, let pauseStart = lastPausedAt else { return }
        
        let pauseDuration = Date().timeIntervalSince(pauseStart)
        pausedDuration += pauseDuration
        lastPausedAt = nil
        status = .active
    }
    
    /// Marque le participant comme ayant terminé
    mutating func finish() {
        guard status == .active || status == .paused else { return }
        
        // Si en pause, ajouter la durée de pause finale
        if status == .paused, let pauseStart = lastPausedAt {
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            pausedDuration += pauseDuration
        }
        
        status = .ended
        endedAt = Date()
        lastPausedAt = nil
    }
    
    /// Marque le participant comme ayant abandonné
    mutating func abandon() {
        guard status == .active || status == .paused else { return }
        
        // Si en pause, ajouter la durée de pause finale
        if status == .paused, let pauseStart = lastPausedAt {
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            pausedDuration += pauseDuration
        }
        
        status = .abandoned
        endedAt = Date()
        lastPausedAt = nil
    }
}

// MARK: - ParticipantStatus

/// Statut d'un participant dans une session
enum ParticipantStatus: String, Codable, CaseIterable {
    /// En attente de démarrage
    case waiting = "WAITING"
    
    /// En course actuellement
    case active = "ACTIVE"
    
    /// En pause
    case paused = "PAUSED"
    
    /// A terminé sa course avec succès
    case ended = "ENDED"
    
    /// A abandonné la course
    case abandoned = "ABANDONED"
    
    // MARK: - UI Helpers
    
    /// Icône SF Symbol
    var icon: String {
        switch self {
        case .waiting:
            return "clock.fill"
        case .active:
            return "figure.run"
        case .paused:
            return "pause.circle.fill"
        case .ended:
            return "checkmark.circle.fill"
        case .abandoned:
            return "xmark.circle.fill"
        }
    }
    
    /// Couleur associée
    var colorName: String {
        switch self {
        case .waiting:
            return "gray"
        case .active:
            return "green"
        case .paused:
            return "orange"
        case .ended:
            return "blue"
        case .abandoned:
            return "red"
        }
    }
    
    /// Nom affiché dans l'UI
    var displayName: String {
        switch self {
        case .waiting:
            return "En attente"
        case .active:
            return "En course"
        case .paused:
            return "En pause"
        case .ended:
            return "Terminé"
        case .abandoned:
            return "Abandonné"
        }
    }
    
    /// Emoji associé
    var emoji: String {
        switch self {
        case .waiting:
            return "⏳"
        case .active:
            return "🏃"
        case .paused:
            return "⏸️"
        case .ended:
            return "🏁"
        case .abandoned:
            return "❌"
        }
    }
}

// MARK: - Extensions

extension ParticipantSessionState {
    /// Crée un état "en attente" pour un nouveau participant
    static func waiting() -> ParticipantSessionState {
        ParticipantSessionState(status: .waiting)
    }
    
    /// Crée un état "actif" avec démarrage immédiat
    static func active() -> ParticipantSessionState {
        ParticipantSessionState(
            status: .active,
            startedAt: Date()
        )
    }
}
