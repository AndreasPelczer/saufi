//
//  Speaker.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//

import Foundation
import AVFoundation
import Combine

/// Toni's Stimme – nutzt OpenAI TTS wenn verfügbar, sonst Apple Enhanced Voice.
@MainActor
final class Speaker: NSObject, ObservableObject {

    @Published var isSpeaking: Bool = false

    // MARK: - TTS Backend Auswahl

    enum Voice: String, CaseIterable {
        case openAI = "OpenAI TTS"
        case appleEnhanced = "Apple Enhanced"
        case appleFallback = "Apple Standard"
    }

    /// Welche Stimme aktiv genutzt wird
    @Published private(set) var activeVoice: Voice = .appleFallback

    // MARK: - OpenAI TTS Config

    /// OpenAI Stimmen: alloy, echo, fable, onyx, nova, shimmer
    /// "onyx" = tief, warm, männlich – perfekt für Toni
    private let openAIVoice: String = "onyx"
    private let openAIModel: String = "tts-1"
    private var openAIKey: String?

    // MARK: - Audio Players

    private var audioPlayer: AVAudioPlayer?
    private let synth = AVSpeechSynthesizer()

    // MARK: - Queue

    private var speechQueue: [String] = []
    private var isProcessingQueue = false

    // MARK: - Init

    override init() {
        super.init()
        synth.delegate = self
    }

    /// API-Key für OpenAI TTS setzen (aktiviert die gute Stimme)
    func configure(openAIKey: String?) {
        self.openAIKey = openAIKey
    }

    // MARK: - Public API

    /// Spricht den Text – wählt automatisch die beste verfügbare Stimme
    func speak(_ text: String) {
        speechQueue.append(text)
        processQueue()
    }

    /// Stoppt sofort alles
    func stop() {
        speechQueue.removeAll()
        audioPlayer?.stop()
        audioPlayer = nil
        synth.stopSpeaking(at: .immediate)
        isSpeaking = false
        isProcessingQueue = false
    }

    // MARK: - Queue Processing

    private func processQueue() {
        guard !isProcessingQueue, let text = speechQueue.first else { return }
        isProcessingQueue = true
        isSpeaking = true
        speechQueue.removeFirst()

        Task {
            // 1. Versuch: OpenAI TTS (beste Qualität)
            if let key = openAIKey, !key.isEmpty {
                if await speakWithOpenAI(text: text, apiKey: key) {
                    activeVoice = .openAI
                    return
                }
            }

            // 2. Versuch: Apple Enhanced Voice
            if speakWithAppleEnhanced(text: text) {
                activeVoice = .appleEnhanced
                return
            }

            // 3. Fallback: Standard Apple TTS
            speakWithAppleFallback(text: text)
            activeVoice = .appleFallback
        }
    }

    private func onSpeechFinished() {
        isProcessingQueue = false
        if speechQueue.isEmpty {
            isSpeaking = false
        } else {
            processQueue()
        }
    }

    // MARK: - OpenAI TTS

    private func speakWithOpenAI(text: String, apiKey: String) async -> Bool {
        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": openAIModel,
            "input": text,
            "voice": openAIVoice,
            "response_format": "mp3",
            "speed": 1.0
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return false }
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  !data.isEmpty else {
                return false
            }

            // Audio abspielen
            try configureAudioSession()
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            return true

        } catch {
            print("OpenAI TTS Fehler: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Apple Enhanced Voice

    private func speakWithAppleEnhanced(text: String) -> Bool {
        // Enhanced Voices (iOS 16+) – müssen auf dem Gerät runtergeladen sein
        // Einstellungen → Bedienungshilfen → Gesprochene Inhalte → Stimmen → Deutsch
        let enhancedIDs = [
            "com.apple.voice.enhanced.de-DE.Anna",
            "com.apple.voice.premium.de-DE.Anna",
            "com.apple.voice.enhanced.de-DE.Martin",
            "com.apple.voice.premium.de-DE.Martin"
        ]

        for voiceID in enhancedIDs {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
                let utterance = makeUtterance(text: text)
                utterance.voice = voice
                synth.speak(utterance)
                return true
            }
        }

        return false
    }

    // MARK: - Apple Fallback

    private func speakWithAppleFallback(text: String) {
        let utterance = makeUtterance(text: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        synth.speak(utterance)
    }

    // MARK: - Helpers

    private func makeUtterance(text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        // Toni-Stimme: etwas langsamer, tiefere Stimme
        utterance.rate = 0.48
        utterance.pitchMultiplier = 0.85
        utterance.volume = 1.0
        // Kleine Pause vor dem Sprechen für natürlicheren Effekt
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2
        return utterance
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension Speaker: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.onSpeechFinished()
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension Speaker: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.audioPlayer = nil
            self.onSpeechFinished()
        }
    }
}
