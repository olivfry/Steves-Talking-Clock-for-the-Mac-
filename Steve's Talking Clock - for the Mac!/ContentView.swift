// Steve's Talking Clock for the Mac
// Copyright © 2026 Oliver Fry.
// MIT licensed — see LICENSE for details.

import SwiftUI
import AVFoundation
import AVKit
import Combine
import CoreAudio
import ServiceManagement

struct ContentView: View {
    // MARK: - Persisted settings
    @AppStorage("mainVoice") private var mainVoice = "Default"
    @AppStorage("quarterVoice") private var quarterVoice = "None"
    @AppStorage("halfVoice") private var halfVoice = "None"
    @AppStorage("threeQuarterVoice") private var threeQuarterVoice = "None"
    @AppStorage("hourVoice") private var hourVoice = "None"
    @AppStorage("alarmVoice") private var alarmVoice = "None"
    @AppStorage("hour24Mode") private var hour24Mode = false
    @AppStorage("alarmTime") private var alarmTime = "08:00 am"
    @AppStorage("gapDuration") private var gapDuration: Double = 0.03
    @AppStorage("didInstallDefaultVoice") private var didInstallDefaultVoice = false
    @AppStorage("selectedOutputDeviceUID") private var selectedOutputDeviceUID = ""

    @AppStorage("qEnable") private var qEnable = false
    @AppStorage("qBefore") private var qBefore = "11:00 pm"
    @AppStorage("qAfter") private var qAfter = "08:00 am"

    @AppStorage("hk_sayTime") private var hk_sayTime = "t"
    @AppStorage("hk_toggle24") private var hk_toggle24 = "h"
    @AppStorage("hk_initialise") private var hk_initialise = "i"
    @AppStorage("hk_audio") private var hk_audio = "u"
    @AppStorage("hk_hotkeys") private var hk_hotkeys = "k"
    @AppStorage("hk_quiet") private var hk_quiet = "q"
    @AppStorage("hk_minimise") private var hk_minimise = "m"

    // MARK: - Runtime state
    @State private var voices: [String: URL] = [:]
    @State private var voiceNames: [String] = ["None", "Default"]
    @State private var activeSheet: Sheet?
    @State private var recordingAction: String? = nil
    @State private var engine = AVAudioEngine()
    @State private var sourceNode: AVAudioSourceNode?
    @State private var speakGeneration: Int = 0
    @State private var outputDevices: [AudioOutputDevice] = []
    @State private var selectedDeviceID: AudioDeviceID = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var lastAnnouncedEpochMinute: Int = -1
    @State private var lastAlarmFiredEpochMinute: Int = -1

    enum FocusedControl: Hashable, CaseIterable {
        case mainVoice, quarterVoice, halfVoice, threeQuarterVoice, hourVoice, alarmVoice
        case gapDuration, alarmTime, hour24Mode
        case sayTime, initialise, openVoices, saveSettings, audio, hotkeys, quiet, minimise
    }
    @FocusState private var focusedControl: FocusedControl?

    enum Sheet: Identifiable {
        case audio, hotkeys, quiet
        var id: Int { hashValue }
    }

    private static var hotkeyMonitorInstalled = false
    private static let ttsEngine = AVSpeechSynthesizer()

