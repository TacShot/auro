import SwiftUI

// MARK: - MixerView

struct MixerView: View {
    @EnvironmentObject var engine: AudioEngine

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 2) {
                ForEach(engine.apps) { app in
                    ChannelStrip(app: app)
                        .environmentObject(engine)
                }
                if engine.apps.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.badge.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No audio apps running")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ChannelStrip

private struct ChannelStrip: View {
    @EnvironmentObject var engine: AudioEngine
    var app: AudioApp
    @State private var showOutputMenu = false

    private var binding: Binding<AudioApp> {
        Binding(
            get: { engine.apps.first(where: { $0.id == app.id }) ?? app },
            set: { engine.updateApp($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: icon + name
            header

            Divider().opacity(0.3)

            // Level meter + Volume fader side by side
            HStack(spacing: 4) {
                LevelMeter(level: app.peakLevel, isMuted: app.isMuted)
                    .frame(width: 10, height: 140)
                VolumeFader(volume: binding.volume)
                    .frame(width: 28, height: 140)
            }
            .padding(.vertical, 8)

            // Pan knob
            PanKnob(pan: binding.pan)
                .frame(width: 40, height: 40)

            Text(panLabel(app.pan))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            Divider().opacity(0.3)

            // Output device
            outputSelector
                .padding(.vertical, 6)

            Divider().opacity(0.3)

            // Mute / Solo
            mutesoloRow

            Divider().opacity(0.3)

            // Effects toggle
            effectsToggle
        }
        .frame(width: 80)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    engine.selectedAppID == app.id ? Color.cyan.opacity(0.7) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .onTapGesture {
            engine.selectedAppID = app.id
        }
    }

    // MARK: Sub-views

    private var header: some View {
        VStack(spacing: 4) {
            Group {
                if let data = app.iconData,
                   let img  = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.cyan)
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .padding(.top, 8)

            Text(app.name)
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 24)
                .padding(.horizontal, 4)
        }
    }

    private var outputSelector: some View {
        Menu {
            Button("System Default") {
                var updated = app
                updated.outputDeviceUID = nil
                engine.updateApp(updated)
            }
            Divider()
            ForEach(engine.outputDevices) { dev in
                Button(dev.displayName) {
                    var updated = app
                    updated.outputDeviceUID = dev.uid
                    engine.updateApp(updated)
                }
            }
        } label: {
            let name = engine.outputDevices.first(where: { $0.uid == app.outputDeviceUID })?.displayName
            Text(name ?? "Default")
                .font(.system(size: 8))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }

    private var mutesoloRow: some View {
        HStack(spacing: 4) {
            Button {
                var updated = app
                updated.isMuted.toggle()
                engine.updateApp(updated)
            } label: {
                Text("M")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 26, height: 20)
                    .background(app.isMuted ? Color.red.opacity(0.8) : Color.secondary.opacity(0.2),
                                in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(app.isMuted ? .white : .primary)
            }
            .buttonStyle(.plain)

            Button {
                var updated = app
                updated.isSolo.toggle()
                engine.updateApp(updated)
            } label: {
                Text("S")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 26, height: 20)
                    .background(app.isSolo ? Color.yellow.opacity(0.8) : Color.secondary.opacity(0.2),
                                in: RoundedRectangle(cornerRadius: 4))
                    .foregroundStyle(app.isSolo ? .black : .primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var effectsToggle: some View {
        Button {
            var updated = app
            updated.effectsEnabled.toggle()
            engine.updateApp(updated)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 9))
                Text("FX")
                    .font(.system(size: 9, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(app.effectsEnabled ? Color.cyan.opacity(0.25) : Color.clear)
            .foregroundStyle(app.effectsEnabled ? .cyan : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func panLabel(_ pan: Float) -> String {
        if abs(pan) < 0.05 { return "C" }
        let pct = Int(abs(pan) * 100)
        return pan < 0 ? "L\(pct)" : "R\(pct)"
    }
}

// MARK: - LevelMeter

private struct LevelMeter: View {
    var level: Float
    var isMuted: Bool

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let filled = CGFloat(isMuted ? 0 : level) * h
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.15))
                RoundedRectangle(cornerRadius: 3)
                    .fill(meterGradient(height: h))
                    .frame(height: filled)
                    .animation(.linear(duration: 0.05), value: filled)
            }
        }
    }

    private func meterGradient(height: CGFloat) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .green,  location: 0.0),
                .init(color: .yellow, location: 0.75),
                .init(color: .red,    location: 1.0)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

// MARK: - VolumeFader

private struct VolumeFader: View {
    @Binding var volume: Float

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let thumbY = h - CGFloat(volume / 1.5) * h

            ZStack(alignment: .top) {
                // Track
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 4)
                    .frame(maxWidth: .infinity)

                // Fill
                Capsule()
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: 4)
                    .frame(height: h - thumbY)
                    .frame(maxWidth: .infinity)
                    .offset(y: thumbY)

                // Thumb
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.shadow(.drop(radius: 2)))
                    .frame(width: 22, height: 10)
                    .frame(maxWidth: .infinity)
                    .offset(y: thumbY - 5)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let newY = max(0, min(h, val.location.y))
                                volume = Float((h - newY) / h) * 1.5
                            }
                    )
            }
        }
    }
}

// MARK: - PanKnob

private struct PanKnob: View {
    @Binding var pan: Float
    @State private var isDragging = false
    @State private var startPan: Float = 0
    @State private var startY: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))

            // Indicator line
            Rectangle()
                .fill(Color.cyan)
                .frame(width: 2, height: 12)
                .offset(y: -8)
                .rotationEffect(.degrees(Double(pan) * 140))
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { val in
                    if !isDragging {
                        isDragging = true
                        startPan = pan
                        startY = val.startLocation.y
                    }
                    let delta = Float(startY - val.location.y) / 100.0
                    pan = max(-1, min(1, startPan + delta))
                }
                .onEnded { _ in isDragging = false }
        )
        .onTapGesture(count: 2) { pan = 0 }  // double-tap resets
    }
}

#Preview {
    MixerView()
        .environmentObject(AudioEngine.shared)
        .frame(width: 600, height: 400)
}
