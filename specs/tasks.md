# Life Is Short: v0.1 Tasks and Handoff

Status: Implementation in progress; development authorized on 2026-10-25

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

## Current handoff

- Working branch: `docs/v0.1-specification`; foundation implementation will use an issue-linked branch.
- Xcode 27.1 and an iOS 27 simulator are available locally.
- No application feature has passed runtime verification yet.
- First checkpoint: native time-data-source rendering of the complete Type 2 countdown, followed by domain/storage tests and app/widget integration.
- Preserve the distinction between simulator verification, real-device validation, and App Store availability.
