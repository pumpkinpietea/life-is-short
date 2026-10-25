# Life Is Short: v0.1 Design

Status: Implementation design; development authorized on 2026-10-25

The confirmed product requirements are in [requirements.md](requirements.md). Architecture and interface choices below are proposals unless that document identifies them as confirmed requirements.

## Repository baseline before implementation

- A SwiftUI app target exists with an initial greeting screen.
- The deployment target is iOS 27.0.
- The project currently lists both iPhone and iPad device families; the intended v0.1 product scope is iPhone.
- There is no widget extension, persistence layer, string catalog, test target, or CI workflow yet.
- GitHub required PRs for changes to `main`, including administrators, and blocked force pushes and branch deletion on `main`. CI was added during implementation; the successful `Validate` check is now required.

## User experience

### Settings app

Use a milestone library list as the starting screen. Each row identifies its milestone, provides access to settings, and offers a widget-display on/off control. Standard list interactions support reordering and deletion. Editing retains the milestone's identity and list position while overwriting its saved values; do not create another milestone or a user-visible version history.

Do not impose a record-count limit on the saved library. Enforce a separate maximum of three selected milestones in the interface and persistence validation. Hidden milestones remain visible in the app library and retain their photos and settings.

Use an iOS switch-style toggle in each list row, labeled "Show in Widget", and a selected-count summary such as "2 of 3". Keep the library as a list rather than three fixed storage fields.

Use the confirmed selection behavior in R-04: when fewer than three are selected, enable a milestone directly. When three are already selected, offer to choose which currently selected milestone to replace. Apply replacement atomically, keep the displaced milestone and its photo/settings saved with visibility off, and leave the previous selection unchanged if canceled. Never silently deselect an existing milestone or save an intermediate selection of four.

Enable a newly saved milestone by default when a selection place is available; otherwise save it with widget display off. Editing an existing milestone preserves its visibility unless the user changes it.

Use a confirmation before deletion. After a confirmed deletion, publish the updated shared list and request a widget timeline update. The system may temporarily retain an already rendered entry until it processes the update; subsequent timeline entries must exclude the deleted milestone.

Turning widget display off is not deletion. Preserve the full saved order and derive the widget sequence by filtering for selected milestones. Turning display back on restores the milestone's relative position. Retain photo assets referenced by hidden milestones during cleanup.

The milestone editor contains:

- A user-entered title.
- A target input mode: date or age.
- A date and optional time, or a birth date and target age with an optional target time.
- The saved target time zone, presented clearly enough that travel behavior is understandable.
- A single-photo selector and an option to return to the built-in background.
- Type 1 unit selection or Type 2 selection.
- A widget-style preview using the same milestone data and rendering rules.

Validate required titles and date/age input. Report invalid or unsupported values without discarding valid input. In age mode, automatically calculate the target birthday from the entered birth date and target age, as confirmed in R-01 (formerly proposal P-02). This creates a user-defined milestone and does not supply a lifespan estimate.

An empty library explains how to add a milestone. A nonempty library with no widget selection explains how to turn on widget display, without treating saved milestones as missing. Saving a fourth or later milestone remains available even when all three selection places are filled. After setup, provide concise instructions for adding the Home Screen widget. No personal data is required merely to open the app.

### Home Screen widget

Use one widget configuration supporting small and medium families. All instances read the same shared selection of at most three milestones and automatically rotate through it in relative saved order, as confirmed in R-04. Do not add per-instance milestone selections in v0.1.

Each entry represents a complete presentation: milestone identity, photo or built-in background, title, target instant, and countdown format. A transition must not combine the title from one milestone with another milestone's image or time.

Prioritize photo, title, and countdown legibility. Use a restrained contrast treatment and layout that works with localized text. The small layout may arrange Type 2 across multiple lines. An empty selection or unavailable data produces a useful setup/fallback view. Hidden or deleted milestones must not appear in newly generated entries. Request updates when visibility changes, while acknowledging that iOS may temporarily retain an already rendered entry.

Use a widget link to open the milestone list, as confirmed in R-04. This destination is independent of the displayed milestone and must work on a cold start or when that milestone no longer exists.

## Implemented architecture

Keep a small shared domain layer and separate app and widget entry points. Avoid a third-party dependency unless a concrete requirement cannot be met with Apple frameworks.

| Component | Responsibility | Proposed Apple facilities |
| --- | --- | --- |
| App UI | Milestone list, editor, system photo selection, previews | SwiftUI, PhotosUI |
| Domain model | Milestone values, validation, age-to-date calculation, duration rules | Foundation |
| Shared local store | Ordered milestones and widget-ready photo assets | Codable, FileManager, App Groups |
| Widget extension | Timeline sequence, small/medium views, system time text | WidgetKit, SwiftUI |
| Localization | User-facing text, unit variants, localized formatting | String Catalogs, Foundation |
| Navigation | Open the milestone list from any widget | Widget links and SwiftUI URL handling |

Use a versioned local file format in an App Group container, shared by the app and widget. A small JSON document plus separately stored image assets is sufficient for the initial data model; reassess only if implementation reveals a concrete need for a different Apple persistence framework.

