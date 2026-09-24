import SwiftUI

/// The privacy policy, bundled in-app and shown as a sheet from Settings → About.
///
/// The canonical copy lives in `docs/PRIVACY.md` (also used for App Store disclosures);
/// keep this text in sync with it.
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Self.sections) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            if let heading = section.heading {
                                Text(heading)
                                    .font(heading == Self.title ? .title2.weight(.semibold) : .headline)
                            }
                            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                                Text(paragraph)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 460, height: 520)
    }

    // MARK: - Content

    private static let title = "Privacy"

    private struct Section: Identifiable {
        let id = UUID()
        let heading: String?
        let paragraphs: [String]
    }

    /// Mirrors `docs/PRIVACY.md`. Plain prose (no markdown bullets) so it renders cleanly here.
    private static let sections: [Section] = [
        Section(heading: title, paragraphs: [
            "Last updated: 24 September 2026.",
            "Shoo is designed to be private by default. It has no account, no analytics, "
                + "and no network access."
        ]),
        Section(heading: "What Shoo does", paragraphs: [
            "Uses the camera only while watching is turned on. Your camera's green light is on "
                + "whenever it does.",
            "Processes each frame entirely on-device using Apple's Vision framework.",
            "From each frame it works out where your face is (a face outline plus the mouth and nose "
                + "area) and where your hands are (fingertip and wrist positions). It uses this only "
                + "to decide whether to show a reminder, keeps it in memory for that one frame, and "
                + "then discards it.",
            "With \"Show camera snapshot in reminder\" on (the default; you can turn it off in "
                + "Settings), the reminder shows a still photo from the camera. The photo is kept in "
                + "memory only while the reminder is on screen and is never saved."
        ]),
        Section(heading: "What Shoo stores on your Mac", paragraphs: [
            "Shoo keeps a few things in its own preferences, inside the app's sandbox: your settings; "
                + "a count of reminders per day, kept for 90 days, for the \"reminders today\" count; "
                + "and the identifier of the camera it last used, so it picks the same camera next time."
        ]),
        Section(heading: "What Shoo does NOT do", paragraphs: [
            "It does not record video or audio, and it does not save any image.",
            "It does not upload, stream, or share any imagery, face or hand data, or anything else. "
                + "The app has no network access.",
            "It does not use face or hand data for advertising, marketing, identification, "
                + "or profiling.",
            "It does not include analytics, tracking, or third-party code."
        ]),
        Section(heading: "Permissions", paragraphs: [
            "Camera: required to notice hand-to-face gestures. macOS asks the first time you "
                + "start watching.",
            "Notifications (optional): only if you turn on \"Show a notification\". macOS asks "
                + "when you do."
        ]),
        Section(heading: "Sandbox", paragraphs: [
            "The app runs in the macOS App Sandbox with only the camera entitlement. "
                + "No network, file, or other device entitlements are requested."
        ]),
        Section(heading: "Contact", paragraphs: [
            "Questions about privacy: open an issue at github.com/jkkronk/shoo/issues."
        ])
    ]
}

#Preview {
    PrivacyPolicyView()
}
