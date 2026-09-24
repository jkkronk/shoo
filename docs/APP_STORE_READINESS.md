# Shoo: Mac App Store readiness report

_Reviewed `master` at `64ee00f` on 2026-09-24. I read every Swift file in `Shoo/`, the test target, `project.yml`, Info.plist, the entitlements, the privacy manifest, CI, fastlane, the scripts and the docs. Apple's requirements were checked against Apple's own pages; links are inline._

_What I didn't do: build or run the app. This machine has only the Command Line Tools, not Xcode. So the runtime behavior described below comes from reading the code. P0-5 includes a quick way to check it, and [Appendix B](#appendix-b-pre-submission-checks) covers checking the rest on a real build._

---

## Summary

The foundation suits the Mac App Store. Shoo is sandboxed with only the camera entitlement and has no network access. It ships a privacy manifest and a clear camera purpose string, and it asks for the camera only after the user acts. Launch at login uses `SMAppService` and is off by default. The export-compliance key is set, and 132 unit tests cover the detection and alerting logic.

Three things stand in the way of a submission:

1. **The distribution setup was never built.** There's no team, no signing and no upload path, and CI runs on a GitHub runner that's retired on 2 November.
2. **Some Apple policy problems.** The most serious is that the app icon is Apple's ✋ emoji (since replaced, see [P0-3](#p0-3-the-app-icon-is-apples--emoji)).
3. **Bugs in first launch and settings that a reviewer will hit within minutes.** The worst one: on a fresh install the app shows no window at all.

