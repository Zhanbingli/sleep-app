# Sleep Assistant

`Sleep Assistant` is a lightweight iOS app for the few minutes before sleep.

Instead of trying to be an all-in-one sleep tracker, it narrows the experience down to one short nightly flow:

`Tonight -> Breathing -> Soundscape -> Phone Down -> Morning Reflection`

The app is built with SwiftUI, works offline, stores data locally, and is designed around low-friction bedtime use rather than dashboards first.

## What It Does

- Personalized nightly plan based on a simple sleep profile plus recent reflections.
- Guided breathing with 4-7-8, box breathing, and coherent breathing.
- Built-in synthesized soundscapes: pink noise, rain, and fireplace.
- Configurable sound fade-out with background playback support.
- Editable bedtime routine/checklist.
- Morning quick check plus detailed review flow.
- Sleep history with trend summaries from detailed entries only.
- English localization support alongside the original Chinese UI.
- In-app `About`, `Privacy`, `Support`, and local data management pages.

## Product Direction

This app is intentionally not a medical product.

The current goal is to help users who:

- feel mentally too on before bed
- get pulled into their phone at night
- want a very short wind-down ritual
- prefer an app that stays local and simple

## Project Structure

- Xcode project: `sleep.xcodeproj`
- App source: `sleep/`
- Unit tests: `sleepTests/`
- UI tests: `sleepUITests/`

## Tech Stack

- SwiftUI
- AVAudioEngine for generated soundscapes
- UserDefaults for local persistence
- iOS 16.0 deployment target

## Run Locally

1. Open `sleep.xcodeproj` in Xcode.
2. Select the `sleep` scheme.
3. Choose an iPhone simulator or device running iOS 16+.
4. Build and run with `Cmd+R`.

You can also build from the command line:

```bash
xcodebuild -project sleep.xcodeproj -scheme sleep -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Current App Surfaces

- `Tonight`: start the nightly flow and see the current recommendation.
- `Morning`: quick subjective check-in plus detailed review.
- `More`: breathing, routine, soundscape, history, sleep profile, about/privacy/support/data pages.

## Privacy

- The app currently stores user data locally on-device.
- There are no analytics, login flows, cloud sync flows, or ad SDKs in the app.
- A `PrivacyInfo.xcprivacy` manifest is included for local `UserDefaults` usage.

Important:

- Real public privacy/support URLs still need to be filled in `sleep/AppMetadata.swift` before release.
- App Store Connect privacy answers must match the in-app privacy page.

## Release Readiness

The project now includes:

- app icon assets
- privacy manifest
- about/privacy/support/data pages
- localized English strings

Still recommended before App Store submission:

- replace placeholder public metadata with real URLs/contact info
- replace the current placeholder icon with final brand artwork if needed
- add meaningful unit tests for recommendation and summary logic
- do a final accessibility and visual QA pass

## Status

This is an actively iterated prototype moving toward App Store readiness, not a finished production app yet.

## License

MIT