### Milestone data

Store the following concepts, without persisting preformatted localized strings:

| Field | Purpose |
| --- | --- |
| Stable identifier | Editing, ordering, and asset references |
| Title | Explain what the countdown represents |
| Target source | Date input or age input; retain enough source data to edit it |
| Target instant | Absolute countdown endpoint |
| Time-zone identifier | Preserve the target zone across travel and edits |
| Optional-time flag | Distinguish omitted time from an explicitly selected midnight |
| Optional photo reference | Reference an imported widget-ready local asset |
| Display configuration | Type 1 plus unit, or Type 2 |
| Widget visibility | Whether this milestone is included in the shared selection of at most three |

The store maintains milestone order and per-record visibility as the sources of truth. Derive the selected sequence by filtering this order; do not maintain a conflicting second selection list. Reject any mutation that would leave more than three selected records. The widget derives presentations from saved target instants and the current time instead of saving a countdown value that immediately becomes stale.

### Library growth

Use a collection of identified records rather than fixed fields for three milestones. Keep the selected-item limit as a policy independent of library storage. Use a versioned schema so future storage changes can preserve identities, order, photos, and visibility.

Start with the simple local format, but validate a synthetic 200-record library during implementation. Keep images as separate files, use lazy list rendering, and load only the image assets needed for visible app rows or the selected widget presentations. Do not decode every library photo to build a widget timeline.

Search and filtering are useful future interface options as the library grows; they are not added to the confirmed v0.1 scope by this proposal. Handle storage exhaustion and failed imports without discarding existing saved records. No physical device can guarantee an infinite library.

### Persistence and photos

- Use the system photo picker for an explicitly selected image, rather than requesting general photo-library access.
- Import and resize an image into application-managed local storage. The widget must not depend on subsequently reading the original library asset.
- Treat a canceled selection as no change. If importing fails, retain the existing photo or the built-in background and show a recoverable error in the app.
- A cloud-only photo may need an OS-managed download during import; the offline guarantee starts after a successful import.
- Publish a new image asset before atomically replacing the metadata snapshot that refers to it.
- Keep the previous valid snapshot intact if saving fails.
- Bound image size and cleanup. Account for old widget timelines that may still reference an older asset before removing it.
- When a referenced image is unavailable, show the built-in background and preserve the title/countdown.
- Do not retain image location metadata for this feature or send selected photos to an application service.

The app and widget share `group.com.pumpkinpietea.LifeIsShort`. Physical-device provisioning requires a development team with that App Group capability. Do not place credentials or personal photos in Git.

## Time semantics

### Fixed target

Capture the device time-zone identifier when a target is created. Persist the resolved absolute target instant and that identifier. Changing the device zone must not recalculate the instant.

When editing a target, display it using its saved zone. An omitted time means the start of the selected date in that zone. A target date in the past is allowed and produces the confirmed zero state.

For a February 29 birthday, use February 28 in a non-leap target year and February 29 when it exists, as confirmed in R-01. Show the calculated target date before saving.

Implementation defaults selected under the delegated development authority:

- Use Gregorian calendar arithmetic to calculate the target birthday from a birth date and integer target age.
- Resolve a nonexistent local time at a daylight-saving transition to the next valid time, and display the resolved value before saving.
- For a repeated local time, propose the first occurrence and display the resolved zone/offset before saving.

These are convenience policies for a user-defined milestone, not legal definitions of age. Cover them with deterministic checks and show the resolved target before saving.

### Remaining duration

Under the confirmed duration rules in R-03 (formerly proposal P-01), derive one nonnegative duration from the saved target instant and an injectable current time:

- Type 1: whole 24-hour days, seven-day weeks, or hours, with the less-than-one-unit state for a positive remainder below one unit.
- Type 2: total 24-hour days followed by an hours/minutes/seconds remainder.
- At or after the target instant: zero for both formats, with no elapsed-time mode.

Keep the model independent of the rendering environment so boundary cases can be tested with a fixed clock. Verify behavior at exact targets, one unit before/after a boundary, time-zone changes, daylight-saving transitions, and long durations.

### Widget scheduling

Generate a timeline containing multiple future entries, cycling through the saved order. Use the confirmed fixed nominal ten-minute rotation cadence, within the approximate 5-to-15-minute preference. Do not add an interval selector in v0.1. Plan ahead rather than asking the extension to reload for every second.

Keep rotation selection deterministic from the filtered, at-most-three-item sequence and a saved rotation anchor. Handle zero selected milestones, one selected milestone, reordering, visibility changes, replacement, and deletion explicitly. With one selected milestone, do not rotate to an empty entry. Do not reset every cycle merely because WidgetKit requests a new timeline.

The OS controls the actual rendering and reload schedule. Do not promise exact transition times, identical transitions across widget instances, or a continuous slideshow. Use timeline requests after settings change, while preserving a coherent presentation if the system delays an update.

Include target-boundary changes in the schedule where needed, and use supported system time rendering for changing countdown text. Clamp reached targets to zero without relying on a continuously running extension.

### Type 2 feasibility checkpoint

