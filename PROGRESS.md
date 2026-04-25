# Progress

## Current milestone

**M6 — History view**

Goal: Per spec §8, add a History tab showing days with activity (newest first, grouped by month, row format `"Monday, Apr 20 — 85 pushups"`), and a tappable `DayDetailView` showing that day's set timeline (read-only in v1).

Exit criteria:
- [ ] History tab in `AppShell` replaced from placeholder `Text("History")` with a real `HistoryView`
- [ ] `HistoryView` lists days with at least one set, newest first, grouped by month
- [ ] Each row shows the formatted date and the daily total
- [ ] Tapping a row navigates to a `DayDetailView` that shows the set timeline for that day (read-only)
- [ ] Days/totals are derived from `PushupSet` records via `PushupCore` (SwiftData is source of truth)
- [ ] No third-party deps; SwiftUI only
- [ ] `swift test --package-path PushupCore` passes (add tests if a new derivation helper lands in `PushupCore`)
- [ ] Full `xcodebuild test` on `PushupTracker` passes
- [ ] Zero warnings under Swift 6 strict concurrency
- [ ] Committed with message `M6: <description>`

## Completed

- [x] M1 — Project skeleton (commit fe154af)
- [x] M2 — Data model + store (commit 94e7443)
- [x] M3 — Today view (commit 3f35911)
- [x] M4 — HealthKit service (commit a3cd20f)
- [x] M5 — Settings view (commit pending)

## Remaining

- [ ] M6 — History view
- [ ] M7 — Trends view
- [ ] M8 — Home Screen widget
- [ ] M9 — Lock Screen widget
- [ ] M10 — Polish pass

## Last iteration notes

Closed out M5 by wiring the "Sync now" button to the same `HealthSyncController` used on foreground. Refactored `HealthSyncController.syncToday()` into a generalized `private func syncDay(_ day: Date)` that takes any target date — kept the existing fetch-by-day-window + `WorkoutSynthesizer.plan(for:on:)` + `service.sync(dayID:plan:)` + `healthKitSyncedAt` stamping logic identical, just parameterized on `day` instead of always `Date()`. Added `func syncNow() async` that calls `requestAuthorizationIfNeeded()` then `syncDay(today)` then `syncDay(yesterday)` (yesterday derived via `Calendar.current.date(byAdding: .day, value: -1, ...)`), per spec §6 manual-sync trigger. The foreground path (`appBecameActive`) now calls `syncDay(Date())`. Plumbed an `onSyncNow: () async -> Void` closure from `PushupTrackerApp` (capturing `await syncController.syncNow()`) through `AppShell` into `SettingsView`. In `SettingsView`, added a "Sync now" button under the Health section that wraps the call in a `Task` with an `isSyncing` flag (disables the button while in flight) and calls `refreshStatus()` after the sync completes so any newly granted/denied state reflects in the UI. Touched 4 files (`HealthSyncController.swift`, `SettingsView.swift`, `AppShell.swift`, `PushupTrackerApp.swift`) — slightly above the typical 3-file cap, but the change is one tightly coupled feature with no good way to split it without leaving a half-wired button. `swift test --package-path PushupCore`: 21/21 passed (no package changes). `xcodebuild test` on iPhone 17 Pro / OS=latest: TEST SUCCEEDED in ~41s with zero warnings. Saw the now-familiar SourceKit "No such module 'PushupCore'" indexer-cache stale diagnostic on all four edited files; ignored, as the real build resolved the package fine. M5 exit criteria all met; promoted M6 — History view to current milestone with concrete exit criteria from spec §8.

### Earlier iteration notes

