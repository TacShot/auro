import XCTest
@testable import Auro

final class AudioRouteTests: XCTestCase {

    // MARK: - Initialization

    func testDefaultInitialization() {
        let route = AudioRoute(sourceID: "com.example.app", destinationUID: "uid-speaker")
        XCTAssertEqual(route.sourceID, "com.example.app")
        XCTAssertEqual(route.destinationUID, "uid-speaker")
        XCTAssertEqual(route.volume, 1.0)
        XCTAssertTrue(route.isActive)
    }

    func testUniqueIDs() {
        let r1 = AudioRoute(sourceID: "src", destinationUID: "dst")
        let r2 = AudioRoute(sourceID: "src", destinationUID: "dst")
        XCTAssertNotEqual(r1.id, r2.id)
    }

    // MARK: - Equatable / Hashable

    func testEqualityById() {
        var r1 = AudioRoute(sourceID: "src", destinationUID: "dst")
        var r2 = r1
        r2.volume = 0.5
        r2.isActive = false
        XCTAssertEqual(r1, r2, "Equality should depend only on id")
    }

    func testInequalityDifferentId() {
        let r1 = AudioRoute(sourceID: "src", destinationUID: "dst")
        let r2 = AudioRoute(sourceID: "src", destinationUID: "dst")
        XCTAssertNotEqual(r1, r2)
    }

    func testUsableAsSetElement() {
        let r1 = AudioRoute(sourceID: "a", destinationUID: "b")
        let r2 = AudioRoute(sourceID: "a", destinationUID: "b")
        let set: Set<AudioRoute> = [r1, r2, r1]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        var route = AudioRoute(sourceID: "com.app", destinationUID: "uid-out")
        route.volume = 0.6
        route.isActive = false

        let data = try JSONEncoder().encode(route)
        let decoded = try JSONDecoder().decode(AudioRoute.self, from: data)

        XCTAssertEqual(decoded.id, route.id)
        XCTAssertEqual(decoded.sourceID, route.sourceID)
        XCTAssertEqual(decoded.destinationUID, route.destinationUID)
        XCTAssertEqual(decoded.volume, route.volume)
        XCTAssertEqual(decoded.isActive, route.isActive)
    }

    func testCodableArrayRoundTrip() throws {
        let routes = [
            AudioRoute(sourceID: "app1", destinationUID: "out1"),
            AudioRoute(sourceID: "app2", destinationUID: "out2")
        ]
        let data = try JSONEncoder().encode(routes)
        let decoded = try JSONDecoder().decode([AudioRoute].self, from: data)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].sourceID, "app1")
        XCTAssertEqual(decoded[1].sourceID, "app2")
    }

    // MARK: - Effect settings default

    func testDefaultEffectSettings() {
        let route = AudioRoute(sourceID: "s", destinationUID: "d")
        XCTAssertFalse(route.effectSettings.eqEnabled)
        XCTAssertFalse(route.effectSettings.delayEnabled)
        XCTAssertFalse(route.effectSettings.compressorEnabled)
    }
}
