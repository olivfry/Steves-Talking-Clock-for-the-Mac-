// Steve's Talking Clock
// Copyright © 2026 Oliver Fry.
// This code is using the MIT license. This means you can freely use, copy, modify, merge, publish, distribute, sublicense, and even sell the code, even in commercial, closed-source projects, as long as you include the original copyright notice and license text in all copies or substantial portions of the software, otherwise you may receive a DMCA copyright takedown request. Thank you!

import SwiftUI
import AVFoundation
import AVKit
import Combine

struct ContentView: View {
    @AppStorage("mainVoice") private var mainVoice = "Default"
    @AppStorage("quarterVoice") private var quarterVoice = "None"
    @AppStorage("halfVoice") private var halfVoice = "None"
    @AppStorage("threeQuarterVoice") private var threeQuarterVoice = "None"
    @AppStorage("hourVoice") private var hourVoice = "None"
    @AppStorage("alarmVoice") private var alarmVoice = "None"
    @AppStorage("hour24Mode") private var hour24Mode = false
    @AppStorage("alarmTime") private var alarmTime = "08:00 am"
    @AppStorage("gapDuration") private var gapDuration: Double = 0.03
    
    @AppStorage("qEnable") private var qEnable = false
    @AppStorage("qBefore") private var qBefore = "11:00 pm" // Stop speaking after
    @AppStorage("qAfter") private var qAfter = "08:00 am"  // Start speaking from
    
    @AppStorage("hk_sayTime") private var hk_sayTime = "t"
    @AppStorage("hk_toggle24") private var hk_toggle24 = "h"
    @AppStorage("hk_initialise") private var hk_initialise = "i"
    @AppStorage("hk_audio") private var hk_audio = "u"
    @AppStorage("hk_hotkeys") private var hk_hotkeys = "k"
    @AppStorage("hk_quiet") private var hk_quiet = "q"
    @AppStorage("hk_minimise") private var hk_minimise = "m"

    @State private var voices: [String: URL] = [:]
    @State private var voiceNames: [String] = ["None", "Default"]
    @State private var activeSheet: Sheet?
    @State private var recordingAction: String? = nil
    @State private var engine = AVAudioEngine()
    @State private var sourceNode: AVAudioSourceNode?
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var lastAnnouncedMinute: Int = -1

