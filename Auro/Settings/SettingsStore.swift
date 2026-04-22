import AppKit
import Foundation
import Combine

// MARK: - SettingsStore

/// Singleton that persists all user preferences to UserDefaults.
/// Observed by SwiftUI views via @EnvironmentObject.
@MainActor
final class SettingsStore: ObservableObject {

    static let shared = SettingsStore()

    // MARK: General
    @Published var launchAtLogin: Bool    = false { didSet { save() } }
    @Published var runInBackground: Bool  = true  { didSet { save() } }
    @Published var hideInDock: Bool       = false { didSet { save() } }
    @Published var theme: AppTheme        = .system { didSet { save(); applyTheme() } }

    // MARK: Device overrides (UID → custom name)
    @Published var deviceNames: [String: String] = [:] { didSet { save() } }

    // MARK: Default effect settings (applied to new apps)
    @Published var defaultEffects: EffectSettings = EffectSettings() { didSet { save() } }

    // MARK: Default device UIDs
    @Published var defaultOutputUID: String = "" { didSet { save() } }
    @Published var defaultInputUID:  String = "" { didSet { save() } }

    // MARK: Saved app settings
    @Published var savedAppSettings: [String: AudioApp] = [:] { didSet { save() } }

    // MARK: Saved routes
    @Published var savedRoutes: [AudioRoute] = [] { didSet { save() } }

    // MARK: Init
    private init() { load() }

    // MARK: Persistence

    private enum Keys {
        static let launchAtLogin    = "launchAtLogin"
        static let runInBackground  = "runInBackground"
        static let hideInDock       = "hideInDock"
        static let theme            = "theme"
        static let deviceNames      = "deviceNames"
        static let defaultEffects   = "defaultEffects"
        static let defaultOutputUID = "defaultOutputUID"
        static let defaultInputUID  = "defaultInputUID"
        static let savedAppSettings = "savedAppSettings"
        static let savedRoutes      = "savedRoutes"
    }

    func save() {
        let ud = UserDefaults.standard
        ud.set(launchAtLogin,   forKey: Keys.launchAtLogin)
        ud.set(runInBackground, forKey: Keys.runInBackground)
        ud.set(hideInDock,      forKey: Keys.hideInDock)
        ud.set(theme.rawValue,  forKey: Keys.theme)
        ud.set(deviceNames,     forKey: Keys.deviceNames)
        ud.set(defaultOutputUID, forKey: Keys.defaultOutputUID)
        ud.set(defaultInputUID,  forKey: Keys.defaultInputUID)

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(defaultEffects) {
            ud.set(data, forKey: Keys.defaultEffects)
        }
        if let data = try? encoder.encode(savedAppSettings) {
            ud.set(data, forKey: Keys.savedAppSettings)
        }
        if let data = try? encoder.encode(savedRoutes) {
            ud.set(data, forKey: Keys.savedRoutes)
        }
    }

    func load() {
        let ud = UserDefaults.standard
        launchAtLogin    = ud.bool(forKey: Keys.launchAtLogin)
        runInBackground  = ud.object(forKey: Keys.runInBackground) as? Bool ?? true
        hideInDock       = ud.bool(forKey: Keys.hideInDock)
        theme            = AppTheme(rawValue: ud.string(forKey: Keys.theme) ?? "") ?? .system
        deviceNames      = ud.dictionary(forKey: Keys.deviceNames) as? [String: String] ?? [:]
        defaultOutputUID = ud.string(forKey: Keys.defaultOutputUID) ?? ""
        defaultInputUID  = ud.string(forKey: Keys.defaultInputUID) ?? ""

        let decoder = JSONDecoder()
        if let data = ud.data(forKey: Keys.defaultEffects),
           let fx = try? decoder.decode(EffectSettings.self, from: data) {
            defaultEffects = fx
        }
        if let data = ud.data(forKey: Keys.savedAppSettings),
           let apps = try? decoder.decode([String: AudioApp].self, from: data) {
            savedAppSettings = apps
        }
        if let data = ud.data(forKey: Keys.savedRoutes),
           let routes = try? decoder.decode([AudioRoute].self, from: data) {
            savedRoutes = routes
        }
    }

    func resetToDefaults() {
        launchAtLogin    = false
        runInBackground  = true
        hideInDock       = false
        theme            = .system
        deviceNames      = [:]
        defaultEffects   = EffectSettings()
        defaultOutputUID = ""
        defaultInputUID  = ""
    }

    // MARK: Theme

    private func applyTheme() {
        switch theme {
        case .light:  NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:   NSApp.appearance = NSAppearance(named: .darkAqua)
        case .system: NSApp.appearance = nil
        }
    }
}

// MARK: - AppTheme

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"
    var id: String { rawValue }
}
