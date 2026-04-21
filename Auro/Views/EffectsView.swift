import SwiftUI

// MARK: - EffectsView

struct EffectsView: View {
    @EnvironmentObject var engine: AudioEngine

    var app: AudioApp?
    var route: AudioRoute?

    @State private var settings = EffectSettings()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let app = app {
                    header("Effects — \(app.name)", icon: "waveform.path.ecg")
                } else if let route = route {
                    header("Effects — Route: \(route.sourceID) → \(route.destinationUID)", icon: "arrow.triangle.branch")
                } else {
                    emptyPrompt
                }

                if app != nil || route != nil {
                    gainSection
                    Divider()
                    eqSection
                    Divider()
                    noiseGateSection
                    Divider()
                    noiseSuppressSection
                    Divider()
                    compressorSection
                    Divider()
                    delaySection
                    Divider()
                    reverbSection
                    Divider()
                    pitchSection
                    Divider()
                    harmonizeSection
                    Divider()
                    modulationSection
                }
            }
            .padding(20)
        }
        .onAppear { loadSettings() }
        .onChange(of: app?.id) { _ in loadSettings() }
        .onChange(of: route?.id) { _ in loadSettings() }
        .onChange(of: settings) { newSettings in applySettings(newSettings) }
    }

    // MARK: Header

    private func header(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.cyan)
            Text(title).font(.headline)
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg.rectangle").font(.system(size: 48)).foregroundStyle(.tertiary)
            Text("Select an app in the Mixer or a route in the Graph to edit its effects.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: Gain

    private var gainSection: some View {
        EffectSection(title: "Gain", systemImage: "dial.high", enabled: $settings.gainEnabled) {
            LabeledSlider(label: "Gain", value: $settings.gainDB, range: -24...24, unit: "dB", defaultValue: 0)
        }
    }

    // MARK: EQ

    private var eqSection: some View {
        EffectSection(title: "Equalizer", systemImage: "slider.horizontal.3", enabled: $settings.eqEnabled) {
            VStack(alignment: .leading, spacing: 8) {
                // Band count picker
                HStack {
                    Text("Bands")
                    Spacer()
                    Picker("", selection: $settings.eqBandCount) {
                        ForEach([4, 8, 16, 32, 64], id: \.self) { n in Text("\(n)").tag(n) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
                    .onChange(of: settings.eqBandCount) { n in
                        settings.eqBands = EQBand.defaultBands(count: n)
                    }
                }

                // Visual EQ frequency response curve
                EQCurveView(bands: settings.eqBands)
                    .frame(height: 100)
                    .background(Color.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))

                // Per-band gain sliders (show first 8 for readability)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 4) {
                    ForEach(settings.eqBands.prefix(8).indices, id: \.self) { i in
                        VStack(spacing: 2) {
                            Text(freqLabel(settings.eqBands[i].frequency))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                            Slider(value: $settings.eqBands[i].gainDB, in: -24...24)
                                .frame(height: 16)
                            Text(String(format: "%.1f", settings.eqBands[i].gainDB))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Noise Gate

    private var noiseGateSection: some View {
        EffectSection(title: "Noise Gate", systemImage: "rectangle.compress.vertical", enabled: $settings.noiseGateEnabled) {
            LabeledSlider(label: "Threshold", value: $settings.noiseGateThresholdDB, range: -96...0,    unit: "dB", defaultValue: -60)
            LabeledSlider(label: "Attack",    value: $settings.noiseGateAttackMs,    range: 0.1...200,  unit: "ms", defaultValue: 5)
            LabeledSlider(label: "Release",   value: $settings.noiseGateReleaseMs,   range: 1...2000,   unit: "ms", defaultValue: 100)
        }
    }

    // MARK: Noise Suppressor

    private var noiseSuppressSection: some View {
        EffectSection(title: "Noise Suppressor", systemImage: "waveform.path.badge.minus", enabled: $settings.noiseSuppressEnabled) {
            LabeledSlider(label: "Strength", value: $settings.noiseSuppressStrength, range: 0...1, unit: "", defaultValue: 0.5)
        }
    }

    // MARK: Compressor

    private var compressorSection: some View {
        EffectSection(title: "Compressor", systemImage: "waveform.path", enabled: $settings.compressorEnabled) {
            LabeledSlider(label: "Threshold", value: $settings.compressorThresholdDB, range: -60...0, unit: "dB", defaultValue: -20)
            LabeledSlider(label: "Ratio",     value: $settings.compressorRatio,       range: 1...40,  unit: ":1", defaultValue: 4)
            LabeledSlider(label: "Attack",    value: $settings.compressorAttackMs,    range: 0.1...200, unit: "ms", defaultValue: 10)
            LabeledSlider(label: "Release",   value: $settings.compressorReleaseMs,   range: 1...2000,  unit: "ms", defaultValue: 100)
        }
    }

    // MARK: Delay

    private var delaySection: some View {
        EffectSection(title: "Delay", systemImage: "arrow.uturn.right", enabled: $settings.delayEnabled) {
            LabeledSlider(label: "Time",     value: $settings.delayTimeMs,   range: 0...2000, unit: "ms", defaultValue: 250)
            LabeledSlider(label: "Feedback", value: $settings.delayFeedback, range: 0...1,    unit: "",   defaultValue: 0.3)
            LabeledSlider(label: "Mix",      value: $settings.delayMix,      range: 0...1,    unit: "",   defaultValue: 0.3)
        }
    }

    // MARK: Reverb

    private var reverbSection: some View {
        EffectSection(title: "Reverb", systemImage: "square.3.layers.3d", enabled: $settings.reverbEnabled) {
            LabeledSlider(label: "Room Size", value: $settings.reverbRoomSize, range: 0...1, unit: "", defaultValue: 0.5)
            LabeledSlider(label: "Damping",   value: $settings.reverbDamping,  range: 0...1, unit: "", defaultValue: 0.5)
            LabeledSlider(label: "Mix",       value: $settings.reverbMix,      range: 0...1, unit: "", defaultValue: 0.25)
        }
    }

    // MARK: Pitch

    private var pitchSection: some View {
        EffectSection(title: "Pitch Shift", systemImage: "music.note", enabled: $settings.pitchEnabled) {
            LabeledSlider(label: "Semitones", value: $settings.pitchSemitones, range: -24...24, unit: "st", defaultValue: 0)
        }
    }

    // MARK: Harmonize

    private var harmonizeSection: some View {
        EffectSection(title: "Harmonize", systemImage: "music.note.list", enabled: $settings.harmonizeEnabled) {
            HStack {
                Text("Interval")
                Spacer()
                Stepper("\(settings.harmonizeInterval) st", value: $settings.harmonizeInterval, in: -24...24)
            }
            LabeledSlider(label: "Mix", value: $settings.harmonizeMix, range: 0...1, unit: "", defaultValue: 0.5)
        }
    }

    // MARK: Modulation

    private var modulationSection: some View {
        EffectSection(title: "Modulation", systemImage: "waveform", enabled: $settings.modulationEnabled) {
            Picker("Type", selection: $settings.modulationType) {
                ForEach(ModulationType.allCases) { t in Text(t.rawValue).tag(t) }
            }
            .pickerStyle(.segmented)
            LabeledSlider(label: "Rate",  value: $settings.modulationRate,  range: 0.1...20, unit: "Hz", defaultValue: 1.0)
            LabeledSlider(label: "Depth", value: $settings.modulationDepth, range: 0...1,    unit: "",   defaultValue: 0.5)
        }
    }

    // MARK: Helpers

    private func loadSettings() {
        if let app = app, let a = engine.apps.first(where: { $0.id == app.id }) {
            settings = a.effectSettings
        } else if let route = route, let r = engine.routes.first(where: { $0.id == route.id }) {
            settings = r.effectSettings
        }
    }

    private func applySettings(_ s: EffectSettings) {
        if let app = app {
            engine.applyEffects(s, to: app)
        } else if var route = route {
            route.effectSettings = s
            engine.updateRoute(route)
        }
    }

    private func freqLabel(_ freq: Float) -> String {
        freq >= 1000 ? String(format: "%.1fk", freq / 1000) : String(format: "%.0f", freq)
    }
}

// MARK: - EffectSection

private struct EffectSection<Content: View>: View {
    let title: String
    let systemImage: String
    @Binding var enabled: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(enabled ? .cyan : .secondary)
                    .frame(width: 18)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(enabled ? .primary : .secondary)
                Spacer()
                Toggle("", isOn: $enabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(.cyan)
            }
            if enabled {
                content()
                    .padding(.leading, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: enabled)
    }
}

// MARK: - LabeledSlider

private struct LabeledSlider: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let unit: String
    let defaultValue: Float

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
                .frame(width: 80, alignment: .leading)
            Slider(value: $value, in: range)
            Text(formatted(value))
                .font(.system(.caption, design: .monospaced))
                .frame(width: 60, alignment: .trailing)
                .foregroundStyle(.secondary)
            Button {
                value = defaultValue
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
        }
    }

    private func formatted(_ v: Float) -> String {
        unit.isEmpty ? String(format: "%.2f", v) : String(format: "%.1f %@", v, unit)
    }
}

// MARK: - EQCurveView

private struct EQCurveView: View {
    let bands: [EQBand]

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let midY = h / 2

            // Grid
            ctx.stroke(
                Path { p in p.move(to: CGPoint(x: 0, y: midY)); p.addLine(to: CGPoint(x: w, y: midY)) },
                with: .color(.secondary.opacity(0.3)),
                lineWidth: 0.5
            )

            guard !bands.isEmpty else { return }

            // Build frequency response curve
            var path = Path()
            let steps = Int(w)
            for xPx in 0...steps {
                let freq = logFreq(xPx: CGFloat(xPx), width: w)
                var totalGain: Float = 0
                for band in bands {
                    totalGain += bandResponse(freq: freq, band: band)
                }
                let y = midY - CGFloat(totalGain) / 24.0 * (midY - 4)
                let pt = CGPoint(x: CGFloat(xPx), y: y)
                if xPx == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }

            ctx.stroke(path, with: .color(Color.cyan.opacity(0.9)), lineWidth: 2)

            // Fill area under curve
            var fill = path
            fill.addLine(to: CGPoint(x: w, y: midY))
            fill.addLine(to: CGPoint(x: 0, y: midY))
            fill.closeSubpath()
            ctx.fill(fill, with: .color(Color.cyan.opacity(0.1)))
        }
    }

    /// Map pixel x to log-scale frequency (20 Hz – 20 kHz)
    private func logFreq(xPx: CGFloat, width: CGFloat) -> Float {
        let t = xPx / width
        return Float(pow(10.0, Double(t) * (log10(20000) - log10(20)) + log10(20)))
    }

    /// Simple peaking filter magnitude response approximation
    private func bandResponse(freq: Float, band: EQBand) -> Float {
        guard band.gainDB != 0 else { return 0 }
        let ratio = freq / band.frequency
        let denom = 1 + band.q * band.q * (ratio - 1/ratio) * (ratio - 1/ratio)
        return band.gainDB / Float(denom)
    }
}

#Preview {
    EffectsView(app: nil, route: nil)
        .environmentObject(AudioEngine.shared)
        .frame(width: 500, height: 700)
}
