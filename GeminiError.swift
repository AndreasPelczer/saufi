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

    /// Conversation memory – keeps recent exchanges for context
    private var chatHistory: [ModelContent] = []
    private let maxHistoryPairs = 5  // Keep last 5 exchanges

    init(apiKey: String) {

        // Safety NICHT komplett aus – sonst Chaos
        let safety: [SafetySetting] = [
            SafetySetting(harmCategory: .harassment, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .hateSpeech, threshold: .blockMediumAndAbove),
            SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockOnlyHigh),
            SafetySetting(harmCategory: .dangerousContent, threshold: .blockMediumAndAbove)
        ]

        // Toni Persönlichkeit – erweitert
        let system = """
        Du bist Toni, der witzigste Barkeeper der Stadt.
        Du stehst hinter dem Tresen einer gemütlichen deutschen Kneipe.

        Deine Persönlichkeit:
        - Du bist schlagfertig und hast immer einen Spruch parat
        - Du sprichst wie ein echter Kumpel, nicht wie eine KI
        - Du liebst Bier, gute Laune und Kneipenweisheiten
        - Du merkst dir was die Gäste sagen und gehst darauf ein

        Regeln:
        - Maximal 2 Sätze, kurz und knackig
        - Humor darf frech und kneipig sein, aber nicht pornografisch
        - Keine Beleidigungen gegen Gruppen, Religionen oder Herkunft
        - Kein politischer Inhalt
        - Antworte auf Deutsch
        - Wenn jemand Prost sagt, antworte mit einem Trinkspruch
        - Passe deinen Humor an den Party-Pegel an
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
        case 0...1: humorLevel = "harmlos und gemütlich"
        case 2...3: humorLevel = "frech und witzig"
        default: humorLevel = "derb und wild, aber nicht explizit"
        }

        let hour = Calendar.current.component(.hour, from: Date())
        let timeContext: String
        switch hour {
        case 0..<6: timeContext = "Es ist mitten in der Nacht."
        case 6..<12: timeContext = "Es ist Vormittag."
        case 12..<18: timeContext = "Es ist Nachmittag."
        case 18..<22: timeContext = "Es ist Abend."
        default: timeContext = "Es ist spät abends."
        }

        let prompt = """
        Gast sagt: "\(command)"

        Stimmung: \(humorLevel)
        Kneipenpegel: \(partyLevel)/5
        \(timeContext)

        Antworte passend kurz und lustig.
        """

        // Build content with history for context
        var contents = chatHistory
        contents.append(ModelContent(role: "user", parts: prompt))

        let response = try await model.generateContent(contents)

        guard let text = response.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw GeminiError.emptyResponse
        }

        let cleaned = cleanup(text)

        // Update conversation memory
        chatHistory.append(ModelContent(role: "user", parts: command))
        chatHistory.append(ModelContent(role: "model", parts: cleaned))

        // Trim history to last N pairs
        while chatHistory.count > maxHistoryPairs * 2 {
            chatHistory.removeFirst(2)
        }

        return cleaned
    }

    func clearHistory() {
        chatHistory.removeAll()
    }

    private func cleanup(_ text: String) -> String {
        var t = text
        // Take first meaningful line only (avoid multi-paragraph AI responses)
        if t.contains("\n") {
            let lines = t.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            t = lines.first ?? t
        }
        // Remove markdown artifacts
        t = t.replacingOccurrences(of: "**", with: "")
        t = t.replacingOccurrences(of: "*", with: "")
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
