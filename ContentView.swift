//
//  ContentView.swift
//  Saufi
//
//  Created by Andreas Pelczer on 18.02.26.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Services

    @StateObject private var speechListener = SpeechCommandListener()
    @StateObject private var audioMonitor = AudioMonitor()
    @StateObject private var partyEngine = PartyEngine()
    @StateObject private var speaker = Speaker()

    private let toniBrain = ToniBrain()
    private let jokeGenerator = JokeGenerator()

    // MARK: - State

    @State private var toniText: String = "Moin! Ich bin Toni. Drück den Knopf und sag was."
    @State private var isProcessing: Bool = false
    @State private var showSettings: Bool = false
    @State private var geminiService: GeminiService?
    @State private var idleTimer: Task<Void, Never>?
    @State private var lastInteractionTime = Date()
    @State private var toniMood: String = "🍺"
    @AppStorage("openai_key") private var openAIKey: String = ""
    @AppStorage("gemini_key") private var geminiKey: String = ""

    /// Auto-interaction interval in seconds
    private let idleIntervalMin: TimeInterval = 45
    private let idleIntervalMax: TimeInterval = 90

    // MARK: - Farben (Kneipe-Theme)

    private let bgDark = Color(red: 0.08, green: 0.06, blue: 0.04)
    private let bgWarm = Color(red: 0.15, green: 0.10, blue: 0.06)
    private let amber = Color(red: 1.0, green: 0.75, blue: 0.20)
    private let neonOrange = Color(red: 1.0, green: 0.45, blue: 0.10)
    private let beerGold = Color(red: 0.95, green: 0.80, blue: 0.30)

    // MARK: - Body

    var body: some View {
        ZStack {
            // Hintergrund
            bgDark.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 8)

                Spacer()

                // Toni Sprechblase
                toniSpeechBubble
                    .padding(.horizontal, 24)

                Spacer()

                // Party Level Anzeige
                partyLevelBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 20)

                // Hauptbutton
                micButton
                    .padding(.bottom, 16)

                // Status
                statusBar
                    .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupServices()
            startIdleTimer()
        }
        .onDisappear {
            idleTimer?.cancel()
        }
        .onChange(of: speechListener.transcript) { _, newValue in
            if speechListener.isListening && !newValue.isEmpty {
                toniText = "🎤 \(newValue)"
            }
        }
        .onChange(of: speechListener.finalTranscript) { _, newValue in
            if newValue == "__EMPTY__" {
                toniText = "Ich hab nix verstanden. Versuch's nochmal! 🙉"
            } else if !newValue.isEmpty {
                handleTranscript(newValue)
            }
        }
        .onChange(of: speechListener.isListening) { _, listening in
            if !listening {
                audioMonitor.resume()
            }
        }
        .onChange(of: audioMonitor.level) { _, newValue in
            partyEngine.update(with: newValue)
        }
        .onChange(of: partyEngine.partyLevel) { _, newLevel in
            updateToniMood(for: newLevel)
        }
        .sheet(isPresented: $showSettings) {
            settingsView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SAUFI")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(amber)

                Text("Kneipenstimme")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(amber.opacity(0.5))
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(amber.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Toni Sprechblase

    private var toniSpeechBubble: some View {
        VStack(spacing: 16) {
            // Toni Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [amber.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Text(toniMood)
                    .font(.system(size: 56))
                    .scaleEffect(speaker.isSpeaking ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: speaker.isSpeaking)
            }

            // Sprechblase
            Text(toniText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(bgWarm)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(amber.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: amber.opacity(0.1), radius: 10)

            // Active Voice Indicator
            if speaker.isSpeaking {
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                    Text(speaker.activeVoice.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(amber.opacity(0.4))
            }
        }
    }

    // MARK: - Party Level Bar

    private var partyLevelBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("PARTY-PEGEL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(amber.opacity(0.5))

                Spacer()

                Text(partyLevelDescription)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(partyLevelColor)
            }

            // Level Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Hintergrund
                    RoundedRectangle(cornerRadius: 6)
                        .fill(bgWarm)
                        .frame(height: 12)

                    // Füllstand
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [beerGold, partyLevelColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * partyFraction, height: 12)
                        .animation(.easeInOut(duration: 0.8), value: partyEngine.partyLevel)

                    // Glow-Effekt bei hohem Level
                    if partyEngine.partyLevel >= 4 {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(neonOrange.opacity(0.3))
                            .frame(width: geo.size.width * partyFraction, height: 12)
                            .blur(radius: 4)
                    }
                }
            }
            .frame(height: 12)

            // Level Labels
            HStack {
                Text("😴")
                Spacer()
                Text("🍺")
                Spacer()
                Text("🔥")
                Spacer()
                Text("🎉")
                Spacer()
                Text("🤪")
                Spacer()
                Text("💀")
            }
            .font(.system(size: 10))
        }
    }

    // MARK: - Mic Button

    private var micButton: some View {
        Button {
            handleMicTap()
        } label: {
            ZStack {
                // Äußerer Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                micButtonColor.opacity(speechListener.isListening ? 0.4 : 0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Button
                Circle()
                    .fill(micButtonColor)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 2)
                    )
                    .shadow(color: micButtonColor.opacity(0.5), radius: 10)

                // Icon
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: speechListener.isListening ? "waveform" : "mic.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: speechListener.isListening)
                }
            }
        }
        .disabled(isProcessing || speaker.isSpeaking)
        .scaleEffect(speechListener.isListening ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: speechListener.isListening)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(statusText)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    // MARK: - Settings

    private var settingsView: some View {
        NavigationStack {
            Form {
                Section("OpenAI TTS (bessere Stimme)") {
                    SecureField("API Key", text: $openAIKey)
                        .textContentType(.password)
                    Text("Stimme: onyx (männlich, warm)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Gemini AI (Witze-Generator)") {
                    SecureField("API Key", text: $geminiKey)
                        .textContentType(.password)
                    Text("Für AI-generierte Antworten von Toni")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Aktive Stimme") {
                    HStack {
                        Text("Backend")
                        Spacer()
                        Text(speaker.activeVoice.rawValue)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.2.0")
                            .foregroundStyle(.secondary)
                    }
                    Text("Bitte trinke verantwortungsvoll.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        speaker.configure(openAIKey: openAIKey.isEmpty ? nil : openAIKey)
                        if !geminiKey.isEmpty {
                            geminiService = GeminiService(apiKey: geminiKey)
                        }
                        showSettings = false
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var partyFraction: CGFloat {
        CGFloat(partyEngine.partyLevel) / 5.0
    }

    private var partyLevelColor: Color {
        switch partyEngine.partyLevel {
        case 0: return .gray
        case 1: return beerGold
        case 2: return amber
        case 3: return .orange
        case 4: return neonOrange
        default: return .red
        }
    }

    private var partyLevelDescription: String {
        switch partyEngine.partyLevel {
        case 0: return "😴 SCHLAFMODUS"
        case 1: return "🍺 GEMÜTLICH"
        case 2: return "🔥 WIRD WARM"
        case 3: return "🎉 PARTY!"
        case 4: return "🤪 ESKALATION"
        default: return "💀 MAXIMUM"
        }
    }

    private var micButtonColor: Color {
        if speechListener.isListening { return .red }
        if isProcessing { return .orange }
        return amber
    }

    private var statusColor: Color {
        if speechListener.isListening { return .red }
        if speaker.isSpeaking { return .green }
        if isProcessing { return .orange }
        return .gray
    }

    private var statusText: String {
        if speechListener.isListening { return "HÖRT ZU..." }
        if isProcessing { return "TONI DENKT..." }
        if speaker.isSpeaking { return "TONI SPRICHT" }
        return "BEREIT"
    }

    // MARK: - Actions

    private func setupServices() {
        audioMonitor.start()
        if !openAIKey.isEmpty {
            speaker.configure(openAIKey: openAIKey)
        }
        if !geminiKey.isEmpty {
            geminiService = GeminiService(apiKey: geminiKey)
        }

        Task {
            let ok = await speechListener.requestPermissions()
            if !ok {
                toniText = "Ich brauch Mikrofon-Zugriff, sonst bin ich taub! 🙉"
            }
        }
    }

    private func handleMicTap() {
        if speechListener.isListening {
            speechListener.stopListening()
            audioMonitor.resume()
        } else {
            toniText = "Ich hör zu..."
            audioMonitor.pause()
            speechListener.startListening(seconds: 5.0)
            resetIdleTimer()
        }
    }

    private func handleTranscript(_ text: String) {
        guard !text.isEmpty else { return }

        print("[ContentView] handleTranscript: '\(text)'")
        isProcessing = true
        let level = partyEngine.partyLevel
        resetIdleTimer()

        Task {
            var response: String

            // Zuerst Gemini probieren wenn Key vorhanden
            if let gemini = geminiService {
                do {
                    response = try await gemini.generateResponse(command: text, partyLevel: level)
                    print("[ContentView] Gemini response: '\(response)'")
                } catch {
                    print("[ContentView] Gemini error: \(error) – Fallback auf ToniBrain")
                    response = toniBrain.respond(to: text, partyLevel: level)
                }
            } else {
                response = toniBrain.respond(to: text, partyLevel: level)
                print("[ContentView] ToniBrain response: '\(response)'")
            }

            toniText = response
            speaker.speak(response)
            isProcessing = false
        }
    }

    // MARK: - Auto-Interaction (Toni spricht von selbst)

    private func startIdleTimer() {
        idleTimer?.cancel()
        lastInteractionTime = Date()

        idleTimer = Task { @MainActor in
            while !Task.isCancelled {
                let interval = TimeInterval.random(in: idleIntervalMin...idleIntervalMax)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { return }

                // Only auto-interact if not busy
                let idle = Date().timeIntervalSince(lastInteractionTime)
                guard idle >= idleIntervalMin,
                      !isProcessing,
                      !speaker.isSpeaking,
                      !speechListener.isListening else {
                    continue
                }

                let level = partyEngine.partyLevel
                let comment = idleComment(for: level)
                toniText = comment
                speaker.speak(comment)
                lastInteractionTime = Date()
            }
        }
    }

    private func resetIdleTimer() {
        lastInteractionTime = Date()
    }

    private func idleComment(for level: Int) -> String {
        switch level {
        case 0:
            return ["Hallo? Ist noch jemand da?", "So still hier… soll ich nen Witz erzählen?", "Drück den Knopf, ich langweil mich!"].randomElement()!
        case 1...2:
            return [jokeGenerator.joke(for: level), jokeGenerator.toast(), "Na, noch ne Runde?"].randomElement()!
        case 3:
            return [jokeGenerator.joke(for: level), "PROST! Auf den Pegel!", "Weiter so, Leute!"].randomElement()!
        default:
            return [jokeGenerator.joke(for: level), "DAS ist ne PARTY!", "Noch eine Runde für alle!"].randomElement()!
        }
    }

    private func updateToniMood(for level: Int) {
        switch level {
        case 0: toniMood = "😴"
        case 1: toniMood = "🍺"
        case 2: toniMood = "😄"
        case 3: toniMood = "🎉"
        case 4: toniMood = "🤪"
        default: toniMood = "🔥"
        }
    }
}

#Preview {
    ContentView()
}
