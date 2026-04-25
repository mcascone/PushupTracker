# Progress

## Current milestone

**M5 — Settings view**

Goal: Add the Settings tab per spec §8 — a visible HealthKit section (permission status: granted / denied / not determined, with an "Open Health settings" link when denied), a "Sync now" button that syncs today + yesterday on demand, and an About section (app version, build number, credits, feedback link). No new user-configurable settings in v1.

Exit criteria:
- [ ] Settings tab in `AppShell` replaced from placeholder `Text("Settings")` with a real `SettingsView`
- [ ] `SettingsView` shows current HealthKit authorization status (granted / denied / not determined)
- [ ] When denied, a control opens `Health.app` permissions (or surfaces fallback guidance)
- [ ] "Sync now" button manually syncs today + yesterday via the same `HealthKitService` used on foreground
- [ ] About section shows `CFBundleShortVersionString`, `CFBundleVersion`, credits text, and a feedback link target (TBD email — placeholder acceptable, surface as Open question)
- [ ] No third-party deps; SwiftUI only
- [ ] `swift test --package-path PushupCore` passes
- [ ] Full `xcodebuild test` on `PushupTracker` passes
- [ ] Zero warnings under Swift 6 strict concurrency
- [ ] Committed with message `M5: <description>`

## Completed

- [x] M1 — Project skeleton (commit fe154af)
- [x] M2 — Data model + store (commit 94e7443)
- [x] M3 — Today view (commit 3f35911)
- [x] M4 — HealthKit service (commit a3cd20f)

## Remaining

- [ ] M6 — History view
- [ ] M7 — Trends view
- [ ] M8 — Home Screen widget
- [ ] M9 — Lock Screen widget
- [ ] M10 — Polish pass

## Last iteration notes

Closed out M4 by wiring foreground sync into the app target. Added `PushupTracker/Services/HealthSyncController.swift` as a `@MainActor` final class holding a `ModelContainer` and an `any HealthKitService`. `appBecameActive()` cancels any in-flight debounce and schedules a `Task` that sleeps 1s, then runs `requestAuthorizationIfNeeded()` (one-shot, guarded by `didRequestAuthorization`) followed by `syncToday()`. `syncToday()` builds a fresh `ModelContext` from the container, fetches `PushupSet` records whose `timestamp` falls in `[startOfDay, startOfTomorrow)` via `FetchDescriptor` + `#Predicate`, asks `WorkoutSynthesizer.plan(for:on:)` for the plan (nil for zero sets, which is the delete-only path the live service already handles), and `WorkoutSynthesizer.dayID(for:)` for the `dayID`. On a successful `service.sync(dayID:plan:)`, stamps `healthKitSyncedAt = .now` on every set in the fetched array and saves the context. Failures are logged via `os.Logger` subsystem `app` and do not delete or modify local data, per invariant §13. Updated `PushupTrackerApp` to instantiate the controller in `init` (with `HealthKitServiceLive()` as the service) using `@State` (Swift 6 / SwiftUI Observable pattern — no `ObservableObject` needed for a non-published controller) and to call `syncController.appBecameActive()` in an `.onChange(of: scenePhase)` handler when the new phase is `.active`. Cold-launch covers "first launch" since scenePhase transitions to `.active` then. The controller is plain `final class`, not `@Observable`, since the app doesn't read any state from it. Surprise: SourceKit emitted a stale "No such module 'PushupCore'" diagnostic for both the new file and the edited app entry-point right after the writes, but the actual `xcodebuild test` build resolved the package fine and ran `TEST SUCCEEDED` in ~42s with zero compiler warnings; treated those diagnostics as indexer cache lag, not real errors. `swift test --package-path PushupCore`: 20/20 passed. M4 exit criteria are now all checked off; promoted M5 — Settings view to current milestone with concrete exit criteria from spec §8.

### Earlier iteration notes

