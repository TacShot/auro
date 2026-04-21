import AppKit
import SwiftUI

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var popover = NSPopover()
    private var aboutWindow: NSWindow?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        applyThemeOnLaunch()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in background when windows are closed if user chose that option
        return !SettingsStore.shared.runInBackground
    }

    // MARK: Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem?.button {
            btn.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Auro")
            btn.image?.isTemplate = true
            btn.action = #selector(togglePopover(_:))
            btn.target = self
        }

        popover.contentSize = NSSize(width: 300, height: 360)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(SettingsStore.shared)
                .environmentObject(AudioEngine.shared)
        )
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let btn = statusItem?.button {
                popover.show(relativeTo: btn.bounds, of: btn, preferredEdge: .minY)
            }
        }
    }

    // MARK: About

    func showAbout() {
        if aboutWindow == nil {
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 240),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = "About Auro"
            aboutWindow?.contentView = NSHostingView(rootView: AboutView())
            aboutWindow?.center()
            aboutWindow?.isReleasedWhenClosed = false
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: Theme

    private func applyThemeOnLaunch() {
        switch SettingsStore.shared.theme {
        case .light:  NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:   NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system: NSApp.appearance = nil
        }
    }
}

// MARK: - AboutView

private struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 72, height: 72)
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("Auro")
                .font(.largeTitle.bold())
            Text("Version 1.0.0 (1)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Audio routing, mixing and effects for macOS.")
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal)
            Text("© 2024 TacShot. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 340, height: 240)
    }
}
