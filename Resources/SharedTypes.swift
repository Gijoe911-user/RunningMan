//
//  SharedTypes.swift
//  RunningMan
//
//  Types partagés pour l'application
//

import Foundation
import CoreLocation

// MARK: - RunnerLocation
/// Position d'un runner en temps réel
struct RunnerLocation: Identifiable, Codable {
    let id: String // User ID
    var displayName: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var photoURL: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
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
