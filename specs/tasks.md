# Life Is Short: v0.1 Tasks and Handoff

Status: Working development build; physical-device and distribution validation remain open

Requirements: [requirements.md](requirements.md)
Design: [design.md](design.md)

## Discovery and specification

- [x] Read AGENTS.md and inspect the existing repository.
- [x] Read the reference repository's SDD workflow and specification templates.
- [x] Discover the primary experience, milestone input, photos, countdown formats, widgets, rotation, localization, storage, and release goal.
- [x] Draft the three English specification documents, separating confirmed requirements from proposed defaults and feasibility work.
- [x] Confirm P-01: count remaining days in 24-hour units, with the same duration underlying both formats.
- [x] Confirm P-03: all small and medium widget instances share the milestone list and order.
- [x] Confirm widget-tap navigation: open the milestone list rather than the displayed milestone's editor.
- [x] Confirm P-02: calculate the target birthday from an entered birth date and target age.
- [x] Confirm P-05: use a fixed nominal ten-minute rotation cadence without an interval selector.
- [x] Confirm the February 29 birthday policy: use February 28 in a non-leap target year.
- [x] Resolve P-04: save milestones without an application-imposed record-count limit, overwrite edits, and permit deletion; limit the shared widget selection to three.
- [x] Confirm zero to three selected milestones and changing the selection without deleting saved records.
- [x] Confirm P-06: no application-specific account, external transmission of milestone/birth-date/photo data, or application-specific usage analytics.
- [x] Record per-milestone widget visibility and the design direction for libraries of 100 to 200 records.
- [x] Confirm fourth-selection replacement: choose a selected milestone to replace, retain its saved record, and preserve the previous selection when canceled.
- [x] Select documented Gregorian/leap-day/daylight-saving defaults under the delegated development authority; deterministic verification remains required.
- [x] Record authorization to implement autonomously with issues, PRs, and relevant verification.

## Planned implementation outcomes

Track implementation below and in the linked issues. A checked outcome requires recorded evidence, not just code.

| ID | Outcome | Dependencies | Acceptance coverage |
| --- | --- | --- | --- |
| T-01 | Prove supported widget rendering for Type 2 and zero stopping on iOS 27; inspect small and medium layouts | Specification review and implementation authorization | AC-08, AC-09 |
| T-02 | Prepare shared app/widget code boundaries, widget target, local App Group setup, and iPhone configuration | T-01 findings; confirmed target setup | AC-04, AC-14 |
| T-03 | Implement the milestone model, date/age resolution, saved-zone semantics, and both countdown calculation rules | Accepted time policies | AC-01, AC-02, AC-03, AC-06, AC-07, AC-09, AC-17 |
| T-04 | Implement versioned local persistence and selected-photo import with atomic updates, no library-count cap, three-item widget-selection validation, visibility/overwrite/deletion semantics, replacement, and fallback behavior | T-02, T-03 | AC-01, AC-04, AC-05, AC-13, AC-18, AC-19, AC-20, AC-21, AC-22 |
| T-05 | Build the library list, widget visibility controls, milestone editor, three-item selection limit and replacement flow, overwrite/reorder/delete flows, and shared previews | T-03, T-04 | AC-01, AC-02, AC-04, AC-05, AC-06, AC-10, AC-18, AC-19, AC-22 |
| T-06 | Build small/medium widgets, rotation among selected milestones, all-hidden state, reached-target retention, and navigation to the milestone list | T-01, T-02, T-04, T-05 | AC-04, AC-06, AC-07, AC-08, AC-09, AC-10, AC-11, AC-15, AC-16, AC-19, AC-21 |
| T-07 | Complete Japanese/English/Indonesian localization and accessibility across settings and widgets | T-05, T-06; localization should be established throughout earlier tasks | AC-12; cross-cutting quality expectations |
| T-08 | Establish suitable PR validation and record relevant build/test evidence; only then require available checks | Buildable targets and meaningful tests | Relevant automated acceptance checks; PR workflow |
| T-09 | Verify the integrated experience on iPhone, including photos, offline operation, privacy, zones, zero, rotation, multiple widget instances, navigation, visibility/selection limits, replacement, and a synthetic 200-record library | T-03 through T-08 | AC-01 through AC-22, excluding App Store release itself |
| T-10 | Prepare App Store assets/metadata and distribution validation; separately perform submission and verify release when authorized | Accepted app, T-09, required distribution setup | R-07, AC-14 |

Create scoped issues and branches when those outcomes become ready. Link requirements, design, acceptance criteria, PRs, and validation evidence without copying whole specifications into issue comments.

## Completion rules

- Each implementation outcome must identify the exact acceptance criteria it satisfies.
- Run relevant checks and resolve failures within the accepted scope.
- Actually inspect rendered app/widget screens before declaring visual checks complete.
- Treat widget refresh requests as requests; record actual runtime observations and limitations.
- Review the outgoing diff, secrets, personal data, and commit identities before committing or publishing changes.
- Follow the repository's PR protection. Do not push or merge without the necessary authorization.
- Distinguish drafted specifications, implemented code, tested behavior, merged changes, and verified App Store availability.

## Issue tracking