| ID | Problem | Priority | Status |
|---|---|---|---|
| [P0-1](#p0-1-no-signing-archive-or-upload-pipeline) | No signing, archive or upload pipeline | Blocker | Open |
| [P0-2](#p0-2-lsapplicationcategorytype-is-missing-so-the-upload-is-rejected-itms-90242) | `LSApplicationCategoryType` is missing, so the upload is rejected (ITMS-90242) | Blocker | Open (depends on your category choice) |
| [P0-3](#p0-3-the-app-icon-is-apples--emoji) | The app icon is Apple's ✋ emoji (guideline 5.2.5) | Blocker | Partly: replaced with an original blue hand (`scripts/draw-appicon.swift`); still needs an Icon Composer version for macOS 26+ |
| [P0-4](#p0-4-move-to-xcode-26) | Move to Xcode 26: the `macos-14` CI runner is retired on 2 Nov 2026, and the icon fix needs Xcode 26 | Blocker | **Fixed in CI**: `macos-26` with Xcode 26.6. Build locally with Xcode 26 too |
| [P0-5](#p0-5-a-fresh-install-shows-no-ui-because-onboarding-never-opens) | A fresh install shows no UI because onboarding never opens (guideline 2.1) | Blocker in practice | **Fixed** |
| [P0-6](#p0-6-the-app-store-connect-listing-doesnt-exist-yet) | The App Store Connect listing is missing: privacy URL, support URL, screenshots, review notes | Blocker | Open |
| [P1-1](#p1-1-the-overlays-snooze-and-dismiss-buttons-cant-be-clicked-with-default-settings) | The overlay's Snooze and Dismiss buttons can't be clicked with default settings | Fix before submitting | **Fixed** |
| [P1-2](#p1-2-show-a-notification-never-asks-for-permission-so-it-never-works) | "Show a notification" never asks for permission, so it never works | Fix before submitting | **Fixed** |
| [P1-3](#p1-3-start-watching-on-launch-is-ignored-at-launch) | "Start watching on launch" is ignored at launch | Fix before submitting | **Fixed** |
| [P1-4](#p1-4-escalation-plays-a-sound-even-when-play-a-sound-is-off) | Escalation plays a sound even when "Play a sound" is off | Fix before submitting | **Fixed** |
| [P1-5](#p1-5-camera-permission-priming-screen-wording) | Button wording on the camera-permission priming screen (guideline 5.1.1) | Fix before submitting | **Fixed** (the close button stays enabled on the camera step) |
| [P1-6](#p1-6-give-the-reviewer-a-way-to-see-the-app-work) | The reviewer has no way to see the app work without a real trigger | Fix before submitting | Partly: *Preview Reminder* added; description and demo video still to do |
| [P1-7](#p1-7-make-the-privacy-policy-complete-and-host-it) | The privacy policy is incomplete and not hosted | Fix before submitting | Partly: text updated in the app and `docs/PRIVACY.md`; still needs hosting |
| [P1-8](#p1-8-the-camera-snapshot-is-on-by-default-and-shows-up-in-screen-shares) | The camera snapshot is on by default and shows up in screen shares | Fix before submitting | Partly: the overlay is kept out of screen capture; the snapshot stays **on by default** (product decision) |
| [P1-9](#p1-9-keep-the-marketing-claims-accurate-and-non-medical) | Keep the marketing claims accurate and non-medical (guidelines 1.4.1 and 2.3.1) | Fix before submitting | Partly: onboarding now mentions the camera light; listing text is yours |
| [P2-*](#p2-should-fix-quality-ratings-robustness) | Features with no UI, camera choice, energy use, a rare frame-rate crash, discoverability, localization, copyright | Should fix | P2-4 (frame-rate crash) **fixed**; the rest open |
| [P3-*](#p3-hygiene) | CI, deprecated API, Swift 6 readiness, dead code, stale docs, two builds sharing one bundle ID | Nice to have | Open |

**Fixes, 2026-09-24 (uncommitted):**
- **Onboarding:** opens by itself at launch. Relaunching the running app opens onboarding or Settings.
- **Start watching on launch:** now works, and never shows the camera prompt at launch.
- **Overlay:** the buttons can be clicked, and "Click overlay to dismiss" works.
- **Notifications:** turning them on asks for permission.
- **Escalation:** no sound unless "Play a sound" is on.
- **Camera permission:** the button on the priming screen says "Continue".
- **Preview Reminder:** new button in Settings.
- **Privacy policy:** updated in the app and in `docs/PRIVACY.md`.
- **Snapshot:** the overlay is kept out of screen capture. The snapshot itself stays on by default.
- **Overlay hand:** when there's no snapshot, the overlay now shows a blue hand symbol instead of the yellow ✋ emoji.
- **App icon:** now an original blue hand drawn from basic shapes, not the Apple emoji. `scripts/draw-appicon.swift` regenerates it. SF Symbols can't be used in app icons, so it isn't the overlay's symbol.
- **All displays:** the reminder shows on every display by default. Settings → "Show on all displays" limits it to the display with the pointer.
- **CI:** now runs on `macos-26` with Xcode 26.6.
- **Frame-rate crash:** fixed for cameras with fractional rates such as 29.97 fps.

**Verification:** there's no Xcode on the review machine, so everything was checked with the Command Line Tools:
- The app compiles with no new warnings.
- All 138 unit tests pass: the 132 existing ones plus 6 new launch and onboarding tests, run against a stand-in for XCTest.
- CI's SwiftLint 0.57.0 reports 0 violations in strict mode.
- A sandboxed test build was launched on macOS 27 to confirm the launch, relaunch, onboarding-close and overlay-click behavior.

**Priority key.** **P0**: the upload fails or review is very likely to reject. **P1**: a bug the reviewer will see, or a likely rejection reason. **P2**: user-facing quality, ratings and privacy optics. **P3**: hygiene.

---

## P0: Blockers

### P0-1 No signing, archive or upload pipeline

**Where:** [`project.yml:18`](../project.yml#L18) has `DEVELOPMENT_TEAM: ""`. The `release` lane at [`fastlane/Fastfile:44-48`](../fastlane/Fastfile#L44-L48) fails on purpose. [`release.yml`](../.github/workflows/release.yml) only builds an unsigned archive, and [`scripts/package.sh`](../scripts/package.sh) produces ad-hoc-signed zips for GitHub.

**What's needed:**

1. **Join the Apple Developer Program.** Enrolling as an organization shows the company as the seller and needs a D-U-N-S number. Enrolling as an individual shows your name.
2. **Choose the permanent bundle ID now.** It can never change after the first upload. `com.shoo.Shoo` suggests you own `shoo.com`, so use a domain you control, for example `io.github.jkkronk.shoo` or your company's domain. Then:
   - update [`project.yml:6`](../project.yml#L6), [`:33`](../project.yml#L33) and [`:50`](../project.yml#L50);
   - replace the hard-coded `com.shoo` strings in [`AppLogger.swift:6`](../Shoo/Support/AppLogger.swift#L6), [`NotificationAlerter.swift:12`](../Shoo/Alerting/NotificationAlerter.swift#L12), [`CameraController.swift:26`](../Shoo/Camera/CameraController.swift#L26) and [`HandFaceDetector.swift:16`](../Shoo/Detection/HandFaceDetector.swift#L16). Better still, derive them from `Bundle.main.bundleIdentifier`.
3. **Register the App ID and create the app record in App Store Connect.** Reserve the name early. A different, paid Mac utility called **"Shoo!"** already exists: it locks apps behind Touch ID and is sold outside the App Store ([shooapp.com](https://shooapp.com/)). The App Store name may still be free, but expect confusion in search and possible trademark friction. A more distinctive store name, such as "Shoo: Hands Off Your Face", avoids both.
4. **Sign and upload.** Set `DEVELOPMENT_TEAM`, archive with the Release configuration, and export an App Store `.pkg` using an `ExportOptions.plist` with `method` set to `app-store-connect`.
   - For the first upload, Xcode Organizer is easiest.
   - For CI, use `xcodebuild -exportArchive` with `destination` set to `upload` and an App Store Connect API key (`-authenticationKeyPath`, `-authenticationKeyID`, `-authenticationKeyIssuerID`), or fastlane `deliver`.
   - CI also needs manual signing: an Apple Distribution certificate, a Mac Installer Distribution certificate for the `.pkg`, and a Mac App Store provisioning profile.
5. **Automate versioning.** Every upload needs a higher `CURRENT_PROJECT_VERSION`, so replace the `bump` lane stub. Consider `MARKETING_VERSION: 1.0.0` for launch; `0.1.0` is allowed but looks like a beta on a store page.

### P0-2 `LSApplicationCategoryType` is missing, so the upload is rejected (ITMS-90242)

**Where:** [`Shoo/Info.plist`](../Shoo/Info.plist) doesn't have the key, and `project.yml` doesn't set it either.

**Why it matters:** Mac App Store uploads must declare a category UTI in Info.plist. Without it, App Store Connect rejects the upload with ITMS-90242 ([Apple: LSApplicationCategoryType](https://developer.apple.com/documentation/bundleresources/information-property-list/lsapplicationcategorytype)).

**Fix:** add the key to the plist. Use the value that matches the primary category you'll choose in App Store Connect:

```xml
<key>LSApplicationCategoryType</key>
<string>public.app-category.healthcare-fitness</string>  <!-- or public.app-category.productivity -->
```

A related gotcha: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` at [`project.yml:23`](../project.yml#L23) has no effect. The app target uses a hand-written Info.plist and doesn't enable `GENERATE_INFOPLIST_FILE`. The encryption key already sits in the plist, so nothing is broken, but new keys must go into `Shoo/Info.plist` itself, not into `INFOPLIST_KEY_*` settings.

### P0-3 The app icon is Apple's ✋ emoji

**Where:** [`art/AppIcon-1024.png`](../art/AppIcon-1024.png) and the PNGs generated from it in `Shoo/Resources/Assets.xcassets/AppIcon.appiconset/` by [`scripts/make-appicon.sh`](../scripts/make-appicon.sh).

**Evidence:** I rendered U+270B in Apple Color Emoji on this Mac. The icon's hand matches it: same outline, finger lengths, thumb and shading.

**Why it matters:** guideline 5.2.5 says apps "may not include Apple emoji" ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/#intellectual-property)). Emoji typed as text and rendered by the system at runtime are fine: the ✋ in the notification title can stay. (The reminder overlay now uses a blue SF Symbol hand instead of the emoji.) Emoji artwork baked into the bundle is not allowed. The icon also looks soft at 512 and 1024 px because it was scaled up from the emoji bitmap.

**Fix:**
- Commission or draw an original hand/stop mark. SF Symbols are licensed for in-app UI but not for app icons, so `hand.raised` can't be the icon either.
- **Build it in Icon Composer** as `AppIcon.icon` ([Apple guide](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)), not as PNGs:
  - macOS 26 shrinks legacy icons into a gray rounded-square backdrop ([HIG: App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons), [example](https://lapcatsoftware.com/articles/2025/6/2.html)). That includes icons drawn to the Big Sur template, which this one is: an 824×824 plate with 100 px margins.
  - Naming it `AppIcon.icon` matches the existing `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`, so no build-setting change is needed.
  - Xcode 26 generates the images for older macOS versions from the `.icon` file.
  - XcodeGen picks up `.icon` files from [2.45.1](https://github.com/yonaskolb/XcodeGen/blob/master/CHANGELOG.md).
- Keep a 1024 px PNG export for marketing.
- Keep Apple emoji imagery out of the App Store screenshots too.

### P0-4 Move to Xcode 26

**Where:** [`ci.yml:15,28`](../.github/workflows/ci.yml#L15) and [`release.yml:12,19`](../.github/workflows/release.yml#L12) use the `macos-14` runner with Xcode 16.2. The README says "Xcode 16 or later".

**What Apple requires:** since 28 Apr 2026, uploads need Xcode 26 and the 26 SDKs, but the rule only names iOS, iPadOS, tvOS, visionOS and watchOS, not macOS ([Apple, Feb 2026](https://developer.apple.com/news/?id=ueeok6yw)). The announced April 2027 step to the 27 SDKs also leaves out macOS ([Apple, Sep 2026](https://developer.apple.com/news/?id=k1mtkt1k)). So an Xcode 16 Mac build may still upload today; only a test upload can confirm it.

**Why it's still a blocker:**
- **The CI stops working.** The `macos-14` runner, the only GitHub image with Xcode 16.2, is deprecated ([runner-images#13518](https://github.com/actions/runner-images/issues/13518)):
  - brownouts, where jobs fail between 14:00 and 00:00 UTC, on 5, 12, 16, 19, 23, 26, 29 and 30 October;
  - unsupported from **2 November 2026**.
- **The icon fix needs it.** The Icon Composer icon from [P0-3](#p0-3-the-app-icon-is-apples--emoji) requires Xcode 26.

**Fix:**
- Switch `runs-on` to `macos-26` in both workflows. It has Xcode 26.0.1–26.6, with 26.6 as default. An `xcode-27` preview label exists if you want to follow Xcode 27.
- Build locally with the same Xcode.
- Walk through the UI again on macOS 26 and 27. Building with the new SDK switches the popover, Settings and onboarding to the new system design, and fixed sizes such as the 460×420 onboarding window and the 270 pt popover may need adjusting.
- You can keep the macOS 14 deployment target, but then test on macOS 14 too.

### P0-5 A fresh install shows no UI because onboarding never opens

**Where:** [`ShooAppDelegate.swift:24-36`](../Shoo/App/ShooAppDelegate.swift#L24-L36), [`ShooApp.swift:19`](../Shoo/App/ShooApp.swift#L19) and [`:39-45`](../Shoo/App/ShooApp.swift#L39-L45), and [`MenuBarView.swift:25-33`](../Shoo/Views/MenuBarView.swift#L25-L33).

**What goes wrong:**
- `applicationDidFinishLaunching` starts with `guard let appState else { return }`.
- `appDelegate.appState` is only set in `wireWindowActions()`, which runs from the menu content's `.onAppear`. A `.window`-style `MenuBarExtra` doesn't create its content until the user clicks the menu-bar icon. `windowOpener.open` is also only captured there.
- So at launch the guard returns early. Onboarding is skipped, and the `didBecomeActive` observer is never installed.
- After the user finally opens the menu, nothing checks `hasOnboarded` again. Onboarding then only appears through Settings → "Show onboarding again".

**Why it matters:** an App Reviewer launches Shoo and sees no window and no Dock icon (the app is `LSUIElement`). There's only a small glyph in a crowded menu bar, which may be hidden behind the notch. That's the classic rejection for "we couldn't find the app's UI", and it's exactly what onboarding was meant to prevent.

**Fix:**
- Create `AppState` in the app delegate so it exists at launch, and have `ShooApp` read it from there.
- In `applicationDidFinishLaunching`, show onboarding in an AppKit-hosted window, e.g. `NSWindow(contentViewController: NSHostingController(rootView: OnboardingView().environmentObject(appState)))`. Don't rely on a SwiftUI `openWindow` captured from a view that doesn't exist yet.
- Implement `applicationShouldHandleReopen(_:hasVisibleWindows:)`. When the user launches the app again from Finder, Spotlight or Launchpad, open Settings, or onboarding if it isn't finished. That's the first thing a confused reviewer tries.
- End onboarding by pointing to the menu-bar icon: "Shoo lives in your menu bar ↗". Also mention that the icon can be hidden behind the notch.

**Check:** quit Shoo, run `defaults delete ~/Library/Containers/com.shoo.Shoo/Data/Library/Preferences/com.shoo.Shoo` (sandboxed apps keep their settings in their container; use your final bundle ID), then launch it again.

### P0-6 The App Store Connect listing doesn't exist yet

These are required before you can submit. Section [App Store Connect checklist](#app-store-connect-checklist) has suggested values.

- **Privacy policy URL.** Required for every app, even one that collects nothing ([Apple](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)). Guideline 5.1.1(i) also wants it easy to reach from inside the app. `docs/PRIVACY.md` exists but isn't hosted anywhere; GitHub Pages on this public repo is enough. See [P1-7](#p1-7-make-the-privacy-policy-complete-and-host-it) for what the policy is missing.
- **Support URL.** Required, and it must lead to real contact information ([Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)). A small page with an email address, or the GitHub Issues page, works.
- **Screenshots.** Mac apps need 1–10 screenshots in 16:10: 1280×800, 1440×900, 2560×1600 or 2880×1800 ([Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)). [`art/overlay-screenshot.png`](../art/overlay-screenshot.png) is 980×748, and it shows an illustration where the real app shows a camera photo.
- **Age rating.** The questionnaire was reworked in July 2025: new 13+/16+/18+ tiers, plus required questions that include medical and wellness topics ([Apple](https://developer.apple.com/news/?id=ks775ehf)). Social-media questions became required in September 2026 ([Apple](https://developer.apple.com/news/?id=tlur8uvi)). Answering yes on health or wellness topics can move Shoo from 4+ to 9+.
- **EU trader status.** Under the Digital Services Act you must declare "trader" or "not a trader", or the app isn't offered in the EU ([Apple](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)). "Not a trader" is allowed for non-commercial developers. Traders must publish a verified address, phone number and email on the EU product page.
- **Regulated medical device declaration**, if you pick Health & Fitness as the category. See [P1-9](#p1-9-keep-the-marketing-claims-accurate-and-non-medical).
- **Other listing fields:** App Privacy ("Data Not Collected" is correct), category, copyright, subtitle, description, keywords and price.
- **Review notes and a demo video.** There's a draft in [Appendix A](#appendix-a-review-notes-draft).

---

## P1: Fix before submitting

### P1-1 The overlay's Snooze and Dismiss buttons can't be clicked with default settings

**Where:** [`OverlayController.swift:26-28`](../Shoo/Alerting/OverlayController.swift#L26-L28) and [`:153`](../Shoo/Alerting/OverlayController.swift#L153) set `ignoresMouseEvents = !clickToDismiss`, and `clickToDismiss` defaults to `false` ([`AppSettings.swift:67`](../Shoo/Models/AppSettings.swift#L67)). Meanwhile [`OverlayView.swift:50-61`](../Shoo/Alerting/OverlayView.swift#L50-L61) always draws the buttons.

**Why it matters:** a window with `ignoresMouseEvents = true` passes every click through, including clicks on its own buttons. The README screenshot shows these buttons, so a reviewer will try them.

**Fix:** pick one of these:
- keep the panel click-through and hide the buttons in that mode; or
- always accept mouse events, and make only "click anywhere to dismiss" optional.

Also check that the first click works on a borderless, non-activating panel. It can't become key, so SwiftUI buttons may need `acceptsFirstMouse`.

### P1-2 "Show a notification" never asks for permission, so it never works

**Where:** the toggle at [`SettingsView.swift:89`](../Shoo/Views/SettingsView.swift#L89) only flips the setting. The permission request path ([`AppState.swift:233-235`](../Shoo/App/AppState.swift#L233-L235) → [`AlertPresenter.swift:103-105`](../Shoo/Alerting/AlertPresenter.swift#L103-L105) → [`NotificationAlerter.swift:27`](../Shoo/Alerting/NotificationAlerter.swift#L27)) is never called. `post()` does nothing while the app isn't authorized ([`NotificationAlerter.swift:60-61`](../Shoo/Alerting/NotificationAlerter.swift#L60-L61)).

**Fix:** when the toggle turns on, call `await appState.requestNotificationAuthorization()`. If the user denies it, turn the toggle back off and explain how to allow notifications in System Settings → Notifications.

### P1-3 "Start watching on launch" is ignored at launch

**Where:** the setting defaults to `true` ([`AppSettings.swift:71`](../Shoo/Models/AppSettings.swift#L71)), `isWatching` starts as `false` ([`AppState.swift:18`](../Shoo/App/AppState.swift#L18)), and no launch path calls `startWatching()`. The setting is only read after a camera permission is granted ([`AppState.swift:308`](../Shoo/App/AppState.swift#L308)) and at the end of onboarding ([`OnboardingView.swift:185-189`](../Shoo/Views/OnboardingView.swift#L185-L189)).

**Why it matters:** with "Launch at login" on, Shoo starts after every reboot but doesn't watch until the user opens the menu. The setting looks broken.

**Fix:** in the new launch path from [P0-5](#p0-5-a-fresh-install-shows-no-ui-because-onboarding-never-opens), call `startWatching()` when `hasOnboarded`, `startWatchingOnLaunch` and camera authorization are all true. Never trigger the camera prompt at launch.

### P1-4 Escalation plays a sound even when "Play a sound" is off

**Where:** [`AlertPresenter.swift:84`](../Shoo/Alerting/AlertPresenter.swift#L84) plays a sound when `settings.soundEnabled || level == .persistent`. Escalation is on by default ([`AppSettings.swift:68`](../Shoo/Models/AppSettings.swift#L68)), and there's been no Settings control for it since the tabbed Settings window was removed in `b2a784b`.

**Why it matters:** a menu-bar app that makes a sound in a meeting after the user turned sound off looks like a bug, and the user has no way to stop it.

**Fix:** pick one of these:
- respect the sound toggle and make escalation visual only, with a longer hold or stronger styling; or
- add an "Escalate if it continues" toggle with a clear description.

### P1-5 Camera-permission priming screen wording

**Where:** the button on onboarding's camera step says "Enable Camera Access" ([`OnboardingView.swift:141`](../Shoo/Views/OnboardingView.swift#L141)). The menu's call to action says "Grant Camera Access" ([`MenuBarView.swift:75`](../Shoo/Views/MenuBarView.swift#L75)).

**What Apple asks:** for a screen shown before a permission alert, Apple's HIG asks for one button that clearly leads to the system alert, labelled "Continue" or "Next". The label shouldn't be "Allow" or anything close in meaning, and there should be no other actions such as close or cancel ([HIG: Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)). App Review enforces this under 5.1.1. For example, an app was rejected for a button labelled "Configure Location Access" and told to use Continue/Next ([forum thread](https://developer.apple.com/forums/thread/757532)). "Enable…" and "Grant…" are close enough to "Allow" to be risky.

**Fix:**
- **Onboarding:** relabel the button "Continue".
- **Menu:** remove the separate "Grant Camera Access" button. Let the normal "Watch for face-touching" toggle start watching, which triggers the system prompt, or reopen onboarding.
- **Lower-confidence risk:** the onboarding window can be closed before the prompt appears ([`ShooApp.swift:23`](../Shoo/App/ShooApp.swift#L23)), which might count as a way around it. Consider disabling the close button on the camera step.

### P1-6 Give the reviewer a way to see the app work

- **Add a "Preview reminder" button** in Settings, and optionally in the menu, that calls `AppState.fireAlert()`. That method already exists ([`AppState.swift:224`](../Shoo/App/AppState.swift#L224)) but nothing calls it. Reviewers can then see the overlay without acting out the habit on camera, and users can try settings like display duration and the snapshot.
- **Not every Mac has a camera.** Reviewers may test on a Mac without one, such as a Mac mini or Mac Studio, where Shoo only shows "No camera found". State "Requires a Mac with a camera" in the description and the review notes, and put a short demo video link in the review notes.

### P1-7 Make the privacy policy complete and host it

**Where:** [`docs/PRIVACY.md:16`](PRIVACY.md) and [`PrivacyPolicyView.swift:69-70`](../Shoo/Views/PrivacyPolicyView.swift#L69-L70) say the only data kept is "sensitivity, cooldown, launch-at-login".

**What's actually stored**, all in `UserDefaults`:
- about 18 settings;
- a per-day count of reminders, kept for 90 days ([`CatchStats.swift`](../Shoo/Models/CatchStats.swift), key `catchStats`);
- the chosen camera's device ID ([`CameraController.swift:191`](../Shoo/Camera/CameraController.swift#L191)).

None of it leaves the Mac, so "Data Not Collected" is still the right App Privacy answer. The policy should still say what's stored.

**Add these sections to both copies of the policy:**
- **Face and hand data.** Apple's Developer Program License Agreement (§3.3.3(K)) counts face landmarks obtained through the camera APIs as "face data", not only TrueDepth data. It requires telling users how that data is used and getting clear consent first ([DPLA](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/)). Guideline 5.1.2(vi) bans using it for advertising or data mining ([guidelines](https://developer.apple.com/app-store/review/guidelines/#data-use-and-sharing)). Say it plainly: for each frame Shoo computes a face box, the mouth and nose landmarks, and the hand-joint positions. It uses them only to decide whether to show a reminder. It keeps them in memory for one frame and never writes them to disk or shares them.
  
  The consent part is also why [P0-5](#p0-5-a-fresh-install-shows-no-ui-because-onboarding-never-opens) matters: today a user can grant camera access from the menu without ever seeing onboarding's privacy page.
- **The reminder snapshot.** The overlay shows a still frame from the camera; it's held in memory only while the overlay is visible.
- **Contact and effective date.**

**Hosting:** publish the policy at a stable URL (GitHub Pages works) and link to it from Settings → Privacy Policy. Keep the in-app copy for offline reading.

### P1-8 The camera snapshot is on by default and shows up in screen shares

**Where:** the snapshot defaults to on ([`AppSettings.swift:70`](../Shoo/Models/AppSettings.swift#L70)). The overlay panel sits at `.screenSaver` level with `.canJoinAllSpaces` and `.fullScreenAuxiliary` ([`OverlayController.swift:149-155`](../Shoo/Alerting/OverlayController.swift#L149-L155)), and it never sets `sharingType`.

**Why it matters:** the reminder puts a photo of the user, caught mid-habit, on top of everything else. That includes Zoom, Meet or Teams screen shares, full-screen Keynote presentations and screen recordings. For an app sold on privacy, that's the likeliest one-star review, and a strange first impression for a reviewer.

**Fix:**
- Make the snapshot opt-in, with a one-line explanation.
- Set `panel.sharingType = .none`. It's a best-effort way to keep the overlay out of captures, so test it with the conferencing apps you care about, since newer capture APIs may not honor it.
- Consider an option to skip the overlay during screen sharing or in full-screen apps.

### P1-9 Keep the marketing claims accurate and non-medical

- **No treatment claims.** Don't present Shoo as treating a condition such as BFRB, onychophagia or trichotillomania; say it "helps you notice". Guideline 1.4.1 gives medical apps extra scrutiny and expects them to tell users to consult a doctor.
- **Category has consequences.** Since March 2026, new apps in the EEA, UK or US that choose the **Health & Fitness** category must declare whether they're a regulated medical device ([Apple](https://developer.apple.com/news/?id=nyqbfz1y)). Answering "No" is fine, but it's one more form. **Productivity** as the primary category avoids it.
- **Only claim what it detects.** Detection covers the mouth (nail and lip biting) and the nose. `GestureMask.hairPulling` exists ([`SettingsTypes.swift:16`](../Shoo/Models/SettingsTypes.swift#L16)), but there's no hair region in the detector ([`DetectorConfig.swift:66-74`](../Shoo/Detection/DetectorConfig.swift#L66-L74)). Claiming hair pulling or skin picking would break guideline 2.3.1 (accurate metadata).
- **Say the camera light stays on.** The green camera light is on the whole time Shoo is watching. Say so in the description and in onboarding so it doesn't alarm people.

---

## P2: Should fix (quality, ratings, robustness)

**P2-1 Features with no UI.** Commit `b2a784b` removed the Schedule tab, the gesture toggles and the escalation toggle from Settings, but their logic is still in the app:
- the active-hours timers, the `outsideSchedule` state and "Watch anyway" ([`AppState.swift:375-443`](../Shoo/App/AppState.swift#L375-L443));
- `watchedGestures` gating;
- `escalationEnabled`.

As a result, users can never reach the "Paused by schedule" state, and "Snooze until tomorrow morning" always means 09:00. Either bring back a compact "Active hours" section (watching only during work hours is a good selling point) or delete the dead paths.

**P2-2 No camera picker.** [`DeviceSelector`](../Shoo/Camera/DeviceSelector.swift) picks the remembered camera first, then the system default, then the built-in camera. People with several webcams or an iPhone Continuity Camera can't choose. Add a camera picker in Settings backed by `DeviceSelector.availableDevices()`.

**P2-3 Energy use (guideline 2.4.2).** Running face landmarks and hand pose at 12 fps all day ([`CameraController.swift:40`](../Shoo/Camera/CameraController.swift#L40)) is the main cost, and utilities that show up in Activity Monitor's Energy tab get uninstalled. Ideas:
- Run the face request first and skip hand pose when no face is found. [`runPipeline`](../Shoo/Detection/HandFaceDetector.swift#L90-L105) already ignores the hands in that case.
- Drop to 3–4 fps while no hand is in view, and ramp up when a hand gets near the face.
- Measure with Instruments (Energy Log) or `powermetrics`, and fix any regressions before launch.

**P2-4 A rare crash in the frame-rate cap.** [`FrameRateCap.swift:38-39`](../Shoo/Camera/FrameRateCap.swift#L38-L39) rebuilds the frame duration from the *rounded* fps. When the nearest supported range has a fractional limit, rounding can land just outside it. For example, a virtual or capture device that only supports 29.97 fps gets 1/30 s. Setting a duration outside the supported range raises an Objective-C exception that Swift can't catch, as that file's own comment says. When snapping to a range limit, use the range's own `minFrameDuration`/`maxFrameDuration` `CMTime`.

**P2-5 Discoverability.** This covers `applicationShouldHandleReopen` and the menu-bar pointer from [P0-5](#p0-5-a-fresh-install-shows-no-ui-because-onboarding-never-opens). Also add an About entry with a link to the support page.

**P2-6 Localization readiness.** All strings are English literals. Labels built as a `String`, such as `Text(statusText)` at [`MenuBarView.swift:61`](../Shoo/Views/MenuBarView.swift#L61), bypass localization, and the plural at [`:149`](../Shoo/Views/MenuBarView.swift#L149) is hand-rolled. Add a String Catalog (`Localizable.xcstrings`); Xcode extracts SwiftUI literals automatically. This isn't needed to submit, but localizing just the store listing already widens your reach.

**P2-7 Copyright line.** [`Info.plist:34`](../Shoo/Info.plist#L34) says "Copyright © 2026. All rights reserved." with no rights holder. Use "© 2026 ⟨your name or company⟩". App Store Connect's Copyright field needs the holder's name too.

---

## P3: Hygiene

| Item | Where | Suggestion |
|---|---|---|
| XcodeGen not pinned | `ci.yml:38`, `release.yml:22`, `scripts/bootstrap.sh` | Still open from AUDIT P1. Pin it, or stop committing `Shoo.xcodeproj`. |
| No release validation in CI | `release.yml` | Once signing exists, add a job that archives and exports, then runs the App Store validation step (Organizer's *Validate App* or `altool --validate-app`) on every tag. |
| Deprecated API | [`AppState.swift:173`](../Shoo/App/AppState.swift#L173) | `NSApp.activate(ignoringOtherApps:)` is deprecated in macOS 14. Use `NSApp.activate()`. |
| Old project format settings | `project.pbxproj` has `LastUpgradeCheck = 1430` | New Xcode will prompt to "update to recommended settings". Set XcodeGen `options.xcodeVersion`. |
| Swift 6 readiness | [`AppState.swift:531-541`](../Shoo/App/AppState.swift#L531-L541) | The `camera.onFrame` closure is created on the main actor but runs on the capture queue and reads `self.detector`. In Swift 6 language mode it would be treated as main-actor-isolated and crash at runtime. Make it nonisolated/`@Sendable`, and move `detector` out of `AppState`'s isolation before switching modes. Not needed for 1.0. |
| Dead code | various | `CameraPermission.openSystemSettings()` duplicates `SystemSettings.openCameraPrivacy()`. Also unused: `AppState.pauseAlerts`/`alertsSuppressed`/`snoozedUntil`, `AlertManager.tick()` (the app never calls it), `CatchStatsStore.last7Days()`, `PauseReason.lowPower`, `ProximityAnalyzer.isHandInFace` and `WindowOpener.dismiss`. |
| Stale docs | [`ARCHITECTURE.md`](ARCHITECTURE.md), README | ARCHITECTURE.md still mentions `CameraManager`, a `TabView` with a Schedule tab, `AlertMode` and `VNDetectFaceRectanglesRequest`. The README's "Download / unsigned" section changes once the app is on the store. |
| Two builds share one bundle ID | `scripts/package.sh` | The ad-hoc GitHub zip and the App Store build would both be `com.shoo.Shoo`. macOS keys the camera permission to bundle ID *and* signature, so switching between the two builds re-prompts or gets confused. Either stop shipping ad-hoc zips, or sign the GitHub build with Developer ID and notarize it using the same account. Notarizing also removes the README's `xattr` workaround. |
| Launch and AppKit paths have no tests | tests | Every P0/P1 bug above sits in app-lifecycle or AppKit glue that unit tests don't reach. Run the [checklist in Appendix B](#appendix-b-pre-submission-checks) on a clean macOS user account before each submission. Optionally add one XCUITest that launches with empty defaults and asserts the onboarding window appears. |

---

## App Store Connect checklist

| Field | Status | Suggestion |
|---|---|---|
| App name (≤30 characters) | To do | A distinctive name, e.g. "Shoo: Hands Off Your Face". "Shoo!" is already an unrelated Mac utility ([P0-1](#p0-1-no-signing-archive-or-upload-pipeline)) |
| Subtitle (≤30 characters) | To do | "Stop touching your face" / "Break the nail-biting habit" |
| Category | To do | Health & Fitness is the natural fit but needs the medical-device declaration; Productivity avoids it. Must match `LSApplicationCategoryType` ([P0-2](#p0-2-lsapplicationcategorytype-is-missing-so-the-upload-is-rejected-itms-90242)) |
| Privacy policy URL | Missing | GitHub Pages page built from `docs/PRIVACY.md` ([P1-7](#p1-7-make-the-privacy-policy-complete-and-host-it)) |
| Support URL | Missing | Small support page or GitHub Issues |
| Screenshots | Missing | 3–5 images at 2560×1600: menu popover, overlay (blue hand symbol or a consenting person's photo), Settings, onboarding privacy page |
| App Privacy | Ready | "Data Not Collected" (matches `PrivacyInfo.xcprivacy`) |
| Age rating | To do | Answer the reworked questionnaire; expect 4+, or 9+ if you say yes to health or wellness topics |
| Export compliance | Ready | `ITSAppUsesNonExemptEncryption = false` is in Info.plist |
| Price | To do | Free |
| Copyright | Fix | "2026 ⟨name⟩" ([P2-7](#p2-should-fix-quality-ratings-robustness)) |
| EU trader status | To do | Declare "trader" or "not a trader"; required for EU distribution ([P0-6](#p0-6-the-app-store-connect-listing-doesnt-exist-yet)) |
| Regulated medical device | To do if Health & Fitness | Declare "No" ([P1-9](#p1-9-keep-the-marketing-claims-accurate-and-non-medical)) |
| Review notes and demo video | Draft | [Appendix A](#appendix-a-review-notes-draft) |
| Version / build | To do | 1.0.0 (build 1 or higher) |

---

## Suggested order of work

1. **Code fixes that need no Apple account:** P0-5, P1-1 to P1-4, P1-6, P1-8, P2-4, `LSApplicationCategoryType`, and the privacy-policy text.
2. **New icon.** Start now; design has lead time.
3. **Toolchain:** Xcode 26 locally and in CI. Do the CI move before the first `macos-14` brownout on 5 October. Re-test on macOS 26 and 27.
4. **Account and signing:** developer account, final bundle ID, App Store Connect record (reserve the name), signing. Archive and validate locally.
5. **Listing:** host the privacy and support pages, then make the screenshots, metadata, review notes and demo video.
6. **TestFlight and submission:** install the TestFlight build on a clean user account, run Appendix B, then submit.

---

## Appendix A: Review notes (draft)

> Shoo is a menu-bar app: it has no Dock icon and no main window. On first launch a welcome window explains the app and asks for camera access. After that, everything is in the hand icon in the menu bar (top right).
>
> Shoo uses the camera only while "Watch for face-touching" is on. It detects, on-device with Apple's Vision framework, when a fingertip comes close to the mouth or nose, and then shows a short reminder overlay. No images or derived data are stored or transmitted, and the app has no network entitlement.
>
> To test:
> 1. Complete the welcome window and allow camera access.
> 2. Click the hand icon in the menu bar and make sure "Watch for face-touching" is on.
> 3. Hold a fingertip at your lips for about a second. A reminder appears.
> 4. Settings → "Preview reminder" shows the reminder without using the camera.
>
> Detection needs a Mac with a camera. Demo video: ⟨link⟩. No account or sign-in is required.

## Appendix B: Pre-submission checks

Run these on the exported, App Store–signed build:

```sh
# Only app-sandbox + device.camera should appear
codesign -d --entitlements - build/export/Shoo.app
# Signed by Apple Distribution
codesign -dv --verbose=4 build/export/Shoo.app
# Installer is signed by Mac Installer Distribution
pkgutil --check-signature build/export/Shoo.pkg
# Category key is present
plutil -p build/export/Shoo.app/Contents/Info.plist | grep LSApplicationCategoryType
# Privacy manifest is bundled
ls build/export/Shoo.app/Contents/Resources/PrivacyInfo.xcprivacy
# Reset the camera prompt for a re-test
tccutil reset Camera <bundle-id>
```

Then, on a clean macOS user account, confirm that:
- onboarding opens by itself;
- the camera prompt shows the purpose string;
- the overlay's buttons work;
- turning on notifications triggers the system prompt;
- launch at login works, and "Start watching on launch" works after a reboot;
- launching the app again opens a window;
- no Dock icon remains after its windows close;
- Activity Monitor shows reasonable CPU and energy use after an hour of watching.

## Appendix C: What's already right (keep it)

- **Entitlements:** App Sandbox with only `device.camera`, and no network entitlement. The privacy claim is enforced by the sandbox, not just promised.
- **Privacy manifest:** `PrivacyInfo.xcprivacy` declares no tracking and no collected data, and gives `UserDefaults` / `CA92.1` as the only required-reason API. That's correct: `CA92.1` is the right reason, and `CACurrentMediaTime()` in `FrameThrottle` isn't a required-reason API. Apple only enforces required-reason declarations for iOS, iPadOS, tvOS, visionOS and watchOS ([Apple](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)), so on macOS the file is optional but harmless.
- **Recording indicator:** guideline 2.5.14 asks for consent and a clear indicator when an app records user activity, and it names camera use. If a reviewer applies it to Shoo, the green camera light and the menu-bar icon switching to a filled hand while watching cover it. Keep that change obvious.
- **Camera access:** the purpose string is clear, and access is only requested after a user action.
- **Launch at login:** uses `SMAppService.mainApp`, is off by default and only turns on when the user asks. That satisfies guideline 2.4.5(iii), which bans launching at login without consent.
- **Standard behavior:** a Quit item in the menu, and camera pausing on screen lock, display sleep, system sleep and critical thermal state.
- **Accessibility:** VoiceOver announcements, and support for Reduce Motion, Reduce Transparency and Increase Contrast in the overlay.
- **Tests:** a thorough unit-test suite for the pure logic (schedule, detector, alert state machine, stats).
