// Steve's Talking Clock
// Copyright © 2026 Oliver Fry.
// This code is using the MIT license. This means you can freely use, copy, modify, merge, publish, distribute, sublicense, and even sell the code, even in commercial, closed-source projects, as long as you include the original copyright notice and license text in all copies or substantial portions of the software, otherwise you may receive a DMCA copyright takedown request. Thank you!
import SwiftUI

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
                    appDelegate.setupWindowPersistence()
                }
        }
        // This checks if the Mac running the app is on macOS 13 or newer
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
            // Updated to Alt (Option) + S
            let showItem = NSMenuItem(title: "Show Clock", action: #selector(toggleWindow), keyEquivalent: "s")
            showItem.keyEquivalentModifierMask = [.option]
            menu.addItem(showItem)
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminate), keyEquivalent: "q"))
            statusBarItem?.menu = menu
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setupWindowPersistence() {
        if let window = NSApp.windows.first(where: { $0.canBecomeKey }) {
            window.isReleasedWhenClosed = false
            window.delegate = self
            // Fix: Prevents Space bar from acting as a "click" on the default button
            window.defaultButtonCell = nil
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
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
// Steve's Talking Clock
// Copyright © 2026 Oliver Fry.
// This code is using the MIT license. This means you can freely use, copy, modify, merge, publish, distribute, sublicense, and even sell the code, even in commercial, closed-source projects, as long as you include the original copyright notice and license text in all copies or substantial portions of the software, otherwise you may receive a DMCA copyright takedown request. Thank you!
