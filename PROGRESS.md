# Progress

## Current milestone

**M4 — HealthKit service**

Goal: Implement HealthKit write integration per spec §6 with no new UI surface beyond what foreground sync needs. Add the `HealthKitService` protocol with a live impl and a mock, build the `WorkoutSynthesizer` that turns a day's `PushupSet` records into one `HKWorkout` with nested `HKWorkoutActivity` per set, and wire up the foreground-sync trigger from the app target. Stamp `healthKitSyncedAt` on success. Tests exercise the mock and the synthesizer.

Exit criteria:
- [ ] `NSHealthUpdateUsageDescription` set in app target Info.plist; no `NSHealthShareUsageDescription`
- [ ] HealthKit entitlement enabled on app target only (not widget)
- [ ] `Constants` enum in `PushupCore` matches spec §6 (`secondsPerPushup`, `kcalPerPushup`, `activityType`, `dayIDMetadataKey`)
- [ ] `HealthKitService` protocol in `PushupCore` with `requestAuthorization()` and `syncDay(_:)` (or equivalent)
- [ ] `HealthKitServiceLive` implements the delete-and-rewrite-per-day algorithm using `HKWorkoutBuilder` with one `HKWorkoutActivity` per set
- [ ] `HealthKitServiceMock` records calls so tests can assert on them
- [ ] `WorkoutSynthesizer` in `PushupCore` is a pure function: `[PushupSet] -> WorkoutPlan` (start/end/activities/energy) — testable without HealthKit
- [ ] On successful sync, every set for that day has `healthKitSyncedAt` stamped
- [ ] App requests authorization on first launch and triggers a sync for today on foreground (debounced 1s)
- [ ] `swift test --package-path PushupCore` passes (including new synthesizer tests)
- [ ] Full `xcodebuild test` on `PushupTracker` passes
- [ ] Zero warnings under Swift 6 strict concurrency
- [ ] Committed with message `M4: <description>`

## Completed

- [x] M1 — Project skeleton (commit fe154af)
- [x] M2 — Data model + store (commit 94e7443)
- [x] M3 — Today view (commit pending — this iteration)

## Remaining

- [ ] M5 — Settings view
- [ ] M6 — History view
- [ ] M7 — Trends view
- [ ] M8 — Home Screen widget
- [ ] M9 — Lock Screen widget
- [ ] M10 — Polish pass

## Last iteration notes

Added the 5-second undo banner to complete M3. Created `PushupTracker/Views/Common/UndoBanner.swift` as a small reusable view: a message label + Undo button on a `.thinMaterial` rounded background, with a move/opacity transition. Wired it into `TodayView` via `.safeAreaInset(edge: .bottom)` so it sits pinned above the tab bar. Added three pieces of state to `TodayView`: `pendingUndoSetID: PersistentIdentifier?`, `pendingUndoCount: Int`, and `undoDismissTask: Task<Void, Never>?`. `add(_:)` now calls `showUndoBanner(for:count:)` after inserting; the helper cancels any in-flight dismiss task, captures the new set's `persistentModelID` and count, then schedules a `Task` that sleeps for 5s and clears the banner only if the same id is still pending (so a fresh log resets the timer cleanly). `undoLastLog()` looks up the pending set in `todaySets` by `persistentModelID` and deletes it via `modelContext`. Also taught `deleteSets(at:)` to cancel the banner if the user swipe-deletes the same set the banner refers to, preventing a stale undo from firing. Tests pass: `swift test --package-path PushupCore` 8/8, full `xcodebuild test` succeeded, no source warnings. Promoted M4 to current milestone with exit criteria drawn from spec §6.

## Open questions

_(empty)_

## Blockers

_(empty)_

---

## How to read this file

- **Current milestone** — the one being worked on right now
- **Completed** — milestones done, with commit SHA
- **Remaining** — milestones not yet started
- **Last iteration notes** — what the most recent loop iteration actually did (past tense, factual, not plans)
- **Open questions** — non-blocking clarifications for the human; work continues around them
- **Blockers** — things that genuinely stop progress; if non-empty, the loop should halt
