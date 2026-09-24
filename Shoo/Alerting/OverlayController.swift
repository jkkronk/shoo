import AppKit
import SwiftUI

/// Hosts ``OverlayView`` in borderless, non-activating, floating panels: one per display when
/// ``showOnAllScreens`` is on (the default), otherwise one on the display under the mouse.
///
/// Fades in/out (window alpha + content scale), floats above full-screen apps, follows the user
/// across Spaces, and never steals focus. Panels are created lazily and reused between alerts so
/// fade state is easy to manage. They all share one ``OverlayModel``, so every display shows the
/// same reminder, and dismissing it on one display dismisses it everywhere.
@MainActor
final class OverlayController {
    /// Animation timings (seconds). `holdFor(level:)` derives the on-screen hold.
    private enum Timing {
        static let fadeIn: TimeInterval = 0.22
        static let fadeOut: TimeInterval = 0.30
        /// Reduced-motion cross-fade — short, no scale.
        static let reducedFade: TimeInterval = 0.12
        /// Extra hold for `.persistent` escalation.
        static let persistentExtra: TimeInterval = 1.0
    }

    /// Base hold time; updated from `AppSettings.displayDurationSeconds`.
    var displayDuration: TimeInterval = 2.5

    /// When true, a click anywhere on the overlay dismisses it (driven from `clickToDismiss`).
    /// The Snooze and Dismiss buttons work either way.
    var clickToDismiss: Bool = false {
        didSet { model.clickToDismiss = clickToDismiss }
    }

    /// Show the reminder on every connected display (driven from `showOnAllScreens`). When false,
    /// only the display under the mouse pointer gets it.
    var showOnAllScreens: Bool = true

    /// Optional callbacks invoked from overlay affordances (click / Dismiss / Snooze).
    var onDismiss: (() -> Void)?
    var onSnooze: (() -> Void)?

    /// Reused panels. For a reminder shown on `n` displays, the first `n` are in use.
    private var panels: [NSPanel] = []
    private let model = OverlayModel()
    /// In-flight auto-dismiss; cancelled when a new alert arrives so re-fires don't dismiss
    /// the freshly-shown overlay.
    private var dismissTask: Task<Void, Never>?
    private var screenObserver: NSObjectProtocol?
    /// Bumped on every `show()`. A fade-out completion handler captures the value at dismiss
    /// time and bails if it changed, so a re-fire during the fade isn't hidden by the stale
    /// completion of the previous dismiss.
    private var generation = 0

