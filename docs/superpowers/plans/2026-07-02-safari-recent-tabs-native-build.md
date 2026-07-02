# Safari Recent Tabs Native Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first runnable native macOS Safari recent-tabs switcher.

**Architecture:** Create a SwiftPM macOS app bundle that runs as a background/menu-bar utility. Keep deterministic behavior in testable models and services, and use narrow AppKit bridges for global hotkey registration and the floating overlay panel.

**Tech Stack:** SwiftPM, Swift, SwiftUI, AppKit, Carbon global hotkeys, NSAppleScript/JXA-style Safari automation, XCTest, shell-first `script/build_and_run.sh`.

---

## File Structure

- `Package.swift`: SwiftPM package with one executable and one test target.
- `Sources/SafariRecentTabs/App/SafariRecentTabsApp.swift`: app entrypoint and scene setup.
- `Sources/SafariRecentTabs/App/AppDelegate.swift`: accessory activation policy, menu-bar item, app wiring.
- `Sources/SafariRecentTabs/Models/SafariTab.swift`: tab identity and display model input.
- `Sources/SafariRecentTabs/Models/SwitcherState.swift`: overlay state and highlighted selection.
- `Sources/SafariRecentTabs/Stores/RecentTabStore.swift`: MRU ordering.
- `Sources/SafariRecentTabs/Services/SafariAutomationClient.swift`: protocol and AppleScript-backed Safari client.
- `Sources/SafariRecentTabs/Services/FaviconProvider.swift`: favicon cache and fallback logic.
- `Sources/SafariRecentTabs/Services/HotkeyController.swift`: Carbon hotkey registration and modifier-release monitor.
- `Sources/SafariRecentTabs/Services/SwitcherCoordinator.swift`: hotkey-to-overlay orchestration.
- `Sources/SafariRecentTabs/Views/SwitcherOverlayView.swift`: SwiftUI overlay contents.
- `Sources/SafariRecentTabs/Support/SwitcherPanelController.swift`: floating `NSPanel` ownership.
- `Tests/SafariRecentTabsTests/RecentTabStoreTests.swift`: MRU behavior.
- `Tests/SafariRecentTabsTests/SwitcherStateTests.swift`: cycle/cancel/activate behavior.
- `Tests/SafariRecentTabsTests/DisplayModelTests.swift`: title/domain/fallback formatting.
- `script/build_and_run.sh`: build, bundle, launch, and optional verification.
- `.codex/environments/environment.toml`: Codex Run button wiring.

## Task 1: Scaffold SwiftPM Package And Tests

**Files:**
- Create: `Package.swift`
- Create: `Tests/SafariRecentTabsTests/RecentTabStoreTests.swift`
- Create: `Tests/SafariRecentTabsTests/SwitcherStateTests.swift`
- Create: `Tests/SafariRecentTabsTests/DisplayModelTests.swift`

- [ ] **Step 1: Create package manifest with app and test targets.**
- [ ] **Step 2: Write failing tests for MRU order, switcher cycling, and display formatting.**
- [ ] **Step 3: Run `swift test` and confirm tests fail because production types are missing.**

## Task 2: Implement Testable Models And Stores

**Files:**
- Create: `Sources/SafariRecentTabs/Models/SafariTab.swift`
- Create: `Sources/SafariRecentTabs/Models/SwitcherState.swift`
- Create: `Sources/SafariRecentTabs/Stores/RecentTabStore.swift`

- [ ] **Step 1: Implement minimal tab model, display formatting, MRU ordering, and switcher state.**
- [ ] **Step 2: Run `swift test` and confirm the model/store tests pass.**
- [ ] **Step 3: Commit package, tests, models, and stores.**

## Task 3: Implement Native App Shell

**Files:**
- Create: `Sources/SafariRecentTabs/App/SafariRecentTabsApp.swift`
- Create: `Sources/SafariRecentTabs/App/AppDelegate.swift`

- [ ] **Step 1: Add SwiftUI app entrypoint with an app delegate.**
- [ ] **Step 2: Configure accessory/background behavior and a menu-bar item with status and quit.**
- [ ] **Step 3: Run `swift build` and fix compile errors only.**

## Task 4: Implement Safari Automation And Favicon Services

**Files:**
- Create: `Sources/SafariRecentTabs/Services/SafariAutomationClient.swift`
- Create: `Sources/SafariRecentTabs/Services/FaviconProvider.swift`

- [ ] **Step 1: Add a Safari client protocol and AppleScript-backed implementation for frontmost-window tabs and activation.**
- [ ] **Step 2: Add non-blocking favicon lookup with in-memory cache and domain fallback.**
- [ ] **Step 3: Run `swift test` and `swift build`.**

## Task 5: Implement Hotkey, Coordinator, And Overlay

**Files:**
- Create: `Sources/SafariRecentTabs/Services/HotkeyController.swift`
- Create: `Sources/SafariRecentTabs/Services/SwitcherCoordinator.swift`
- Create: `Sources/SafariRecentTabs/Support/SwitcherPanelController.swift`
- Create: `Sources/SafariRecentTabs/Views/SwitcherOverlayView.swift`

- [ ] **Step 1: Register Control-Backtick as a Carbon global hotkey.**
- [ ] **Step 2: Track Control release and Escape cancel with AppKit event monitors.**
- [ ] **Step 3: Show a centered floating `NSPanel` containing the tab-aware SwiftUI overlay.**
- [ ] **Step 4: Wire hotkey open/cycle/release/cancel to the coordinator.**
- [ ] **Step 5: Run `swift test` and `swift build`.**

## Task 6: Add Build/Run Tooling

**Files:**
- Create: `script/build_and_run.sh`
- Create: `.codex/environments/environment.toml`

- [ ] **Step 1: Create project-local build/run script that builds, bundles, launches, and verifies the app.**
- [ ] **Step 2: Add Codex Run action pointing at the script.**
- [ ] **Step 3: Run `./script/build_and_run.sh --verify`.**

## Task 7: Final Verification And GitHub Publish

**Files:**
- Modify as needed based on verification.

- [ ] **Step 1: Run `swift test`.**
- [ ] **Step 2: Run `./script/build_and_run.sh --verify`.**
- [ ] **Step 3: Commit the implementation.**
- [ ] **Step 4: Use GitHub CLI auth to create a new private GitHub repo named `recent-tabs-app` unless a remote already exists.**
- [ ] **Step 5: Push the full folder history to GitHub.**
