// Steve's Talking Clock
// Copyright © 2026 Oliver Fry.
// This code is using the MIT license. This means you can freely use, copy, modify, merge, publish, distribute, sublicense, and even sell the code, even in commercial, closed-source projects, as long as you include the original copyright notice and license text in all copies or substantial portions of the software, otherwise you may receive a DMCA copyright takedown request. Thank you!

import SwiftUI
import AppKit

@main
struct StevesClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // .regular allows the app to have a name in the menu bar and stay in the Dock
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .onAppear {
                    // This ensures the window is captured by the AppDelegate when it opens
                    appDelegate.setupWindowPersistence()
                }
        }
        .windowResizabilityContentSize()
    }
}

// This helper allows us to use the feature only when it's available
extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, *) {
            return self.windowResizability(.contentSize)
        } else {
            return self
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusBarItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Steve's Talking Clock")
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Show Clock", action: #selector(toggleWindow), keyEquivalent: "s"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminate), keyEquivalent: "q"))
            statusBarItem?.menu = menu
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }

    // This is the fix! It finds the window and tells it NOT to delete itself when closed
    func setupWindowPersistence() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" || $0.canBecomeKey }) {
            window.isReleasedWhenClosed = false
            window.delegate = self
        }
    }

    @objc func toggleWindow() {
        NSApp.activate(ignoringOtherApps: true)
        // Look for the window again
        if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
            window.setIsVisible(true) // Force it to be visible even if it was closed
        }
    }
    
    @objc func terminate() {
        NSApplication.shared.terminate(nil)
    }
    
    // This tells macOS NOT to quit the app just because the window is gone
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Steve's Talking Clock
// Copyright © 2026 Oliver Fry.
// This code is using the MIT license. This means you can freely use, copy, modify, merge, publish, distribute, sublicense, and even sell the code, even in commercial, closed-source projects, as long as you include the original copyright notice and license text in all copies or substantial portions of the software, otherwise you may receive a DMCA copyright takedown request. Thank you!