Added the HealthKit Info.plist key and entitlement on the app target (config-only iteration; no Swift code touched). In `PushupTracker.xcodeproj/project.pbxproj`, added `INFOPLIST_KEY_NSHealthUpdateUsageDescription = "Pushup Tracker adds your pushup sets to Apple Health as workouts so your activity is captured in one place."` to both the Debug and Release `XCBuildConfiguration` blocks for the app target (next to the existing `INFOPLIST_KEY_*` settings; widget target untouched, per spec §6 — no `NSHealthShareUsageDescription` since we don't read). In `PushupTracker/PushupTracker.entitlements`, added `<key>com.apple.developer.healthkit</key><true/>` alongside the existing App Group entry. Did not add the `com.apple.developer.healthkit.access` array — spec §6 only requires the boolean entitlement plus the usage description; the access-types array is optional and only narrows what HK clinical-record categories the app may request, which we don't use. Ran the full `xcodebuild test` on `iPhone 17 Pro / OS=latest`: TEST SUCCEEDED in ~41s, codesign embedded the new HealthKit entitlement into `PushupTracker.app.xcent` cleanly. Did not run `swift test --package-path PushupCore` since no package code changed. Remaining for M4: foreground-sync wiring in the app target (instantiate `HealthKitServiceLive`, request authorization on first launch, debounce 1s on foreground, build plan via `WorkoutSynthesizer`, call `sync(dayID:plan:)`, then stamp `healthKitSyncedAt` on every set for the synced day).

### Earlier iteration notes

Added `HealthKitServiceLive` (`Sources/PushupCore/HealthKit/HealthKitServiceLive.swift`) as an `actor` implementing the `HealthKitService` protocol. `requestAuthorization()` short-circuits to `false` when `HKHealthStore.isHealthDataAvailable()` is false, otherwise requests share-only access to `HKObjectType.workoutType()` and `HKQuantityType(.activeEnergyBurned)` with no read types, then derives the boolean result from `authorizationStatus(for:)` on both types (`.sharingAuthorized` on each → true). `sync(dayID:plan:)` does delete-then-rewrite per spec §6: queries existing workouts via `HKQuery.predicateForObjects(withMetadataKey:allowedValues:)` matching `Constants.dayIDMetadataKey`, deletes any hits, and if `plan` is non-nil drives an `HKWorkoutBuilder` (configuration `.functionalStrengthTraining`, device `.local()`) through `beginCollection` → `addWorkoutActivity` per set (each carrying a fresh `HKWorkoutConfiguration`, the activity's start/end, and metadata `["PushupCount", "PushupSetID"]`) → `addSamples([HKQuantitySample])` for total active energy in kcal spanning the workout window → `addMetadata([dayIDMetadataKey, "PushupTrackerVersion"])` → `endCollection` → `finishWorkout`. Whole file is gated behind `#if canImport(HealthKit)`. The sample query uses `withCheckedThrowingContinuation` rather than the iOS 15+ async query API, since the iOS 18 deployment target doesn't preclude the older callback API and it sidesteps a Sendable warning. Surprise: macOS 26 SDK now ships HealthKit, so the file compiled on the macOS test host (rather than being excluded), which actually surfaced a renamed initializer — `HKWorkoutActivity(workoutConfiguration:startDate:endDate:metadata:)` → `init(workoutConfiguration:start:end:metadata:)`. Fixed and re-ran. `swift test --package-path PushupCore` passes 20/20 — no new tests added since the live impl needs a real HKHealthStore and the mock + synthesizer cover the testable surface. Did not touch app/widget code, so no xcodebuild run. Still remaining for M4: Info.plist `NSHealthUpdateUsageDescription` key, HealthKit entitlement on the app target, foreground-sync wiring, and stamping `healthKitSyncedAt` on success.

### Earlier iteration notes

Added the `HealthKitService` protocol (`Sources/PushupCore/HealthKit/HealthKitService.swift`) with two async methods: `requestAuthorization() -> Bool` and `sync(dayID:plan:)`. Chose to take a pre-built `WorkoutPlan?` (nil = delete-only for zero-set days) rather than `[PushupSet]` so the protocol stays Sendable-clean — `PushupSet` is a `@Model` class and not safe to ferry across actor boundaries. The caller (app) will use `WorkoutSynthesizer.plan(for:on:)` to build the plan, hand it to the service, then stamp `healthKitSyncedAt` on its own SwiftData side after success. Added `HealthKitServiceMock` as an `actor` that records `authorizationCallCount` and a list of `SyncCall(dayID:plan:)` and exposes setters for `authorizationResult`, `authorizationError`, and `syncError` so tests can drive both happy and failure paths. Added `HealthKitServiceMockTests` covering: authorization call-count + return value, authorization error propagation, sync recording dayID+plan (including nil-plan delete case) preserving order, and sync error propagation without recording the call. `swift test --package-path PushupCore` now passes 20/20 (4 new). Did not touch app/widget code, so no xcodebuild run. Live HK impl, Info.plist key, entitlement, and foreground-sync wiring remain.

### Earlier iteration notes

Started M4 with the smallest pure slice: added `Sources/PushupCore/Constants.swift` (with `secondsPerPushup`, `kcalPerPushup`, `dayIDMetadataKey`, and `activityType` gated behind `#if canImport(HealthKit)` so the package still builds for macOS-hosted tests) and `Sources/PushupCore/HealthKit/WorkoutSynthesizer.swift`, a pure namespace producing a `WorkoutPlan` value (`dayID`, `start`, `end`, `totalCount`, `totalEnergyKcal`, `[Activity]`) from `[PushupSet]` for a given day. The synthesizer filters via `Calendar.isDate(_, inSameDayAs:)`, sorts ascending by timestamp, and computes per-activity end as `timestamp + secondsPerPushup * count`. dayID is formatted with a fresh `DateFormatter` per call (gregorian + en_US_POSIX) using the supplied calendar's timezone — keeps it deterministic without relying on a non-Sendable static formatter under Swift 6 strict concurrency. Tests live in `Tests/PushupCoreTests/WorkoutSynthesizerTests.swift` and pin a New York timezone so the day-boundary cases are deterministic; covers empty input, no-match, sort order, cross-day exclusion, end-time math, plan span, totals, and dayID format. `swift test --package-path PushupCore` passes 16/16 (8 new). No app/widget code touched, so no xcodebuild run this iteration. HealthKit service protocol, live impl, mock, Info.plist key, entitlement, and foreground sync wiring remain for subsequent M4 iterations.

### Earlier iteration notes

Added the 5-second undo banner to complete M3. Created `PushupTracker/Views/Common/UndoBanner.swift` as a small reusable view: a message label + Undo button on a `.thinMaterial` rounded background, with a move/opacity transition. Wired it into `TodayView` via `.safeAreaInset(edge: .bottom)` so it sits pinned above the tab bar. Added three pieces of state to `TodayView`: `pendingUndoSetID: PersistentIdentifier?`, `pendingUndoCount: Int`, and `undoDismissTask: Task<Void, Never>?`. `add(_:)` now calls `showUndoBanner(for:count:)` after inserting; the helper cancels any in-flight dismiss task, captures the new set's `persistentModelID` and count, then schedules a `Task` that sleeps for 5s and clears the banner only if the same id is still pending (so a fresh log resets the timer cleanly). `undoLastLog()` looks up the pending set in `todaySets` by `persistentModelID` and deletes it via `modelContext`. Also taught `deleteSets(at:)` to cancel the banner if the user swipe-deletes the same set the banner refers to, preventing a stale undo from firing. Tests pass: `swift test --package-path PushupCore` 8/8, full `xcodebuild test` succeeded, no source warnings. Promoted M4 to current milestone with exit criteria drawn from spec §6.

## Open questions

- M5 About section needs a feedback email address (spec §8 says "TBD email"). Using a `mailto:` placeholder until the human supplies one.

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
