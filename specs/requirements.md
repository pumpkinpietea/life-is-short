# Life Is Short: v0.1 Requirements

Status: Accepted v0.1 scope; implementation in progress

These specifications record the product decisions made during requirements discovery. The developer authorized implementation on 2026-10-25. Implementation choices are identified separately from confirmed product decisions.

## Product purpose

Life Is Short helps people feel that the present moment matters by showing the time remaining until personally chosen milestones, alongside meaningful photos.

The Home Screen widget is the primary experience. The containing iPhone app is primarily for creating and managing milestones, choosing photos, configuring the presentation, and previewing the result.

A target age is a personal milestone chosen by the user. It is not a prediction of death or a medical estimate. A milestone can also represent an event, such as a trip.

## Confirmed scope

### R-01: Milestones

- Support a saved milestone library with user-entered titles and no application-imposed record-count limit. Available device storage and resources remain practical limits; this is not a promise of physically infinite capacity.
- Separate the number of saved milestones from the number selected for widgets. At most three milestones can be selected for widget display at once.
- Allow partially filled selections and show a setup state when the library is empty.
- Save edits over the existing milestone rather than creating another milestone or a user-visible revision history.
- Allow milestones to be deleted. Deleted milestones are removed from the widget rotation source list.
- Offer both target-age and target-date input.
- In age mode, enter a birth date and target age, then automatically calculate the birthday on which that age is reached as the target date. Apply the same optional-time and saved-time-zone rules as date input; do not suggest a lifespan or estimate a death date.
- For a February 29 birth date, use February 28 when the target year is not a leap year. Retain February 29 when it exists in the target year.
- Date input supports an optional time; omitting the time means midnight at the start of that date.
- Preserve the target's time zone when the device changes time zones. Traveling must not change the target instant.
- Show the milestone title with its countdown in both the app and widget.
- Allow the user to reorder milestones in the app. Widgets rotate through selected milestones in their relative saved order.

Fictional example: a milestone titled "Personal milestone" targets January 1, 2030, with a user-selected background photo. Development examples must not disclose the user's actual plans.

### R-02: Photos and presentation

- Associate one manually selected photo with each milestone.
- Use the same milestone photo in the app and widget.
- Allow photo replacement after setup.
- Allow a milestone to be saved without a photo; show a built-in background until a photo is selected.
- Use the photo as the background, with the title and remaining-time numbers as the main foreground content.
- Keep the presentation focused on typography and imagery. Life-progress bars and grids are outside v0.1.

### R-03: Countdown formats

Each milestone has its own display configuration.

| Format | Configuration | Example |
| --- | --- | --- |
| Type 1 | Choose total days, total weeks, or total hours | "825 days remaining" |
| Type 2 | Days plus hours, minutes, and seconds | "825 days 12:34:56" |

- Default a new milestone to Type 1, using days.
- Count a day as 24 hours, a week as seven such days, and an hour as 60 minutes. Both formats use the remaining duration, rather than calendar-date differences.
- Type 1 displays whole completed units of remaining time, without decimal places.
- When a positive duration is shorter than the selected unit, show a localized equivalent of "Less than 1 day", "Less than 1 week", or "Less than 1 hour".
- Type 2 includes seconds and uses the system's supported live time presentation mechanisms.
- For example, 26 hours remaining displays as one day in Type 1 days mode and as "1 day 02:00:00" in Type 2.
- At or after the target instant, stop at zero. Never count upward or show a negative remaining duration.
- Reached milestones remain saved and, while selected for widget display, remain in the rotation with their photo, title, and zero countdown. The user can edit their target or turn off widget display without deleting them.

### R-04: Home Screen widgets

