# Life Is Short

A local-first iPhone app for keeping meaningful moments close. Choose a photo, name a milestone, and see the time remaining on your Home Screen.

The app manages the library and settings. Small and medium widgets rotate through a shared selection of up to three milestones. Saved milestones have no application-imposed count limit, and hiding a milestone preserves its photo and settings.

## v0.1 experience

- Date-based targets with optional times, or birthdays calculated from a birth date and target age.
- Saved target time zones that stay fixed when traveling.
- Total days, weeks, or hours; or days with an hours/minutes/seconds countdown.
- One manually selected background photo per milestone, with a built-in background available.
- A nominal ten-minute widget rotation, subject to iOS scheduling.
- Japanese, English, and Indonesian, selected by iOS language settings.
- Local storage, no application account, no application-specific analytics, and no application backend.

A target age is a milestone chosen by the user, not a prediction of death. Reached milestones stop at zero and remain saved.

## Development

Use Xcode 27 or later and an iPhone simulator running iOS 27 or later. Open `LifeIsShort/LifeIsShort.xcodeproj` and select the shared `LifeIsShort` scheme.

Run the shared domain tests:

```sh
swift test --scratch-path "$TMPDIR/LifeIsShortCore"
```

Build the app and its embedded widget for the simulator:

```sh
xcodebuild -project LifeIsShort/LifeIsShort.xcodeproj \
  -scheme LifeIsShort -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$TMPDIR/LifeIsShortDerivedData" build
```

For UI tests, choose an available iPhone simulator destination and run the scheme's tests. Add `-collect-test-diagnostics never` if collecting simulator diagnostics stalls in the local environment. Screenshots use synthetic milestones; debug-only seed arguments are confined to the development build.

The photo integration test requires a synthetic image in the simulator photo library. Generate it with `swift Scripts/generate-photo-fixture.swift`, then import the resulting `.build/fixtures/mountain.png` with `xcrun simctl addmedia <device-id> <absolute-image-path>`. The widget integration tests operate the native Home Screen and may take several minutes while iOS finishes edit-mode animations. Run them on a dedicated simulator, since adding widgets changes its Home Screen.

The shared tests verify countdown calculations, calendar rules, transaction failures, library growth, timeline boundaries, and composition with Apple's native timer formatter. CI runs those tests and builds the iPhone app with its embedded widget; UI integration evidence is recorded separately.

Place build output outside file-provider-managed folders if their extended attributes interfere with code signing. No global configuration change is required.

For a physical iPhone, select the appropriate development team for both targets and provision the shared App Group `group.com.pumpkinpietea.LifeIsShort`. Do not commit signing credentials or provisioning profiles.

## Adding a widget

Add milestones in the app and turn on **Show in Widget** for up to three. Touch and hold the Home Screen, open the widget gallery, search for **Life Is Short**, and choose the small or medium widget. Tapping it opens the milestone list.

iOS controls actual widget update timing. Seconds use Apple's bounded system timer. Prepared timeline entries update whole-unit/day values and rotation; no every-second extension reload loop is used. The system can delay entry transitions. See the design document for the resulting scheduling limits.

## Specifications and verification

- [Requirements and acceptance criteria](specs/requirements.md)
- [Design and implementation decisions](specs/design.md)
- [Tasks, issues, and verification status](specs/tasks.md)

Development verification and App Store distribution are tracked separately. See the task document for current evidence and remaining limitations.

## Privacy

Milestone details, birth dates, and imported photos stay in the app's local shared container. The app does not transmit them to an application service. The system photo picker can download an iCloud-only photo during import; an imported copy is then available offline. No full-library scanning or location access is required.
