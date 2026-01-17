// Steve's Talking Clock
// Copyright © 2026 Oliver Fry.
// This code is using the MIT license. This means you can freely use, copy, modify, merge, publish, distribute, sublicense, and even sell the code, even in commercial, closed-source projects, as long as you include the original copyright notice and license text in all copies or substantial portions of the software, otherwise you may receive a DMCA copyright takedown request. Thank you!

import SwiftUI
import AppKit

@main
struct StevesClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Keeps the app visible in the Dock and Menu Bar
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .onAppear {
                    appDelegate.setupWindowPersistence()
                }
        }
        .windowResizabilityContentSize()
    }
}

// Helper for window sizing compatibility
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
        // Setup the Menu Bar / Status Bar Item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Steve's Talking Clock")
            let menu = NSMenu()
            
            // "Show Clock" remains, but we use Command+S as a shortcut instead of space
            let showItem = NSMenuItem(title: "Show Clock", action: #selector(toggleWindow), keyEquivalent: "s")
            showItem.keyEquivalentModifierMask = [.command]
            menu.addItem(showItem)
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminate), keyEquivalent: "q"))
            statusBarItem?.menu = menu
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }

    // Fix: Ensures the window is just hidden, not destroyed, when closed
    func setupWindowPersistence() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" || $0.canBecomeKey }) {
            window.isReleasedWhenClosed = false
            window.delegate = self
        }
    }

    @objc func toggleWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.setIsVisible(true)
        }
    }
    
    @objc func terminate() {
        NSApplication.shared.terminate(nil)
    }
    
    // Keeps the timer running even if the window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Steve's Talking Clock
// Copyright © 2026 Oliver Fry.
// This code is using the MIT license. This means you can freely use, copy, modify, merge, publish, distribute, sublicense, and even sell the code, even in commercial, closed-source projects, as long as you include the original copyright notice and license text in all copies or substantial portions of the software, otherwise you may receive a DMCA copyright takedown request. Thank you!
