import AppKit

/// Deep-links into the relevant panes of System Settings.
///
/// Opening these URLs via `NSWorkspace` is permitted under the App Sandbox and does **not**
/// require the network entitlement.
enum SystemSettings {
    /// Open System Settings → Privacy & Security → Camera so a denied/undetermined user can
    /// grant access. Tries the newer (macOS 13+) URL first, then the legacy one.
    @MainActor
    static func openCameraPrivacy() {
        openFirst([
            // Newer System Settings (Ventura+).
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Camera",
            // Legacy.
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera",
            "x-apple.systempreferences:Privacy_Camera"
        ])
    }

    /// Open System Settings → Notifications (at Shoo's entry where supported) so a user who
    /// refused notification permission can turn it back on.
    @MainActor
    static func openNotifications() {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        openFirst([
            // Newer System Settings (Ventura+).
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleID)",
            // Legacy.
            "x-apple.systempreferences:com.apple.preference.notifications"
        ])
    }

    /// Open the first URL that System Settings accepts.
    @MainActor
    private static func openFirst(_ candidates: [String]) {
        for string in candidates {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