    enum Sheet: Identifiable { case audio, hotkeys, quiet; var id: Int { hashValue } }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                voicePicker("Main Voice List", selection: $mainVoice)
                voicePicker("Quarter Hour Voice List", selection: $quarterVoice)
                voicePicker("Half Hour Voice List", selection: $halfVoice)
                voicePicker("Three Quarter Hour Voice List", selection: $threeQuarterVoice)
                voicePicker("On the Hour Voice List", selection: $hourVoice)
                voicePicker("Alarm Voice List", selection: $alarmVoice)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gap Delay: \(String(format: "%.3f", gapDuration))s")
                        .font(.system(size: 9, weight: .bold))
                    Slider(value: $gapDuration, in: 0.00...0.20).controlSize(.mini)
                }
                
                HStack {
                    Text("Alarm:").font(.system(size: 9, weight: .bold))
                    TextField("hh:mm am", text: $alarmTime).textFieldStyle(.roundedBorder).font(.system(size: 9))
                }
                Toggle("24 Hour Mode", isOn: $hour24Mode).font(.caption)
                Spacer().frame(height: 8)
            }
            .frame(width: 200).padding(.trailing, 12)

            VStack(spacing: 20) {
                Button("Say Time") {
                    // Manual override: bypassQuietMode is true
                    startSpeak(mainVoice, bypassQuietMode: true)
                    }
                    .keyboardShortcut("t", modifiers: [.option])
                    .focusable(false)
                
                Button("Initialise") { refresh(); NSSound.beep() }.focusable(false)
                Button("Open Voices Folder") { revealVoicesFolder() }.focusable(false)
                Button("Save Settings") { NSSound.beep() }.focusable(false)
                AirPlayView().frame(width: 120, height: 30)
                Button("Hotkeys...") { activeSheet = .hotkeys }.focusable(false)
                Button("Quiet Mode...") { activeSheet = .quiet }.focusable(false)
                Button("Minimise") { NSApp.hide(nil) }
                    .keyboardShortcut("m", modifiers: [.option])
                    .focusable(false)
            }
            .buttonStyle(.bordered).controlSize(.small).frame(width: 120)
        }
        .padding().frame(width: 350, height: 400)
        .onAppear { setupEngine(); refresh(); setupHotkeyMonitor() }
        .sheet(item: $activeSheet) { item in sheetView(for: item) }
        .onReceive(timer) { _ in
            checkAutoAnnounce()
        }
    }

    func checkAutoAnnounce() {
        let components = Calendar.current.dateComponents([.minute], from: Date())
        guard let minute = components.minute else { return }
        let isQuarterHour = (minute == 0 || minute == 15 || minute == 30 || minute == 45)
        
        if isQuarterHour && minute != lastAnnouncedMinute {
            lastAnnouncedMinute = minute
            var selectedVoice = "None"
            switch minute {
            case 0: selectedVoice = hourVoice
            case 15: selectedVoice = quarterVoice
            case 30: selectedVoice = halfVoice
            case 45: selectedVoice = threeQuarterVoice
            default: break
            }
            if selectedVoice == "None" { selectedVoice = mainVoice }
            if selectedVoice != "None" {
                // Auto announcements respect Quiet Mode
                startSpeak(selectedVoice, bypassQuietMode: false)
            }
        }
    }

    func getExternalVoicesURL() -> URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = paths[0].appendingPathComponent("StevesTalkingClock/Voices")
        if !FileManager.default.fileExists(atPath: appSupportURL.path) {
            try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }
        return appSupportURL
    }

    func revealVoicesFolder() {
        let url = getExternalVoicesURL()
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }

    func refresh() {
        var foundVoices: [String: URL] = [:]
        if let p = Bundle.main.resourcePath, let items = try? FileManager.default.contentsOfDirectory(atPath: p) {
            for item in items where !item.contains(".") {
                foundVoices[item] = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(item)")
            }
        }
        let externalURL = getExternalVoicesURL()
        if let items = try? FileManager.default.contentsOfDirectory(atPath: externalURL.path) {
            for item in items where !item.contains(".") {
                foundVoices[item] = externalURL.appendingPathComponent(item)
            }
        }
        self.voices = foundVoices
        var names = Array(foundVoices.keys).sorted()
        if !names.contains("Default") { names.insert("Default", at: 0) }
        if !names.contains("None") { names.insert("None", at: 0) }
        self.voiceNames = names
    }

    func setupEngine() { _ = engine.mainMixerNode; try? engine.start() }

    // Logic updated to allow manual override
    func startSpeak(_ voice: String, bypassQuietMode: Bool = false) {
        if voice == "None" { return }
        if !bypassQuietMode && checkQuietMode() { return }
        
        let cal = Calendar.current
        let now = Date()
        var h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        let isPm = h >= 12
        if !hour24Mode { h = (h % 12 == 0) ? 12 : h % 12 }
        var words = ["its.wav", "\(h).wav"]
        if m == 0 { words.append("oclock.wav") }
        else if m < 10 { words += ["o.wav", "\(m).wav"] }
        else if m < 20 { words.append("\(m).wav") }
        else {
            words.append("\((m/10)*10).wav"); if m % 10 > 0 { words.append("\(m%10).wav") }
        }
        if !hour24Mode { words.append(isPm ? "pm.wav" : "am.wav") }
        playUsingSourceNode(files: words, voiceName: voice)
    }

    func playUsingSourceNode(files: [String], voiceName: String) {
        if let oldNode = sourceNode { engine.detach(oldNode) }
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        var allData: [Float] = []
        let gapSamples = Int(gapDuration * outputFormat.sampleRate)
        guard let voiceURL = voices[voiceName] else { return }
        for fileName in files {
            let fileURL = voiceURL.appendingPathComponent(fileName)
            guard let file = try? AVAudioFile(forReading: fileURL) else { continue }
            let frameCount = AVAudioFrameCount(file.length)
            let inputBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount)!
            try? file.read(into: inputBuffer)
            let converter = AVAudioConverter(from: file.processingFormat, to: outputFormat)!
            let ratio = file.processingFormat.sampleRate / outputFormat.sampleRate
            let convertedFrameCount = AVAudioFrameCount(Double(frameCount) / ratio)
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: convertedFrameCount)!
            var error: NSError?
            converter.convert(to: outputBuffer, error: &error) { _, outStatus in outStatus.pointee = .haveData; return inputBuffer }
            if let channelData = outputBuffer.floatChannelData?[0] {
                for i in 0..<Int(outputBuffer.frameLength) { allData.append(channelData[i]) }
            }
            allData.append(contentsOf: Array(repeating: 0, count: gapSamples))
        }
        allData.append(contentsOf: Array(repeating: 0, count: Int(1.0 * outputFormat.sampleRate)))
        var currentFrame = 0
        let totalFrames = allData.count
        sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sample = currentFrame < totalFrames ? allData[currentFrame] : 0
                for buffer in abl { buffer.mData!.assumingMemoryBound(to: Float.self)[frame] = sample }
                currentFrame += 1
            }
            return noErr
        }
        if let node = sourceNode { engine.attach(node); engine.connect(node, to: engine.mainMixerNode, format: outputFormat) }
    }

    // Fixed comparison logic
    func checkQuietMode() -> Bool {
        guard qEnable else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Convert current time to total minutes
        let currentHour = calendar.component(.hour, from: now)
        let currentMin = calendar.component(.minute, from: now)
        let nowMinutes = currentHour * 60 + currentMin
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        
        // Helper to convert "hh:mm a" to total minutes from midnight
        func timeToMinutes(_ timeStr: String) -> Int? {
            guard let date = formatter.date(from: timeStr) else { return nil }
            let h = calendar.component(.hour, from: date)
            let m = calendar.component(.minute, from: date)
            return h * 60 + m
        }
        
        guard let stopMins = timeToMinutes(qBefore), let startMins = timeToMinutes(qAfter) else { return false }
        
        if stopMins < startMins {
            // daytime quiet (e.g., 9am to 5pm)
            return nowMinutes >= stopMins && nowMinutes < startMins
        } else {
            // overnight quiet (e.g., 11pm to 8am)
            return nowMinutes >= stopMins || nowMinutes < startMins
        }
    }

    func setupHotkeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if let action = recordingAction {
                let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
                saveHotkey(action: action, key: key)
                recordingAction = nil
                return nil
            }
            let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
            if event.modifierFlags.contains(.option) {
                switch key {
                // Hotkeys also override Quiet Mode
                case hk_sayTime: startSpeak(mainVoice, bypassQuietMode: true); return nil
                case hk_toggle24: hour24Mode.toggle(); return nil
                case hk_initialise: refresh(); return nil
                case hk_audio: activeSheet = .audio; return nil
                case hk_hotkeys: activeSheet = .hotkeys; return nil
                case hk_quiet: activeSheet = .quiet; return nil
                case hk_minimise: NSApp.hide(nil); return nil
                default: break
                }
            }
            return event
        }
    }

    func saveHotkey(action: String, key: String) {
        switch action {
        case "Say Time": hk_sayTime = key
        case "24 Hour Mode": hk_toggle24 = key
        case "Initialise": hk_initialise = key
        case "Audio": hk_audio = key
        case "Hotkeys": hk_hotkeys = key
        case "Quiet": hk_quiet = key
        case "Minimise": hk_minimise = key
        default: break
        }
    }

    func voicePicker(_ l: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(l).font(.system(size: 9, weight: .bold))
            Picker("", selection: selection) { ForEach(voiceNames, id: \.self) { Text($0).tag($0) } }.labelsHidden().controlSize(.small)
        }
    }

    @ViewBuilder
    func sheetView(for type: Sheet) -> some View {
        VStack(spacing: 15) {
            if type == .hotkeys {
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
            } else if type == .quiet {
                Text("Quiet Mode Settings").font(.headline)
                Toggle("Enable Quiet Mode", isOn: $qEnable)
                VStack(alignment: .leading) {
                    Text("Stop speaking after:").font(.caption)
                    TextField("11:00 pm", text: $qBefore).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading) {
                    Text("Start speaking from:").font(.caption)
                    TextField("08:00 am", text: $qAfter).textFieldStyle(.roundedBorder)
                }
            }
            Button("OK") { activeSheet = nil }.buttonStyle(.borderedProminent)
        }.padding().frame(width: 350)
    }

    func hotkeyRow(_ title: String, key: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(recordingAction == title ? "Press Key..." : "Alt + \(key.uppercased())") { recordingAction = title }.controlSize(.mini)
        }
    }
}

struct AirPlayView: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView { AVRoutePickerView() }
    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}

// Steve's Talking Clock
// Copyright © 2026 Oliver Fry.
// This code is using the MIT license. This means you can freely use, copy, modify, merge, publish, distribute, sublicense, and even sell the code, even in commercial, closed-source projects, as long as you include the original copyright notice and license text in all copies or substantial portions of the software, otherwise you may receive a DMCA copyright takedown request. Thank you!
