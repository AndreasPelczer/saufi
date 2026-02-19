//
//  SpeechCommandListener.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//


import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
final class SpeechCommandListener: ObservableObject {

    @Published var isListening: Bool = false
    @Published var transcript: String = ""
    @Published var lastError: String?
    /// Fires once with the final transcript when listening stops
    @Published var finalTranscript: String = ""

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))

    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions() async -> Bool {
        // Speech permission
        let speechOK = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }

        // Microphone permission
        let micOK = await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }

        if !speechOK { lastError = "Speech Recognition nicht erlaubt." }
        if !micOK { lastError = "Mikrofon nicht erlaubt." }

        return speechOK && micOK
    }

    func startListening(seconds: TimeInterval = 5.0) {
        guard !isListening else { return }
        lastError = nil
        transcript = ""

        guard let recognizer, recognizer.isAvailable else {
            lastError = "Speech Recognizer ist gerade nicht verfügbar."
            return
        }

        // Alte Session beenden
        stopListening()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            lastError = "AVAudioSession Fehler: \(error.localizedDescription)"
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else {
            lastError = "RecognitionRequest konnte nicht erstellt werden."
            return
        }

        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            lastError = "AudioEngine Start fehlgeschlagen: \(error.localizedDescription)"
            return
        }

        isListening = true

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if let error {
                Task { @MainActor in
                    self.lastError = "Speech Fehler: \(error.localizedDescription)"
                    self.stopListening()
                }
            }
        }

        // Auto-Stop nach X Sekunden
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            self.stopListening()
        }
    }

    func stopListening() {
        guard isListening else { return }

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        request?.endAudio()
        request = nil

        task?.cancel()
        task = nil

        isListening = false

        // Publish the final transcript so observers can react
        let captured = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !captured.isEmpty {
            finalTranscript = captured
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // nicht kritisch
        }
    }
}
