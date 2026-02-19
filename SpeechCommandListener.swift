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
    private var stopTimer: Task<Void, Never>?
    private var finalResultTimer: Task<Void, Never>?

    func requestPermissions() async -> Bool {
        let speechOK = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }

        let micOK: Bool
        if #available(iOS 17.0, *) {
            micOK = await AVAudioApplication.requestRecordPermission()
        } else {
            micOK = await withCheckedContinuation { cont in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
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
        // Reset so onChange fires even if the user says the same thing
        finalTranscript = ""

        guard let recognizer, recognizer.isAvailable else {
            lastError = "Speech Recognizer ist gerade nicht verfügbar."
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .duckOthers])
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
        print("[SpeechListener] Listening gestartet für \(seconds)s")

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                    print("[SpeechListener] Partial: \(self.transcript)")

                    // Wenn das Ergebnis final ist, sofort publishen
                    if result.isFinal {
                        print("[SpeechListener] Final result erhalten")
                        self.publishAndStop()
                    }
                }
            }

            if let error {
                Task { @MainActor in
                    // Cancelled-Fehler ignorieren (kommt beim normalen Stoppen)
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                        // "Retry" error – normal bei kurzen Aufnahmen
                        print("[SpeechListener] Recognition retry error – ignoriert")
                    } else if nsError.code != 1 { // code 1 = cancelled
                        print("[SpeechListener] Error: \(error.localizedDescription)")
                        self.lastError = error.localizedDescription
                    }
                    self.publishAndStop()
                }
            }
        }

        // Auto-Stop nach X Sekunden: Audio beenden, aber Task laufen lassen
        stopTimer = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard self.isListening else { return }
            print("[SpeechListener] Timer abgelaufen – beende Audio")

            // Audio-Input stoppen
            if self.audioEngine.isRunning {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
            }
            self.request?.endAudio()

            // Warte kurz auf finales Ergebnis, dann force-stop
            self.finalResultTimer = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s Gnadenfrist
                guard self.isListening else { return }
                print("[SpeechListener] Kein finales Ergebnis – force publish")
                self.publishAndStop()
            }
        }
    }

    /// Publishes the transcript and cleans up
    private func publishAndStop() {
        guard isListening else { return }

        stopTimer?.cancel()
        finalResultTimer?.cancel()

        task?.cancel()
        task = nil
        request = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        isListening = false

        let captured = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[SpeechListener] Publishing transcript: '\(captured)'")

        if !captured.isEmpty {
            finalTranscript = captured
        } else {
            // Kein Text erkannt – User informieren
            finalTranscript = "__EMPTY__"
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // nicht kritisch
        }
    }

    func stopListening() {
        publishAndStop()
    }
}
