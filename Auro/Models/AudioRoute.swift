import Foundation

// MARK: - AudioRoute

/// Describes a routing connection between a source (app or device) and an output device.
struct AudioRoute: Identifiable, Codable, Hashable {
    var id: UUID
    /// Either an app `bundleID` or an input device `uid`.
    var sourceID: String
    /// UID of the destination output device.
    var destinationUID: String
    var volume: Float     // 0.0 – 1.0
    var isActive: Bool
    var effectSettings: EffectSettings

    init(sourceID: String, destinationUID: String) {
        self.id = UUID()
        self.sourceID = sourceID
        self.destinationUID = destinationUID
        self.volume = 1.0
        self.isActive = true
        self.effectSettings = EffectSettings()
    }

    // MARK: Hashable
    static func == (lhs: AudioRoute, rhs: AudioRoute) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
