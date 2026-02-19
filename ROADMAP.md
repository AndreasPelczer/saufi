# Saufi - Roadmap & Verbesserungsplan

> "Toni" soll vom schlechten Prototyp zur besten Party-App im App Store werden.

---

## Ist-Zustand: Was ist schlecht?

### 1. Die Stimme (Speaker.swift)
- `AVSpeechSynthesizer` klingt **robotisch und leblos**
- Nur eine Stimme, keine Variation
- Kein Audio-Feedback (Soundeffekte, Jingles)
- Toni klingt wie Siri's hässlicher Bruder, nicht wie ein Kneipenwirt

### 2. Das Gehirn (ToniBrain.swift)
- **Nur 2 hardcodierte Witze** (1x clean, 1x dirty)
- Keyword-Erkennung ist primitiv (nur exakte Wörter)
- Kein Kontext/Gedächtnis - Toni vergisst alles sofort
- Kein Fallback wenn Gemini nicht erreichbar ist
- ToniBrain und GeminiService sind nicht verbunden im Code

### 3. Die Witze (JokeGenerator.swift)
- Nur **6 Witze** total - nach 5 Minuten langweilig
- Keine Kategorien (Trinksprüche, Challenges, Fragen)
- Kein Mechanismus gegen Wiederholungen

### 4. Das UI (ContentView.swift)
- **Fehlt komplett** - keine visuelle Oberfläche im Repo
- Kein visuelles Feedback zur Party-Stimmung
- Keine Anzeige was Toni gerade macht

### 5. Die Party-Erkennung (PartyEngine.swift)
- Schwankt wild (jedes Update +1 oder -1)
- Kein Smoothing/Averaging
- Reagiert zu schnell auf kurze Stille

### 6. Architektur-Probleme
- Info.plist leer (keine Berechtigungs-Beschreibungen)
- Kein API-Key-Management
- AudioMonitor und SpeechCommandListener konkurrieren um das Mikrofon
- Kein Error-Handling für den User sichtbar

---

## Stufe 1: Funktionsfähig & Benutzbar

> Ziel: App funktioniert zuverlässig, sieht gut aus, macht Spaß für 15 Minuten

### 1.1 ContentView bauen
```
- Hauptbildschirm mit Toni-Avatar/Animation
- Party-Level-Anzeige (Neon-Bar oder Thermometer)
- Großer "Sprich mit Toni"-Button
- Textanzeige was Toni sagt
- Stimmungs-Indikator (Farben: blau→grün→gelb→orange→rot)
```

### 1.2 Stimme verbessern
```
Option A (schnell): Apple Enhanced Voices nutzen
  - iOS 16+ hat "Premium" Voices die man downloaden kann
  - Voice ID: "com.apple.voice.enhanced.de-DE.Anna" oder ähnlich
  - Deutlich natürlicher als Standard

Option B (besser): OpenAI TTS API
  - Endpoint: POST https://api.openai.com/v1/audio/speech
  - Stimme "onyx" oder "echo" klingt männlich/warm
  - ~15ms Latenz, $0.015/1000 Zeichen
  - Nachteil: braucht Internet

Option C (best): ElevenLabs mit Custom Voice
  - Eigene "Toni"-Stimme trainieren
  - Klingt am menschlichsten
  - Teurer, braucht Internet

Empfehlung: Option A als Fallback, Option B als Standard
```

### 1.3 ToniBrain aufwerten
```
- GeminiService als primäre Antwort-Engine einbauen
- ToniBrain als Fallback wenn Gemini offline
- Mehr Keywords erkennen (Trinkspruch, Prost, Challenge, Spiel...)
- Fuzzy Matching statt exakte Keyword-Suche
- Conversation-History für Kontext (letzte 3 Aussagen merken)
```

### 1.4 Witze-Datenbank erweitern
```
- Mindestens 50 Witze pro Level (= 300 total)
- Kategorien: Kneipenwitze, Trinksprüche, Wortspiele, Scherzfragen
- "Schon erzählt"-Tracking (keine Wiederholungen)
- JSON-Datei statt hardcoded Strings
```

