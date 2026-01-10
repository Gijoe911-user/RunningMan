//
//  VoiceMessageService.swift
//  RunningMan
//
//  Service pour envoyer et recevoir des messages vocaux/texte
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import AVFoundation
import Combine

@MainActor
class VoiceMessageService: ObservableObject {
    
    static let shared = VoiceMessageService()
    
    // MARK: - Properties
    
    @Published var unreadMessages: [VoiceMessage] = []
    @Published var recentMessages: [VoiceMessage] = []
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let ttsService = TextToSpeechService.shared
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var messagesListener: ListenerRegistration?
    private var recordingTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        Logger.log("[VMS] 📬 VoiceMessageService initialisé", category: .service)
    }
    
    // MARK: - Send Messages
    
    /// Envoyer un message texte
    func sendTextMessage(
        text: String,
        recipientType: SharingScope,
        recipientId: String?,
        sessionId: String? = nil,
        squadId: String? = nil
    ) async throws {
        guard let userId = AuthService.shared.currentUserId else {
            throw NSError(domain: "VoiceMessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }
        
        // Récupérer le nom d'utilisateur depuis Firestore
        guard let userProfile = try await AuthService.shared.getUserProfile(userId: userId) else {
            throw NSError(domain: "VoiceMessageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Profil utilisateur introuvable"])
        }
        
        let userName = userProfile.displayName
        
        Logger.log("[VMS] 📤 Envoi message texte: '\(text.prefix(30))...' à \(recipientType.displayName)", category: .service)
        
        let message = VoiceMessage(
            senderId: userId,
            senderName: userName,
            recipientType: recipientType,
            recipientId: recipientId,
            messageType: .text,
            textContent: text,
            audioURL: nil,
            audioDuration: nil,
            timestamp: Date(),
            isRead: false,
            readAt: nil,
            sessionId: sessionId,
            squadId: squadId
        )
        
        try await saveMessage(message)
        Logger.logSuccess("[VMS] ✅ Message texte envoyé", category: .service)
    }
    
    /// Envoyer un message vocal
    func sendVoiceMessage(
        audioURL: URL,
        duration: TimeInterval,
        recipientType: SharingScope,
        recipientId: String?,
        sessionId: String? = nil,
        squadId: String? = nil
    ) async throws {
        guard let userId = AuthService.shared.currentUserId else {
            throw NSError(domain: "VoiceMessageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }
        
        // Récupérer le nom d'utilisateur depuis Firestore
        guard let userProfile = try await AuthService.shared.getUserProfile(userId: userId) else {
            throw NSError(domain: "VoiceMessageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Profil utilisateur introuvable"])
        }
        
        let userName = userProfile.displayName
        
        Logger.log("[VMS] 📤 Upload message vocal (\(duration)s)...", category: .service)
        
        // Upload l'audio vers Firebase Storage
        let storageRef = storage.reference().child("voiceMessages/\(UUID().uuidString).m4a")
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        
        _ = try await storageRef.putFileAsync(from: audioURL, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        let message = VoiceMessage(
            senderId: userId,
            senderName: userName,
            recipientType: recipientType,
            recipientId: recipientId,
            messageType: .voice,
            textContent: nil,
            audioURL: downloadURL.absoluteString,
            audioDuration: duration,
            timestamp: Date(),
            isRead: false,
            readAt: nil,
            sessionId: sessionId,
            squadId: squadId
        )
        
        try await saveMessage(message)
        Logger.logSuccess("[VMS] ✅ Message vocal envoyé", category: .service)
    }
    
    // MARK: - Receive Messages
    
    /// Démarrer l'écoute des messages pour l'utilisateur
    func startListeningForMessages(userId: String) {
        stopListeningForMessages()
        
        Logger.log("[VMS] 👂 Écoute des messages pour userId: \(userId)", category: .service)
        
        // Écouter tous les messages où l'utilisateur est destinataire
        messagesListener = db.collection("voiceMessages")
            .whereField("timestamp", isGreaterThan: Date().addingTimeInterval(-86400))  // Dernières 24h
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    Logger.logError(error, context: "startListeningForMessages", category: .service)
                    return
                }
                
                Task { @MainActor in
                    await self.processMessagesSnapshot(snapshot, userId: userId)
                }
            }
    }
    
    /// Arrêter l'écoute des messages
    func stopListeningForMessages() {
        messagesListener?.remove()
        messagesListener = nil
        Logger.log("[VMS] 🛑 Écoute des messages arrêtée", category: .service)
    }
    
    // MARK: - Recording
    
    /// Démarrer l'enregistrement audio
    func startRecording() async throws -> URL {
        Logger.log("[VMS] 🎙️ Démarrage enregistrement...", category: .service)
        
        // Configurer la session audio
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
        
        // URL temporaire
        let tempDir = FileManager.default.temporaryDirectory
        let audioURL = tempDir.appendingPathComponent("voice_\(UUID().uuidString).m4a")
        
        // Configuration de l'enregistrement
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
        audioRecorder?.record()
        
        isRecording = true
        recordingDuration = 0
        
        // Timer pour la durée
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.recordingDuration = self.audioRecorder?.currentTime ?? 0
            }
        }
        
        Logger.logSuccess("[VMS] ✅ Enregistrement démarré", category: .service)
        return audioURL
    }
    
    /// Arrêter l'enregistrement
    func stopRecording() -> (url: URL?, duration: TimeInterval) {
        Logger.log("[VMS] 🛑 Arrêt enregistrement", category: .service)
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        audioRecorder?.stop()
        let url = audioRecorder?.url
        let duration = audioRecorder?.currentTime ?? 0
        
        audioRecorder = nil
        isRecording = false
        recordingDuration = 0
        
        return (url, duration)
    }
    
    /// Annuler l'enregistrement
    func cancelRecording() {
        Logger.log("[VMS] ❌ Annulation enregistrement", category: .service)
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        if let url = audioRecorder?.url {
            audioRecorder?.stop()
            try? FileManager.default.removeItem(at: url)
        }
        
        audioRecorder = nil
        isRecording = false
        recordingDuration = 0
    }
    
    // MARK: - Playback
    
    /// Lire un message vocal
    func playVoiceMessage(_ message: VoiceMessage) async throws {
        guard let audioURLString = message.audioURL,
              let audioURL = URL(string: audioURLString) else {
            throw NSError(domain: "VoiceMessageService", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL audio invalide"])
        }
        
        Logger.log("[VMS] ▶️ Lecture message vocal...", category: .service)
        
        // Télécharger et lire
        let (localURL, _) = try await URLSession.shared.download(from: audioURL)
        
        audioPlayer = try AVAudioPlayer(contentsOf: localURL)
        audioPlayer?.play()
        
        // Marquer comme lu
        try await markMessageAsRead(messageId: message.encodedId, autoRead: false)
    }
    
    /// Arrêter la lecture
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Auto-Read During Tracking
    
    /// Lire automatiquement un message pendant le tracking
    func autoReadMessageDuringTracking(_ message: VoiceMessage, preferences: MessageReadingPreference) async {
        // Vérifier les préférences utilisateur
        guard preferences.autoReadDuringTracking else {
            Logger.log("[VMS] ⏭️ Lecture auto désactivée", category: .service)
            return
        }
        
        guard !preferences.doNotDisturbMode else {
            Logger.log("[VMS] 🔕 Mode bulle activé - message ignoré", category: .service)
            return
        }
        
        switch message.messageType {
        case .text:
            guard preferences.autoReadTextMessages else { return }
            if let text = message.textContent {
                let announcement = "Message de \(message.senderName): \(text)"
                ttsService.speakNotification(announcement)
                try? await markMessageAsRead(messageId: message.encodedId, autoRead: true)
            }
            
        case .voice:
            guard preferences.autoReadVoiceMessages else { return }
            try? await playVoiceMessage(message)
            try? await markMessageAsRead(messageId: message.encodedId, autoRead: true)
        }
    }
    
    // MARK: - Private Methods
    
    private func saveMessage(_ message: VoiceMessage) async throws {
        try db.collection("voiceMessages").addDocument(from: message)
    }
    
    private func markMessageAsRead(messageId: String, autoRead: Bool) async throws {
        guard let userId = AuthService.shared.currentUserId else { return }
        
        try await db.collection("voiceMessages")
            .document(messageId)
            .updateData([
                "isRead": true,
                "readAt": FieldValue.serverTimestamp()
            ])
        
        // Enregistrer le statut de lecture
        let status = MessageReadStatus(
            userId: userId,
            messageId: messageId,
            isRead: true,
            readAt: Date(),
            autoRead: autoRead
        )
        
        try db.collection("messageReadStatus").addDocument(from: status)
        
        Logger.log("[VMS] ✅ Message marqué comme lu (auto: \(autoRead))", category: .service)
    }
    
    private func processMessagesSnapshot(_ snapshot: QuerySnapshot?, userId: String) async {
        guard let documents = snapshot?.documents else { return }
        
        let messages = documents.compactMap { doc -> VoiceMessage? in
            try? doc.data(as: VoiceMessage.self)
        }
        
        // Filtrer les messages destinés à cet utilisateur
        let relevantMessages = messages.filter { message in
            isMessageForUser(message, userId: userId)
        }
        
        recentMessages = relevantMessages
        unreadMessages = relevantMessages.filter { !$0.isRead }
        
        Logger.log("[VMS] 📬 \(relevantMessages.count) messages reçus, \(unreadMessages.count) non lus", category: .service)
        
        // Auto-lecture si tracking actif
        if TrackingManager.shared.isTracking {
            await autoReadNewMessages(userId: userId)
        }
    }
    
    private func isMessageForUser(_ message: VoiceMessage, userId: String) -> Bool {
        // Ne pas afficher ses propres messages
        guard message.senderId != userId else { return false }
        
        switch message.recipientType {
        case .allMySquads:
            // Vérifier si l'utilisateur est dans la squad
            return message.squadId != nil
            
        case .allMySessions:
            // Vérifier si l'utilisateur est dans la session
            return message.sessionId != nil
            
        case .onlyOne:
            // Message direct
            return message.recipientId == userId
        }
    }
    
    private func autoReadNewMessages(userId: String) async {
        // Récupérer les préférences utilisateur
        // TODO: Implémenter la récupération depuis Firestore
        let preferences = MessageReadingPreference()
        
        for message in unreadMessages {
            await autoReadMessageDuringTracking(message, preferences: preferences)
        }
    }
}
