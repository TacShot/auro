import XCTest
@testable import Auro

final class AudioAppTests: XCTestCase {

    // MARK: - Initialization

    func testDefaultInitialization() {
        let app = AudioApp(bundleID: "com.example.app", name: "Example", pid: 1234)
        XCTAssertEqual(app.bundleID, "com.example.app")
        XCTAssertEqual(app.name, "Example")
        XCTAssertEqual(app.pid, 1234)
        XCTAssertEqual(app.volume, 1.0)
        XCTAssertEqual(app.pan, 0.0)
        XCTAssertFalse(app.isMuted)
        XCTAssertFalse(app.isSolo)
        XCTAssertFalse(app.effectsEnabled)
        XCTAssertNil(app.outputDeviceUID)
        XCTAssertNil(app.inputDeviceUID)
        XCTAssertNil(app.iconData)
        XCTAssertEqual(app.peakLevel, 0)
    }

    func testUniqueIDs() {
        let app1 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        let app2 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        XCTAssertNotEqual(app1.id, app2.id, "Each AudioApp should have a unique UUID")
    }

    // MARK: - Equatable / Hashable

    func testEqualityById() {
        var app1 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        var app2 = app1
        app2.name = "Different Name"
        XCTAssertEqual(app1, app2, "Equality is based on id only")
    }

    func testInequalityDifferentIds() {
        let app1 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        let app2 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        XCTAssertNotEqual(app1, app2, "Different UUIDs should be unequal")
    }

    func testHashableConsistency() {
        let app = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        var hasher1 = Hasher()
        var hasher2 = Hasher()
        app.hash(into: &hasher1)
        app.hash(into: &hasher2)
        XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
    }

    func testUsableInSet() {
        let app1 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        let app2 = AudioApp(bundleID: "com.b", name: "B", pid: 2)
        let set: Set<AudioApp> = [app1, app2, app1]
        XCTAssertEqual(set.count, 2, "Set should deduplicate by id")
    }

    // MARK: - Codable (peakLevel excluded)

    func testCodableRoundTrip() throws {
        var app = AudioApp(bundleID: "com.test", name: "Test", pid: 99)
        app.volume = 0.75
        app.pan = -0.5
        app.isMuted = true
        app.isSolo = false
        app.effectsEnabled = true
        app.outputDeviceUID = "uid-out"
        app.inputDeviceUID = "uid-in"
        app.peakLevel = 0.88  // should NOT be encoded

        let data = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(AudioApp.self, from: data)

        XCTAssertEqual(decoded.id, app.id)
        XCTAssertEqual(decoded.bundleID, app.bundleID)
        XCTAssertEqual(decoded.name, app.name)
        XCTAssertEqual(decoded.pid, app.pid)
        XCTAssertEqual(decoded.volume, app.volume)
        XCTAssertEqual(decoded.pan, app.pan)
        XCTAssertEqual(decoded.isMuted, app.isMuted)
        XCTAssertEqual(decoded.outputDeviceUID, app.outputDeviceUID)
        XCTAssertEqual(decoded.inputDeviceUID, app.inputDeviceUID)
        XCTAssertEqual(decoded.effectsEnabled, app.effectsEnabled)
        XCTAssertEqual(decoded.peakLevel, 0, "peakLevel should not be persisted; default is 0")
    }

    func testCodableWithNilOptionals() throws {
        let app = AudioApp(bundleID: "com.nil", name: "Nil", pid: 0)
        let data = try JSONEncoder().encode(app)
        let decoded = try JSONDecoder().decode(AudioApp.self, from: data)
        XCTAssertNil(decoded.outputDeviceUID)
        XCTAssertNil(decoded.inputDeviceUID)
        XCTAssertNil(decoded.iconData)
    }

    // MARK: - Volume range

    func testVolumeField() {
        var app = AudioApp(bundleID: "com.v", name: "V", pid: 1)
        app.volume = 1.5
        XCTAssertEqual(app.volume, 1.5)
        app.volume = 0.0
        XCTAssertEqual(app.volume, 0.0)
    }

    // MARK: - Effect settings default

    func testDefaultEffectSettings() {
        let app = AudioApp(bundleID: "com.fx", name: "FX", pid: 1)
        XCTAssertFalse(app.effectSettings.eqEnabled)
        XCTAssertFalse(app.effectSettings.reverbEnabled)
        XCTAssertFalse(app.effectSettings.gainEnabled)
    }
}
