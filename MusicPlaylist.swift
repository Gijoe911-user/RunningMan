//
//  MusicPlaylist.swift
//  RunningMan
//
//  Playlist musicale adaptative (Phase 4 - Boilerplate)
//

import Foundation

/// Playlist musicale adaptative selon l'allure
///
/// **⚠️ Boilerplate pour Phase 4 :**
/// Cette structure prépare l'intégration future avec Spotify/Apple Music.
/// La logique d'activation automatique sera implémentée dans `MusicManager`.
///
/// **Cas d'usage :**
/// - Playlist "Warm-up" pour les 2 premiers km
/// - Playlist "Tempo" quand allure < 5:00/km
/// - Playlist "Ultime" pour les 2 derniers km d'un marathon
///
/// **Workflow futur :**
/// 1. Utilisateur lie ses comptes Spotify/Apple Music
/// 2. Crée des playlists avec conditions de déclenchement
/// 3. `MusicManager` surveille les métriques en temps réel
/// 4. Bascule automatiquement vers la playlist appropriée
///
/// - SeeAlso: `MusicManager`, `AudioTrigger`
struct MusicPlaylist: Codable, Identifiable, Hashable {
    
    // MARK: - Properties
    
    /// Identifiant unique
    var id: String = UUID().uuidString
    
    /// Nom de la playlist
    ///
    /// Ex: "Playlist Ultime", "Warm-up 10k", "Recovery Run"
    var name: String
    
    /// Description de la playlist
    var description: String?
    
    // MARK: Liens Externes
    
    /// URI Spotify (ex: spotify:playlist:37i9dQZF1DXcBWIGoYBM5M)
    ///
    /// **Note :** Nécessite Spotify SDK intégré.
    var spotifyUri: String?
    
    /// URL Spotify (pour ouvrir dans l'app Spotify)
    var spotifyUrl: String?
    
    /// ID Apple Music (pour ouvrir dans l'app Music)
    var appleMusicId: String?
    
    /// URL Apple Music
    var appleMusicUrl: String?
    
    // MARK: Conditions de Déclenchement
    
    /// Allure cible (en min/km)
    ///
    /// Si l'allure actuelle franchit ce seuil, la playlist s'active.
    /// Ex: `5.0` = Si allure < 5:00/km → Activer
    var triggerPace: Double?
    
    /// Distance de déclenchement (en mètres)
    ///
    /// Ex: `40000` = Activer aux 40 derniers km (42km - 40km = 2km finaux)
    var triggerDistance: Double?
    
    /// Fréquence cardiaque cible (en BPM)
    ///
    /// Ex: `160` = Si BPM > 160 → Activer
    var triggerHeartRate: Double?
    
    /// Temps écoulé (en secondes)
    ///
    /// Ex: `600` = Activer après 10 minutes de course
    var triggerTimeElapsed: Double?
    
    // MARK: Priorité & État
    
    /// Priorité de la playlist (plus élevé = prioritaire)
    ///
    /// Si plusieurs playlists correspondent aux conditions,
    /// celle avec la priorité la plus élevée est activée.
    var priority: Int = 0
    
    /// Indique si la playlist est active
    var isActive: Bool = false
    
    /// Indique si la playlist est par défaut (lecture au démarrage)
    var isDefault: Bool = false
    
    // MARK: Metadata
    
    /// ID de l'utilisateur propriétaire
    var createdBy: String
    
    /// Date de création
    var createdAt: Date = Date()
    
    /// Dernière modification
    var updatedAt: Date = Date()
    
    // MARK: - Computed Properties
    
    /// Texte formaté des conditions de déclenchement
    var formattedTriggers: String {
        var triggers: [String] = []
        
        if let pace = triggerPace {
            let minutes = Int(pace)
            let seconds = Int((pace - Double(minutes)) * 60)
            triggers.append("Allure < \(minutes):\(String(format: "%02d", seconds))/km")
        }
        
        if let distance = triggerDistance {
            triggers.append("Après \(String(format: "%.1f", distance / 1000)) km")
        }
        
        if let hr = triggerHeartRate {
            triggers.append("BPM > \(Int(hr))")
        }
        
        if let time = triggerTimeElapsed {
            let minutes = Int(time / 60)
            triggers.append("Après \(minutes) min")
        }
        
        return triggers.isEmpty ? "Aucune condition" : triggers.joined(separator: " • ")
    }
    
    /// Indique si au moins une condition est définie
    var hasConditions: Bool {
        triggerPace != nil || triggerDistance != nil || triggerHeartRate != nil || triggerTimeElapsed != nil
    }
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        spotifyUri: String? = nil,
        spotifyUrl: String? = nil,
        appleMusicId: String? = nil,
        appleMusicUrl: String? = nil,
        triggerPace: Double? = nil,
        triggerDistance: Double? = nil,
        triggerHeartRate: Double? = nil,
        triggerTimeElapsed: Double? = nil,
        priority: Int = 0,
        isActive: Bool = false,
        isDefault: Bool = false,
        createdBy: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.spotifyUri = spotifyUri
        self.spotifyUrl = spotifyUrl
        self.appleMusicId = appleMusicId
        self.appleMusicUrl = appleMusicUrl
        self.triggerPace = triggerPace
        self.triggerDistance = triggerDistance
        self.triggerHeartRate = triggerHeartRate
        self.triggerTimeElapsed = triggerTimeElapsed
        self.priority = priority
        self.isActive = isActive
        self.isDefault = isDefault
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Methods
    
    /// Vérifie si les conditions de déclenchement sont remplies
    ///
    /// **⚠️ Boilerplate :** Implémentation complète dans `MusicManager`
    ///
    /// - Parameters:
    ///   - currentPace: Allure actuelle (min/km)
    ///   - distanceRun: Distance parcourue (m)
    ///   - heartRate: BPM actuel
    ///   - timeElapsed: Temps écoulé (s)
    /// - Returns: `true` si au moins une condition est satisfaite
    func shouldActivate(
        currentPace: Double?,
        distanceRun: Double?,
        heartRate: Double?,
        timeElapsed: Double?
    ) -> Bool {
        var matches = false
        
        if let triggerPace = triggerPace, let currentPace = currentPace {
            matches = matches || currentPace < triggerPace
        }
        
        if let triggerDistance = triggerDistance, let distanceRun = distanceRun {
            matches = matches || distanceRun >= triggerDistance
        }
        
        if let triggerHeartRate = triggerHeartRate, let heartRate = heartRate {
            matches = matches || heartRate > triggerHeartRate
        }
        
        if let triggerTimeElapsed = triggerTimeElapsed, let timeElapsed = timeElapsed {
            matches = matches || timeElapsed >= triggerTimeElapsed
        }
        
        return matches
    }
    
    // MARK: - Hashable
    
    static func == (lhs: MusicPlaylist, rhs: MusicPlaylist) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
