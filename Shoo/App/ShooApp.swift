import SwiftUI

/// Entry point. Shoo is a menu-bar agent (no dock icon — see `LSUIElement` in Info.plist).
///
/// The app runs on a single ``AppState`` (``AppState/shared``) that wires the camera → detector →
/// alert pipeline. The UI is a `MenuBarExtra` and a standard `Settings` scene; first-run
/// onboarding is an AppKit-hosted window that ``ShooAppDelegate`` opens at launch.
@main
struct ShooApp: App {
    @NSApplicationDelegateAdaptor(ShooAppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra("Shoo", systemImage: appState.menuBarSymbolName) {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
