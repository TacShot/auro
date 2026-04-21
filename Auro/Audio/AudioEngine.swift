import Foundation
import Combine
import CoreAudio

// MARK: - AudioEngine

/// Central observable singleton that owns DeviceManager, AppMonitor and the
/// routing/effects state.  SwiftUI views observe this object.
@MainActor
final class AudioEngine: ObservableObject {

    static let shared = AudioEngine()

    // MARK: Published state
    @Published var devices: [AudioDevice] = []
    @Published var apps: [AudioApp] = []
    @Published var routes: [AudioRoute] = []
    @Published var selectedAppID: UUID?
    @Published var selectedRouteID: UUID?

    // MARK: Sub-systems
    let deviceManager = AudioDeviceManager()
    let appMonitor    = AppAudioMonitor()

    // Per-app effects processors (keyed by AudioApp.id)
    private var effectsProcessors: [UUID: AudioEffectsProcessor] = [:]

    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    private init() {
        // Mirror device manager
        deviceManager.$devices
            .receive(on: RunLoop.main)
            .sink { [weak self] devs in
                self?.devices = devs
            }
            .store(in: &cancellables)

        // Mirror app monitor, preserve per-app settings
        appMonitor.$apps
            .receive(on: RunLoop.main)
            .sink { [weak self] newApps in
                guard let self else { return }
                self.mergeApps(newApps)
            }
            .store(in: &cancellables)
    }

    // MARK: Device helpers

    var outputDevices: [AudioDevice] { devices.filter { $0.isOutput } }
    var inputDevices:  [AudioDevice] { devices.filter { $0.isInput  } }
    var defaultOutput: AudioDevice?  { devices.first { $0.isDefaultOutput } }
    var defaultInput:  AudioDevice?  { devices.first { $0.isDefaultInput  } }

    // MARK: App management

    func updateApp(_ app: AudioApp) {
        if let idx = apps.firstIndex(of: app) {
            apps[idx] = app
            applyEffectsIfNeeded(app)
        }
    }

    func setAppVolume(_ volume: Float, app: AudioApp) {
        if let idx = apps.firstIndex(of: app) {
            apps[idx].volume = max(0, min(1.5, volume))
        }
    }

    func setAppMute(_ muted: Bool, app: AudioApp) {
        if let idx = apps.firstIndex(of: app) {
            apps[idx].isMuted = muted
        }
    }

    func setAppSolo(_ solo: Bool, app: AudioApp) {
        // Toggle solo: unmute all others when turning off solo
        for i in apps.indices {
            if apps[i].id == app.id {
                apps[i].isSolo = solo
            } else if solo {
                apps[i].isSolo = false
            }
        }
    }

    // MARK: Route management

    func addRoute(sourceID: String, destinationUID: String) {
        let route = AudioRoute(sourceID: sourceID, destinationUID: destinationUID)
        routes.append(route)
    }

    func removeRoute(_ route: AudioRoute) {
        routes.removeAll { $0.id == route.id }
    }

    func updateRoute(_ route: AudioRoute) {
        if let idx = routes.firstIndex(of: route) {
            routes[idx] = route
        }
    }

    // MARK: Effects

    func applyEffects(_ settings: EffectSettings, to app: AudioApp) {
        if let idx = apps.firstIndex(of: app) {
            apps[idx].effectSettings = settings
            applyEffectsIfNeeded(apps[idx])
        }
    }

    private func applyEffectsIfNeeded(_ app: AudioApp) {
        guard app.effectsEnabled else { return }
        let processor = effectsProcessors[app.id] ?? {
            let p = AudioEffectsProcessor()
            effectsProcessors[app.id] = p
            return p
        }()
        processor.apply(app.effectSettings)
    }

    // MARK: Private helpers

    private func mergeApps(_ newApps: [AudioApp]) {
        var merged: [AudioApp] = []
        for new in newApps {
            if let existing = apps.first(where: { $0.bundleID == new.bundleID }) {
                var kept = existing
                kept.pid = new.pid
                kept.peakLevel = new.peakLevel
                if kept.iconData == nil { kept.iconData = new.iconData }
                merged.append(kept)
            } else {
                merged.append(new)
            }
        }
        apps = merged
    }
}
