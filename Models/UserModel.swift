//
//  UserModel.swift
//  RunningMan
//
//  Created by jocelyn GIARD on 20/12/2025.
//

import Foundation
import FirebaseFirestore

/// Modèle représentant un utilisateur de l'application
/// Synchronisé avec Firestore dans la collection `users`
struct UserModel: Identifiable, Codable {
    
    /// ID unique de l'utilisateur (correspondant à Firebase Auth UID)
    @DocumentID var id: String?
    
    /// Nom d'affichage de l'utilisateur
    var displayName: String
    
    /// Email de l'utilisateur (depuis Firebase Auth)
    var email: String
    
    /// URL de la photo de profil (Firebase Storage)
    var photoURL: String?
    
    /// Date de création du compte
    var createdAt: Date
    
    /// Liste des IDs de squads auxquelles l'utilisateur appartient
    var squadIds: [String]
    
    /// Préférences utilisateur
    var preferences: UserPreferences
    
    /// Statistiques globales de l'utilisateur
    var statistics: UserStatistics?
    
    // MARK: - Initialisation
    
    /// Initialise un nouvel utilisateur
    init(
        id: String? = nil,
        displayName: String,
        email: String,
        photoURL: String? = nil,
        createdAt: Date = Date(),
        squadIds: [String] = [],
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.squadIds = squadIds
        self.preferences = preferences
    }
}

// MARK: - UserPreferences

/// Préférences de l'utilisateur
struct UserPreferences: Codable {
    
    /// Activer les notifications push
    var pushNotificationsEnabled: Bool = true
    
    /// Activer les notifications vocales pendant la course
    var voiceNotificationsEnabled: Bool = true
    
    /// Partager automatiquement la position GPS pendant les courses
    var shareLocationInRace: Bool = true
    
    /// Autoriser les supporters à envoyer des messages audio
    var allowSupporterAudio: Bool = true
    
    /// Fréquence de mise à jour GPS (en secondes)
    /// 10 secondes en mode Race, 30 secondes en mode Training
    var gpsUpdateInterval: Int = 10
    
    /// Mode économie de batterie
    var batterySaverMode: Bool = false
}

// MARK: - UserStatistics

/// Statistiques globales de l'utilisateur
struct UserStatistics: Codable {
    
    /// Nombre total de courses complétées
    var totalRaces: Int = 0
    
    /// Nombre total d'entraînements complétés
    var totalTrainings: Int = 0
    
    /// Distance totale parcourue (en mètres)
    var totalDistanceMeters: Double = 0
    
    /// Temps total de course (en secondes)
    var totalTimeSeconds: Double = 0
    
    /// Nombre de squads rejoint
    var squadsJoined: Int = 0
    
    /// Nombre de messages audio envoyés
    var audioMessagesSent: Int = 0
    
    /// Nombre d'encouragements reçus
    var cheersReceived: Int = 0
}

// MARK: - Helper Extensions

extension UserModel {
    
    /// Indique si l'utilisateur fait partie d'au moins une squad
    var hasSquad: Bool {
        !squadIds.isEmpty
    }
    
    /// Indique si l'utilisateur a complété au moins une course
    var hasCompletedRace: Bool {
        (statistics?.totalRaces ?? 0) > 0
    }
    
    /// Distance totale en kilomètres
    var totalDistanceKm: Double {
        (statistics?.totalDistanceMeters ?? 0) / 1000
    }
}
