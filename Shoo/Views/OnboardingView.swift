import AppKit
import AVFoundation
import SwiftUI

/// First-run onboarding + camera-permission priming, shown in an AppKit-hosted window (see
/// ``OnboardingWindow``) while the app temporarily runs as `.regular`.
///
/// A simple paged step machine: Welcome → Privacy → Camera access → All set. The macOS camera
/// prompt fires only at the camera step's "Continue" tap — never on launch.
struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState

    private enum Step: Int {
        case welcome, privacy, camera, done
    }

    @State private var step: Step = .welcome
    @State private var requesting = false
    @State private var cameraOutcome: CameraPermission.Status?

    var body: some View {
        VStack(spacing: 24) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            controls
        }
        .padding(32)
        .frame(width: 460, height: 420)
    }

    // MARK: - Step content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            stepBody(
                symbol: "hand.raised.fill",
                title: "Welcome to Shoo",
                message: "Shoo gently reminds you when you bring your hands to your face — "
                    + "to help you stop nail-biting and other nervous habits."
            )
        case .privacy:
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("Private by design")
                    .font(.title2.weight(.semibold))
                VStack(alignment: .leading, spacing: 8) {
                    privacyBullet("All processing happens on-device with Apple Vision.")
                    privacyBullet("Nothing is ever recorded or saved.")
                    privacyBullet("No network access — your video never leaves your Mac.")
                    privacyBullet("Your camera's green light is on whenever Shoo is watching.")
                    privacyBullet("Sandboxed and built for the Mac App Store.")
                }
            }
        case .camera:
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("Enable camera access")
                    .font(.title2.weight(.semibold))
                Text("Shoo needs to see your webcam to notice face-touching. macOS will ask for permission next.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                if let outcome = cameraOutcome, outcome != .authorized {
                    deniedNotice
                }
            }
        case .done:
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("You're all set")
                    .font(.title2.weight(.semibold))
                let icon = Image(systemName: "hand.raised.fill")
                Text("Shoo lives in your menu bar. Look for \(icon) at the top of your screen.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Toggle("Start watching now and at every launch", isOn: Binding(
                    get: { appState.settings.startWatchingOnLaunch },
                    set: { appState.settings.startWatchingOnLaunch = $0 }
                ))
                .toggleStyle(.switch)
                .padding(.top, 8)
            }
        }
    }

    private func stepBody(symbol: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private func privacyBullet(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.primary)
    }

    private var deniedNotice: some View {
        VStack(spacing: 8) {
            Text("Camera access was not granted.")
                .foregroundStyle(.secondary)
            Button("Open System Settings") {
                SystemSettings.openCameraPrivacy()
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Controls

    @ViewBuilder
    private var controls: some View {
        switch step {
        case .welcome:
            Button("Continue") { step = .privacy }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
        case .privacy:
            HStack {
                Button("Back") { step = .welcome }
                Button("Continue") { step = .camera }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
            }
        case .camera:
            if cameraOutcome == nil {
                // Apple's guidance for a screen shown before a permission prompt: one button that
                // leads to the system prompt, labelled "Continue" — not "Allow" or anything similar.
                Button("Continue") {
                    requestAccess()
                }
                .disabled(requesting)
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            } else {
                Button("Continue") { step = .done }
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
            }
        case .done:
            Button("Done") { appState.completeOnboarding() }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
        }
    }

    // MARK: - Actions

    private func requestAccess() {
        requesting = true
        Task {
            await appState.requestCameraAccess()
            cameraOutcome = appState.cameraStatus
            requesting = false
            if appState.cameraStatus == .authorized {
                step = .done
            }
        }
    }
}

/// Hosts ``OnboardingView`` in a plain AppKit window. AppKit rather than a SwiftUI `Window`
/// scene because onboarding has to open from `applicationDidFinishLaunching`, before any SwiftUI
/// view exists to hand out an `openWindow` action. ``AppState`` owns the window and tracks it by
/// identity so the activation policy reverts once it closes.
@MainActor
enum OnboardingWindow {
    static func make(appState: AppState) -> NSWindow {
        let window = NSWindow(
            contentViewController: NSHostingController(
                rootView: OnboardingView().environmentObject(appState)))
        window.title = "Welcome to Shoo"
        window.styleMask = [.titled, .closable]
        // AppState holds the only strong reference; AppKit also releasing it on close would
        // over-release it.
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
