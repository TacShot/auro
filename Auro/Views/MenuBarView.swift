import SwiftUI

// MARK: - MenuBarView

/// Compact popover accessible from the menu bar status item.
struct MenuBarView: View {
    @EnvironmentObject var engine: AudioEngine
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                Text("Auro").font(.headline)
                Spacer()
                Button {
                    bringMainWindowForward()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Open Auro")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Output selector
            HStack {
                Image(systemName: "speaker.wave.2").foregroundStyle(.secondary)
                Picker("", selection: Binding(
                    get: { engine.defaultOutput?.uid ?? "" },
                    set: { uid in
                        if let dev = engine.outputDevices.first(where: { $0.uid == uid }) {
                            engine.deviceManager.setAsDefaultOutput(dev)
                        }
                    }
                )) {
                    ForEach(engine.outputDevices) { dev in
                        Text(dev.displayName).tag(dev.uid)
                    }
                }
                .labelsHidden()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()

            // Quick app controls (top 5)
            if engine.apps.isEmpty {
                Text("No audio apps running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(engine.apps.prefix(6)) { app in
                            MiniAppRow(app: app)
                                .environmentObject(engine)
                            Divider().opacity(0.3)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }

            Divider()

            // Global mute / unmute
            HStack(spacing: 8) {
                Button("Mute All") {
                    for i in engine.apps.indices { engine.apps[i].isMuted = true }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Unmute All") {
                    for i in engine.apps.indices { engine.apps[i].isMuted = false }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .font(.callout)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
        .background(VisualEffectBackground())
    }

    private func bringMainWindowForward() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - MiniAppRow

private struct MiniAppRow: View {
    @EnvironmentObject var engine: AudioEngine
    var app: AudioApp

    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Group {
                if let data = app.iconData, let img = NSImage(data: data) {
                    Image(nsImage: img).resizable().scaledToFill()
                } else {
                    Image(systemName: "app.fill").foregroundStyle(.cyan)
                }
            }
            .frame(width: 22, height: 22)
            .clipShape(RoundedRectangle(cornerRadius: 5))

            // Name
            Text(app.name)
                .font(.callout)
                .lineLimit(1)

            Spacer()

            // Level dot
            Circle()
                .fill(app.isMuted ? Color.gray : levelColor(app.peakLevel))
                .frame(width: 8, height: 8)

            // Volume slider
            Slider(
                value: Binding(
                    get: { Double(app.volume) },
                    set: { engine.setAppVolume(Float($0), app: app) }
                ),
                in: 0...1.5
            )
            .frame(width: 80)
            .tint(.cyan)

            // Mute button
            Button {
                engine.setAppMute(!app.isMuted, app: app)
            } label: {
                Image(systemName: app.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(app.isMuted ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    private func levelColor(_ level: Float) -> Color {
        level > 0.8 ? .red : level > 0.5 ? .yellow : .green
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AudioEngine.shared)
        .environmentObject(SettingsStore.shared)
}
