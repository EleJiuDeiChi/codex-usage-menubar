# Codex Menu Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS SwiftUI menu bar app that shows today's Codex USD cost, refreshes every minute, and exposes a detail panel with today and last-7-day usage.

**Architecture:** Create a small Swift package with a testable core service layer and a SwiftUI app entry point. The app will call `ccusage-codex --json`, parse the result into typed models, and bind the data to a `MenuBarExtra` interface.

**Tech Stack:** Swift 6, SwiftUI, XCTest, Foundation, AppKit integration only where needed for menu bar behavior

---

### Task 1: Create package skeleton and failing parser tests

**Files:**
- Create: `Package.swift`
- Create: `Sources/CodexMenuBarApp/App/CodexMenuBarApp.swift`
- Create: `Sources/CodexMenuBarApp/Core/UsageModels.swift`
- Create: `Sources/CodexMenuBarApp/Core/UsageParser.swift`
- Test: `Tests/CodexMenuBarAppTests/UsageParserTests.swift`

- [ ] Step 1: Write failing parser tests for one-day and seven-day JSON payloads.
- [ ] Step 2: Run `swift test` and verify the parser tests fail for missing types.
- [ ] Step 3: Add the minimal models and parser code to decode the JSON.
- [ ] Step 4: Run `swift test` and verify the parser tests pass.

### Task 2: Add command runner and view model tests

**Files:**
- Create: `Sources/CodexMenuBarApp/Core/CodexUsageService.swift`
- Create: `Sources/CodexMenuBarApp/Core/MenuBarViewModel.swift`
- Test: `Tests/CodexMenuBarAppTests/MenuBarViewModelTests.swift`

- [ ] Step 1: Write failing tests for successful refresh, command failure, and title formatting.
- [ ] Step 2: Run `swift test` and verify the new tests fail for missing service and view model behavior.
- [ ] Step 3: Implement the command service protocol, live shell runner, and view model.
- [ ] Step 4: Run `swift test` and verify the tests pass.

### Task 3: Build the SwiftUI menu bar UI

**Files:**
- Modify: `Sources/CodexMenuBarApp/App/CodexMenuBarApp.swift`
- Create: `Sources/CodexMenuBarApp/UI/MenuBarContentView.swift`

- [ ] Step 1: Write a failing build by referencing the planned SwiftUI views from the app entry point.
- [ ] Step 2: Run `swift build` and verify it fails for missing UI types.
- [ ] Step 3: Implement `MenuBarExtra`, the detail panel, and refresh controls.
- [ ] Step 4: Run `swift build` and verify the app builds.

### Task 4: Verify end-to-end behavior

**Files:**
- Modify: `README.md`

- [ ] Step 1: Add a short README with run instructions and the `ccusage-codex` dependency.
- [ ] Step 2: Run `swift test`.
- [ ] Step 3: Run `swift build`.
- [ ] Step 4: Launch locally with `swift run CodexMenuBarApp` and verify the menu bar app starts.
