//
//  AudioMonitor.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//

import Foundation
import AVFoundation
import Combine

final class AudioMonitor: ObservableObject {

    private let engine = AVAudioEngine()

    @Published var level: Float = 0.0
    @Published var silenceDuration: TimeInterval = 0

    private var lastUpdate = Date()
    private var isRunning = false

    func start() {
        guard !isRunning else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AVAudioSession Fehler: \(error)")
        }

        startEngine()
    }

    func pause() {
        guard isRunning else { return }
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        isRunning = false
        level = 0
    }

    func resume() {
        start()
    }

    private func startEngine() {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.process(buffer: buffer)
        }

        do {
            try engine.start()
            isRunning = true
        } catch {
            print("AudioEngine Start fehlgeschlagen: \(error)")
        }
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = data[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))

        DispatchQueue.main.async {
            self.level = rms

            let now = Date()
            let delta = now.timeIntervalSince(self.lastUpdate)

            if rms < 0.015 {
                self.silenceDuration += delta
            } else {
                self.silenceDuration = 0
            }

            self.lastUpdate = now
        }
    }
}