- Support small and medium Home Screen widgets.
- Provide a per-milestone display on/off control in the app. Turning display off removes the milestone from the widget rotation while retaining its title, target, photo, display settings, and saved position in the app.
- Enforce a shared maximum of three selected milestones across all widget instances. Hidden milestones do not use a widget-selection place.
- When enabling another milestone while three are already selected, ask the user which selected milestone to replace. Apply the change together, keep the displaced milestone saved with widget display off, and preserve the original selection if canceled.
- Allow zero, one, two, or three selected milestones. When none are selected, show a widget state that directs the user to select a milestone in the app.
- Automatically rotate between milestones, changing the photo, title, and countdown together.
- Aim for a rotation interval of approximately 5 to 15 minutes. This is a requested schedule, not a guarantee of exact system delivery times.
- Use a fixed nominal interval of ten minutes in v0.1, without a user-facing interval selector. iOS may adjust the actual update timing.
- Use the order established in the app.
- All small and medium widget instances share the same selected milestone list and order. There are no per-widget milestone selections in v0.1. Exact simultaneous transitions between instances are not guaranteed.
- Tapping any widget opens the app's milestone list, regardless of which milestone is currently displayed.
- Provide both countdown formats, with the presentation configured per milestone.
- Treat live countdown text updates separately from milestone rotation. The photo does not need to change every second.

### R-05: Language

- Localize the app and widgets into Japanese, English, and Indonesian.
- Follow the user's iOS language preferences and any iOS per-app language override.
- Fall back to English when no preferred language is supported.
- Use the iOS per-app language setting rather than adding an in-app language selector in v0.1.
- Write all repository documentation, specifications, code comments, and developer-facing explanations in English. Conversation with the developer remains in Japanese.

### R-06: Platform and storage

- Target iPhone running iOS 27.0 or later.
- Use Swift and SwiftUI, preferring Apple frameworks and standard iOS interactions.
- Save milestones, selected photos, order, and display settings locally.
- After setup and photo import, the core app and widget experience works offline.
- Do not require an application backend or iCloud synchronization for v0.1.
- Require no application-specific account registration.
- Do not transmit milestone details, birth dates, or selected photos from the app to an external application service.
- Do not introduce application-specific usage analytics.

### R-07: Release goal

The v0.1 delivery goal is public availability on the App Store. Local builds and previews are intermediate milestones, not evidence of an App Store release.

## Growth and design direction

Support future growth to libraries of 100 to 200 milestones without representing the library as three fixed storage slots. Keep stable milestone identities, saved order, photo references, and widget visibility separate from the three-item widget-selection policy. Validate representative larger libraries during implementation; no performance result is claimed yet.

The fourth-selection replacement interaction is confirmed in R-04. Exact list layout remains a design proposal in [design.md](design.md).

## Acceptance criteria

The following define the acceptance contract. Execution status and evidence are maintained in tasks.md.

| ID | Observable outcome | Requirement |
| --- | --- | --- |
| AC-01 | Create titled milestones using date input or birth-date plus target-age input, including more than three saved milestones. Age mode calculates the birthday for that age. Reopening the app preserves milestones, input settings, and visibility. | R-01, R-06 |
| AC-02 | An omitted target time resolves to the start of the chosen date in the saved target time zone. An explicitly chosen time is preserved. | R-01 |
| AC-03 | Changing the device time zone does not change a saved target instant. | R-01 |
| AC-04 | A selected photo and milestone title appear consistently in the app preview and small and medium widgets. | R-01, R-02, R-04 |
| AC-05 | A milestone without a photo has a readable built-in background; adding or replacing its photo preserves its other settings. | R-02 |
| AC-06 | Each milestone independently selects Type 1 days/weeks/hours or Type 2. New milestones default to Type 1 days. | R-03 |
| AC-07 | Type 1 shows whole units without decimal places and uses a less-than-one-unit label for a positive subunit remainder. | R-03 |
| AC-08 | Type 2 presents days and hours/minutes/seconds, including durations longer than 24 hours, using supported widget time rendering. | R-03, R-04 |
| AC-09 | A target in the past or at the current instant displays zero, never negative time or elapsed time. It remains in the widget rotation while selected for display. | R-03, R-04 |
| AC-10 | The widget's scheduled sequence includes only selected milestones in their relative saved order, changing the title, photo, and countdown as one item. | R-01, R-04 |
| AC-11 | Rotation uses a fixed nominal ten-minute schedule with no interval selector. Device verification records observed timing and iOS delays without claiming a strict refresh guarantee. | R-04 |
| AC-12 | Japanese, English, and Indonesian are complete and readable in the app and both widget sizes; system language selection, per-app overrides, and English fallback work. | R-05 |
| AC-13 | Existing milestones, imported photos, and countdowns remain available offline after app relaunch. | R-06 |
| AC-14 | Core flows work on an iPhone running the minimum supported OS. App Store release status is reported separately from build or test status. | R-06, R-07 |
| AC-15 | Multiple small and medium widget instances share the same selection of at most three milestones and its order, without per-instance milestone selections. | R-04 |
| AC-16 | Tapping a small or medium widget opens the milestone list, including when the app starts from a closed state or the displayed milestone has been deleted. | R-04 |
| AC-17 | Age input for a February 29 birth date resolves to February 28 in a non-leap target year and February 29 in a leap target year, applying the saved target time and zone. | R-01 |
| AC-18 | Additional milestones can be saved while three are selected for widget display. Editing overwrites saved values without creating a copy or user-visible revision history. Deletion removes the milestone and any widget selection; an empty library shows a setup state. | R-01, R-04 |
| AC-19 | Turning widget display off preserves the milestone and its photo/settings in the app; turning it back on restores eligibility in the saved order. No more than three are selected. With all display controls off, no saved milestone is deleted or rotated into the widget. | R-01, R-04 |
| AC-20 | The app requires no app-specific account, contains no application-specific analytics integration, and does not send milestones, birth dates, or selected photos to external application services. | R-06 |
| AC-21 | A synthetic library of 200 milestones persists and reopens, with at most three selected for widgets. No library-count restriction prevents saving records; widget rendering does not load every library photo into memory. | R-01, R-04, R-06 |
| AC-22 | Enabling a fourth milestone offers replacement of one currently selected milestone. Confirming leaves exactly three selected and preserves the displaced record, photo, and settings. Canceling leaves the original selection unchanged; no intermediate state with four selected milestones is saved. | R-01, R-04 |

