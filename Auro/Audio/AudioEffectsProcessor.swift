import Foundation
import AVFoundation
import AudioToolbox

// MARK: - AudioEffectsProcessor

/// Wraps an AVAudioEngine with a chain of effects nodes applied in order:
///   input → gain → EQ → compressor → noise-gate → delay → reverb → pitch → output
///
/// One processor instance is created per AudioApp.
final class AudioEffectsProcessor {

    let engine = AVAudioEngine()

    // Nodes
    private let inputNode: AVAudioMixerNode
    private let gainNode  = AVAudioMixerNode()
    private let eq        = AVAudioUnitEQ(numberOfBands: 8)
    private let reverb    = AVAudioUnitReverb()
    private let delay     = AVAudioUnitDelay()
    private let pitch     = AVAudioUnitTimePitch()
    private let dynamics  = AVAudioUnitEffect(
        audioComponentDescription: AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_DynamicsProcessor,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0, componentFlagsMask: 0))

    private(set) var currentSettings = EffectSettings()

    init() {
        inputNode = engine.mainMixerNode

        // Build graph: inputNode → gainNode → eq → reverb → delay → pitch → output
        engine.attach(gainNode)
        engine.attach(eq)
        engine.attach(reverb)
        engine.attach(delay)
        engine.attach(pitch)
        engine.attach(dynamics)

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(engine.inputNode, to: gainNode,  format: format)
        engine.connect(gainNode,          to: eq,       format: format)
        engine.connect(eq,                to: dynamics, format: format)
        engine.connect(dynamics,          to: reverb,   format: format)
        engine.connect(reverb,            to: delay,    format: format)
        engine.connect(delay,             to: pitch,    format: format)
        engine.connect(pitch,             to: engine.outputNode, format: format)

        do { try engine.start() } catch { print("[AudioEffectsProcessor] Engine start failed: \(error)") }
    }

    // MARK: Apply Settings

    func apply(_ settings: EffectSettings) {
        currentSettings = settings
        applyGain(settings)
        applyEQ(settings)
        applyReverb(settings)
        applyDelay(settings)
        applyPitch(settings)
    }

    // MARK: Private helpers

    private func applyGain(_ s: EffectSettings) {
        let linear = s.gainEnabled ? pow(10.0, s.gainDB / 20.0) : 1.0
        gainNode.outputVolume = Float(linear)
    }

    private func applyEQ(_ s: EffectSettings) {
        guard s.eqEnabled else {
            eq.globalGain = 0
            return
        }
        eq.globalGain = 0
        // AVAudioUnitEQ bands are fixed at init time; map as many as we can
        for (i, band) in s.eqBands.enumerated() {
            guard i < eq.bands.count else { break }
            let b = eq.bands[i]
            b.frequency  = band.frequency
            b.gain       = band.gainDB
            b.bandwidth  = 1.0 / band.q
            b.bypass     = false
            b.filterType = avFilterType(band.type)
        }
        // Bypass unused bands
        for i in s.eqBands.count..<eq.bands.count {
            eq.bands[i].bypass = true
        }
    }

    private func avFilterType(_ type: EQBandType) -> AVAudioUnitEQFilterType {
        switch type {
        case .highPass:  return .highPass
        case .lowShelf:  return .lowShelf
        case .peaking:   return .parametric
        case .highShelf: return .highShelf
        case .lowPass:   return .lowPass
        case .bandPass:  return .bandPass
        case .notch:     return .bandStop
        }
    }

    private func applyReverb(_ s: EffectSettings) {
        reverb.bypass = !s.reverbEnabled
        reverb.wetDryMix = s.reverbMix * 100
        reverb.loadFactoryPreset(reverbPreset(s.reverbRoomSize))
    }

    private func reverbPreset(_ roomSize: Float) -> AVAudioUnitReverbPreset {
        switch roomSize {
        case ..<0.2:  return .smallRoom
        case ..<0.4:  return .mediumRoom
        case ..<0.6:  return .largeRoom
        case ..<0.8:  return .largeHall
        default:      return .cathedral
        }
    }

    private func applyDelay(_ s: EffectSettings) {
        delay.bypass      = !s.delayEnabled
        delay.delayTime   = TimeInterval(s.delayTimeMs / 1000.0)
        delay.feedback    = s.delayFeedback * 100
        delay.wetDryMix   = s.delayMix * 100
    }

    private func applyPitch(_ s: EffectSettings) {
        pitch.bypass = !s.pitchEnabled
        pitch.pitch  = s.pitchSemitones * 100  // cents
    }
}
