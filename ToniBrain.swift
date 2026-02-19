//
//  ToniBrain.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//


import Foundation

final class ToniBrain {

    private let jokeGenerator = JokeGenerator()

    func respond(to command: String, partyLevel: Int) -> String {
        let text = command.lowercased()

        // Begrüßungen
        if matchesAny(text, keywords: ["hallo", "moin", "servus", "hey toni", "hi toni", "grüß", "guten abend"]) {
            return greeting(for: partyLevel)
        }

        // Trinkspruch
        if matchesAny(text, keywords: ["prost", "trinkspruch", "anstoßen", "cheers", "auf ex"]) {
            return jokeGenerator.toast()
        }

        // Witz-Anfrage
        let wantsJoke = matchesAny(text, keywords: ["witz", "spruch", "erzähl", "lustig", "lach", "humor", "joke", "sag was", "unterhalt"])
        let wantsDirty = matchesAny(text, keywords: ["dreck", "versaut", "unanständig", "derb", "schmutz", "frivol"])

        if wantsJoke || wantsDirty {
            return jokeGenerator.joke(for: wantsDirty ? max(partyLevel, 4) : partyLevel)
        }

        // Wie geht's Toni?
        if matchesAny(text, keywords: ["wie geht", "alles klar", "was geht", "wie läuft", "wie stehts"]) {
            return toniStatus(for: partyLevel)
        }

        // Party-Level Frage
        if matchesAny(text, keywords: ["party", "pegel", "stimmung", "level", "laut", "wie wild"]) {
            return partyComment(for: partyLevel)
        }

        // Hilfe
        if matchesAny(text, keywords: ["hilfe", "help", "was kannst", "befehle", "kommando"]) {
            return "Sag zum Beispiel: Toni, erzähl einen Witz! Oder: Prost! Oder frag mich wie die Stimmung ist."
        }

        // Danke
        if matchesAny(text, keywords: ["danke", "dankeschön", "thanks"]) {
            return ["Gerne! Dafür bin ich da.", "Bitte, bitte! Noch ein Bier?", "Kein Ding! Prost!"].randomElement()!
        }

        // Tschüss
        if matchesAny(text, keywords: ["tschüss", "ciao", "bye", "gute nacht", "ich geh"]) {
            return farewell(for: partyLevel)
        }

        // Fallback – Level-passenden Witz liefern statt langweilige Antwort
        return jokeGenerator.joke(for: partyLevel)
    }

    // MARK: - Kontext-Antworten

    private func greeting(for level: Int) -> String {
        switch level {
        case 0...1:
            return ["Moin! Na, bereit für heute Abend?", "Hey! Schön dass du da bist. Bier?", "Servus! Willkommen in meiner Kneipe!"].randomElement()!
        case 2...3:
            return ["Na endlich! Wird auch Zeit! Her mit dem Bier!", "Hey hey! Die Party kann starten – du bist ja da!"].randomElement()!
        default:
            return ["YOOO! Wo warst du? Das hier ist schon WILD!", "Da biste ja! Schnapp dir was zu trinken, schnell!"].randomElement()!
        }
    }

    private func toniStatus(for level: Int) -> String {
        switch level {
        case 0:
            return "Mir geht's gut, aber hier ist es stiller als in ner Kirche am Montag."
        case 1...2:
            return "Läuft! Die Stimmung kommt langsam. Noch ein, zwei Runden und dann geht's ab!"
        case 3:
            return "Mir geht's bestens! Bei der Stimmung macht Barkeeper sein richtig Spaß!"
        default:
            return "MEGA! Das hier ist der beste Abend seit langem! PROST!"
        }
    }

    private func partyComment(for level: Int) -> String {
        switch level {
        case 0:
            return "Party-Pegel: Null. Hier schlafen sogar die Bierdeckel."
        case 1:
            return "Gemütlich! Aber da geht noch was. Bestellt ne Runde!"
        case 2:
            return "Wird langsam! Die Stimmung zieht an. Weiter so!"
        case 3:
            return "Oh ja! Jetzt wird gefeiert! Level 3 von 5 – das rockt!"
        case 4:
            return "WILD! Party-Level 4! Hier geht die Post ab!"
        default:
            return "MAXIMUM! Pegel 5 von 5! Wenn die Bullen kommen, kennen wir uns nicht!"
        }
    }

    private func farewell(for level: Int) -> String {
        switch level {
        case 0...1:
            return "Ciao! Komm bald wieder – und bring Freunde mit!"
        case 2...3:
            return "Schon? Na gut, komm gut heim! Und trink Wasser!"
        default:
            return "Du willst JETZT gehen?! Mitten im besten Chaos? Na gut… Taxi, nicht fahren!"
        }
    }

    // MARK: - Helpers

    private func matchesAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
