import Foundation

// MARK: - AudioApp

/// Represents a running application that is currently producing or consuming audio.
struct AudioApp: Identifiable, Codable, Hashable {
    var id: UUID
    var bundleID: String
    var name: String
    /// PNG data of the app icon (optional – may be nil for system processes).
    var iconData: Data?
    var pid: Int32
    var volume: Float      // 0.0 – 1.5  (0 = silent, 1 = unity, 1.5 = +50 %)
    var pan: Float         // -1.0 (full-left) … 0.0 (centre) … +1.0 (full-right)
    var isMuted: Bool
    var isSolo: Bool
    var outputDeviceUID: String?   // nil → system default
    var inputDeviceUID: String?    // nil → system default
    var effectsEnabled: Bool
    var effectSettings: EffectSettings
    /// Peak audio level for the level-meter UI (0.0 – 1.0), not persisted.
    var peakLevel: Float = 0

    init(bundleID: String, name: String, pid: Int32) {
        self.id = UUID()
        self.bundleID = bundleID
        self.name = name
        self.pid = pid
        self.volume = 1.0
        self.pan = 0.0
        self.isMuted = false
        self.isSolo = false
        self.effectsEnabled = false
        self.effectSettings = EffectSettings()
    }

    // MARK: Hashable / Equatable (ignore transient peakLevel)
    static func == (lhs: AudioApp, rhs: AudioApp) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: Codable – exclude peakLevel
    enum CodingKeys: String, CodingKey {
        case id, bundleID, name, iconData, pid
        case volume, pan, isMuted, isSolo
        case outputDeviceUID, inputDeviceUID
        case effectsEnabled, effectSettings
    }
}
