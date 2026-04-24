# Bootstrap — One-Time Xcode Setup

This is the only Xcode-GUI step in the project. After this, all work happens via CLI and the Ralph loop. Budget 20–30 minutes.

**Goal:** produce a committed repo with an Xcode project containing the app target, a widget extension target, a local `PushupCore` Swift package, App Group capability on both targets, and a passing `⌘B` build.

---

## 0. Prerequisites

- **Xcode 16.0 or later** installed from the App Store (Xcode 26 is current as of 2026 — fine to use).
- Your Apple ID signed in to Xcode: `Xcode → Settings → Accounts → +`. The **Maximilian Cascone** team (Team ID `9WNXKEF4SM`) should appear in the account's team list.
- Command Line Tools: `xcode-select --install` if not already installed.
- No existing `PushupTracker.xcodeproj` anywhere on disk (avoids path collisions in Xcode's recent-projects list).

---

## 1. Prep the repo (terminal)

```bash
mkdir ~/code/pushup-tracker && cd ~/code/pushup-tracker
git init

# Drop in the spec files produced earlier
cp /path/to/spec.md .
cp /path/to/PROGRESS.md .
cp /path/to/ralph_prompt.md .
cp /path/to/ExportOptions.plist .
cp /path/to/.gitignore .

git add -A && git commit -m "chore: initial spec and conventions"
```

Adjust the `cp` source paths to wherever you saved the files.

---

## 2. Create the Xcode project

Open Xcode, then **File → New → Project…** (`⇧⌘N`).

**Template:** iOS → **App** → Next.

**Options:**

| Field | Value |
|---|---|
| Product Name | `PushupTracker` |
| Team | Maximilian Cascone (9WNXKEF4SM) |
| Organization Identifier | `com.mcmusicworkshop` |
| Bundle Identifier | (auto-fills to `com.mcmusicworkshop.PushupTracker` — leave it) |
| Interface | SwiftUI |
| Language | Swift |
| Testing System | **Swift Testing** (not XCTest) |
| Storage | **SwiftData** |
| Host in CloudKit | **unchecked** |
| Include Tests | **checked** |

Click **Next**.

**Save location:** choose `~/code/pushup-tracker` (the repo folder you created in step 1). **Uncheck "Create Git repository on my Mac"** — you already have one.

Click **Create**.

**After creation, delete the UI test target.** If Xcode created both `PushupTrackerTests` (unit, Swift Testing) and `PushupTrackerUITests` (UI, XCTest-only — Swift Testing doesn't support UI tests yet), right-click `PushupTrackerUITests` in the navigator → **Delete → Remove Reference and Move to Trash**. The v1 spec has no UI tests; removing the unused target prevents the agent from accidentally writing tests there later.

---

## 3. Set iOS deployment target and Swift 6

In the navigator, click the blue `PushupTracker` project icon at the top.

- Select the **PushupTracker** target → **General** tab → **Minimum Deployments → iOS** → set to **18.0**.
- Same target → **Build Settings** tab → search **Swift Language Version** → set to **Swift 6**.

---

## 4. Add the Widget Extension target

**File → New → Target…**

- iOS → **Widget Extension** → Next.
- Options:
  - Product Name: `PushupWidgets`
  - Team: Maximilian Cascone
  - **Include Configuration App Intent: checked** (required — we'll replace the default intent with our own `LogPushupsIntent` in M8)
  - **Include Live Activity: unchecked**
  - **Include Control: unchecked** (Control Center widgets are out of scope for v1 per spec §3)
- Click **Finish**.
- When Xcode prompts "Activate PushupWidgets scheme?" — click **Don't Activate** (older Xcode versions label this button `Cancel`; either way, pick the option that does *not* activate it). You want the scheme selector at the top of Xcode to stay on `PushupTracker`, which builds the app and embeds the widget — that's the scheme you'll use for all local testing.

**Verify the target name and bundle ID Xcode produced.** Depending on Xcode version, the target may be named `PushupWidgets` or `PushupWidgetsExtension` (Xcode sometimes appends "Extension"). Select the target in the navigator and check:

- **General → Bundle Identifier** should be `com.mcmusicworkshop.PushupTracker.PushupWidgets`. If Xcode appended "Extension" (e.g. `...PushupTracker.PushupWidgetsExtension`), edit the bundle ID to remove the suffix so it matches the spec.
- The target's display name in the navigator can stay as-is; what matters is the bundle ID and folder name.

**Apply same project-level settings as the app target:**

- Target **PushupWidgets** → **General** → **Minimum Deployments → iOS 18.0** (Xcode often defaults widgets to a lower iOS version).
- Target **PushupWidgets** → **Build Settings** → search **Swift Language Version** → set to **Swift 6**.

---

## 5. Create the PushupCore local Swift Package (terminal)

From the repo root:

```bash
mkdir PushupCore && cd PushupCore
swift package init --type library --name PushupCore
cd ..
```

Now edit `PushupCore/Package.swift` to specify iOS 18 as the minimum platform. Replace the generated file's `Package(...)` block with:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PushupCore",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "PushupCore", targets: ["PushupCore"]),
    ],
    targets: [
        .target(name: "PushupCore"),
        .testTarget(name: "PushupCoreTests", dependencies: ["PushupCore"]),
    ]
)
```

Verify it compiles:

```bash
swift test --package-path PushupCore
```

Should pass with one trivial default test.

---

## 6. Link PushupCore into both Xcode targets

Back in Xcode: **File → Add Package Dependencies…**

- In the bottom-left of the dialog, click **Add Local…**
- Navigate to the `PushupCore` folder you just created → **Add Package**.
- When the "Choose Package Products" sheet appears, set `PushupCore` to be added to **both**:
  - `PushupTracker` target
  - `PushupWidgetsExtension` target

If the sheet doesn't give you both options, add it to PushupTracker first, then go to the PushupWidgetsExtension target → **General** → **Frameworks and Libraries** → **+** → pick `PushupCore`.

**Verify the link worked.** We want to confirm that both targets can see the `PushupCore` module. Do this in two passes — app target first, then widget target.

### Quick Xcode build primer

If you're not used to Xcode, three things to know before the verification steps below:

- **Build a target:** select the target's scheme in the top bar (the dropdown immediately to the right of the stop/run buttons — it usually shows the scheme name and a device/simulator), then press **`⌘B`** (or menu: Product → Build).
- **Where results appear:**
  - The status bar at the top-center of the Xcode window shows the current action and outcome — "Building PushupTracker…" while in progress, then either "Build Succeeded" or "Build Failed".
  - The **Issue Navigator** (left sidebar, click the ⚠️ triangle icon, or `⌘5`) lists every error and warning. Errors have red circles; warnings have yellow triangles.
  - If a build fails, Xcode usually opens the Issue Navigator automatically and jumps to the first error in the source file.
- **Clean build** if something gets weird: menu Product → Clean Build Folder (`⇧⌘K`), then `⌘B` again. Useful when Xcode seems to be caching stale state after adding a package.

### Pass 1: App target

1. In the Xcode navigator (left sidebar, `⌘1` for the file tree), open `PushupTracker/ContentView.swift` by clicking it.
2. At the top of the file, below the existing `import SwiftUI` line, add a new line: `import PushupCore`
3. Save the file (`⌘S`).
4. In the top bar, make sure the scheme dropdown shows `PushupTracker` (not `PushupWidgetsExtension`). If it doesn't, click the dropdown and pick `PushupTracker`.
5. Press `⌘B` to build.
6. **Expected result:** status bar shows "Build Succeeded". The Issue Navigator (`⌘5`) should show no red errors. Yellow warnings about unused imports are fine and expected here.
7. **If you see `No such module 'PushupCore'`** in the Issue Navigator, the link didn't register on the app target. Go back to the package-adding step — Project icon (top of navigator) → `PushupTracker` target → General tab → scroll to "Frameworks, Libraries, and Embedded Content" → click `+` → pick `PushupCore` → Add. Then `⌘B` again.
8. Once the build succeeds, **remove the `import PushupCore` line** you added. Save (`⌘S`). Build once more (`⌘B`) to confirm nothing broke — the file doesn't actually need the import yet, we were just using it as a probe.

### Pass 2: Widget target

1. In the navigator, open `PushupWidgets/PushupWidgets.swift` (the widget implementation file — not `PushupWidgetsBundle.swift`).
2. Below the existing `import WidgetKit` and `import SwiftUI` lines, add: `import PushupCore`
3. Save (`⌘S`).
4. **Switch the active scheme** to `PushupWidgetsExtension`: click the scheme dropdown in the top bar → select `PushupWidgetsExtension`. If Xcode prompts to activate the scheme, click **Activate** this time — we want to build the widget specifically.
5. Press `⌘B`.
6. **Expected result:** "Build Succeeded" in the status bar, no red errors.
7. **If you see `No such module 'PushupCore'`**: Project icon → `PushupWidgetsExtension` target → General → Frameworks and Libraries → `+` → pick `PushupCore` → Add. Rebuild.
8. Once the widget build succeeds, **remove the `import PushupCore` line**. Save. Build once more to confirm.
9. Switch the active scheme **back to `PushupTracker`** for subsequent steps (top bar dropdown).

**Why we're testing both separately:** it's common for Xcode's "Add Local Package" dialog to link the package to only the app target by default, leaving the widget target silently without the dependency. If you skip this verification, the failure won't surface until M8 (widget implementation) and will be annoying to debug in that context.

---

## 7. Add App Group capability

This is the most error-prone step. The App Group must be identical on both targets, spelled exactly right.

**For the PushupTracker target:**

1. Select the project → **PushupTracker** target → **Signing & Capabilities** tab.
2. Make sure **Automatically manage signing** is checked and Team is Maximilian Cascone.
3. Click **+ Capability** → double-click **App Groups**.
4. In the App Groups section, click **+** to add a new group.
5. Type exactly: `group.com.mcmusicworkshop.pushuptracker`
6. Ensure the checkbox next to the group is **checked**.

**For the PushupWidgetsExtension target:**

1. Select the **PushupWidgetsExtension** target → **Signing & Capabilities** tab.
2. Click **+ Capability** → double-click **App Groups**.
3. The same group you just created should appear in the list. **Check it.**
4. If it doesn't appear, click **+** under the group list and add `group.com.mcmusicworkshop.pushuptracker` again, identically. Xcode will sync them.

Automatic signing will now provision both bundle IDs on Apple's side and add the App Group to both app IDs. This can take 30 seconds; watch the status in the Signing & Capabilities pane — if it shows a red error, click **Try Again** or wait a moment.

---

## 8. Add the encryption-exemption Info.plist key (saves friction at release)

This skips an export-compliance question on every TestFlight build.

- Select **PushupTracker** target → **Info** tab.
- Click the **+** at the end of any row in the "Custom iOS Target Properties" list.
- Add key `ITSAppUsesNonExemptEncryption` with Type `Boolean` and Value `NO`.

Repeat for the **PushupWidgetsExtension** target.

---

## 9. Build and test (Xcode)

- Select the **PushupTracker** scheme (top bar, next to the device selector). Device: any iPhone-class simulator (e.g. iPhone 17 Pro).
- Press **`⌘B`** → should build with zero errors and zero warnings. If there are warnings under strict concurrency, fix them before committing (usually just adding `@MainActor` or `Sendable` annotations to the scaffolded code).
- Press **`⌘U`** → default tests should pass.

---

## 10. Verify the CLI flow works

Close Xcode. From the repo root:

```bash
# Full app + widget + tests via xcodebuild
xcodebuild -project PushupTracker.xcodeproj \
  -scheme PushupTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  test

# Package-level tests (fast inner loop)
swift test --package-path PushupCore
```

Both should pass. If `xcodebuild` complains about the destination, run `xcrun simctl list devices available` and substitute any iPhone-class simulator name that exists. The `OS=latest` keyword picks whatever iOS version that simulator has installed — our iOS 18 minimum deployment target only affects shipped-app compatibility, not what simulator OS we test on.

---

## 11. Commit

```bash
git add -A
git status   # sanity-check — should NOT contain .xcuserstate, DerivedData, .build, etc.
git commit -m "M1: initial project scaffolding (app target, widget extension, PushupCore package, App Group)"
```

If you see build artifacts in `git status`, your `.gitignore` isn't being respected — check it's at the repo root and matches the template.

---

## 12. Mark M1 complete

Edit `PROGRESS.md`:

- Move the **Current milestone** block content into **Completed** as `[x] M1 — Project skeleton (commit <SHA>)`.
- Promote **M2 — Data model + store** to the **Current milestone** section. Fill in its goal and exit criteria by referencing `spec.md` §11 M2 and §5 (Data Model).
- Commit this `PROGRESS.md` update separately: `chore: mark M1 complete, queue M2`.

---

## 13. Start the loop

You never need to open Xcode again until M10 (and even then, optionally — the release commands in `spec.md` §10 are all CLI). From here on out:

```bash
# Each loop iteration
<your-agent-runner> --prompt "$(cat ralph_prompt.md)"
```

The agent reads `spec.md` + `PROGRESS.md`, does one iteration of M2 work, commits, and stops. Review the commit, run again.

---

## Common bootstrap snags

- **"No signing certificate" red error in Signing & Capabilities.** Your Apple ID isn't signed in, or Maximilian Cascone isn't the selected team. Fix in Xcode → Settings → Accounts.ls PushupTracker.xcodeproj/xcshareddata/xcschemes/

- **App Group shows red "failed to register" error.** Hit Try Again once or twice; automatic signing sometimes needs to retry. If it persists, visit [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list/applicationGroup) and manually create the group `group.com.mcmusicworkshop.pushuptracker`, then back in Xcode click Try Again.
- **"Cannot find 'PushupCore' in scope" when you add `import PushupCore`.** The package wasn't linked to that target. Target → General → Frameworks and Libraries → + → add it.
- **Strict-concurrency warnings in generated SwiftData boilerplate.** Xcode 16's default template has some rough edges here. Most fixes are small; if something seems deeply wrong, note it in `PROGRESS.md` Open questions rather than fighting it during bootstrap.
- **`xcodebuild` destination errors.** Simulator names change across Xcode versions. Use `xcrun simctl list devices available` to find one that exists locally.