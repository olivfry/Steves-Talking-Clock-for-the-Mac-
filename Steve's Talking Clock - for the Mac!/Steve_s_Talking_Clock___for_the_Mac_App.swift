// Steve's Talking Clock for the Mac
// Copyright © 2026 Oliver Fry.
// MIT licensed — see LICENSE for details.

import SwiftUI
import AppKit

@main
struct StevesClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .onAppear { appDelegate.setupWindowPersistence() }
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusBarItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "clock",
                                   accessibilityDescription: "Steve's Talking Clock")
            let menu = NSMenu()
            let showItem = NSMenuItem(title: "Show Clock",
                                      action: #selector(toggleWindow),
                                      keyEquivalent: "s")
            showItem.keyEquivalentModifierMask = [.option]
            menu.addItem(showItem)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit",
                                    action: #selector(terminate),
                                    keyEquivalent: "q"))
            statusBarItem?.menu = menu
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func setupWindowPersistence() {
        if let window = mainWindow() {
            window.isReleasedWhenClosed = false
            window.delegate = self
        }
    }

    private func mainWindow() -> NSWindow? {
        NSApp.windows.first { $0.identifier?.rawValue == "main" }
            ?? NSApp.windows.first { $0.canBecomeKey }
    }

    @objc func toggleWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = mainWindow() {
            window.makeKeyAndOrderFront(nil)
            window.setIsVisible(true)
        }
    }

    @objc func terminate() { NSApplication.shared.terminate(nil) }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}
