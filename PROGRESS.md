# Progress

## Current milestone

**M3 — Today view**

Goal: Build the in-app Today tab per spec §8: hero number for today's total, four quick-add buttons (`+1`, `+5`, `+10`, `+25`), per-set timeline below (newest first, swipe-to-delete), and a 5-second undo banner pinned to the bottom after each log. Use `PushupStore` and the shared SwiftData container; no HealthKit wiring yet (that's M4).

Exit criteria:
- [ ] App's root `AppShell` injects the shared `ModelContainer` via `SharedContainer.makeModelContainer()`
- [ ] `TodayView` displays today's total as a hero number (~120pt SF Rounded) and `"N sets today"` subtitle
- [ ] Four quick-add buttons (`+1`, `+5`, `+10`, `+25`) insert a `PushupSet` via `PushupStore`
- [ ] Per-set timeline list shows today's sets newest-first, formatted `"h:mm a — N pushups"`, swipe-to-delete removes the set
- [ ] `UndoBanner` appears for 5 seconds after each log; tapping Undo removes the most-recent set
- [ ] No HealthKit calls (deferred to M4); no widget code touched
- [ ] `swift test --package-path PushupCore` still passes
- [ ] Full `xcodebuild test` on `PushupTracker` passes
- [ ] Zero warnings under Swift 6 strict concurrency
- [ ] Committed with message `M3: <description>`

Goal: Implement `PushupSet` SwiftData model and `PushupStore` read/write facade in `PushupCore`, configured to use the shared App Group container. Per spec §5 (Data Model) and §4 (App Group).

Exit criteria:
- [x] `PushupSet` `@Model` class exists in `PushupCore/Sources/PushupCore/Models/PushupSet.swift` matching spec §5 exactly (fields: `id`, `count`, `timestamp`, `healthKitSyncedAt`)
- [x] `SharedContainer` factory exists in `PushupCore/Sources/PushupCore/Persistence/ModelContainer+Shared.swift` matching spec §5 reference implementation
- [x] `PushupStore` facade exists in `PushupCore/Sources/PushupCore/Persistence/PushupStore.swift` with public methods: `insert(count: Int, at: Date = .now)`, `delete(_ set: PushupSet)`, `setsForToday()`, `setsForDay(_ date: Date)`, `allSets()`
- [x] Swift Testing tests in `PushupCore/Tests/PushupCoreTests/`:
  - `PushupSetTests.swift` — model init defaults, uniqueness of id
  - `PushupStoreTests.swift` — insert, delete, today query, day query, all query (using an in-memory `ModelContainer` for isolation)
- [x] `swift test --package-path PushupCore` passes with >0 real tests (not just the placeholder)
- [x] Full `xcodebuild test` on the `PushupTracker` scheme passes
- [x] App-target code still builds; no wiring into the app UI yet (that's M3)
- [x] Zero warnings under Swift 6 strict concurrency
- [x] Committed to git with message `M2: <description>`

## Completed

- [x] M1 — Project skeleton (commit fe154af)
- [x] M2 — Data model + store (commit 94e7443)

## Remaining

- [ ] M4 — HealthKit service
- [ ] M5 — Settings view
- [ ] M6 — History view
- [ ] M7 — Trends view
- [ ] M8 — Home Screen widget
- [ ] M9 — Lock Screen widget
- [ ] M10 — Polish pass

## Last iteration notes

Added `PushupStore` public facade in `PushupCore/Sources/PushupCore/Persistence/PushupStore.swift` with the methods specified in M2 exit criteria: `insert(count:at:)` (returns the inserted `PushupSet`, defaults timestamp to `.now`), `delete(_:)`, `allSets()` (reverse-chronological), `setsForToday()`, and `setsForDay(_:)` (chronological within the day). Marked the class `@MainActor` since `ModelContext` is not `Sendable`; the spec's Swift 6 strict-concurrency requirement makes this the simplest correct posture, and tests/UI both run on the main actor. Added `PushupStoreTests.swift` with five tests using an in-memory `ModelConfiguration(isStoredInMemoryOnly: true)` for isolation: insert, delete, today filter, day filter, and reverse-chronological ordering. `swift test --package-path PushupCore` passes 8/8 (3 PushupSet + 5 PushupStore). Full `xcodebuild test` on the `PushupTracker` scheme passes. SourceKit/IDE flagged a spurious "no such module 'Testing'" diagnostic on the new test file but the actual swiftc + xcodebuild builds succeed — same import as the existing PushupSetTests.swift. M2 exit criteria fully met.

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