## Quality expectations

- Keep milestone titles and countdown text readable over bright, dark, and visually busy photos.
- Provide meaningful VoiceOver labels and localized time-unit wording; do not rely only on color or animation.
- Check small and medium widgets for long titles, large duration values, and all three languages.
- Respect standard system appearance, accessibility, and reduced-update behavior.
- Keep user photos, birth dates, milestone details, and other personal data out of repository files, fixtures, logs, and shared screenshots. Use synthetic examples for development evidence.

## Outside v0.1

- Automatic photo selection, photo slideshows within a milestone, and "On This Day" memories.
- Nearby-photo discovery, location access, and geographic memory exploration.
- iCloud synchronization and an application backend.
- Lock Screen widgets, large widgets, and a dedicated iPad experience.
- Life-progress grids or bars.

These boundaries keep the first release focused; they do not define a future roadmap.

## Remaining review and feasibility work

- P-01 (duration arithmetic) has been accepted and incorporated into R-03. Its identifier is retained here for decision history; the remaining proposals keep their original identifiers.
- P-02 (birth-date and target-age input) has been accepted and incorporated into R-01. Calendar edge cases remain identified separately in the design.
- P-03 (shared rotation) has been accepted and incorporated into R-04. Different widget instances share the list and order; their exact display times may differ.
- P-04 (basic milestone management) has been resolved in R-01: saved milestones have no application-imposed count limit, editing overwrites an existing milestone, and deletion is supported. The shared widget selection is limited to three and can be changed without deletion.
- P-05 (fixed nominal ten-minute rotation without an interval selector) has been accepted and incorporated into R-04.
- Widget-tap navigation has been confirmed as opening the milestone list and incorporated into R-04. The earlier proposal to open the displayed milestone's editor does not apply.
- P-06 (local operation and privacy) has been accepted and incorporated into R-06.
- The fourth-selection replacement flow is accepted and incorporated into R-04 and AC-22.
- Verify the exact Type 2 day-plus-time format, zero stopping, long durations, and localization with the supported live-text APIs inside a real widget. A documentation example is not proof of the complete format.
- The February 29 birthday policy has been accepted and incorporated into R-01. Review remaining daylight-saving-time handling in [design.md](design.md).
- Review widget layout previews once implementation is authorized. Exact typography, photo framing, and overlay treatments remain design work.

## Related documents

- [Design and verification plan](design.md)
- [Tasks and handoff](tasks.md)
