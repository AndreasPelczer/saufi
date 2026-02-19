//
//  PartyEngine.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//

import Foundation
import Combine

final class PartyEngine: ObservableObject {

    // MARK: - Öffentlicher Party-Level (0–5)

    @Published var partyLevel: Int = 0

    /// Gleitender Wert für smoothe UI-Animationen (0.0–5.0)
    @Published var smoothLevel: Double = 0.0

    // MARK: - Interner Zustand

    /// Energie-Ringpuffer für Rolling Average
    private var energyBuffer: [Float] = []
    private let bufferSize = 60          // ~10 Sek bei 6 Updates/Sek

    /// Wann wurde das Level zuletzt geändert?
    private var lastLevelChange = Date.distantPast

    /// Mindest-Verweildauer auf einem Level (Sekunden)
    private let dwellTime: TimeInterval = 20

    /// Schwellwerte mit Hysterese (steigen ist leichter als fallen)
    private let riseThresholds: [Double] = [0.008, 0.025, 0.05, 0.08, 0.12]
    private let fallThresholds: [Double]  = [0.003, 0.012, 0.03, 0.05, 0.08]

    // MARK: - Update

    func update(with energy: Float) {
        // 1. Energie in Ringpuffer sammeln
        energyBuffer.append(energy)
        if energyBuffer.count > bufferSize {
            energyBuffer.removeFirst()
        }

        // Nicht genug Daten → noch nicht bewerten
        guard energyBuffer.count >= 10 else { return }

        // 2. Durchschnittsenergie berechnen
        let avgEnergy = Double(energyBuffer.reduce(0, +)) / Double(energyBuffer.count)

        // 3. Zeitbonus: nach 23 Uhr leichter Party-Level steigern
        let hour = Calendar.current.component(.hour, from: Date())
        let lateNightBonus: Double = (hour >= 23 || hour < 4) ? 0.01 : 0.0
        let adjusted = avgEnergy + lateNightBonus

        // 4. Ziel-Level berechnen basierend auf Hysterese-Schwellwerten
        var targetLevel = 0
        for i in 0..<5 {
            let threshold = (i < partyLevel) ? fallThresholds[i] : riseThresholds[i]
            if adjusted > threshold {
                targetLevel = i + 1
            }
        }

        // 5. Smooth-Level für Animationen (reagiert sofort)
        let smoothTarget = Double(targetLevel)
        let alpha = 0.08  // Glättungsfaktor
        smoothLevel = smoothLevel + alpha * (smoothTarget - smoothLevel)

        // 6. Integer-Level nur ändern wenn Dwell-Time erreicht
        let now = Date()
        guard now.timeIntervalSince(lastLevelChange) >= dwellTime else { return }

        if targetLevel != partyLevel {
            // Level ändert sich maximal um 1 pro Schritt
            if targetLevel > partyLevel {
                partyLevel += 1
            } else {
                partyLevel -= 1
            }
            partyLevel = max(0, min(partyLevel, 5))
            lastLevelChange = now
        }
    }

    // MARK: - Reset

    func reset() {
        energyBuffer.removeAll()
        partyLevel = 0
        smoothLevel = 0.0
        lastLevelChange = Date.distantPast
    }
}

