import XCTest
@testable import Auro

// Tests for AudioEffectsProcessor.apply() – only the pure Swift logic (settings
// applied to nodes) is verified.  AVAudioEngine start requires an audio device,
// so we skip engine-running assertions and focus on the settings routing.
final class AudioEffectsProcessorTests: XCTestCase {

    var processor: AudioEffectsProcessor!

    override func setUp() {
        super.setUp()
        processor = AudioEffectsProcessor()
    }

    // MARK: - apply stores current settings

    func testApplyStoresSettings() {
        var settings = EffectSettings()
        settings.gainEnabled = true
        settings.gainDB = 3.0
        processor.apply(settings)
        XCTAssertEqual(processor.currentSettings.gainDB, 3.0, accuracy: 0.001)
        XCTAssertTrue(processor.currentSettings.gainEnabled)
    }

    func testApplyMultipleTimesTakesLatest() {
        var s1 = EffectSettings()
        s1.pitchEnabled = true
        s1.pitchSemitones = 2
        processor.apply(s1)

        var s2 = EffectSettings()
        s2.pitchEnabled = false
        s2.pitchSemitones = -4
        processor.apply(s2)

        XCTAssertFalse(processor.currentSettings.pitchEnabled)
        XCTAssertEqual(processor.currentSettings.pitchSemitones, -4, accuracy: 0.001)
    }

    // MARK: - Reverb preset logic (tested via EffectSettings values)

    func testReverbSettingsStoredCorrectly() {
        var settings = EffectSettings()
        settings.reverbEnabled = true
        settings.reverbRoomSize = 0.9
        settings.reverbMix = 0.5
        processor.apply(settings)
        XCTAssertTrue(processor.currentSettings.reverbEnabled)
        XCTAssertEqual(processor.currentSettings.reverbRoomSize, 0.9, accuracy: 0.001)
        XCTAssertEqual(processor.currentSettings.reverbMix, 0.5, accuracy: 0.001)
    }

    // MARK: - Delay settings

    func testDelaySettingsStoredCorrectly() {
        var settings = EffectSettings()
        settings.delayEnabled = true
        settings.delayTimeMs = 300
        settings.delayFeedback = 0.6
        settings.delayMix = 0.4
        processor.apply(settings)
        XCTAssertTrue(processor.currentSettings.delayEnabled)
        XCTAssertEqual(processor.currentSettings.delayTimeMs, 300, accuracy: 0.001)
        XCTAssertEqual(processor.currentSettings.delayFeedback, 0.6, accuracy: 0.001)
    }

    // MARK: - EQ settings

    func testEQSettingsStoredCorrectly() {
        var settings = EffectSettings()
        settings.eqEnabled = true
        settings.eqBandCount = 8
        settings.eqBands[0].gainDB = 6.0
        processor.apply(settings)
        XCTAssertTrue(processor.currentSettings.eqEnabled)
        XCTAssertEqual(processor.currentSettings.eqBands[0].gainDB, 6.0, accuracy: 0.001)
    }

    // MARK: - Pitch settings

    func testPitchSettingsStoredCorrectly() {
        var settings = EffectSettings()
        settings.pitchEnabled = true
        settings.pitchSemitones = -12
        processor.apply(settings)
        XCTAssertTrue(processor.currentSettings.pitchEnabled)
        XCTAssertEqual(processor.currentSettings.pitchSemitones, -12, accuracy: 0.001)
    }

    // MARK: - Default settings produce no-op

    func testApplyDefaultSettingsDoesNotEnableEffects() {
        let settings = EffectSettings()
        processor.apply(settings)
        XCTAssertFalse(processor.currentSettings.gainEnabled)
        XCTAssertFalse(processor.currentSettings.eqEnabled)
        XCTAssertFalse(processor.currentSettings.reverbEnabled)
        XCTAssertFalse(processor.currentSettings.delayEnabled)
        XCTAssertFalse(processor.currentSettings.pitchEnabled)
    }
}
