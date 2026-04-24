# PushupTracker

An iOS app for logging pushups throughout the day, with interactive widgets and Apple Health sync.

**Build method:** Ralph loop. The agent reads `spec.md` + `PROGRESS.md` each iteration, does one focused unit of work, commits, stops. See `ralph_prompt.md` for the agent-facing instructions and `BOOTSTRAP.md` for the one-time Xcode setup.

- **Spec:** `spec.md` — locked decisions, feature scope, architecture, invariants
- **Current state:** `PROGRESS.md` — which milestone is active, what's been completed
- **Tech:** iOS 18+, Swift 6, SwiftUI, SwiftData, HealthKit, WidgetKit
- **Targets:** `PushupTracker` (app), `PushupWidgets` (extension), `PushupCore` (local package, shared logic)