Wired the HealthKit authorization status into `SettingsView`. Replaced the placeholder Health section with a `LabeledContent("Permission", value: …)` row driven by a `@State` `HealthKitAuthorizationStatus`, refreshed in a `.task { await healthService.authorizationStatus() }`; status maps to "Granted" / "Denied" / "Not Determined". When the status is `.denied`, an "Open Health Settings" button appears that opens `URL("x-apple-health://")` via `@Environment(\.openURL)` — there is no public deep link to a specific app's Health permissions, so this jumps to the Health app where the user can navigate to Sources → Pushup Tracker. To get the service into the view, threaded `any HealthKitService` from `PushupTrackerApp` (now holding `let healthService: any HealthKitService` alongside the sync controller, instantiating one `HealthKitServiceLive()` and sharing it with both `HealthSyncController` and `AppShell`) → `AppShell(healthService:)` → `SettingsView(healthService:)`. Did not introduce an environment-key wrapper since only one consumer needs it; passing as an init parameter stayed within the 3-file cap. "Sync now" button is still pending — deferred to keep this iteration to 3 files and below the line cap. `swift test --package-path PushupCore`: 21/21 passed (no package changes). `xcodebuild test` on iPhone 17 Pro / OS=latest: TEST SUCCEEDED in ~38s with zero warnings. Saw the now-familiar SourceKit "No such module 'PushupCore'" indexer-cache stale diagnostic on all three edited files; ignored, as the real build resolved the package fine.

### Earlier iteration notes

Extended `HealthKitService` with an `authorizationStatus() async -> HealthKitAuthorizationStatus` accessor so the upcoming Settings UI can display granted / denied / not determined without driving a re-prompt. Added a public `HealthKitAuthorizationStatus` enum (Sendable, Equatable) in `HealthKitService.swift` alongside the protocol. In `HealthKitServiceLive`, the implementation guards `HKHealthStore.isHealthDataAvailable()` (returns `.denied` when unavailable so the UI can still surface the "Open Health settings" affordance), reads `authorizationStatus(for:)` for both `HKObjectType.workoutType()` and `HKQuantityType(.activeEnergyBurned)`, then collapses to: `.denied` if either is `.sharingDenied`, `.granted` only if both are `.sharingAuthorized`, otherwise `.notDetermined`. In `HealthKitServiceMock`, added a `status` field with `setAuthorizationStatus(_:)` setter and a `statusCallCount` counter mirroring the existing `authorizationCallCount` pattern. Added a single Swift Testing test `authorizationStatus returns configured value and counts calls` covering all three states and call counting. `swift test --package-path PushupCore`: 21/21 passed (1 new). `xcodebuild test` on `iPhone 17 Pro / OS=latest`: TEST SUCCEEDED in ~35s with zero warnings — confirmed the protocol change didn't break the existing `HealthSyncController` consumer in the app target. Did not touch `SettingsView` this iteration; wiring the status into the UI (and the "Open Health settings" link + "Sync now" button) remains for the next iteration.

### Earlier iteration notes

Started M5 with the smallest scaffold slice. Created `PushupTracker/Views/Settings/SettingsView.swift` — a `NavigationStack` wrapping a `Form` with two sections. The "Health" section is a placeholder (`Text("HealthKit status will appear here.")` in secondary foreground style); wiring real authorization status + "Sync now" is deferred because exposing status requires extending the `HealthKitService` protocol with a status accessor plus mock + tests + live impl, which would push this iteration past the 1–3 file cap. The "About" section uses `LabeledContent` rows for Version (`CFBundleShortVersionString`), Build (`CFBundleVersion`), and Credits, plus a `Link` to a `mailto:feedback@example.com?subject=Pushup%20Tracker%20feedback` placeholder URL — see Open question. Replaced the `Text("Settings")` placeholder in `AppShell.swift` with `SettingsView()`. No `pbxproj` edits needed because the app target uses a file-system-synchronized group (M3's `UndoBanner.swift` confirmed this — no entries appear in `project.pbxproj`). `xcodebuild test` passed (TEST SUCCEEDED, ~38s, zero warnings). Did not run `swift test --package-path PushupCore` because no package code changed. M5 exit criteria still open: HK auth status display, denied-state link to Health.app, "Sync now" button wired to the same service used on foreground.

### Earlier iteration notes

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
