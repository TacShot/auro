import XCTest
@testable import Auro

final class EffectSettingsTests: XCTestCase {

    // MARK: - Defaults

    func testDefaultValues() {
        let fx = EffectSettings()
        XCTAssertFalse(fx.eqEnabled)
        XCTAssertEqual(fx.eqBandCount, 8)
        XCTAssertEqual(fx.eqBands.count, 8)
        XCTAssertFalse(fx.gainEnabled)
        XCTAssertEqual(fx.gainDB, 0)
        XCTAssertFalse(fx.noiseGateEnabled)
        XCTAssertEqual(fx.noiseGateThresholdDB, -60)
        XCTAssertFalse(fx.noiseSuppressEnabled)
        XCTAssertEqual(fx.noiseSuppressStrength, 0.5)
        XCTAssertFalse(fx.compressorEnabled)
        XCTAssertEqual(fx.compressorRatio, 4)
        XCTAssertFalse(fx.delayEnabled)
        XCTAssertEqual(fx.delayTimeMs, 250)
        XCTAssertFalse(fx.reverbEnabled)
        XCTAssertEqual(fx.reverbRoomSize, 0.5)
        XCTAssertFalse(fx.pitchEnabled)
        XCTAssertEqual(fx.pitchSemitones, 0)
        XCTAssertFalse(fx.harmonizeEnabled)
        XCTAssertFalse(fx.modulationEnabled)
        XCTAssertEqual(fx.modulationType, .chorus)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        var fx = EffectSettings()
        fx.eqEnabled = true
        fx.gainEnabled = true
        fx.gainDB = 6.0
        fx.reverbEnabled = true
        fx.reverbMix = 0.4
        fx.delayEnabled = true
        fx.delayTimeMs = 500
        fx.pitchEnabled = true
        fx.pitchSemitones = 3
        fx.modulationEnabled = true
        fx.modulationType = .flanger

        let data = try JSONEncoder().encode(fx)
        let decoded = try JSONDecoder().decode(EffectSettings.self, from: data)

        XCTAssertEqual(decoded.eqEnabled, fx.eqEnabled)
        XCTAssertEqual(decoded.gainEnabled, fx.gainEnabled)
        XCTAssertEqual(decoded.gainDB, fx.gainDB)
        XCTAssertEqual(decoded.reverbEnabled, fx.reverbEnabled)
        XCTAssertEqual(decoded.reverbMix, fx.reverbMix)
        XCTAssertEqual(decoded.delayEnabled, fx.delayEnabled)
        XCTAssertEqual(decoded.delayTimeMs, fx.delayTimeMs)
        XCTAssertEqual(decoded.pitchEnabled, fx.pitchEnabled)
        XCTAssertEqual(decoded.pitchSemitones, fx.pitchSemitones)
        XCTAssertEqual(decoded.modulationEnabled, fx.modulationEnabled)
        XCTAssertEqual(decoded.modulationType, fx.modulationType)
    }

    // MARK: - EQBand

    func testDefaultBandsCount8() {
        let bands = EQBand.defaultBands(count: 8)
        XCTAssertEqual(bands.count, 8)
    }

    func testDefaultBandsCount16() {
        let bands = EQBand.defaultBands(count: 16)
        XCTAssertEqual(bands.count, 16)
    }

    func testDefaultBandsCount32() {
        let bands = EQBand.defaultBands(count: 32)
        XCTAssertEqual(bands.count, 32)
    }

    func testFirstBandIsHighPass() {
        let bands = EQBand.defaultBands(count: 8)
        XCTAssertEqual(bands[0].type, .highPass)
    }

    func testLastBandIsLowPass() {
        let bands = EQBand.defaultBands(count: 8)
        XCTAssertEqual(bands[7].type, .lowPass)
    }

    func testMiddleBandsArePeaking() {
        let bands = EQBand.defaultBands(count: 8)
        for i in 1..<7 {
            XCTAssertEqual(bands[i].type, .peaking, "Band \(i) should be peaking")
        }
    }

    func testBandIDsMatchIndices() {
        let bands = EQBand.defaultBands(count: 8)
        for (i, band) in bands.enumerated() {
            XCTAssertEqual(band.id, i)
        }
    }

    func testDefaultBandGainIsZero() {
        let bands = EQBand.defaultBands(count: 8)
        bands.forEach { XCTAssertEqual($0.gainDB, 0) }
    }

    func testDefaultBandQIsOne() {
        let bands = EQBand.defaultBands(count: 8)
        bands.forEach { XCTAssertEqual($0.q, 1.0) }
    }

    func testDefaultBandsOverflowFrequencies() {
        // When count > available preset frequencies, fallback formula is used
        let bands = EQBand.defaultBands(count: 64)
        XCTAssertEqual(bands.count, 64)
        XCTAssertGreaterThan(bands[63].frequency, 0)
    }

    // MARK: - EQBand Codable

    func testEQBandCodableRoundTrip() throws {
        let band = EQBand(id: 3, frequency: 1000, gainDB: 3.5, q: 2.0, type: .highShelf)
        let data = try JSONEncoder().encode(band)
        let decoded = try JSONDecoder().decode(EQBand.self, from: data)
        XCTAssertEqual(decoded.id, band.id)
        XCTAssertEqual(decoded.frequency, band.frequency)
        XCTAssertEqual(decoded.gainDB, band.gainDB)
        XCTAssertEqual(decoded.q, band.q)
        XCTAssertEqual(decoded.type, band.type)
    }

    // MARK: - EQBandType all cases

    func testAllEQBandTypesDecodable() throws {
        for bandType in EQBandType.allCases {
            let band = EQBand(id: 0, frequency: 1000, gainDB: 0, q: 1.0, type: bandType)
            let data = try JSONEncoder().encode(band)
            let decoded = try JSONDecoder().decode(EQBand.self, from: data)
            XCTAssertEqual(decoded.type, bandType)
        }
    }

    // MARK: - ModulationType all cases

    func testAllModulationTypesDecodable() throws {
        for modType in ModulationType.allCases {
            var fx = EffectSettings()
            fx.modulationType = modType
            let data = try JSONEncoder().encode(fx)
            let decoded = try JSONDecoder().decode(EffectSettings.self, from: data)
            XCTAssertEqual(decoded.modulationType, modType)
        }
    }

    // MARK: - Hashable

    func testHashableConsistency() {
        let fx1 = EffectSettings()
        let fx2 = EffectSettings()
        XCTAssertEqual(fx1.hashValue, fx2.hashValue, "Default instances should hash equally")
    }

    func testHashableChangesWhenModified() {
        let fx1 = EffectSettings()
        var fx2 = EffectSettings()
        fx2.gainDB = 12.0
        XCTAssertNotEqual(fx1.hashValue, fx2.hashValue)
    }
}
