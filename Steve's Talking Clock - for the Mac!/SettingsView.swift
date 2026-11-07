import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("autoCheckUpdates") private var autoCheckUpdates = true
    @State private var launchAtLogin = false
    @State private var loginItemNeedsApproval = false
    @State private var updateStatus: String = ""

    var body: some View {
        Form {
            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $autoCheckUpdates)
                    .accessibilityHint("Checks GitHub for a newer version when the app launches.")

                HStack {
                    Button("Check for Updates Now…") { checkNow() }
                    Text(updateStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }

                if loginItemNeedsApproval {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("macOS needs your approval to add this app as a login item.")
                                .font(.caption)
                            Button("Open Login Items Settings") {
                                if let url = URL(string:
                                    "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .controlSize(.small)
                        }
                    }
                }
            }

            Section("First-Run Experience") {
                Button("Show Welcome Prompt Again") {
                    UserDefaults.standard.removeObject(forKey: "hasDoneFirstRun")

                    let a = NSAlert()
                    a.messageText = "Welcome prompt reset"
                    if Bundle.main.bundlePath.hasPrefix("/Applications/") {
                        a.informativeText = "The welcome prompt will appear the next time you launch the app."
                    } else {
                        a.informativeText = """
                        You're currently running from:

                        \(Bundle.main.bundlePath)

                        The welcome prompt only appears when running from /Applications. \
                        Install with ./install.sh and launch from there to test.
                        """
                    }
                    a.addButton(withTitle: "OK")
                    a.runModal()
                }
                .accessibilityHint("Resets the first-run flag. The welcome prompt appears on the next launch from /Applications.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
        .onAppear { refreshLoginItemState() }
    }

    // MARK: - Login item

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Login item update failed: \(error)")
        }
        refreshLoginItemState()
    }

    private func refreshLoginItemState() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLogin = true
            loginItemNeedsApproval = false
        case .requiresApproval:
            launchAtLogin = true
            loginItemNeedsApproval = true
        default:
            launchAtLogin = false
            loginItemNeedsApproval = false
        }
    }

    // MARK: - Update check

    private func checkNow() {
        updateStatus = "Checking…"
        guard let url = URL(string:
            "https://api.github.com/repos/olivfry/Steves-Talking-Clock-for-the-Mac-/releases/latest")
        else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tag = json["tag_name"] as? String
                else {
                    updateStatus = "Could not reach GitHub."
                    return
                }
                let latest = tag.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

                if latest.compare(current, options: .numeric) == .orderedDescending {
                    updateStatus = "v\(latest) available."
                    let a = NSAlert()
                    a.messageText = "Update Available — v\(latest)"
                    a.informativeText = "You're on v\(current)."
                    a.addButton(withTitle: "Download")
                    a.addButton(withTitle: "Later")
                    if a.runModal() == .alertFirstButtonReturn,
                       let releases = URL(string:
                        "https://github.com/olivfry/Steves-Talking-Clock-for-the-Mac-/releases") {
                        NSWorkspace.shared.open(releases)
                    }
                } else {
                    updateStatus = "Up to date (v\(current))."
                }
            }
        }.resume()
    }
}