Apple documents live-updating widget date text, bounded timers, and time-data-source-based formatting. That does not by itself establish support for the exact requested combination of total days, time remainder, localized labels, and zero stopping in both widget sizes.

The first code investigation, only after implementation is authorized, must verify the complete Type 2 presentation in a widget on iOS 27. Check long durations, the 24-hour boundary, zero, all three languages, and reduced update rates. A timer that only shows total hours is not an equivalent implementation of the accepted day-plus-time requirement.

If the requested presentation cannot be achieved with supported system mechanisms, bring that specific limitation back for a product decision. Do not silently drop days, use an approximate yearly conversion, add a backend, or make an every-second timeline reload loop.

### Runtime rendering decision

The iOS 27 simulator rejected an app-defined `DiscreteFormatStyle` inside a widget view archive (`noType` in WidgetRenderer). Compilation and app previews had succeeded, so a simulator Home Screen check was essential.

The implemented widget uses only Apple-defined live timer formatting. Whole-unit values and the total-day field are calculated at each prepared entry date. `PresentationSchedule` merges rotation dates with whole-unit changes, target instants, day changes, and the few boundaries where the native timer omits a leading zero field. The native bounded timer renders seconds between those entries and stops at zero without extension execution. Leading zero prefixes retain the requested `HH:MM:SS` presentation. The application preview can use the shared custom discrete formatter because it runs inside the app process.

This preserves total 24-hour days and the clock remainder without per-second timeline entries. The planned 24-hour timeline is renewed by WidgetKit. As with milestone rotation, an OS-delayed timeline transition can temporarily retain the previous whole-unit/day value or leading-zero layout; the bounded timer never counts upward or becomes negative. Real-device scheduling and reduced-update behavior remain distribution validation items.

## Localization and accessibility

- Use an English development/fallback localization with Japanese and Indonesian translations.
- Let iOS choose the supported language, including its per-app language override.
- Localize unit labels, less-than-one-unit states, empty states, errors, and VoiceOver descriptions; support language-appropriate pluralization.
- Use system-aware date/number formatting in settings. Do not store the user's language choice as a separate app preference.
- Check title wrapping, long countdown values, and layout in both widget families.
- Use system text/accessibility behavior, sufficient image/text contrast, and meaningful reading order. Avoid VoiceOver announcements for every second of a countdown.
- Respect iOS reduced-luminance and reduced-update behavior; continuous per-second rendering is not a hardware-independent guarantee.

## Verification plan

| Area | Planned evidence |
| --- | --- |
| Domain behavior | Deterministic tests covering target resolution, duration boundaries, zero stopping, and proposed calendar rules |
| Storage | Round-trip persistence, 200 synthetic records, visibility retention, failed writes, missing images, canceled imports, deletion, and valid snapshot fallback |
| Rotation | Deterministic sequence tests for zero to three selected milestones, hidden records, all-hidden state, reordering, replacement, deletion, and timeline continuation |
| Widget time rendering | iOS 27 runtime proof of Type 2, long durations, zero, and reduced-update behavior |
| Visual quality | Actually inspected small/medium widget and app previews, three languages, readable title/countdown over varied images |
| Accessibility | VoiceOver labels/order, text sizing, contrast, and relevant system accessibility settings |
| Offline behavior | Reopen the app and view existing widgets without network access after importing photos |
| Privacy | Inspect dependencies, app-defined data flows, and account requirements against R-06; distinguish system-managed photo downloads from application data transmission |
| Device behavior | Observed rotation timing, settings updates, device-zone changes, and relevant app/widget lifecycle cases on iPhone |
| Delivery | Relevant build/tests and PR evidence, followed later by separately verified App Store release |

See [tasks.md](tasks.md) for completed checks and remaining device/distribution work. Simulator evidence does not establish real-device widget scheduling behavior.

## SDD and PR workflow

Adapt the reference repository's requirements/design/tasks discipline to the three files requested for this project.

1. Review and maintain these specifications before dependent implementation.
2. Use issues for independently reviewable outcomes, linking the relevant specification sections and acceptance criteria.
3. Make changes on a branch and submit them through a PR targeting `main`.
4. Attach relevant build, test, and visual verification evidence to the PR. Keep personal photos and data out of shared evidence.
5. Update task state and remaining limitations as work proceeds.
6. Add suitable PR validation before requiring its exact check name in branch protection. Do not configure a nonexistent check that prevents merging.

The developer authorized autonomous v0.1 implementation, issue tracking, scoped branches and PRs, and relevant verification on 2026-10-25. Routine design choices may be resolved within this contract. App Store submission remains a separate distribution step.

## Primary references

- [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
- [Displaying dynamic dates in widgets](https://developer.apple.com/documentation/widgetkit/displaying-dynamic-dates)
- [Text with a time data source and format](https://developer.apple.com/documentation/swiftui/text/init(_:format:)-8sfgg)
- [Bringing Photos picker to your SwiftUI app](https://developer.apple.com/documentation/photokit/bringing-photos-picker-to-your-swiftui-app)
- [Apple localization overview](https://developer.apple.com/localization/)
- [Apple toggle guidance](https://developer.apple.com/design/human-interface-guidelines/toggles)
