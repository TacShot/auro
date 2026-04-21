import SwiftUI

@main
struct AuroApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsStore = SettingsStore.shared
    @StateObject private var audioEngine   = AudioEngine.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .environmentObject(audioEngine)
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Auro") { appDelegate.showAbout() }
            }
            CommandGroup(after: .appSettings) {
                Button("Preferences…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(settingsStore)
                .environmentObject(audioEngine)
        }
    }
}
