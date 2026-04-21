import Foundation
import CoreAudio

// MARK: - AudioDevice

/// Represents a physical or virtual audio device discovered via CoreAudio.
struct AudioDevice: Identifiable, Codable, Hashable {
    var id: AudioDeviceID        // CoreAudio numeric ID
    var uid: String              // Persistent UID (kAudioDevicePropertyDeviceUID)
    var name: String             // Factory name
    var customName: String?      // User-assigned name override
    var isInput: Bool
    var isOutput: Bool
    var inputChannelCount: Int
    var outputChannelCount: Int
    var sampleRate: Double
    var isDefaultInput: Bool
    var isDefaultOutput: Bool
    var volume: Float            // 0.0 – 1.0  (master output volume)
    var isMuted: Bool

    /// The name shown in the UI (custom if set, else factory name).
    var displayName: String { customName ?? name }

    init(
        id: AudioDeviceID,
        uid: String,
        name: String,
        customName: String? = nil,
        isInput: Bool,
        isOutput: Bool,
        inputChannelCount: Int,
        outputChannelCount: Int,
        sampleRate: Double,
        isDefaultInput: Bool = false,
        isDefaultOutput: Bool = false,
        volume: Float = 1.0,
        isMuted: Bool = false
    ) {
        self.id = id
        self.uid = uid
        self.name = name
        self.customName = customName
        self.isInput = isInput
        self.isOutput = isOutput
        self.inputChannelCount = inputChannelCount
        self.outputChannelCount = outputChannelCount
        self.sampleRate = sampleRate
        self.isDefaultInput = isDefaultInput
        self.isDefaultOutput = isDefaultOutput
        self.volume = volume
        self.isMuted = isMuted
    }
}
