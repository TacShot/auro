import XCTest
@testable import Auro

@MainActor
final class AudioEngineTests: XCTestCase {

    var engine: AudioEngine!

    override func setUp() async throws {
        try await super.setUp()
        engine = AudioEngine.shared
        // Reset to clean state
        engine.apps = []
        engine.routes = []
        engine.selectedAppID = nil
        engine.selectedRouteID = nil
    }

    // MARK: - Device Filtering Helpers

    func testOutputDevicesFilteredFromAll() {
        let output = AudioDevice(
            id: 1, uid: "out", name: "Speaker",
            isInput: false, isOutput: true,
            inputChannelCount: 0, outputChannelCount: 2,
            sampleRate: 44100
        )
        let input = AudioDevice(
            id: 2, uid: "in", name: "Mic",
            isInput: true, isOutput: false,
            inputChannelCount: 2, outputChannelCount: 0,
            sampleRate: 44100
        )
        engine.devices = [output, input]
        XCTAssertEqual(engine.outputDevices.count, 1)
        XCTAssertEqual(engine.outputDevices[0].uid, "out")
    }

    func testInputDevicesFilteredFromAll() {
        let output = AudioDevice(
            id: 1, uid: "out", name: "Speaker",
            isInput: false, isOutput: true,
            inputChannelCount: 0, outputChannelCount: 2,
            sampleRate: 44100
        )
        let input = AudioDevice(
            id: 2, uid: "in", name: "Mic",
            isInput: true, isOutput: false,
            inputChannelCount: 2, outputChannelCount: 0,
            sampleRate: 44100
        )
        engine.devices = [output, input]
        XCTAssertEqual(engine.inputDevices.count, 1)
        XCTAssertEqual(engine.inputDevices[0].uid, "in")
    }

    func testDefaultOutputReturnsNilWhenNone() {
        engine.devices = []
        XCTAssertNil(engine.defaultOutput)
    }

    func testDefaultOutputReturnsDefaultDevice() {
        let defaultOut = AudioDevice(
            id: 1, uid: "def-out", name: "Default",
            isInput: false, isOutput: true,
            inputChannelCount: 0, outputChannelCount: 2,
            sampleRate: 44100,
            isDefaultOutput: true
        )
        engine.devices = [defaultOut]
        XCTAssertEqual(engine.defaultOutput?.uid, "def-out")
    }

    func testDefaultInputReturnsDefaultDevice() {
        let defaultIn = AudioDevice(
            id: 2, uid: "def-in", name: "Default Mic",
            isInput: true, isOutput: false,
            inputChannelCount: 2, outputChannelCount: 0,
            sampleRate: 48000,
            isDefaultInput: true
        )
        engine.devices = [defaultIn]
        XCTAssertEqual(engine.defaultInput?.uid, "def-in")
    }

    // MARK: - App Volume

    func testSetAppVolumeClampedToMax() {
        let app = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        engine.apps = [app]
        engine.setAppVolume(2.0, app: app)
        XCTAssertEqual(engine.apps[0].volume, 1.5, accuracy: 0.001)
    }

    func testSetAppVolumeClampedToMin() {
        let app = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        engine.apps = [app]
        engine.setAppVolume(-1.0, app: app)
        XCTAssertEqual(engine.apps[0].volume, 0.0, accuracy: 0.001)
    }

    func testSetAppVolumeWithinRange() {
        let app = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        engine.apps = [app]
        engine.setAppVolume(0.75, app: app)
        XCTAssertEqual(engine.apps[0].volume, 0.75, accuracy: 0.001)
    }

    func testSetAppVolumeForUnknownAppDoesNothing() {
        let app = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        engine.apps = []
        engine.setAppVolume(0.5, app: app) // no crash expected
        XCTAssertTrue(engine.apps.isEmpty)
    }

    // MARK: - App Mute

    func testSetAppMuteTrue() {
        var app = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        app.isMuted = false
        engine.apps = [app]
        engine.setAppMute(true, app: app)
        XCTAssertTrue(engine.apps[0].isMuted)
    }

