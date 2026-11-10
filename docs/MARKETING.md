# Shoo — Marketing plan and todo

Working checklist for spreading the word now that Shoo is on the Mac App Store. Sized for a solo, spare-time project.

**Status legend:** `[ ]` open · `[~]` partial · `[x]` done

## Positioning

- **Pitch:** "A Mac menu-bar app that catches you biting your nails or touching your face, and tells you to stop."
- **Main objection:** it is a webcam app. Every post, page and listing says early that it runs on-device, makes no network calls, and is open source.
- **Tone:** a habit reminder, not a treatment. No medical claims (see P1-9 in [`APP_STORE_READINESS.md`](APP_STORE_READINESS.md)): they risk App Store review and goodwill in habit communities.
- **Name clash:** an unrelated paid Mac utility called "Shoo!" exists ([shooapp.com](https://shooapp.com/)). Always pair the name with what it does ("Shoo, the nail-biting reminder") and link directly instead of telling people to search for it.

## Week 0 — Fix the funnel before sending traffic

Nothing in weeks 1–6 starts until sections A–C are done. Everything below sends people to the site, the README or the App Store page, and today two of those three say the app is unsigned and not on the App Store.

### A. Decisions (do these first, they unblock the rest)

- [x] **Record the App Store URL** here: <https://apps.apple.com/app/id6822772523> (listed as "Shoo: Hands Off Your Face", app ID `6822772523`)
- [ ] **Decide the fate of the GitHub zip.** Recommended: App Store is the primary download; keep GitHub Releases as a secondary "build from source / unsigned zip" option for the open-source audience. Note that both builds share the bundle ID `io.github.jkkronk.shoo`, so users should install only one. _Done: site, support page and README now say so._
- [ ] **Write the one-line pitch and a 50-word blurb** once, and reuse them verbatim everywhere (listing, site, posts, press email).

### B. Site (`site/`)

- [x] `site/index.html` — point the four download buttons (nav, hero pill, hero button, bottom call to action) at the App Store URL. Use Apple's official "Download on the Mac App Store" badge for the hero. _Links done; the buttons are styled text, the official badge artwork is still to add._
- [x] `site/index.html` — replace the FAQ entry "Will there be an App Store version?" ("It's being worked on") with "Where do I get it?".
- [x] `site/index.html` — rewrite the bottom call-to-action text that says "not notarized: macOS blocks the first launch".
- [~] `site/index.html` — update the `<meta name="description">` and add Open Graph / Twitter card tags (`og:title`, `og:description`, `og:image`, `twitter:card`) so shared links show a preview. Needs a 1200×630 image in `site/assets/`. _Description updated and OG tags exist; still uses the 512 px icon and a `summary` card until the 1200×630 image exists._
- [~] `site/index.html` — add `<meta name="apple-itunes-app" content="app-id=…">` and embed the demo clip from section D near the top. _Meta tag done; clip waits on section D._
- [x] `site/support.html` — make "From the Mac App Store" the first install section; move the Gatekeeper / "Open Anyway" steps under a "GitHub build only" heading.
- [x] `site/privacy.html` and `site/support.html` — point the nav "Download" buttons at the App Store.
- [ ] Add a campaign token to the site's App Store links (`?pt=…&ct=website`) so App Store Connect attributes the traffic.

### C. Repository

- [x] `README.md` — replace the "Download" section: App Store badge first, GitHub zip second. Drop "unsigned / not notarized" as the headline.
- [ ] `README.md` — put the demo GIF above the fold.
- [ ] GitHub repo settings — set the description, the website URL, and topics (`macos`, `menu-bar`, `swift`, `vision-framework`, `nail-biting`, `habit-tracker`, `privacy`).
- [ ] GitHub repo settings — upload a social preview image (same 1200×630 as the site).
- [ ] Latest GitHub Release notes — add a line pointing to the App Store version.

### D. Demo assets (the most reused thing in this plan)

- [ ] **Hero clip, 10–15 seconds, no audio needed:** working at the Mac → hand drifts to mouth → "Gotcha!" overlay → hand drops. Record with a real person who consents to being shown, in good light, on a clean desktop.
- [ ] Export it as: MP4 16:9 (site, X, Product Hunt), MP4 9:16 with captions (TikTok, Reels, Shorts), and a GIF under 5 MB (README, Reddit, press email).
- [ ] **App Store preview video** cut from the same footage (1920×1080, 15–30 seconds, must show only the app in use).
- [ ] **Screenshots,** 3–5 at 2560×1600: overlay, menu popover, Settings, onboarding privacy page. Add a short caption on each ("Runs entirely on your Mac"). No Apple emoji imagery.
- [ ] One still image at 1200×630 for link previews (section B and C).

### E. App Store listing

- [ ] **Subtitle (30 characters):** state the job, e.g. "Stop biting your nails".
- [ ] **Keywords (100 characters):** no repeats of words already in the name or subtitle. Candidates: `nail,biting,face,touching,habit,skin,picking,hair,pulling,reminder,webcam,menu,bar,focus`.
- [ ] **Description:** first two lines carry the pitch and the privacy promise, since that is all that shows before "more".
- [ ] **Promotional text:** editable without a new build; use it for launch and seasonal hooks.
- [ ] Upload the preview video and captioned screenshots from section D.
- [ ] Check the listing in a logged-out browser and on the Mac App Store app: does search for "nail biting" and "stop touching face" find it?

### F. Reviews and feedback loop

- [ ] Ask 5–10 friends or colleagues who actually use it for an honest App Store rating. Send the direct review link (`…/id…?action=write-review`).
- [ ] Decide whether to add an in-app rating prompt (`SKStoreReviewController`) after a week of use. This is a code change; track it as an issue rather than doing it during launch week.
- [ ] Confirm `site/support.html` lists a contact route you check, and turn on GitHub issue notifications. Launch traffic brings bug reports within hours.

### G. Measurement baseline

- [ ] Create one App Store Connect campaign link per channel (`ct=hn`, `ct=reddit-macapps`, `ct=producthunt`, …) and keep them in the table below.
- [ ] Note the starting numbers before launch: impressions, product page views, conversion rate, downloads, GitHub stars.

| Channel | Campaign link | Date posted | Downloads after 7 days |
|---|---|---|---|
| Website | | | |
| Show HN | | | |
| r/macapps | | | |
| Product Hunt | | | |

**Week 0 is done when:** every download link leads to the App Store, a shared link shows a preview image, the demo clip exists in three formats, and the listing has a video, captioned screenshots and at least a handful of ratings.

## Weeks 1–2 — Launch posts

Spread these over several days so every comment gets an answer.

- [ ] **Show HN.** Lead with the on-device Vision pipeline and open source. Link the repo; mention the App Store in the text.
- [ ] **Reddit, Mac audience:** r/macapps, r/SideProject, r/opensource.
- [ ] **Reddit, habit audience:** r/calmhands, r/CompulsiveSkinPicking, r/trichotillomania. Read each sub's self-promotion rules, ask the mods where unclear, and write as a person who built it for their own habit.
- [ ] **Product Hunt.** One day, with the demo clip.
- [ ] **Short video** on X, TikTok, Reels and LinkedIn with the personal story of why it exists.

## Weeks 2–6 — Slow-burn channels

- [ ] **Directories:** AlternativeTo, the `awesome-mac` and `open-source-mac-os-apps` GitHub lists, Mac menu-bar app catalogues.
- [ ] **Press:** three-sentence email plus the GIF to Mac writers and newsletters (MacStories, 9to5Mac, Indie Apps Catalog, The Loop). Hook: "open-source webcam app that sends nothing anywhere".
- [ ] **Write-up:** one blog post on how the detection works, including false positives and the chin-rest problem. It earns a second HN and Reddit post.
- [ ] **Seasonal hooks:** New Year's resolutions; cold and flu season ("stop touching your face"). Update the promotional text for each.

## Measure and repeat

- [ ] Review the campaign table two weeks after launch.
- [ ] Repeat whichever channel converts; drop the rest.
