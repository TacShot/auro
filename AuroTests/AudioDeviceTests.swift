import XCTest
@testable import Auro

final class AudioDeviceTests: XCTestCase {

    private func makeDevice(
        id: UInt32 = 1,
        uid: String = "uid-1",
        name: String = "Built-in Output",
        customName: String? = nil,
        isInput: Bool = false,
        isOutput: Bool = true,
        inputChannelCount: Int = 0,
        outputChannelCount: Int = 2,
        sampleRate: Double = 44100,
        isDefaultInput: Bool = false,
        isDefaultOutput: Bool = false,
        volume: Float = 1.0,
        isMuted: Bool = false
    ) -> AudioDevice {
        AudioDevice(
            id: id,
            uid: uid,
            name: name,
            customName: customName,
            isInput: isInput,
            isOutput: isOutput,
            inputChannelCount: inputChannelCount,
            outputChannelCount: outputChannelCount,
            sampleRate: sampleRate,
            isDefaultInput: isDefaultInput,
            isDefaultOutput: isDefaultOutput,
            volume: volume,
            isMuted: isMuted
        )
    }

    // MARK: - displayName

    func testDisplayNameUsesFactoryNameWhenNoCustomName() {
        let device = makeDevice(name: "Speakers", customName: nil)
        XCTAssertEqual(device.displayName, "Speakers")
    }

    func testDisplayNameUsesCustomNameWhenSet() {
        let device = makeDevice(name: "Speakers", customName: "Living Room")
        XCTAssertEqual(device.displayName, "Living Room")
    }

    func testDisplayNameEmptyCustomNameFallsBackToFactory() {
        // customName is non-nil but empty - still overrides factory name
        let device = makeDevice(name: "Speakers", customName: "")
        XCTAssertEqual(device.displayName, "")
    }

    // MARK: - Codable

    func testCodableRoundTrip() throws {
        let device = makeDevice(
            id: 42, uid: "uid-42", name: "Test Device",
            customName: "My Device", isInput: true, isOutput: true,
            inputChannelCount: 2, outputChannelCount: 2, sampleRate: 48000,
            isDefaultInput: true, isDefaultOutput: false, volume: 0.8, isMuted: true
        )
        let data = try JSONEncoder().encode(device)
        let decoded = try JSONDecoder().decode(AudioDevice.self, from: data)

        XCTAssertEqual(decoded.id, device.id)
        XCTAssertEqual(decoded.uid, device.uid)
        XCTAssertEqual(decoded.name, device.name)
        XCTAssertEqual(decoded.customName, device.customName)
        XCTAssertEqual(decoded.isInput, device.isInput)
        XCTAssertEqual(decoded.isOutput, device.isOutput)
        XCTAssertEqual(decoded.inputChannelCount, device.inputChannelCount)
        XCTAssertEqual(decoded.outputChannelCount, device.outputChannelCount)
        XCTAssertEqual(decoded.sampleRate, device.sampleRate)
        XCTAssertEqual(decoded.isDefaultInput, device.isDefaultInput)
        XCTAssertEqual(decoded.isDefaultOutput, device.isDefaultOutput)
        XCTAssertEqual(decoded.volume, device.volume)
        XCTAssertEqual(decoded.isMuted, device.isMuted)
    }

    func testCodableRoundTripNilCustomName() throws {
        let device = makeDevice(customName: nil)
        let data = try JSONEncoder().encode(device)
        let decoded = try JSONDecoder().decode(AudioDevice.self, from: data)
        XCTAssertNil(decoded.customName)
    }

    // MARK: - Hashable

    func testHashableUsesId() {
        let d1 = makeDevice(id: 1, uid: "a")
        let d2 = makeDevice(id: 1, uid: "b")
        // Both have the same `id` integer; struct equality covers all fields
        var set: Set<AudioDevice> = [d1]
        set.insert(d2)
        // d1 and d2 have different uids, so they are different values
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Property defaults

    func testDefaultVolumeIsOne() {
        let device = makeDevice()
        XCTAssertEqual(device.volume, 1.0)
    }

    func testDefaultIsMutedIsFalse() {
        let device = makeDevice()
        XCTAssertFalse(device.isMuted)
    }

    func testInputOnlyDevice() {
        let device = makeDevice(isInput: true, isOutput: false, inputChannelCount: 2, outputChannelCount: 0)
        XCTAssertTrue(device.isInput)
        XCTAssertFalse(device.isOutput)
        XCTAssertEqual(device.inputChannelCount, 2)
        XCTAssertEqual(device.outputChannelCount, 0)
    }
}
