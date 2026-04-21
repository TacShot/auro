import Foundation

// MARK: - EffectSettings

/// Full set of audio-effect parameters for one audio channel/app.
struct EffectSettings: Codable, Hashable {

    // MARK: EQ
    var eqEnabled: Bool = false
    var eqBandCount: Int = 8        // 4 | 8 | 16 | 32 | 64
    var eqBands: [EQBand] = EQBand.defaultBands(count: 8)

    // MARK: Gain
    var gainEnabled: Bool = false
    var gainDB: Float = 0           // -24 … +24 dB

    // MARK: Noise Gate
    var noiseGateEnabled: Bool = false
    var noiseGateThresholdDB: Float = -60   // -96 … 0 dB
    var noiseGateAttackMs: Float = 5        // 0.1 … 200 ms
    var noiseGateReleaseMs: Float = 100     // 1 … 2000 ms

    // MARK: Noise Suppressor
    var noiseSuppressEnabled: Bool = false
    var noiseSuppressStrength: Float = 0.5  // 0 … 1

    // MARK: Compressor
    var compressorEnabled: Bool = false
    var compressorThresholdDB: Float = -20
    var compressorRatio: Float = 4          // 1 … 40
    var compressorAttackMs: Float = 10
    var compressorReleaseMs: Float = 100

    // MARK: Delay
    var delayEnabled: Bool = false
    var delayTimeMs: Float = 250    // 0 … 2000 ms
    var delayFeedback: Float = 0.3  // 0 … 1
    var delayMix: Float = 0.3       // 0 … 1

    // MARK: Reverb
    var reverbEnabled: Bool = false
    var reverbRoomSize: Float = 0.5  // 0 … 1
    var reverbDamping: Float = 0.5
    var reverbMix: Float = 0.25      // 0 … 1

    // MARK: Pitch Shift
    var pitchEnabled: Bool = false
    var pitchSemitones: Float = 0    // -24 … +24

    // MARK: Harmonize
    var harmonizeEnabled: Bool = false
    var harmonizeInterval: Int = 5   // semitones
    var harmonizeMix: Float = 0.5

    // MARK: Modulation
    var modulationEnabled: Bool = false
    var modulationType: ModulationType = .chorus
    var modulationRate: Float = 1.0   // Hz
    var modulationDepth: Float = 0.5  // 0 … 1
}

// MARK: - EQBand

struct EQBand: Codable, Hashable, Identifiable {
    var id: Int            // band index
    var frequency: Float   // Hz  (20 … 20000)
    var gainDB: Float      // -24 … +24
    var q: Float           // 0.1 … 10
    var type: EQBandType

    static func defaultBands(count: Int) -> [EQBand] {
        let freqs: [Float] = [
            32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000,
            20, 40, 80, 160, 315, 630, 1250, 2500, 5000, 10000,
            22, 45, 90, 180, 360, 720, 1440, 2880, 5760, 11520,
            30, 60, 120, 240, 480, 960, 1920, 3840, 7680, 15360,
            25, 50, 100, 200, 400, 800, 1600, 3200, 6400, 12800,
            28, 56, 112, 224, 448, 896, 1792, 3584, 7168, 14336,
            18, 36, 72, 144
        ]
        return (0..<count).map { i in
            EQBand(
                id: i,
                frequency: i < freqs.count ? freqs[i] : Float(1000 * (i + 1)),
                gainDB: 0,
                q: 1.0,
                type: i == 0 ? .highPass : i == count - 1 ? .lowPass : .peaking
            )
        }
    }
}

// MARK: - Enums

enum EQBandType: String, Codable, CaseIterable {
    case highPass   = "High Pass"
    case lowShelf   = "Low Shelf"
    case peaking    = "Peaking"
    case highShelf  = "High Shelf"
    case lowPass    = "Low Pass"
    case bandPass   = "Band Pass"
    case notch      = "Notch"
}

enum ModulationType: String, Codable, CaseIterable {
    case chorus   = "Chorus"
    case flanger  = "Flanger"
    case tremolo  = "Tremolo"
    case vibrato  = "Vibrato"
}
