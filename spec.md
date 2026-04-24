# Pushup Tracker — Build Spec

**Status**: v1 specification, locked decisions marked 🔒
**Project type**: iOS 18+ native app — Swift / SwiftUI / SwiftData
**Build method**: Ralph loop. Each iteration, the agent reads this spec + `PROGRESS.md`, picks the smallest next unit of work, executes it, updates `PROGRESS.md`, commits, and stops.

---

## 1. What We're Building

A native iOS app for logging pushups done throughout the day in short sets, with:

- An interactive Home Screen and Lock Screen widget for tap-to-log without opening the app
- Automatic sync to Apple Health as a single daily workout, with per-set timing preserved
- A simple history + trends view

Target user: someone who does pushups in informal sets throughout the day (e.g. every time they walk past a doorway) and wants the log to end up in Apple Health without friction.

---

## 2. Locked Decisions 🔒

Decided. Do not revisit during implementation. If a decision looks wrong in practice, surface it under **Open questions** in `PROGRESS.md`; do not silently change course.

| Area | Decision |
|------|----------|
| Minimum iOS | **18.0** |
| UI framework | **SwiftUI** |
| Persistence | **SwiftData** (stored in an App Group container) |
| Testing framework | **Swift Testing** |
| Data model | **Set-level truth, daily-total default view** (hybrid) |
| Widget quick-add buttons | **Fixed: +1, +5, +10, +25** (not user-configurable) |
| HealthKit strategy | **One `HKWorkout` per day containing nested `HKWorkoutActivity` per set**; activity type `.functionalStrengthTraining` |
| Widget surfaces | **Home Screen** (small + medium) and **Lock Screen** (circular + rectangular) |
| Engagement features | **None** — no goals, no streaks, no notifications |
| watchOS app | **Out of scope for v1** |

---

## 3. Feature Scope

### In v1

- **Today view**: today's total as a hero number, four quick-add buttons, per-set timeline
- **History view**: past days with daily totals; tap a day to see its set timeline
- **Trends view**: bar chart of daily totals over 7 / 30 / 90 days (Swift Charts)
- **Settings view**: HealthKit permission status, "Sync now", About
- **Home Screen widget** — `.systemSmall` (total + single `+10`) and `.systemMedium` (total + all four buttons)
- **Lock Screen widget** — `.accessoryCircular` (total as gauge) and `.accessoryRectangular` (total + `+10` button)
- **HealthKit write**: automatic on app foreground and after each widget log (debounced 1s)
- **Undo**: 5-second undo banner after any log, from app or widget; undoing removes the most recent set and re-syncs Health

### Explicitly out of scope for v1

