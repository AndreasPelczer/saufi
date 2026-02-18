//
//  GeminiError.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//

import Foundation
import GoogleGenerativeAI  // von generative-ai-swift Package

enum GeminiError: Error {
    case emptyResponse
    case generic(String)
}

final class GeminiService {

    private let model: GenerativeModel

    init(apiKey: String) {

        // Safety NICHT komplett aus – sonst Chaos
        let safety: [SafetySetting] = [
            SafetySetting(harmCategory: .harassment, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .hateSpeech, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockOnlyHigh),
            SafetySetting(harmCategory: .dangerousContent, threshold: .blockMediumAndAbove)
        ]

        // Toni Persönlichkeit
        let system = """
        Du bist Toni, eine humorvolle Kneipenstimme.
        Du erzählst kurze spontane Kneipenwitze.

        Regeln:
        - Maximal 2 Sätze
        - Humor darf frech sein, aber nicht pornografisch
        - Keine Beleidigungen gegen Gruppen
        - Kein politischer Inhalt
        - Kling wie ein echter Mensch, nicht wie eine KI
        """

        model = GenerativeModel(
            name: "gemini-1.5-flash",
            apiKey: apiKey,
            safetySettings: safety,
            systemInstruction: system
        )
    }

    func generateResponse(command: String, partyLevel: Int) async throws -> String {

        let humorLevel: String
        switch partyLevel {
        case 0...1: humorLevel = "harmlos"
        case 2...3: humorLevel = "frech"
        default: humorLevel = "derb aber nicht explizit"
        }

        let prompt = """
        Gast sagt: "\(command)"

        Stimmung: \(humorLevel)
        Kneipenpegel: \(partyLevel)/5

        Antworte passend kurz und lustig.
        """

        let response = try await model.generateContent(prompt)

        guard let text = response.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw GeminiError.emptyResponse
        }

        return cleanup(text)
    }

    private func cleanup(_ text: String) -> String {
        var t = text
        if t.contains("\n") { t = t.components(separatedBy: "\n")[0] }
        return t
    }
}
