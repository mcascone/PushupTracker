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

Added the per-set timeline list with swipe-to-delete to `TodayView`. It's a `List` (`.plain` style) under the quick-add buttons, populated from the same `@Query` already in the view, with each row formatted as `"h:mm AM — N pushup(s)"` using `Text(_:format: .dateTime.hour().minute())` and singular/plural pushup wording. `.onDelete(perform:)` calls a new `deleteSets(at:)` helper that maps the `IndexSet` into `todaySets` and calls `modelContext.delete` then `save`. Replaced the trailing `Spacer()` since `List` expands to fill the remaining vertical space. The undo banner is the last remaining piece for M3 and is deferred to the next iteration. Tests all pass: `swift test --package-path PushupCore` 8/8 and `xcodebuild test` on `PushupTracker` succeeded.

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