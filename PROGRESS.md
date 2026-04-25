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

Filled out `TodayView` with the hero section and quick-add buttons. The view uses `@Query` with a `Predicate<PushupSet>` bounded by `Calendar.current.startOfDay` for "now" and the next day's start, sorted by `timestamp` descending — that gives both the live total and a list ready to feed the timeline next iteration. Hero is a 120pt SF Rounded number with `.contentTransition(.numericText())` and a "N set/sets today" subtitle (singular/plural). Four `+1 / +5 / +10 / +25` buttons in an `HStack` use `.borderedProminent` and call `modelContext.insert(PushupSet(count:))` then `try? modelContext.save()` directly — kept it inline rather than threading a `PushupStore` through the view environment, since `@Query` already mandates an in-view `ModelContext` and `PushupStore` adds nothing here. Per-set timeline, swipe-to-delete, and the undo banner remain for following iterations. Tests all pass: `swift test --package-path PushupCore` 8/8 and `xcodebuild test` succeeds. Only build output line matching warning/error is the unrelated `appintentsmetadataprocessor` "No AppIntents.framework dependency found" notice on the app target — expected since intents will live in the widget extension (M8).

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