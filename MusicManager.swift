//
//  MusicManager.swift
//  RunningMan
//
//  Gestionnaire de playlists adaptatives (Phase 4 Boilerplate)
//

import Foundation
import MediaPlayer
import Combine

/// Gestionnaire de playlists musicales adaptatives
///
/// **⚠️ Boilerplate pour Phase 4 :**
/// Ce service prépare l'intégration avec Spotify et Apple Music
/// pour des playlists qui changent automatiquement selon l'allure.
///
/// **Workflow futur :**
/// 1. Utilisateur lie son compte Spotify/Apple Music
/// 2. Configure des playlists avec conditions (allure, distance, BPM)
/// 3. `MusicManager` surveille les métriques en temps réel
/// 4. Bascule automatiquement vers la playlist appropriée
///
/// **Exemples d'usage :**
/// - Playlist "Warm-up" pour les 2 premiers km
/// - Playlist "Tempo" quand allure < 5:00/km
/// - Playlist "Ultime" pour les 2 derniers km
///
/// **Intégrations nécessaires :**
/// - Spotify SDK (iOS)
/// - MusicKit (Apple Music)
/// - AVFoundation pour le contrôle du volume
///
/// - SeeAlso: `MusicPlaylist`, `AudioTriggerService`
@MainActor
final class MusicManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = MusicManager()
    
    // MARK: - Published State
    
    /// Playlist actuellement active
    @Published private(set) var currentPlaylist: MusicPlaylist?
    
    /// Indique si une musique est en lecture
    @Published private(set) var isPlaying: Bool = false
    
    /// Volume actuel (0.0 - 1.0)
    @Published private(set) var volume: Float = 1.0
    
    /// Playlists configurées par l'utilisateur
    @Published private(set) var userPlaylists: [MusicPlaylist] = []
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        Logger.log("🎵 MusicManager initialisé (Boilerplate)", category: .audio)
    }
    
    // MARK: - Public API (Boilerplate)
    
    /// Vérifie si un changement de playlist est nécessaire
    ///
    /// **⚠️ À implémenter en Phase 4**
    ///
    /// Appelé régulièrement pendant une session active.
    ///
    /// - Parameters:
    ///   - pace: Allure actuelle (min/km)
    ///   - distance: Distance parcourue (m)
    ///   - heartRate: BPM actuel
    ///   - timeElapsed: Temps écoulé (s)
    func checkPlaylistTriggers(
        pace: Double?,
        distance: Double?,
        heartRate: Double?,
        timeElapsed: Double?
    ) {
        Logger.log("🎵 [BOILERPLATE] checkPlaylistTriggers", category: .audio)
        
        // TODO: Phase 4 - Implémentation
        // 1. Pour chaque playlist, vérifier shouldActivate()
        // 2. Si plusieurs playlists matchent, prendre celle avec la priorité la plus élevée
        // 3. Si différente de currentPlaylist → switchPlaylist()
    }
    
    /// Bascule vers une nouvelle playlist
    ///
    /// **⚠️ À implémenter en Phase 4**
    ///
    /// - Parameter playlist: Playlist cible
    func switchPlaylist(_ playlist: MusicPlaylist) async {
        Logger.log("🎵 [BOILERPLATE] switchPlaylist: \(playlist.name)", category: .audio)
        
        currentPlaylist = playlist
        
        // TODO: Phase 4 - Implémentation
        // Si Spotify:
        //   - Utiliser Spotify SDK pour changer de playlist
        // Si Apple Music:
        //   - Utiliser MusicKit pour lancer la playlist
    }
    
    /// Démarre la lecture
    ///
    /// **⚠️ À implémenter en Phase 4**
    func play() {
        Logger.log("🎵 [BOILERPLATE] play", category: .audio)
        isPlaying = true
        
        // TODO: Phase 4 - Implémentation
    }
    
    /// Met en pause la lecture
    ///
    /// **⚠️ À implémenter en Phase 4**
    func pause() {
        Logger.log("🎵 [BOILERPLATE] pause", category: .audio)
        isPlaying = false
        
        // TODO: Phase 4 - Implémentation
    }
    
    /// Ajuste le volume
    ///
    /// Utilisé par `AudioTriggerService` pour le ducking audio.
    ///
    /// - Parameter newVolume: Nouveau volume (0.0 - 1.0)
    func setVolume(_ newVolume: Float) {
        Logger.log("🎵 [BOILERPLATE] setVolume: \(newVolume)", category: .audio)
        
        volume = min(max(newVolume, 0.0), 1.0)
        
        // TODO: Phase 4 - Implémentation
        // Appliquer le volume à AVAudioEngine ou aux SDKs
    }
    
    /// Abaisse temporairement le volume (ducking)
    ///
    /// **⚠️ À implémenter en Phase 4**
    ///
    /// Appelé par `AudioTriggerService` pendant la diffusion de messages vocaux.
    ///
    /// - Parameter duration: Durée du ducking (en secondes)
    func duckVolume(for duration: Double) async {
        Logger.log("🎵 [BOILERPLATE] duckVolume: \(duration)s", category: .audio)
        
        let originalVolume = volume
        
        // Réduire à 20%
        setVolume(0.2)
        
        // Attendre la durée
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        
        // Remonter au volume original
        setVolume(originalVolume)
    }
    
    /// Charge les playlists configurées par l'utilisateur
    ///
    /// **⚠️ À implémenter en Phase 4**
    ///
    /// - Parameter userId: ID de l'utilisateur
    func loadUserPlaylists(for userId: String) async throws {
        Logger.log("🎵 [BOILERPLATE] loadUserPlaylists: \(userId)", category: .audio)
        
        // TODO: Phase 4 - Fetch depuis Firestore
        userPlaylists = []
    }
    
    /// Sauvegarde une nouvelle playlist
    ///
    /// **⚠️ À implémenter en Phase 4**
    ///
    /// - Parameter playlist: Playlist à sauvegarder
    func savePlaylist(_ playlist: MusicPlaylist) async throws {
        Logger.log("🎵 [BOILERPLATE] savePlaylist: \(playlist.name)", category: .audio)
        
        // TODO: Phase 4 - Sauvegarder dans Firestore
        userPlaylists.append(playlist)
    }
    
    // MARK: - Spotify Integration (Future)
    
    /// Authentifie l'utilisateur avec Spotify
    ///
    /// **⚠️ À implémenter en Phase 4**
    func authenticateSpotify() async throws {
        Logger.log("🎵 [BOILERPLATE] authenticateSpotify", category: .audio)
        
        // TODO: Phase 4
        // 1. Utiliser SpotifyiOS SDK
        // 2. OAuth 2.0 flow
        // 3. Sauvegarder le token d'accès
        
        throw MusicManagerError.notImplemented
    }
    
    // MARK: - Apple Music Integration (Future)
    
    /// Authentifie l'utilisateur avec Apple Music
    ///
    /// **⚠️ À implémenter en Phase 4**
    func authenticateAppleMusic() async throws {
        Logger.log("🎵 [BOILERPLATE] authenticateAppleMusic", category: .audio)
        
        // TODO: Phase 4
        // 1. Utiliser MusicKit
        // 2. Demander l'autorisation
        // 3. Vérifier l'abonnement Apple Music
        
        throw MusicManagerError.notImplemented
    }
}

// MARK: - Errors

enum MusicManagerError: LocalizedError {
    case notImplemented
    case spotifyNotConnected
    case appleMusicNotConnected
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Fonctionnalité non implémentée (Phase 4)"
        case .spotifyNotConnected:
            return "Spotify non connecté"
        case .appleMusicNotConnected:
            return "Apple Music non connecté"
        case .playbackFailed:
            return "Échec de la lecture"
        }
    }
}