    // MARK: - Body
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                voicePicker("Main Voice List", selection: $mainVoice, control: .mainVoice)
                voicePicker("Quarter Hour Voice List", selection: $quarterVoice, control: .quarterVoice)
                voicePicker("Half Hour Voice List", selection: $halfVoice, control: .halfVoice)
                voicePicker("Three Quarter Hour Voice List", selection: $threeQuarterVoice, control: .threeQuarterVoice)
                voicePicker("On the Hour Voice List", selection: $hourVoice, control: .hourVoice)
                voicePicker("Alarm Voice List", selection: $alarmVoice, control: .alarmVoice)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Gap Delay: \(String(format: "%.3f", gapDuration))s")
                        .font(.system(size: 9, weight: .bold))
                    Slider(value: $gapDuration, in: 0.00...0.20)
                        .controlSize(.mini)
                        .focused($focusedControl, equals: .gapDuration)
                        .accessibilityLabel("Gap delay")
                        .accessibilityValue(String(format: "%.3f seconds", gapDuration))
                        .accessibilityHint("Delay inserted between each spoken word.")
                }

                HStack {
                    TextField("hh:mm am", text: $alarmTime)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 9))
                        .focused($focusedControl, equals: .alarmTime)
                        .accessibilityLabel("Alarm time")
                        .accessibilityHint("Enter hh:mm am or pm, or hh:mm for 24-hour time.")
                }
                Toggle("24 Hour Mode", isOn: $hour24Mode)
                    .font(.caption)
                    .focused($focusedControl, equals: .hour24Mode)
                    .accessibilityLabel("24 hour mode")
                    .accessibilityHint("Announces the time in 24 hour format.")
                Spacer().frame(height: 8)
            }
            .frame(width: 200).padding(.trailing, 12)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Voice settings")

            VStack(spacing: 20) {
                Button("Say Time") { startSpeak(mainVoice, bypassQuietMode: true) }
                    .keyboardShortcut("t", modifiers: [.option])
                    .focused($focusedControl, equals: .sayTime)
                    .accessibilityHint("Speaks the current time using the main voice. Option T.")

                Button("Initialise") {
                    generateDefaultIfMissing()
                    refresh()
                    NSSound.beep()
                    announce("Voices refreshed")
                }
                .focused($focusedControl, equals: .initialise)
                .accessibilityHint("Rescans the voices folder and refreshes the voice lists. Option I.")

                Button("Open Voices Folder") { revealVoicesFolder() }
                    .focused($focusedControl, equals: .openVoices)
                    .accessibilityHint("Reveals the folder where voice packs are stored in Finder.")

                Button("Save Settings") { NSSound.beep() }
                    .focused($focusedControl, equals: .saveSettings)
                    .accessibilityHint("Settings save automatically. This button is retained for compatibility.")

                Button("Audio...") { openAudioSheet() }
                    .focused($focusedControl, equals: .audio)
                    .accessibilityHint("Choose the sound device used for announcements. Option U.")

                Button("Hotkeys…") { activeSheet = .hotkeys }
                    .focused($focusedControl, equals: .hotkeys)
                    .accessibilityHint("Opens the hotkey configuration dialog. Option K.")

                Button("Quiet Mode…") { activeSheet = .quiet }
                    .focused($focusedControl, equals: .quiet)
                    .accessibilityHint("Opens the quiet mode configuration dialog. Option Q.")

                Button("Minimise") { NSApp.hide(nil) }
                    .keyboardShortcut("m", modifiers: [.option])
                    .focused($focusedControl, equals: .minimise)
                    .accessibilityHint("Hides the window. The clock keeps running. Option M.")
            }
            .buttonStyle(.bordered).controlSize(.small).frame(width: 120)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Clock controls")
        }
        .padding().frame(width: 350, height: 400)
        .onAppear {
            setupEngine()
            setupHotkeyMonitor()
            refresh()
            promptFirstRun()
            checkForUpdatesOnLaunch()
            if !didInstallDefaultVoice {
                DispatchQueue.global(qos: .userInitiated).async {
                    seedBundledDefaultVoice()
                    DispatchQueue.main.async {
                        didInstallDefaultVoice = true
                        refresh()
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { item in sheetView(for: item) }
        .onReceive(timer) { _ in checkAutoAnnounce() }
        .onChange(of: hour24Mode) { isOn in
            reformatAlarmTimeForMode(isOn)
            announce(isOn ? "24 hour mode on" : "24 hour mode off")
        }
    }

    // MARK: - Method detection (matches concatenation.txt)
    //
    // Detects the concatenation method from the set of files in the voice folder.
    // The order matters — the most specific markers are checked first:
    //   7  cuckoo.wav
    //   6  chime.wav
    //   8  hour01.wav
    //   10 and.wav
    //   9  teena.wav / tya.wav / ty1a.wav  (unique to Method 9)
    //   5  1a.wav                          (unique after Method 9 has been ruled out)
    //   2  thir.wav                        (unique after Methods 5 and 9 ruled out)
    //   4  59.wav                          (only Method 4 has single-file 21-59)
    //   1  10.wav                          (Method 1 has 10.wav but no 59.wav)
    //   3  only single-digit files         (Method 3 has no 10-59)
    func detectMethod(in voiceURL: URL) -> Int {
        let fm = FileManager.default
        func has(_ f: String) -> Bool {
            fm.fileExists(atPath: voiceURL.appendingPathComponent(f).path)
        }
        if has("cuckoo.wav") { return 7 }
        if has("chime.wav") { return 6 }
        if has("hour01.wav") { return 8 }
        if has("and.wav") { return 10 }
        if has("teena.wav") || has("tya.wav") || has("ty1a.wav") { return 9 }
        if has("1a.wav") { return 5 }
        if has("thir.wav") { return 2 }
        if has("59.wav") { return 4 }
        if has("10.wav") { return 1 }
        if has("its.wav") && has("1.wav") { return 3 }
        return 1
    }

    // MARK: - Speaking
    func startSpeak(_ voice: String, bypassQuietMode: Bool = false) {
        if voice == "None" { return }
        if !bypassQuietMode && checkQuietMode() { return }

        if voice == "System Voice" {
            speakSystemVoice()
            return
        }
        if voice.hasPrefix("System: ") {
            speakWithTTS(voice: voice)
            return
        }

        guard let voiceURL = voices[voice] else { return }

        let method = detectMethod(in: voiceURL)
        let cal = Calendar.current
        let now = Date()
        let h24 = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        let isPm = h24 >= 12

        // Methods 6, 7, 8 are chiming clocks — they never speak AM/PM.
        let use24 = (method == 6 || method == 7 || method == 8) ? false : hour24Mode
        var h12 = h24 % 12
        if h12 == 0 { h12 = 12 }

        var words = buildWordList(method: method, h24: h24, h12: h12, m: m, use24: use24)
        if words.isEmpty { return }

        // "It's ..." prefix and AM/PM suffix are for talking methods only.
        if method != 6 && method != 7 && method != 8 {
            words.insert("its.wav", at: 0)
            if !use24 {
                words.append(isPm ? "PM.wav" : "AM.wav")
            }
        }

        playUsingSourceNode(files: words, voiceName: voice)
    }

    /// Builds the word-file list for a given method and time, per concatenation.txt.
    /// Returns [] if the method has nothing to say at this minute (Big Ben off-quarter,
    /// Method 8 at non-hour is still returned — Say Time uses it).
    func buildWordList(method: Int, h24: Int, h12: Int, m: Int, use24: Bool) -> [String] {
        let h = use24 ? h24 : h12
        var words: [String] = []

        // MARK: Hour
        switch method {
        case 1:
            if h <= 20 { words.append("\(h).wav") }
            else { words += ["20.wav", "\(h % 10).wav"] }   // 21-23 in 24h mode

        case 2, 5:
            if h <= 12 { words.append("\(h).wav") }
            else if h < 20 {
                let prefix = ["thir","for","fif","six","seven","eight","nine"][h - 13]
                words += ["\(prefix).wav", "teen.wav"]
            } else {
                // h = 20-23 in 24h mode
                words += ["twen.wav", "ty.wav"]
                if h % 10 > 0 { words.append("ty\(h % 10).wav") }
            }

        case 3:
            // Digits only: each digit of the hour as its own file.
            for d in String(h) { words.append("\(d).wav") }

        case 4:
            words.append("\(h).wav")

        case 6:
            // Big Ben: the entire word list is the quarter-hour song.
            switch m {
            case 0:  return ["00.wav"]
            case 15: return ["15.wav"]
            case 30: return ["30.wav"]
            case 45: return ["45.wav"]
            default: return []
            }

        case 7:
            // Cuckoo: one cuckoo per hour, at any minute (Say Time works too).
            var w: [String] = []
            for _ in 0..<h12 { w.append("cuckoo.wav") }
            return w

        case 8:
            // Hourly: always returns the current hour's sound so Say Time works.
            return [String(format: "hour%02d.wav", h12)]

        case 9:
            if h <= 12 { words.append("\(h).wav") }
            else if h < 20 {
                let prefix = ["thir","for","fif","six","seven","eight","nine"][h - 13]
                words += ["\(prefix).wav", "teen.wav"]
            } else {
                words += ["twen.wav", "ty.wav"]
                if h % 10 > 0 { words.append("ty\(h % 10).wav") }
            }

        case 10:
            if h <= 20 { words.append("\(h).wav") }
            else { words += ["\(h % 10).wav", "and.wav", "20.wav"] }   // 21-23 in 24h

        default:
            words.append("\(h).wav")
        }

        // MARK: Minute
        switch method {
        case 1:
            if m == 0 { words.append("00.wav") }
            else if m < 10 { words += ["o.wav", "\(m).wav"] }
            else if m < 20 { words.append("\(m).wav") }
            else {
                words.append("\((m / 10) * 10).wav")
                if m % 10 > 0 { words.append("\(m % 10).wav") }
            }

        case 2:
            if m == 0 { words.append("00.wav") }
            else if m < 10 { words += ["o.wav", "\(m).wav"] }
            else if m < 13 { words.append("\(m).wav") }
            else if m < 20 {
                let prefix = ["thir","for","fif","six","seven","eight","nine"][m - 13]
                words += ["\(prefix).wav", "teen.wav"]
            } else {
                let tens = ["twen","thir","for","fif"][m / 10 - 2]
                words += ["\(tens).wav", "ty.wav"]
                if m % 10 > 0 { words.append("ty\(m % 10).wav") }
            }

        case 3:
            if m == 0 { words.append("00.wav") }
            else if m < 10 { words += ["o.wav", "\(m).wav"] }
            else { for d in String(m) { words.append("\(d).wav") } }

        case 4:
            words.append(m == 0 ? "00.wav" : "\(m).wav")

        case 5:
            // Method 5 has 1a-12a only; 13-59 reuse the hour recordings.
            if m == 0 { words.append("00.wav") }
            else if m < 10 { words += ["o.wav", "\(m)a.wav"] }
            else if m < 13 { words.append("\(m)a.wav") }
            else if m < 20 {
                let prefix = ["thir","for","fif","six","seven","eight","nine"][m - 13]
                words += ["\(prefix).wav", "teen.wav"]
            } else {
                let tens = ["twen","thir","for","fif"][m / 10 - 2]
                words += ["\(tens).wav", "ty.wav"]
                if m % 10 > 0 { words.append("ty\(m % 10).wav") }
            }

        case 9:
            // Method 9 has a-variants for every minute component.
            if m == 0 { words.append("00.wav") }
            else if m < 10 { words += ["o.wav", "\(m)a.wav"] }
            else if m < 13 { words.append("\(m)a.wav") }
            else if m < 20 {
                let prefix = ["thir","for","fif","six","seven","eight","nine"][m - 13]
                words += ["\(prefix).wav", "teena.wav"]
            } else {
                let tens = ["twen","thir","for","fif"][m / 10 - 2]
                words += ["\(tens).wav", "tya.wav"]
                if m % 10 > 0 { words.append("ty\(m % 10)a.wav") }
            }

        case 10:
            // Danish: "one and twenty" for 21.
            if m < 20 { words.append("\(m).wav") }
            else if m % 10 == 0 { words.append("\(m).wav") }
            else { words += ["\(m % 10).wav", "and.wav", "\((m / 10) * 10).wav"] }

        default:
            break
        }

        return words
    }

    // MARK: - TTS

    /// Speaks the time using the VoiceOver voice if VoiceOver is running, or the
    /// Spoken Content System Voice otherwise. VoiceOver has no public API to read
    /// its own configured voice, so this is the closest available approximation.
    func speakSystemVoice() {
        Self.ttsEngine.stopSpeaking(at: .immediate)
        speakGeneration += 1
        if let oldNode = sourceNode {
            engine.detach(oldNode)
            sourceNode = nil
        }

        let text = timeText(for: Date(), use24: hour24Mode)

        if NSWorkspace.shared.isVoiceOverEnabled {
            NSAccessibility.post(
                element: NSApp.mainWindow ?? NSApplication.shared,
                notification: .announcementRequested,
                userInfo: [
                    NSAccessibility.NotificationUserInfoKey.announcement: text,
                    NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel.high.rawValue
                ]
            )
        } else {
            let utterance = AVSpeechUtterance(string: text)
            let defaultRaw = NSSpeechSynthesizer.defaultVoice.rawValue
            let short = defaultRaw.split(separator: ".").last.map(String.init) ?? ""
            if let match = AVSpeechSynthesisVoice.speechVoices().first(where: {
                $0.name.lowercased() == short.lowercased()
            }) {
                utterance.voice = match
            }
            Self.ttsEngine.speak(utterance)
        }
    }

    /// Speaks with a specific AVSpeech voice, looked up by the name in "System: X".
    func speakWithTTS(voice: String) {
        Self.ttsEngine.stopSpeaking(at: .immediate)
        speakGeneration += 1
        if let oldNode = sourceNode {
            engine.detach(oldNode)
            sourceNode = nil
        }

        let systemName = String(voice.dropFirst("System: ".count))
        let text = timeText(for: Date(), use24: hour24Mode)
        let utterance = AVSpeechUtterance(string: text)

        // Try AVFoundation first; if the voice only exists in NSSpeechSynthesizer's
        // list (rare), fall through and use the default AVSpeech voice instead.
        if let v = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name == systemName }) {
            utterance.voice = v
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
                ?? AVSpeechSynthesisVoice(language: "en-US")
        }
        Self.ttsEngine.speak(utterance)
    }

    /// Human-readable time text for TTS synthesis.
    func timeText(for date: Date, use24: Bool) -> String {
        let cal = Calendar.current
        var h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        let isPm = h >= 12
        if !use24 { h = (h % 12 == 0) ? 12 : h % 12 }

        let hWord = "\(h)"
        let mWord: String
        if m == 0 { mWord = "o'clock" }
        else if m < 10 { mWord = "oh \(m)" }
        else { mWord = "\(m)" }

        var s = "The time is \(hWord) \(mWord)"
        if !use24 { s += isPm ? " P M" : " A M" }
        return s
    }

    // MARK: - Auto announcements (quarter hours + alarm)
    func checkAutoAnnounce() {
        let cal = Calendar.current
        let now = Date()
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        let epochMinute = h * 60 + m

        // Alarm takes priority if it collides with a quarter-hour.
        if let (ah, am) = parseAlarmTime(alarmTime), ah == h, am == m,
           lastAlarmFiredEpochMinute != epochMinute {
            lastAlarmFiredEpochMinute = epochMinute
            let selected = (alarmVoice == "None") ? mainVoice : alarmVoice
            if selected != "None" {
                startSpeak(selected, bypassQuietMode: true)
            }
            return
        }

        let isQuarter = (m == 0 || m == 15 || m == 30 || m == 45)
        guard isQuarter, epochMinute != lastAnnouncedEpochMinute else { return }
        lastAnnouncedEpochMinute = epochMinute

        // Per the manual, no fallback to mainVoice for automatic announcements.
        var selected = "None"
        switch m {
        case 0:  selected = hourVoice
        case 15: selected = quarterVoice
        case 30: selected = halfVoice
        case 45: selected = threeQuarterVoice
        default: return
        }
        if selected == "None" { return }
        startSpeak(selected, bypassQuietMode: false)
    }

    // MARK: - Alarm time parsing / formatting
    func parseAlarmTime(_ raw: String) -> (hour: Int, minute: Int)? {
        let s = raw.trimmingCharacters(in: .whitespaces).lowercased()
        if s.isEmpty { return nil }

        let f12 = DateFormatter()
        f12.dateFormat = "h:mm a"
        f12.isLenient = true
        f12.locale = Locale(identifier: "en_US_POSIX")
        if let d = f12.date(from: s) {
            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
            if let h = c.hour, let m = c.minute { return (h, m) }
        }

        let f24 = DateFormatter()
        f24.dateFormat = "HH:mm"
        f24.locale = Locale(identifier: "en_US_POSIX")
        if let d = f24.date(from: s) {
            let c = Calendar.current.dateComponents([.hour, .minute], from: d)
            if let h = c.hour, let m = c.minute { return (h, m) }
        }
        return nil
    }

    func formatAlarmTime(hour: Int, minute: Int, use24: Bool) -> String {
        if use24 { return String(format: "%02d:%02d", hour, minute) }
        let h12 = (hour % 12 == 0) ? 12 : hour % 12
        let suffix = hour >= 12 ? "pm" : "am"
        return String(format: "%02d:%02d %@", h12, minute, suffix)
    }

    func reformatAlarmTimeForMode(_ use24: Bool) {
        guard let (h, m) = parseAlarmTime(alarmTime) else { return }
        alarmTime = formatAlarmTime(hour: h, minute: m, use24: use24)
    }

    // MARK: - Voices on disk
    func getExternalVoicesURL() -> URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let url = paths[0].appendingPathComponent("StevesTalkingClock/Voices")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func revealVoicesFolder() {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: getExternalVoicesURL().path)
    }

    func seedBundledDefaultVoice() {
        guard let resources = Bundle.main.resourceURL else { return }
        let bundled = resources.appendingPathComponent("Default")
        let dest = getExternalVoicesURL().appendingPathComponent("Default")
        let fm = FileManager.default
        guard fm.fileExists(atPath: bundled.path) else { return }
        if fm.fileExists(atPath: dest.path) { return }
        try? fm.copyItem(at: bundled, to: dest)
    }

    func generateDefaultIfMissing() {
        let dest = getExternalVoicesURL().appendingPathComponent("Default")
        guard !FileManager.default.fileExists(atPath: dest.path) else { return }
        seedBundledDefaultVoice()
    }

    func refresh() {
        var foundVoices: [String: URL] = [:]

        // Bundled folders
        if let resources = Bundle.main.resourceURL,
           let items = try? FileManager.default.contentsOfDirectory(
                at: resources,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]) {
            for url in items {
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                guard isDir else { continue }
                foundVoices[url.lastPathComponent] = url
            }
        }

        // User folders
        let externalURL = getExternalVoicesURL()
        if let items = try? FileManager.default.contentsOfDirectory(
            at: externalURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]) {
            for url in items {
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                guard isDir else { continue }
                foundVoices[url.lastPathComponent] = url
            }
        }

        // "System Voice" — uses the Spoken Content System Voice (the one users
        // configure to match their VoiceOver voice in System Settings), or posts
        // a real VoiceOver announcement if VoiceOver is currently running.
        foundVoices["System Voice"] = URL(fileURLWithPath: "/SystemVoice")

        // Installed AVFoundation voices as "System: X" entries.
        let installed = AVSpeechSynthesisVoice.speechVoices()
        print("refresh(): AVSpeechSynthesisVoice.speechVoices() returned \(installed.count) voices")
        for v in installed {
            let key = "System: \(v.name)"
            if foundVoices[key] == nil {
                foundVoices[key] = URL(fileURLWithPath: "/TTS")
            }
        }

        // If AVFoundation returned nothing, fall back to NSSpeechSynthesizer's list.
        if installed.isEmpty {
            let nsVoices = NSSpeechSynthesizer.availableVoices
            print("refresh(): AV returned 0; falling back to NSSpeechSynthesizer (\(nsVoices.count))")
            for v in nsVoices {
                let raw = v.rawValue
                let short = raw.split(separator: ".").last.map(String.init) ?? raw
                let key = "System: \(short)"
                if foundVoices[key] == nil {
                    foundVoices[key] = URL(fileURLWithPath: "/TTS")
                }
            }
        }

        self.voices = foundVoices
        var names = Array(foundVoices.keys).sorted()
        if !names.contains("Default") { names.insert("Default", at: 0) }
        if !names.contains("None") { names.insert("None", at: 0) }
        self.voiceNames = names
        print("refresh(): picker now shows \(names.count) entries: \(names)")
    }
    // MARK: - Audio output devices
    struct AudioOutputDevice: Identifiable, Hashable {
        let id: AudioDeviceID
        let name: String
        let uid: String
    }

    func openAudioSheet() {
        outputDevices = enumerateOutputDevices()
        selectedDeviceID = resolveSavedDeviceID()
        activeSheet = .audio
    }

    func enumerateOutputDevices() -> [AudioOutputDevice] {
        var propertySize: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let systemObject = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(systemObject, &address, 0, nil, &propertySize) == noErr
        else { return [] }

        let count = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(systemObject, &address, 0, nil, &propertySize, &ids) == noErr
        else { return [] }

        var result: [AudioOutputDevice] = []
        for id in ids {
            var streamsAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamsSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(id, &streamsAddress, 0, nil, &streamsSize) == noErr,
                  streamsSize > 0 else { continue }

            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var nameUnmanaged: Unmanaged<CFString>?
            var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            guard AudioObjectGetPropertyData(id, &nameAddress, 0, nil, &nameSize, &nameUnmanaged) == noErr,
                  let nameCF = nameUnmanaged?.takeRetainedValue() else { continue }
            let name = nameCF as String

            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var uidUnmanaged: Unmanaged<CFString>?
            var uidSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            guard AudioObjectGetPropertyData(id, &uidAddress, 0, nil, &uidSize, &uidUnmanaged) == noErr,
                  let uidCF = uidUnmanaged?.takeRetainedValue() else { continue }

            result.append(AudioOutputDevice(id: id, name: name, uid: uidCF as String))
        }
        return result
    }

    func resolveSavedDeviceID() -> AudioDeviceID {
        guard !selectedOutputDeviceUID.isEmpty else { return 0 }
        return enumerateOutputDevices().first { $0.uid == selectedOutputDeviceUID }?.id ?? 0
    }

    private func applyDeviceProperty(_ id: AudioDeviceID) {
        guard id != 0 else { return }
        guard let outputUnit = engine.outputNode.audioUnit else { return }
        var deviceID = id
        AudioUnitSetProperty(outputUnit,
                             kAudioOutputUnitProperty_CurrentDevice,
                             kAudioUnitScope_Global,
                             0,
                             &deviceID,
                             UInt32(MemoryLayout<AudioDeviceID>.size))
    }

    func applyOutputDevice(_ id: AudioDeviceID) {
        let wasRunning = engine.isRunning
        if wasRunning { engine.stop() }
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        applyDeviceProperty(id)
        if wasRunning { try? engine.start() }

        if id == 0 {
            selectedOutputDeviceUID = ""
        } else if let match = enumerateOutputDevices().first(where: { $0.id == id }) {
            selectedOutputDeviceUID = match.uid
        }
    }

    // MARK: - First-run experience

    func promptFirstRun() {
        guard !UserDefaults.standard.bool(forKey: "hasDoneFirstRun") else { return }

        // Only prompt from /Applications. From Xcode, SMAppService would register the
        // DerivedData path, which breaks on the next Clean Build.
        guard Bundle.main.bundlePath.hasPrefix("/Applications/") else {
            print("promptFirstRun(): skipping — not running from /Applications (\(Bundle.main.bundlePath))")
            return
        }

        let alert = NSAlert()
        alert.messageText = "Welcome to Steve's Talking Clock"
        alert.informativeText = "Two quick preferences. You can change these later from System Settings."
        alert.addButton(withTitle: "Continue")
        alert.alertStyle = .informational

        let loginCheck = NSButton(checkboxWithTitle: "Launch at login",
                                  target: nil, action: nil)
        loginCheck.state = .on

        let updateCheck = NSButton(checkboxWithTitle: "Check for updates automatically",
                                   target: nil, action: nil)
        updateCheck.state = .on

        let stack = NSStackView(views: [loginCheck, updateCheck])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.frame = NSRect(x: 0, y: 0, width: 300, height: 52)
        alert.accessoryView = stack

        // Show after a brief delay so the main window is up first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            alert.runModal()

            if loginCheck.state == .on {
                do {
                    try SMAppService.mainApp.register()
                    print("Registered as login item.")
                } catch {
                    print("Login item registration failed: \(error)")
                }
            }

            UserDefaults.standard.set(updateCheck.state == .on, forKey: "autoCheckUpdates")
            UserDefaults.standard.set(true, forKey: "hasDoneFirstRun")
        }
    }

    /// Silent check on launch. Only shows an alert if a newer version exists.
    /// Never bothers the user with "you're up to date."
    func checkForUpdatesOnLaunch() {
        guard UserDefaults.standard.bool(forKey: "autoCheckUpdates") else { return }
        guard let url = URL(string:
            "https://api.github.com/repos/olivfry/Steves-Talking-Clock-for-the-Mac-/releases/latest")
        else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String
            else { return }   // silent on network error — don't nag on first launch

            let latest = tag.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

            guard latest.compare(current, options: .numeric) == .orderedDescending else { return }

            // Grab a one-line excerpt from the release body, if present
            let body = (json["body"] as? String) ?? ""
            let firstLine = body.split(separator: "\n").first.map(String.init) ?? ""

            DispatchQueue.main.async {
                let a = NSAlert()
                a.messageText = "Update Available — v\(latest)"
                a.informativeText = "You're on v\(current).\n\n\(firstLine)"
                a.addButton(withTitle: "Download")
                a.addButton(withTitle: "Later")
                a.alertStyle = .informational
                if a.runModal() == .alertFirstButtonReturn,
                   let releases = URL(string:
                    "https://github.com/olivfry/Steves-Talking-Clock-for-the-Mac-/releases") {
                    NSWorkspace.shared.open(releases)
                }
            }
        }.resume()
    }
    
    // MARK: - Audio engine
    func setupEngine() {
        _ = engine.mainMixerNode
        applyDeviceProperty(resolveSavedDeviceID())
        try? engine.start()
        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { _ in
            if !self.engine.isRunning { try? self.engine.start() }
        }
    }

    func playUsingSourceNode(files: [String], voiceName: String) {
        guard let voiceURL = voices[voiceName] else { return }
        if files.isEmpty { return }

        Self.ttsEngine.stopSpeaking(at: .immediate)

        speakGeneration += 1
        let thisGen = speakGeneration

        if let oldNode = sourceNode {
            engine.detach(oldNode)
            sourceNode = nil
        }
        if !engine.isRunning { try? engine.start() }

        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let gap = gapDuration

        DispatchQueue.global(qos: .userInitiated).async {
            guard let allData = ContentView.buildAudioData(
                files: files, voiceURL: voiceURL,
                outputFormat: outputFormat, gapDuration: gap) else { return }

            DispatchQueue.main.async {
                guard self.speakGeneration == thisGen else { return }
                self.attachSourceNode(allData: allData, outputFormat: outputFormat)
            }
        }
    }

    /// Returns nil if no file could be read — the caller treats that as "nothing to play".
    static func buildAudioData(files: [String], voiceURL: URL,
                               outputFormat: AVAudioFormat, gapDuration: Double) -> [Float]? {
        var allData: [Float] = []
        var readAny = false
        let gapSamples = Int(gapDuration * outputFormat.sampleRate)

        for fileName in files {
            let fileURL = voiceURL.appendingPathComponent(fileName)
            guard let file = try? AVAudioFile(forReading: fileURL) else { continue }
            let frameCount = AVAudioFrameCount(file.length)
            guard frameCount > 0 else { continue }
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                     frameCapacity: frameCount) else { continue }
            try? file.read(into: inputBuffer)

            guard let converter = AVAudioConverter(from: file.processingFormat, to: outputFormat)
            else { continue }

            let ratio = file.processingFormat.sampleRate / outputFormat.sampleRate
            let convertedFrames = AVAudioFrameCount(Double(frameCount) / ratio) + 1
            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat,
                                                      frameCapacity: convertedFrames) else { continue }

            var error: NSError?
            var inputProvided = false
            // NOTE: the input block must return data exactly once — returning .haveData
            // on every call (as an earlier version did) produces silence or doubled audio.
            converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                if inputProvided {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                inputProvided = true
                outStatus.pointee = .haveData
                return inputBuffer
            }

            if let channelData = outputBuffer.floatChannelData?[0] {
                for i in 0..<Int(outputBuffer.frameLength) {
                    allData.append(channelData[i])
                }
                readAny = true
            }
            if gapSamples > 0 {
                allData.append(contentsOf: Array(repeating: 0, count: gapSamples))
            }
        }

        guard readAny else { return nil }

        let trailing = Int(0.3 * outputFormat.sampleRate)
        if trailing > 0 {
            allData.append(contentsOf: Array(repeating: 0, count: trailing))
        }
        return allData
    }

    func attachSourceNode(allData: [Float], outputFormat: AVAudioFormat) {
        var currentFrame = 0
        let totalFrames = allData.count

        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sample: Float = currentFrame < totalFrames ? allData[currentFrame] : 0
                for buffer in abl {
                    if let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) {
                        ptr[frame] = sample
                    }
                }
                currentFrame += 1
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: outputFormat)
        sourceNode = node

        let duration = Double(totalFrames) / outputFormat.sampleRate + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard self.sourceNode === node else { return }
            self.engine.detach(node)
            self.sourceNode = nil
        }
    }

    // MARK: - Quiet mode
    func checkQuietMode() -> Bool {
        guard qEnable else { return false }
        let cal = Calendar.current
        let now = Date()
        let nowMinutes = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)

        func timeToMinutes(_ s: String) -> Int? {
            let trimmed = s.trimmingCharacters(in: .whitespaces).lowercased()
            if trimmed.isEmpty { return nil }

            let f12 = DateFormatter()
            f12.dateFormat = "h:mm a"   // single-h accepts both "8:00 am" and "08:00 am"
            f12.isLenient = true
            f12.locale = Locale(identifier: "en_US_POSIX")
            if let d = f12.date(from: trimmed) {
                return cal.component(.hour, from: d) * 60 + cal.component(.minute, from: d)
            }

            let f24 = DateFormatter()
            f24.dateFormat = "HH:mm"
            f24.locale = Locale(identifier: "en_US_POSIX")
            if let d = f24.date(from: trimmed) {
                return cal.component(.hour, from: d) * 60 + cal.component(.minute, from: d)
            }
            return nil
        }

        let stopMins = timeToMinutes(qBefore) ?? 1380   // 11:00 pm
        let startMins = timeToMinutes(qAfter) ?? 360    // 06:00 am

        if stopMins > startMins {
            return nowMinutes >= stopMins || nowMinutes < startMins
        } else {
            return nowMinutes >= stopMins && nowMinutes < startMins
        }
    }

    // MARK: - Hotkeys
    func setupHotkeyMonitor() {
        guard !Self.hotkeyMonitorInstalled else { return }
        Self.hotkeyMonitorInstalled = true

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let action = recordingAction {
                let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
                saveHotkey(action: action, key: key)
                recordingAction = nil
                return nil
            }

            // When a sheet is open, let it handle Tab/Space itself.
            if activeSheet != nil { return event }

            // Tab (keyCode 48) — advance focus through our explicit order.
            if event.keyCode == 48 {
                let shift = event.modifierFlags.contains(.shift)
                advanceFocus(forward: !shift)
                return nil
            }

            if event.keyCode == 49,
               event.modifierFlags.intersection([.option, .command, .control]).isEmpty {
                if let responder = NSApp.keyWindow?.firstResponder,
                   responder is NSTextView { return event }
                if let control = focusedControl {
                    return handleControl(control) ? nil : event
                }
                startSpeak(mainVoice, bypassQuietMode: true)
                return nil
            }

            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
            if event.modifierFlags.contains(.option) {
                switch key {
                case hk_sayTime:    startSpeak(mainVoice, bypassQuietMode: true); return nil
                case hk_toggle24:   hour24Mode.toggle(); return nil
                case hk_initialise: generateDefaultIfMissing(); refresh(); return nil
                case hk_audio:      openAudioSheet(); return nil
                case hk_hotkeys:    activeSheet = .hotkeys; return nil
                case hk_quiet:      activeSheet = .quiet; return nil
                case hk_minimise:   NSApp.hide(nil); return nil
                default: break
                }
            }
            return event
        }
    }

    func advanceFocus(forward: Bool) {
        let order = FocusedControl.allCases
        let idx = order.firstIndex(of: focusedControl ?? .mainVoice) ?? 0
        let next = forward ? (idx + 1) % order.count : (idx - 1 + order.count) % order.count
        focusedControl = order[next]
    }

    /// Returns true if we handled Space for this control (event should be swallowed),
    /// false if the system control should receive it (picker opens menu, text field
    /// inserts a space, etc.).
    @discardableResult
    func handleControl(_ c: FocusedControl) -> Bool {
        switch c {
        case .sayTime:      startSpeak(mainVoice, bypassQuietMode: true); return true
        case .initialise:   generateDefaultIfMissing(); refresh(); NSSound.beep(); return true
        case .openVoices:   revealVoicesFolder(); return true
        case .saveSettings: NSSound.beep(); return true
        case .audio:        openAudioSheet(); return true
        case .hotkeys:      activeSheet = .hotkeys; return true
        case .quiet:        activeSheet = .quiet; return true
        case .minimise:     NSApp.hide(nil); return true
        case .hour24Mode:   hour24Mode.toggle(); return true

        case .mainVoice, .quarterVoice, .halfVoice, .threeQuarterVoice,
             .hourVoice, .alarmVoice, .gapDuration, .alarmTime:
            // System controls: let Space open the picker menu, move the slider, or
            // insert a space into the text field.
            return false
        }
    }

    func saveHotkey(action: String, key: String) {
        switch action {
        case "Say Time":     hk_sayTime = key
        case "24 Hour Mode": hk_toggle24 = key
        case "Initialise":   hk_initialise = key
        case "Audio":        hk_audio = key
        case "Hotkeys":      hk_hotkeys = key
        case "Quiet":        hk_quiet = key
        case "Minimise":     hk_minimise = key
        default: break
        }
    }

    // MARK: - UI helpers
    func voicePicker(_ label: String, selection: Binding<String>, control: FocusedControl) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.system(size: 9, weight: .bold))
            Picker("", selection: selection) {
                ForEach(voiceNames, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            .controlSize(.small)
            .focused($focusedControl, equals: control)
            .accessibilityLabel(label)
            .accessibilityValue(selection.wrappedValue)
            .accessibilityHint("Chooses the voice used for \(label.replacingOccurrences(of: " Voice List", with: "").lowercased()).")
        }
    }

    @ViewBuilder
    func sheetView(for type: Sheet) -> some View {
        VStack(spacing: 15) {
            switch type {
            case .hotkeys:
                Text("Hotkey Configuration").font(.headline)
                List {
                    hotkeyRow("Say Time", key: hk_sayTime)
                    hotkeyRow("24 Hour Mode", key: hk_toggle24)
                    hotkeyRow("Initialise", key: hk_initialise)
                    hotkeyRow("Audio", key: hk_audio)
                    hotkeyRow("Hotkeys", key: hk_hotkeys)
                    hotkeyRow("Quiet", key: hk_quiet)
                    hotkeyRow("Minimise", key: hk_minimise)
                }.frame(height: 200)

            case .quiet:
                Text("Quiet Mode Settings").font(.headline)
                Toggle("Enable Quiet Mode", isOn: $qEnable)
                    .accessibilityHint("Suppresses automatic announcements during the quiet window.")
                VStack(alignment: .leading) {
                    Text("Stop speaking after:").font(.caption)
                    TextField("11:00 pm", text: $qBefore)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Stop speaking after")
                        .accessibilityHint("Enter hh:mm am or pm, or hh:mm for 24-hour time.")
                }
                VStack(alignment: .leading) {
                    Text("Start speaking from:").font(.caption)
                    TextField("08:00 am", text: $qAfter)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Start speaking from")
                        .accessibilityHint("Enter hh:mm am or pm, or hh:mm for 24-hour time.")
                }

            case .audio:
                Text("Audio Output").font(.headline)
                Text("Choose the sound device used for clock announcements.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Picker("Sound device", selection: $selectedDeviceID) {
                    Text("System Default").tag(AudioDeviceID(0))
                    ForEach(outputDevices) { device in
                        Text(device.name).tag(device.id)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Sound device")
                .accessibilityHint("Select the output device for clock announcements.")
            }

            HStack {
                if type == .audio {
                    Button("Cancel") { activeSheet = nil }
                        .keyboardShortcut(.cancelAction)
                }
                Button(type == .audio ? "Apply" : "OK") {
                    if type == .audio { applyOutputDevice(selectedDeviceID) }
                    activeSheet = nil
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding().frame(width: 350)
    }

    func hotkeyRow(_ title: String, key: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(recordingAction == title ? "Press Key…" : "Alt + \(key.uppercased())") {
                recordingAction = title
                announce("Press a key to assign to \(title)")
            }
            .controlSize(.mini)
            .accessibilityLabel("Hotkey for \(title)")
            .accessibilityValue(recordingAction == title ? "Recording" : "Alt \(key.uppercased())")
            .accessibilityHint("Press to record a new keyboard shortcut.")
        }
    }

    func announce(_ message: String) {
        guard let app = NSApp else { return }
        NSAccessibility.post(
            element: app.mainWindow ?? app,
            notification: .announcementRequested,
            userInfo: [
                NSAccessibility.NotificationUserInfoKey.announcement: message,
                NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel.medium.rawValue
            ]
        )
    }
}
