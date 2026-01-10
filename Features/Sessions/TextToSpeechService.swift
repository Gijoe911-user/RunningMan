//
//  TextToSpeechService.swift
//  RunningMan
//
//  Service de synthèse vocale (Text-to-Speech)
//

import AVFoundation
import Combine

@MainActor
class TextToSpeechService: NSObject, ObservableObject {
    
    static let shared = TextToSpeechService()
    
    // MARK: - Properties
    
    @Published var isSpeaking: Bool = false
    @Published var currentText: String?
    
    private let synthesizer = AVSpeechSynthesizer()
    private var speechQueue: [String] = []
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    // MARK: - Public Methods
    
    /// Lire un texte à voix haute
    func speak(_ text: String, language: String = "fr-FR", rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        Logger.log("[TTS] 🔊 Demande de lecture: '\(text.prefix(50))...'", category: .service)
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
        isSpeaking = true
        currentText = text
    }
    
    /// Arrêter la lecture en cours
    func stop() {
        Logger.log("[TTS] 🛑 Arrêt de la lecture", category: .service)
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentText = nil
        speechQueue.removeAll()
    }
    
    /// Mettre en pause
    func pause() {
        Logger.log("[TTS] ⏸️ Pause de la lecture", category: .service)
        synthesizer.pauseSpeaking(at: .immediate)
    }
    
    /// Reprendre la lecture
    func resume() {
        Logger.log("[TTS] ▶️ Reprise de la lecture", category: .service)
        synthesizer.continueSpeaking()
    }
    
    /// Ajouter à la file d'attente
    func enqueue(_ text: String) {
        speechQueue.append(text)
        if !isSpeaking {
            processQueue()
        }
    }
    
    // MARK: - Private Methods
    
    private func processQueue() {
        guard !speechQueue.isEmpty else { return }
        let nextText = speechQueue.removeFirst()
        speak(nextText)
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            Logger.log("[TTS] ✅ Session audio configurée", category: .service)
        } catch {
            Logger.logError(error, context: "configureAudioSession", category: .service)
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            Logger.log("[TTS] 🎤 Début de lecture", category: .service)
            isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            Logger.log("[TTS] ✅ Fin de lecture", category: .service)
            isSpeaking = false
            currentText = nil
            processQueue()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            Logger.log("[TTS] 🚫 Lecture annulée", category: .service)
            isSpeaking = false
            currentText = nil
        }
    }
}

// MARK: - Convenience Extensions

extension TextToSpeechService {
    
    /// Lire un texte avec une voix naturelle optimisée pour les notifications
    func speakNotification(_ text: String) {
        speak(text, rate: AVSpeechUtteranceDefaultSpeechRate * 1.1)
    }
    
    /// Lire un texte avec une voix plus lente pour l'onboarding
    func speakOnboarding(_ text: String) {
        speak(text, rate: AVSpeechUtteranceDefaultSpeechRate * 0.9)
    }
    
    /// Lire un message urgent avec emphase
    func speakUrgent(_ text: String) {
        speak(text, rate: AVSpeechUtteranceDefaultSpeechRate * 1.2)
    }
}
