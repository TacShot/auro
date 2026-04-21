import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var engine: AudioEngine
    @EnvironmentObject var settings: SettingsStore
    @State private var selectedTab: Tab = .graph
    @State private var showingSettings = false

    enum Tab: String, CaseIterable {
        case graph  = "Routing"
        case mixer  = "Mixer"
        case effects = "Effects"
    }

    var body: some View {
        ZStack {
            // Background blur
            VisualEffectBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Toolbar
                toolbar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                Divider().opacity(0.4)

                // Main content
                switch selectedTab {
                case .graph:
                    RoutingGraphView()
                        .environmentObject(engine)
                        .transition(.opacity)
                case .mixer:
                    MixerView()
                        .environmentObject(engine)
                        .transition(.opacity)
                case .effects:
                    EffectsView(
                        app: engine.apps.first(where: { $0.id == engine.selectedAppID }),
                        route: engine.routes.first(where: { $0.id == engine.selectedRouteID })
                    )
                    .environmentObject(engine)
                    .transition(.opacity)
                }

                Divider().opacity(0.4)

                // Status bar
                statusBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }

    // MARK: Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            // App icon + name
            HStack(spacing: 6) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                Text("Auro")
                    .font(.title2.bold())
            }

            Spacer()

            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tabIcon(tab))
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            Spacer()

            // Default output selector
            if !engine.outputDevices.isEmpty {
                outputPicker
            }

            // Settings button
            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    private var outputPicker: some View {
        Menu {
            ForEach(engine.outputDevices) { device in
                Button(device.displayName) {
                    engine.deviceManager.setAsDefaultOutput(device)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "speaker.wave.2")
                Text(engine.defaultOutput?.displayName ?? "No Output")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .font(.callout)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .frame(maxWidth: 180)
    }

    // MARK: Status bar

    private var statusBar: some View {
        HStack {
            Circle()
                .fill(.green)
                .frame(width: 7, height: 7)
            Text("Audio engine running")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(engine.apps.count) app\(engine.apps.count == 1 ? "" : "s")  •  \(engine.devices.count) device\(engine.devices.count == 1 ? "" : "s")  •  \(engine.routes.count) route\(engine.routes.count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func tabIcon(_ tab: Tab) -> String {
        switch tab {
        case .graph:   return "point.3.connected.trianglepath.dotted"
        case .mixer:   return "slider.horizontal.3"
        case .effects: return "waveform.path.ecg"
        }
    }
}

// MARK: - VisualEffectBackground

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore.shared)
        .environmentObject(AudioEngine.shared)
}