    func testSetAppMuteFalse() {
        var app = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        app.isMuted = true
        engine.apps = [app]
        engine.setAppMute(false, app: app)
        XCTAssertFalse(engine.apps[0].isMuted)
    }

    // MARK: - App Solo

    func testSetAppSoloMutesOthers() {
        let app1 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        let app2 = AudioApp(bundleID: "com.b", name: "B", pid: 2)
        let app3 = AudioApp(bundleID: "com.c", name: "C", pid: 3)
        engine.apps = [app1, app2, app3]
        engine.setAppSolo(true, app: app1)
        XCTAssertTrue(engine.apps[0].isSolo)
        XCTAssertFalse(engine.apps[1].isSolo)
        XCTAssertFalse(engine.apps[2].isSolo)
    }

    func testSetAppSoloTurningOffDoesNotSoloOthers() {
        var app1 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        app1.isSolo = true
        engine.apps = [app1]
        engine.setAppSolo(false, app: app1)
        XCTAssertFalse(engine.apps[0].isSolo)
    }

    func testSetSoloReplacesPreviousSolo() {
        let app1 = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        let app2 = AudioApp(bundleID: "com.b", name: "B", pid: 2)
        engine.apps = [app1, app2]
        engine.setAppSolo(true, app: app1)
        engine.setAppSolo(true, app: app2)
        XCTAssertFalse(engine.apps[0].isSolo, "app1 should be unsoloed when app2 is soloed")
        XCTAssertTrue(engine.apps[1].isSolo)
    }

    // MARK: - updateApp

    func testUpdateAppChangesStoredValues() {
        var app = AudioApp(bundleID: "com.a", name: "A", pid: 1)
        engine.apps = [app]
        app.volume = 0.3
        app.isMuted = true
        engine.updateApp(app)
        XCTAssertEqual(engine.apps[0].volume, 0.3, accuracy: 0.001)
        XCTAssertTrue(engine.apps[0].isMuted)
    }

    // MARK: - Route Management

    func testAddRoute() {
        engine.addRoute(sourceID: "com.app", destinationUID: "uid-out")
        XCTAssertEqual(engine.routes.count, 1)
        XCTAssertEqual(engine.routes[0].sourceID, "com.app")
        XCTAssertEqual(engine.routes[0].destinationUID, "uid-out")
    }

    func testAddMultipleRoutes() {
        engine.addRoute(sourceID: "com.a", destinationUID: "out1")
        engine.addRoute(sourceID: "com.b", destinationUID: "out2")
        XCTAssertEqual(engine.routes.count, 2)
    }

    func testRemoveRoute() {
        engine.addRoute(sourceID: "com.app", destinationUID: "uid-out")
        let route = engine.routes[0]
        engine.removeRoute(route)
        XCTAssertTrue(engine.routes.isEmpty)
    }

    func testRemoveNonExistentRouteDoesNothing() {
        let route = AudioRoute(sourceID: "x", destinationUID: "y")
        engine.routes = []
        engine.removeRoute(route) // should not crash
        XCTAssertTrue(engine.routes.isEmpty)
    }

    func testUpdateRoute() {
        engine.addRoute(sourceID: "src", destinationUID: "dst")
        var route = engine.routes[0]
        route.volume = 0.4
        route.isActive = false
        engine.updateRoute(route)
        XCTAssertEqual(engine.routes[0].volume, 0.4, accuracy: 0.001)
        XCTAssertFalse(engine.routes[0].isActive)
    }

    // MARK: - applyEffects

    func testApplyEffectsUpdatesAppEffectSettings() {
        let app = AudioApp(bundleID: "com.fx", name: "FX", pid: 1)
        engine.apps = [app]
        var fx = EffectSettings()
        fx.gainEnabled = true
        fx.gainDB = 6.0
        engine.applyEffects(fx, to: app)
        XCTAssertTrue(engine.apps[0].effectSettings.gainEnabled)
        XCTAssertEqual(engine.apps[0].effectSettings.gainDB, 6.0, accuracy: 0.001)
    }
}
