//
//  JokeGenerator.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//


import Foundation

final class JokeGenerator {

    // MARK: - Witze nach Party-Level

    private let level0Jokes = [
        "Hier ist es so ruhig… selbst mein Bier schläft schon.",
        "Ist das hier ne Party oder ein Wartezimmer?",
        "So still hier… ich hör die Hefe arbeiten.",
        "Hallo? Ist da jemand? Oder red ich mit den Bierdeckeln?",
        "In diesem Tempo wird mein Bier schneller warm als die Stimmung.",
        "Letzte Kneipe war lauter. Und die war geschlossen.",
        "Ich hab schon lautere Bibliotheken erlebt.",
        "Wenn's noch stiller wird, hör ich das Licht flackern.",
    ]

    private let level1Jokes = [
        "Der Barkeeper arbeitet heute ehrenamtlich… er bekommt nur Trinkgeld.",
        "Was ist der Unterschied zwischen Bier und Wasser? Bier macht lustig, Wasser macht sauber. Beides braucht hier keiner.",
        "Ein Bier bestellt man nicht. Man rettet es aus der Flasche.",
        "Prost! Auf die, die nicht hier sind – die verpassen was!",
        "Mein Arzt sagt, ich soll aufhören zu trinken. Ich hab den Arzt gewechselt.",
        "Bier ist der Beweis, dass Gott uns liebt und will, dass wir glücklich sind.",
        "Ein Tag ohne Bier ist wie… keine Ahnung, hab ich noch nie probiert.",
        "Alkohol löst keine Probleme. Aber Wasser auch nicht.",
        "Bier vor vier – da bin ich mir sicher.",
        "Ich trinke nur an Tagen die mit G enden. Und mittwochs.",
    ]

    private let level2Jokes = [
        "Wenn du dein Bier suchst — es steht direkt vor deiner Zukunft.",
        "Ab jetzt zählt jedes Bier doppelt. Also trinkt langsamer! Oder schneller. Mir egal.",
        "Mein Bier sagt mir, ich bin toll. Mein Bier lügt nie.",
        "Warum gehen Witze immer in die Bar? Weil dort alle lachen.",
        "Wer sein Bier nicht liebt, ist selber schuld.",
        "Jetzt wird's gemütlich! Also… für die Bierdeckel.",
        "Alkohol ist keine Lösung. Chemisch gesehen schon.",
        "Ich bin nicht betrunken. Ich bin emotional flexibel.",
        "Der beste Moment einer Party? Der nächste Schluck.",
        "Lieber arm dran als Arm ab. Prost!",
    ]

    private let level3Jokes = [
        "Ab diesem Pegel werden Entscheidungen getroffen, die morgen jemand anders erklären muss.",
        "Morgen ist auch noch ein Tag – zum Bereuen!",
        "Die beste Entscheidung triffst du nach dem fünften Bier. Hat mir mein sechstes Bier gesagt.",
        "Wir sind an dem Punkt, wo alle Ideen gleichzeitig genial und furchtbar sind.",
        "Wer nüchtern fährt, fährt am besten. Wer betrunken fährt, fährt am kürzesten.",
        "In dieser Runde wird nicht mehr diskutiert. Nur noch bestellt!",
        "Das hier ist kein Kontrollverlust. Das ist kontrollierte Hingabe.",
        "Ab jetzt übernimmt das Bier die Planung!",
        "Ihr seid alle eingeladen zu meiner Entschuldigungs-Party morgen früh.",
        "Drei Bier sind auch ein Schnitzel!",
    ]

    private let level4Jokes = [
        "Die Musik ist nicht zu laut… ihr seid zu nüchtern.",
        "Jetzt noch was Schlaues sagen? Unmöglich. Aber Lustiges geht immer!",
        "Wenn dich jemand fragt was du heute gemacht hast, sag einfach: Erinnerungen gelöscht.",
        "Ich merk schon, heute wird eine Geschichte für die Enkel. Oder das Gericht.",
        "Ab jetzt gilt: Was in der Kneipe passiert, bleibt in der Kneipe.",
        "Wir sind auf dem Level wo Fremde zu besten Freunden werden!",
        "Dein Kater morgen ist nur die Erinnerung an den geilsten Abend deines Lebens.",
        "Tanzen ist wie Laufen, nur sinnvoller!",
        "Ab jetzt wird jede SMS ein Abenteuer.",
        "Wer jetzt noch Wasser bestellt, wird rausgeworfen!",
    ]

    private let level5Jokes = [
        "Wenn du jetzt noch gerade läufst, bist du nur auf dem Weg zur nächsten Runde.",
        "Party-Level Maximum! Ab hier geht's nur noch bergab – und das ist gut so!",
        "Mein Bierdeckel ist nasser als dein letzter Witz. Aber das hier ist Chaos auf Meisterebene!",
        "Wir haben offiziell den Punkt überschritten, ab dem Google Maps nicht mehr hilft.",
        "Taxi? Wohin? Ich weiß ja nicht mal mehr wo ich bin!",
        "Morgen gibt's nur noch Fragen und keine Antworten.",
        "Das ist nicht mehr feiern. Das ist Leistungssport!",
        "Wer noch stehen kann: Respekt. Wer nicht: noch mehr Respekt!",
        "Ab hier schreiben wir Geschichte. Oder zumindest den Polizeibericht.",
        "Die letzte Runde? Die war vor fünf Runden!",
    ]

    // MARK: - Trinksprüche

    private let toasts = [
        "Prost! Auf die Leber – und ihren unermüdlichen Einsatz!",
        "Ex oder Anex!",
        "Auf uns! Die Schönsten hier drin!",
        "Hoch die Tassen – runter damit!",
        "Prost! Möge dein Glas nie leer sein!",
        "Ein Hoch auf alle die noch stehen!",
        "Auf die Freundschaft! Solange wir uns noch erkennen!",
        "Bier her, Bier her, oder ich fall um!",
    ]

    // MARK: - Public API

    func joke(for level: Int) -> String {
        let jokes: [String]
        switch level {
        case 0: jokes = level0Jokes
        case 1: jokes = level1Jokes
        case 2: jokes = level2Jokes
        case 3: jokes = level3Jokes
        case 4: jokes = level4Jokes
        default: jokes = level5Jokes
        }
        return jokes.randomElement() ?? "Prost!"
    }

    func toast() -> String {
        toasts.randomElement() ?? "Prost!"
    }

    func randomJoke() -> String {
        let allJokes = level0Jokes + level1Jokes + level2Jokes + level3Jokes + level4Jokes + level5Jokes
        return allJokes.randomElement() ?? "Prost!"
    }
}