| Issue | Outcome |
| --- | --- |
| [#1](https://github.com/pumpkinpietea/life-is-short/issues/1) | v0.1 delivery umbrella |
| [#2](https://github.com/pumpkinpietea/life-is-short/issues/2) | Specifications, domain, storage, and shared foundation |
| [#3](https://github.com/pumpkinpietea/life-is-short/issues/3) | Settings app, photos, and localization |
| [#4](https://github.com/pumpkinpietea/life-is-short/issues/4) | Small/medium widgets and live countdown |
| [#5](https://github.com/pumpkinpietea/life-is-short/issues/5) | Integrated verification and PR validation |
| [#10](https://github.com/pumpkinpietea/life-is-short/issues/10) | Physical-device validation and App Store preparation |

## Implementation evidence

- [PR #6](https://github.com/pumpkinpietea/life-is-short/pull/6): accepted specification and development instructions, merged.
- [PR #7](https://github.com/pumpkinpietea/life-is-short/pull/7): shared countdown, date/age rules, library, local persistence, and deterministic tests, merged.
- [PR #8](https://github.com/pumpkinpietea/life-is-short/pull/8): PR validation, merged after a successful actual run. `Validate` is now required on protected `main`, including administrators.
- [PR #9](https://github.com/pumpkinpietea/life-is-short/pull/9): native settings, photos, localization, App Group, widgets, and UI integration verification. The PR must pass `Validate` at its final revision before merge.
- Shared verification: 14 tests passed, including Gregorian/leap-day/DST resolution, saved zones, whole units/subunits, zero, replacement rollback, visibility/order/delete, corrupt/invalid snapshots, 200-record persistence, native timer composition, and presentation timeline boundaries.
- Xcode 27.1 builds the app and embedded widget for the iOS 27 simulator and unsigned iPhone Release configuration.
- Simulator app checks passed for create/overwrite/relaunch, all-hidden retention, fourth-selection cancel/replace, saving additional hidden milestones, confirmed deletion, three-language library/editor screens, URL navigation, and date/age validation with saved age input.
- An actual small Home Screen widget rendered a 50-day countdown with an hours/minutes/seconds remainder. Native seconds changed while the app was backgrounded; tapping the widget opened the list. A 35-second fixture reached `0 days 00:00:00` and remained at zero. Small and medium instances crossed from one day to `0 days 23:59:57` using prepared entries and native seconds.
- Visual review includes real simulator screenshots of English/Japanese/Indonesian app screens, the photo editor/library, small and medium photo widgets side by side, the long countdown, and the zero state. All milestones and images in this evidence are synthetic.
- Runtime testing exposed two issues absent from successful builds: widget archives cannot decode the app-defined live format, and a 1,200-by-900 image exceeded the small-widget archive budget. The design records the Apple timer/timeline approach and additional widget image downsampling used to address them.

## Outcome status

| Outcome | Development status | Remaining validation |
| --- | --- | --- |
| T-01 | Native small/medium clock rendering, long durations, zero stopping, and 24-hour boundary observed | Hardware scheduling and reduced-update behavior in #10 |
| T-02 | App/widget targets, shared App Group, iPhone setup, and shared scheme build successfully | Signed hardware provisioning in #10 |
| T-03 | Domain, time policies, and countdown rules implemented and tested | Device-zone interaction in #10 |
| T-04 | Versioned atomic storage, bounded photo import/rendering, visibility, replacement, and record preservation implemented | Offline hardware and broader photo cases in #10 |
| T-05 | Native list/editor, overwrite/delete, reordering, selection controls, replacement, and previews implemented | Hardware accessibility review in #10 |
| T-06 | Small/medium widgets, shared selection/order, rotation, empty state, bounded clock, and list navigation implemented | Ordinary hardware refresh timing in #10 |
| T-07 | All 77 catalog entries include English/Japanese/Indonesian; both built bundles contain all three localizations; three-language app UI checked | All widget languages, OS overrides/fallback, and accessibility on hardware in #10 |
| T-08 | Actual successful CI runs; `Validate` required by branch protection | Maintain this check for future changes |
| T-09 | Domain/storage tests and focused simulator integration/visual checks completed | Remaining hardware matrix in #10 |
| T-10 | Release follow-up issue prepared | App Store preparation and separately authorized submission in #10 |

A synthetic 200-record library was opened, edited through the native editor, and reopened successfully. The persistence test independently verifies the record count and the maximum of three selected records. A runtime rotation fixture retained the normal 600-second cadence and placed its anchor 570 seconds in the past; small/medium widgets transitioned from the first selected milestone to the second. This tests a scheduled transition without claiming that 30 seconds is the product's rotation cadence or a hardware timing result.

Acceptance coverage combines deterministic checks for AC-01/02/03/06/07/09/10/17/18/19/21/22, simulator app/widget evidence for AC-01/04/05/08/09/12/15/16/18/19/21/22, and source/resource inspection for AC-13/20. AC-11, the hardware aspects of AC-03/12/13/14/15/16, and App Store availability remain explicitly assigned to #10 and the open parent issue #1.

## Device and release handoff

[Issue #10](https://github.com/pumpkinpietea/life-is-short/issues/10) tracks hardware and distribution checks. These remain open; simulator evidence is not App Store availability.

- Signed physical-iPhone installation requires an appropriate development team and shared App Group provisioning.
- Observe ordinary ten-minute rotation, multiple instances, actual refresh delays, reduced-update behavior, and boundary transitions on hardware.
- Review all widget languages, iOS per-app language override, unsupported-language fallback, VoiceOver, large text, contrast, and dark/light appearance on hardware.
- Verify imported photos after relaunch without networking and saved targets across a device-zone change. Core zone arithmetic and local storage are already covered by deterministic tests.
- Prepare final screenshots, metadata, privacy/support information, and distribution validation; perform App Store submission only when separately authorized.

No credentials, provisioning profiles, personal images, or private conversational plans are stored in the repository. Build logs, result bundles, and working screenshots remain in ignored local build output.