### 1.5 PartyEngine stabilisieren
```
- Rolling Average über 10 Sekunden statt sofortige Änderung
- Hysterese: Level steigt leicht, fällt langsam
- Mindest-Verweildauer pro Level (30 Sekunden)
```

### 1.6 Info.plist & Permissions
```
- NSMicrophoneUsageDescription: "Toni hört zu wenn du mit ihm sprichst"
- NSSpeechRecognitionUsageDescription: "Toni versteht was du sagst"
```

---

## Stufe 2: Richtige Party-App

> Ziel: App ist DER Grund warum Leute ihr Handy rausholen auf der Party

### 2.1 Trinkspiele
```
Integrierte Spiele die Toni moderiert:

- "Busfahrer": Karten-Trinkspiel, Toni ist Dealer
- "Wahrheit oder Pflicht": Toni stellt Fragen/gibt Aufgaben
- "Ich hab noch nie...": Toni generiert Aussagen (AI-powered)
- "Kings Cup": Digitale Karten mit Toni als Regelerklärer
- "Kategorien": Toni nennt Kategorie, Spieler müssen Begriffe nennen
- "Reimkette": Toni gibt Wort vor, Spieler reimen

Jedes Spiel nutzt den Party-Level für Intensität.
```

### 2.2 Spieler-System
```
- Spieler mit Namen registrieren (Spracheingabe oder Tippen)
- Toni spricht Spieler direkt an: "Hey Marco, trink!"
- Zufällige Spieler-Auswahl für Challenges
- Punkte/Strafen pro Spieler tracken
```

### 2.3 Sound-Design
```
- Kneipen-Atmosphäre: Gläserklirren, Gemurmel, Musik
- Fanfare bei neuem Party-Level
- Trommelwirbel vor Challenges
- "Prost!"-Sound bei Trink-Momenten
- Hintergrund-Playlist (eigene Sounds, kein Copyright)
```

### 2.4 UI/UX Upgrade
```
- Kneipe-Theme: Holztextur, Neonlichter, Bier-Animationen
- Party-Meter als leuchtende Bar
- Toni-Avatar mit Animationen (spricht, lacht, trinkt)
- Haptic Feedback bei Events
- Dark Mode (ist ja Kneipe, immer dunkel)
- Confetti/Partikel bei hohem Party-Level
```

### 2.5 Toni Persönlichkeit erweitern
```
Gemini System Prompt verbessern:

- Toni merkt sich den Abend ("Ihr seid ja immer noch da!")
- Toni reagiert auf Uhrzeit ("Um 3 Uhr morgens? Respekt!")
- Toni hat Catchphrases ("Prost ihr Säcke!", "Nächste Runde!")
- Toni kommentiert Party-Level-Änderungen
- Toni macht Ansagen wenn es zu ruhig wird
- Verschiedene Stimmungen: lustig, philosophisch, motivierend
```

### 2.6 Automatische Interaktionen
```
- Toni meldet sich selbstständig (nicht nur auf Kommando)
- "Hey, es ist zu ruhig hier!" wenn Stille > 2 Min
- Zufällige Trinksprüche alle X Minuten
- "Mitternachts-Special" um 0:00 Uhr
- "Letzte Runde!"-Warnung wenn Party-Level sinkt
```

---

## Stufe 3: App Store Hit

> Ziel: Viral gehen, in den Charts landen

### 3.1 Dialekte & Persönlichkeiten
```
Verschiedene Toni-Varianten (In-App-Purchase oder freischaltbar):

- "Toni" (Standard): Berliner Schnauze
- "Sepp": Bayerisch/Österreichisch
- "Jürgen": Schwäbisch
- "Hein": Norddeutsch/Platt
- "Toni Deluxe": Wienerisch, sophisticated

Jeder mit eigenem Humor-Stil und Sprachmelodie.
```

