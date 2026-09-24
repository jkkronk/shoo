import AppKit

/// Minimal `NSApplicationDelegate` for the launch-time work SwiftUI scenes can't do in an
/// `LSUIElement` app: open first-run onboarding (otherwise the app shows no window at all),
/// resume watching when the user opted in, and answer a relaunch from Finder or Spotlight.
@MainActor
final class ShooAppDelegate: NSObject, NSApplicationDelegate {
    /// The same instance the SwiftUI scenes observe. It's created on first use, so it's ready
    /// here even though no menu content has appeared yet.
    private var appState: AppState { .shared }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Unit tests run hosted in the app: don't open onboarding or start the camera under them.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        appState.handleLaunch()
        // Pick up permission/login-item changes whenever we come forward.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    /// Relaunching a running menu-bar app otherwise does nothing visible.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        appState.handleReopen()
        return false
    }

    @objc private func didBecomeActive() {
        appState.refreshCameraStatus()
    }
}