- Daily goals / progress rings
- Streaks
- Notifications or reminders
- Watch app / complication
- Control Center widget (candidate for fast-follow)
- Export (CSV, share sheet)
- iCloud sync across devices
- Editing past sets (only: undo most recent, or delete from today's list)
- Localization beyond English
- iPad-optimized layouts (works on iPad, no bespoke layout)
- User-configurable widget increments
- HealthKit *read* (we only write)

If implementation drifts into anything on the "out of scope" list, stop and add a note in `PROGRESS.md`.

---

## 4. Architecture

### Targets

1. `PushupTracker` — app target
2. `PushupWidgets` — Widget Extension target
3. `PushupCore` — local Swift Package, shared by both targets. Contains models, persistence, HealthKit service, business logic, constants.

Both targets depend on `PushupCore`. Keeping logic in a package makes it trivially testable without iOS app scaffolding.

### App Group

- Identifier: `group.com.mcmusicworkshop.pushuptracker`
- SwiftData store lives inside the App Group so app and widgets share one database
- HealthKit entitlements on app target only — widgets call into shared code that defers HK writes to a sync triggered on next app foreground OR via `BGTaskScheduler` (see §6)

### Bundle identifiers

- App: `com.mcmusicworkshop.PushupTracker`
- Widget: `com.mcmusicworkshop.PushupTracker.PushupWidgets`

(PascalCase matches Xcode's defaults when the product name is `PushupTracker`. App Group identifier stays lowercase per Apple convention.)

### Directory layout

```
PushupTracker.xcodeproj/
PushupTracker/                       # app target
  PushupTrackerApp.swift
  AppShell.swift                     # TabView root
  Views/
    Today/TodayView.swift
    History/HistoryView.swift
    History/DayDetailView.swift
    Trends/TrendsView.swift
    Settings/SettingsView.swift
    Common/UndoBanner.swift
  Info.plist
  Assets.xcassets/
PushupWidgets/                       # widget extension target
  PushupWidgetsBundle.swift
  HomeScreen/
    HomeSmallWidget.swift
    HomeMediumWidget.swift
  LockScreen/
    LockCircularWidget.swift
    LockRectangularWidget.swift
  Intents/
    LogPushupsIntent.swift
    UndoLastSetIntent.swift
  Info.plist
PushupCore/                          # local Swift Package
  Package.swift
  Sources/PushupCore/
    Models/
      PushupSet.swift                # @Model
    Persistence/
      ModelContainer+Shared.swift    # App Group container factory
      PushupStore.swift              # read/write facade
    HealthKit/
      HealthKitService.swift         # protocol
      HealthKitServiceLive.swift     # real impl
      HealthKitServiceMock.swift     # test impl
      WorkoutSynthesizer.swift       # builds today's HKWorkout from SwiftData
    Constants.swift
  Tests/PushupCoreTests/
    PushupSetTests.swift
    PushupStoreTests.swift
    WorkoutSynthesizerTests.swift
spec.md
PROGRESS.md
README.md
```

---

## 5. Data Model

One SwiftData model:

```swift
@Model
final class PushupSet {
    @Attribute(.unique) var id: UUID
    var count: Int
    var timestamp: Date
    var healthKitSyncedAt: Date?   // nil = not synced; non-nil = last successful sync

    init(count: Int, timestamp: Date = .now) {
        self.id = UUID()
        self.count = count
        self.timestamp = timestamp
        self.healthKitSyncedAt = nil
    }
}
```

Derived values (not stored):

- **Today's total** — sum of `count` where `Calendar.current.isDateInToday(timestamp)`
- **Daily total for any day** — same pattern with `isDate(_, inSameDayAs:)`
- **Days with activity** — unique calendar days across all sets

No other entities. Days, totals, and trends are all computed from the set list.

### SwiftData container configuration (critical)

The `ModelContainer` **must** be configured to use the App Group container URL, not the default sandbox location. Both app and widget must use the identical configuration, provided via the `ModelContainer+Shared.swift` factory in `PushupCore`. Reference implementation:

```swift
public enum SharedContainer {
    public static let appGroupID = "group.com.mcmusicworkshop.pushuptracker"
    public static let storeFilename = "PushupTracker.sqlite"

    public static func makeModelContainer() throws -> ModelContainer {
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else {
            fatalError("App Group container unavailable — check entitlements on both targets")
        }
        let storeURL = groupURL.appending(path: storeFilename)
        let schema = Schema([PushupSet.self])
        let config = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
```

Using the default `.modelContainer(for: PushupSet.self)` modifier (without a custom configuration) will silently put the store in the app's sandbox and the widget will see an empty database. Always use the factory above.

---

## 6. HealthKit Integration

### Permissions

Request **write** only:

- `HKObjectType.workoutType()`
- `HKQuantityType(.activeEnergyBurned)`

Do not request read access. On first app launch, show a one-screen pre-prompt explaining why, then call `requestAuthorization`. If denied, the app continues functioning locally; Settings shows a link to open Health permissions.

**Required Info.plist keys** (app target only — not widget):

- `NSHealthUpdateUsageDescription` — user-facing string, e.g. `"Pushup Tracker adds your pushup sets to Apple Health as workouts so your activity is captured in one place."`
- Do **not** add `NSHealthShareUsageDescription` — we don't read from HealthKit.

Without `NSHealthUpdateUsageDescription`, the app crashes on permission request with no useful error message. This is a common M4 bug.

### Write strategy: delete-and-rewrite per day

SwiftData is the source of truth. HealthKit is a derived projection. The sync algorithm for a target day:

1. Load all `PushupSet` records for the day from SwiftData.
2. Query HealthKit for a workout whose metadata contains `Constants.dayIDMetadataKey == <yyyy-MM-dd>`.
3. If found, delete it.
4. If the day has zero sets, stop.
5. Otherwise, use `HKWorkoutBuilder` to construct a new workout:
   - Activity type: `.functionalStrengthTraining`
   - Workout start: timestamp of first set
   - Workout end: timestamp of last set `+ Constants.secondsPerPushup * lastSet.count`
   - For each set, add an `HKWorkoutActivity`:
     - Configuration: `.functionalStrengthTraining`
     - Start: `set.timestamp`
     - End: `set.timestamp + Constants.secondsPerPushup * set.count`
     - Metadata: `["PushupCount": set.count, "PushupSetID": set.id.uuidString]`
   - Total energy: `totalCount × Constants.kcalPerPushup` added as an `HKQuantitySample(.activeEnergyBurned)` spanning workout start→end
   - Workout metadata: `[Constants.dayIDMetadataKey: "yyyy-MM-dd", "PushupTrackerVersion": "1"]`
6. On successful save, stamp `healthKitSyncedAt = .now` on every set for that day.

### Constants

```swift
enum Constants {
    static let secondsPerPushup: TimeInterval = 2.0
    static let kcalPerPushup: Double = 0.32
    static let activityType: HKWorkoutActivityType = .functionalStrengthTraining
    static let dayIDMetadataKey = "PushupTrackerDayID"
}
```

These are documented estimates. Do not make them user-configurable in v1.

### Sync triggers

- App returns to foreground → sync today (debounced 1s)
- `LogPushupsIntent` (widget) inserts a set, then requests a sync for today
- Settings → "Sync now" → syncs today + yesterday manually
- Midnight rollover handled on next foreground sync (yesterday + today)

### Failure handling

If a HealthKit write fails (permission denied, transient error, etc.):

- Log via `os.Logger` subsystem `healthkit`
- Leave `healthKitSyncedAt` nil on affected sets
- Surface a subtle indicator in Settings ("Last sync: failed — tap to retry")
- Never delete local data for HealthKit reasons

---

## 7. Widget Specification

### App Intents

Two intents live in the widget target and are linked into `PushupCore`'s store API:

```swift
struct LogPushupsIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Pushups"
    @Parameter(title: "Count") var count: Int
    func perform() async throws -> some IntentResult { ... }
}

struct UndoLastSetIntent: AppIntent {
    static var title: LocalizedStringResource = "Undo Last Set"
    func perform() async throws -> some IntentResult { ... }
}
```

`LogPushupsIntent.perform()`:

1. Open the shared SwiftData container
2. Insert `PushupSet(count: count)`
3. Request a HealthKit sync for today (widget extension may or may not have HK entitlement — if not, sync is deferred until next app foreground)
4. Call `WidgetCenter.shared.reloadAllTimelines()`

### Home Screen

- **`.systemSmall`** — today's total as a hero number; one `+10` button below
- **`.systemMedium`** — today's total on the left; four buttons on the right (`+1`, `+5`, `+10`, `+25`). Each button is a `Button(intent: LogPushupsIntent(count: N))`.

### Lock Screen

- **`.accessoryCircular`** — today's total rendered in a `Gauge`. Gauge max = max daily total from the last 30 days, or 100 if less than 7 days of history exists. Tap opens the app.
- **`.accessoryRectangular`** — today's total as text on one row, `+10` interactive button on the next row.

### Timeline

- One entry at boot, refresh every 15 minutes to keep "today" correct
- Timeline includes a scheduled entry at the next midnight with a zeroed total
- After any intent runs: `WidgetCenter.shared.reloadAllTimelines()`

---

## 8. App UI Specification

Root is a `TabView` with four tabs: **Today**, **History**, **Trends**, **Settings**.

### Today

- Hero number — today's total, SF Rounded, ~120pt
- Subtitle — `"N sets today"`
- Four quick-add buttons: `+1`, `+5`, `+10`, `+25` (same mapping as widget, for in-app use)
- Scrollable timeline below: today's sets, newest first, formatted `"8:42 AM — 10 pushups"`, swipe-to-delete
- Undo banner pinned to bottom for 5 seconds after each log

### History

- List of days with activity, newest first, grouped by month, row format `"Monday, Apr 20 — 85 pushups"`
- Tap a day → `DayDetailView` showing the set timeline for that day (read-only in v1)

### Trends

- Segmented control: 7 / 30 / 90 days
- Swift Charts bar chart (`BarMark` per day)
- Below the chart: total for period, average per day, best day

### Settings

- HealthKit section: permission status (granted / denied / not determined), "Open Health settings" link when denied, "Sync now" button
- About: app version, build number, credits, feedback link (TBD email)
- No user-configurable settings in v1

---

## 9. Project Conventions

- Swift 6, strict concurrency on
- SwiftUI only; no UIKit imports except where WidgetKit / App Intents require
- No third-party dependencies. If one seems necessary, stop and flag in `PROGRESS.md`
- File naming: `ThingView.swift`, `ThingViewModel.swift`, `ThingService.swift`; one type per file
- Access control: default `internal`; `public` only on `PushupCore`'s API surface
- Dates: use `Calendar.current` and `Date`; never round-trip through strings for logic (strings are for display only)
- Errors: concrete `enum` types conforming to `Error`; no generic `NSError` or stringly-typed errors
- Logging: `os.Logger`, one per subsystem. Subsystems: `app`, `widget`, `healthkit`, `persistence`
- No `print` statements in shipped code

---

## 10. Build & Test

```bash
# Build app
xcodebuild -project PushupTracker.xcodeproj \
  -scheme PushupTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' build

# Run full test suite
xcodebuild -project PushupTracker.xcodeproj \
  -scheme PushupTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' test

# Fast iteration: PushupCore tests only
swift test --package-path PushupCore
```

If `iPhone 17 Pro` isn't installed locally, run `xcrun simctl list devices available` and substitute any iPhone-class simulator that exists. The `OS=latest` qualifier lets xcodebuild use whatever iOS version that simulator has — our iOS 18 minimum deployment target only affects what OS versions can *run* the shipped app, not what simulator OS we test on.

Tests must pass before a milestone is marked complete in `PROGRESS.md`.

Test targets in v1:

- `PushupCore` unit tests (Swift Testing): model, store, workout synthesizer
- `HealthKitService` is protocol-based; tests exercise the mock, not the live impl
- No UI tests, no snapshot tests in v1

### Release (M10 only)

Release is a **manual, CLI-driven** step run once per TestFlight submission. The Ralph loop does not perform releases.

**One-time prerequisites:**

1. App Store Connect API key at `appstoreconnect.apple.com` → Users and Access → Integrations → App Store Connect API → generate key with **Developer** role. Download the `.p8` file (downloadable only once). Save to `~/.private_keys/AuthKey_<KEYID>.p8`.
2. Shell environment variables (add to `~/.zshrc`):
```bash
   export APPSTORE_KEY_ID="<your 10-char key ID>"
   export APPSTORE_ISSUER_ID="<your issuer UUID>"
```
3. App record in App Store Connect with bundle ID `com.mcmusicworkshop.PushupTracker` created (My Apps → + → New App).
4. `ExportOptions.plist` at repo root (template provided alongside this spec).

**Release commands:**

```bash
# 1. Clean archive
rm -rf build
xcodebuild -project PushupTracker.xcodeproj \
  -scheme PushupTracker \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath build/PushupTracker.xcarchive \
  archive \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=9WNXKEF4SM

# 2. Export IPA
xcodebuild -exportArchive \
  -archivePath build/PushupTracker.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# 3. Upload to App Store Connect (→ TestFlight)
xcrun altool --upload-app \
  -f build/export/PushupTracker.ipa \
  --type ios \
  --apiKey "$APPSTORE_KEY_ID" \
  --apiIssuer "$APPSTORE_ISSUER_ID"
```

The API key `.p8` file must be in `~/.private_keys/` (or `~/.appstoreconnect/private_keys/`) — `altool` discovers it automatically by key ID.

**After upload**, the build appears in App Store Connect → TestFlight → Builds within ~5–15 minutes, usually requires a compliance question answered (export encryption — add `ITSAppUsesNonExemptEncryption = false` to `Info.plist` to skip this permanently since we use no custom crypto), then it's available for internal testing.

---

## 11. Implementation Plan (Milestones)

Build in this order. Each milestone is a working, testable slice. Do not begin milestone N+1 until milestone N's tests pass and a commit is made.

1. **M1 — Project skeleton**: Xcode project, app target, widget extension target, `PushupCore` package, App Group entitlement. App launches to empty TabView.
2. **M2 — Data model + store**: `PushupSet`, `PushupStore`, shared SwiftData container. Tests for insert / query / delete.
3. **M3 — Today view**: hero number, quick-add buttons (in-app), per-set timeline, swipe-to-delete, undo banner.
4. **M4 — HealthKit service (no new UI)**: permission request, `WorkoutSynthesizer`, `HealthKitServiceLive`, mock + tests. Wire to foreground sync.
5. **M5 — Settings view**: HK permission UI, "Sync now", About.
6. **M6 — History view**: days list + day detail.
7. **M7 — Trends view**: Swift Charts bar chart + 7/30/90 segmented control.
8. **M8 — Home Screen widget**: `LogPushupsIntent`, small + medium widgets.
9. **M9 — Lock Screen widget**: circular + rectangular.
10. **M10 — Polish pass**: app icon, launch screen, empty states, error states, HealthKit-denied states, `PrivacyInfo.xcprivacy` manifest (required for App Store submission — declare zero collected data types and only the required-reason APIs actually used, if any), VoiceOver labels on all interactive elements, archive build check.

---

## 12. Progress Tracking Protocol

The agent maintains `PROGRESS.md` at repo root, shape:

```markdown
# Progress

## Current milestone
M3 — Today view (in progress)

## Completed
- [x] M1 — Project skeleton (commit abc123)
- [x] M2 — Data model + store (commit def456)

## Remaining
- [ ] M3 — Today view
- [ ] M4 — HealthKit service
- [ ] ... (through M10)

## Last iteration notes
<what was done this loop iteration, dead ends, surprises>

## Open questions
<non-blocking questions for the human>

## Blockers
<things that DO block further work>
```

Each loop iteration:

1. Read `spec.md` and `PROGRESS.md` fully
2. Pick the smallest next unit of work in the current milestone
3. Implement it
4. Run tests; fix any failures before proceeding
5. Update `PROGRESS.md` with what was actually done (not plans)
6. Commit with message `M<n>: <brief description>`
7. Stop

---

## 13. Invariants (Do NOT violate)

- **SwiftData is the source of truth.** HealthKit is a derived projection. Never read from HealthKit to populate the UI.
- **Never delete local data to resolve a HealthKit error.** HealthKit errors get logged and surfaced, nothing more.
- **Widget intents must be idempotent at the SwiftData layer.** If the system retries an intent, it must not double-log. Use intent result semantics correctly.
- **Do not touch anything in the out-of-scope list (§3).** If tempted, add an open question.
- **No new dependencies.** Everything is buildable with the standard library, SwiftUI, SwiftData, HealthKit, WidgetKit, App Intents, Swift Charts.
- **Do not change locked decisions (§2).** Surface disagreements as open questions.
- **Do not rewrite code from prior milestones** unless fixing a bug or unless a later milestone explicitly requires a refactor — and if so, note it in `PROGRESS.md`.

---

## 14. Anti-patterns

- Building an abstraction before it's needed ("in case we want to swap SwiftData later") — don't
- Adding configuration toggles no one asked for — don't
- Changes that touch more than ~3 files per loop iteration — split them
- Writing plans into `PROGRESS.md` ("I will next..."); only record what actually happened
- Silently skipping a failing test; fix it or document why in Blockers
- "Improving" code outside the current milestone; stay in scope

---

## 15. Done Criteria (v1 ship)

All of the following must be true:

- [ ] M1–M10 complete
- [ ] All `PushupCore` tests pass
- [ ] App builds cleanly with zero warnings under Swift 6 strict concurrency
- [ ] Fresh install → HealthKit prompt → log some sets → single workout with nested activities appears in Apple Health
- [ ] Home Screen widget logs without opening the app
- [ ] Lock Screen widget shows today's total; `+10` button works
- [ ] Undo works from both app and widget
- [ ] App functions with HealthKit permission denied (local-only mode, banner in Settings)
- [ ] Archive build succeeds (TestFlight-ready)

---

## 16. When Stuck

If the agent cannot make progress during an iteration:

1. Write a clear, specific question under **Open questions** in `PROGRESS.md`
2. Do not invent answers or pick random directions
3. If any adjacent work in the current milestone is unblocked, do that instead
4. If the whole milestone is blocked, move to the next milestone's unblocked tasks
5. If everything is blocked, stop and leave `PROGRESS.md` describing the blocker