//
//  ToniBrain.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//


import Foundation

final class ToniBrain {

    func respond(to command: String, partyLevel: Int) -> String {
        let text = command.lowercased()

        let wantsDirty = text.contains("dreck") || text.contains("versaut") || text.contains("unanständig")
        let wantsJoke  = text.contains("witz") || text.contains("spruch") || text.contains("erzähl")

        if wantsJoke {
            if wantsDirty || partyLevel >= 4 {
                return dirtyJoke()
            } else {
                return cleanJoke()
            }
        }

        if text.contains("hilfe") {
            return "Sag zum Beispiel: Toni, erzähl einen Witz."
        }

        return "Ich hab dich gehört. Sag: Toni, erzähl einen Witz."
    }

    private func cleanJoke() -> String {
        "Warum trinken Programmierer gern Kaffee? Weil sie sonst nicht kompilieren."
    }

    private func dirtyJoke() -> String {
        // Hinweis: Wir halten es “kneipig”, aber nicht hassend/gegen Gruppen.
        "Ich kenne einen dreckigen Witz… aber den erzähl ich nur, wenn du mir noch ein Bier versprichst."
    }
}
