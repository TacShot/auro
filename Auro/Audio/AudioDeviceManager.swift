import Foundation
import CoreAudio
import Combine

// MARK: - AudioDeviceManager

/// Enumerates CoreAudio hardware devices and provides get/set helpers.
/// Publishes the `devices` array; callers observe it via Combine or SwiftUI.
@MainActor
final class AudioDeviceManager: ObservableObject {

    @Published var devices: [AudioDevice] = []

    private var listenerBlock: AudioObjectPropertyListenerBlock?

    init() {
        loadDevices()
        subscribeToHardwareChanges()
    }

    deinit {
        if let block = listenerBlock {
            var addr = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &addr, nil, block)
        }
    }

    // MARK: Public

    func reload() { loadDevices() }

    func setVolume(_ volume: Float, for device: AudioDevice) {
        guard device.isOutput else { return }
        var v = max(0, min(1, volume))
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let size = UInt32(MemoryLayout<Float32>.size)
        AudioObjectSetPropertyData(device.id, &addr, 0, nil, size, &v)
        if let idx = devices.firstIndex(where: { $0.id == device.id }) {
            devices[idx].volume = volume
        }
    }

    func setMute(_ muted: Bool, for device: AudioDevice) {
        var val: UInt32 = muted ? 1 : 0
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let size = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectSetPropertyData(device.id, &addr, 0, nil, size, &val)
        if let idx = devices.firstIndex(where: { $0.id == device.id }) {
            devices[idx].isMuted = muted
        }
    }

    func setAsDefaultOutput(_ device: AudioDevice) {
        var devID = device.id
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, size, &devID)
        loadDevices()
    }

    func setAsDefaultInput(_ device: AudioDevice) {
        var devID = device.id
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, size, &devID)
        loadDevices()
    }

    func renameDevice(uid: String, newName: String) {
        if let idx = devices.firstIndex(where: { $0.uid == uid }) {
            devices[idx].customName = newName.isEmpty ? nil : newName
        }
    }

    // MARK: Private

    private func loadDevices() {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &dataSize) == noErr
        else { return }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &dataSize, &deviceIDs) == noErr
        else { return }

        let defaultOut = defaultDeviceID(selector: kAudioHardwarePropertyDefaultOutputDevice)
        let defaultIn  = defaultDeviceID(selector: kAudioHardwarePropertyDefaultInputDevice)

        devices = deviceIDs.compactMap { devID in
            buildAudioDevice(id: devID, defaultOutID: defaultOut, defaultInID: defaultIn)
        }
    }

    private func defaultDeviceID(selector: AudioObjectPropertySelector) -> AudioDeviceID {
        var devID: AudioDeviceID = 0
        var addr = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &devID)
        return devID
    }

    private func buildAudioDevice(
        id: AudioDeviceID,
        defaultOutID: AudioDeviceID,
        defaultInID: AudioDeviceID
    ) -> AudioDevice? {
        guard let name = stringProperty(id: id, selector: kAudioDevicePropertyDeviceNameCFString),
              let uid  = stringProperty(id: id, selector: kAudioDevicePropertyDeviceUID)
        else { return nil }

        let inputChannels  = channelCount(id: id, scope: kAudioDevicePropertyScopeInput)
        let outputChannels = channelCount(id: id, scope: kAudioDevicePropertyScopeOutput)
        let sampleRate     = getSampleRate(id: id)
        let volume         = getVolume(id: id)
        let muted          = getMute(id: id)

        return AudioDevice(
            id: id,
            uid: uid,
            name: name,
            isInput:  inputChannels > 0,
            isOutput: outputChannels > 0,
            inputChannelCount:  inputChannels,
            outputChannelCount: outputChannels,
            sampleRate: sampleRate,
            isDefaultInput:  id == defaultInID,
            isDefaultOutput: id == defaultOutID,
            volume: volume,
            isMuted: muted
        )
    }

    private func stringProperty(id: AudioDeviceID, selector: AudioObjectPropertySelector) -> String? {
        var addr = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfStr: CFString? = nil
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &cfStr)
        guard status == noErr, let s = cfStr else { return nil }
        return s as String
    }

    private func channelCount(id: AudioDeviceID, scope: AudioObjectPropertyScope) -> Int {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &dataSize) == noErr,
              dataSize > 0 else { return 0 }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(dataSize))
        defer { bufferList.deallocate() }
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &dataSize, bufferList) == noErr
        else { return 0 }

        let abl = UnsafeMutableAudioBufferListPointer(bufferList)
        return abl.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private func getSampleRate(id: AudioDeviceID) -> Double {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var rate: Float64 = 44100
        var size = UInt32(MemoryLayout<Float64>.size)
        AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &rate)
        return rate
    }

    private func getVolume(id: AudioDeviceID) -> Float {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var vol: Float32 = 1
        var size = UInt32(MemoryLayout<Float32>.size)
        AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &vol)
        return vol
    }

    private func getMute(id: AudioDeviceID) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &muted)
        return muted != 0
    }

    private func subscribeToHardwareChanges() {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.loadDevices()
            }
        }
        listenerBlock = block
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &addr, nil, block)
    }
}
