# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Source of truth: spec.md + PROGRESS.md

This project is built with the **Ralph loop**: each iteration the agent reads `spec.md` and `PROGRESS.md` in full, picks the smallest next unit of work, executes, tests, updates `PROGRESS.md`, and commits with `M<n>: <description>`. Trust those two files over assumptions.

- `spec.md` — locked decisions, architecture, invariants. **Never edit.** If wrong, add an entry to `PROGRESS.md` "Open questions".
- `PROGRESS.md` — current milestone, completed work, last-iteration notes (past-tense facts only — no plans), open questions, blockers.
- `ralph_prompt.md` — the canonical loop protocol the agent follows each iteration.
- `BOOTSTRAP.md` — one-time Xcode/App Group/HealthKit setup notes.

v1 milestones (M1–M10) are complete. Further work should still respect the loop's invariants below.

## Build & test

```bash
# Fast iteration: PushupCore unit tests (Swift Testing)
swift test --package-path PushupCore

# Full app + widget build
xcodebuild -project PushupTracker.xcodeproj -scheme PushupTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' build

# Full test suite
xcodebuild -project PushupTracker.xcodeproj -scheme PushupTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' test
```

If `iPhone 17 Pro` isn't installed, run `xcrun simctl list devices available` and substitute any iPhone-class simulator. `OS=latest` is fine — the iOS 18 deployment target only constrains runtime, not the simulator OS.

Release (signed archive + `xcodebuild -exportArchive` + `xcrun altool --upload-app`) is **manual, CLI-driven**, run by the human per `spec.md` §10. The loop does not perform releases.

## Architecture (the big picture)

Three targets, one shared package:

- **`PushupTracker`** (app target) — SwiftUI `TabView` with Today / History / Trends / Settings. Owns HealthKit entitlement and `HealthSyncController` (in `PushupTracker/Services/`).
- **`PushupWidgets`** (widget extension) — Home Screen (`.systemSmall`, `.systemMedium`) and Lock Screen (`.accessoryCircular`, `.accessoryRectangular`). Interactive via `LogPushupsIntent` / `UndoLastSetIntent`.
- **`PushupCore`** (local Swift package) — shared by both targets. Models (`PushupSet` `@Model`), persistence facade (`PushupStore`), shared `ModelContainer` factory, HealthKit service (protocol + live + mock), `WorkoutSynthesizer`, `Constants`. All business logic lives here so it's testable without app scaffolding.

**Data flow invariants:**

- **SwiftData is the source of truth.** HealthKit is a derived projection — never read from HealthKit to populate UI.
- The SwiftData store lives in the App Group container `group.com.mcmusicworkshop.pushuptracker` so app and widget share one database. Always construct the `ModelContainer` via `SharedContainer.makeModelContainer()` in `PushupCore/Persistence/`. Using `.modelContainer(for: PushupSet.self)` directly puts the store in the app sandbox and the widget sees an empty database.
- HealthKit sync uses **delete-and-rewrite per day**: one `HKWorkout` per calendar day with nested `HKWorkoutActivity` per set, identified by `Constants.dayIDMetadataKey`. Triggered on app foreground (debounced 1s), after each widget log, and via Settings → "Sync now".
- Widget intents must be **idempotent** at the SwiftData layer.
- Never delete local data to resolve a HealthKit error — log + surface in Settings instead.

Bundle IDs: app `com.mcmusicworkshop.PushupTracker`, widget `com.mcmusicworkshop.PushupTracker.PushupWidgets`. Team `9WNXKEF4SM`.

## Project conventions

- Swift 6, strict concurrency on. SwiftUI only (no UIKit except where WidgetKit / App Intents require).
- **No third-party dependencies.** If one seems necessary, stop and add to `PROGRESS.md` Open questions.
- Locked widget increments: `+1, +5, +10, +25` (not user-configurable).
- Out-of-scope for v1 (do not implement, even opportunistically): goals, streaks, notifications, watchOS, Control Center widget, export, iCloud sync, editing past sets, localization, iPad layouts, HealthKit *read*. Full list in `spec.md` §3.
- Don't rewrite code from earlier milestones unless fixing a real bug — and note it in `PROGRESS.md` if you do.
- Logging: `os.Logger` with subsystems `app`, `widget`, `healthkit`, `persistence`. No `print` in shipped code.
- Errors: concrete `enum: Error`. No `NSError`, no stringly-typed errors.
- Access control: `public` only on `PushupCore`'s API surface; otherwise default `internal`.

## Loop discipline

- One iteration = one commit. Commit message: `M<n>: <brief description>`.
- Touch ~1–3 files per iteration; >200 lines of new code means you're doing too much — wrap up and split.
- Tests must pass before marking a milestone complete.
- Familiar harmless noise: SourceKit "No such module 'PushupCore'" stale-index diagnostics on freshly edited files; ignore. The `appintelligenceprocessor` "No AppIntents.framework dependency found" tooling note is also documented and benign.
