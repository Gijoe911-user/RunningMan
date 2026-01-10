//
//  SharedTypes.swift
//  RunningMan
//
//  Types partagés pour l'application
//

import Foundation
import CoreLocation


/// Options de partage pour les messages et notifications
enum SharingScope: String, Codable, CaseIterable, Identifiable {
    case allMySquads = "all_my_squads"
    case allMySessions = "all_my_sessions"
    case onlyOne = "only_one"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .allMySquads:
            return "Toute ma Squad"
        case .allMySessions:
            return "Ma session active"
        case .onlyOne:
            return "Un seul participant"
        }
    }
    
    var icon: String {
        switch self {
        case .allMySquads:
            return "person.3.fill"
        case .allMySessions:
            return "figure.run.circle.fill"
        case .onlyOne:
            return "person.fill"
        }
    }
    
    var description: String {
        switch self {
        case .allMySquads:
            return "Envoyer à tous les membres de ma Squad"
        case .allMySessions:
            return "Envoyer à tous les participants de ma session active"
        case .onlyOne:
            return "Envoyer à un participant spécifique"
        }
    }
}

/// Préférence de lecture automatique des messages
struct MessageReadingPreference: Codable {
    var autoReadDuringTracking: Bool = true  // Lire automatiquement pendant le tracking
    var autoReadVoiceMessages: Bool = true   // Lire les messages vocaux
    var autoReadTextMessages: Bool = true    // Lire les messages texte
    var doNotDisturbMode: Bool = false       // Mode "bulle de course"
}


// MARK: - RunnerLocation
/// Position d'un runner en temps réel
struct RunnerLocation: Identifiable, Codable, Equatable {
    let id: String // User ID
    var displayName: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var photoURL: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Equatable
    static func == (lhs: RunnerLocation, rhs: RunnerLocation) -> Bool {
        lhs.id == rhs.id &&
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.displayName == rhs.displayName
    }
}

// MARK: - Message
/// Message dans le chat d'une session
struct Message: Identifiable, Codable {
    let id: String
    var senderId: String
    var senderName: String
    var content: String
    var timestamp: Date
    var isAudio: Bool
    var audioURL: String?
    var sessionId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case senderName
        case content
        case timestamp
        case isAudio
        case audioURL
        case sessionId
    }
}

// MARK: - CLLocationCoordinate2D Extensions

// Note: On n'ajoute PAS Equatable à CLLocationCoordinate2D car cela peut créer des conflits
// avec les futures versions d'iOS. À la place, utilisez .onReceive() au lieu de .onChange()
extension CLLocationCoordinate2D {
    /// Compare deux coordonnées pour l'égalité
    /// Alternative safe à Equatable pour éviter les conflits avec Apple
    func isEqual(to other: CLLocationCoordinate2D) -> Bool {
        self.latitude == other.latitude && self.longitude == other.longitude
    }
}
