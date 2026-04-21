# Auro — Audio Routing, Mixing & Effects for macOS

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013%2B-blue?logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" />
  <img src="https://img.shields.io/badge/Version-1.0.0-brightgreen" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
</p>

Auro is a native Swift/SwiftUI macOS application that gives you complete control over your Mac's audio.  
Route any application's audio to any output device, apply studio-quality effects per app, and watch the signal flow in an animated routing graph — all from a single window or the menu bar.

---

## Table of Contents

1. [Features](#features)  
2. [System Requirements](#system-requirements)  
3. [Installation](#installation)  
   - [Option A — Download pre-built release (recommended)](#option-a--download-pre-built-release-recommended)  
   - [Option B — Build from source](#option-b--build-from-source)  
4. [First Launch — Allowing the App to Run](#first-launch--allowing-the-app-to-run)  
5. [Granting Permissions](#granting-permissions)  
6. [How Auro Works](#how-auro-works)  
   - [Routing Graph](#routing-graph)  
   - [Mixer](#mixer)  
   - [Effects](#effects)  
   - [Settings](#settings)  
   - [Menu Bar](#menu-bar)  
7. [Audio Effects Reference](#audio-effects-reference)  
8. [Persistence & Background Mode](#persistence--background-mode)  
9. [Versioning & Updates](#versioning--updates)  
10. [Troubleshooting](#troubleshooting)  
11. [Contributing](#contributing)  
12. [License](#license)  

---

## Features

| Category | Capability |
|----------|-----------|
| **Routing** | Per-application audio routing to any output device |
| **Mixing** | Per-app volume (0–150 %), pan, mute, solo, peak level meters |
| **Effects** | EQ (4 / 8 / 16 / 32 / 64 bands), Gain, Noise Gate, Noise Suppressor, Compressor, Delay, Reverb, Pitch Shift, Harmonize, Modulation (Chorus / Flanger / Tremolo / Vibrato) |
| **Graph UI** | Animated bezier-curve routing graph showing live signal flow |
| **Menu Bar** | Quick-access popover with volume sliders, output selector, mute-all |
| **Settings** | Light / Dark / System theme, device rename, default device & effects, launch-at-login |
| **Persistence** | All settings survive app close and system restarts (UserDefaults / Codable) |
| **Background** | Runs silently in the menu bar — no dock icon required |

---

## System Requirements

- **macOS 13 Ventura** or later (macOS 14 Sonoma / 15 Sequoia recommended)  
- Apple Silicon **or** Intel Mac  
- Xcode 15+ (build from source only)  

---

## Installation

### Option A — Download pre-built release (recommended)

1. Go to the [**Releases**](https://github.com/TacShot/auro/releases) page.  
2. Download the latest `Auro-x.x.x.dmg`.  
3. Open the `.dmg` and drag **Auro.app** into your `/Applications` folder.  
4. Follow the [First Launch](#first-launch--allowing-the-app-to-run) steps below.

### Option B — Build from source

```bash
# 1. Clone the repository
git clone https://github.com/TacShot/auro.git
cd auro

# 2. Open in Xcode
open Auro.xcodeproj

# 3. Select the "Auro" scheme and your Mac as the destination
# 4. Press ⌘R to build and run
```

Or build from the command line (no code-signing required for local use):

```bash
xcodebuild \
  -project Auro.xcodeproj \
  -scheme Auro \
  -configuration Release \
  -derivedDataPath /tmp/AuroBuild \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  build

# The built app is at:
open /tmp/AuroBuild/Build/Products/Release/Auro.app
```

---

## First Launch — Allowing the App to Run

Because Auro is distributed outside the Mac App Store (or is freshly built), macOS Gatekeeper will block it on first open.  Follow **one** of the methods below.

### Method 1 — Remove the quarantine attribute (Terminal)

```bash
xattr -cr /Applications/Auro.app
```

Then double-click `Auro.app` normally.

### Method 2 — Privacy & Security Settings (no Terminal needed)

1. Try to open Auro.app — you will see a dialog saying it *"cannot be opened because it is from an unidentified developer"*. Click **OK**.  
2. Open **System Settings** → **Privacy & Security** (macOS 13+) or **System Preferences** → **Security & Privacy** (macOS 12).  
3. Scroll to the bottom of the **Security** section.  
4. You will see: *"Auro was blocked from use because it is not from an identified developer."*  
5. Click **Open Anyway**.  
6. In the confirmation dialog, click **Open**.  

Auro will now open and will not be blocked again.

---

## Granting Permissions

Auro may request the following permissions on first launch:

| Permission | Why it's needed |
|-----------|----------------|
| **Microphone** | To monitor and process audio from input devices (microphone, line-in). |

To grant or review permissions at any time:  
**System Settings** → **Privacy & Security** → **Microphone** → enable the toggle next to **Auro**.

---

## How Auro Works

### Routing Graph

The **Routing** tab displays an animated signal-flow canvas:

- **Left column** — Source nodes: running audio apps and input devices.  
- **Right column** — Destination nodes: output devices.  
- **Curves** — Animated dashed bezier curves showing active routes. Green = active, grey = inactive, red = muted.  
- **Level indicators** — A glowing dot on each node pulses in real time with the audio level.  

To create a new route, drag from a source node to a destination node.  
Click a connection curve to select it and edit its per-route effects in the **Effects** panel.

### Mixer

The **Mixer** tab shows a horizontal row of channel strips — one per running audio application.

Each strip contains:

- **App icon & name**  
- **Peak level meter** (green → yellow → red)  
- **Volume fader** (vertical drag, 0–150 %)  
- **Pan knob** (drag up/down; double-click to reset to centre)  
- **Output device selector** (overrides the system default for that app)  
- **M / S buttons** — Mute and Solo  
- **FX button** — Enable / disable the effects chain for this app  

### Effects

The **Effects** tab (or panel when an app is selected in the Mixer) shows the complete effect chain:

| Effect | Controls |
|--------|---------|
| Gain | ±24 dB gain |
| EQ | 4 / 8 / 16 / 32 / 64 bands; per-band frequency, gain, Q; interactive frequency-response curve |
| Noise Gate | Threshold, Attack, Release |
| Noise Suppressor | Strength |
| Compressor | Threshold, Ratio, Attack, Release |
| Delay | Time (ms), Feedback, Mix |
| Reverb | Room Size, Damping, Mix |
| Pitch Shift | ±24 semitones |
| Harmonize | Interval (semitones), Mix |
| Modulation | Type (Chorus/Flanger/Tremolo/Vibrato), Rate (Hz), Depth |

Enable or disable individual effects with their toggle switch.  The EQ displays a live frequency-response curve that updates as you drag the band handles.

### Settings

Open **Auro → Preferences** (⌘,) for the Settings window:

- **General** — Launch at login, background mode, hide Dock icon, appearance theme (System / Light / Dark).  
- **Devices** — Set default input and output device; rename any device with a custom label; clear custom names.  
- **Effects** — Set default effect chain applied to newly-discovered apps.  
- **About** — Version information and links.

### Menu Bar

Click the **waveform icon** in the menu bar for quick access:

- Volume sliders for the top 6 active apps  
- Output device picker  
- Mute All / Unmute All  
- **Open Auro** button to bring the main window forward  
- Quit button  

---

## Audio Effects Reference

### EQ Band Types

| Type | Description |
|------|-------------|
| High Pass | Removes frequencies below the cutoff |
| Low Shelf | Boosts/cuts all frequencies below the shelf frequency |
| Peaking | Bell-shaped boost/cut at a centre frequency |
| High Shelf | Boosts/cuts all frequencies above the shelf frequency |
| Low Pass | Removes frequencies above the cutoff |
| Band Pass | Passes only a narrow band of frequencies |
| Notch | Deep cut at a single frequency |

### EQ Band Count

Choose from 4, 8, 16, 32, or 64 bands.  When changing the band count the bands are redistributed logarithmically across the 20 Hz – 20 kHz spectrum.

---

## Persistence & Background Mode

All settings are stored in **UserDefaults** using JSON-encoded Codable models. This includes:

- Per-app volume, pan, mute, solo  
- Per-app effect chains  
- Routing connections  
- Device custom names and defaults  
- General preferences  

Settings are loaded on every launch and saved on every change, so nothing is lost when the app is quit or the system restarts.

When **Run in background** is enabled (the default), closing the main window keeps Auro running and accessible via the menu bar icon.

---

## Versioning & Updates

Auro follows **Semantic Versioning** (`MAJOR.MINOR.PATCH`):

- `CFBundleShortVersionString` — marketing version (e.g., `1.0.0`)  
- `CFBundleVersion` — monotonically increasing build number (e.g., `1`)  

The bundle identifier is `com.tacshot.auro`.  Because the identifier never changes, dragging a newer build into `/Applications` **replaces** the existing app rather than creating a duplicate — macOS treats them as the same application.

New releases are published on the [GitHub Releases](https://github.com/TacShot/auro/releases) page.  Each release includes:

- A signed & notarised `.dmg` (when available)  
- A changelog  
- The build number (always incrementing)  

---

## Troubleshooting

**The app opens but shows no audio apps.**  
→ Make sure audio apps are running *before* or *after* opening Auro.  Auro polls for running applications every 2 seconds.

**"Auro.app is damaged and can't be opened."**  
→ Run `xattr -cr /Applications/Auro.app` in Terminal, then try again.

**No audio devices appear.**  
→ Check that your output device is recognised in **System Settings → Sound**.  CoreAudio device enumeration uses the standard hardware property system; third-party virtual devices (e.g. BlackHole) are supported automatically.

**Effects do not seem to apply.**  
→ Ensure the **FX** button is lit (enabled) on the channel strip and that at least one effect toggle is turned on in the Effects panel.

**Menu bar icon is missing.**  
→ If your menu bar is full, try holding **⌘** and dragging icons to make space, or enable **Automatically hide and show the menu bar** in System Settings to reveal hidden icons.

---

## Contributing

Pull requests are welcome!  

1. Fork the repository  
2. Create your feature branch: `git checkout -b feature/amazing-feature`  
3. Commit your changes: `git commit -m 'Add amazing feature'`  
4. Push to the branch: `git push origin feature/amazing-feature`  
5. Open a Pull Request  

Please ensure your Swift code follows the existing style (SwiftUI, `@MainActor`, Combine for observation).

---

## License

Auro is available under the **MIT License**.  See [LICENSE](LICENSE) for details.

---

*Built with ❤️ using Swift, SwiftUI, CoreAudio, and AVFoundation.*