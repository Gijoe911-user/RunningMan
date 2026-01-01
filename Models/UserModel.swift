//
//  UserModel.swift
//  RunningMan
//
//  Modèle utilisateur avec système de gamification intégré
//

import Foundation
import FirebaseFirestore

/// Modèle utilisateur avec gamification intégrée
///
/// Gère les informations de profil, les objectifs hebdomadaires,
/// et le système de progression/consistance.
///
/// **Changements majeurs (v2.0) :**
/// - Suppression du rôle global (désormais géré par squad)
/// - Ajout du système de consistance (`consistencyRate`)
/// - Support des objectifs hebdomadaires (`weeklyGoals`)
/// - Profil enrichi (avatar, bio)
///
/// - Important: Les rôles sont désormais définis au niveau de chaque squad.
///   Voir `SquadModel.members` pour la gestion des permissions.
///
/// - SeeAlso: `WeeklyGoal`, `ProgressionService`
struct UserModel: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Identifiant unique (Firebase Auth UID)
    @DocumentID var id: String?
    
    // MARK: Profil de Base
    
    /// Nom affiché dans l'app
    var displayName: String
    
    /// Email de l'utilisateur
    var email: String
    
    /// URL de l'avatar (Firebase Storage)
    var avatarUrl: String?
    
    /// Biographie / Description du profil
    var bio: String?
    
    // MARK: Gamification
    
    /// Indice de consistance (0.0 - 1.0)
    ///
    /// Calculé par `ProgressionService` selon la formule :
    /// ```
    /// consistencyRate = objectifsRéalisés / objectifsTentés
    /// ```
    ///
    /// **Interprétation :**
    /// - `> 0.75` : Vert (Excellence)
    /// - `0.50 - 0.75` : Jaune (Alerte)
    /// - `< 0.50` : Rouge (Réajustement suggéré)
    var consistencyRate: Double?  // ✅ Optionnel pour compatibilité
    
    /// Objectifs hebdomadaires en cours et historique
    ///
    /// Limité aux 12 dernières semaines pour optimiser les performances.
    var weeklyGoals: [WeeklyGoal]?  // ✅ Optionnel pour compatibilité
    
    /// Distance totale parcourue (lifetime, en mètres)
    var totalDistance: Double?  // ✅ Optionnel pour compatibilité
    
    /// Nombre total de sessions complétées
    var totalSessions: Int?  // ✅ Optionnel pour compatibilité
    
    // MARK: Metadata
    
    /// Date de création du compte
    var createdAt: Date?  // ✅ Optionnel pour compatibilité
    
    /// Dernière connexion
    var lastSeen: Date?  // ✅ Optionnel pour compatibilité
    
    /// IDs des squads auxquelles l'utilisateur appartient
    var squads: [String]?  // ✅ Optionnel pour compatibilité
    
    /// Préférences utilisateur (ancienne structure, peut être absente)
    var preferences: UserPreferences?  // ✅ Optionnel
    
    // MARK: - Computed Properties
    
    /// Taux de consistance en pourcentage (0-100)
    var consistencyPercentage: Int {
        Int((consistencyRate ?? 0.0) * 100)
    }
    
    /// Couleur de la barre de progression selon le taux
    var consistencyColor: ProgressionColor {
        ProgressionService.shared.getProgressionColor(for: consistencyRate ?? 0.0)
    }
    
    /// Objectifs de la semaine en cours
    var currentWeekGoals: [WeeklyGoal] {
        let startOfWeek = Calendar.current.startOfWeek(for: Date())
        return (weeklyGoals ?? []).filter { Calendar.current.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .weekOfYear) }
    }
    
    /// Initiales pour l'avatar fallback
    var initials: String {
        let components = displayName.components(separatedBy: " ")
        let first = components.first?.prefix(1) ?? ""
        let last = components.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
    
    // MARK: - Initialization
    
    init(
        id: String? = nil,
        displayName: String,
        email: String,
        avatarUrl: String? = nil,
        bio: String? = nil,
        consistencyRate: Double? = nil,
        weeklyGoals: [WeeklyGoal]? = nil,
        totalDistance: Double? = nil,
        totalSessions: Int? = nil,
        createdAt: Date? = nil,
        lastSeen: Date? = nil,
        squads: [String]? = nil,
        preferences: UserPreferences? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.consistencyRate = consistencyRate
        self.weeklyGoals = weeklyGoals
        self.totalDistance = totalDistance
        self.totalSessions = totalSessions
        self.createdAt = createdAt
        self.lastSeen = lastSeen
        self.squads = squads
        self.preferences = preferences
    }
    
    // MARK: - Hashable
    
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Supporting Types

// Note: ProgressionColor est défini dans ProgressionService.swift
// pour respecter le principe DRY (Don't Repeat Yourself)

// MARK: - Calendar Extension

extension Calendar {
    /// Retourne le lundi de la semaine contenant la date donnée
    ///
    /// - Parameter date: Date de référence
    /// - Returns: Lundi à 00:00:00
    func startOfWeek(for date: Date) -> Date {
        var components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // Lundi
        return self.date(from: components) ?? date
    }
}
// MARK: - Bridge de compatibilité (v1 -> v2)
extension UserModel {
    
    /// Anciennement photoURL, maintenant avatarUrl
    var photoURL: String? {
        get { avatarUrl }
        set { avatarUrl = newValue }
    }
    
    /// Anciennement squadIds, maintenant squads
    var squadIds: [String] {
        get { squads ?? [] }
        set { squads = newValue }
    }
    
    /// Simule l'ancien objet statistics pour ne pas casser les vues de profil actuelles
    var statistics: UserStatisticsBridge? {
        UserStatisticsBridge(parent: self)
    }
    
    /// Indique si l'utilisateur fait partie d'au moins une squad
    var hasSquad: Bool {
        !(squads ?? []).isEmpty
    }
    
    /// Indique si l'utilisateur a complété au moins une course
    var hasCompletedRace: Bool {
        (totalSessions ?? 0) > 0
    }
    
    /// Distance totale en kilomètres
    var totalDistanceKm: Double {
        (totalDistance ?? 0.0) / 1000
    }
}

/// Objet temporaire pour simuler l'ancienne structure de statistiques
struct UserStatisticsBridge {
    let parent: UserModel
    
    var totalDistanceMeters: Double { parent.totalDistance ?? 0.0 }
    var totalRaces: Int { parent.totalSessions ?? 0 } // Approximation
    var totalTrainings: Int { 0 } // À mapper si besoin
    var squadsJoined: Int { (parent.squads ?? []).count }
    var totalTimeSeconds: Double { 0 } // À mapper si besoin dans le futur
    var audioMessagesSent: Int { 0 } // À mapper si besoin dans le futur
    var cheersReceived: Int { 0 } // À mapper si besoin dans le futur
}

// MARK: - UserPreferences (Compatibilité v1)

/// Préférences de l'utilisateur
/// 
/// **Note :** Cette structure est conservée pour la compatibilité avec le code existant.
/// À terme, ces préférences devraient être migrées dans le modèle principal ou un système de Settings.
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