### 3.2 Spotify/Apple Music Integration
```
- Musik automatisch zur Stimmung anpassen
- "Toni, mach lauter!" → Spotify Volume
- Party-Playlist Vorschläge basierend auf Level
- Erkennung welcher Song läuft → passende Kommentare
```

### 3.3 Multiplayer/Social
```
- Mehrere Handys verbinden (Bluetooth/WiFi)
- Alle hören Toni synchron
- Gruppen-Challenges
- "Wer trinkt am meisten?"-Leaderboard
- Party-Replay am nächsten Tag (beste Momente)
```

### 3.4 AR-Features
```
- Virtuelle Biergläser auf dem Tisch (ARKit)
- Toni als 3D-Avatar im Raum
- AR-Trinkspiel auf dem Tisch
- Photo-Filter mit Party-Effekten
```

### 3.5 Gamification
```
- Achievements: "Erste Party", "5 Spiele gespielt", "Level 5 erreicht"
- Daily Challenges
- Freischaltbare Inhalte (mehr Spiele, Stimmen, Sounds)
- Party-Statistiken: "Deine lauteste Party war am..."
```

### 3.6 Monetarisierung
```
- Kostenlos: Grundfunktionen + 2 Spiele + Standard-Toni
- Premium ($4.99): Alle Spiele + Alle Stimmen + Kein Werbung
- Dialekt-Packs: $1.99 pro Persönlichkeit
- Party-Pass (Abo): $2.99/Monat für AI-powered Features
```

### 3.7 Offline-Modus
```
- Lokale Witze-Datenbank (300+ Witze)
- Alle Trinkspiele offline spielbar
- TTS Fallback auf Enhanced Apple Voices
- Nur AI-generierte Antworten brauchen Internet
```

---

## Technische Verbesserungen (Alle Stufen)

### Audio-Architektur
```
Problem: AudioMonitor und SpeechCommandListener nutzen BEIDE AVAudioEngine
Lösung: Einen SharedAudioManager der die Engine zentral verwaltet
- Ein Tap für Audio-Level
- Ein Tap für Speech Recognition
- Kein Konflikt mehr
```

### API-Key Management
```
- NIEMALS im Code hardcoden
- Option A: Keychain + bei erstem Start eingeben
- Option B: CloudKit für Key-Distribution
- Option C: Eigener Backend-Proxy (sicherer)
```

### Error Handling
```
- Schöne UI-Meldungen statt Console Prints
- Retry-Logik für Gemini API
- Graceful Degradation: AI offline → lokale Witze
- Mikrofon verweigert → Tipp-Modus als Fallback
```

### Testing
```
- Unit Tests für ToniBrain, JokeGenerator, PartyEngine
- UI Tests für kritische Flows
- Snapshot Tests für UI
```

---

## Prioritäten-Matrix

| Was | Impact | Aufwand | Priorität |
|-----|--------|---------|-----------|
| ContentView bauen | Hoch | Mittel | 🔴 Sofort |
| Stimme verbessern | Hoch | Klein | 🔴 Sofort |
| Mehr Witze | Hoch | Klein | 🔴 Sofort |
| PartyEngine fixen | Mittel | Klein | 🟡 Bald |
| Trinkspiele | Hoch | Hoch | 🟡 Bald |
| Spieler-System | Hoch | Mittel | 🟡 Bald |
| Sound-Design | Mittel | Mittel | 🟢 Später |
| Dialekte | Mittel | Hoch | 🟢 Später |
| AR-Features | Niedrig | Hoch | ⚪ Vielleicht |
| Spotify | Mittel | Hoch | ⚪ Vielleicht |

---

## App Store Anforderungen

- **Altersfreigabe**: 17+ (wegen Alkohol-Referenzen)
- **Content Guidelines**: Humor ja, Pornografie/Hate nein
- **Privacy**: Mikrofon-Nutzung klar kommunizieren
- **Disclaimer**: "Bitte trinke verantwortungsvoll" (rechtlich empfohlen)
