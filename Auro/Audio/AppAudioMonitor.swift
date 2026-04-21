import Foundation
import AppKit

// MARK: - AppAudioMonitor

/// Monitors which NSRunningApplications are active.
/// On macOS 14.2+ a CoreAudio Process Tap approach would be used; here we poll
/// NSRunningApplication to build an AudioApp list that the UI can display.
@MainActor
final class AppAudioMonitor: ObservableObject {

    @Published var apps: [AudioApp] = []

    /// Previously-saved per-app settings (persisted between launches)
    var savedSettings: [String: AudioApp] = [:]

    private var timer: Timer?

    init() { start() }
    deinit { timer?.invalidate() }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        refresh()
    }

    func stop() { timer?.invalidate(); timer = nil }

    // MARK: Private

    private func refresh() {
        let running = NSWorkspace.shared.runningApplications
        var updated: [AudioApp] = []

        for app in running {
            guard let bundle = app.bundleIdentifier,
                  let name   = app.localizedName,
                  app.activationPolicy == .regular
            else { continue }

            if var existing = apps.first(where: { $0.bundleID == bundle }) {
                existing.pid = app.processIdentifier
                updated.append(existing)
            } else if let saved = savedSettings[bundle] {
                var a = saved
                a.pid = app.processIdentifier
                updated.append(a)
            } else {
                var a = AudioApp(bundleID: bundle, name: name, pid: app.processIdentifier)
                if let icon = app.icon {
                    a.iconData = icon.tiffRepresentation
                }
                updated.append(a)
            }
        }

        // Simulate level meters with random values for UI demonstration
        for i in updated.indices {
            updated[i].peakLevel = updated[i].isMuted ? 0 : Float.random(in: 0.1...0.9)
        }

        apps = updated
    }
}