    init() {
        // Re-lay out if the display arrangement changes while the reminder is showing.
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.relayoutIfVisible() }
        }
    }

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
    }

    // MARK: - Show / dismiss

    /// Show the reminder at the given escalation level, fading in and scheduling auto-dismiss.
    /// `snapshot` is a small camera photo shown in place of the hand symbol (nil → the hand).
    func show(level: EscalationLevel = .first, snapshot: NSImage? = nil) {
        dismissTask?.cancel()
        generation &+= 1  // invalidate any pending fade-out completion from a prior dismiss

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        model.reduceMotion = reduceMotion

        // Fresh headline, cheeky line, and snapshot every appearance.
        model.headline = StopMessages.randomHeadline()
        model.message = StopMessages.random()
        model.snapshot = snapshot

        // Windows start transparent; fade alpha to 1. Content scales up unless reduce-motion.
        let shown = layoutPanels()
        for panel in shown {
            panel.alphaValue = 0
            panel.orderFrontRegardless()  // never key/activates — no focus steal
        }
        model.isVisible = false

        let fade = reduceMotion ? Timing.reducedFade : Timing.fadeIn
        NSAnimationContext.runAnimationGroup { context in
            context.duration = fade
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            for panel in shown { panel.animator().alphaValue = 1 }
        }
        // Drive the SwiftUI content transition just after ordering in.
        model.isVisible = true

        scheduleDismiss(after: holdFor(level: level))
    }

    /// Fade the overlay out on every display immediately (e.g. click-to-dismiss). Idempotent.
    func dismiss() {
        dismissTask?.cancel()
        let showing = panels.filter { $0.isVisible }
        guard !showing.isEmpty else { return }

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        model.isVisible = false  // content scales/fades down
        let gen = generation

        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion ? Timing.reducedFade : Timing.fadeOut
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            for panel in showing { panel.animator().alphaValue = 0 }
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                // If a newer show() ran during the fade, it bumped `generation` — don't hide the
                // freshly re-displayed overlay.
                guard let self, self.generation == gen else { return }
                for panel in self.panels {
                    panel.alphaValue = 0
                    panel.orderOut(nil)
                }
            }
        }
    }

    // MARK: - Scheduling

    private func scheduleDismiss(after seconds: TimeInterval) {
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    private func holdFor(level: EscalationLevel) -> TimeInterval {
        switch level {
        case .first: return displayDuration
        case .persistent: return displayDuration + Timing.persistentExtra
        }
    }

    // MARK: - Panel lifecycle

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 180),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // `.screenSaver` reliably floats above full-screen apps while staying below the
        // actual screen saver / login window.
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        // Takes clicks so its Snooze/Dismiss buttons work. The panel is non-activating and can't
        // become key, so clicking it never pulls focus from the app the user is in.
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        // Keep the reminder, and any camera snapshot in it, out of screen sharing, recordings and
        // screenshots wherever macOS honors this.
        panel.sharingType = .none

        let root = OverlayView(
            model: model,
            onDismiss: { [weak self] in self?.handleDismissTap() },
            onSnooze: { [weak self] in self?.handleSnoozeTap() }
        )
        panel.contentView = FirstMouseHostingView(rootView: root)
        return panel
    }

    private func handleDismissTap() {
        onDismiss?()
        dismiss()
    }

    private func handleSnoozeTap() {
        onSnooze?()
        dismiss()
    }

    // MARK: - Multi-display targeting

    /// The displays to show on: all of them, or just the one under the mouse pointer.
    /// Re-resolved on every show so display rearrangement is handled automatically.
    private func targetScreens() -> [NSScreen] {
        if showOnAllScreens { return NSScreen.screens }
        return targetScreen().map { [$0] } ?? []
    }

    /// The single display to use when not showing on all of them: the screen under the mouse,
    /// then `NSScreen.main`, then the first screen.
    func targetScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        if let underMouse = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
            return underMouse
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    /// Give each target display a panel (creating more when needed) centred on it, and hide
    /// panels left over from displays no longer in use. Returns the panels in use.
    private func layoutPanels() -> [NSPanel] {
        let screens = targetScreens()
        while panels.count < screens.count {
            panels.append(makePanel())
        }
        for (panel, screen) in zip(panels, screens) {
            position(panel, on: screen)
        }
        for panel in panels.dropFirst(screens.count) where panel.isVisible {
            panel.orderOut(nil)
        }
        return Array(panels.prefix(screens.count))
    }

    /// Center the panel within the display's `visibleFrame`, nudged ~8% above center so it sits
    /// slightly high (more glanceable) and clear of the menu bar.
    private func position(_ panel: NSPanel, on screen: NSScreen) {
        panel.layoutIfNeeded()  // settle the SwiftUI content's size before centring
        let frame = screen.visibleFrame
        let size = panel.frame.size
        // Center, nudged ~8% high, then clamp so the panel stays fully on a short display.
        let rawX = frame.midX - size.width / 2
        let rawY = frame.midY - size.height / 2 + frame.height * 0.08
        let origin = NSPoint(
            x: min(max(rawX, frame.minX), max(frame.minX, frame.maxX - size.width)),
            y: min(max(rawY, frame.minY), max(frame.minY, frame.maxY - size.height))
        )
        panel.setFrameOrigin(origin)
    }

    /// If the display arrangement changed mid-show, re-centre on the current displays and give
    /// a newly connected display its own copy of the reminder.
    private func relayoutIfVisible() {
        guard panels.contains(where: { $0.isVisible }) else { return }
        for panel in layoutPanels() where !panel.isVisible {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
        }
    }
}

extension OverlayController: OverlayPresenting {}

/// Hands the first click straight to the SwiftUI buttons. The overlay panel never becomes key,
/// so without this a click would be spent on the window instead of the button under it.
private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
