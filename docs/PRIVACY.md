# Privacy

_Last updated: 24 September 2026_

Shoo is designed to be private by default. It has no account, no analytics, and no network access.

## What Shoo does

- Uses the camera **only** while watching is turned on. Your camera's green light is on whenever it does.
- Processes each frame **entirely on-device** using Apple's Vision framework.
- From each frame it works out where your face is (a face outline plus the mouth and nose area) and where your hands are (fingertip and wrist positions). It uses this **only** to decide whether to show a reminder, keeps it in memory for that one frame, and then discards it.
- If you turn on **Show camera snapshot in reminder** (off by default), the reminder shows a still photo from the camera. The photo is kept in memory only while the reminder is on screen and is never saved.

## What Shoo stores on your Mac

Shoo keeps a few things in its own preferences (`UserDefaults`, inside the app's sandbox):

- your settings (sensitivity, timing, reminder options, launch at login, and so on);
- a count of reminders per day, kept for 90 days, for the "reminders today" count in the menu;
- the identifier of the camera it last used, so it picks the same camera next time.

## What Shoo does NOT do

- It does **not** record video or audio, and it does **not** save any image.
- It does **not** upload, stream, or share any imagery, face or hand data, or anything else. The app has no network access.
- It does **not** use face or hand data for advertising, marketing, identification, or profiling.
- It does **not** include analytics, tracking, or third-party code.

## Permissions

- **Camera** (`NSCameraUsageDescription`): required to notice hand-to-face gestures. macOS asks the first time you start watching.
- **Notifications** (optional): only if you turn on "Show a notification". macOS asks when you do.

## App Store privacy disclosures

When filling out App Store Connect's privacy questionnaire, the intended answers are:

- **Data collection:** None.
- **Data linked to you:** None.
- **Data used to track you:** None.

Camera input is used transiently in memory and never leaves the device, so it does not constitute "data collection" under Apple's definition. If this changes (e.g. opt-in diagnostics are ever added), this document and the disclosures must be updated first.

## Sandbox

The app runs in the macOS App Sandbox with only the camera entitlement
(`com.apple.security.device.camera`). No network, file, or other device
entitlements are requested.

## Contact

Questions about privacy: open an issue at <https://github.com/jkkronk/shoo/issues>.
