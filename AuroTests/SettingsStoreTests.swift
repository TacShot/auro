import XCTest
@testable import Auro

@MainActor
final class SettingsStoreTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() async throws {
        try await super.setUp()
        // Use a fresh UserDefaults suite per test to avoid cross-test contamination
        suiteName = "com.tacshot.auro.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        try await super.tearDown()
    }

    // MARK: - AppTheme

    func testAppThemeRawValues() {
        XCTAssertEqual(AppTheme.system.rawValue, "System")
        XCTAssertEqual(AppTheme.light.rawValue, "Light")
        XCTAssertEqual(AppTheme.dark.rawValue, "Dark")
    }

    func testAppThemeIDMatchesRawValue() {
        for theme in AppTheme.allCases {
            XCTAssertEqual(theme.id, theme.rawValue)
        }
    }

    func testAppThemeFromValidRawValue() {
        XCTAssertEqual(AppTheme(rawValue: "System"), .system)
        XCTAssertEqual(AppTheme(rawValue: "Light"), .light)
        XCTAssertEqual(AppTheme(rawValue: "Dark"), .dark)
    }

    func testAppThemeFromInvalidRawValueIsNil() {
        XCTAssertNil(AppTheme(rawValue: "invalid"))
        XCTAssertNil(AppTheme(rawValue: ""))
    }

    func testAppThemeAllCasesCount() {
        XCTAssertEqual(AppTheme.allCases.count, 3)
    }

    // MARK: - SettingsStore persistence (using shared instance)

    func testResetToDefaultsRestoresValues() {
        let store = SettingsStore.shared
        // Mutate
        store.launchAtLogin = true
        store.hideInDock = true
        store.runInBackground = false
        store.theme = .dark

        store.resetToDefaults()

        XCTAssertFalse(store.launchAtLogin)
        XCTAssertFalse(store.hideInDock)
        XCTAssertTrue(store.runInBackground)
        XCTAssertEqual(store.theme, .system)
        XCTAssertEqual(store.defaultOutputUID, "")
        XCTAssertEqual(store.defaultInputUID, "")
    }

    func testDeviceNamesRoundTrip() {
        let store = SettingsStore.shared
        store.deviceNames = ["uid-1": "Custom Speaker", "uid-2": "My Mic"]
        store.save()
        store.load()
        XCTAssertEqual(store.deviceNames["uid-1"], "Custom Speaker")
        XCTAssertEqual(store.deviceNames["uid-2"], "My Mic")
        // Cleanup
        store.deviceNames = [:]
    }

    func testDefaultEffectsRoundTrip() throws {
        let store = SettingsStore.shared
        var fx = EffectSettings()
        fx.gainEnabled = true
        fx.gainDB = 3.0
        fx.reverbEnabled = true
        store.defaultEffects = fx
        store.save()
        store.load()
        XCTAssertTrue(store.defaultEffects.gainEnabled)
        XCTAssertEqual(store.defaultEffects.gainDB, 3.0, accuracy: 0.001)
        XCTAssertTrue(store.defaultEffects.reverbEnabled)
        // Cleanup
        store.defaultEffects = EffectSettings()
    }

    func testSavedAppSettingsRoundTrip() throws {
        let store = SettingsStore.shared
        let app = AudioApp(bundleID: "com.test.roundtrip", name: "RoundTrip", pid: 42)
        store.savedAppSettings = [app.bundleID: app]
        store.save()
        store.load()
        XCTAssertNotNil(store.savedAppSettings["com.test.roundtrip"])
        XCTAssertEqual(store.savedAppSettings["com.test.roundtrip"]?.name, "RoundTrip")
        // Cleanup
        store.savedAppSettings = [:]
    }

    func testSavedRoutesRoundTrip() throws {
        let store = SettingsStore.shared
        let route = AudioRoute(sourceID: "com.app", destinationUID: "uid-out")
        store.savedRoutes = [route]
        store.save()
        store.load()
        XCTAssertEqual(store.savedRoutes.count, 1)
        XCTAssertEqual(store.savedRoutes[0].sourceID, "com.app")
        // Cleanup
        store.savedRoutes = []
    }

    func testDefaultOutputAndInputUIDs() {
        let store = SettingsStore.shared
        store.defaultOutputUID = "out-uid"
        store.defaultInputUID = "in-uid"
        store.save()
        store.load()
        XCTAssertEqual(store.defaultOutputUID, "out-uid")
        XCTAssertEqual(store.defaultInputUID, "in-uid")
        // Cleanup
        store.defaultOutputUID = ""
        store.defaultInputUID = ""
    }

    func testRunInBackgroundDefaultsToTrue() {
        // Simulate loading with no stored value (fresh UserDefaults)
        let store = SettingsStore.shared
        UserDefaults.standard.removeObject(forKey: "runInBackground")
        store.load()
        XCTAssertTrue(store.runInBackground, "runInBackground should default to true")
    }

    func testThemePersistenceRoundTrip() {
        let store = SettingsStore.shared
        store.theme = .dark
        store.save()
        store.load()
        XCTAssertEqual(store.theme, .dark)
        // Cleanup
        store.theme = .system
    }
}
