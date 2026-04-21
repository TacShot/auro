import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var engine: AudioEngine

    var body: some View {
        TabView {
            GeneralTab()
                .environmentObject(settings)
                .tabItem { Label("General",  systemImage: "gearshape") }

            DevicesTab()
                .environmentObject(settings)
                .environmentObject(engine)
                .tabItem { Label("Devices",  systemImage: "speaker.wave.3") }

            EffectsDefaultsTab()
                .environmentObject(settings)
                .tabItem { Label("Effects",  systemImage: "waveform.path.ecg") }

            AboutTab()
                .tabItem { Label("About",    systemImage: "info.circle") }
        }
        .frame(width: 520, height: 400)
    }
}

// MARK: - GeneralTab

private struct GeneralTab: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch Auro at login", isOn: $settings.launchAtLogin)
                Toggle("Run in background when window is closed", isOn: $settings.runInBackground)
                Toggle("Hide from Dock (menu bar only)", isOn: $settings.hideInDock)
            }

            Section("Appearance") {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                Button("Reset all settings to defaults", role: .destructive) {
                    settings.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - DevicesTab

private struct DevicesTab: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var engine: AudioEngine
    @State private var editingUID: String? = nil
    @State private var editText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Default Input:")
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $settings.defaultInputUID) {
                    Text("System Default").tag("")
                    ForEach(engine.inputDevices) { dev in
                        Text(dev.displayName).tag(dev.uid)
                    }
                }
                .labelsHidden()
            }
            .padding()

            HStack {
                Text("Default Output:")
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $settings.defaultOutputUID) {
                    Text("System Default").tag("")
                    ForEach(engine.outputDevices) { dev in
                        Text(dev.displayName).tag(dev.uid)
                    }
                }
                .labelsHidden()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            Text("Rename Devices")
                .font(.headline)
                .padding()

            List {
                ForEach(engine.devices) { device in
                    HStack {
                        Image(systemName: device.isOutput ? "speaker.wave.2" : "mic")
                            .frame(width: 20)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(device.name).font(.callout)
                            Text(device.uid)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if editingUID == device.uid {
                            TextField("Custom name", text: $editText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                                .onSubmit {
                                    commitRename(uid: device.uid)
                                }
                            Button("Save") {
                                commitRename(uid: device.uid)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            Button("Cancel") {
                                editingUID = nil
                            }
                            .controlSize(.small)
                        } else {
                            if let custom = settings.deviceNames[device.uid] {
                                Text(custom)
                                    .foregroundStyle(.cyan)
                                    .font(.callout)
                            }
                            Button("Rename") {
                                editText = settings.deviceNames[device.uid] ?? ""
                                editingUID = device.uid
                            }
                            .controlSize(.small)
                            if settings.deviceNames[device.uid] != nil {
                                Button("Clear") {
                                    settings.deviceNames.removeValue(forKey: device.uid)
                                    engine.deviceManager.renameDevice(uid: device.uid, newName: "")
                                }
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.top, 4)
    }

    private func commitRename(uid: String) {
        if editText.isEmpty {
            settings.deviceNames.removeValue(forKey: uid)
        } else {
            settings.deviceNames[uid] = editText
        }
        engine.deviceManager.renameDevice(uid: uid, newName: editText)
        editingUID = nil
    }
}

// MARK: - EffectsDefaultsTab

private struct EffectsDefaultsTab: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Default effects applied to new applications")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                EffectsView(app: nil, route: nil)
                    .environmentObject(AudioEngine.shared)
            }
        }
    }
}

// MARK: - AboutTab

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
            Text("Auro")
                .font(.largeTitle.bold())
            Text("Version 1.0.0 (Build 1)")
                .foregroundStyle(.secondary)
            Text("Advanced audio routing, mixing, and effects for macOS.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Divider()
            Link("View on GitHub", destination: URL(string: "https://github.com/TacShot/auro")!)
                .font(.callout)
            Text("© 2024 TacShot. All rights reserved.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsStore.shared)
        .environmentObject(AudioEngine.shared)
}
