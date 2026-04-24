# Progress

## Current milestone

**M2 — Data model + store**

Goal: Implement `PushupSet` SwiftData model and `PushupStore` read/write facade in `PushupCore`, configured to use the shared App Group container. Per spec §5 (Data Model) and §4 (App Group).

Exit criteria:
- [ ] `PushupSet` `@Model` class exists in `PushupCore/Sources/PushupCore/Models/PushupSet.swift` matching spec §5 exactly (fields: `id`, `count`, `timestamp`, `healthKitSyncedAt`)
- [ ] `SharedContainer` factory exists in `PushupCore/Sources/PushupCore/Persistence/ModelContainer+Shared.swift` matching spec §5 reference implementation
- [ ] `PushupStore` facade exists in `PushupCore/Sources/PushupCore/Persistence/PushupStore.swift` with public methods: `insert(count: Int, at: Date = .now)`, `delete(_ set: PushupSet)`, `setsForToday()`, `setsForDay(_ date: Date)`, `allSets()`
- [ ] Swift Testing tests in `PushupCore/Tests/PushupCoreTests/`:
  - `PushupSetTests.swift` — model init defaults, uniqueness of id
  - `PushupStoreTests.swift` — insert, delete, today query, day query, all query (using an in-memory `ModelContainer` for isolation)
- [ ] `swift test --package-path PushupCore` passes with >0 real tests (not just the placeholder)
- [ ] Full `xcodebuild test` on the `PushupTracker` scheme passes
- [ ] App-target code still builds; no wiring into the app UI yet (that's M3)
- [ ] Zero warnings under Swift 6 strict concurrency
- [ ] Committed to git with message `M2: <description>`

## Completed

- [x] M1 — Project skeleton (commit fe154af)

## Remaining

- [ ] M3 — Today view
- [ ] M4 — HealthKit service
- [ ] M5 — Settings view
- [ ] M6 — History view
- [ ] M7 — Trends view
- [ ] M8 — Home Screen widget
- [ ] M9 — Lock Screen widget
- [ ] M10 — Polish pass

## Last iteration notes

M1 completed via manual bootstrap per BOOTSTRAP.md. Hit several snags: widget target product name got corrupted by pasted markdown (fixed by recreating target cleanly); UI test target had to be fully removed including scheme references; entitlements file landed at repo root instead of inside widget folder (moved to PushupWidgets/ and updated CODE_SIGN_ENTITLEMENTS build setting); `iPhone 16,OS=18.0` destination doesn't exist on Xcode 26 (switched to `iPhone 17 Pro,OS=latest`). All M1 exit criteria met; `xcodebuild test` and `swift test --package-path PushupCore` both pass on fe154af.

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